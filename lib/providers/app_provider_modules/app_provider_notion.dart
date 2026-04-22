import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/notion_sync_service.dart';

/// Notion 同步 Provider Mixin
///
/// 提供 Notion 双向同步功能：
/// - 自动同步到 Notion
/// - 手动同步到 Notion
/// - 从 Notion 导入笔记
mixin AppProviderNotion on ChangeNotifier {
  // ============================================================
  // Notion 同步相关状态
  // ============================================================

  /// Notion 同步服务实例
  final NotionSyncService _notionSyncService = NotionSyncService();

  /// 是否正在进行 Notion 同步
  bool _isNotionSyncing = false;

  // ============================================================
  // 抽象属性（需要主类提供）
  // ============================================================

  /// 获取笔记列表（由主类提供）
  List<Note> get notes;

  /// 从本地数据库加载笔记（由主类实现）
  Future<void> loadNotesFromLocal({bool reset = false});

  // ============================================================
  // Getters
  // ============================================================

  /// 获取 Notion 同步状态
  bool get isNotionSyncing => _isNotionSyncing;

  // ============================================================
  // Notion 同步方法
  // ============================================================

  /// 🚀 Notion 自动同步（内部方法，异步执行，不阻塞UI）
  ///
  /// 在后台自动同步笔记到 Notion，不会阻塞 UI。
  /// 仅在启用自动同步且同步方向为 "to_notion" 或 "both" 时执行。
  void _autoSyncToNotion() async {
    try {
      // 检查是否启用自动同步
      final isEnabled = await _notionSyncService.isEnabled();
      final isAutoSync = await _notionSyncService.isAutoSyncEnabled();

      if (!isEnabled || !isAutoSync) {
        return; // 未启用或未开启自动同步，直接返回
      }

      // 防止重复同步
      if (_isNotionSyncing) {
        debugPrint('Notion: 同步进行中，跳过本次自动同步');
        return;
      }

      debugPrint('Notion: 开始自动同步');
      _isNotionSyncing = true;

      // 获取同步方向
      final direction = await _notionSyncService.getSyncDirection();

      // 执行同步
      if (direction == 'to_notion' || direction == 'both') {
        await _notionSyncService.syncNotesToNotion(notes);
        debugPrint('Notion: 自动同步完成');
      }

    } catch (e) {
      debugPrint('Notion: 自动同步失败: $e');
      // 静默失败，不影响用户使用
    } finally {
      _isNotionSyncing = false;
    }
  }

  /// 🚀 手动同步到 Notion（供下拉刷新等场景使用）
  ///
  /// 根据同步方向执行相应的同步操作：
  /// - to_notion: 仅将本地笔记同步到 Notion
  /// - from_notion: 仅从 Notion 导入笔记到本地
  /// - both: 双向同步（先上传再下载）
  ///
  /// 抛出异常供 UI 处理（如显示错误提示）
  Future<void> syncToNotion() async {
    try {
      // 检查是否启用
      final isEnabled = await _notionSyncService.isEnabled();
      if (!isEnabled) {
        throw Exception('Notion 同步未启用');
      }

      // 防止重复同步
      if (_isNotionSyncing) {
        debugPrint('Notion: 同步进行中，跳过本次请求');
        return;
      }

      debugPrint('Notion: 开始手动同步');
      _isNotionSyncing = true;
      notifyListeners(); // 通知UI显示加载状态

      // 获取同步方向
      final direction = await _notionSyncService.getSyncDirection();

      // 执行同步
      if (direction == 'to_notion') {
        await _notionSyncService.syncNotesToNotion(notes);
      } else if (direction == 'from_notion') {
        final result = await _notionSyncService.syncNotesFromNotion();
        debugPrint('Notion: 从 Notion 导入完成 - 成功: ${result['success']}, 失败: ${result['failed']}');
        await loadNotesFromLocal();
      } else if (direction == 'both') {
        // 双向同步
        await _notionSyncService.syncNotesToNotion(notes);
        final result = await _notionSyncService.syncNotesFromNotion();
        debugPrint('Notion: 从 Notion 导入完成 - 成功: ${result['success']}, 失败: ${result['failed']}');
        await loadNotesFromLocal();
      }

      debugPrint('Notion: 手动同步完成');

    } catch (e) {
      debugPrint('Notion: 手动同步失败: $e');
      rethrow; // 抛出异常供UI处理
    } finally {
      _isNotionSyncing = false;
      notifyListeners();
    }
  }
}
