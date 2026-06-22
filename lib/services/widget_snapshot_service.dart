import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/random_review_selector_service.dart';
import 'package:inkroot/utils/memos_content_helper.dart';
import 'package:inkroot/utils/todo_parser.dart';

abstract final class WidgetSnapshotService {
  static const String _snapshotPrefsKey = 'inkroot_widget_snapshot';
  static const String _channelName = Config.AppConfig.channelNativeAlarm;
  static const MethodChannel _channel = MethodChannel(_channelName);
  static Timer? _debounceTimer;
  static String? _lastSnapshotJson;

  static void scheduleUpdate({
    required List<Note> notes,
    required bool isLocalMode,
    required bool isLoggedIn,
    required bool isSyncing,
    int reviewRefreshIntervalMinutes = 60,
    int reviewRangeDays = 0,
    String? syncMessage,
    Duration delay = const Duration(milliseconds: 350),
  }) {
    _debounceTimer?.cancel();
    final snapshotNotes = List<Note>.from(notes);
    _debounceTimer = Timer(delay, () {
      unawaited(
        update(
          notes: snapshotNotes,
          isLocalMode: isLocalMode,
          isLoggedIn: isLoggedIn,
          isSyncing: isSyncing,
          reviewRefreshIntervalMinutes: reviewRefreshIntervalMinutes,
          reviewRangeDays: reviewRangeDays,
          syncMessage: syncMessage,
        ),
      );
    });
  }

  static Future<void> update({
    required List<Note> notes,
    required bool isLocalMode,
    required bool isLoggedIn,
    required bool isSyncing,
    int reviewRefreshIntervalMinutes = 60,
    int reviewRangeDays = 0,
    String? syncMessage,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    try {
      final json = jsonEncode(
        _buildSnapshot(
          notes: notes,
          isLocalMode: isLocalMode,
          isLoggedIn: isLoggedIn,
          isSyncing: isSyncing,
          reviewRefreshIntervalMinutes: reviewRefreshIntervalMinutes,
          reviewRangeDays: reviewRangeDays,
          syncMessage: syncMessage,
        ),
      );

      if (json == _lastSnapshotJson) {
        return;
      }
      _lastSnapshotJson = json;

      await _channel.invokeMethod<void>(
        'saveWidgetSnapshot',
        <String, Object?>{
          'key': _snapshotPrefsKey,
          'snapshot': json,
        },
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('WidgetSnapshotService: 更新桌面小组件快照失败: $e');
      }
    }
  }

  @visibleForTesting
  static Map<String, Object?> debugBuildSnapshot({
    required List<Note> notes,
    required bool isLocalMode,
    required bool isLoggedIn,
    required bool isSyncing,
    int reviewRefreshIntervalMinutes = 60,
    int reviewRangeDays = 0,
    String? syncMessage,
  }) =>
      _buildSnapshot(
        notes: notes,
        isLocalMode: isLocalMode,
        isLoggedIn: isLoggedIn,
        isSyncing: isSyncing,
        reviewRefreshIntervalMinutes: reviewRefreshIntervalMinutes,
        reviewRangeDays: reviewRangeDays,
        syncMessage: syncMessage,
      );

  static Map<String, Object?> _buildSnapshot({
    required List<Note> notes,
    required bool isLocalMode,
    required bool isLoggedIn,
    required bool isSyncing,
    required int reviewRefreshIntervalMinutes,
    required int reviewRangeDays,
    String? syncMessage,
  }) {
    final visibleNotes = notes
        .where((note) => note.rowStatus.toUpperCase() == 'NORMAL')
        .toList()
      ..sort((a, b) => b.displayTime.compareTo(a.displayTime));

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayNotes = visibleNotes
        .where((note) => note.displayTime.isAfter(todayStart))
        .toList();
    final tagCounts = <String, int>{};
    var pendingTodos = 0;
    var todayWords = 0;

    for (final note in visibleNotes) {
      for (final tag in note.tags) {
        final cleanTag = tag.trim();
        if (cleanTag.isNotEmpty) {
          tagCounts[cleanTag] = (tagCounts[cleanTag] ?? 0) + 1;
        }
      }
      pendingTodos += TodoParser.countTodos(note.content)['pending'] ?? 0;
    }

    for (final note in todayNotes) {
      todayWords +=
          _wordCount(MemosContentHelper.previewVisibleText(note.content));
    }

    final quickTags = tagCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    final reviewNotes = _pickReviewNotes(
      visibleNotes,
      reviewRangeDays: reviewRangeDays,
    );
    final unsyncedCount = visibleNotes.where((note) => !note.isSynced).length;

    return <String, Object?>{
      'schemaVersion': 1,
      'generatedAt': now.toIso8601String(),
      'today': <String, Object?>{
        'notes': todayNotes.length,
        'words': todayWords,
        'tags': todayNotes.expand((note) => note.tags).toSet().length,
        'pendingTodos': pendingTodos,
      },
      'sync': <String, Object?>{
        'mode': isLocalMode
            ? 'local'
            : isLoggedIn
                ? 'memos'
                : 'local',
        'status': isSyncing ? 'syncing' : 'idle',
        'message': syncMessage,
        'unsyncedCount': unsyncedCount,
      },
      'quickTags': quickTags.take(5).map((entry) => entry.key).toList(),
      'reviewConfig': <String, Object?>{
        'refreshIntervalMinutes': reviewRefreshIntervalMinutes.clamp(15, 1440),
        'rangeDays': reviewRangeDays < 0 ? 0 : reviewRangeDays,
      },
      'reviewNotes': reviewNotes.map(_noteSnapshot).toList(),
      'privacyMode': false,
    };
  }

  static List<Note> _pickReviewNotes(
    List<Note> notes, {
    required int reviewRangeDays,
  }) {
    return RandomReviewSelectorService.selectWidgetCandidates(
      notes: notes,
      reviewDays: reviewRangeDays == 0
          ? RandomReviewSelectorService.allDays
          : reviewRangeDays,
      random: Random(),
    );
  }

  static Map<String, Object?> _noteSnapshot(Note note) {
    final visibleText =
        MemosContentHelper.previewVisibleText(note.content).trim();
    final preview = visibleText.isNotEmpty
        ? _trimPreview(visibleText, 120)
        : _attachmentPreview(note);
    return <String, Object?>{
      'id': note.id,
      'preview': preview,
      'tags': note.tags.take(3).toList(),
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'displayTime': note.displayTime.toIso8601String(),
    };
  }

  static String _attachmentPreview(Note note) {
    if (MemosContentHelper.extractNoteImagePaths(note).isNotEmpty) {
      return '这是一条含图片的笔记';
    }
    if (note.resourceList.isNotEmpty) {
      return '这是一条含附件的笔记';
    }
    return _trimPreview(note.content.trim(), 120);
  }

  static int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    final cjkCount = RegExp('[\u4e00-\u9fff]').allMatches(trimmed).length;
    final latinCount = RegExp('[A-Za-z0-9]+').allMatches(trimmed).length;
    return cjkCount + latinCount;
  }

  static String _trimPreview(String text, int maxLength) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength).trimRight()}...';
  }
}
