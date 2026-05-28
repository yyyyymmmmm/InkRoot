import 'dart:convert'; // Added for jsonEncode and jsonDecode

import 'package:flutter/foundation.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  factory DatabaseService() => _instance;

  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    return openDatabase(
      path,
      version: 8, // 🔥 版本8：添加annotations字段，支持批注功能
      onCreate: (Database db, int version) => createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) =>
          upgradeSchema(db, oldVersion: oldVersion, newVersion: newVersion),
    );
  }

  static const int schemaVersion = 8;

  /// Creates all tables/indexes for the latest schema.
  static Future<void> createSchema(Database db) async {
    // notes
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

    // reminder_notifications
    await db.execute('''
      CREATE TABLE reminder_notifications(
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        note_title TEXT NOT NULL,
        note_content TEXT NOT NULL,
        reminder_time TEXT NOT NULL,
        triggered_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        is_clicked INTEGER DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_reminder_triggered_at ON reminder_notifications(triggered_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_reminder_note_id ON reminder_notifications(note_id)
    ''');
  }

  /// Upgrades an existing DB to the latest schema.
  static Future<void> upgradeSchema(
    Database db, {
    required int oldVersion,
    required int newVersion,
  }) async {
    if (oldVersion < 1) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN is_synced INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN visibility TEXT DEFAULT "PRIVATE"',
      );
    }
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN resourceList TEXT DEFAULT "[]"',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN relations TEXT DEFAULT "[]"',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN reminder_time TEXT');
    }
    if (oldVersion < 7) {
      // v7: WebDAV last sync time
      await db.execute('ALTER TABLE notes ADD COLUMN last_sync_time TEXT');
    }
    if (oldVersion < 5) {
      // v5: reminder_notifications
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminder_notifications(
          id TEXT PRIMARY KEY,
          note_id TEXT NOT NULL,
          note_title TEXT NOT NULL,
          note_content TEXT NOT NULL,
          reminder_time TEXT NOT NULL,
          triggered_at TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          is_clicked INTEGER DEFAULT 0,
          FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_reminder_triggered_at ON reminder_notifications(triggered_at)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_reminder_note_id ON reminder_notifications(note_id)
      ''');
    }
    if (oldVersion < 6) {
      // v6: rowStatus
      await db.execute(
        'ALTER TABLE notes ADD COLUMN rowStatus TEXT DEFAULT "NORMAL"',
      );
    }
    if (oldVersion < 8) {
      // v8: annotations
      await db.execute(
        'ALTER TABLE notes ADD COLUMN annotations TEXT DEFAULT "[]"',
      );
    }
  }

  // 保存笔记到数据库
  Future<void> saveNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 更新笔记
  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // 删除笔记
  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有笔记
  /// 获取所有笔记（兼容旧代码）
  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('notes', orderBy: 'createdAt DESC');

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// 分页获取笔记（性能优化）
  Future<List<Note>> getNotesPaged({
    int page = 0,
    int pageSize = 50,
    String? orderBy,
  }) async {
    final db = await database;
    final offset = page * pageSize;

    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: orderBy ?? 'createdAt DESC',
      limit: pageSize,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  /// 获取笔记总数
  Future<int> getNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }

  // 根据ID获取笔记
  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Note.fromMap(maps[0]);
  }

  // 获取未同步的笔记
  Future<List<Note>> getUnsyncedNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // 更新笔记的服务器ID
  Future<void> updateNoteServerId(String localId, String serverId) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'id': serverId,
        'is_synced': 1,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // 标记笔记为已同步
  Future<void> markNoteSynced(String id) async {
    final db = await database;
    await db.update(
      'notes',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 清空所有笔记
  Future<void> clearAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }

  // 批量保存笔记（upsert：存在则更新，不存在则插入）
  Future<void> saveNotes(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();

    for (final note in notes) {
      batch.insert(
        'notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  /// 删除服务器已不存在的本地已同步笔记（安全清理，不影响未同步数据）
  Future<void> deleteSyncedNotesNotIn(List<String> serverIds) async {
    if (serverIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(serverIds.length, '?').join(',');
    await db.delete(
      'notes',
      where: 'is_synced = 1 AND id NOT IN ($placeholders)',
      whereArgs: serverIds,
    );
  }

  // 按标签获取笔记
  Future<List<Note>> getNotesByTag(String tag) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Note(
        id: map['id'],
        content: map['content'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        displayTime: map['displayTime'] != null
            ? DateTime.parse(map['displayTime'])
            : null,
        tags: map['tags'] != null && map['tags'].isNotEmpty
            ? map['tags'].split(',')
            : null,
        creator: map['creator'],
        isSynced: map['is_synced'] == 1,
        isPinned: map['isPinned'] == 1,
        visibility: map['visibility'] ?? 'PRIVATE',
      );
    });
  }

  // 搜索笔记
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return Note(
        id: map['id'],
        content: map['content'],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        displayTime: map['displayTime'] != null
            ? DateTime.parse(map['displayTime'])
            : null,
        tags: map['tags'] != null && map['tags'].isNotEmpty
            ? map['tags'].split(',')
            : null,
        creator: map['creator'],
        isSynced: map['is_synced'] == 1,
        isPinned: map['isPinned'] == 1,
        visibility: map['visibility'] ?? 'PRIVATE',
      );
    });
  }

  // 获取数据库大小（估算值，单位：字节）
  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(LENGTH(content)) FROM notes');
    return (Sqflite.firstIntValue(result) ?? 0) + 1024; // 添加一些额外的元数据大小
  }

  // 将笔记导出为JSON
  Future<String> exportNotesToJson() async {
    final notes = await getNotes();
    final jsonList = notes.map((note) => note.toJson()).toList();
    return jsonEncode({
      'version': '1.0',
      'exportTime': DateTime.now().toIso8601String(),
      'notes': jsonList,
    });
  }

  // 导入JSON格式的笔记
  Future<int> importNotesFromJson(
    String jsonData, {
    bool overwriteExisting = false,
    bool asNewNotes = true,
  }) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      if (!data.containsKey('notes') || data['notes'] is! List) {
        throw Exception('Invalid backup file format'); // 无效的备份文件格式
      }

      final List<dynamic> jsonNotes = data['notes'];
      final notes = <Note>[];

      for (final item in jsonNotes) {
        if (item is Map<String, dynamic>) {
          try {
            final note = Note.fromJson(item);
            notes.add(note);
          } catch (e) {
            debugPrint('解析笔记失败: $e');
          }
        }
      }

      return await _importNotes(
        notes,
        overwriteExisting: overwriteExisting,
        asNewNotes: asNewNotes,
      );
    } catch (e) {
      debugPrint('导入JSON笔记失败: $e');
      throw Exception('导入JSON笔记失败: $e');
    }
  }

  // 导入Markdown格式的笔记
  Future<int> importNotesFromMarkdown(
    List<String> markdownFiles,
    List<String> contents,
  ) async {
    if (markdownFiles.length != contents.length) {
      throw Exception('File name and content count mismatch'); // 文件名和内容数量不匹配
    }

    final notes = <Note>[];
    final now = DateTime.now();

    for (var i = 0; i < markdownFiles.length; i++) {
      final fileName = markdownFiles[i];
      final content = contents[i];
      final tags = Note.extractTagsFromContent(content);

      notes.add(
        Note(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}_$i',
          content: content,
          createdAt: now,
          updatedAt: now,
          tags: tags,
        ),
      );
    }

    return _importNotes(notes);
  }

  // 导入纯文本格式的笔记
  Future<int> importNotesFromText(
    List<String> textFiles,
    List<String> contents,
  ) async {
    if (textFiles.length != contents.length) {
      throw Exception('File name and content count mismatch'); // 文件名和内容数量不匹配
    }

    final notes = <Note>[];
    final now = DateTime.now();

    for (var i = 0; i < textFiles.length; i++) {
      final fileName = textFiles[i];
      final content = contents[i];
      final tags = Note.extractTagsFromContent(content);

      notes.add(
        Note(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}_$i',
          content: content,
          createdAt: now,
          updatedAt: now,
          tags: tags,
        ),
      );
    }

    return _importNotes(notes);
  }

  // 内部方法：导入笔记通用逻辑
  Future<int> _importNotes(
    List<Note> notes, {
    bool overwriteExisting = false,
    bool asNewNotes = true,
  }) async {
    final db = await database;
    var imported = 0;

    await db.transaction((txn) async {
      for (final note in notes) {
        try {
          if (asNewNotes) {
            // 作为新笔记导入，使用新ID
            final newNote = note.copyWith(
              id: 'local_${DateTime.now().millisecondsSinceEpoch}_$imported',
              isSynced: false,
            );

            await txn.insert(
              'notes',
              newNote.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            imported++;
          } else if (overwriteExisting) {
            // 检查是否存在相同ID的笔记
            final exists = Sqflite.firstIntValue(
                  await txn.rawQuery(
                    'SELECT COUNT(*) FROM notes WHERE id = ?',
                    [note.id],
                  ),
                ) ??
                0;

            if (exists > 0) {
              // 存在则更新
              await txn.update(
                'notes',
                note.toMap(),
                where: 'id = ?',
                whereArgs: [note.id],
              );
            } else {
              // 不存在则插入
              await txn.insert(
                'notes',
                note.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            imported++;
          } else {
            // 检查是否存在相同ID的笔记
            final exists = Sqflite.firstIntValue(
                  await txn.rawQuery(
                    'SELECT COUNT(*) FROM notes WHERE id = ?',
                    [note.id],
                  ),
                ) ??
                0;

            // 只有不存在时才插入
            if (exists == 0) {
              await txn.insert(
                'notes',
                note.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
              imported++;
            }
          }
        } catch (e) {
          debugPrint('导入单条笔记失败: $e');
        }
      }
    });

    return imported;
  }

  // 批量更新笔记（增量同步专用）
  Future<void> updateNotesBatch(List<Note> notes) async {
    if (notes.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final note in notes) {
        batch.update(
          'notes',
          note.toMap(),
          where: 'id = ?',
          whereArgs: [note.id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // 批量插入笔记（增量同步专用）
  Future<void> insertNotesBatch(List<Note> notes) async {
    if (notes.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final note in notes) {
        batch.insert(
          'notes',
          note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
