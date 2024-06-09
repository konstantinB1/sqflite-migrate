enum FileType { sql, dart }

/// Small abstraction over io in case the impementation
/// of mocking io if necessary
abstract class FilesScanner {
  /// Logic for getting files from directory
  Future<List<String>> getPaths(String basePath);

  /// Logic for reading files
  Future<String> getFile(String path);

  const FilesScanner();
}
