import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../models/notion_field_mapping.dart';
import '../services/notion_api_service.dart';
import '../services/database_service.dart';

/// Notion 同步服务
/// 参考滴答清单的 Notion 集成，实现双向同步
class NotionSyncService {
  final NotionApiService _notionApi = NotionApiService();
  final DatabaseService _database = DatabaseService();
  
  // 配置键
  static const String _keyEnabled = 'notion_sync_enabled';
  static const String _keyAccessToken = 'notion_access_token';
  static const String _keyDatabaseId = 'notion_database_id';
  static const String _keyAutoSync = 'notion_auto_sync';
  static const String _keySyncDirection = 'notion_sync_direction'; // 'to_notion', 'from_notion', 'both'
  static const String _keyLastSyncTime = 'notion_last_sync_time';
  static const String _keyFieldMapping = 'notion_field_mapping'; // 字段映射配置
  
  /// 是否已启用
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }
  
  /// 设置启用状态
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }
  
  /// 设置访问令牌
  Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
    _notionApi.setAccessToken(token);
  }
  
  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAccessToken);
    if (token != null) {
      _notionApi.setAccessToken(token);
    }
    return token;
  }
  
  /// 设置数据库 ID
  Future<void> setDatabaseId(String databaseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDatabaseId, databaseId);
  }
  
  /// 获取数据库 ID
  Future<String?> getDatabaseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDatabaseId);
  }
  
  /// 设置自动同步
  Future<void> setAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, enabled);
  }
  
  /// 是否自动同步
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSync) ?? false;
  }
  
  /// 设置同步方向
  Future<void> setSyncDirection(String direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncDirection, direction);
  }
  
  /// 获取同步方向
  Future<String> getSyncDirection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySyncDirection) ?? 'to_notion';
  }
  
  /// 设置字段映射
  Future<void> setFieldMapping(NotionFieldMapping mapping) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFieldMapping, jsonEncode(mapping.toJson()));
  }
  
  /// 获取字段映射
  Future<NotionFieldMapping?> getFieldMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyFieldMapping);
    if (jsonStr != null) {
      try {
        return NotionFieldMapping.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint('解析字段映射失败: $e');
        return null;
      }
    }
    return null;
  }
  
  /// 测试连接
  Future<bool> testConnection() async {
    await getAccessToken(); // 确保 token 已加载
    return await _notionApi.testConnection();
  }
  
  /// 获取可用的数据库列表
  Future<List<NotionDatabase>> getDatabases() async {
    await getAccessToken();
    return await _notionApi.searchDatabases();
  }
  
  /// 同步单个笔记到 Notion（带去重）
  Future<String?> syncNoteToNotion(Note note) async {
    try {
      if (!await isEnabled()) {
        debugPrint('Notion 同步未启用');
        return null;
      }
      
      final databaseId = await getDatabaseId();
      if (databaseId == null) {
        debugPrint('未设置 Notion 数据库');
        return null;
      }
      
      // 获取字段映射
      final fieldMapping = await getFieldMapping();
      if (fieldMapping == null || !fieldMapping.isComplete) {
        debugPrint('❌ 字段映射未配置或不完整');
        return null;
      }
      
      await getAccessToken();
      
      // 提取标题（使用内容的第一行或前50个字符）
      final title = _extractTitle(note.content);
      
      // 过滤内容中的标签（因为标签已经在标签属性中了）
      final contentWithoutTags = _removeTagsFromContent(note.content);
      debugPrint('📝 原始内容长度: ${note.content.length}, 过滤后: ${contentWithoutTags.length}');
      
      // 检查是否已存在（通过标题查询）
      debugPrint('🔍 检查笔记是否已存在: $title');
      final existingPages = await _notionApi.queryDatabase(
        databaseId: databaseId,
        titleProperty: fieldMapping.titleProperty!,
        titleValue: title,
      );
      
      String pageId;
      if (existingPages.isNotEmpty) {
        // 已存在，更新
        pageId = existingPages.first['id'];
        debugPrint('📝 笔记已存在，更新页面: $pageId');
        await _notionApi.updatePageWithMapping(
          pageId: pageId,
          title: title,
          content: contentWithoutTags,
          tags: note.tags,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          fieldMapping: fieldMapping,
        );
        debugPrint('✅ 笔记已更新到 Notion: $pageId');
      } else {
        // 不存在，创建
        debugPrint('➕ 笔记不存在，创建新页面');
        pageId = await _notionApi.createPageWithMapping(
          databaseId: databaseId,
          title: title,
          content: contentWithoutTags,
          tags: note.tags,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          fieldMapping: fieldMapping,
        );
        debugPrint('✅ 笔记已创建到 Notion: $pageId');
      }
      
      return pageId;
    } catch (e) {
      debugPrint('❌ 同步笔记到 Notion 失败: $e');
      return null;
    }
  }
  
  /// 批量同步笔记到 Notion
  Future<Map<String, dynamic>> syncNotesToNotion(
    List<Note> notes, {
    Function(int current, int total)? onProgress,
  }) async {
    debugPrint('🚀 开始批量同步 ${notes.length} 条笔记到 Notion...');
    int successCount = 0;
    int failCount = 0;
    final errors = <String>[];
    
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      try {
        final pageId = await syncNoteToNotion(note);
        if (pageId != null) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
        errors.add('同步笔记失败: $e');
        debugPrint('❌ 同步笔记失败: $e');
      }
      
      // 更新进度
      if (onProgress != null) {
        onProgress(i + 1, notes.length);
      }
    }
    
    // 更新最后同步时间
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
    
    debugPrint('📊 同步完成统计:');
    debugPrint('  ✅ 成功: $successCount 条');
    debugPrint('  ❌ 失败: $failCount 条');
    if (errors.isNotEmpty) {
      debugPrint('  错误列表:');
      for (var error in errors) {
        debugPrint('    - $error');
      }
    }
    
    return {
      'success': successCount,
      'failed': failCount,
      'errors': errors,
    };
  }
  
  /// 从 Notion 同步笔记
  Future<Map<String, dynamic>> syncNotesFromNotion({
    Function(int current, int total)? onProgress,
  }) async {
    try {
      if (!await isEnabled()) {
        return {'success': 0, 'failed': 0, 'errors': ['Notion 同步未启用']};
      }
      
      final databaseId = await getDatabaseId();
      if (databaseId == null) {
        return {'success': 0, 'failed': 0, 'errors': ['未设置 Notion 数据库']};
      }
      
      await getAccessToken();
      
      // 查询数据库中的所有页面
      final pages = await _notionApi.queryDatabasePages(databaseId);
      
      int successCount = 0;
      int failCount = 0;
      final errors = <String>[];
      
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        try {
          // 获取页面内容
          final content = await _notionApi.getPageContent(page.id);
          
          // 创建本地笔记
          final note = Note(
            id: page.id, // 使用 Notion 页面 ID
            content: content,
            tags: page.tags,
            createdAt: page.createdAt ?? DateTime.now(),
            updatedAt: page.updatedAt ?? DateTime.now(),
          );
          
          // 保存到本地数据库
          await _database.saveNote(note);
          successCount++;
        } catch (e) {
          failCount++;
          errors.add('页面 ${page.id}: $e');
        }
        
        // 更新进度
        if (onProgress != null) {
          onProgress(i + 1, pages.length);
        }
      }
      
      // 更新最后同步时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
      
      return {
        'success': successCount,
        'failed': failCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('从 Notion 同步失败: $e');
      return {
        'success': 0,
        'failed': 0,
        'errors': ['同步失败: $e'],
      };
    }
  }
  
  /// 双向同步
  Future<Map<String, dynamic>> syncBoth(List<Note> localNotes) async {
    final toNotionResult = await syncNotesToNotion(localNotes);
    final fromNotionResult = await syncNotesFromNotion();
    
    return {
      'to_notion': toNotionResult,
      'from_notion': fromNotionResult,
    };
  }
  
  /// 获取最后同步时间
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_keyLastSyncTime);
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }
  
  /// 清除配置
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyDatabaseId);
    await prefs.remove(_keyAutoSync);
    await prefs.remove(_keySyncDirection);
    await prefs.remove(_keyLastSyncTime);
    await prefs.remove(_keyFieldMapping);
  }
  
  // ========== 私有辅助方法 ==========
  
  /// 从内容中移除标签
  String _removeTagsFromContent(String content) {
    // 移除所有 #标签 格式的标签
    return content
        .replaceAll(RegExp(r'#[\u4e00-\u9fa5\w]+\s*'), '') // 移除 #tag
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // 移除多余空行
        .trim();
  }
  
  /// 从笔记内容中提取标题
  String _extractTitle(String content) {
    if (content.trim().isEmpty) {
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      debugPrint('⚠️ 笔记内容为空，使用默认标题');
      return '无标题笔记 $timestamp';
    }
    
    // 移除 Markdown 标记和标签
    String cleaned = content
        .replaceAll(RegExp(r'#[\u4e00-\u9fa5\w]+\s*'), '') // 移除标签 #tag
        .replaceAll(RegExp(r'^#+\s*'), '') // 移除标题标记
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // 移除粗体
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // 移除斜体
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // 移除代码
        .replaceAll(RegExp(r'>\s*'), '') // 移除引用
        .replaceAll(RegExp(r'---+'), '') // 移除分隔线
        .replaceAll(RegExp(r'[\$◆♦★☆●○■□▲△▼▽◇◆]'), '') // 移除特殊符号
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '') // 移除表情符号
        .trim();
    
    // 获取第一行非空内容
    final lines = cleaned.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final firstLine = lines.isNotEmpty ? lines[0].trim() : '';
    
    if (firstLine.isEmpty) {
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');
      debugPrint('⚠️ 清理后内容为空，使用默认标题');
      return '无标题笔记 $timestamp';
    }
    
    // 限制长度
    String title;
    if (firstLine.length > 50) {
      title = '${firstLine.substring(0, 50)}...';
    } else {
      title = firstLine;
    }
    
    debugPrint('📝 提取标题: $title');
    return title;
  }
}
