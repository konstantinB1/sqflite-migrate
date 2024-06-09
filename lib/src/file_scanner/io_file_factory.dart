import 'dart:io';

import 'package:sqflite_migrate/sqflite_migrate.dart';

/// Implementation for dart:io file operations
/// Should be stubbed in test cases
class IOFactory extends FilesScanner {
  @override
  Future<String> getFile(String path) async {
    return await File(path).readAsString();
  }

  @override
  Future<List<String>> getPaths(String basePath) async {
    Directory dir = Directory(basePath);
    return dir.list(recursive: false).map((element) => element.path).toList();
  }
}
