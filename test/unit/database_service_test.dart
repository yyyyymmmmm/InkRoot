// ============================================================
// 第二档测试 · DatabaseService
// 使用 sqflite_common_ffi 在内存数据库中验证 CRUD 逻辑
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:inkroot/models/note_model.dart';

// ─── 内存数据库工具 ───────────────────────────────────────────────────────────

/// 直接在内存中创建与 DatabaseService 结构相同的数据库，
/// 用于测试业务逻辑而无需依赖单例。
Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            displayTime TEXT,
            tags TEXT,
            creator TEXT,
            is_synced INTEGER DEFAULT 0,
            isPinned INTEGER DEFAULT 0,
            visibility TEXT DEFAULT 'PRIVATE',
            rowStatus TEXT DEFAULT 'NORMAL',
            resourceList TEXT DEFAULT '[]',
            relations TEXT DEFAULT '[]',
            annotations TEXT DEFAULT '[]',
            reminder_time TEXT,
            last_sync_time TEXT
          )
        ''');
      },
    ),
  );
}

// ─── 测试用 Note 工厂 ─────────────────────────────────────────────────────────

Note _makeNote({
  String id = 'test-001',
  String content = '测试内容',
  bool isSynced = false,
  bool isPinned = false,
  String rowStatus = 'NORMAL',
  String visibility = 'PRIVATE',
  List<String> tags = const [],
}) =>
    Note(
      id: id,
      content: content,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      isSynced: isSynced,
      isPinned: isPinned,
      rowStatus: rowStatus,
      visibility: visibility,
      tags: tags,
    );

// ─── 模拟 DatabaseService 的核心方法（直接对 db 操作） ────────────────────────

Future<void> _saveNote(Database db, Note note) => db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

Future<Note?> _getNoteById(Database db, String id) async {
  final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
  if (maps.isEmpty) return null;
  return Note.fromMap(maps[0]);
}

Future<List<Note>> _getAllNotes(Database db) async {
  final maps = await db.query('notes', orderBy: 'createdAt DESC');
  return maps.map(Note.fromMap).toList();
}

Future<void> _deleteNote(Database db, String id) =>
    db.delete('notes', where: 'id = ?', whereArgs: [id]);

Future<void> _markSynced(Database db, String id) =>
    db.update('notes', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);

Future<int> _getCount(Database db) async {
  final result = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
  return result.first['count'] as int;
}

Future<List<Note>> _getUnsyncedNotes(Database db) async {
  final maps =
      await db.query('notes', where: 'is_synced = ?', whereArgs: [0]);
  return maps.map(Note.fromMap).toList();
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await _openTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  // ─────────────────────────────────────────────────────────
  // CRUD 基础操作
  // ─────────────────────────────────────────────────────────
  group('DatabaseService — CRUD', () {
    test('DB-01 saveNote 插入后可通过 id 查询', () async {
      final note = _makeNote(id: 'n1', content: '你好世界');
      await _saveNote(db, note);
      final found = await _getNoteById(db, 'n1');
      expect(found, isNotNull);
      expect(found!.content, '你好世界');
    });

    test('DB-02 saveNote 重复插入执行 upsert（替换）', () async {
      final note = _makeNote(id: 'n2', content: '原始内容');
      await _saveNote(db, note);
      final updated = note.copyWith(content: '更新内容');
      await _saveNote(db, updated);
      final found = await _getNoteById(db, 'n2');
      expect(found!.content, '更新内容');
      expect(await _getCount(db), 1);
    });

    test('DB-03 deleteNote 删除后不可查询', () async {
      await _saveNote(db, _makeNote(id: 'n3'));
      await _deleteNote(db, 'n3');
      final found = await _getNoteById(db, 'n3');
      expect(found, isNull);
    });

    test('DB-04 getNotes 返回所有笔记', () async {
      await _saveNote(db, _makeNote(id: 'a1'));
      await _saveNote(db, _makeNote(id: 'a2'));
      await _saveNote(db, _makeNote(id: 'a3'));
      final notes = await _getAllNotes(db);
      expect(notes.length, 3);
    });

    test('DB-05 空数据库查询返回空列表', () async {
      final notes = await _getAllNotes(db);
      expect(notes, isEmpty);
    });

    test('DB-06 getNoteById 不存在时返回 null', () async {
      final found = await _getNoteById(db, 'non-existent');
      expect(found, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 同步状态管理
  // ─────────────────────────────────────────────────────────
  group('DatabaseService — 同步状态', () {
    test('DB-07 markSynced 将 is_synced 设为 1', () async {
      await _saveNote(db, _makeNote(id: 's1', isSynced: false));
      await _markSynced(db, 's1');
      final note = await _getNoteById(db, 's1');
      expect(note!.isSynced, isTrue);
    });

    test('DB-08 getUnsyncedNotes 只返回未同步笔记', () async {
      await _saveNote(db, _makeNote(id: 'u1', isSynced: false));
      await _saveNote(db, _makeNote(id: 'u2', isSynced: true));
      await _saveNote(db, _makeNote(id: 'u3', isSynced: false));
      final unsynced = await _getUnsyncedNotes(db);
      expect(unsynced.length, 2);
      expect(unsynced.map((n) => n.id), containsAll(['u1', 'u3']));
    });

    test('DB-09 新插入笔记默认 is_synced=false', () async {
      await _saveNote(db, _makeNote(id: 'def1'));
      final note = await _getNoteById(db, 'def1');
      expect(note!.isSynced, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 数据完整性
  // ─────────────────────────────────────────────────────────
  group('DatabaseService — 数据完整性', () {
    test('DB-10 tags 存储和读取一致', () async {
      final note = _makeNote(id: 't1', tags: ['flutter', 'dart', 'test']);
      await _saveNote(db, note);
      final found = await _getNoteById(db, 't1');
      expect(found!.tags, containsAll(['flutter', 'dart', 'test']));
    });

    test('DB-11 isPinned=true 存储和读取一致', () async {
      final note = _makeNote(id: 'p1', isPinned: true);
      await _saveNote(db, note);
      final found = await _getNoteById(db, 'p1');
      expect(found!.isPinned, isTrue);
    });

    test('DB-12 visibility=PUBLIC 存储和读取一致', () async {
      final note = _makeNote(id: 'v1', visibility: 'PUBLIC');
      await _saveNote(db, note);
      final found = await _getNoteById(db, 'v1');
      expect(found!.visibility, 'PUBLIC');
    });

    test('DB-13 rowStatus=ARCHIVED 存储和读取一致', () async {
      final note = _makeNote(id: 'r1', rowStatus: 'ARCHIVED');
      await _saveNote(db, note);
      final found = await _getNoteById(db, 'r1');
      expect(found!.rowStatus, 'ARCHIVED');
      expect(found.isArchived, isTrue);
    });

    test('DB-14 content 含 Unicode/Emoji 正确存储', () async {
      final note = _makeNote(id: 'e1', content: '🎉 测试 Unicode ✅');
      await _saveNote(db, note);
      final found = await _getNoteById(db, 'e1');
      expect(found!.content, '🎉 测试 Unicode ✅');
    });

    test('DB-15 getCount 返回正确笔记数', () async {
      for (var i = 0; i < 5; i++) {
        await _saveNote(db, _makeNote(id: 'c$i'));
      }
      expect(await _getCount(db), 5);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 批量操作
  // ─────────────────────────────────────────────────────────
  group('DatabaseService — 批量操作', () {
    test('DB-16 批量插入 100 条笔记', () async {
      final batch = db.batch();
      for (var i = 0; i < 100; i++) {
        batch.insert(
          'notes',
          _makeNote(id: 'batch-$i', content: '批量笔记 $i').toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
      expect(await _getCount(db), 100);
    });

    test('DB-17 批量 upsert：已存在的更新，不存在的插入', () async {
      await _saveNote(db, _makeNote(id: 'exist1', content: '旧内容'));
      final batch = db.batch();
      batch.insert('notes', _makeNote(id: 'exist1', content: '新内容').toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      batch.insert('notes', _makeNote(id: 'new1', content: '全新笔记').toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit();
      expect(await _getCount(db), 2);
      final updated = await _getNoteById(db, 'exist1');
      expect(updated!.content, '新内容');
    });

    test('DB-18 deleteSyncedNotesNotIn 只删除已同步的不在列表中的笔记', () async {
      await _saveNote(db, _makeNote(id: 'keep1', isSynced: true));
      await _saveNote(db, _makeNote(id: 'keep2', isSynced: true));
      await _saveNote(db, _makeNote(id: 'del1', isSynced: true));
      await _saveNote(db, _makeNote(id: 'local1', isSynced: false));

      final serverIds = ['keep1', 'keep2'];
      final placeholders = List.filled(serverIds.length, '?').join(',');
      await db.delete(
        'notes',
        where: 'is_synced = 1 AND id NOT IN ($placeholders)',
        whereArgs: serverIds,
      );

      expect(await _getCount(db), 3); // keep1 + keep2 + local1
      final del1 = await _getNoteById(db, 'del1');
      expect(del1, isNull);
      final local1 = await _getNoteById(db, 'local1');
      expect(local1, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 查询过滤
  // ─────────────────────────────────────────────────────────
  group('DatabaseService — 查询过滤', () {
    test('DB-19 分页查询返回正确数量', () async {
      for (var i = 0; i < 10; i++) {
        await _saveNote(db, _makeNote(id: 'page-$i'));
      }
      final maps = await db.query('notes',
          orderBy: 'createdAt DESC', limit: 3, offset: 0);
      expect(maps.length, 3);
    });

    test('DB-20 按 rowStatus 过滤归档笔记', () async {
      await _saveNote(db, _makeNote(id: 'norm1', rowStatus: 'NORMAL'));
      await _saveNote(db, _makeNote(id: 'arch1', rowStatus: 'ARCHIVED'));
      await _saveNote(db, _makeNote(id: 'arch2', rowStatus: 'ARCHIVED'));

      final archived = await db.query('notes',
          where: 'rowStatus = ?', whereArgs: ['ARCHIVED']);
      expect(archived.length, 2);
    });
  });
}
