import 'package:sqflite_migrate/src/measure.dart';

abstract class BaseReporter<R> {
  /// Takes a [Measure] object as a parameter,
  /// which is used to measure the time taken to run the migrations.
  Measure measure;

  /// Constructor for the [BaseReporter] class.
  BaseReporter(this.measure);

  /// Constructs a list of fields.
  /// In a case of [TextReporter] class it is
  /// used to write header information to the
  /// terminal
  List<String> get fields;

  /// Current content of [StringBuffer] object.
  String get contents;

  /// Current line number of the report.
  int get updatingLine;

  /// Clears the content of the [StringBuffer] object.
  void clear();

  /// Appends a [R] model to the [StringBuffer] object.
  void createReport(R model);

  /// Updates a [R] model in the [StringBuffer] object.
  /// If the model is skipped, the [skipped] parameter
  /// is set to true.
  void updateReportLine(R model, bool skipped);

  /// Writes the content of the [StringBuffer] object to the [Stdout].
  void write();

  /// Finishes the report with a success flag and the number of scanned and migrated files.
  void finish(bool success, int scannedLen, int migratedLen);
}
