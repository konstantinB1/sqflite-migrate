import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migrate/sqflite_migrate.dart';
import 'package:sqflite_migrate/src/paths_flutter.dart';

class IOFactory extends FilesScanner {
  @override
  Future<String> getFile(String path) {
    // TODO: implement getFile
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getPaths(String basePath) {
    // TODO: implement getPaths
    throw UnimplementedError();
  }
}

void setFactoryImpl() {
  defaultFileScannerFactory = IOFactory();
}
