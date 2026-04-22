import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 标签颜色配置模型
/// 支持自定义背景色和字体颜色
class TagColor {
  final String tagName;
  final Color backgroundColor;
  final Color textColor;
  final DateTime updatedAt;

  const TagColor({
    required this.tagName,
    required this.backgroundColor,
    required this.textColor,
    required this.updatedAt,
  });

  // 默认配色（主题色）
  static Color defaultBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF1E3A5F)
        : const Color(0xFFEDF3FF);
  }

  static Color defaultTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF82B1FF)
        : const Color(0xFF1976D2);
  }

  // 预设配色方案（简洁优雅，符合主题）
  static const List<Map<String, dynamic>> presetColors = [
    // 蓝色系（默认）
    {
      'name': '经典蓝',
      'bg': Color(0xFFEDF3FF),
      'text': Color(0xFF1976D2),
      'darkBg': Color(0xFF1E3A5F),
      'darkText': Color(0xFF82B1FF),
    },
    // 绿色系
    {
      'name': '清新绿',
      'bg': Color(0xFFE8F5E9),
      'text': Color(0xFF388E3C),
      'darkBg': Color(0xFF1B5E20),
      'darkText': Color(0xFF81C784),
    },
    // 紫色系
    {
      'name': '优雅紫',
      'bg': Color(0xFFF3E5F5),
      'text': Color(0xFF7B1FA2),
      'darkBg': Color(0xFF4A148C),
      'darkText': Color(0xFFBA68C8),
    },
    // 橙色系
    {
      'name': '活力橙',
      'bg': Color(0xFFFFF3E0),
      'text': Color(0xFFE65100),
      'darkBg': Color(0xFFE65100),
      'darkText': Color(0xFFFFB74D),
    },
    // 红色系
    {
      'name': '热情红',
      'bg': Color(0xFFFFEBEE),
      'text': Color(0xFFC62828),
      'darkBg': Color(0xFFB71C1C),
      'darkText': Color(0xFFE57373),
    },
    // 青色系
    {
      'name': '科技青',
      'bg': Color(0xFFE0F7FA),
      'text': Color(0xFF00838F),
      'darkBg': Color(0xFF006064),
      'darkText': Color(0xFF4DD0E1),
    },
    // 黄色系
    {
      'name': '温暖黄',
      'bg': Color(0xFFFFFDE7),
      'text': Color(0xFFF57F17),
      'darkBg': Color(0xFFF57F17),
      'darkText': Color(0xFFFFF176),
    },
    // 灰色系
    {
      'name': '简约灰',
      'bg': Color(0xFFF5F5F5),
      'text': Color(0xFF616161),
      'darkBg': Color(0xFF424242),
      'darkText': Color(0xFFBDBDBD),
    },
  ];

  // JSON 序列化
  Map<String, dynamic> toJson() => {
        'tagName': tagName,
        'backgroundColor': backgroundColor.value,
        'textColor': textColor.value,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TagColor.fromJson(Map<String, dynamic> json) => TagColor(
        tagName: json['tagName'] as String,
        backgroundColor: Color(json['backgroundColor'] as int),
        textColor: Color(json['textColor'] as int),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  // 复制方法
  TagColor copyWith({
    String? tagName,
    Color? backgroundColor,
    Color? textColor,
    DateTime? updatedAt,
  }) =>
      TagColor(
        tagName: tagName ?? this.tagName,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textColor: textColor ?? this.textColor,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagColor &&
          runtimeType == other.runtimeType &&
          tagName == other.tagName;

  @override
  int get hashCode => tagName.hashCode;
}

/// 标签颜色管理服务
class TagColorService {
  static const String _storageKey = 'tag_colors';

  // 保存标签颜色（使用 SharedPreferences）
  static Future<void> saveTagColor(TagColor tagColor) async {
    final prefs = await _getPrefs();
    final colors = await getAllTagColors();
    colors.removeWhere((c) => c.tagName == tagColor.tagName);
    colors.add(tagColor);

    final jsonList = colors.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // 获取标签颜色
  static Future<TagColor?> getTagColor(String tagName) async {
    final colors = await getAllTagColors();
    try {
      return colors.firstWhere((c) => c.tagName == tagName);
    } catch (e) {
      return null;
    }
  }

  // 获取所有标签颜色
  static Future<List<TagColor>> getAllTagColors() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((json) => TagColor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 删除标签颜色
  static Future<void> removeTagColor(String tagName) async {
    final prefs = await _getPrefs();
    final colors = await getAllTagColors();
    colors.removeWhere((c) => c.tagName == tagName);

    final jsonList = colors.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // 重置所有标签颜色
  static Future<void> resetAllColors() async {
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }
}

