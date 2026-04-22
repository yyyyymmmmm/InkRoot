// 搜索功能模块（从 home_screen.dart 拆分）
// 职责：处理笔记搜索逻辑

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';

/// 搜索助手类
///
/// 负责：
/// 1. 执行搜索（带防抖优化）
/// 2. 数据库搜索和内存搜索
class HomeSearchHelper {
  /// 防抖定时器
  Timer? _searchDebounce;

  /// 搜索结果回调
  void Function(List<Note>)? onSearchResults;

  /// 执行搜索（带防抖优化）
  void performSearch(String query, AppProvider appProvider) {
    // 取消之前的搜索请求
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      // 搜索框为空时，清空搜索结果
      onSearchResults?.call([]);
      return;
    }

    // 延迟300ms执行搜索，避免每次输入都查询
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _executeSearch(query, appProvider),
    );
  }

  /// 实际执行搜索
  Future<void> _executeSearch(String query, AppProvider appProvider) async {
    try {
      // 使用数据库搜索，确保搜索全部笔记
      final results = await appProvider.databaseService.searchNotes(query);
      onSearchResults?.call(results);
    } catch (e) {
      if (kDebugMode) debugPrint('搜索失败: $e');

      // 如果数据库搜索失败，回退到内存搜索
      final results = appProvider.notes
          .where(
            (note) =>
                note.content.toLowerCase().contains(query.toLowerCase()) ||
                note.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
      onSearchResults?.call(results);
    }
  }

  /// 清理资源
  void dispose() {
    _searchDebounce?.cancel();
  }
}
