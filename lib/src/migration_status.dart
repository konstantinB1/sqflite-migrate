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
