import 'dart:io';

import 'package:sqflite_migrate/sqflite_migrate.dart';
import "package:path/path.dart";

Future<List<String>> getTestDir(String path) async {
  Directory dir = Directory(join("test", path));
  final list = dir.list(recursive: false);
  return list.map((element) => element.path).toList();
}

Future<String> getTestFile(String path) async {
  File file = File(join("test", path));
  return await file.readAsString();
}

// Dead simple abstraction over dart:io FS based methods
class IOFactory extends FilesScanner {
  @override
  Future<String> getFile(String path) async {
    return await getTestFile(path);
  }

  @override
  Future<List<String>> getPaths(String basePath) async {
    return await getTestDir(basePath);
  }
}
