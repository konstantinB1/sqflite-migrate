import 'package:sqflite_migrate/src/files_scanner.dart';
import 'package:sqflite_migrate/src/paths_flutter.dart';

FilesScanner? _internalFactory = Paths();

// A setter for resolving files based on either
// dart or flutter implementations ie using
// AssetBundle or File from dart:io
// defaults to dart:io
FilesScanner? get defaultFileScannerFactory => _internalFactory;

set defaultFileScannerFactory(FilesScanner? scanner) {
  if (scanner is! FilesScanner) {
    throw Exception("Must be a FilesScanner factory");
  }

  _internalFactory = scanner;
}
