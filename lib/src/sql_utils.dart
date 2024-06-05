import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Get column rows helper
getColumnCount(Database db, String tableName) async {
  final res =
      await db.rawQuery("SELECT COUNT(*) FROM pragma_table_info('$tableName')");

  return res.first.values.first;
}

tableExists(Database db, String tableName) async {
  final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
  return res.isNotEmpty;
}
