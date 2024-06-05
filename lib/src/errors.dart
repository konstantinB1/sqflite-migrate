class DuplicateVersionError extends Error {
  final int version;

  DuplicateVersionError(this.version);

  @override
  String toString() {
    return 'Duplicate version $version';
  }
}

class InvalidMigrationFile extends Error {
  final String path;

  InvalidMigrationFile(this.path);

  @override
  String toString() {
    return 'Invalid migration file - $path';
  }
}
