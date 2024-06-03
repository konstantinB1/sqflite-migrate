import 'package:sqflite_migrate/src/files_scanner.dart';
import 'package:sqflite_migrate/src/file_scanner/paths_flutter.dart';

// Resolve _internalFactory to default flutter
// implementation. Only time this needs to be
// changed is for testing, so expose the variable
// and keep the internal reference
FilesScanner? _internalFactory;

// Return internal factory reference
FilesScanner get defaultFileScannerFactory {
  return _internalFactory ??= Paths();
}

/// Setter for custom FileScanner, exposed for testing
/// purposes, as we don't want to have to deal with
/// AssetManager logic when testing the migration
/// funcionality
set defaultFileScannerFactory(FilesScanner? scanner) {
  if (scanner is! FilesScanner) {
    throw Exception("Must be a FilesScanner factory");
  }

  _internalFactory = scanner;
}
