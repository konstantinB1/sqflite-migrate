class DuplicateVersionError extends Error {
  final int version;

  DuplicateVersionError(this.version);

  @override
  String toString() {
    return 'Duplicate version $version';
  }
}

/// Thrown if migration file is not in the
/// right format ie <int>_<fileNameString>.sql
class InvalidMigrationFile extends Error {
  final String path;

  InvalidMigrationFile(this.path);

  @override
  String toString() {
    return 'Invalid migration file - $path';
  }
}
