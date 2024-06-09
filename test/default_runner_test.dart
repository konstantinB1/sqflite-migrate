// ignore_for_file: avoid_single_cascade_in_expression_statements
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/measure.dart';
import 'package:sqflite_migrate/src/migration_status.dart';
import 'package:sqflite_migrate/src/sql_utils.dart';
import 'package:sqflite_migrate/src/tracker_transaction.dart';
import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/test/text_reporter_stub.dart';
import 'utils.dart';

Future<void> deleteCacheFile(String path) async {
  try {
    File f = File(p(part: path, file: "data.json"));
    f.delete();
  } catch (e) {
    throw Exception("Could not delete cache file - $e");
  }
}

Future<String> get dbPath async =>
    join(await getDatabasesPath(), "test_test.db");

void main() {
  late Database database;

  Future<MigrationRunner> createRunner({required String path}) async {
    String base = join(Directory.current.path, "test", "migrations_test", path);

    MigrationRunner runner = await MigrationRunner.init(
        path: base,
        dbPath: await dbPath,
        reporter: TextReporterStub(Measure()));

    database = runner.db;

    return runner;
  }

  group("default_runner_test", () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    test("invalid file if does not include db ver as prefix", () async {
      expect(() async => await createRunner(path: "migrations_invalid_file"),
          throwsA(isA<InvalidMigrationFile>()));
    });

    test("should migrate files", () async {
      MigrationRunner runner = await createRunner(path: "pass");
      TrackerTable tracker = runner.tracker;
      await runner.migrate();

      TrackerModel? model = await tracker.getByVersion(1);
      TrackerModel? model2 = await tracker.getByVersion(2);

      expect(model?.status, MigrationStatus.up);
      expect(model2?.status, MigrationStatus.up);

      expect(await getColumnCount(database, "test_table"), 2);
      expect(await getColumnCount(database, "test_table2"), 3);
    });

    test("should rollback files", () async {
      MigrationRunner runner = await createRunner(path: "pass");
      TrackerTable tracker = runner.tracker;

      await runner.rollback();

      TrackerModel? model = await tracker.getByVersion(1);
      TrackerModel? model2 = await tracker.getByVersion(2);

      expect(model?.status, MigrationStatus.down);
      expect(model2?.status, MigrationStatus.down);

      expect(await getColumnCount(database, "test_table"), 0);
      expect(await getColumnCount(database, "test_table2"), 0);
    });

    test('Should only upgrade first version', () async {
      await createRunner(path: "pass")
        ..migrate(until: 2);

      expect(await getColumnCount(database, "test_table"), 0);
      expect(await tableExists(database, "test_table2"), false);
    });
  });
}
