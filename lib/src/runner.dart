import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migrate/src/errors.dart';
import 'package:sqflite_migrate/src/files_scanner.dart';
import 'package:sqflite_migrate/src/migrate_json.dart';
import 'package:sqflite_migrate/src/migration_file.dart';
import 'package:sqflite_migrate/src/parse_sql_file.dart';
import 'paths_io.dart' if (dart.library.ui) 'paths_flutter.dart';

enum PrefixType { dateIso, version }

enum ActionType { up, down }

abstract class RunnerInterface {
  Future<void> migrate({bool force = false, int until = -1});
  Future<void> rollback({bool force = false, int until = -1});
}

final class Runner extends RunnerInterface {
  final String path;
  final String cachePath;
  final Database db;
  final FileType fileType;
  final FilesScanner _scanner = Paths();

  MigrateJson json = MigrateJson();
  late MigrateJson currentJson;
  List<String> _files = [];

  // Only support version for now
  final PrefixType prefix = PrefixType.version;

  static Future<Runner> init(
      {required path,
      required String cachePath,
      required connection,
      FileType fileType = FileType.sql}) async {
    Runner instance = Runner._(
        path: path, cachePath: cachePath, db: connection, fileType: fileType);

    await instance._resolveFiles();
    await instance._parseExistingJson();
    await instance._getFiles();

    return instance;
  }

  Runner._(
      {required this.path,
      required this.cachePath,
      required this.db,
      required this.fileType});

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
    String content = jsonEncode(json.toMap());

    await file.writeAsString(content);
  }

  Future<void> _resolveFiles() async {
    List<String> assets = await _scanner.getPaths(path);
    assets.removeWhere((element) => !element.endsWith(".sql"));
    assets.sort((a, b) => a.compareTo(b));
    _files = assets;
  }

  _getFiles() async {
    MigrateJson next = json;

    for (String entity in _files) {
      String content = await _scanner.getFile(entity);

      String base = basename(entity);
      List<String> split = base.split("_");

      if (split.length >= 2) {
        int? n = int.tryParse(split[0]);

        if (n == null) {
          throw InvalidMigrationFile(entity);
        }

        if (json.hasVersion(n)) {
          throw DuplicateVersionError(n);
        }

        MigrateJson.validateVersion(n);

        bool hasLine = json.hasFile(content);

        if (!hasLine) {
          MigrationFile file = MigrationFile(
            content: content,
            status: MigrationStatus.down,
            path: entity,
            runAt: "never",
            version: n,
          );

          json.addFile(file);
        }
      }
    }

    json = MigrateJson.withFiles(next.files);
  }

  Future<void> _runAction(MigrationStatus type,
      {int until = -1, bool force = false}) async {
    if (json.isEmpty()) {
      return;
    }

    for (MigrationFile file in json.files) {
      if (file.status.text == type.text && !force) {
        continue;
      }

      if (until != -1 && file.version == until) {
        break;
      }

      ParseSQLFile sqlFile =
          ParseSQLFile(content: file.content, type: type.toString());

      print(sqlFile.statements);

      bool passed = true;

      if (passed) {
        Batch batch = db.batch();

        for (String query in sqlFile.statements) {
          batch.execute(query);
        }

        try {
          await batch.commit();
          file.status = MigrationStatus.up;
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
