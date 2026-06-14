import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/notion_field_mapping.dart';

/// Notion API 服务
/// 参考滴答清单的 Notion 集成实现
class NotionApiService {
  static const String _baseUrl = 'https://api.notion.com/v1';
  static const String _notionVersion = '2022-06-28';

  String? _accessToken;

  /// 设置访问令牌
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// 获取通用请求头
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'Notion-Version': _notionVersion,
        'Content-Type': 'application/json',
      };

  /// 测试连接
  Future<bool> testConnection() async {
    if (_accessToken == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } on Object catch (e) {
      debugPrint('Notion 连接测试失败: $e');
      return false;
    }
  }

  /// 搜索数据库
  Future<List<NotionDatabase>> searchDatabases() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: _headers,
        body: jsonEncode({
          'filter': {
            'property': 'object',
            'value': 'database',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results
            .map((db) => NotionDatabase.fromJson(db as Map<String, dynamic>))
            .toList();
      }

      throw Exception('搜索数据库失败: ${response.statusCode}');
    } on Object catch (e) {
      debugPrint('搜索 Notion 数据库失败: $e');
      rethrow;
    }
  }

  /// 获取数据库详情
  Future<NotionDatabase> getDatabase(String databaseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/databases/$databaseId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return NotionDatabase.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw Exception('获取数据库失败: ${response.statusCode}');
    } on Object catch (e) {
      debugPrint('获取 Notion 数据库失败: $e');
      rethrow;
    }
  }

  /// 创建页面（笔记）
  Future<String> createPage({
    required String databaseId,
    required String title,
    required String content,
    List<String>? tags,
    DateTime? createdAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pages'),
        headers: _headers,
        body: jsonEncode({
          'parent': {
            'database_id': databaseId,
          },
          'properties': {
            'Name': {
              'title': [
                {
                  'text': {
                    'content': title,
                  },
                },
              ],
            },
            if (tags != null && tags.isNotEmpty)
              'Tags': {
                'multi_select': tags.map((tag) => {'name': tag}).toList(),
              },
            if (createdAt != null)
              'Created': {
                'date': {
                  'start': createdAt.toIso8601String(),
                },
              },
          },
          'children': _buildContentBlocks(content),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'] as String;
      }

      throw Exception('创建页面失败: ${response.statusCode} - ${response.body}');
    } on Object catch (e) {
      debugPrint('创建 Notion 页面失败: $e');
      rethrow;
    }
  }

  /// 查询数据库（用于去重检查）
  Future<List<Map<String, dynamic>>> queryDatabase({
    required String databaseId,
    required String titleProperty,
    required String titleValue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/databases/$databaseId/query'),
        headers: _headers,
        body: jsonEncode({
          'filter': {
            'property': titleProperty,
            'title': {
              'equals': titleValue,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }

      return [];
    } on Object catch (e) {
      debugPrint('查询数据库失败: $e');
      return [];
    }
  }

  /// 使用字段映射创建页面
  Future<String> createPageWithMapping({
    required String databaseId,
    required String title,
    required String content,
    required NotionFieldMapping fieldMapping,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    try {
      final properties = <String, dynamic>{};

      // 标题属性（必需）
      if (fieldMapping.titleProperty != null) {
        properties[fieldMapping.titleProperty!] = {
          'title': [
            {
              'text': {
                'content': title,
              },
            },
          ],
        };
      }

      // 标签属性（可选）- 只有当映射了标签属性且有标签数据时才写入
      if (fieldMapping.tagsProperty != null &&
          fieldMapping.tagsProperty!.isNotEmpty &&
          tags != null &&
          tags.isNotEmpty) {
        // 如果只有一个标签，使用 select 格式（兼容单选和多选）
        // 如果有多个标签，使用 multi_select 格式
        if (tags.length == 1) {
          properties[fieldMapping.tagsProperty!] = {
            'select': {'name': tags.first},
          };
          debugPrint('  ✅ 将写入 1 个标签到属性: ${fieldMapping.tagsProperty} (单选格式)');
        } else {
          properties[fieldMapping.tagsProperty!] = {
            'multi_select': tags.map((tag) => {'name': tag}).toList(),
          };
          debugPrint(
            '  ✅ 将写入 ${tags.length} 个标签到属性: ${fieldMapping.tagsProperty} (多选格式)',
          );
        }
      } else if (tags != null && tags.isNotEmpty) {
        debugPrint('  ⚠️ 笔记有 ${tags.length} 个标签，但未配置标签映射，将跳过');
      }

      // 创建时间属性（可选）
      // 注意：created_time 是系统属性，只读，不能写入
      if (fieldMapping.createdProperty != null &&
          fieldMapping.createdProperty!.isNotEmpty &&
          createdAt != null) {
        // 只有普通 date 类型才能写入，系统属性跳过
        if (!fieldMapping.createdProperty!
            .toLowerCase()
            .contains('created_time')) {
          properties[fieldMapping.createdProperty!] = {
            'date': {
              'start': createdAt.toIso8601String(),
            },
          };
          debugPrint('  ✅ 将写入创建时间到属性: ${fieldMapping.createdProperty}');
        } else {
          debugPrint('  ⚠️ ${fieldMapping.createdProperty} 是系统属性，只读，跳过写入');
        }
      }

      // 更新时间属性（可选）
      // 注意：last_edited_time 是系统属性，只读，不能写入
      if (fieldMapping.updatedProperty != null &&
          fieldMapping.updatedProperty!.isNotEmpty &&
          updatedAt != null) {
        // 只有普通 date 类型才能写入，系统属性跳过
        if (!fieldMapping.updatedProperty!
                .toLowerCase()
                .contains('last_edited') &&
            !fieldMapping.updatedProperty!
                .toLowerCase()
                .contains('edited_time')) {
          properties[fieldMapping.updatedProperty!] = {
            'date': {
              'start': updatedAt.toIso8601String(),
            },
          };
          debugPrint('  ✅ 将写入更新时间到属性: ${fieldMapping.updatedProperty}');
        } else {
          debugPrint('  ⚠️ ${fieldMapping.updatedProperty} 是系统属性，只读，跳过写入');
        }
      }

      // 内容属性（可选）
      // 如果映射了内容属性，写入 rich_text；否则写入页面正文（blocks）
      var writeContentToProperty = false;
      if (fieldMapping.contentProperty != null &&
          fieldMapping.contentProperty!.isNotEmpty &&
          content.isNotEmpty) {
        properties[fieldMapping.contentProperty!] = {
          'rich_text': [
            {
              'text': {
                'content': content.length > 2000
                    ? content.substring(0, 2000)
                    : content,
              },
            },
          ],
        };
        writeContentToProperty = true;
        debugPrint(
          '  ✅ 将写入内容到属性: ${fieldMapping.contentProperty} (${content.length} 字符)',
        );
        if (content.length > 2000) {
          debugPrint('  ⚠️ 内容超过 2000 字符，已截断');
        }
      }

      debugPrint('📤 创建 Notion 页面，使用映射:');
      debugPrint('  标题属性: ${fieldMapping.titleProperty}');
      debugPrint('  内容属性: ${fieldMapping.contentProperty ?? "无（写入页面正文）"}');
      debugPrint('  标签属性: ${fieldMapping.tagsProperty}');
      debugPrint('  创建时间属性: ${fieldMapping.createdProperty}');
      debugPrint('  更新时间属性: ${fieldMapping.updatedProperty}');

      final body = <String, dynamic>{
        'parent': {
          'database_id': databaseId,
        },
        'properties': properties,
      };

      // 如果内容没有写入属性，则写入页面正文
      if (!writeContentToProperty) {
        body['children'] = _buildContentBlocks(content);
        debugPrint('  📄 内容将写入页面正文 (${content.length} 字符)');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/pages'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ 页面创建成功: ${data['id']}');
        return data['id'] as String;
      }

      throw Exception('创建页面失败: ${response.statusCode} - ${response.body}');
    } on Object catch (e) {
      debugPrint('创建 Notion 页面失败: $e');
      rethrow;
    }
  }

  /// 更新页面
  Future<void> updatePage({
    required String pageId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    try {
      // 1. 更新页面属性
      final properties = <String, dynamic>{};

      if (title != null) {
        properties['Name'] = {
          'title': [
            {
              'text': {
                'content': title,
              },
            },
          ],
        };
      }

      if (tags != null) {
        properties['Tags'] = {
          'multi_select': tags.map((tag) => {'name': tag}).toList(),
        };
      }

      if (properties.isNotEmpty) {
        await http.patch(
          Uri.parse('$_baseUrl/pages/$pageId'),
          headers: _headers,
          body: jsonEncode({'properties': properties}),
        );
      }

      // 2. 更新页面内容（如果提供）
      if (content != null) {
        // 先删除旧内容
        await _deletePageContent(pageId);
        // 添加新内容
        await _appendPageContent(pageId, content);
      }
    } on Object catch (e) {
      debugPrint('更新 Notion 页面失败: $e');
      rethrow;
    }
  }

  /// 使用字段映射更新页面
  Future<void> updatePageWithMapping({
    required String pageId,
    required String title,
    required String content,
    required NotionFieldMapping fieldMapping,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    try {
      final properties = <String, dynamic>{};

      // 标题属性
      if (fieldMapping.titleProperty != null) {
        properties[fieldMapping.titleProperty!] = {
          'title': [
            {
              'text': {'content': title},
            },
          ],
        };
      }

      // 标签属性
      if (fieldMapping.tagsProperty != null &&
          fieldMapping.tagsProperty!.isNotEmpty &&
          tags != null &&
          tags.isNotEmpty) {
        if (tags.length == 1) {
          properties[fieldMapping.tagsProperty!] = {
            'select': {'name': tags.first},
          };
        } else {
          properties[fieldMapping.tagsProperty!] = {
            'multi_select': tags.map((tag) => {'name': tag}).toList(),
          };
        }
      }

      // 内容属性
      var updateContentProperty = false;
      if (fieldMapping.contentProperty != null &&
          fieldMapping.contentProperty!.isNotEmpty &&
          content.isNotEmpty) {
        properties[fieldMapping.contentProperty!] = {
          'rich_text': [
            {
              'text': {
                'content': content.length > 2000
                    ? content.substring(0, 2000)
                    : content,
              },
            },
          ],
        };
        updateContentProperty = true;
      }

      // 更新属性
      if (properties.isNotEmpty) {
        await http.patch(
          Uri.parse('$_baseUrl/pages/$pageId'),
          headers: _headers,
          body: jsonEncode({'properties': properties}),
        );
      }

      // 更新页面正文（如果内容没有写入属性）
      if (!updateContentProperty && content.isNotEmpty) {
        await _deletePageContent(pageId);
        await _appendPageContent(pageId, content);
      }

      debugPrint('✅ 页面更新成功: $pageId');
    } on Object catch (e) {
      debugPrint('更新 Notion 页面失败: $e');
      rethrow;
    }
  }

  /// 删除页面（归档）
  Future<void> deletePage(String pageId) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/pages/$pageId'),
        headers: _headers,
        body: jsonEncode({
          'archived': true,
        }),
      );
    } on Object catch (e) {
      debugPrint('删除 Notion 页面失败: $e');
      rethrow;
    }
  }

  /// 查询数据库中的页面
  Future<List<NotionPage>> queryDatabasePages(String databaseId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/databases/$databaseId/query'),
        headers: _headers,
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results
            .map((page) => NotionPage.fromJson(page as Map<String, dynamic>))
            .toList();
      }

      throw Exception('查询数据库失败: ${response.statusCode}');
    } on Object catch (e) {
      debugPrint('查询 Notion 数据库失败: $e');
      rethrow;
    }
  }

  /// 获取页面内容
  Future<String> getPageContent(String pageId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/blocks/$pageId/children'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final blocks = data['results'] as List<dynamic>;
        return _parseBlocks(blocks);
      }

      throw Exception('获取页面内容失败: ${response.statusCode}');
    } on Object catch (e) {
      debugPrint('获取 Notion 页面内容失败: $e');
      rethrow;
    }
  }

  // ========== 私有辅助方法 ==========

  /// 构建内容块
  List<Map<String, dynamic>> _buildContentBlocks(String content) {
    debugPrint('📝 构建内容块，内容长度: ${content.length} 字符');
    final blocks = <Map<String, dynamic>>[];

    if (content.trim().isEmpty) {
      debugPrint('  ⚠️ 内容为空，不创建内容块');
      return blocks;
    }

    // 将内容按段落分割
    final paragraphs = content.split('\n\n');

    for (final paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        continue;
      }

      // 检查是否是标题
      if (paragraph.startsWith('# ')) {
        blocks.add({
          'object': 'block',
          'type': 'heading_1',
          'heading_1': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': paragraph.substring(2)},
              },
            ],
          },
        });
      } else if (paragraph.startsWith('## ')) {
        blocks.add({
          'object': 'block',
          'type': 'heading_2',
          'heading_2': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': paragraph.substring(3)},
              },
            ],
          },
        });
      } else if (paragraph.startsWith('> ')) {
        // 引用块
        blocks.add({
          'object': 'block',
          'type': 'quote',
          'quote': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': paragraph.substring(2)},
              },
            ],
          },
        });
      } else {
        // 普通段落
        blocks.add({
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': paragraph},
              },
            ],
          },
        });
      }
    }

    debugPrint('  ✅ 创建了 ${blocks.length} 个内容块');
    return blocks;
  }

  /// 解析块内容
  String _parseBlocks(List<dynamic> blocks) {
    final buffer = StringBuffer();

    for (final rawBlock in blocks) {
      final block = rawBlock as Map<String, dynamic>;
      final type = block['type'];

      switch (type) {
        case 'paragraph':
          buffer.writeln(_extractBlockRichText(block, 'paragraph'));
          break;
        case 'heading_1':
          buffer.writeln('# ${_extractBlockRichText(block, 'heading_1')}');
          break;
        case 'heading_2':
          buffer.writeln('## ${_extractBlockRichText(block, 'heading_2')}');
          break;
        case 'heading_3':
          buffer.writeln('### ${_extractBlockRichText(block, 'heading_3')}');
          break;
        case 'quote':
          buffer.writeln('> ${_extractBlockRichText(block, 'quote')}');
          break;
        case 'bulleted_list_item':
          buffer.writeln(
            '- ${_extractBlockRichText(block, 'bulleted_list_item')}',
          );
          break;
        case 'numbered_list_item':
          buffer.writeln(
            '1. ${_extractBlockRichText(block, 'numbered_list_item')}',
          );
          break;
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  String _extractBlockRichText(Map<String, dynamic> block, String key) {
    final typedBlock = block[key] as Map<String, dynamic>?;
    final richText = typedBlock?['rich_text'] as List<dynamic>? ?? <dynamic>[];
    return _extractRichText(richText);
  }

  /// 提取富文本内容
  String _extractRichText(List<dynamic> richText) => richText.map((rawText) {
        final text = rawText as Map<String, dynamic>;
        final textValue = text['text'] as Map<String, dynamic>?;
        return text['plain_text'] ?? textValue?['content'] ?? '';
      }).join();

  /// 删除页面内容
  Future<void> _deletePageContent(String pageId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/blocks/$pageId/children'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final blocks = data['results'] as List<dynamic>;

      for (final rawBlock in blocks) {
        final block = rawBlock as Map<String, dynamic>;
        await http.delete(
          Uri.parse('$_baseUrl/blocks/${block['id'] as String}'),
          headers: _headers,
        );
      }
    }
  }

  /// 追加页面内容
  Future<void> _appendPageContent(String pageId, String content) async {
    await http.patch(
      Uri.parse('$_baseUrl/blocks/$pageId/children'),
      headers: _headers,
      body: jsonEncode({
        'children': _buildContentBlocks(content),
      }),
    );
  }
}

/// Notion 数据库模型
class NotionDatabase {
  // 解析后的属性列表

  NotionDatabase({
    required this.id,
    required this.title,
    required this.properties,
    required this.propertyList,
  });

  factory NotionDatabase.fromJson(Map<String, dynamic> json) {
    final titleList = json['title'] as List<dynamic>;
    final title = titleList.isNotEmpty
        ? (titleList.first as Map<String, dynamic>)['plain_text'] as String? ??
            'Untitled'
        : 'Untitled';

    // 解析属性列表
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    final propertyList = <NotionProperty>[];

    debugPrint('📊 解析 Notion 数据库: $title');
    debugPrint('  数据库 ID: ${json['id']}');
    debugPrint('  属性列表:');

    properties.forEach((name, rawConfig) {
      final config = rawConfig as Map<String, dynamic>;
      final type = config['type'] as String?;
      if (type != null) {
        propertyList.add(
          NotionProperty(
            name: name,
            type: type,
            id: config['id'] as String?,
          ),
        );
        debugPrint('    - $name (类型: $type)');
      }
    });

    return NotionDatabase(
      id: json['id'] as String,
      title: title,
      properties: properties,
      propertyList: propertyList,
    );
  }
  final String id;
  final String title;
  final Map<String, dynamic> properties;
  final List<NotionProperty> propertyList;

  /// 获取指定类型的属性列表
  List<NotionProperty> getPropertiesByType(String type) =>
      propertyList.where((p) => p.type == type).toList();

  /// 获取标题属性
  NotionProperty? getTitleProperty() {
    try {
      return propertyList.firstWhere((p) => p.type == 'title');
    } on Object {
      return null;
    }
  }
}

/// Notion 页面模型
class NotionPage {
  NotionPage({
    required this.id,
    required this.title,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  factory NotionPage.fromJson(Map<String, dynamic> json) {
    // 提取标题
    var title = 'Untitled';
    final properties = json['properties'] as Map<String, dynamic>?;
    if (properties != null && properties['Name'] != null) {
      final nameProperty = properties['Name'] as Map<String, dynamic>;
      final titleList = nameProperty['title'] as List<dynamic>;
      if (titleList.isNotEmpty) {
        title = (titleList.first as Map<String, dynamic>)['plain_text']
                as String? ??
            'Untitled';
      }
    }

    // 提取标签
    var tags = <String>[];
    if (properties != null && properties['Tags'] != null) {
      final tagsProperty = properties['Tags'] as Map<String, dynamic>;
      final tagList = tagsProperty['multi_select'] as List<dynamic>;
      tags = tagList
          .map((tag) => (tag as Map<String, dynamic>)['name'] as String)
          .toList();
    }

    // 提取时间
    DateTime? createdAt;
    if (properties != null && properties['Created'] != null) {
      final createdProperty = properties['Created'] as Map<String, dynamic>;
      final createdDate = createdProperty['date'] as Map<String, dynamic>?;
      final dateStr = createdDate?['start'] as String?;
      if (dateStr != null) {
        createdAt = DateTime.parse(dateStr);
      }
    }

    return NotionPage(
      id: json['id'] as String,
      title: title,
      tags: tags,
      createdAt: createdAt,
      updatedAt: json['last_edited_time'] != null
          ? DateTime.parse(json['last_edited_time'] as String)
          : null,
    );
  }
  final String id;
  final String title;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
