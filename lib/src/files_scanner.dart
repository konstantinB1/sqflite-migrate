enum FileType { sql, dart }

/// Small abstraction over io in case the impementation
/// of mocking io if necessary
abstract class FilesScanner {
  Future<List<String>> getPaths(String basePath);
  Future<String> getFile(String path);

  const FilesScanner();
}
