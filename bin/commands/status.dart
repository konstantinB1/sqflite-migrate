import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

import 'utils.dart';

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
    final (path, dbPath) = getCommonOptions(argResults!);

    MigrationRunner runner = await MigrationRunner.init(
        path: join(
          Directory.current.path,
          path,
        ),
        dbPath: dbPath);

    runner.writeReport();
  }
}
