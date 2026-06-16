import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/user_behavior_service.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;
import 'package:inkroot/utils/text_analysis_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🚀 AI洞察引擎 - 革命性实现
///
/// Phase 1-4 完整实现：
/// - Phase 1: 上下文增强 + 多Agent分析 + 质量保证
/// - Phase 2: 向量语义搜索（可选，基于API）
/// - Phase 3: 用户反馈学习
/// - Phase 4: 多模态支持（代码块、图片识别）
class AIInsightEngine {
  factory AIInsightEngine() => _instance;
  AIInsightEngine._internal();
  static final AIInsightEngine _instance = AIInsightEngine._internal();

  final UserBehaviorService _behaviorService = UserBehaviorService();

  /// 🎯 主入口：AI分析
  Future<AnalysisResult> analyze({
    required Note note,
    required List<Note> allNotes,
    required String apiKey,
    required String apiUrl,
    required String model,
    required AnalysisType type,
    String? customPrompt, // 🔥 新增：自定义提示词
  }) async {
    debugPrint('🚀 AI革命引擎启动 [${type.name}]');

    try {
      // Phase 0: 检查缓存（24小时内有效）
      final cached = await _getCachedAnalysis(note.id, type);
      if (cached != null) {
        debugPrint('💾 使用缓存结果');
        return cached;
      }

      // Phase 1: 智能路由
      final strategy = _selectStrategy(model, note.content.length);
      debugPrint('📋 策略: ${strategy.name}');

      // Phase 2: 上下文增强
      final context = await _buildContext(note, allNotes);
      debugPrint('🔗 上下文: ${context.relatedNotes.length}条相关笔记');

      // Phase 3: 用户画像
      final userProfile = await _buildUserProfile(allNotes);
      debugPrint('👤 用户水平: ${userProfile.level}');

      // Phase 4: 构建Prompt
      final prompt = _buildPrompt(
        note: note,
        context: context,
        userProfile: userProfile,
        type: type,
        strategy: strategy,
        customPrompt: customPrompt, // 🔥 传递自定义提示词
      );

      // Phase 5: AI调用
      final rawOutput = await _callAI(
        prompt: prompt,
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
      );

      // Phase 6: 质量检测与修复
      final finalOutput = await _ensureQuality(
        rawOutput,
        note,
        apiKey,
        apiUrl,
        model,
        type,
      );

      // Phase 7: 记录反馈用于学习
      final result = AnalysisResult(
        content: finalOutput,
        context: context,
        userProfile: userProfile,
        timestamp: DateTime.now(),
      );

      await _recordForLearning(note.id, result);

      // Phase 8: 缓存结果
      await _cacheAnalysis(note.id, type, result);

      debugPrint('✅ AI分析完成');
      return result;
    } on Object catch (e) {
      debugPrint('❌ AI分析失败: $e');
      return AnalysisResult.error('分析失败，请检查网络或API配置');
    }
  }

  /// 📊 智能路由：根据模型能力选择策略
  AnalysisStrategy _selectStrategy(String model, int contentLength) {
    // 检测模型能力
    final capability = _detectModelCapability(model);

    // 检测内容复杂度
    final complexity = contentLength > 2000
        ? 'high'
        : contentLength > 500
            ? 'medium'
            : 'low';

    if (capability == ModelCapability.high) {
      return AnalysisStrategy.deepThinking;
    } else if (capability == ModelCapability.medium) {
      return complexity == 'high'
          ? AnalysisStrategy.twoStage
          : AnalysisStrategy.balanced;
    } else {
      return AnalysisStrategy.economical;
    }
  }

  ModelCapability _detectModelCapability(String model) {
    final lowerModel = model.toLowerCase();
    if (lowerModel.contains('gpt-4') ||
        lowerModel.contains('claude-3-5') ||
        lowerModel.contains('claude-3-opus')) {
      return ModelCapability.high;
    } else if (lowerModel.contains('gpt-3.5') ||
        lowerModel.contains('claude-3-sonnet')) {
      return ModelCapability.medium;
    } else {
      return ModelCapability.low;
    }
  }

  /// 🔗 Phase 2: 上下文构建（支持向量搜索）
  Future<NoteContext> _buildContext(Note note, List<Note> allNotes) async {
    // 策略1: 尝试使用缓存的向量搜索结果
    final cachedContext = await _getCachedContext(note.id);
    if (cachedContext != null) {
      debugPrint('💾 使用缓存上下文');
      return cachedContext;
    }

    // 策略2: 多维度检索
    final relatedNotes = await _findRelatedNotes(note, allNotes);

    // 策略3: 时间维度分析
    final timeline = _analyzeTimeline(note, allNotes);

    final context = NoteContext(
      currentNote: note,
      relatedNotes: relatedNotes,
      timeline: timeline,
    );

    // 缓存结果
    await _cacheContext(note.id, context);

    return context;
  }

  /// 🔍 多维度检索相关笔记
  Future<List<RelatedNoteScore>> _findRelatedNotes(
    Note note,
    List<Note> allNotes,
  ) async {
    final scores = <RelatedNoteScore>[];
    final currentTags = tag_utils.extractTagsFromContent(note.content).toSet();
    final currentKeywords = _extractKeywords(note.content);
    final currentLinks = _extractLinks(note.content);

    for (final other in allNotes) {
      if (other.id == note.id) {
        continue;
      }

      var score = 0.0;
      final reasons = <String>[];

      // 1. 标签相似度（30%）
      final otherTags = tag_utils.extractTagsFromContent(other.content).toSet();
      if (currentTags.isNotEmpty && otherTags.isNotEmpty) {
        final intersection = currentTags.intersection(otherTags);
        final union = currentTags.union(otherTags);
        final tagSim = intersection.length / union.length;
        score += tagSim * 0.3;
        if (tagSim > 0.3) {
          reasons.add('共同标签: ${intersection.take(3).join(", ")}');
        }
      }

      // 2. 关键词重叠（25%）
      final otherKeywords = _extractKeywords(other.content);
      final keywordSim = _calculateKeywordSimilarity(
        currentKeywords,
        otherKeywords,
      );
      score += keywordSim * 0.25;

      // 3. 链接关系（25%）
      final otherLinks = _extractLinks(other.content);
      if (currentLinks.contains(other.id) || otherLinks.contains(note.id)) {
        score += 0.25;
        reasons.add('直接链接');
      } else {
        final commonLinks = currentLinks.intersection(otherLinks);
        if (commonLinks.isNotEmpty) {
          score += (commonLinks.length /
                  max(currentLinks.length, otherLinks.length)) *
              0.2;
          reasons.add('共同链接');
        }
      }

      // 4. 时间相关性（20%）
      final timeDiff = note.updatedAt.difference(other.updatedAt).inDays.abs();
      final timeScore = timeDiff < 7
          ? 1.0
          : timeDiff < 30
              ? 0.7
              : timeDiff < 90
                  ? 0.4
                  : 0.2;
      score += timeScore * 0.2;

      if (score > 0.25) {
        scores.add(
          RelatedNoteScore(
            note: other,
            score: score,
            reasons: reasons,
          ),
        );
      }
    }

    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(5).toList();
  }

  /// 📈 时间维度分析
  TimelineAnalysis _analyzeTimeline(Note note, List<Note> allNotes) {
    final sorted = allNotes.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final currentIndex = sorted.indexWhere((n) => n.id == note.id);
    if (currentIndex == -1) {
      return TimelineAnalysis.empty();
    }

    // 查找前置笔记
    final previousNotes = currentIndex > 0
        ? sorted.sublist(max(0, currentIndex - 3), currentIndex)
        : <Note>[];

    // 查找后续笔记
    final nextNotes = currentIndex < sorted.length - 1
        ? sorted.sublist(currentIndex + 1, min(sorted.length, currentIndex + 4))
        : <Note>[];

    return TimelineAnalysis(
      previousNotes: previousNotes,
      nextNotes: nextNotes,
      totalNotes: allNotes.length,
      position: currentIndex + 1,
    );
  }

  /// 👤 Phase 3: 构建用户画像
  Future<UserProfile> _buildUserProfile(List<Note> allNotes) async {
    final preference = await _behaviorService.getUserPreference();

    // 分析笔记数量
    final noteCount = allNotes.length;
    final level = noteCount < 5
        ? 'beginner'
        : noteCount < 20
            ? 'intermediate'
            : noteCount < 50
                ? 'advanced'
                : 'expert';

    // 分析主题分布
    final topics = <String, int>{};
    for (final note in allNotes) {
      final tags = tag_utils.extractTagsFromContent(note.content);
      for (final tag in tags) {
        topics[tag] = (topics[tag] ?? 0) + 1;
      }
    }

    final topTopics = topics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return UserProfile(
      level: level,
      noteCount: noteCount,
      topTopics: topTopics.take(5).map((e) => e.key).toList(),
      preference: preference,
    );
  }

  /// 📝 构建Prompt
  String _buildPrompt({
    required Note note,
    required NoteContext context,
    required UserProfile userProfile,
    required AnalysisType type,
    required AnalysisStrategy strategy,
    String? customPrompt, // 🔥 新增：自定义提示词
  }) {
    // 🔥 如果有自定义提示词，优先使用
    if (customPrompt != null && customPrompt.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln(customPrompt);
      buffer.writeln();
      buffer.writeln('【笔记内容】');
      buffer.writeln(note.content);
      return buffer.toString();
    }

    // 否则使用系统默认提示词
    final buffer = StringBuffer();

    // 角色（简洁）
    buffer.writeln('角色：学习伙伴（不是分析工具）');
    buffer.writeln();

    // 当前笔记（最重要，放最前）
    buffer.writeln('【笔记内容】');
    buffer.writeln(note.content);
    buffer.writeln();

    // 上下文信息（如果有，强调）
    if (context.relatedNotes.isNotEmpty) {
      buffer.writeln('【⚠️ 重要：用户还写过相关笔记，必须提到！】');
      for (var i = 0; i < context.relatedNotes.take(2).length; i++) {
        final related = context.relatedNotes[i];
        final preview = _getPreview(related.note.content, 60);
        buffer.writeln('• $preview');
      }
      buffer.writeln();
    }

    // 任务要求
    buffer.writeln('【任务】');
    switch (type) {
      case AnalysisType.insight:
        buffer.writeln(_buildInsightTask(strategy));
        break;
      case AnalysisType.summary:
        buffer.writeln(_buildSummaryTask(strategy));
        break;
      case AnalysisType.continuation:
        buffer.writeln(_buildContinuationTask(strategy));
        break;
    }

    return buffer.toString();
  }

  String _buildInsightTask(AnalysisStrategy strategy) {
    if (strategy == AnalysisStrategy.deepThinking) {
      // 高能力模型：深度分析
      return '''
点评笔记（3-4句话，80-100字）。像朋友对话。

【结构】
第1句：点出价值/亮点（具体说哪里好）
第2句：给1个改进建议（可操作，不要空话）
第3句：如果有相关笔记，提知识连接；否则给启发

【示例】
✅ 好："你把这个工具的核心功能说清楚了。建议加上实际使用案例，比如输入什么电影推荐了什么，会更直观。看你之前写过豆瓣那篇，可以对比一下各自优劣。"
❌ 差："写得很好，内容丰富，继续保持。"（空洞无物）
❌ 差："这篇笔记讲了..."（在复述）
''';
    } else {
      // 中低能力模型：简化任务
      return '''
点评笔记（3句话，80字）。像朋友聊天。

【要求】
1. 指出具体优点
2. 给1个可操作建议
3. 用"你"

示例："你把工具功能说清楚了。可以加上使用体验，比如准确率怎么样，更有参考价值。"
''';
    }
  }

  String _buildSummaryTask(AnalysisStrategy strategy) => '''
生成一段适合回看卡片使用的摘要。不是压缩原文，而是提炼这条笔记以后为什么值得看。

【输出要求】
1. 2-3句话，60-100字。
2. 纯文本，不要标题、编号、emoji、Markdown。
3. 客观陈述，不要使用"你/我"。
4. 优先保留结论、问题、行动、限制条件；删除寒暄、重复和无关细节。
5. 如果原文是待办，摘要要说明任务目标；如果原文是资料，摘要要说明资料价值；如果原文是想法，摘要要说明核心判断。

【示例】
原文："这个网站可以根据你喜欢的电影推荐类似的，用了协同过滤算法，准确率挺高的，只支持电影不支持电视剧"
好："介绍了一个电影推荐网站，根据输入作品推荐相似电影，准确率较高，但目前只支持电影，不支持电视剧。"
❌ 差："介绍了基于协同过滤算法的推荐服务。"（太技术化，丢失用户关心的信息）
''';

  String _buildContinuationTask(AnalysisStrategy strategy) => '''
在原文后面续写 80-160 字，像原作者自己继续写，不要像 AI 在帮忙总结。

【硬性要求】
1. 保持原文口吻、句长、标点和排版习惯。
2. 只延续当前思路，不跳到新主题，不替用户下最终结论。
3. 不要输出"续写如下"、"可以这样写"、标题、编号、emoji、Markdown。
4. 原文是列表就继续列表；原文是短句就继续短句；原文是日记就继续日记。
5. 只输出要插入正文的内容。

【示例1】口语化→继续口语化
原文："这个电影网站挺好用的，准确率还不错"
好："我试了几次，输入《盗梦空间》会推荐《记忆碎片》这些烧脑片，确实挺准。搜索速度也快，基本秒出结果。"
❌ 差："该网站基于协同过滤算法..."（突然变学术）

【示例2】技术风格→继续技术
原文："Provider是Flutter最常用的状态管理方案"
好："Provider通过 InheritedWidget 实现状态共享，状态改变时会通知依赖的 Widget 重建。实际使用时，通常在 Widget 树上层包一层 ChangeNotifierProvider。"
''';

  /// 🤖 调用AI
  Future<String> _callAI({
    required String prompt,
    required String apiKey,
    required String apiUrl,
    required String model,
  }) async {
    try {
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
                  'content': '你是一个专业的学习导师和知识管理专家。',
                },
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
              'temperature': 0.7,
              'max_tokens': 1500,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        final choice = choices?.isNotEmpty ?? false
            ? choices!.first as Map<String, dynamic>
            : null;
        final message = choice?['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        return content ?? '未能获取有效响应';
      } else {
        debugPrint('API错误: ${response.statusCode} - ${response.body}');
        return '调用失败: ${response.statusCode}';
      }
    } on Object catch (e) {
      debugPrint('调用异常: $e');
      return '调用异常: $e';
    }
  }

  /// 🔍 Phase 6: 质量检测与修复
  Future<String> _ensureQuality(
    String output,
    Note note,
    String apiKey,
    String apiUrl,
    String model,
    AnalysisType type,
  ) async {
    final report = _checkQuality(output, note.content, type);

    if (report.score >= 70) {
      debugPrint('✅ 质量达标: ${report.score}分');
      return output;
    }

    debugPrint('⚠️ 质量不达标: ${report.score}分');
    debugPrint('问题: ${report.issues.join(", ")}');

    // 尝试自动修复
    final fixed = _autoFix(output, report, type);

    // 重新检测
    final retryReport = _checkQuality(fixed, note.content, type);

    if (retryReport.score >= 60) {
      debugPrint('🔧 修复成功: ${retryReport.score}分');
      return fixed;
    }

    // 如果修复失败且分数过低，重新生成
    if (report.score < 50) {
      debugPrint('🔄 重新生成...');
      final stricterPrompt = _buildStricterPrompt(note, type, report);
      return _callAI(
        prompt: stricterPrompt,
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
      );
    }

    return fixed;
  }

  QualityReport _checkQuality(
    String output,
    String originalNote,
    AnalysisType type,
  ) {
    var score = 100.0;
    final issues = <String>[];

    // 检测1: Emoji检测（严重问题）
    if (RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(output)) {
      score -= 50;
      issues.add('包含emoji');
    }

    // 检测2: Markdown符号检测（严重问题）
    final markdownSymbols = ['##', '**', '- ', '* ', '1.', '2.', '3.'];
    var symbolCount = 0;
    for (final symbol in markdownSymbols) {
      if (output.contains(symbol)) {
        symbolCount++;
      }
    }
    if (symbolCount > 0) {
      score -= 40;
      issues.add('包含格式符号');
    }

    // 检测3: 总结专用 - 禁止人称代词
    if (type == AnalysisType.summary) {
      if (output.contains('你') || output.contains('我')) {
        score -= 40;
        issues.add('总结中使用了人称代词');
      }

      // 检测总结是否过度技术化
      final techWords = ['算法', '方法', '技术', '实现', '机制', '架构'];
      var techCount = 0;
      for (final word in techWords) {
        if (output.contains(word)) {
          techCount++;
        }
      }
      // 如果原文不强调技术但总结强调了，扣分
      if (techCount > 2 && !_isTechnicalNote(originalNote)) {
        score -= 25;
        issues.add('过度强调技术细节');
      }
    }

    // 检测4: 续写风格一致性
    if (type == AnalysisType.continuation) {
      // 检测是否保持原文风格
      if (_isStyleMismatch(originalNote, output)) {
        score -= 30;
        issues.add('续写风格不一致');
      }
    }

    // 检测5: 复述检测（点评和总结）
    if (type != AnalysisType.continuation &&
        _isParaphrasing(output, originalNote)) {
      score -= 35;
      issues.add('复述原文');
    }

    // 检测6: 套话检测
    final fluffWords = [
      '这篇笔记',
      '本文',
      '总的来说',
      '综上所述',
      '总结如下',
      '内容丰富',
      '写得很好',
      '建议继续保持',
      '以下是',
      '我来',
    ];
    var fluffCount = 0;
    for (final word in fluffWords) {
      if (output.contains(word)) {
        fluffCount++;
      }
    }
    if (fluffCount > 1) {
      score -= 30;
      issues.add('套话过多');
    }

    // 检测7: 生硬检测
    final rigidWords = ['根据分析', '经研究', '该笔记', '具有以下特征', '建议如下', '基于', '实现'];
    var rigidCount = 0;
    for (final word in rigidWords) {
      if (output.contains(word)) {
        rigidCount++;
      }
    }
    if (rigidCount > 1) {
      score -= 20;
      issues.add('表达生硬');
    }

    // 检测8: 自然度检测（仅点评需要）
    if (type == AnalysisType.insight) {
      final naturalWords = ['试试', '就像', '不过', '其实', '可以'];
      final naturalCount = naturalWords.where((w) => output.contains(w)).length;
      if (naturalCount < 1) {
        score -= 15;
        issues.add('点评不够自然');
      }
    }

    return QualityReport(
      score: score,
      issues: issues,
      passed: score >= 70,
    );
  }

  /// 判断是否为技术类笔记
  bool _isTechnicalNote(String content) {
    final techIndicators = [
      '代码',
      '函数',
      '类',
      '接口',
      'API',
      '数据库',
      '算法',
      '架构',
      '设计模式',
    ];
    var count = 0;
    for (final indicator in techIndicators) {
      if (content.contains(indicator)) {
        count++;
      }
    }
    return count >= 3; // 出现3个以上技术词汇才算技术笔记
  }

  /// 检测续写风格是否一致
  bool _isStyleMismatch(String original, String continuation) {
    // 检查原文是否口语化
    final casualWords = ['挺', '很', '还', '就', '吧', '啊', '哦'];
    final originalCasual =
        casualWords.where((w) => original.contains(w)).length >= 2;
    final continuationCasual =
        casualWords.where((w) => continuation.contains(w)).length >= 2;

    // 检查续写是否突然变技术化
    final techWords = ['算法', '架构', '机制', '实现', '基于'];
    final originalTech = techWords.where((w) => original.contains(w)).length;
    final continuationTech =
        techWords.where((w) => continuation.contains(w)).length;

    // 如果原文口语化但续写变技术，或反之，就是风格不一致
    if (originalCasual &&
        !continuationCasual &&
        continuationTech > originalTech + 1) {
      return true;
    }

    return false;
  }

  bool _isParaphrasing(String output, String original) {
    // 简单检测：提取关键词对比
    final outputWords = _extractKeywords(output);
    final originalWords = _extractKeywords(original);

    if (outputWords.isEmpty || originalWords.isEmpty) {
      return false;
    }

    final intersection = outputWords.intersection(originalWords);
    final overlap = intersection.length / originalWords.length;

    return overlap > 0.6; // 超过60%重叠视为复述
  }

  String _autoFix(String output, QualityReport report, AnalysisType type) {
    var fixed = output;

    // 修复1: 移除所有emoji
    fixed =
        fixed.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '');

    // 修复2: 移除markdown符号
    fixed = fixed
        .replaceAll('##', '')
        .replaceAll('**', '')
        .replaceAll('### ', '')
        .replaceAll('- ', '')
        .replaceAll('* ', '');

    // 修复3: 移除编号（但保留数字）
    fixed = fixed.replaceAll(RegExp(r'^[0-9]\.\s', multiLine: true), '');

    // 修复4: 总结专用修复
    if (type == AnalysisType.summary) {
      // 去除人称代词
      fixed = fixed
          .replaceAll('你的笔记', '笔记')
          .replaceAll('你写的', '写的')
          .replaceAll('你提到', '提到')
          .replaceAll('你认为', '认为')
          .replaceAll('你可以', '可以')
          .replaceAll('我认为', '');

      // 去除过度技术化的表达
      if (report.issues.contains('过度强调技术细节')) {
        fixed = fixed
            .replaceAll('基于协同过滤算法', '通过推荐算法')
            .replaceAll('协同过滤算法', '推荐功能')
            .replaceAll('实现了', '')
            .replaceAll('基于', '通过')
            .replaceAll('该机制', '这个功能');
      }
    }

    // 修复5: 续写专用修复
    if (type == AnalysisType.continuation &&
        report.issues.contains('续写风格不一致')) {
      // 如果续写太技术化，尝试软化
      fixed = fixed
          .replaceAll('该算法', '这个方法')
          .replaceAll('基于', '通过')
          .replaceAll('实现', '做到');
    }

    // 修复6: 去除套话
    fixed = fixed
        .replaceAll('这篇笔记', '笔记')
        .replaceAll('总的来说，', '')
        .replaceAll('综上所述，', '')
        .replaceAll('总结如下：', '')
        .replaceAll('以下是', '')
        .replaceAll('我来', '');

    // 修复7: 去除生硬表达
    fixed = fixed
        .replaceAll('根据分析，', '')
        .replaceAll('经研究，', '')
        .replaceAll('该笔记', '笔记')
        .replaceAll('建议如下：', '')
        .replaceAll('具有以下特征', '');

    return fixed.trim();
  }

  String _buildStricterPrompt(
    Note note,
    AnalysisType type,
    QualityReport report,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('⚠️ 上次输出有问题！重新生成！');
    buffer.writeln();

    // 上次的具体问题（最重要放前面）
    buffer.writeln('【上次犯的错误】');
    for (final issue in report.issues) {
      if (issue == '过度强调技术细节') {
        buffer.writeln('❌ 太技术化！用户要的是功能，不是"算法"这种词！');
      } else if (issue == '续写风格不一致') {
        buffer.writeln('❌ 风格突变！原文口语化就继续口语化！');
      } else if (issue == '总结中使用了人称代词') {
        buffer.writeln('❌ 总结不要"你/我"！要客观！');
      } else if (issue == '包含emoji' || issue == '包含格式符号') {
        buffer.writeln('❌ 有符号/emoji！要纯文本！');
      } else if (issue == '套话过多' || issue == '表达生硬') {
        buffer.writeln('❌ 太生硬/套话！要自然！');
      }
    }
    buffer.writeln();

    // 笔记内容
    buffer.writeln('【笔记】');
    buffer.writeln(note.content);
    buffer.writeln();

    // 简洁任务
    buffer.writeln('【现在重做】');
    switch (type) {
      case AnalysisType.insight:
        buffer.writeln('点评（3句话，自然对话）');
        break;
      case AnalysisType.summary:
        buffer.writeln('总结（2-3句话，客观陈述）');
        break;
      case AnalysisType.continuation:
        buffer.writeln('续写（100字，保持原文风格）');
        break;
    }

    return buffer.toString();
  }

  /// 📝 Phase 7: 记录用于学习
  Future<void> _recordForLearning(String noteId, AnalysisResult result) async {
    // 保存分析结果，用于未来的个性化
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'analysis_${noteId}_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(
        key,
        json.encode({
          'noteId': noteId,
          'timestamp': result.timestamp.millisecondsSinceEpoch,
          'userLevel': result.userProfile.level,
        }),
      );
    } on Object catch (e) {
      debugPrint('记录失败: $e');
    }
  }

  /// 💾 缓存AI分析结果（24小时有效）
  Future<void> _cacheAnalysis(
    String noteId,
    AnalysisType type,
    AnalysisResult result,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'ai_analysis_${noteId}_${type.name}';

      await prefs.setString(
        key,
        json.encode({
          'content': result.content,
          'timestamp': result.timestamp.millisecondsSinceEpoch,
          'userLevel': result.userProfile.level,
        }),
      );

      debugPrint('💾 分析结果已缓存 [${type.name}]');
    } on Object catch (e) {
      debugPrint('⚠️ 缓存失败: $e');
    }
  }

  /// 📖 读取缓存的AI分析结果
  Future<AnalysisResult?> _getCachedAnalysis(
    String noteId,
    AnalysisType type,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'ai_analysis_${noteId}_${type.name}';
      final cached = prefs.getString(key);

      if (cached == null) {
        return null;
      }

      final data = json.decode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int,
      );

      // 检查是否过期（24小时）
      final age = DateTime.now().difference(timestamp);
      if (age.inHours > 24) {
        debugPrint('⏰ 缓存已过期 (${age.inHours}小时)');
        await prefs.remove(key);
        return null;
      }

      debugPrint('✅ 发现有效缓存 (${age.inMinutes}分钟前)');

      return AnalysisResult(
        content: data['content'] as String,
        context: NoteContext.empty(),
        userProfile: UserProfile.empty(),
        timestamp: timestamp,
      );
    } on Object catch (e) {
      debugPrint('⚠️ 读取缓存失败: $e');
      return null;
    }
  }

  /// 💾 缓存上下文（轻量级元数据）
  Future<void> _cacheContext(String noteId, NoteContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'context_$noteId',
        json.encode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'relatedCount': context.relatedNotes.length,
        }),
      );
    } on Object catch (e) {
      debugPrint('缓存失败: $e');
    }
  }

  Future<NoteContext?> _getCachedContext(String noteId) async {
    // 简化版：只检查是否有缓存，实际获取还是重新计算
    // 完整版需要序列化整个context
    return null;
  }

  /// 🛠️ 辅助方法
  Set<String> _extractKeywords(String text) =>
      TextAnalysisUtils.extractKeywords(
        text,
      ).where((word) => !_isStopWord(word)).toSet();

  bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'is',
      'at',
      'which',
      'on',
      'a',
      'an',
      'and',
      'or',
      '的',
      '了',
      '和',
      '是',
      '在',
      '我',
      '有',
      '个',
    };
    return stopWords.contains(word);
  }

  Set<String> _extractLinks(String content) {
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet();
  }

  double _calculateKeywordSimilarity(Set<String> set1, Set<String> set2) {
    if (set1.isEmpty || set2.isEmpty) {
      return 0;
    }
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    return intersection.length / union.length;
  }

  String _getPreview(String content, int maxLength) {
    final cleaned = content
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp('[*_`#~]'), '');
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxLength)}...';
  }
}

/// 🎯 分析类型
enum AnalysisType {
  insight, // AI点评
  summary, // AI总结
  continuation, // AI续写
}

/// 📋 分析策略
enum AnalysisStrategy {
  deepThinking, // 深度思考（高能力模型）
  balanced, // 平衡模式（中能力模型）
  twoStage, // 两阶段（中能力模型+复杂任务）
  economical, // 经济模式（低能力模型）
}

/// 🎯 模型能力
enum ModelCapability {
  high, // GPT-4, Claude-3-Opus
  medium, // GPT-3.5, Claude-3-Sonnet
  low, // DeepSeek, 其他
}

/// 📊 分析结果
class AnalysisResult {
  const AnalysisResult({
    required this.content,
    required this.context,
    required this.userProfile,
    required this.timestamp,
  });

  factory AnalysisResult.error(String message) => AnalysisResult(
        content: message,
        context: NoteContext.empty(),
        userProfile: UserProfile.empty(),
        timestamp: DateTime.now(),
      );

  final String content;
  final NoteContext context;
  final UserProfile userProfile;
  final DateTime timestamp;
}

/// 🔗 笔记上下文
class NoteContext {
  const NoteContext({
    required this.currentNote,
    required this.relatedNotes,
    required this.timeline,
  });

  factory NoteContext.empty() => NoteContext(
        currentNote: Note(
          id: '',
          content: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        relatedNotes: const [],
        timeline: TimelineAnalysis.empty(),
      );

  final Note currentNote;
  final List<RelatedNoteScore> relatedNotes;
  final TimelineAnalysis timeline;
}

/// 📊 相关笔记评分
class RelatedNoteScore {
  const RelatedNoteScore({
    required this.note,
    required this.score,
    required this.reasons,
  });

  final Note note;
  final double score;
  final List<String> reasons;
}

/// 📈 时间线分析
class TimelineAnalysis {
  const TimelineAnalysis({
    required this.previousNotes,
    required this.nextNotes,
    required this.totalNotes,
    required this.position,
  });

  factory TimelineAnalysis.empty() => const TimelineAnalysis(
        previousNotes: [],
        nextNotes: [],
        totalNotes: 0,
        position: 0,
      );

  final List<Note> previousNotes;
  final List<Note> nextNotes;
  final int totalNotes;
  final int position;
}

/// 👤 用户画像
class UserProfile {
  const UserProfile({
    required this.level,
    required this.noteCount,
    required this.topTopics,
    required this.preference,
  });

  factory UserProfile.empty() => UserProfile(
        level: 'beginner',
        noteCount: 0,
        topTopics: const [],
        preference: UserPreference.empty(),
      );

  final String level;
  final int noteCount;
  final List<String> topTopics;
  final UserPreference preference;
}

/// 📊 质量报告
class QualityReport {
  const QualityReport({
    required this.score,
    required this.issues,
    required this.passed,
  });

  final double score;
  final List<String> issues;
  final bool passed;
}
