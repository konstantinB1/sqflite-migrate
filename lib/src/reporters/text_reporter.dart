import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:path/path.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/base_reporter.dart';
import 'package:sqflite_migrate/src/migration_status.dart';

class TextReporter extends BaseReporter {
  final AnsiPen _pen = AnsiPen();

  TextReporter(super.measure) {
    ansiColorDisabled = false;
  }

  @override
  void status(List<TrackerModel> models) {
    measure.endMeasure();
    _pen.green(bold: true);
    _pen.reset();
    StringBuffer buffer = StringBuffer('''
---------------------------------------------------------------------------
   Version       STATUS        FILE
---------------------------------------------------------------------------
''');

    int getLatestUp = models
        .lastIndexWhere((element) => element.status == MigrationStatus.up);

    for (int i = 0; i < models.length; i++) {
      TrackerModel model = models[i];
      String fileName = basename(model.path);

      String cur = getLatestUp == i ? '->' : '  ';

      _pen.yellow(bold: true);

      buffer.write('${_pen(cur)} ${model.version}');

      _pen.reset();

      if (model.status == MigrationStatus.up) {
        _pen.green(bold: true);
      } else if (model.status == MigrationStatus.down) {
        _pen.red(bold: true);
      }

      buffer.write(
          _pen('             ${model.status.toString().split('.').last}'));
      String spaces =
          model.status == MigrationStatus.down ? '          ' : '            ';
      buffer.write('$spaces$fileName\n');
      buffer.writeln(
          '---------------------------------------------------------------------------');
    }

    print(buffer.toString());
    buffer.clear();
  }

  @override
  void error(String message) {
    _pen.red();
    stdout.write(_pen('❌ Error during migration: $message'));
    _pen.reset();
  }

  @override
  void processModel(TrackerModel file) {}

  @override
  void start(String path, int version) {
    measure.startMeasure();
    _pen.white();

    print(_pen('🚀 Starting migration for $path to version $version'));
  }

  end() {
    measure.endMeasure();
    _pen.white();
    print(_pen('🎉 Migration completed!'));
  }
}
