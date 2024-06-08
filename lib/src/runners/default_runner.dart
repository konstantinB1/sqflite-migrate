import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/extension.dart';
import 'package:sqflite_migrate/src/file_scanner/io_file_factory.dart';
import 'package:sqflite_migrate/src/files_scanner.dart';
import 'package:sqflite_migrate/src/measure.dart';
import 'package:sqflite_migrate/src/migration_status.dart';
import 'package:sqflite_migrate/src/reporters/text_reporter.dart';
import 'package:sqflite_migrate/src/tracker_transaction.dart';
import 'package:sqflite_migrate/src/utils.dart';

enum PrefixType { dateIso, version }

/// Main runner implementation
/// Needs to be run with [Runner.init] static method
/// so we implictly take care of all the resource gathering
/// in that phase, and then returning the instance, which
/// is exposing the BaseRunner methods
/// [connection] an [sqflite] instnace, created usually via
/// [openConnection]
/// [cachePath] argument will create a dedicated json file
/// by default in the same directory if [path] is not provided
/// It will skip all migrations where statuses match with the
/// latest from the cache config file.
/// Using [migrate]](force: true) (or [rollback]](force: true)), will override this behaviour
/// and run the migrations anyway
final class Runner extends BaseRunner {
  /// A path provided by the user, where all the migrations
  /// are stored
  final String path;

  /// Type of the file, by default (and currently the only one)
  /// is [FileType.sql]
  final FileType fileType;

  /// Internal instance of the file scanner
  final FilesScanner _scanner = IOFactory();

  /// Path to the database file to be used by
  /// [Database] instance
  final String _dbPath;

  /// Internal instance of the tracker table
  /// to be used for all the database operations
  /// like insert, update, delete, etc.
  TrackerTable? _tracker;

  // Internal instance of the database
  late Database? _db;

  /// Internal text reported that directly writes
  /// to stdout. It is built for the cli client,
  /// but can be easily extended to other reporters
  /// like json, html, etc.
  final TextReporter _reporter = TextReporter(Measure());

  /// State of all the scanned models currrently
  /// in the database
  final List<TrackerModel> _scannedModels = [];

  /// Track of all the files in the directory provided
  /// in the [path] argument
  List<String> _files = [];

  final List<TrackerModel> _dbModels = [];

  void writeReport() {
    _reporter.write();
  }

  String get status => _reporter.contents;

  FutureOr<List<TrackerModel>>? get models async {
    if (_dbModels.isEmpty) {
      _dbModels.addAll(await _tracker!.getAll());
    }

    return _dbModels;
  }

  // Only support version for now
  final PrefixType prefix = PrefixType.version;

  Future<void> run() async {
    sqfliteFfiInit();

    _db = await databaseFactoryFfi.openDatabase(
      _dbPath,
    );

    _db = db;

    await TrackerTable.createTable(db);
    _tracker = TrackerTable(db);

    await _resolveFiles();
    await _getFiles();
  }

  Runner(
      {required this.path,
      this.fileType = FileType.sql,
      TrackerTable? tracker,
      required String dbPath})
      : _dbPath = dbPath;

  get db {
    if (_db == null) {
      throw Exception("Database is not initialized");
    }

    return _db;
  }

  /// Resolve all the files in directory delegated by [path]
  /// and io implemented in [FilesScanner] insstance
  Future<void> _resolveFiles() async {
    List<String> assets = await _scanner.getPaths(path);
    assets.removeWhere((element) => !element.endsWith(Extension.sql.value));

    /// Sort the files by the version
    assets.sort((a, b) => a.compareTo(b));
    _files = assets;
  }

  /// Wrapper around the [databaseFactoryFfi.deleteDatabase] method
  /// to delete the database file
  Future<void> deleteDatabase() async {
    await databaseFactoryFfi.deleteDatabase(path);
  }

  /// Wrapper around the [TrackerTable.deleteAll] method
  Future<void> deleteRecords() async {
    await _tracker?.deleteAll();
  }

  Future<void> _getFiles() async {
    final List<TrackerModel>? migrations = await models;

    for (String entity in _files) {
      String content = await _scanner.getFile(entity);

      String base = basename(entity);
      List<String> split = base.split("_");

      if (split.length >= 2) {
        int? n = int.tryParse(split[0]);

        if (n == null) {
          throw InvalidMigrationFile(entity);
        }

        TrackerModel? modelByVersion = migrations?.singleWhere(
          (element) => element.version == n,
          orElse: () {
            TrackerModel file = TrackerModel(
              content: content,
              status: MigrationStatus.down,
              path: entity,
              runAt: 'never',
              version: n,
            );

            _tracker!.insert(file);

            return file;
          },
        );

        if (modelByVersion != null) {
          _scannedModels.add(modelByVersion);
          _reporter.createReport(modelByVersion);
        }
      }
    }
  }

  _shouldMigrate(int until, int version, bool matchStatus) {
    if (until == -1) {
      return !matchStatus;
    }

    return version < until && until != -1 && !matchStatus;
  }

  /// Runs the migration action, either [MigrationStatus.up] or
  /// [MigrationStatus.down] based on the [type] argument.
  /// If [force] is set to true, it will try to run all the migrations
  /// regardless of the status in the database
  /// If [until] is set to a specific version, it will run all the migrations
  /// up to that version, if the version is not found in the database
  /// it will create an entry with the status of the migration
  /// The method is atomic, and all the operations are wrapped in a
  /// [Batch] instance
  Future<void> _runAction(MigrationStatus type,
      {int until = -1, bool force = false}) async {
    if (_scannedModels.isEmpty) {
      return;
    }

    final List<TrackerModel>? migrations = await models;
    final List<TrackerModel> updateTrackerTables = [];
    final List<TrackerModel> insertToTrackerTables = [];

    TrackerModel? maybeError;
    List<Object?> res = [];

    try {
      Batch batch = _db!.batch();

      for (TrackerModel model in _scannedModels) {
        maybeError = model;
        TrackerModel? entry = migrations!
            .whereOrNull((element) => element.version == model.version);

        late MigrationStatus status;
        bool skipped = false;

        if (_shouldMigrate(until, model.version, entry?.status == type)) {
          ParseSQLFile sqlFile =
              ParseSQLFile(content: model.content, type: type);

          for (String query in sqlFile.statements) {
            batch.execute(query);
          }

          status = type;
        } else {
          skipped = true;

          if (entry?.status != null) {
            status = entry!.status;
          } else {
            status = type == MigrationStatus.up
                ? MigrationStatus.down
                : MigrationStatus.up;
          }
        }

        TrackerModel modelToUpdate = TrackerModel.copyWith(
            model: model,
            status: status,
            version: entry?.version ?? model.version,
            path: entry?.path ?? model.path,
            runAt: DateTime.now().toIso8601String());

        if (entry == null) {
          insertToTrackerTables.add(modelToUpdate);
        } else {
          updateTrackerTables.add(modelToUpdate);
        }

        await Future.delayed(Duration(milliseconds: 200), () {
          _reporter.updateReportLine(modelToUpdate, skipped);
        });
      }

      res = await batch.commit(continueOnError: false);

      if (res.isNotEmpty) {
        for (TrackerModel model in insertToTrackerTables) {
          await _tracker!.insert(model);
        }

        for (TrackerModel model in updateTrackerTables) {
          await _tracker!.updateWhere(model);
        }
      }

      _reporter.finish(true, _scannedModels.length, res.length);
    } catch (e) {
      _reporter.finish(false, _scannedModels.length, res.length);
      throw Exception(
          "\nError occured at path: ${maybeError?.path} with message: \n$e");
    }
  }

  /// Runs all the migrations from the [path] directory, using internal
  /// database table created by [_tracker] instance. All the operations
  /// are ensured to be atomic.
  /// If [force] is set to true, it will try to run all the migrations
  /// regardless of the status in the database
  /// If [until] is set to a specific version, it will run all the migrations
  /// up to that version, if the version is not found in the database
  /// it will create an entry with the status of the migration
  @override
  Future<void> migrate({bool force = false, int until = -1}) async {
    await _runAction(MigrationStatus.up, force: force, until: until);
  }

  /// Rollbacks all the migrations from the [path] directory, using internal
  /// database table created by [_tracker] instance. All the operations
  /// are ensured to be atomic.
  /// If [force] is set to true, it will try to run all the migrations
  /// regardless of the status in the database
  /// If [until] is set to a specific version, it will run all the migrations
  /// up to that version, if the version is not found in the database
  /// it will create an entry with the status of the migration
  @override
  Future<void> rollback({bool force = false, int until = -1}) async {
    await _runAction(MigrationStatus.down, force: force, until: until);
  }
}
