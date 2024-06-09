import 'package:args/command_runner.dart';
import 'package:sqflite_migrate/src/runners/default_runner.dart';

import 'utils.dart';

class ClearCommand extends Command {
  ClearCommand() {
    createCommonOptions(argParser);
  }

  @override
  String get description => 'Clear all the migration records from the database';

  @override
  String get name => 'clear';

  @override
  void run() async {
    final (_, dbPath) = getCommonOptions(argResults!);

    MigrationRunner runner =
        await MigrationRunner.init(path: "", dbPath: dbPath);

    await runner.deleteRecords();
  }
}
