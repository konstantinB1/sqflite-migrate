import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

class DeleteRecords extends Command {
  DeleteRecords() {
    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');
  }

  @override
  String get description => 'Delete all migration records from the database';

  @override
  String get name => 'delete';

  @override
  void run() async {
    String? path = argResults?.option('path');
    String? dbPath = argResults?.option('database');

    if (path == null || dbPath == null) {
      stdout.writeln('No path provided');
      return;
    }

    Runner runner = Runner(
        path: join(
          Directory.current.path,
          path,
        ),
        dbPath: dbPath);

    await runner.deleteRecords();
  }
}

class ClearCommand extends Command {
  ClearCommand() {
    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');

    argParser.addFlag('force',
        abbr: 'f',
        help: 'Force the deletion of the database and all migration records');

    argParser.addFlag('until',
        abbr: 'u', help: 'Delete all migrations until the provided version');
  }

  @override
  String get description => 'Delete the database and all migration records';

  @override
  String get name => 'delete-hard';

  @override
  void run() async {
    AnsiPen pen = AnsiPen();

    try {
      String? dbPath = argResults?.option('database');
      Runner runner = Runner(path: "", dbPath: dbPath!);
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

class StatusCommand extends Command {
  StatusCommand() {
    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');
  }

  @override
  String get description => 'Show the status of all migrations';

  @override
  String get name => 'status';

  @override
  void run() async {
    String? path = argResults?.option('path');
    String? dbPath = argResults?.option('database');

    if (path == null || dbPath == null) {
      stdout.writeln('No path provided');
      return;
    }

    Runner runner = Runner(
        path: join(
          Directory.current.path,
          path,
        ),
        dbPath: dbPath);

    await runner.run();
    runner.writeReport();
  }
}

class UpCommand extends Command {
  UpCommand() {
    argParser.addFlag('force',
        abbr: 'f',
        help: 'Force the deletion of the database and all migration records');

    argParser.addOption('until',
        abbr: 'u', help: 'Delete all migrations until the provided version');

    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');
  }

  @override
  String get description => 'Run all pending migrations';

  @override
  String get name => 'migrate';

  @override
  void run() async {
    String? path = argResults?.option('path');
    String? dbPath = argResults?.option('database');
    int? until = int.tryParse(argResults?.option('until') ?? '') ?? -1;
    bool force = argResults?.flag('force') ?? false;

    if (path == null || dbPath == null) {
      stdout.writeln('No path provided');
      return;
    }

    Runner runner = Runner(
        path: join(
          Directory.current.path,
          path,
        ),
        dbPath: dbPath);

    await runner.run();
    runner.writeReport();

    await runner.migrate(force: force, until: until);
  }
}

class DownCommand extends Command {
  DownCommand() {
    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');

    argParser.addFlag('force',
        abbr: 'f',
        help: 'Force the deletion of the database and all migration records');

    argParser.addOption('until',
        abbr: 'u', help: 'Delete all migrations until the provided version');
  }

  @override
  String get description => 'Rollback the last migration';

  @override
  String get name => 'rollback';

  @override
  void run() async {
    String? path = argResults?.option('path');
    String? dbPath = argResults?.option('database');
    int? until = int.tryParse(argResults?.option('until') ?? '') ?? -1;
    bool force = argResults?.flag('force') ?? false;

    if (path == null || dbPath == null) {
      stdout.writeln('No path provided');
      return;
    }

    Runner runner = Runner(
        path: join(
          Directory.current.path,
          path,
        ),
        dbPath: dbPath);

    await runner.run();
    runner.writeReport();

    await runner.rollback(force: force, until: until);
  }
}

void main(List<String> args) async {
  final CommandRunner runner =
      CommandRunner('sqflite_migrate', 'SQFLite migration tool');

  runner.argParser.addOption('database',
      mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');
  runner.argParser.addOption('path',
      mandatory: true, abbr: 'p', help: 'Path to migrations folder');

  runner
    ..addCommand(StatusCommand())
    ..addCommand(UpCommand())
    ..addCommand(DownCommand())
    ..addCommand(ClearCommand())
    ..addCommand(DeleteRecords());

  await runner.run(args);
}
