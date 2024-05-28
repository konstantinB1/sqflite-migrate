import 'package:sqflite_migrate/src/paths_io.dart';

// A setter for resolving files based on either
// dart or flutter implementations ie using
// AssetBundle or File from dart:io
// defaults to dart:io
Paths defaultFileScannerFactory = const Paths();
