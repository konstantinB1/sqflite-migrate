import 'package:sqflite_migrate/src/errors.dart';
import 'package:sqflite_migrate/src/migration_file.dart';
import 'package:sqflite_migrate/src/utils.dart';

String getBetween(String text, String start, String end) {
  int startIndex = text.indexOf(start);
  int endIndex = text.indexOf(end, startIndex + start.length);

  return text.substring(startIndex + start.length, endIndex);
}

final RegExp commentNodeTemplate = RegExp(r"^--\s{1}(UP|DOWN|IF)\s{1}--$");

class ParseSQLFile {
  final List<String> _content;
  List<String>? _conditions;
  late final List<String> _statements;
  final MigrationStatus _type;

  ParseSQLFile({required String content, required MigrationStatus type})
      : _content = content.split("\n"),
        _type = type {
    _parseTypeStatements();
  }

  ParseSQLFile.offset(
      {required String content,
      required MigrationStatus type,
      required int offset})
      : _content = content.split("\n"),
        _type = type {
    {
      _parseTypeStatements();
    }
  }

  void _parseTypeStatements() {
    print(_type);
    int statementsLabel =
        _content.indexWhere((element) => "-- $_type --" == element.trim());

    if (statementsLabel == -1) {
      throw InvalidMigrationFile("no $_type found");
    }

    if (statementsLabel == _content.length - 1) {
      throw InvalidMigrationFile("no statements found");
    }

    StringBuffer buffer = StringBuffer();
    List<String> statements = [];

    for (int i = statementsLabel + 1; i < _content.length; i++) {
      String cur = _content[i].trim();

      if (cur.isEmpty) {
        continue;
      }

      if (cur == "--" || cur.startsWith("--")) {
        if (buffer.isNotEmpty) {
          throw InvalidMigrationFile(
              "string buffer not closed and found a comment node");
        }

        buffer.clear();
        break;
      }

      if (commentNodeTemplate.hasMatch(cur)) {
        buffer.clear();
        break;
      }

      if (cur.endsWith(";")) {
        buffer.write(cur);
        statements.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(cur);
      }
    }

    _statements = statements;

    _parseIfConditions(statementsLabel - 1);
  }

  void _parseIfConditions(int startOffset) {
    List<String> nextConditions = untilReverse<String>(
        _content, (element, i) => commentNodeTemplate.hasMatch(element.trim()),
        startIndex: startOffset);

    if (nextConditions.isNotEmpty) {
      _conditions = nextConditions;
    }
  }

  List<String> get statements => _statements;
  List<String>? get conditions => _conditions;
}
