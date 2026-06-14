import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openDbAtVersion(int version) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: version,
      onCreate: (db, v) async {
        // Simulate the schema at the requested version by creating the latest schema
        // and then letting upgrade tests explicitly exercise `upgradeSchema`.
        await DatabaseService.createSchema(db);
      },
    ),
  );
}

Future<List<String>> _columns(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name']! as String).toList();
}

void main() {
  test('DB-MIG-01 createSchema creates notes and reminder tables', () async {
    final db = await _openDbAtVersion(DatabaseService.schemaVersion);
    final tables = await db
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'")
        .then((rows) => rows.map((r) => r['name']! as String).toList());
    expect(tables, contains('notes'));
    expect(tables, contains('reminder_notifications'));
    await db.close();
  });

  test('DB-MIG-02 upgradeSchema (<8) adds annotations column', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          // Create a minimal v1-ish notes table without newer columns
          await db.execute('''
            CREATE TABLE notes(
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    await DatabaseService.upgradeSchema(db, oldVersion: 1, newVersion: 8);
    final cols = await _columns(db, 'notes');
    expect(cols, contains('annotations'));
    expect(cols, contains('rowStatus'));
    expect(cols, contains('last_sync_time'));
    await db.close();
  });
}
