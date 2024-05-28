import 'package:sqflite/sqflite.dart';

getColumnCount(Database db, String tableName) async {
  final res =
      await db.rawQuery("SELECT COUNT(*) FROM pragma_table_info('$tableName')");

  return res.first.values.first;
}
