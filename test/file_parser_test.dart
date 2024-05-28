import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

void main() {
  test('should throw an error if invalid file', () {
    expect(() => ParseSQLFile(content: "content", type: "UP"),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test('should throw if comment is found but no statements to execute',
      () async {
    File file = File("test/migrations/test_files/malformed_no_statements.sql");
    String content = await file.readAsString();

    expect(() => ParseSQLFile(content: content, type: "UP"),
        throwsA(isA<InvalidMigrationFile>()));
  });

  test('should parse statements, and conditions correctly', () async {
    File file = File("test/migrations/test_files/valid_statements_up.sql");
    String content = await file.readAsString();

    ParseSQLFile parser = ParseSQLFile(content: content, type: "UP");

    expect(parser.statements.length, 2);
    expect(parser.conditions?.length, 2);
  });

  test('should parse statements, and conditions correctly with offset',
      () async {
    File file = File("test/migrations/test_files/down_valid_statements.sql");
    String content = await file.readAsString();

    ParseSQLFile parser = ParseSQLFile(content: content, type: "DOWN");

    expect(parser.statements.length, 2);
    expect(parser.conditions?.length, 4);
  });

  test("multiline queries", () async {
    File file = File("test/migrations/test_files/multiline_queries.sql");
    String content = await file.readAsString();

    ParseSQLFile parser = ParseSQLFile(content: content, type: "UP");

    expect(parser.statements.length, 4);
  });
}
