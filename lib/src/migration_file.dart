enum MigrationStatus {
  down("down"),
  up("up");

  final String text;

  const MigrationStatus(this.text);

  factory MigrationStatus.fromString(String str) {
    switch (str) {
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

class MigrationFile {
  MigrationStatus status;
  String path;
  String runAt;
  String content;
  int version;

  MigrationFile(
      {required this.status,
      required this.path,
      required this.runAt,
      required this.version,
      required this.content});

  static String noRun = 'never';

  MigrationFile.fromJson(Map<String, dynamic> json)
      : status = MigrationStatus.fromString(json['status']),
        path = json['path'],
        runAt = json['runAt'],
        version = json['version'],
        content = json['content'];

  @override
  String toString() {
    return '$path - $status - $runAt';
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toString(),
      'path': path,
      'runAt': runAt,
      'version': version,
      'content': content,
    };
  }

  hasVersion(int v) {
    return version == v;
  }

  shouldUpgrade(int v) {
    return MigrationStatus.down;
  }

  shouldDowngrade(int v) {
    return version >= v && status == MigrationStatus.up;
  }
}
