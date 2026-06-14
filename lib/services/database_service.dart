import 'dart:convert'; // Added for jsonEncode and jsonDecode
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  factory DatabaseService() => _instance;

  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool _ffiInitialized = false;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        _ffiInitialized = true;
      }
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = !kIsWeb && (Platform.isWindows || Platform.isLinux)
        ? await _desktopDatabaseDirectory()
        : await getDatabasesPath();
    final path = join(dbPath, AppConfig.databaseName);

    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) => createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) =>
          upgradeSchema(db, oldVersion: oldVersion, newVersion: newVersion),
    );
  }

  Future<String> _desktopDatabaseDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory =
        Directory(join(supportDirectory.path, 'databases'));
    if (!await databaseDirectory.exists()) {
      await databaseDirectory.create(recursive: true);
    }
    return databaseDirectory.path;
  }

  static const int schemaVersion = AppConfig.databaseVersion;

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
    await db.transaction((txn) async {
      await txn.delete('reminder_notifications');
      await txn.delete('notes');
    });
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

  /// 原子替换全部笔记。用于恢复备份，避免先清空后逐条写入导致半恢复状态。
  Future<void> replaceAllNotes(List<Note> notes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('reminder_notifications');
      await txn.delete('notes');
      for (final note in notes) {
        await txn.insert(
          'notes',
          note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 删除服务器已不存在的本地已同步笔记（安全清理，不影响未同步数据）
  Future<void> deleteSyncedNotesNotIn(List<String> serverIds) async {
    if (serverIds.isEmpty) {
      return;
    }
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

    return maps.map(Note.fromMap).toList();
  }

  // 搜索笔记
  Future<List<Note>> searchNotes(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final db = await database;
    final pattern = '%$normalizedQuery%';
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'content LIKE ? OR tags LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'createdAt DESC',
    );

    return maps.map(Note.fromMap).toList();
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

  /// 将单条笔记导出为带元数据的 Markdown。
  ///
  /// 正文仍是用户可读的 Markdown；顶部 front matter 让本应用重新导入时能恢复
  /// 创建时间、更新时间、标签、提醒、批注等本地字段。
  String exportNoteToMarkdown(Note note) {
    final metadata = <String, dynamic>{
      'inkrootNote': true,
      'id': note.id,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'displayTime': note.displayTime.toIso8601String(),
      'tags': note.tags,
      'creator': note.creator,
      'isSynced': note.isSynced,
      'isPinned': note.isPinned,
      'visibility': note.visibility,
      'rowStatus': note.rowStatus,
      'resourceList': note.resourceList,
      'relations': note.relations,
      'annotations':
          note.annotations.map((annotation) => annotation.toJson()).toList(),
      'reminderTime': note.reminderTime?.toIso8601String(),
      'lastSyncTime': note.lastSyncTime?.toIso8601String(),
    };

    final buffer = StringBuffer('---\n');
    metadata.forEach((key, value) {
      buffer.writeln('$key: ${jsonEncode(value)}');
    });
    buffer.writeln('---');
    buffer.write(note.content);
    return buffer.toString();
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
          } on Object catch (e) {
            debugPrint('解析笔记失败: $e');
          }
        }
      }

      return await _importNotes(
        notes,
        overwriteExisting: overwriteExisting,
        asNewNotes: asNewNotes,
      );
    } on Object catch (e) {
      debugPrint('导入JSON笔记失败: $e');
      throw Exception('导入JSON笔记失败: $e');
    }
  }

  // 导入Markdown格式的笔记
  Future<int> importNotesFromMarkdown(
    List<String> markdownFiles,
    List<String> contents, {
    bool overwriteExisting = false,
    bool asNewNotes = true,
  }) async {
    if (markdownFiles.length != contents.length) {
      throw Exception('File name and content count mismatch'); // 文件名和内容数量不匹配
    }

    final notes = <Note>[];
    for (var i = 0; i < markdownFiles.length; i++) {
      final content = contents[i];
      final backupNote = _tryParseMarkdownBackupNote(content, index: i);
      if (backupNote != null) {
        notes.add(backupNote);
        continue;
      }

      final importedAt = DateTime.now().add(Duration(milliseconds: i));
      final tags = Note.extractTagsFromContent(content);

      notes.add(
        Note(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}_$i',
          content: content,
          createdAt: importedAt,
          updatedAt: importedAt,
          tags: tags,
        ),
      );
    }

    return _importNotes(
      notes,
      overwriteExisting: overwriteExisting,
      asNewNotes: asNewNotes,
    );
  }

  // 导入纯文本格式的笔记
  Future<int> importNotesFromText(
    List<String> textFiles,
    List<String> contents, {
    bool overwriteExisting = false,
    bool asNewNotes = true,
  }) async {
    if (textFiles.length != contents.length) {
      throw Exception('File name and content count mismatch'); // 文件名和内容数量不匹配
    }

    final notes = <Note>[];

    for (var i = 0; i < textFiles.length; i++) {
      final content = contents[i];
      final backupNotes = _tryParseTextBackupNotes(content);
      if (backupNotes.isNotEmpty) {
        notes.addAll(backupNotes);
        continue;
      }

      final importedAt = DateTime.now().add(Duration(milliseconds: i));
      final tags = Note.extractTagsFromContent(content);

      notes.add(
        Note(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}_$i',
          content: content,
          createdAt: importedAt,
          updatedAt: importedAt,
          tags: tags,
        ),
      );
    }

    return _importNotes(
      notes,
      overwriteExisting: overwriteExisting,
      asNewNotes: asNewNotes,
    );
  }

  Note? _tryParseMarkdownBackupNote(String content, {required int index}) {
    final match = RegExp(
      r'^---\r?\n(.*?)\r?\n---\r?\n?',
      dotAll: true,
    ).firstMatch(content);
    if (match == null) {
      return null;
    }

    final metadata = <String, dynamic>{};
    for (final line in const LineSplitter().convert(match.group(1) ?? '')) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      final key = line.substring(0, separator).trim();
      final rawValue = line.substring(separator + 1).trim();
      if (key.isEmpty) {
        continue;
      }
      try {
        metadata[key] = jsonDecode(rawValue);
      } on Object {
        metadata[key] = rawValue;
      }
    }

    if (metadata['inkrootNote'] != true) {
      return null;
    }

    final body = content.substring(match.end);
    final json = <String, dynamic>{
      ...metadata,
      'id': metadata['id']?.toString().isNotEmpty ?? false
          ? metadata['id']
          : 'local_${DateTime.now().millisecondsSinceEpoch}_$index',
      'content': body,
    };

    return Note.fromJson(json);
  }

  List<Note> _tryParseTextBackupNotes(String content) {
    final notes = <Note>[];
    final blockRegex = RegExp(
      r'--- 笔记 (.*?) ---\r?\n'
      r'创建时间: (.*?)\r?\n'
      r'更新时间: (.*?)\r?\n'
      r'标签: (.*?)\r?\n'
      r'内容:\r?\n'
      r'(.*?)(?:\r?\n-{20,}\r?\n|$)',
      dotAll: true,
    );

    for (final match in blockRegex.allMatches(content)) {
      final id = match.group(1)?.trim();
      final createdAt = _parseBackupDate(match.group(2));
      final updatedAt = _parseBackupDate(match.group(3));
      final rawTags = match.group(4)?.trim() ?? '';
      final body = match.group(5) ?? '';
      if (createdAt == null || updatedAt == null || id == null || id.isEmpty) {
        continue;
      }

      final tags = rawTags.isEmpty
          ? Note.extractTagsFromContent(body)
          : rawTags
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();
      notes.add(
        Note(
          id: id,
          content: body.trimRight(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          tags: tags,
        ),
      );
    }

    return notes;
  }

  DateTime? _parseBackupDate(String? rawDate) {
    if (rawDate == null) {
      return null;
    }
    final value = rawDate.trim();
    return DateTime.tryParse(value) ??
        DateTime.tryParse(value.replaceFirst(' ', 'T'));
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
              relations: const [],
              clearLastSyncTime: true,
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
        } on Object catch (e) {
          debugPrint('导入单条笔记失败: $e');
        }
      }
    });

    return imported;
  }

  // 批量更新笔记（增量同步专用）
  Future<void> updateNotesBatch(List<Note> notes) async {
    if (notes.isEmpty) {
      return;
    }

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
    if (notes.isEmpty) {
      return;
    }

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
