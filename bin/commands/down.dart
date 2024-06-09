import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

import 'utils.dart';

class DownCommand extends Command {
  DownCommand() {
    createTimelinedOptions(argParser);
  }

  @override
  String get description => 'Rollback migration files';

  @override
  String get name => 'rollback';

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

    await runner.rollback(force: force, until: until);
  }
}
