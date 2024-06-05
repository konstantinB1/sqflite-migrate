import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/measure.dart';
import 'package:sqflite_migrate/src/migration_status.dart';

abstract class BaseReporter {
  Measure measure;

  BaseReporter(this.measure);

  void start(String path, int version);

  void processModel(TrackerModel file);

  void status(List<TrackerModel> models);

  void error(String message);

  void end();
}
