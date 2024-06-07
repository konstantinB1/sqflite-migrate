import 'dart:io';

import 'package:ansi_escapes/ansi_escapes.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/base_reporter.dart';
import 'package:sqflite_migrate/src/migration_status.dart';
import 'package:sqflite_migrate/src/reporters/line_state.dart';

const delimiter = '| ';

class TextReporter extends BaseReporter<TrackerModel> {
  final AnsiPen _pen = AnsiPen();
  final StringBuffer _buffer = StringBuffer();
  final int padding = 18;
  final List<TrackerModelState> _models = [];

  bool _headerSet = false;

  TextReporter(super.measure);

  @override
  void clear() {
    _buffer.clear();
  }

  @override
  void createReport(TrackerModel model) {
    stdout.write(ansiEscapes.clearScreen);
    setHeader();

    String status = "";

    final String version = model.version.toString();
    status += _createPaddedItem(version);
    FieldOffset versionOffset =
        FieldOffset('Version', delimiter.length, version.length);

    final String migrationStatus = model.status.toString();
    status += _createPaddedItem(
        migrationStatus,
        () => model.status == MigrationStatus.up
            ? _pen.green(bold: true)
            : _pen.red(bold: true));

    FieldOffset statusOffset = FieldOffset('Status',
        2 * delimiter.length + padding + version.length, status.length);

    final String file = basename(model.path);
    status += _createPaddedItem(file);

    FieldOffset fileOffset = FieldOffset(
        'File',
        3 * delimiter.length + 2 * padding + version.length + status.length,
        file.length);

    _pen.reset();

    int lineHeight =
        _models.isEmpty ? 3 : _models.last.lineState.lineNumber + 2;

    LineState lineState = LineState(lineHeight, status, [
      versionOffset,
      statusOffset,
      fileOffset,
    ]);

    _models.add(
      TrackerModelState(model, lineState),
    );
    _buffer.writeln(status);
    _buffer.write(_createLine(fields));
  }

  String _createLine(List<String> fields, [int extra = 10]) {
    String line = "";
    for (int i = 0; i < fields.length; i++) {
      line += List.generate(fields[i].length + padding + extra, (_) => '-',
              growable: true)
          .join("");
    }

    return "$line\n";
  }

  String _createPaddedItem(String field, [void Function()? setColor]) {
    const baseStr = "| ";
    final String text = field.padRight(padding);

    if (setColor != null) {
      setColor();
      return '$baseStr ${_pen.write(text)}';
    }

    return '$baseStr $text';
  }

  void setHeader() {
    if (_headerSet) {
      return;
    }

    String line = _createLine(fields);
    String header = line;

    for (int i = 0; i < fields.length; i++) {
      header += _createPaddedItem(fields[i]);
    }

    header += '\n$line';

    _buffer.write(header);
    _headerSet = true;
  }

  @override
  List<String> get fields => ['Version', 'Status', 'File'];

  @override
  void updateReportLine(TrackerModel model, bool skipped) {
    final TrackerModelState state = _models.singleWhere(
      (element) => element.model.version == model.version,
    );

    String status = "";
    if (model.status == MigrationStatus.up) {
      _pen.green(bold: true);
      status = "${model.status}  ";
    } else {
      _pen.red(bold: true);
      status = model.status.toString();
    }

    status = _pen.write(status);

    LineState versionOffset = state.lineState;
    stdout.write(ansiEscapes.cursorTo(
        versionOffset.offsets[1].offset + 1, versionOffset.lineNumber));

    _pen.reset();
    stdout.write(status + (skipped ? ' (skipped)' : ''));
  }

  @override
  int get updatingLine => throw UnimplementedError();

  @override
  String get contents => _buffer.toString();

  @override
  void write() {
    stdout.write(contents);
  }

  @override
  void finish(bool success, int scannedLen, int migratedLen) {
    _buffer.clear();
    stdout.write(ansiEscapes.cursorDown(2));

    if (success) {
      _pen.green(bold: true);
      stdout.write(_pen.write('🎉 Migration successful'));
      stdout.write('\n');
      stdout.write('Scanned: $scannedLen\n');
      stdout.write('Migrated: $migratedLen\n');
    } else {
      _pen.red(bold: true);
      stdout.write(_pen.write('Migration failed'));
    }
  }
}
