import 'package:sqflite_migrate/sqflite_migrate.dart';

class FieldOffset {
  final String name;
  final int offset;
  final int length;

  FieldOffset(this.name, this.offset, this.length);

  FieldOffset.withoutOffset(this.name, this.length) : offset = 0;
}

class LineState {
  final int lineNumber;
  final String line;
  final List<FieldOffset> offsets;

  LineState(this.lineNumber, this.line, this.offsets);

  LineState.empty()
      : lineNumber = 0,
        line = '',
        offsets = [];

  void initialOffset(FieldOffset offset) {
    if (offsets.isEmpty) {
      offsets.add(offset);
    }
  }

  void addToCurrentOffset(FieldOffset offset) {
    FieldOffset last = offsets.last;

    offsets.add(FieldOffset(
      last.name,
      last.offset + offset.offset,
      last.length + offset.length,
    ));
  }
}

class TrackerModelState {
  final TrackerModel model;
  final LineState lineState;

  TrackerModelState(this.model, this.lineState);

  int get lineNumber => lineState.lineNumber;
}
