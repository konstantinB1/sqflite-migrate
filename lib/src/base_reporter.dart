import 'package:sqflite_migrate/src/measure.dart';

abstract class BaseReporter<R> {
  Measure measure;

  BaseReporter(this.measure);

  List<String> get fields;

  String get contents;

  int get updatingLine;

  void clear();

  void createReport(R model);

  void updateReportLine(R model, bool skipped);

  void write();

  void finish(bool success, int scannedLen, int migratedLen);
}
