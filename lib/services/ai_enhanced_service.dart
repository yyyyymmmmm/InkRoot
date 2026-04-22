import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/ai_insight_engine.dart';

/// 🚀 AI 功能增强服务 - 超越大厂版
///
/// 提供三大核心功能：
/// 1. 🏷️ 智能标签生成
/// 2. 📝 智能摘要生成（革命性引擎）
/// 3. ✨ AI 内容续写（革命性引擎）
class AIEnhancedService {
  final AIInsightEngine _engine = AIInsightEngine();
  /// 1. 🏷️ 智能标签生成（个性化 + 上下文增强）
  ///
  /// 根据笔记内容、历史标签、相关笔记智能提取 3-5 个精准标签
  /// 返回格式：(标签列表, 错误信息)
  Future<(List<String>?, String?)> generateTags({
    required String content,
    required String apiKey,
    required String apiUrl,
    required String model,
    List<Note>? allNotes, // 🔥 新增：用于分析历史标签
  }) async {
    try {
      if (content.trim().isEmpty) {
        return (null, '笔记内容为空');
      }

      final cleanContent = _truncateText(content, 1000);

      // 🔥 分析用户的历史标签（个性化）
      final userTagStats = _analyzeUserTags(allNotes ?? []);
      final topUserTags = userTagStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final userTagsHint = topUserTags.isEmpty 
          ? '' 
          : '\n【用户常用标签】\n${topUserTags.take(10).map((e) => '${e.key} (用过${e.value}次)').join('、')}\n';

      final prompt = '''请为以下笔记内容生成 3-5 个精准的标签关键词。
$userTagsHint
笔记内容：
$cleanContent

要求：
1. 标签要精准、简洁（2-6个字）
2. 优先提取核心主题词、技术名词、领域关键词
3. 如果笔记主题与用户常用标签相关，优先使用用户已有标签（保持标签体系一致性）
4. 每行一个标签，不要编号，不要其他文字
5. 标签不要带 # 符号

示例输出：
Flutter
移动开发
状态管理
''';

      final response = await http
          .post(
            Uri.parse('$apiUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: json.encode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': '你是一个专业的知识管理助手，擅长为笔记生成精准标签并保持用户标签体系的一致性。',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.3,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final result = data['choices']?[0]?['message']?['content'] as String?;

        if (result != null) {
          final tags = _parseTags(result);
          return (tags.isEmpty ? null : tags, null);
        }
      }

      return (null, 'AI 响应格式错误');
    } catch (e) {
      debugPrint('❌ 生成标签失败: $e');
      return (null, '生成失败: $e');
    }
  }

  /// 🔥 分析用户的历史标签使用频率
  Map<String, int> _analyzeUserTags(List<Note> notes) {
    final tagFrequency = <String, int>{};
    
    for (final note in notes) {
      // 提取标签（假设标签格式为 #标签）
      final tagRegex = RegExp(r'#(\S+)');
      final matches = tagRegex.allMatches(note.content);
      
      for (final match in matches) {
        final tag = match.group(1);
        if (tag != null && tag.length >= 2 && tag.length <= 20) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }
    }
    
    return tagFrequency;
  }

  /// 2. 📝 生成智能摘要（革命性引擎）
  ///
  /// 为长笔记生成精炼摘要（100字内）
  /// 返回格式：(摘要内容, 错误信息)
  Future<(String?, String?)> generateSummary({
    required String content,
    required String apiKey,
    required String apiUrl,
    required String model,
    List<Note>? allNotes, // 🔥 新增：上下文笔记
  }) async {
    try {
      if (content.trim().isEmpty) {
        return (null, '笔记内容为空');
      }

      // 内容太短不需要摘要
      if (content.length < 200) {
        return (null, '内容太短，无需生成摘要');
      }

      // 🚀 使用革命性引擎
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _engine.analyze(
        note: note,
        allNotes: allNotes ?? [],
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        type: AnalysisType.summary,
      );

      if (result.content.startsWith('分析失败')) {
        return (null, result.content);
      }

      return (result.content, null);
    } catch (e) {
      debugPrint('❌ 生成摘要失败: $e');
      return (null, '生成失败: $e');
    }
  }

  /// 🎯 AI 智能点评（革命性引擎）
  ///
  /// 深度分析笔记，给出洞察和建议
  /// 返回格式：(点评内容, 错误信息)
  Future<(String?, String?)> generateInsight({
    required String content,
    required String apiKey,
    required String apiUrl,
    required String model,
    List<Note>? allNotes, // 🔥 新增：上下文笔记
    String? customPrompt, // 🔥 新增：自定义提示词
  }) async {
    try {
      if (content.trim().isEmpty) {
        return (null, '笔记内容为空');
      }

      // 🚀 使用革命性引擎
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _engine.analyze(
        note: note,
        allNotes: allNotes ?? [],
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        type: AnalysisType.insight,
        customPrompt: customPrompt, // 🔥 传递自定义提示词
      );

      if (result.content.startsWith('分析失败')) {
        return (null, result.content);
      }

      return (result.content, null);
    } catch (e) {
      debugPrint('❌ AI点评失败: $e');
      return (null, 'AI点评失败: $e');
    }
  }

  /// 3. ✨ AI 内容续写（革命性引擎）
  ///
  /// 基于已有内容智能续写
  /// 返回格式：(续写内容, 错误信息)
  Future<(String?, String?)> continueWriting({
    required String content,
    required String apiKey,
    required String apiUrl,
    required String model,
    int maxLength = 200,
    List<Note>? allNotes, // 🔥 新增：上下文笔记
    String? customPrompt, // 🔥 新增：自定义提示词
  }) async {
    try {
      if (content.trim().isEmpty) {
        return (null, '请先输入一些内容');
      }

      // 🚀 使用革命性引擎
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await _engine.analyze(
        note: note,
        allNotes: allNotes ?? [],
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
        type: AnalysisType.continuation,
        customPrompt: customPrompt, // 🔥 传递自定义提示词
      );

      if (result.content.startsWith('分析失败')) {
        return (null, result.content);
      }

      return (result.content, null);
    } catch (e) {
      debugPrint('❌ 续写失败: $e');
      return (null, '续写失败: $e');
    }
  }

  /// 解析标签
  List<String> _parseTags(String text) {
    final tags = <String>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line
          .trim()
          .replaceAll(RegExp(r'^[0-9\.\-\*\+]+\s*'), '') // 移除编号
          .replaceAll(RegExp(r'^[#]+\s*'), '') // 移除 #
          .trim();

      if (trimmed.isNotEmpty && trimmed.length <= 20) {
        tags.add(trimmed);
      }
    }

    return tags.take(5).toList();
  }

  /// 截断文本
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }
}
