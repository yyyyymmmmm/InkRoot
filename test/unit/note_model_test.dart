// ============================================================
// 第一档测试 · Note 数据模型
// 覆盖 v0.21 / v0.22+ / v0.27+ API 格式兼容性以及本地 SQLite 读写
// ============================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';

void main() {
  // ─────────────────────────────────────────────────────────
  // Note.fromJson — v0.21.0 格式 (createdTs / updatedTs)
  // ─────────────────────────────────────────────────────────
  group('Note.fromJson — v0.21.0 格式', () {
    test('TC-01 能正确解析 int id 和秒级时间戳', () {
      final json = {
        'id': 42,
        'content': '测试内容',
        'createdTs': 1700000000,
        'updatedTs': 1700000100,
        'rowStatus': 'NORMAL',
        'visibility': 'PRIVATE',
      };
      final note = Note.fromJson(json);

      expect(note.id, '42');
      expect(note.content, '测试内容');
      expect(note.rowStatus, 'NORMAL');
      expect(note.visibility, 'PRIVATE');
      // 秒级时间戳 → 毫秒
      expect(
        note.createdAt.millisecondsSinceEpoch,
        1700000000 * 1000,
      );
    });

    test('TC-02 resourceList 使用旧字段名 resourceList', () {
      final json = {
        'id': 1,
        'content': '',
        'createdTs': 1700000000,
        'updatedTs': 1700000000,
        'resourceList': [
          {'id': 'res1', 'filename': 'image.png'},
        ],
      };
      final note = Note.fromJson(json);
      expect(note.resourceList.length, 1);
      expect(note.resourceList[0]['id'], 'res1');
    });

    test('TC-03 rowStatus ARCHIVED 正确解析', () {
      final json = {
        'id': 7,
        'content': '',
        'createdTs': 1700000000,
        'updatedTs': 1700000000,
        'rowStatus': 'ARCHIVED',
      };
      final note = Note.fromJson(json);
      expect(note.rowStatus, 'ARCHIVED');
      expect(note.isArchived, isTrue);
      expect(note.isNormal, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────
  // Note.fromJson — v0.22.0+ 格式 (createTime / updateTime)
  // ─────────────────────────────────────────────────────────
  group('Note.fromJson — v0.22.0+ 格式', () {
    test('TC-04 name 字段形如 memos/123 时提取 id=123', () {
      final json = {
        'name': 'memos/123',
        'content': '新版内容',
        'createTime': '2024-05-01T10:00:00Z',
        'updateTime': '2024-05-01T11:00:00Z',
        'visibility': 'PUBLIC',
        'tags': ['flutter', 'dart'],
        'pinned': true,
      };
      final note = Note.fromJson(json);

      expect(note.id, '123');
      expect(note.content, '新版内容');
      expect(note.visibility, 'PUBLIC');
      expect(note.tags, containsAll(['flutter', 'dart']));
      expect(note.isPinned, isTrue);
    });

    test('TC-05 resources 字段（v0.22–v0.26）正确解析', () {
      final json = {
        'name': 'memos/5',
        'content': '',
        'createTime': '2024-05-01T10:00:00Z',
        'updateTime': '2024-05-01T10:00:00Z',
        'resources': [
          {'id': 'r1', 'filename': 'photo.jpg'},
          {'id': 'r2', 'filename': 'doc.pdf'},
        ],
      };
      final note = Note.fromJson(json);
      expect(note.resourceList.length, 2);
    });

    test('TC-06 tags 列表为空时从 content 提取标签', () {
      final json = {
        'name': 'memos/9',
        'content': '今天学习 #Flutter #Dart 真好玩',
        'createTime': '2024-05-01T10:00:00Z',
        'updateTime': '2024-05-01T10:00:00Z',
        'tags': <String>[],
      };
      final note = Note.fromJson(json);
      expect(note.tags, containsAll(['Flutter', 'Dart']));
    });

    test('TC-07 relations 字段正确解析', () {
      final json = {
        'name': 'memos/10',
        'content': '',
        'createTime': '2024-01-01T00:00:00Z',
        'updateTime': '2024-01-01T00:00:00Z',
        'relations': [
          {'type': 'COMMENT', 'relatedMemoId': 'memos/11'},
        ],
      };
      final note = Note.fromJson(json);
      expect(note.relations.length, 1);
    });

    test('TC-08 缺少 updateTime 时使用 createTime', () {
      final json = {
        'name': 'memos/20',
        'content': '',
        'createTime': '2024-03-15T08:00:00Z',
      };
      final note = Note.fromJson(json);
      expect(note.updatedAt, equals(note.createdAt));
    });
  });

  // ─────────────────────────────────────────────────────────
  // Note.fromJson — v0.27.0+ 格式 (attachments / state)
  // ─────────────────────────────────────────────────────────
  group('Note.fromJson — v0.27.0+ 格式', () {
    test('TC-09 attachments 字段优先于 resources/resourceList', () {
      final json = {
        'name': 'memos/30',
        'content': '',
        'createTime': '2024-06-01T00:00:00Z',
        'updateTime': '2024-06-01T00:00:00Z',
        'attachments': [
          {'id': 'att1', 'filename': 'file.png'},
        ],
        'resources': [
          {'id': 'old', 'filename': 'old.png'},
        ],
      };
      final note = Note.fromJson(json);
      // attachments 优先
      expect(note.resourceList.length, 1);
      expect(note.resourceList[0]['id'], 'att1');
    });

    test('TC-10 state 字段替代 rowStatus', () {
      final json = {
        'name': 'memos/31',
        'content': '',
        'createTime': '2024-06-01T00:00:00Z',
        'updateTime': '2024-06-01T00:00:00Z',
        'state': 'ARCHIVED',
      };
      final note = Note.fromJson(json);
      expect(note.rowStatus, 'ARCHIVED');
      expect(note.isArchived, isTrue);
    });

    test('TC-11 state=NORMAL 正确识别', () {
      final json = {
        'name': 'memos/32',
        'content': '',
        'createTime': '2024-06-01T00:00:00Z',
        'updateTime': '2024-06-01T00:00:00Z',
        'state': 'NORMAL',
      };
      final note = Note.fromJson(json);
      expect(note.isNormal, isTrue);
    });

    test('TC-12 用户名格式 users/alice 作为 creator', () {
      final json = {
        'name': 'memos/50',
        'content': '',
        'createTime': '2024-06-01T00:00:00Z',
        'updateTime': '2024-06-01T00:00:00Z',
        'creator': 'users/alice',
      };
      final note = Note.fromJson(json);
      expect(note.creator, 'users/alice');
    });
  });

  // ─────────────────────────────────────────────────────────
  // Note.fromMap — 本地 SQLite 读取
  // ─────────────────────────────────────────────────────────
  group('Note.fromMap — SQLite 行解析', () {
    Map<String, dynamic> _baseMap() => {
          'id': 'local-001',
          'content': '本地笔记',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-02T00:00:00.000',
          'displayTime': '2024-01-01T12:00:00.000',
          'tags': 'flutter,dart',
          'creator': 'user1',
          'is_synced': 1,
          'isPinned': 0,
          'visibility': 'PRIVATE',
          'rowStatus': 'NORMAL',
          'resourceList': '[]',
          'relations': '[]',
          'annotations': '[]',
          'reminder_time': null,
          'last_sync_time': null,
        };

    test('TC-13 基础字段正确解析', () {
      final note = Note.fromMap(_baseMap());
      expect(note.id, 'local-001');
      expect(note.content, '本地笔记');
      expect(note.isSynced, isTrue);
      expect(note.isPinned, isFalse);
    });

    test('TC-14 tags 逗号分隔正确还原为列表', () {
      final note = Note.fromMap(_baseMap());
      expect(note.tags, ['flutter', 'dart']);
    });

    test('TC-15 resourceList JSON 字符串正确反序列化', () {
      final map = _baseMap();
      map['resourceList'] =
          jsonEncode([{'id': 'img1', 'filename': 'a.png'}]);
      final note = Note.fromMap(map);
      expect(note.resourceList.length, 1);
      expect(note.resourceList[0]['id'], 'img1');
    });

    test('TC-16 isPinned=1 → true', () {
      final map = _baseMap()..['isPinned'] = 1;
      final note = Note.fromMap(map);
      expect(note.isPinned, isTrue);
    });

    test('TC-17 reminderTime 正确解析', () {
      final map = _baseMap()
        ..['reminder_time'] = '2025-01-01T09:00:00.000';
      final note = Note.fromMap(map);
      expect(note.reminderTime, isNotNull);
      expect(note.reminderTime!.hour, 9);
    });
  });

  // ─────────────────────────────────────────────────────────
  // Note.toMap — 序列化
  // ─────────────────────────────────────────────────────────
  group('Note.toMap — 序列化', () {
    Note _makeNote() => Note(
          id: 'n1',
          content: '内容',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
          tags: ['tag1', 'tag2'],
          isSynced: true,
          isPinned: true,
          visibility: 'PUBLIC',
          rowStatus: 'NORMAL',
        );

    test('TC-18 tags 列表序列化为逗号字符串', () {
      final map = _makeNote().toMap();
      expect(map['tags'], 'tag1,tag2');
    });

    test('TC-19 is_synced 布尔值序列化为整型', () {
      final map = _makeNote().toMap();
      expect(map['is_synced'], 1);
    });

    test('TC-20 isPinned 序列化为整型 1', () {
      final map = _makeNote().toMap();
      expect(map['isPinned'], 1);
    });

    test('TC-21 resourceList 默认序列化为 "[]"', () {
      final map = _makeNote().toMap();
      expect(map['resourceList'], '[]');
    });
  });

  // ─────────────────────────────────────────────────────────
  // Note.copyWith
  // ─────────────────────────────────────────────────────────
  group('Note.copyWith', () {
    final original = Note(
      id: 'orig',
      content: '原始内容',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      isSynced: false,
      visibility: 'PRIVATE',
    );

    test('TC-22 copyWith 修改内容后原对象不变', () {
      final copy = original.copyWith(content: '新内容');
      expect(copy.content, '新内容');
      expect(original.content, '原始内容');
    });

    test('TC-23 clearReminderTime=true 清除提醒时间', () {
      final withReminder = original.copyWith(
        reminderTime: DateTime(2025, 1, 1),
      );
      final cleared = withReminder.copyWith(clearReminderTime: true);
      expect(cleared.reminderTime, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // Note.extractTagsFromContent
  // ─────────────────────────────────────────────────────────
  group('Note.extractTagsFromContent', () {
    test('TC-24 URL 中的 # 不被识别为标签', () {
      const content = '看这个网址 https://example.com/page#section';
      final tags = Note.extractTagsFromContent(content);
      expect(tags, isEmpty);
    });

    test('TC-25 ## 标题不被识别为标签', () {
      const content = '## 这是标题\n#正式标签';
      final tags = Note.extractTagsFromContent(content);
      expect(tags, contains('正式标签'));
      // 不包含 Markdown 标题产生的假标签
      expect(tags.any((t) => t.startsWith('#')), isFalse);
    });
  });
}
