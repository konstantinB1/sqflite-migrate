// ignore_for_file: avoid_single_cascade_in_expression_statements

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/migration_status.dart';
import 'package:sqflite_migrate/src/sql_utils.dart';
import 'package:sqflite_migrate/src/tracker_transaction.dart';

import 'mocks/io_file_factory.dart';
import 'utils.dart';

Future<void> deleteCacheFile(String path) async {
  try {
    File f = File(p(part: path, file: "data.json"));
    f.delete();
  } catch (e) {
    throw Exception("Could not delete cache file - $e");
  }
}

Future<String> get dbPath async => join(await getDatabasesPath(), "test.db");

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    setFactoryImpl();
  });

  tearDown(() async {
    deleteDatabase(await dbPath);
  });

  tearDownAll(() async {
    resetFactory();
  });

  Future<Runner> createRunner({required String path}) async {
    String base = join(Directory.current.path, "test", "migrations_test", path);

    Runner runner = Runner(
        path: base, cachePath: join(base, "data.json"), dbPath: await dbPath);

    await runner.run();

    database = runner.db;

    return runner;
  }

  test("invalid file if does not include db ver as prefix", () async {
    expect(() async => await createRunner(path: "migrations_invalid_file"),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test("should migrate files", () async {
    await createRunner(path: "pass")
      ..migrate();

    database.transaction((txn) async {
      TrackerTable tracker = TrackerTable(txn);
      TrackerModel? model = await tracker.getByVersion(1);
      TrackerModel? model2 = await tracker.getByVersion(2);

      expect(model?.status, MigrationStatus.up);
      expect(model2?.status, MigrationStatus.up);
    });

    expect(await getColumnCount(database, "test_table"), 2);
    expect(await getColumnCount(database, "test_table3"), 3);
  });

  test("should rollback files", () async {
    await createRunner(path: "pass")
      ..migrate()
      ..rollback();

    database.transaction((txn) async {
      TrackerTable tracker = TrackerTable(txn);
      TrackerModel? model = await tracker.getByVersion(1);
      TrackerModel? model2 = await tracker.getByVersion(2);

      expect(model?.status, MigrationStatus.down);
      expect(model2?.status, MigrationStatus.down);
    });

    expect(await getColumnCount(database, "test_table"), 0);
    expect(await getColumnCount(database, "test_table3"), 0);
  });

  test('Should only upgrade first version', () async {
    await createRunner(path: "pass")
      ..migrate(until: 2);

    expect(await getColumnCount(database, "test_table"), 2);
    expect(await tableExists(database, "test_table3"), false);
  });

  test('Should only rollback first version', () async {
    await createRunner(path: "pass")
      ..migrate()
      ..rollback(until: 1);

    expect(await getColumnCount(database, "test_table3"), 2);
  });
}
