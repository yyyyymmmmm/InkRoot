import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/utils/logger.dart';

/// 批注类型枚举
enum AnnotationType {
  comment, // 💬 评论
  question, // ❓ 问题
  idea, // 💡 想法
  important, // ⭐ 重要
  todo, // ✅ 待办
}

/// 批注模型 - 专业版
///
/// 对标 Notion、Obsidian 等成熟笔记软件的批注系统
class Annotation {
  const Annotation({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.author,
    this.type = AnnotationType.comment,
    this.color,
    this.highlightedText,
    this.startOffset,
    this.endOffset,
    this.replies = const [],
    this.isResolved = false,
  });

  /// 从Map创建批注对象（用于数据库读取）
  factory Annotation.fromMap(Map<String, dynamic> map) {
    // 解析批注类型
    var type = AnnotationType.comment;
    if (map['type'] != null) {
      try {
        type = AnnotationType.values.firstWhere(
          (e) => e.toString() == 'AnnotationType.${map['type']}',
          orElse: () => AnnotationType.comment,
        );
      } on Object {
        type = AnnotationType.comment;
      }
    }

    // 解析回复列表
    var replies = <AnnotationReply>[];
    if (map['replies'] != null && map['replies'] is String) {
      try {
        final List<dynamic> replyList = json.decode(map['replies']);
        replies = replyList
            .map((r) => AnnotationReply.fromMap(r as Map<String, dynamic>))
            .toList();
      } on Object catch (e, stackTrace) {
        Log.custom('Annotation').warning(
          'Failed to parse annotation replies',
          data: {'error': e, 'stackTrace': stackTrace},
        );
      }
    }

    return Annotation(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      author: map['author'] as String?,
      type: type,
      color: map['color'] as String?,
      highlightedText: map['highlightedText'] as String?,
      startOffset: map['startOffset'] as int?,
      endOffset: map['endOffset'] as int?,
      replies: replies,
      isResolved: map['isResolved'] == true || map['isResolved'] == 1,
    );
  }

  /// 从JSON创建批注对象（用于API响应）
  factory Annotation.fromJson(Map<String, dynamic> json) =>
      Annotation.fromMap(json);

  /// 批注ID
  final String id;

  /// 批注内容
  final String content;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间（可选）
  final DateTime? updatedAt;

  /// 作者（可选，用于多人协作场景）
  final String? author;

  /// 批注类型
  final AnnotationType type;

  /// 高亮颜色（可选）
  final String? color;

  /// 被批注的原文（可选，用于文本选择批注）
  final String? highlightedText;

  /// 批注起始位置（可选，用于定位）
  final int? startOffset;

  /// 批注结束位置（可选，用于定位）
  final int? endOffset;

  /// 回复列表
  final List<AnnotationReply> replies;

  /// 是否已解决（用于问题类型）
  final bool isResolved;

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'author': author,
        'type': type.toString().split('.').last,
        'color': color,
        'highlightedText': highlightedText,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'replies': json.encode(replies.map((r) => r.toMap()).toList()),
        'isResolved': isResolved ? 1 : 0,
      };

  /// 转换为JSON（用于API请求）
  Map<String, dynamic> toJson() => toMap();

  /// 复制并修改批注
  Annotation copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? author,
    AnnotationType? type,
    String? color,
    String? highlightedText,
    int? startOffset,
    int? endOffset,
    List<AnnotationReply>? replies,
    bool? isResolved,
  }) =>
      Annotation(
        id: id ?? this.id,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        author: author ?? this.author,
        type: type ?? this.type,
        color: color ?? this.color,
        highlightedText: highlightedText ?? this.highlightedText,
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        replies: replies ?? this.replies,
        isResolved: isResolved ?? this.isResolved,
      );

  /// 获取批注类型图标
  IconData get typeIcon {
    switch (type) {
      case AnnotationType.comment:
        return Icons.comment_outlined;
      case AnnotationType.question:
        return Icons.help_outline;
      case AnnotationType.idea:
        return Icons.lightbulb_outline;
      case AnnotationType.important:
        return Icons.star_outline;
      case AnnotationType.todo:
        return Icons.check_box_outlined;
    }
  }

  /// 获取批注类型颜色
  Color get typeColor {
    switch (type) {
      case AnnotationType.comment:
        return Colors.blue;
      case AnnotationType.question:
        return Colors.orange;
      case AnnotationType.idea:
        return Colors.purple;
      case AnnotationType.important:
        return Colors.red;
      case AnnotationType.todo:
        return Colors.green;
    }
  }

  /// 获取批注类型文本（需要传入context获取国际化）
  String getTypeText(BuildContext context) {
    final localizations = AppLocalizationsSimple.of(context);
    switch (type) {
      case AnnotationType.comment:
        return localizations?.annotationTypeComment ?? '评论';
      case AnnotationType.question:
        return localizations?.annotationTypeQuestion ?? '问题';
      case AnnotationType.idea:
        return localizations?.annotationTypeIdea ?? '想法';
      case AnnotationType.important:
        return localizations?.annotationTypeImportant ?? '重要';
      case AnnotationType.todo:
        return localizations?.annotationTypeTodo ?? '待办';
    }
  }

  /// 获取批注类型文本（兼容旧版本，不需要context）
  String get typeText {
    switch (type) {
      case AnnotationType.comment:
        return '评论';
      case AnnotationType.question:
        return '问题';
      case AnnotationType.idea:
        return '想法';
      case AnnotationType.important:
        return '重要';
      case AnnotationType.todo:
        return '待办';
    }
  }

  @override
  String toString() =>
      'Annotation(id: $id, content: $content, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Annotation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 批注回复模型
class AnnotationReply {
  const AnnotationReply({
    required this.id,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory AnnotationReply.fromMap(Map<String, dynamic> map) => AnnotationReply(
        id: map['id'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        author: map['author'] as String?,
      );

  final String id;
  final String content;
  final DateTime createdAt;
  final String? author;

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'author': author,
      };
}

/// 批注列表工具类
class AnnotationList {
  /// 从JSON字符串解析批注列表
  static List<Annotation> fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Annotation.fromMap(json as Map<String, dynamic>))
          .toList();
    } on Object catch (e, stackTrace) {
      Log.custom('Annotation').warning(
        'Failed to parse annotation list',
        data: {'error': e, 'stackTrace': stackTrace},
      );
      return [];
    }
  }

  /// 将批注列表转换为JSON字符串
  static String toJsonString(List<Annotation> annotations) {
    if (annotations.isEmpty) {
      return '[]';
    }

    try {
      final jsonList = annotations.map((a) => a.toMap()).toList();
      return json.encode(jsonList);
    } on Object catch (e, stackTrace) {
      Log.custom('Annotation').warning(
        'Failed to serialize annotation list',
        data: {'error': e, 'stackTrace': stackTrace},
      );
      return '[]';
    }
  }
}
