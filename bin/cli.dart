import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';

Runner? runner;

void createRunner(
    {required String path, required Future<String> dbPath}) async {
  String base = join(Directory.current.path, 'test', 'migrations_test', path);

  if (runner != null) {
    runner = Runner(path: base, dbPath: await dbPath);
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
  }
}

class UpCommand extends Command {
  UpCommand() {
    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');
  }

  @override
  String get description => 'Run all pending migrations';

  @override
  String get name => 'up';

  @override
  void run() async {
    print(argParser.options);
  }
}

class DownCommand extends Command {
  DownCommand() {
    argParser.addOption('database',
        mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

    argParser.addOption('path',
        mandatory: true, abbr: 'p', help: 'Path to migrations folder');
  }

  @override
  String get description => 'Rollback the last migration';

  @override
  String get name => 'down';

  @override
  void run() async {
    stdout.writeln('Running down command');
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
    ..addCommand(DownCommand());

  await runner.run(args);

  // final ArgParser baseParser = ArgParser();
  // final ArgParser statusCommand = ArgParser();

  // baseParser.addCommand('status', statusCommand);

  // baseParser.addOption('path',
  //     mandatory: true, abbr: 'p', help: 'Path to migrations folder');

//   String help = '''
//   Usage: sqflite_migrate <command> [arguments]

//   Commands:
//     status           Show the status of all migrations
//     up               Run all pending migrations
//     down             Rollback the last migration
//     create           Create a new migration
//     help             Show this help message

//   Options:
//     -p, --path       Path to migrations folder
// ''';

  // ArgResults results = baseParser.parse(['status', ...args]);

  // String? path = results.option('path');

  // if (path == null) {
  //   stdout.writeln('No command provided\n');
  //   stdout.writeln(baseParser.usage);

  //   return;
  // }

  // switch (results.command?.name) {
  //   case 'status':
  //     break;
  //   case 'up':
  //     break;
  //   case 'down':
  //     break;
  //   case 'create':
  //     break;
  //   case 'help':
  //     stdout.write(help);
  //     break;
  //   default:
  //     stdout.write(help);
  //     break;
  // }

  // final dhbPath = join(Directory.current.path, 'test.db');
  // final migrationsFolder =
  //     join(Directory.current.path, 'test', 'migrations_test', 'pass');

  // Runner runner = Runner(dbPath: dhbPath, path: migrationsFolder);

  // await runner.run();

  // var verbose = args.contains('-v');
  // var logger = verbose ? Logger.verbose() : Logger.standard();

  // logger.stdout('Hello world!');
  // logger.trace('message 1');
  // await Future.delayed(Duration(milliseconds: 200));
  // logger.trace('message 2');
  // logger.trace('message 3');

  // var progress = logger.progress('doing some work');
  // await Future.delayed(Duration(seconds: 2));
  // progress.finish(showTiming: true);

  // logger.stdout('All ${logger.ansi.emphasized('done')}.');
}
