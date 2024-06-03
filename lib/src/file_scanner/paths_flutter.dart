import 'package:flutter/services.dart';
import 'package:sqflite_migrate/src/files_scanner.dart';

// A implementation of AssetManager based
// file system retrieval (default behaviour)
class Paths extends FilesScanner {
  @override
  Future<String> getFile(String path) {
    return rootBundle.loadString(path);
  }

  @override
  Future<List<String>> getPaths(String basePath) async {
    AssetManifest manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    List<String> list = manifest.listAssets();

    return list
        .where((element) => element.startsWith(basePath))
        .map((e) => e)
        .toList();
  }
}
