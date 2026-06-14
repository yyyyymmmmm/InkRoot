import 'package:flutter/foundation.dart';

/// Notion 字段映射配置
/// 定义笔记字段如何映射到 Notion 属性
class NotionFieldMapping {
  // 更新时间 → Notion 日期属性名

  NotionFieldMapping({
    this.titleProperty,
    this.contentProperty,
    this.tagsProperty,
    this.createdProperty,
    this.updatedProperty,
  });

  /// 从 JSON 创建
  factory NotionFieldMapping.fromJson(Map<String, dynamic> json) =>
      NotionFieldMapping(
        titleProperty: json['titleProperty'] as String?,
        contentProperty: json['contentProperty'] as String?,
        tagsProperty: json['tagsProperty'] as String?,
        createdProperty: json['createdProperty'] as String?,
        updatedProperty: json['updatedProperty'] as String?,
      );

  /// 创建默认映射（智能匹配）
  factory NotionFieldMapping.createDefault(List<NotionProperty> properties) {
    String? titleProp;
    String? tagsProp;
    String? createdProp;
    String? updatedProp;

    debugPrint('🔍 开始智能匹配字段映射...');

    for (final prop in properties) {
      final name = prop.name;
      final type = prop.type;
      final nameLower = name.toLowerCase();

      // 智能匹配标题属性
      if (type == 'title' && titleProp == null) {
        titleProp = name;
        debugPrint('  ✅ 标题属性: $name');
      }

      // 智能匹配标签属性（支持中英文，支持 select 和 multi_select）
      if ((type == 'multi_select' || type == 'select') && tagsProp == null) {
        if (nameLower.contains('tag') ||
            nameLower.contains('标签') ||
            name == 'tags' ||
            name == 'Tags' ||
            name == '标签') {
          tagsProp = name;
          debugPrint('  ✅ 标签属性: $name (类型: $type)');
        }
      }

      // 智能匹配创建时间（支持中英文，支持 date 和 created_time 类型）
      if ((type == 'date' || type == 'created_time') && createdProp == null) {
        if (type == 'created_time' ||
            nameLower.contains('create') ||
            nameLower.contains('创建') ||
            name == 'created' ||
            name == 'Created' ||
            name == '创建时间' ||
            name == 'Created Time' ||
            name == 'created_time') {
          createdProp = name;
          debugPrint('  ✅ 创建时间属性: $name (类型: $type)');
        }
      }

      // 智能匹配更新时间（支持中英文，支持 date 和 last_edited_time 类型）
      if ((type == 'date' || type == 'last_edited_time') &&
          updatedProp == null) {
        if (type == 'last_edited_time' ||
            nameLower.contains('update') ||
            nameLower.contains('更新') ||
            nameLower.contains('edit') ||
            nameLower.contains('编辑') ||
            nameLower.contains('修改') ||
            name == 'updated' ||
            name == 'Updated' ||
            name == '更新时间' ||
            name == '编辑时间' ||
            name == '修改时间' ||
            name == 'Updated Time' ||
            name == 'Last Edited' ||
            name == 'last_edited' ||
            name == 'updated_time') {
          updatedProp = name;
          debugPrint('  ✅ 更新时间属性: $name (类型: $type)');
        }
      }
    }

    // 如果没有匹配到标签，尝试使用第一个 multi_select 或 select 属性
    if (tagsProp == null) {
      for (final prop in properties) {
        if (prop.type == 'multi_select' || prop.type == 'select') {
          tagsProp = prop.name;
          debugPrint('  ⚠️ 使用第一个选择属性作为标签: $tagsProp (类型: ${prop.type})');
          break;
        }
      }
    }

    // 如果没有匹配到日期，尝试使用系统属性或前两个 date 属性
    if (createdProp == null || updatedProp == null) {
      // 优先使用系统属性
      for (final prop in properties) {
        if (createdProp == null && prop.type == 'created_time') {
          createdProp = prop.name;
          debugPrint('  ⚠️ 使用系统创建时间属性: $createdProp');
        }
        if (updatedProp == null && prop.type == 'last_edited_time') {
          updatedProp = prop.name;
          debugPrint('  ⚠️ 使用系统编辑时间属性: $updatedProp');
        }
      }

      // 如果还没有，使用普通 date 属性
      if (createdProp == null || updatedProp == null) {
        var dateCount = 0;
        for (final prop in properties) {
          if (prop.type == 'date') {
            if (createdProp == null && dateCount == 0) {
              createdProp = prop.name;
              debugPrint('  ⚠️ 使用第一个日期属性作为创建时间: $createdProp');
            } else if (updatedProp == null && dateCount == 1) {
              updatedProp = prop.name;
              debugPrint('  ⚠️ 使用第二个日期属性作为更新时间: $updatedProp');
            }
            dateCount++;
          }
        }
      }
    }

    return NotionFieldMapping(
      titleProperty: titleProp,
      tagsProperty: tagsProp,
      createdProperty: createdProp,
      updatedProperty: updatedProp,
    );
  }
  final String? titleProperty; // 笔记标题 → Notion 标题属性名
  final String? contentProperty; // 笔记内容 → Notion 富文本属性名（可选）
  final String? tagsProperty; // 笔记标签 → Notion 多选属性名
  final String? createdProperty; // 创建时间 → Notion 日期属性名
  final String? updatedProperty;

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'titleProperty': titleProperty,
        'contentProperty': contentProperty,
        'tagsProperty': tagsProperty,
        'createdProperty': createdProperty,
        'updatedProperty': updatedProperty,
      };

  /// 复制并修改
  NotionFieldMapping copyWith({
    String? titleProperty,
    String? contentProperty,
    String? tagsProperty,
    String? createdProperty,
    String? updatedProperty,
  }) =>
      NotionFieldMapping(
        titleProperty: titleProperty ?? this.titleProperty,
        contentProperty: contentProperty ?? this.contentProperty,
        tagsProperty: tagsProperty ?? this.tagsProperty,
        createdProperty: createdProperty ?? this.createdProperty,
        updatedProperty: updatedProperty ?? this.updatedProperty,
      );

  /// 是否已配置完整
  bool get isComplete {
    return titleProperty != null; // 至少需要标题映射
  }
}

/// Notion 属性模型
class NotionProperty {
  NotionProperty({
    required this.name,
    required this.type,
    this.id,
  });

  final String name;
  final String type; // title, rich_text, multi_select, date, etc.
  final String? id;

  /// 获取属性类型的显示名称
  String get typeDisplayName {
    switch (type) {
      case 'title':
        return '标题';
      case 'rich_text':
        return '文本';
      case 'multi_select':
        return '多选';
      case 'select':
        return '单选';
      case 'date':
        return '日期';
      case 'number':
        return '数字';
      case 'checkbox':
        return '复选框';
      case 'url':
        return '链接';
      case 'email':
        return '邮箱';
      case 'phone_number':
        return '电话';
      case 'people':
        return '人员';
      case 'files':
        return '文件';
      case 'relation':
        return '关联';
      case 'formula':
        return '公式';
      case 'rollup':
        return '汇总';
      case 'created_time':
        return '创建时间';
      case 'created_by':
        return '创建人';
      case 'last_edited_time':
        return '最后编辑时间';
      case 'last_edited_by':
        return '最后编辑人';
      default:
        return type;
    }
  }
}
