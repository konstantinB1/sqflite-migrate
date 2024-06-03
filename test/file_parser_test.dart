import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/migration_status.dart';

import 'utils.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('should throw an error if invalid file', () {
    expect(() => ParseSQLFile(content: "content", type: MigrationStatus.up),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test('should throw if comment is found but no statements to execute',
      () async {
    String content =
        await getTestFile(join("test_files", 'malformed_no_statements.sql'));

    expect(() => ParseSQLFile(content: content, type: MigrationStatus.up),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test('should parse statements, and conditions correctly', () async {
    String content =
        await getTestFile(join("test_files", 'valid_statements_up.sql'));
    ParseSQLFile parser =
        ParseSQLFile(content: content, type: MigrationStatus.up);

    expect(parser.statements.length, 2);
    expect(parser.conditions?.length, 2);
  });

  test('should parse statements, and conditions correctly with offset',
      () async {
    String content =
        await getTestFile(join("test_files", 'down_valid_statements.sql'));

    ParseSQLFile parser =
        ParseSQLFile(content: content, type: MigrationStatus.down);

    expect(parser.statements.length, 2);
    expect(parser.conditions?.length, 4);
  });

  test("multiline queries", () async {
    String content =
        await getTestFile(join("test_files", 'multiline_queries.sql'));

    ParseSQLFile parser =
        ParseSQLFile(content: content, type: MigrationStatus.up);

    expect(parser.statements.length, 4);
  });
}
