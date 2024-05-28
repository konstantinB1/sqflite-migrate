import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:test/test.dart';

const baseTestPath = 'test/test_files/migrations_test';

String p(String pt) => join(baseTestPath, pt);

void main() {
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
        path: p(path),
        cachePath: join(baseTestPath, path, "data.json"),
        connection: database);
  }

  test("invalid file if does not include db ver as prefix", () async {
    expect(() async => await createRunner(path: "migrations_invalid_file"),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test("should migrate files", () async {
    // ignore: avoid_single_cascade_in_expression_statements
    await createRunner(path: "pass")
      ..migrate();

    expect(await getColumnCount(database, "test_table"), 2);
  });

  test("should rollback files", () async {
    // ignore: avoid_single_cascade_in_expression_statements
    await createRunner(path: "pass")
      ..rollback();

    expect(await getColumnCount(database, "test_table"), 0);
  });
}
