import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/command_runner.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

import 'utils.dart';

class DeleteDbCommand extends Command {
  DeleteDbCommand() {
    createCommonOptions(argParser);
  }

  @override
  String get description =>
      'Delete the database whole database provided, along with migration records';

  @override
  String get name => 'delete-db';

  @override
  void run() async {
    AnsiPen pen = AnsiPen();

    try {
      final (_, dbPath) = getCommonOptions(argResults!);

      MigrationRunner runner = MigrationRunner(path: "", dbPath: dbPath);
      await runner.deleteDatabase();

      pen.green(bold: true);
      stdout.writeln(pen.write('Database deleted'));
    } catch (e) {
      pen.red(bold: true);
      stdout.writeln(pen.write('Unable to delete database') + e.toString());
    }

    pen.reset();
  }
}
