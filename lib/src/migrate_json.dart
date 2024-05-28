import 'package:sqflite_migrate/src/migration_file.dart';

class MigrateJson {
  List<MigrationFile> files = [];

  MigrateJson();

  static validateVersion(int version) {
    if (version < 1) {
      throw Exception("Version must be greater than 0");
    }
  }

  factory MigrateJson.merge(MigrateJson json, MigrateJson currentJson) {
    for (var file in currentJson.files) {
      if (!json.hasFile(file.path)) {
        json.addFile(file);
      }
    }

    return json;
  }

  MigrateJson.withFiles(this.files);

  MigrateJson.fromJson(Map<String, dynamic> json) {
    List<MigrationFile> files = [];

    for (var file in json['files']) {
      files.add(MigrationFile.fromJson(file));
    }

    this.files = files;
  }

  hasFile(String path) {
    return files.any((file) => file.path == path);
  }

  addFile(MigrationFile file) {
    files.add(file);
  }

  isEmpty() {
    return files.isEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'files': files.map((file) => file.toMap()).toList(),
    };
  }

  bool hasVersion(int v) {
    return files.any((file) => file.hasVersion(v));
  }
}
