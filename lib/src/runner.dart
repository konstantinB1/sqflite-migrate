import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/base_runner.dart';
import 'package:sqflite_migrate/src/extension.dart';
import 'package:sqflite_migrate/src/files_scanner.dart';
import 'package:sqflite_migrate/src/migrate_json.dart';
import 'package:sqflite_migrate/src/migration_file.dart';

enum PrefixType { dateIso, version }

enum ActionType { up, down }

final class Runner extends BaseRunner {
  final String path;
  final String cachePath;
  final Database db;
  final FileType fileType;
  final FilesScanner _scanner = defaultFileScannerFactory;

  MigrateJson currentJson = MigrateJson();
  List<String> _files = [];

  // Only support version for now
  final PrefixType prefix = PrefixType.version;

  static Future<Runner> init({
    required path,
    required String cachePath,
    required connection,
    FileType fileType = FileType.sql,
  }) async {
    Runner instance = Runner._(
      path: path,
      cachePath: cachePath,
      db: connection,
      fileType: fileType,
    );

    await instance._parseExistingJson();
    await instance._resolveFiles();
    await instance._getFiles();

    return instance;
  }

  Runner._({
    required this.path,
    required this.cachePath,
    required this.db,
    required this.fileType,
  });

  get currentVersion {
    if (currentJson.isEmpty()) {
      return 0;
    }

    return currentJson.files.sort((a, b) {
      int versionComparison = b.version.compareTo(a.version);
      if (versionComparison != 0) {
        return versionComparison;
      } else {
        return a.status == MigrationStatus.up ? -1 : 1;
      }
    });
  }

  _parseExistingJson() async {
    File file = File(cachePath);

    bool exists = await file.exists();

    if (!exists) {
      await file.create(recursive: true);
    } else {
      String content = await file.readAsString();

      if (content.isEmpty) {
        currentJson = MigrateJson();
        return;
      }

      Map<String, dynamic> current = jsonDecode(content);
      currentJson = MigrateJson.fromJson(current);
    }
  }

  Future<void> _createReportJson() async {
    File file = File(cachePath);
    String content = jsonEncode(currentJson.toMap());

    await file.writeAsString(content);
  }

  Future<void> _resolveFiles() async {
    List<String> assets = await _scanner.getPaths(path);
    assets.removeWhere((element) => !element.endsWith(Extension.sql.value));
    assets.sort((a, b) => a.compareTo(b));
    _files = assets;
  }

  _getFiles() async {
    MigrateJson next = currentJson;

    for (String entity in _files) {
      String content = await _scanner.getFile(entity);

      String base = basename(entity);
      List<String> split = base.split("_");

      if (split.length >= 2) {
        int? n = int.tryParse(split[0]);

        if (n == null) {
          throw InvalidMigrationFile(entity);
        }

        // if (currentJson.hasVersion(n)) {
        //   throw DuplicateVersionError(n);
        // }

        MigrateJson.validateVersion(n);

        bool hasLine = currentJson.hasFile(entity);

        if (!hasLine) {
          MigrationFile file = MigrationFile(
            content: content,
            status: MigrationStatus.down,
            path: entity,
            runAt: MigrationFile.noRun,
            version: n,
          );

          currentJson.addFile(file);
        }
      }
    }

    currentJson = MigrateJson.withFiles(next.files);
  }

  Future<void> _runAction(MigrationStatus type,
      {int until = -1, bool force = false}) async {
    if (currentJson.isEmpty()) {
      return;
    }

    for (MigrationFile file in currentJson.files) {
      if (until != -1 && file.version == until) {
        break;
      }

      ParseSQLFile sqlFile =
          ParseSQLFile(content: file.content, type: type.toString());

      bool passed = true;

      if (passed) {
        Batch batch = db.batch();

        for (String query in sqlFile.statements) {
          batch.execute(query);
        }

        try {
          await batch.commit();
          file.status = type;
          file.runAt = DateTime.now().toString();
        } catch (e) {
          throw Exception("Error running migration: ${e.toString()}");
        }
      }
    }

    await _createReportJson();
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
