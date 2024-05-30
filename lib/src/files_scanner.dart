enum FileType { sql, dart }

// Small abstraction layer over AssetManager, if we
// decide to resolve paths in a different way
// (ie only in testing currently)
abstract class FilesScanner {
  Future<List<String>> getPaths(String basePath);
  Future<String> getFile(String path);

  const FilesScanner();
}
