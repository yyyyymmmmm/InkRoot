import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:inkroot/models/annotation_model.dart';

class Note {
  // 提醒时间

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    DateTime? displayTime,
    List<String>? tags,
    String? creator,
    this.isSynced = false,
    this.isPinned = false,
    this.visibility = 'PRIVATE',
    this.rowStatus = 'NORMAL',
    List<Map<String, dynamic>>? resourceList,
    List<Map<String, dynamic>>? relations,
    List<Annotation>? annotations,
    this.reminderTime,
    this.lastSyncTime,
  })  : displayTime = displayTime ?? updatedAt,
        tags = tags ?? [],
        creator = creator ?? 'local',
        resourceList = resourceList ?? [],
        relations = relations ?? [],
        annotations = annotations ?? [];

  factory Note.fromMap(Map<String, dynamic> map) {
    // if (kDebugMode) debugPrint('Note.fromMap: 数据库数据: ${map.toString()}');

    // 处理resourceList
    var resourceList = <Map<String, dynamic>>[];
    if (map['resourceList'] != null && map['resourceList'].isNotEmpty) {
      // if (kDebugMode) debugPrint('Note.fromMap: resourceList原始数据: ${map['resourceList']}');
      try {
        final decoded = json.decode(map['resourceList']);
        resourceList = List<Map<String, dynamic>>.from(decoded);
        // if (kDebugMode) debugPrint('Note.fromMap: resourceList解析成功，长度: ${resourceList.length}');
      } catch (e) {
        if (kDebugMode) debugPrint('Note.fromMap: 解析resourceList失败: $e');
      }
    } else {
      // if (kDebugMode) debugPrint('Note.fromMap: resourceList为空或null');
    }

    // 处理relations
    var relations = <Map<String, dynamic>>[];
    if (map['relations'] != null && map['relations'].isNotEmpty) {
      try {
        final decoded = json.decode(map['relations']);
        relations = List<Map<String, dynamic>>.from(decoded);
      } catch (e) {
        if (kDebugMode) debugPrint('Note.fromMap: 解析relations失败: $e');
      }
    }

    // 处理annotations（批注）
    var annotations = <Annotation>[];
    if (map['annotations'] != null && map['annotations'].isNotEmpty) {
      annotations = AnnotationList.fromJsonString(map['annotations']);
    }

    final note = Note(
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
      rowStatus: map['rowStatus'] ?? 'NORMAL',
      resourceList: resourceList,
      relations: relations,
      annotations: annotations,
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'])
          : null,
      lastSyncTime: map['last_sync_time'] != null
          ? DateTime.parse(map['last_sync_time'])
          : null,
    );

    // if (kDebugMode) debugPrint('Note.fromMap: 创建的Note resourceList长度: ${note.resourceList.length}');
    return note;
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    // ── ID ────────────────────────────────────────────────────────────────
    // v0.21.0: int/string 'id' field
    // v0.22.0+: string 'name' field like "memos/123"
    final rawId = json['id'] ?? json['name'] ?? '';
    final id = rawId.toString().contains('/')
        ? rawId.toString().split('/').last
        : rawId.toString();

    // ── Timestamps ────────────────────────────────────────────────────────
    // v0.21.0: 'createdTs'/'updatedTs' – Unix seconds (int)
    // v0.22.0+: 'createTime'/'updateTime' – ISO-8601 string
    DateTime createdAt;
    DateTime updatedAt;
    if (json['createdTs'] != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch((json['createdTs'] as int) * 1000);
      updatedAt = DateTime.fromMillisecondsSinceEpoch(((json['updatedTs'] ?? json['createdTs']) as int) * 1000);
    } else {
      createdAt = DateTime.tryParse(json['createTime']?.toString() ?? '') ?? DateTime.now();
      updatedAt = DateTime.tryParse(json['updateTime']?.toString() ?? '') ?? createdAt;
    }

    // ── Display time ──────────────────────────────────────────────────────
    DateTime? displayTime;
    if (json['displayTime'] != null) {
      displayTime = DateTime.tryParse(json['displayTime'].toString());
    }

    // ── Resources / Attachments ───────────────────────────────────────────
    // v0.21.0: 'resourceList'
    // v0.22.0–v0.26.x: 'resources'
    // v0.27.0+: 'attachments'  (resource_service → attachment_service rename)
    var resourceList = <Map<String, dynamic>>[];
    final rawResources =
        json['attachments'] ?? json['resourceList'] ?? json['resources'];
    if (rawResources != null) {
      resourceList = List<Map<String, dynamic>>.from(rawResources as List);
    }

    // ── Relations ─────────────────────────────────────────────────────────
    // v0.21.0: 'relationList'   v0.22.0+: 'relations'
    var relations = <Map<String, dynamic>>[];
    final rawRelations = json['relationList'] ?? json['relations'];
    if (rawRelations != null) {
      relations = List<Map<String, dynamic>>.from(rawRelations as List);
    }

    // ── Row status / State ────────────────────────────────────────────────
    // v0.21.0–v0.26.x: 'rowStatus' (ROW_STATUS_UNSPECIFIED / NORMAL / ARCHIVED)
    // v0.27.0+: 'state' (STATE_UNSPECIFIED / NORMAL / ARCHIVED)
    // Both use the same string values NORMAL / ARCHIVED, so we just unify them.
    final rowStatus =
        json['rowStatus']?.toString() ?? json['state']?.toString() ?? 'NORMAL';

    // ── Visibility ────────────────────────────────────────────────────────
    // Both old and new API use enum string names: PRIVATE / PROTECTED / PUBLIC
    final visibility = json['visibility']?.toString() ?? 'PRIVATE';

    // ── Tags ──────────────────────────────────────────────────────────────
    // v0.22.0+: 'tags' is List<String>; v0.21.0: absent (extracted from content)
    final rawTags = json['tags'];
    final List<String> tags = rawTags != null
        ? List<String>.from(rawTags as List)
        : [];

    // ── Creator ───────────────────────────────────────────────────────────
    // v0.21.0: 'creatorId' (int) or 'creator' (string username)
    // v0.22.0+: 'creator' = "users/{id}"
    final creator = json['creatorId']?.toString() ?? json['creator']?.toString();

    return Note(
      id: id,
      content: json['content']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      displayTime: displayTime,
      tags: tags.isNotEmpty ? tags : Note.extractTagsFromContent(json['content']?.toString() ?? ''),
      creator: creator,
      isSynced: true,
      isPinned: json['pinned'] as bool? ?? false,
      visibility: visibility,
      rowStatus: rowStatus,
      resourceList: resourceList,
      relations: relations,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.tryParse(json['lastSyncTime'].toString())
          : null,
    );
  }
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime displayTime;
  final List<String> tags;
  final String creator;
  bool isSynced;
  final bool isPinned;
  final String visibility;
  final String rowStatus; // 行状态：NORMAL, ARCHIVED
  final List<Map<String, dynamic>> resourceList; // 添加资源列表
  final List<Map<String, dynamic>> relations; // 添加关系列表
  final List<Annotation> annotations; // 批注列表
  final DateTime? reminderTime;
  final DateTime? lastSyncTime; // WebDAV同步时间戳

  Note copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? displayTime,
    List<String>? tags,
    String? creator,
    bool? isSynced,
    bool? isPinned,
    String? visibility,
    String? rowStatus,
    List<Map<String, dynamic>>? resourceList,
    List<Map<String, dynamic>>? relations,
    List<Annotation>? annotations,
    DateTime? reminderTime,
    bool clearReminderTime = false,
    DateTime? lastSyncTime,
  }) =>
      Note(
        id: id ?? this.id,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        displayTime: displayTime ?? this.displayTime,
        tags: tags ?? this.tags,
        creator: creator ?? this.creator,
        isSynced: isSynced ?? this.isSynced,
        isPinned: isPinned ?? this.isPinned,
        visibility: visibility ?? this.visibility,
        rowStatus: rowStatus ?? this.rowStatus,
        resourceList: resourceList ?? this.resourceList,
        relations: relations ?? this.relations,
        annotations: annotations ?? this.annotations,
        reminderTime:
            clearReminderTime ? null : (reminderTime ?? this.reminderTime),
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'displayTime': displayTime.toIso8601String(),
        'tags': tags.join(','),
        'creator': creator,
        'is_synced': isSynced ? 1 : 0,
        'isPinned': isPinned ? 1 : 0,
        'visibility': visibility,
        'rowStatus': rowStatus,
        'resourceList': json.encode(resourceList), // 将resourceList序列化为JSON字符串
        'relations': json.encode(relations), // 将relations序列化为JSON字符串
        'annotations': AnnotationList.toJsonString(annotations), // 将批注序列化为JSON字符串
        'reminder_time': reminderTime?.toIso8601String(),
        'last_sync_time': lastSyncTime?.toIso8601String(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdTs': createdAt.millisecondsSinceEpoch ~/
            1000, // 🔧 转换为秒级时间戳，与 Memos API 一致
        'updatedTs': updatedAt.millisecondsSinceEpoch ~/ 1000, // 🔧 转换为秒级时间戳
        'displayTime': displayTime.toIso8601String(),
        'tags': tags,
        'creator': creator,
        'pinned': isPinned,
        'visibility': visibility,
        'rowStatus': rowStatus,
        'resourceList': resourceList, // ✅ 包含图片/资源
        'relationList': relations, // ✅ 包含关系
        'reminderTime': reminderTime?.toIso8601String(), // ✅ 包含提醒时间
        'lastSyncTime': lastSyncTime?.toIso8601String(), // ✅ 包含同步时间
      };

  // 从笔记内容中提取标签（改进版，排除URL中的#）
  static List<String> extractTagsFromContent(String content) {
    // 使用统一的标签提取逻辑
    return _extractTagsImproved(content);
  }

  // 改进的标签提取逻辑（参考Obsidian/Notion/Logseq）
  static List<String> _extractTagsImproved(String content) {
    // 🎯 改进的标签识别规则：
    // - 排除URL中的#
    // - 前缀要求：#前面不能是字母、数字、下划线、冒号、斜杠
    // - 排除连续##（Markdown标题）
    final tagRegex = RegExp(
      r'(?<![\w:/])(?!##)#([^\s\[\],，、;；:：！!？?\n#]+)',
      unicode: true,
    );

    final tags = <String>[];
    final lines = content.split('\n');

    for (final line in lines) {
      // 如果这行包含URL，需要排除URL中的#
      if (line.contains(RegExp(r'[a-zA-Z]+://'))) {
        // 找出所有URL的位置范围
        final urlRegex = RegExp(r'[a-zA-Z]+://[^\s\)]+');
        final urlMatches = urlRegex.allMatches(line).toList();
        final urlRanges = urlMatches.map((m) => [m.start, m.end]).toList();

        // 找出所有标签，但排除在URL范围内的
        final tagMatches = tagRegex.allMatches(line);
        for (final match in tagMatches) {
          var inUrl = false;
          for (final range in urlRanges) {
            if (match.start >= range[0] && match.end <= range[1]) {
              inUrl = true;
              break;
            }
          }
          if (!inUrl) {
            tags.add(match.group(1)!);
          }
        }
      } else {
        // 没有URL的行，直接提取所有标签
        tags.addAll(
          tagRegex.allMatches(line).map((match) => match.group(1)!),
        );
      }
    }

    return tags;
  }

  // 判断可见性
  bool get isPrivate => visibility == 'PRIVATE';
  bool get isProtected => visibility == 'PROTECTED';
  bool get isPublic => visibility == 'PUBLIC';
  bool get isArchived => rowStatus == 'ARCHIVED';
  bool get isNormal => rowStatus == 'NORMAL';
}
