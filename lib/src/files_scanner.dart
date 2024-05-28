enum FileType { sql, dart }

abstract class FilesScanner {
  Future<List<String>> getPaths(String basePath);
  Future<String> getFile(String path);

  const FilesScanner();
}
