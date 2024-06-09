// ignore: file_names
import 'package:sqflite_migrate/src/base_reporter.dart';

class TextReporterStub extends BaseReporter {
  TextReporterStub(super.measure);

  @override
  void clear() {}

  @override
  String get contents => throw UnimplementedError();

  @override
  void createReport(model) {}

  @override
  List<String> get fields => [];

  @override
  void finish(bool success, int scannedLen, int migratedLen) {}

  @override
  void updateReportLine(model, bool skipped) {}

  @override
  int get updatingLine => 0;

  @override
  void write() {}
}
