import 'dart:io';
import 'package:path/path.dart';

Future<List<String>> getTestDir(String path) async {
  Directory dir = Directory(join("test", path));
  final list = dir.list(recursive: false);
  return list.map((element) => element.path).toList();
}

Future<String> getTestFile(String path) async {
  File file = File(join("test", path));
  return await file.readAsString();
}

p({String? part = "", String? file = ""}) =>
    join('assets/test_files', part, file);
