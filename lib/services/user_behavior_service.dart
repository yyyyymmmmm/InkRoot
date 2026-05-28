import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/intelligent_related_notes_service.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;
import 'package:shared_preferences/shared_preferences.dart';

/// 🧠 用户行为学习服务
/// 
/// 功能：
/// 1. 记录点击行为
/// 2. 分析用户偏好（标签、关系类型、主题）
/// 3. 提供个性化权重调整
class UserBehaviorService {
  static const String _clickHistoryKey = 'user_click_history';
  static const String _preferenceKey = 'user_preferences';
  static const int _maxHistorySize = 100; // 保留最近100次点击
  
  /// 📊 记录用户点击笔记
  Future<void> recordClick({
    required String noteId,
    required List<String> noteTags,
    required RelationType? relationType, // 从哪种关系类型点击的
    required int viewDurationSeconds, // 浏览时长
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 读取历史记录
      final historyJson = prefs.getString(_clickHistoryKey);
      final history = historyJson != null
          ? List<Map<String, dynamic>>.from(json.decode(historyJson))
          : <Map<String, dynamic>>[];
      
      // 添加新记录
      history.insert(0, {
        'noteId': noteId,
        'tags': noteTags,
        'relationType': relationType?.name,
        'viewDuration': viewDurationSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // 只保留最近N条
      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }
      
      // 保存
      await prefs.setString(_clickHistoryKey, json.encode(history));
      
      // 更新偏好分析
      await _updatePreferences(history);
      
      debugPrint('📊 记录点击：noteId=$noteId, 浏览${viewDurationSeconds}秒');
    } catch (e) {
      debugPrint('⚠️ 记录点击失败: $e');
    }
  }
  
  /// 🔍 分析并更新用户偏好
  Future<void> _updatePreferences(List<Map<String, dynamic>> history) async {
    try {
      if (history.isEmpty) return;
      
      // 1. 统计标签偏好
      final tagFrequency = <String, int>{};
      for (final record in history) {
        final tags = List<String>.from(record['tags'] ?? []);
        for (final tag in tags) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }
      
      // 2. 统计关系类型偏好
      final relationTypeFrequency = <String, int>{};
      for (final record in history) {
        final relationType = record['relationType'] as String?;
        if (relationType != null) {
          relationTypeFrequency[relationType] =
              (relationTypeFrequency[relationType] ?? 0) + 1;
        }
      }
      
      // 3. 计算平均浏览时长
      final totalDuration = history.fold<int>(
        0,
        (sum, record) => sum + (record['viewDuration'] as int? ?? 0),
      );
      final avgViewDuration = totalDuration / history.length;
      
      // 4. 找出Top标签（最喜欢的）
      final topTags = tagFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteTagsMap = Map.fromEntries(
        topTags.take(20).map((e) => MapEntry(e.key, e.value)),
      );
      
      // 5. 找出最喜欢的关系类型
      final topRelationTypes = relationTypeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteRelationTypesMap = Map.fromEntries(topRelationTypes);
      
      // 保存偏好
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _preferenceKey,
        json.encode({
          'favoriteTags': favoriteTagsMap,
          'favoriteRelationTypes': favoriteRelationTypesMap,
          'avgViewDuration': avgViewDuration,
          'totalClicks': history.length,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      
      debugPrint('🧠 偏好已更新：'
          'Top标签=${favoriteTagsMap.keys.take(3).join(", ")}, '
          'Top关系=${favoriteRelationTypesMap.keys.take(2).join(", ")}');
    } catch (e) {
      debugPrint('⚠️ 更新偏好失败: $e');
    }
  }
  
  /// 🎯 获取用户偏好
  Future<UserPreference> getUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferenceJson = prefs.getString(_preferenceKey);
      
      if (preferenceJson == null) {
        return UserPreference.empty();
      }
      
      final data = json.decode(preferenceJson) as Map<String, dynamic>;
      
      return UserPreference(
        favoriteTags: Map<String, int>.from(data['favoriteTags'] ?? {}),
        favoriteRelationTypes: Map<String, int>.from(
          data['favoriteRelationTypes'] ?? {},
        ),
        avgViewDuration: (data['avgViewDuration'] as num?)?.toDouble() ?? 0,
        totalClicks: data['totalClicks'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('⚠️ 读取偏好失败: $e');
      return UserPreference.empty();
    }
  }
  
  /// 🎨 为笔记计算个性化权重加成
  double calculatePersonalizedBoost({
    required Note note,
    required RelationType relationType,
    required UserPreference preference,
  }) {
    if (preference.totalClicks < 5) {
      return 0.0; // 数据太少，不调整
    }
    
    var boost = 0.0;
    
    // 1. 标签匹配加成（最高 +30%）
    final noteTags = tag_utils.extractTagsFromContent(note.content).toSet();
    var tagBoost = 0.0;
    for (final tag in noteTags) {
      final frequency = preference.favoriteTags[tag] ?? 0;
      if (frequency > 0) {
        // 频率越高，加成越大
        tagBoost += (frequency / preference.totalClicks) * 0.5;
      }
    }
    boost += tagBoost.clamp(0.0, 0.3); // 最多加30%
    
    // 2. 关系类型匹配加成（最高 +20%）
    final relationFrequency =
        preference.favoriteRelationTypes[relationType.name] ?? 0;
    if (relationFrequency > 0) {
      final relationBoost = (relationFrequency / preference.totalClicks) * 0.4;
      boost += relationBoost.clamp(0.0, 0.2); // 最多加20%
    }
    
    return boost; // 总加成：0-50%
  }
  
  /// 📈 获取点击历史（用于可视化）
  Future<List<ClickRecord>> getClickHistory({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_clickHistoryKey);
      
      if (historyJson == null) return [];
      
      final history = List<Map<String, dynamic>>.from(json.decode(historyJson));
      
      return history.take(limit).map((record) {
        return ClickRecord(
          noteId: record['noteId'] as String,
          tags: List<String>.from(record['tags'] ?? []),
          relationType: record['relationType'] as String?,
          viewDuration: record['viewDuration'] as int? ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            record['timestamp'] as int,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ 读取历史失败: $e');
      return [];
    }
  }
  
  /// 🗑️ 清除所有数据
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clickHistoryKey);
      await prefs.remove(_preferenceKey);
      debugPrint('🗑️ 用户行为数据已清除');
    } catch (e) {
      debugPrint('⚠️ 清除数据失败: $e');
    }
  }
}

/// 👤 用户偏好模型
class UserPreference {
  const UserPreference({
    required this.favoriteTags,
    required this.favoriteRelationTypes,
    required this.avgViewDuration,
    required this.totalClicks,
  });
  
  factory UserPreference.empty() {
    return const UserPreference(
      favoriteTags: {},
      favoriteRelationTypes: {},
      avgViewDuration: 0,
      totalClicks: 0,
    );
  }
  
  final Map<String, int> favoriteTags; // 标签 -> 点击次数
  final Map<String, int> favoriteRelationTypes; // 关系类型 -> 点击次数
  final double avgViewDuration; // 平均浏览时长（秒）
  final int totalClicks; // 总点击次数
  
  /// 获取Top N 标签
  List<String> getTopTags(int n) {
    final sorted = favoriteTags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }
  
  /// 获取Top N 关系类型
  List<String> getTopRelationTypes(int n) {
    final sorted = favoriteRelationTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }
  
  /// 是否有足够数据进行个性化
  bool get hasEnoughData => totalClicks >= 5;
}

/// 📊 点击记录模型
class ClickRecord {
  const ClickRecord({
    required this.noteId,
    required this.tags,
    required this.relationType,
    required this.viewDuration,
    required this.timestamp,
  });
  
  final String noteId;
  final List<String> tags;
  final String? relationType;
  final int viewDuration;
  final DateTime timestamp;
}


