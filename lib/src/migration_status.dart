/// All the statuses that a migration can be in
///
/// Special [Pending] status should be used
/// for atomic transactions using either [Batch]
/// or [Transaction] API from sqflite package,
/// so that before actually migrating we have
/// a visual indicator that its not yet commited
enum MigrationStatus {
  down("down"),
  up("up"),
  pending("pending");

  final String text;

  const MigrationStatus(this.text);

  factory MigrationStatus.fromString(String str) {
    switch (str.toUpperCase()) {
      case "DOWN":
        return MigrationStatus.down;
      case "UP":
        return MigrationStatus.up;
      case "PENDING":
        return MigrationStatus.pending;
      default:
        throw Exception("Invalid migration status");
    }
  }

  @override
  toString() {
    return text.toUpperCase();
  }
}
