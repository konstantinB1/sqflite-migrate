import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

void main() {
  late Database database;
  late Runner runner;
  late String path;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();

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

  Future<Runner> createRunner(
      {bool useManifest = false, required String path}) async {
    return await Runner.init(
        path: path, cachePath: join(path, "data.json"), connection: database);
  }

  test("invalid file if does not include db ver as prefix", () async {
    expect(
        () async =>
            await createRunner(useManifest: false, path: "assets/migrations"),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test("should migrate files", () async {
    runner = await createRunner(path: "assets/migrations");

    await runner.migrate();

    final res1 = await database
        .rawQuery("SELECT COUNT(*) FROM pragma_table_info('transactions')");

    expect(res1.first.values.first, 7);
  });

  test("should rollback files", () async {
    runner = await createRunner(
        useManifest: false,
        path: "test/migrations/test_files/migrations_test/pass");

    await runner.migrate();
    await runner.rollback();

    final res1 = await database
        .rawQuery("SELECT COUNT(*) FROM pragma_table_info('test_table')");
    final res2 = await database
        .rawQuery("SELECT COUNT(*) FROM pragma_table_info('test_table2')");

    expect(res1.first.values.first, 0);
    expect(res2.first.values.first, 0);
  });
}
