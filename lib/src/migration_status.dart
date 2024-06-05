enum MigrationStatus {
  down("down"),
  up("up");

  final String text;

  const MigrationStatus(this.text);

  factory MigrationStatus.fromString(String str) {
    switch (str.toUpperCase()) {
      case "DOWN":
        return MigrationStatus.down;
      case "UP":
        return MigrationStatus.up;
      default:
        throw Exception("Invalid migration status");
    }
  }

  @override
  toString() {
    return text.toUpperCase();
  }
}
