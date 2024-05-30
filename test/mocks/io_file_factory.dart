import 'package:sqflite_migrate/sqflite_migrate.dart';

import '../utils.dart';

// For reseting to default, in tearDown
final _originalImpl = defaultFileScannerFactory;

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

// Calling before all tests
void setFactoryImpl() {
  defaultFileScannerFactory = IOFactory();
}

// Calling after all tests
void resetFactory() {
  defaultFileScannerFactory = _originalImpl;
}
