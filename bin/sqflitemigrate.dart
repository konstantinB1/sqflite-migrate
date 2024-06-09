import 'package:args/command_runner.dart';

import 'commands/clear.dart';
import 'commands/delete_db.dart';
import 'commands/down.dart';
import 'commands/status.dart';
import 'commands/up.dart';

void main(List<String> args) async {
  final CommandRunner runner =
      CommandRunner('sqflite_migrate', 'SQFLite migration tool');

  runner
    ..addCommand(StatusCommand())
    ..addCommand(UpCommand())
    ..addCommand(DownCommand())
    ..addCommand(ClearCommand())
    ..addCommand(DeleteDbCommand());

  await runner.run(args);
}
