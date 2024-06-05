import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_migrate/src/migration_status.dart';
import 'package:sqflite_migrate/src/sql_utils.dart';

const String trackerTable = 'migrate_tracker';

class TrackerModel {
  final int version;
  final MigrationStatus status;
  final String path;
  final String runAt;
  final String content;

  bool needUpdate = false;

  TrackerModel({
    required this.version,
    required this.status,
    required this.path,
    required this.runAt,
    required this.content,
  });

  TrackerModel.copyWith({
    required TrackerModel model,
    this.needUpdate = false,
    int? version,
    MigrationStatus? status,
    String? path,
    String? runAt,
    String? content,
  })  : version = version ?? model.version,
        status = status ?? model.status,
        path = path ?? model.path,
        runAt = runAt ?? model.runAt,
        content = content ?? model.content;

  toMap() {
    return {
      'version': version,
      'status': status.text,
      'path': path,
      'run_at': runAt,
      'content': content,
    };
  }

  @override
  String toString() {
    return 'TrackerModel{version: $version, status: ${status.text}, path: $path, runAt: $runAt, content: $content}';
  }
}

class TrackerTable {
  final Transaction _db;
  Batch? batch;

  TrackerTable(
    Transaction db,
  ) : _db = db;

  static Future<void> createTable(Database db) async {
    if (!await tableExists(db, trackerTable)) {
      await db.execute('''
        CREATE TABLE $trackerTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          version INTEGER NOT NULL,
          status TEXT NOT NULL,
          path TEXT NOT NULL,
          run_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> insert(TrackerModel model) async {
    await _db.insert(trackerTable, {
      'version': model.version,
      'status': model.status.text,
      'path': model.path,
      'run_at': model.runAt,
      'content': model.content,
    });
  }

  Future<List<TrackerModel>> getAll() async {
    final List<Map<String, dynamic>> rows =
        await _db.query(trackerTable, orderBy: 'version ASC');

    return rows.map((row) {
      return TrackerModel(
        version: row['version'],
        status: MigrationStatus.fromString(row['status']),
        path: row['path'],
        runAt: row['run_at'],
        content: row['content'],
      );
    }).toList();
  }

  Future<TrackerModel?> getByVersion(int version) async {
    final List<Map<String, dynamic>> rows = await _db.query(
      trackerTable,
      where: 'version = ?',
      whereArgs: [version],
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    return TrackerModel(
      version: row['version'],
      status: MigrationStatus.fromString(row['status']),
      path: row['path'],
      runAt: row['run_at'],
      content: row['content'],
    );
  }

  toMap(TrackerModel model) {
    return {
      'version': model.version,
      'status': model.status.text,
      'path': model.path,
      'run_at': model.runAt,
      'content': model.content,
    };
  }

  Future<int?> updateWhere(TrackerModel model) async {
    int id = await _db.update(
      trackerTable,
      {
        'status': model.status.text,
        'run_at': model.runAt,
      },
      where: 'version = ? AND path = ?',
      whereArgs: [model.version, model.path],
    );

    if (id == 0) {
      throw Exception('No row found');
    }

    return id;
  }
}
