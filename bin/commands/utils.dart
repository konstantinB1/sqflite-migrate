import 'dart:io';

import 'package:args/args.dart';

void createCommonOptions(ArgParser argParser) {
  argParser.addOption('database',
      mandatory: true, abbr: 'd', help: 'Path to sqlite3 database file');

  argParser.addOption('path',
      mandatory: true, abbr: 'p', help: 'Path to migrations folder');
}

void createTimelinedOptions(ArgParser argParser) {
  createCommonOptions(argParser);

  argParser.addFlag('force',
      abbr: 'f',
      help: 'Force the deletion of the database and all migration records');

  argParser.addOption('until',
      abbr: 'u', help: 'Delete all migrations until the provided version');
}

typedef TimelineOptionsResults = (
  String path,
  String dbPath,
  int until,
  bool force
);

typedef CommonOptionsResults = (
  String path,
  String dbPath,
);

TimelineOptionsResults getTimelineOptions(ArgResults argResults) {
  String? path = argResults.option('path');
  String? dbPath = argResults.option('database');
  int until = int.tryParse(argResults.option('until') ?? '') ?? -1;
  bool force = argResults.flag('force');

  if (path == null) {
    throw ArgumentError('No path provided');
  }

  if (dbPath == null) {
    throw ArgumentError('No database path provided');
  }

  return (path, dbPath, until, force);
}

CommonOptionsResults getCommonOptions(ArgResults argResults) {
  String? path = argResults.option('path');
  String? dbPath = argResults.option('database');

  if (path == null) {
    throw ArgumentError('No path provided');
  }

  if (dbPath == null) {
    throw ArgumentError('No database path provided');
  }

  return (path, dbPath);
}
