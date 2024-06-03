import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/base_reporter.dart';
import 'package:sqflite_migrate/src/extension.dart';
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
  final String cachePath;
  final FileType fileType;
  final FilesScanner _scanner = defaultFileScannerFactory;
  final String _dbPath;

  // Internal instance of the database
  late Database? _db;
  final BaseReporter _reporter;

  final List<TrackerModel> _scannedModels = [];

  int _version = 1;

  List<String> _files = [];

  // Only support version for now
  final PrefixType prefix = PrefixType.version;

  Future<void> run() async {
    _reporter.start(path, _version);
    await openDatabase(
      _dbPath,
      version: _version,
      onUpgrade: (db, oldVersion, newVersion) {
        print("Upgrading database from $oldVersion to $newVersion");
      },
      onCreate: (db, version) async {
        _db = db;

        await TrackerTable.createTable(db);

        await _resolveFiles();
        await _getFiles();
      },
    );
  }

  Runner(
      {required this.path,
      required this.cachePath,
      this.fileType = FileType.sql,
      TrackerTable? tracker,
      BaseReporter? reporter,
      required String dbPath})
      : _dbPath = dbPath,
        _reporter = reporter ?? TextReporter(Measure());

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

  _getFiles() async {
    for (String entity in _files) {
      String content = await _scanner.getFile(entity);

      String base = basename(entity);
      List<String> split = base.split("_");

      if (split.length >= 2) {
        int? n = int.tryParse(split[0]);

        if (n == null) {
          throw InvalidMigrationFile(entity);
        }

        TrackerModel file = TrackerModel(
          content: content,
          status: MigrationStatus.down,
          path: entity,
          runAt: 'never',
          version: n,
        );

        _scannedModels.add(file);
      }
    }
  }

  Future<void> _runAction(MigrationStatus type,
      {int until = -1, bool force = false}) async {
    if (_scannedModels.isEmpty) {
      return;
    }

    List<TrackerModel> migrated = [];

    _db!.transaction((txn) async {
      TrackerTable tracker = TrackerTable(txn);
      List<TrackerModel> migrations = await tracker.getAll();

      Batch batch = txn.batch();

      for (TrackerModel model in _scannedModels) {
        TrackerModel? entry = migrations
            .whereOrNull((element) => element.version == model.version);

        late MigrationStatus status;

        try {
          if (model.version < until) {
            ParseSQLFile sqlFile =
                ParseSQLFile(content: model.content, type: type);

            for (String query in sqlFile.statements) {
              batch.execute(query);
            }

            status = type;
          } else {
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
              runAt: DateTime.now().toIso8601String());

          if (entry == null) {
            tracker.insert(modelToUpdate);
          } else {
            tracker.updateWhere(modelToUpdate);
          }

          migrated.add(modelToUpdate);
        } catch (e) {
          _reporter.error(e.toString());
          rethrow;
        }
      }

      await batch.commit(noResult: true);

      ++_version;
      _reporter.end(migrated);
    });
  }

  @override
  Future<void> migrate({bool force = false, int until = -1}) async {
    _scannedModels.sort((a, b) => b.version.compareTo(a.version));
    await _runAction(MigrationStatus.up, force: force, until: until);
  }

  @override
  Future<void> rollback({bool force = false, int until = -1}) async {
    _scannedModels.sort();
    await _runAction(MigrationStatus.down, force: force, until: until);
  }
}
