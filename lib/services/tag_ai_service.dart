import 'dart:math';

import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/utils/logger.dart';

/// 🤖 标签AI服务（混合模式）
///
/// 提供两级智能分析：
/// 1. **本地算法**（快速、免费）：
///    - TF-IDF算法的相关标签推荐
///    - 时间序列预测（线性回归）
///    - 规则基础的洞察生成
///
/// 2. **LLM API**（智能、深度）：
///    - 基于真实大语言模型的深度分析
///    - 个性化建议和洞察
///    - 支持用户在AI设置中配置的任何兼容OpenAI API的模型
class TagAIService {
  /// 📊 使用TF-IDF算法计算标签相关性
  ///
  /// TF-IDF (Term Frequency-Inverse Document Frequency) 是一种常用的文本挖掘算法
  /// 用于评估一个词对于一个文件集或文档库中的其中一份文件的重要程度
  static Map<String, double> calculateTagRelevance({
    required String currentTag,
    required List<Note> allNotes,
  }) {
    // 计算包含当前标签的笔记
    final currentTagNotes =
        allNotes.where((note) => note.tags.contains(currentTag)).toList();

    if (currentTagNotes.isEmpty) {
      return {};
    }

    final tagScores = <String, double>{};
    final totalNotes = allNotes.length;

    // 收集所有出现过的标签
    final allTags = <String>{};
    for (final note in allNotes) {
      allTags.addAll(note.tags);
    }
    allTags.remove(currentTag); // 移除当前标签

    for (final tag in allTags) {
      // TF (Term Frequency): 标签在当前标签笔记中出现的频率
      final tfCount =
          currentTagNotes.where((note) => note.tags.contains(tag)).length;
      final tf = tfCount / currentTagNotes.length;

      // IDF (Inverse Document Frequency): 标签的逆文档频率
      final dfCount = allNotes.where((note) => note.tags.contains(tag)).length;
      final idf = log(totalNotes / (dfCount + 1)); // +1 避免除零

      // TF-IDF分数
      final tfidf = tf * idf;

      // 额外考虑共现次数（Jaccard相似度）
      final cooccurrence = tfCount.toDouble();
      final jaccard =
          cooccurrence / (currentTagNotes.length + dfCount - cooccurrence);

      // 综合评分：TF-IDF + Jaccard相似度 + 共现权重
      tagScores[tag] = (tfidf * 0.4) + (jaccard * 0.3) + (cooccurrence * 0.3);
    }

    return tagScores;
  }

  /// 🔮 预测未来趋势（简单线性回归）
  ///
  /// 基于历史数据预测未来的笔记创建趋势
  static Map<String, dynamic> predictTrend({
    required Map<String, int> monthlyStats,
  }) {
    if (monthlyStats.length < 2) {
      return {
        'trend': 'insufficient_data',
        'prediction': 0,
        'confidence': 0.0,
      };
    }

    // 将月份转换为数值（从0开始）
    final sortedMonths = monthlyStats.keys.toList()..sort();
    final x = List.generate(sortedMonths.length, (i) => i.toDouble());
    final y =
        sortedMonths.map((month) => monthlyStats[month]!.toDouble()).toList();

    // 计算线性回归参数 y = ax + b
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // 预测下个月的值
    final nextMonthIndex = n.toDouble();
    final prediction = (slope * nextMonthIndex + intercept).round();

    // 计算R²（决定系数）作为置信度
    final yMean = sumY / n;
    final ssTot = y.map((yi) => pow(yi - yMean, 2)).reduce((a, b) => a + b);
    final ssRes = List.generate(n, (i) {
      final predicted = slope * x[i] + intercept;
      return pow(y[i] - predicted, 2);
    }).reduce((a, b) => a + b);
    final r2 = 1 - (ssRes / ssTot);

    // 判断趋势
    String trend;
    if (slope > 0.5) {
      trend = 'increasing';
    } else if (slope < -0.5) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'prediction': prediction > 0 ? prediction : 0,
      'confidence': (r2 * 100).clamp(0, 100).toInt(),
      'slope': slope,
    };
  }

  /// 💡 生成智能洞察
  ///
  /// 基于统计数据生成对用户有价值的洞察
  static List<String> generateInsights({
    required String tagName,
    required List<Note> tagNotes,
    required Map<String, int> monthlyStats,
    required Map<String, dynamic> trendData,
  }) {
    final insights = <String>[];

    // 洞察1: 标签使用规模
    if (tagNotes.length >= 10) {
      insights.add('「$tagName」已经沉淀 ${tagNotes.length} 条笔记，适合做一次主题复盘。');
    } else if (tagNotes.length >= 5) {
      insights.add('「$tagName」已有 ${tagNotes.length} 条笔记，主题开始成形，适合做一次小复盘。');
    } else {
      insights.add('「$tagName」还在起步阶段，建议先补足背景、案例和下一步动作。');
    }

    // 洞察2: 趋势分析
    final trend = trendData['trend'] as String?;
    final confidence = trendData['confidence'] as int? ?? 0;

    if (confidence > 70) {
      if (trend == 'increasing') {
        insights.add('这个标签近期明显升温，说明它正在变成当前关注重点。');
      } else if (trend == 'decreasing') {
        insights.add('这个标签近期降温，适合判断是已经完成、暂停，还是需要重新激活。');
      } else {
        insights.add('这个标签记录节奏稳定，适合按周或按月整理成连续脉络。');
      }
    }

    // 洞察3: 时间分布
    if (monthlyStats.isNotEmpty) {
      final maxMonth =
          monthlyStats.entries.reduce((a, b) => a.value > b.value ? a : b);
      final maxCount = maxMonth.value;

      if (maxCount >= 5) {
        insights.add('${maxMonth.key} 是最活跃阶段，共记录 $maxCount 条，建议回看当时触发了什么问题。');
      }
    }

    // 洞察4: 内容密度
    final avgLength = tagNotes.isEmpty
        ? 0
        : tagNotes.map((n) => n.content.length).reduce((a, b) => a + b) /
            tagNotes.length;

    if (avgLength > 500) {
      insights.add('这个标签下长笔记较多，建议提炼 3 条可复用观点，避免资料沉底。');
    } else if (avgLength > 200) {
      insights.add('这个标签内容密度适中，适合整理成问题、证据、结论三类卡片。');
    } else if (avgLength > 0) {
      insights.add('这个标签多为短记录，建议给关键笔记补一句“为什么重要”。');
    }

    return insights.take(5).toList();
  }

  /// 🎯 计算标签相似度矩阵（用于聚类分析）
  ///
  /// 使用余弦相似度计算标签之间的相似性
  static Map<String, Map<String, double>> calculateTagSimilarity({
    required List<String> allTags,
    required List<Note> allNotes,
  }) {
    final similarity = <String, Map<String, double>>{};

    // 为每个标签建立笔记向量
    final tagVectors = <String, Set<String>>{};
    for (final tag in allTags) {
      tagVectors[tag] = allNotes
          .where((note) => note.tags.contains(tag))
          .map((note) => note.id)
          .toSet();
    }

    // 计算余弦相似度
    for (var i = 0; i < allTags.length; i++) {
      final tag1 = allTags[i];
      similarity[tag1] = {};

      for (var j = i + 1; j < allTags.length; j++) {
        final tag2 = allTags[j];
        final vector1 = tagVectors[tag1]!;
        final vector2 = tagVectors[tag2]!;

        // 余弦相似度 = 交集大小 / (sqrt(|A| * |B|))
        final intersection = vector1.intersection(vector2).length;
        final cosineSim = intersection / sqrt(vector1.length * vector2.length);

        similarity[tag1]![tag2] = cosineSim;
      }
    }

    return similarity;
  }

  /// 🎨 根据标签使用频率推荐颜色（视觉辅助）
  static String recommendColor(int noteCount) {
    if (noteCount >= 20) {
      return '#FF6B6B'; // 红色 - 高频
    } else if (noteCount >= 10) {
      return '#4ECDC4'; // 青色 - 中频
    } else if (noteCount >= 5) {
      return '#95E1D3'; // 浅绿 - 常用
    } else {
      return '#A8A8A8'; // 灰色 - 低频
    }
  }

  // ========================================
  // 🚀 LLM增强功能（基于用户AI设置）
  // ========================================

  /// 🤖 增强版：相关标签推荐（本地算法 + LLM深度分析）
  ///
  /// **工作流程**：
  /// 1. 使用本地TF-IDF算法快速计算相关标签（秒级）
  /// 2. 如果AI已启用，调用LLM进行深度语义分析（智能推荐）
  /// 3. 合并本地和AI结果，返回综合推荐
  ///
  /// **参数**：
  /// - currentTag: 当前标签
  /// - allNotes: 所有笔记
  /// - appConfig: 应用配置（包含AI设置）
  ///
  /// **返回**：
  /// - localRecommendations: 本地算法推荐（Map<标签, 相关度分数>）
  /// - aiRecommendations: AI推荐（List<String>，可能为空）
  /// - aiInsight: AI分析洞察（String?，可能为null）
  static Future<Map<String, dynamic>> getEnhancedTagRecommendations({
    required String currentTag,
    required List<Note> allNotes,
    required AppConfig appConfig,
  }) async {
    Log.service.debug(
      'Start enhanced tag recommendations',
      data: {'currentTag': currentTag},
    );

    // 1️⃣ 本地算法：快速计算（秒级）
    final localScores = calculateTagRelevance(
      currentTag: currentTag,
      allNotes: allNotes,
    );

    Log.service.debug(
      'Local tag recommendation completed',
      data: {'relatedTagCount': localScores.length},
    );

    // 2️⃣ LLM增强：深度分析（如果已启用）
    List<String>? aiRecommendations;
    String? aiInsight;

    if (appConfig.aiEnabled &&
        appConfig.aiApiUrl != null &&
        appConfig.aiApiKey != null) {
      Log.service.debug('AI is enabled for tag recommendations');

      try {
        final aiService = DeepSeekApiService(
          apiUrl: appConfig.aiApiUrl!,
          apiKey: appConfig.aiApiKey!,
          model: appConfig.aiModel,
        );

        // 获取当前标签下的笔记样本（最多5条）
        final tagNotes = allNotes
            .where((note) => note.tags.contains(currentTag))
            .take(5)
            .toList();

        // 获取所有标签列表
        final allTags = <String>{};
        for (final note in allNotes) {
          allTags.addAll(note.tags);
        }
        allTags.remove(currentTag);

        // 构建提示词
        final prompt = _buildTagRecommendationPrompt(
          currentTag: currentTag,
          sampleNotes: tagNotes,
          availableTags: allTags.toList(),
          localTopTags: localScores.entries.take(10).map((e) => e.key).toList(),
        );

        // 🎯 大厂标准：支持用户自定义提示词
        final customPrompt = appConfig.useCustomPrompt &&
                appConfig.customTagRecommendationPrompt != null &&
                appConfig.customTagRecommendationPrompt!.isNotEmpty
            ? appConfig.customTagRecommendationPrompt!.trim()
            : null;
        final systemPrompt = customPrompt == null
            ? '你是一个克制、准确的笔记标签顾问。只推荐用户已有标签，不创造新标签，不输出解释性废话。'
            : '$customPrompt\n\n额外硬性要求：只推荐可用标签列表中的标签；不要推荐当前标签；不要编造新标签。';

        // 调用LLM
        final (response, error) = await aiService.chat(
          messages: [
            DeepSeekApiService.buildSystemMessage(systemPrompt),
            DeepSeekApiService.buildUserMessage(prompt),
          ],
          temperature: 0.7,
          maxTokens: 500,
        );

        if (error != null) {
          Log.service.warning(
            'LLM tag recommendation failed',
            data: {'error': error},
          );
        } else if (response != null) {
          Log.service.debug('LLM tag recommendation succeeded');
          final parsed = _parseAIRecommendationResponse(response);
          aiRecommendations = _sanitizeRecommendedTags(
            parsed['recommendations'] as List<String>? ?? const [],
            availableTags: allTags,
            currentTag: currentTag,
          );
          aiInsight = parsed['insight'];
        }
      } on Object catch (e, stackTrace) {
        Log.service.error(
          'LLM tag recommendation threw',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } else {
      Log.service.debug('AI disabled for tag recommendations');
    }

    return {
      'localRecommendations': localScores,
      'aiRecommendations': aiRecommendations,
      'aiInsight': aiInsight,
    };
  }

  /// 🤖 增强版：智能洞察生成（本地规则 + LLM深度分析）
  ///
  /// **工作流程**：
  /// 1. 使用本地规则生成基础洞察
  /// 2. 如果AI已启用，调用LLM进行深度分析
  /// 3. 合并返回综合洞察
  static Future<List<String>> getEnhancedInsights({
    required String tagName,
    required List<Note> tagNotes,
    required Map<String, int> monthlyStats,
    required Map<String, dynamic> trendData,
    required AppConfig appConfig,
  }) async {
    Log.service.debug(
      'Start enhanced tag insights',
      data: {'tagName': tagName},
    );

    // 1️⃣ 本地规则：快速生成基础洞察
    final localInsights = generateInsights(
      tagName: tagName,
      tagNotes: tagNotes,
      monthlyStats: monthlyStats,
      trendData: trendData,
    );

    Log.service.debug(
      'Local tag insights completed',
      data: {'insightCount': localInsights.length},
    );

    // 2️⃣ LLM增强：深度分析（如果已启用）
    var aiInsights = <String>[];

    if (appConfig.aiEnabled &&
        appConfig.aiApiUrl != null &&
        appConfig.aiApiKey != null) {
      Log.service.debug('AI is enabled for tag insights');

      try {
        final aiService = DeepSeekApiService(
          apiUrl: appConfig.aiApiUrl!,
          apiKey: appConfig.aiApiKey!,
          model: appConfig.aiModel,
        );

        // 构建提示词
        final prompt = _buildInsightPrompt(
          tagName: tagName,
          noteCount: tagNotes.length,
          monthlyStats: monthlyStats,
          trendData: trendData,
          sampleNotes: tagNotes.take(3).toList(),
        );

        // 🎯 大厂标准：支持用户自定义提示词
        final customPrompt = appConfig.useCustomPrompt &&
                appConfig.customTagInsightPrompt != null &&
                appConfig.customTagInsightPrompt!.isNotEmpty
            ? appConfig.customTagInsightPrompt!.trim()
            : null;
        final systemPrompt = customPrompt == null
            ? '你是一个克制、专业的笔记主题分析顾问。必须输出具体、有证据感、可行动的短洞察，禁止泛泛鼓励。'
            : '$customPrompt\n\n额外硬性要求：输出短句洞察，不要 Markdown 标题，不要 emoji，不要泛泛鼓励。';

        // 调用LLM
        final (response, error) = await aiService.chat(
          messages: [
            DeepSeekApiService.buildSystemMessage(systemPrompt),
            DeepSeekApiService.buildUserMessage(prompt),
          ],
          temperature: 0.8,
          maxTokens: 400,
        );

        if (error != null) {
          Log.service.warning(
            'LLM tag insights failed',
            data: {'error': error},
          );
        } else if (response != null) {
          Log.service.debug('LLM tag insights succeeded');
          aiInsights = _parseAIInsightsResponse(response);
        }
      } on Object catch (e, stackTrace) {
        Log.service.error(
          'LLM tag insights threw',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // 3️⃣ 合并本地和AI洞察（AI洞察在前，更重要）
    return _dedupeInsights([...aiInsights, ...localInsights]).take(6).toList();
  }

  // ========================================
  // 🛠️ 私有辅助方法
  // ========================================

  /// 构建标签推荐的提示词
  static String _buildTagRecommendationPrompt({
    required String currentTag,
    required List<Note> sampleNotes,
    required List<String> availableTags,
    required List<String> localTopTags,
  }) {
    final notesPreview = sampleNotes.isEmpty
        ? '暂无笔记内容'
        : sampleNotes
            .map(
              (n) =>
                  '- ${n.content.length > 100 ? '${n.content.substring(0, 100)}...' : n.content}',
            )
            .join('\n');

    return '''
分析任务：为标签「$currentTag」推荐相关标签

**当前标签下的笔记示例**：
$notesPreview

**本地算法推荐的Top标签**：
${localTopTags.take(5).join(', ')}

**可用的所有标签**（部分）：
${availableTags.take(20).join(', ')}

请基于笔记内容的语义分析，推荐3-5个与「$currentTag」**语义相关**或**逻辑关联**的标签。

**输出格式**（严格遵守）：
推荐标签：标签1, 标签2, 标签3
分析洞察：简要说明这些标签之间的关联性（1-2句话）

注意：
1. 推荐的标签必须在「可用的所有标签」列表中
2. 不要推荐「$currentTag」本身
3. 优先推荐语义相关的标签，而不仅仅是共现频率高的
4. 不要输出解释过程，不要使用 Markdown，不要新增不存在的标签
''';
  }

  /// 构建智能洞察的提示词
  static String _buildInsightPrompt({
    required String tagName,
    required int noteCount,
    required Map<String, int> monthlyStats,
    required Map<String, dynamic> trendData,
    required List<Note> sampleNotes,
  }) {
    final trend = trendData['trend'] ?? 'unknown';
    final prediction = trendData['prediction'] ?? 0;
    final confidence = trendData['confidence'] ?? 0;

    final notesPreview = sampleNotes.isEmpty
        ? '暂无笔记内容'
        : sampleNotes
            .map(
              (n) =>
                  '- ${n.content.length > 80 ? '${n.content.substring(0, 80)}...' : n.content}',
            )
            .join('\n');

    final monthlyStatsStr = monthlyStats.isEmpty
        ? '暂无月度统计'
        : monthlyStats.entries
            .take(6)
            .map((e) => '${e.key}: ${e.value}条')
            .join(', ');

    return '''
分析任务：为标签「$tagName」生成智能洞察

**基础数据**：
- 笔记总数：$noteCount 条
- 趋势：$trend
- AI预测下月笔记数：$prediction 条（置信度：$confidence%）
- 最近月度统计：$monthlyStatsStr

**笔记内容示例**：
$notesPreview

请基于以上数据，从以下3个维度提供**有价值的洞察和建议**：
1. **使用习惯分析**：用户在这个标签上的记录模式
2. **内容主题发现**：笔记内容反映的核心主题或关注点
3. **行动建议**：基于趋势和内容的个性化建议

**输出格式**（每条洞察独立一行）：
使用习惯：[一句具体洞察]
内容主题：[一句具体洞察]
行动建议：[一句具体建议]

要求：
- 每条洞察控制在40字以内
- 语言简洁、具体、可操作
- 不要重复基础数据，要提供新的视角
- 不要使用 emoji、Markdown 标题或编号
''';
  }

  /// 解析AI推荐响应
  static Map<String, dynamic> _parseAIRecommendationResponse(String response) {
    try {
      final lines = response.split('\n');
      List<String>? recommendations;
      String? insight;

      for (final line in lines) {
        if (line.contains('推荐标签') || line.contains('Recommended tags')) {
          final tags = line
              .replaceAll(RegExp('推荐标签[：:]*'), '')
              .replaceAll(RegExp('Recommended tags[：:]*'), '')
              .split(RegExp('[,，、]'))
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
          recommendations = tags;
        } else if (line.contains('分析洞察') || line.contains('Insight')) {
          insight = line
              .replaceAll(RegExp('分析洞察[：:]*'), '')
              .replaceAll(RegExp('Insight[：:]*'), '')
              .trim();
        }
      }

      return {
        'recommendations': recommendations ?? [],
        'insight': insight,
      };
    } on Object catch (e, stackTrace) {
      Log.service.warning(
        'Failed to parse AI tag recommendation response',
        data: {'error': e, 'stackTrace': stackTrace},
      );
      return {
        'recommendations': [],
        'insight': null,
      };
    }
  }

  /// 解析AI洞察响应
  static List<String> _parseAIInsightsResponse(String response) {
    try {
      final lines =
          response.split('\n').where((line) => line.trim().isNotEmpty).toList();

      final insights = <String>[];
      for (final line in lines) {
        final trimmed = _cleanInsightLine(line);
        if (trimmed.length >= 8) {
          insights.add(trimmed);
        }
      }

      return _dedupeInsights(insights).take(5).toList(); // 最多5条
    } on Object catch (e, stackTrace) {
      Log.service.warning(
        'Failed to parse AI tag insights response',
        data: {'error': e, 'stackTrace': stackTrace},
      );
      return [];
    }
  }

  static List<String> _sanitizeRecommendedTags(
    List<String> rawTags, {
    required Set<String> availableTags,
    required String currentTag,
  }) {
    final normalizedAvailable = {
      for (final tag in availableTags) _normalizeTag(tag): tag,
    };
    final result = <String>[];
    final seen = <String>{};

    for (final raw in rawTags) {
      final normalized = _normalizeTag(raw);
      if (normalized.isEmpty ||
          normalized == _normalizeTag(currentTag) ||
          seen.contains(normalized)) {
        continue;
      }
      final existing = normalizedAvailable[normalized];
      if (existing == null) {
        continue;
      }
      result.add(existing);
      seen.add(normalized);
      if (result.length >= 5) {
        break;
      }
    }
    return result;
  }

  static List<String> _dedupeInsights(List<String> insights) {
    final result = <String>[];
    final seen = <String>{};
    for (final insight in insights) {
      final cleaned = _cleanInsightLine(insight);
      final key = cleaned.replaceAll(RegExp(r'\s+'), '');
      if (cleaned.isEmpty || seen.contains(key)) {
        continue;
      }
      result.add(cleaned);
      seen.add(key);
    }
    return result;
  }

  static String _cleanInsightLine(String line) {
    var cleaned = line.trim();
    cleaned = cleaned
        .replaceAll(RegExp(r'^[\-\*\d\.\s]+'), '')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
        .replaceAll('**', '')
        .replaceAll('#', '')
        .trim();
    return cleaned;
  }

  static String _normalizeTag(String tag) => tag
      .replaceAll('#', '')
      .replaceAll(RegExp(r'^[\-\*\d\.\s]+'), '')
      .trim()
      .toLowerCase();
}
