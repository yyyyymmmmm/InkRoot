import 'package:flutter/foundation.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:inkroot/services/sync_merge_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 增量同步服务
/// 实现类似Notion、Evernote的高性能同步机制
class IncrementalSyncService {
  IncrementalSyncService(this._databaseService, this._apiService);
  final DatabaseService _databaseService;
  final MemosApiServiceFixed? _apiService;

  // 🚀 使用统一配置管理
  static const String _lastSyncTimeKey = AppConfig.prefKeyLastSyncTime;

  /// 增量同步笔记
  /// 只同步自上次同步以来发生变化的数据
  Future<SyncResult> incrementalSync() async {
    if (_apiService == null) {
      throw Exception('API服务未初始化');
    }

    final startTime = DateTime.now();

    try {
      // 1. 获取上次同步时间
      final lastSyncTime = await _getLastSyncTime();

      // 2. 只获取更新的笔记（增量）
      final updatedNotes = await _fetchUpdatedNotes(lastSyncTime);

      // 3. 智能合并到本地数据库
      final mergeResult = await _smartMerge(updatedNotes);

      // 4. 更新同步时间
      await _updateLastSyncTime(DateTime.now());

      final duration = DateTime.now().difference(startTime);
      // 🚀 只在有更新时打印
      if (kDebugMode &&
          (mergeResult.newCount > 0 || mergeResult.updatedCount > 0)) {}

      return SyncResult(
        success: true,
        totalNotes: mergeResult.totalCount,
        updatedNotes: mergeResult.updatedCount,
        newNotes: mergeResult.newCount,
        deletedNotes: mergeResult.deletedCount,
        duration: duration,
      );
    } on Object {
      rethrow;
    }
  }

  /// 获取更新的笔记（增量）
  Future<List<Note>> _fetchUpdatedNotes(DateTime? since) async {
    try {
      // 🚀 如果是首次同步，获取所有笔记
      if (since == null) {
        final response = await _apiService!.getMemos();
        final memosList = response['memos'] as List<dynamic>;
        return memosList
            .map((memo) => Note.fromJson(memo as Map<String, dynamic>))
            .toList();
      }

      // 🚀 增量同步：获取所有笔记，本地过滤
      // 如果 API 后续支持 updatedAfter 参数，可以移到服务器端过滤。
      final response = await _apiService!.getMemos();
      final memosList = response['memos'] as List<dynamic>;
      final allNotes = memosList
          .map((memo) => Note.fromJson(memo as Map<String, dynamic>))
          .toList();

      // 本地过滤：只返回更新的笔记
      final updatedNotes =
          allNotes.where((note) => note.updatedAt.isAfter(since)).toList();

      return updatedNotes;
    } on Object {
      rethrow;
    }
  }

  /// 智能合并笔记到本地数据库
  /// 使用高效的批量更新策略，避免清空重建
  Future<MergeResult> _smartMerge(List<Note> updatedNotes) async {
    const deletedCount = 0;

    try {
      // 获取本地所有笔记ID
      final localNotes = await _databaseService.getNotes();
      final plan =
          planSyncMerge(localNotes: localNotes, updatedNotes: updatedNotes);

      // 批量操作（比逐个操作快很多）
      if (plan.toUpdate.isNotEmpty) {
        await _databaseService.updateNotesBatch(plan.toUpdate);
        if (kDebugMode) {
          // 🚀 静默批量更新
        }
      }

      if (plan.toInsert.isNotEmpty) {
        await _databaseService.insertNotesBatch(plan.toInsert);
        if (kDebugMode) {
          // 🚀 静默批量插入
        }
      }

      // 检测被删除的笔记（服务器没有但本地有）
      // 注意：这个逻辑需要谨慎，可能需要额外的API支持
      // 暂时跳过删除检测，避免误删本地未同步的笔记

      final totalCount = await _databaseService.getNotesCount();

      return MergeResult(
        newCount: plan.newCount,
        updatedCount: plan.updatedCount,
        deletedCount: deletedCount,
        totalCount: totalCount,
      );
    } on Object {
      rethrow;
    }
  }

  /// 获取上次同步时间
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncTimeKey);
      if (timestamp == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } on Object {
      return null;
    }
  }

  /// 更新同步时间
  Future<void> _updateLastSyncTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncTimeKey, time.millisecondsSinceEpoch);
      if (kDebugMode) {
        // 🚀 静默更新同步时间
      }
    } on Object catch (_) {
      // Last sync time is an optimization; failure should not break sync.
    }
  }

  /// 重置同步状态（强制全量同步）
  Future<void> resetSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncTimeKey);
    } on Object catch (_) {
      // Resetting sync state is best-effort.
    }
  }
}

/// 同步结果
class SyncResult {
  SyncResult({
    required this.success,
    required this.totalNotes,
    required this.updatedNotes,
    required this.newNotes,
    required this.deletedNotes,
    required this.duration,
  });
  final bool success;
  final int totalNotes;
  final int updatedNotes;
  final int newNotes;
  final int deletedNotes;
  final Duration duration;

  @override
  String toString() =>
      'SyncResult(总计: $totalNotes, 新增: $newNotes, 更新: $updatedNotes, 删除: $deletedNotes, 耗时: ${duration.inMilliseconds}ms)';
}

/// 合并结果
class MergeResult {
  MergeResult({
    required this.newCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.totalCount,
  });
  final int newCount;
  final int updatedCount;
  final int deletedCount;
  final int totalCount;
}
