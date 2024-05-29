// ignore_for_file: avoid_single_cascade_in_expression_statements

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

import 'utils.dart';

Future<void> deleteCacheFile(String path) async {
  try {
    File f = File(p(part: path, file: "data.json"));
    f.delete();
  } catch (e) {
    print("Error deleting file: $e");
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  late Database database;
  late String path;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    String dbPath = await getDatabasesPath();
    path = join(dbPath, "test.db");

    database = await openDatabase(path);
  });

  tearDownAll() async {
    await database.close();
    deleteDatabase(path);
  }

  Future<Runner> createRunner({required String path}) async {
    return await Runner.init(
        path: join("assets", "migrations_test", path),
        cachePath: p(part: path, file: "data.json"),
        connection: database);
  }

  test("invalid file if does not include db ver as prefix", () async {
    expect(() async => await createRunner(path: "migrations_invalid_file"),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test("should migrate files", () async {
    await createRunner(path: "pass")
      ..migrate();

    expect(await getColumnCount(database, "test_table"), 2);
  });

  test("should rollback files", () async {
    await createRunner(path: "pass")
      ..rollback();

    expect(await getColumnCount(database, "test_table"), 0);
  });
}
