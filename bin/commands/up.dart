import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

import 'utils.dart';

class UpCommand extends Command {
  UpCommand() {
    createTimelinedOptions(argParser);
  }

  @override
  String get description => 'Run all pending migrations';

  @override
  String get name => 'migrate';

  @override
  void run() async {
    final (path, dbPath, until, force) = getTimelineOptions(argResults!);

    MigrationRunner runner = await MigrationRunner.init(
        path: join(
          Directory.current.path,
          path,
        ),
        dbPath: dbPath);

    runner.writeReport();

    await runner.migrate(force: force, until: until);
  }
}
