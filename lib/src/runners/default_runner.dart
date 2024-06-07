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
  final String path;
  final FileType fileType;
  final FilesScanner _scanner = IOFactory();
  final String _dbPath;

  TrackerTable? _tracker;

  // Internal instance of the database
  late Database? _db;
  final TextReporter _reporter = TextReporter(Measure());

  final List<TrackerModel> _scannedModels = [];

  List<String> _files = [];
  final List<TrackerModel> _dbModels = [];

  void writeReport() {
    _reporter.write();
  }

  @override
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

  Future<void> _resolveFiles() async {
    List<String> assets = await _scanner.getPaths(path);
    assets.removeWhere((element) => !element.endsWith(Extension.sql.value));
    assets.sort((a, b) => a.compareTo(b));
    _files = assets;
  }

  Future<void> deleteDatabase() async {
    await databaseFactoryFfi.deleteDatabase(path);
  }

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

  Future<void> _runAction(MigrationStatus type,
      {int until = -1, bool force = false}) async {
    if (_scannedModels.isEmpty) {
      return;
    }

    List<TrackerModel> migrated = [];
    final List<TrackerModel>? migrations = await models;
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
          await _tracker?.insert(modelToUpdate);
        } else {
          await _tracker?.updateWhere(modelToUpdate);
        }

        await Future.delayed(Duration(milliseconds: 200), () {
          _reporter.updateReportLine(modelToUpdate, skipped);
        });

        migrated.add(modelToUpdate);
      }

      res = await batch.commit(continueOnError: false);

      _reporter.finish(true, _scannedModels.length, res.length);
    } catch (e) {
      _reporter.finish(false, _scannedModels.length, res.length);
      throw Exception(
          "\nError occured at path: ${maybeError?.path} with message: \n$e");
    }
  }

  @override
  Future<void> migrate({bool force = false, int until = -1}) async {
    await _runAction(MigrationStatus.up, force: force, until: until);
  }

  @override
  Future<void> rollback({bool force = false, int until = -1}) async {
    await _runAction(MigrationStatus.down, force: force, until: until);
  }
}
