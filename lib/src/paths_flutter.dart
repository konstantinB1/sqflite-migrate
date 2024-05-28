import 'package:flutter/services.dart';
import 'package:sqflite_migrate/src/files_scanner.dart';

class Paths extends FilesScanner {
  @override
  Future<String> getFile(String path) {
    return rootBundle.loadString(path);
  }

  @override
  Future<List<String>> getPaths(String basePath) async {
    AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets();
  }
}
