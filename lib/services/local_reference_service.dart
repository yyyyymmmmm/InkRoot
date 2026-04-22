import 'package:flutter/foundation.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/unified_reference_manager.dart';

/// 本地引用关系管理服务
/// 支持离线创建、管理和查看引用关系，在线时自动同步
class LocalReferenceService {
  LocalReferenceService._internal();
  static final LocalReferenceService _instance =
      LocalReferenceService._internal();
  static LocalReferenceService get instance => _instance;

  final DatabaseService _databaseService = DatabaseService();
  AppProvider? _appProvider;

  /// 创建引用关系（离线）
  /// 在本地数据库中创建引用关系，标记为未同步
  Future<bool> createReference(
    String fromNoteId,
    String toNoteId, {
    String type = 'REFERENCE',
  }) async {
    try {
      // 🔧 修复：使用UnifiedReferenceManager创建完整的双向引用关系
      final success =
          await UnifiedReferenceManager().createReference(fromNoteId, toNoteId);

      if (success) {
      } else {}

      return success;
    } catch (e) {
      return false;
    }
  }

  /// 删除引用关系（离线）
  Future<bool> removeReference(
    String fromNoteId,
    String toNoteId, {
    String type = 'REFERENCE',
  }) async {
    try {
      // 获取源笔记
      final fromNote = await _databaseService.getNoteById(fromNoteId);
      if (fromNote == null) {
        return false;
      }

      // 过滤掉要删除的关系
      final updatedRelations = fromNote.relations.where((relation) {
        final memoId = relation['memoId']?.toString();
        final relatedMemoId = relation['relatedMemoId']?.toString();
        final relationType = relation['type']?.toString();

        return !(memoId == fromNoteId &&
            relatedMemoId == toNoteId &&
            (relationType == type || relationType == type.toLowerCase()));
      }).toList();

      // 如果有变化，更新笔记
      if (updatedRelations.length != fromNote.relations.length) {
        final updatedNote = fromNote.copyWith(
          relations: updatedRelations,
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await _databaseService.updateNote(updatedNote);

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取笔记的所有引用关系
  Future<Map<String, List<Map<String, dynamic>>>> getNoteReferences(
    String noteId,
  ) async {
    try {
      final note = await _databaseService.getNoteById(noteId);
      if (note == null) {
        return {'outgoing': [], 'incoming': []};
      }

      // 获取所有笔记用于查找反向引用
      final allNotes = await _databaseService.getNotes();

      // 分类引用关系
      final outgoingRefs = <Map<String, dynamic>>[]; // 当前笔记引用的其他笔记
      final incomingRefs = <Map<String, dynamic>>[]; // 其他笔记引用当前笔记

      // 处理当前笔记的直接引用
      for (final relation in note.relations) {
        final type = relation['type'];
        if (type == 'REFERENCE' || type == 1) {
          final memoId = relation['memoId']?.toString();
          final relatedMemoId = relation['relatedMemoId']?.toString();

          if (memoId == noteId) {
            outgoingRefs.add(relation);
          }
        }
      }

      // 查找其他笔记中引用当前笔记的关系
      for (final otherNote in allNotes) {
        if (otherNote.id == noteId) continue;

        for (final relation in otherNote.relations) {
          final type = relation['type'];
          if (type == 'REFERENCE' || type == 1) {
            final relatedMemoId = relation['relatedMemoId']?.toString();

            if (relatedMemoId == noteId) {
              incomingRefs.add(relation);
            }
          }
        }
      }

      return {
        'outgoing': outgoingRefs,
        'incoming': incomingRefs,
      };
    } catch (e) {
      return {'outgoing': [], 'incoming': []};
    }
  }

  /// 从文本内容中解析引用并自动创建关系
  Future<int> parseAndCreateReferences(String noteId, String content) async {
    try {
      // 解析文本中的引用内容
      final referencedContents = _parseReferencesFromText(content);

      if (referencedContents.isEmpty) {
        return 0;
      }

      // 根据内容查找笔记ID
      final referencedIds = await _findNoteIdsByContent(referencedContents);

      var createdCount = 0;
      for (final relatedId in referencedIds) {
        final success = await createReference(noteId, relatedId);
        if (success) {
          createdCount++;
        }
      }

      return createdCount;
    } catch (e) {
      return 0;
    }
  }

  /// 获取所有未同步的引用关系
  Future<List<Map<String, dynamic>>> getUnsyncedReferences() async {
    try {
      final allNotes = await _databaseService.getNotes();
      final unsyncedRefs = <Map<String, dynamic>>[];

      for (final note in allNotes) {
        for (final relation in note.relations) {
          final synced = relation['synced'] as bool? ?? true; // 默认已同步（兼容旧数据）
          if (!synced) {
            unsyncedRefs.add({
              'noteId': note.id,
              'relation': relation,
            });
          }
        }
      }

      return unsyncedRefs;
    } catch (e) {
      return [];
    }
  }

  /// 标记引用关系为已同步
  Future<bool> markReferenceAsSynced(
    String noteId,
    Map<String, dynamic> relation,
  ) async {
    try {
      final note = await _databaseService.getNoteById(noteId);
      if (note == null) return false;

      // 查找并更新对应的关系
      final updatedRelations = note.relations.map((rel) {
        if (_isSameRelation(rel, relation)) {
          return {...rel, 'synced': true};
        }
        return rel;
      }).toList();

      final updatedNote = note.copyWith(relations: updatedRelations);
      await _databaseService.updateNote(updatedNote);

      return true;
    } catch (e) {
      return false;
    }
  }

  // 私有辅助方法

  /// 检查引用关系是否已存在
  bool _hasReference(
    List<Map<String, dynamic>> relations,
    String fromId,
    String toId,
    String type,
  ) =>
      relations.any((relation) {
        final memoId = relation['memoId']?.toString();
        final relatedMemoId = relation['relatedMemoId']?.toString();
        final relationType = relation['type']?.toString();

        return memoId == fromId &&
            relatedMemoId == toId &&
            (relationType == type || relationType == type.toLowerCase());
      });

  /// 解析文本中的引用内容，获取被引用的内容列表
  List<String> _parseReferencesFromText(String content) {
    final referencedContents = <String>[];

    // 匹配 [[引用内容]] 格式
    final referenceRegex = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = referenceRegex.allMatches(content);

    for (final match in matches) {
      final referenceContent = match.group(1);
      if (referenceContent != null && referenceContent.isNotEmpty) {
        referencedContents.add(referenceContent.trim());
      }
    }

    return referencedContents;
  }

  /// 根据引用内容查找笔记ID
  Future<List<String>> _findNoteIdsByContent(List<String> contents) async {
    try {
      final allNotes = await _databaseService.getNotes();
      final foundIds = <String>[];

      for (final content in contents) {
        final matchingNote = allNotes.firstWhere(
          (note) => note.content.trim() == content.trim(),
          orElse: () => Note(
            id: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (matchingNote.id.isNotEmpty) {
          foundIds.add(matchingNote.id);
        }
      }

      return foundIds;
    } catch (e) {
      return [];
    }
  }

  /// 检查两个关系是否相同
  bool _isSameRelation(Map<String, dynamic> rel1, Map<String, dynamic> rel2) =>
      rel1['memoId'] == rel2['memoId'] &&
      rel1['relatedMemoId'] == rel2['relatedMemoId'] &&
      rel1['type'] == rel2['type'];

  /// 设置AppProvider实例
  void setAppProvider(AppProvider appProvider) {
    _appProvider = appProvider;
  }

  /// 通知AppProvider更新笔记
  void _notifyAppProviderUpdate(Note updatedNote) {
    if (_appProvider != null) {
      _appProvider!.updateNoteInMemory(updatedNote);
      if (kDebugMode) {
        // 已通知AppProvider更新笔记
      }
    }
  }
}
