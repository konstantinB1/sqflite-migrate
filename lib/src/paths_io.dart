import 'dart:io';

import 'package:sqflite_migrate/src/files_scanner.dart';

class Paths extends FilesScanner {
  const Paths() : super();

  @override
  Future<String> getFile(String path) async {
    File file = File(path);
    return await file.readAsString();
  }

  @override
  Future<List<String>> getPaths(String basePath) async {
    Directory dir = Directory(basePath);
    return await dir.list().map((e) => e.path).toList();
  }
}
