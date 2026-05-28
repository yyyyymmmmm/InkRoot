import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🚀 AI 相关笔记服务 - 超越大厂版
///
/// 根据用户选择的模型，自动使用最佳策略：
/// - OpenAI 模型：使用 Embedding API（高精度向量相似度）
/// - DeepSeek/其他：使用 Chat API（AI 智能语义分析）
class AIRelatedNotesService {
  // 🚀 使用统一配置管理
  static const String _cachePrefix = AppConfig.noteCachePrefix;
  static final Duration _cacheExpiry = Duration(hours: AppConfig.aiRelatedNotesCacheHours);

  /// 查找相关笔记 - 智能路由
  Future<List<RelatedNote>> findRelatedNotes({
    required Note currentNote,
    required List<Note> allNotes,
    required String apiKey,
    required String apiUrl,
    required String model,
    int topK = 5,
  }) async {
    try {
      debugPrint('🔍 AI相关笔记分析开始...');
      debugPrint('📋 当前笔记ID: ${currentNote.id}');
      debugPrint('🤖 使用模型: $model');

      // 检查缓存
      final cacheKey =
          '${currentNote.id}_${currentNote.updatedAt.millisecondsSinceEpoch}';
      final cachedResult = await _getCachedResult(cacheKey);
      if (cachedResult != null) {
        debugPrint('💾 使用缓存结果');
        return _parseRelatedNotes(cachedResult, allNotes).take(topK).toList();
      }

      List<RelatedNote> relatedNotes;

      // 根据模型选择策略
      if (_isOpenAIModel(model, apiUrl)) {
        debugPrint('✨ 使用 OpenAI Embedding 策略');
        relatedNotes = await _findByEmbedding(
          currentNote: currentNote,
          allNotes: allNotes,
          apiKey: apiKey,
          apiUrl: apiUrl,
          topK: topK,
        );
      } else {
        debugPrint('🧠 使用 AI 智能分析策略');
        relatedNotes = await _findByAIAnalysis(
          currentNote: currentNote,
          allNotes: allNotes,
          apiKey: apiKey,
          apiUrl: apiUrl,
          model: model,
          topK: topK,
        );
      }

      // 缓存结果
      if (relatedNotes.isNotEmpty) {
        await _cacheResult(cacheKey, relatedNotes);
      }

      debugPrint('✅ 找到 ${relatedNotes.length} 条相关笔记');
      return relatedNotes;
    } catch (e) {
      debugPrint('❌ 查找相关笔记失败: $e');
      return [];
    }
  }

  /// 判断是否为 OpenAI 模型
  bool _isOpenAIModel(String model, String apiUrl) =>
      apiUrl.contains('openai.com') ||
      model.startsWith('gpt-') ||
      model.contains('text-embedding');

  /// 策略1：使用 OpenAI Embedding API（高精度）
  Future<List<RelatedNote>> _findByEmbedding({
    required Note currentNote,
    required List<Note> allNotes,
    required String apiKey,
    required String apiUrl,
    required int topK,
  }) async {
    try {
      // 获取当前笔记的向量
      final currentVector = await _getEmbedding(
        text: _cleanText(currentNote.content),
        apiKey: apiKey,
        apiUrl: apiUrl,
      );

      if (currentVector == null) {
        debugPrint('⚠️ 获取向量失败，降级为本地算法');
        return _findByLocalAlgorithm(currentNote, allNotes, topK);
      }

      final results = <RelatedNote>[];

      // 计算每个笔记的相似度
      for (final note in allNotes) {
        if (note.id == currentNote.id || note.content.trim().isEmpty) continue;

        final noteVector = await _getEmbedding(
          text: _cleanText(note.content),
          apiKey: apiKey,
          apiUrl: apiUrl,
        );

        if (noteVector != null) {
          final similarity = _cosineSimilarity(currentVector, noteVector);
          if (similarity > 0.5) {
            results.add(RelatedNote(note: note, similarity: similarity));
          }
        }
      }

      results.sort((a, b) => b.similarity.compareTo(a.similarity));
      return results.take(topK).toList();
    } catch (e) {
      debugPrint('❌ Embedding 策略失败: $e');
      return _findByLocalAlgorithm(currentNote, allNotes, topK);
    }
  }

  /// 获取文本向量
  Future<List<double>?> _getEmbedding({
    required String text,
    required String apiKey,
    required String apiUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/embeddings'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: json.encode({
              'model': 'text-embedding-3-small',
              'input': text.substring(0, min(text.length, 2000)),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<double>.from(data['data'][0]['embedding']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 策略2：使用 Chat API 进行智能分析（DeepSeek 等）
  Future<List<RelatedNote>> _findByAIAnalysis({
    required Note currentNote,
    required List<Note> allNotes,
    required String apiKey,
    required String apiUrl,
    required String model,
    required int topK,
  }) async {
    try {
      // 准备候选笔记（最多30条，避免 token 过多）
      final candidates = allNotes
          .where((n) => n.id != currentNote.id && n.content.trim().isNotEmpty)
          .take(30)
          .toList();

      if (candidates.isEmpty) return [];

      // 构建 AI 分析的 prompt
      final prompt = _buildAnalysisPrompt(currentNote, candidates);

      // 调用 Chat API
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
                {'role': 'system', 'content': '你是一个专业的笔记分析助手，擅长理解笔记之间的语义关联。'},
                {
                  'role': 'user',
                  'content': prompt,
                }
              ],
              'temperature': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content'] as String?;

        if (content != null) {
          return _parseAIResponse(content, candidates);
        }
      } else {
        debugPrint('⚠️ AI分析失败 (${response.statusCode})，降级为本地算法');
      }

      return _findByLocalAlgorithm(currentNote, allNotes, topK);
    } catch (e) {
      debugPrint('❌ AI分析策略失败: $e');
      return _findByLocalAlgorithm(currentNote, allNotes, topK);
    }
  }

  /// 构建 AI 分析的 prompt
  String _buildAnalysisPrompt(Note currentNote, List<Note> candidates) {
    final currentText = _cleanText(currentNote.content);
    final buffer = StringBuffer();

    buffer.writeln('【当前笔记】');
    buffer.writeln(_truncateText(currentText, 500));
    buffer.writeln('\n【候选笔记列表】');

    for (var i = 0; i < candidates.length; i++) {
      final candidateText = _cleanText(candidates[i].content);
      buffer.writeln('ID:${i + 1} | ${_truncateText(candidateText, 200)}');
    }

    buffer.writeln('\n【任务要求】');
    buffer.writeln('请分析当前笔记与候选笔记的语义相关性，找出最相关的5条笔记。');
    buffer.writeln('考虑因素：主题相关性、内容延续性、知识关联性。');
    buffer.writeln('输出格式（每行一个）：');
    buffer.writeln('ID:相关度分数(0-100)');
    buffer.writeln('例如：ID:3:95');
    buffer.writeln('只输出结果，不要其他解释。');

    return buffer.toString();
  }

  /// 解析 AI 返回的结果
  List<RelatedNote> _parseAIResponse(String content, List<Note> candidates) {
    final results = <RelatedNote>[];
    final lines = content.split('\n');

    for (final line in lines) {
      // 匹配格式：ID:3:95 或 3:95
      final match = RegExp(r'(?:ID:)?(\d+)[:\s]+(\d+)').firstMatch(line);
      if (match != null) {
        final id = int.tryParse(match.group(1) ?? '');
        final score = int.tryParse(match.group(2) ?? '');

        if (id != null &&
            score != null &&
            id > 0 &&
            id <= candidates.length &&
            score >= 50) {
          final note = candidates[id - 1];
          results.add(
            RelatedNote(
              note: note,
              similarity: score / 100.0,
            ),
          );
        }
      }
    }

    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }

  /// 策略3：本地算法（降级方案）- 🔥 使用大厂级多维度算法
  List<RelatedNote> _findByLocalAlgorithm(
    Note currentNote,
    List<Note> allNotes,
    int topK,
  ) {
    debugPrint('📊 使用大厂级多维度算法（TF-IDF + 链接分析 + 时间衰减）');
    
    // 使用改进的算法
    return _findByAdvancedAlgorithm(currentNote, allNotes, topK);
  }
  
  /// 🏢 大厂级多维度算法（参考 Notion/Obsidian）
  List<RelatedNote> _findByAdvancedAlgorithm(
    Note currentNote,
    List<Note> allNotes,
    int topK,
  ) {
    final results = <RelatedNote>[];
    final currentText = _cleanText(currentNote.content);
    final currentTags = currentNote.tags.toSet();
    final currentLinks = _extractLinks(currentNote.content);
    
    // 🔥 构建 TF-IDF 模型
    final tfidfModel = _buildTFIDF(allNotes);
    final currentVector = tfidfModel[currentNote.id] ?? {};
    
    for (final note in allNotes) {
      if (note.id == currentNote.id || note.content.trim().isEmpty) continue;
      
      final noteText = _cleanText(note.content);
      final noteTags = note.tags.toSet();
      final noteLinks = _extractLinks(note.content);
      final noteVector = tfidfModel[note.id] ?? {};
      
      // 🎯 多维度评分
      final contentScore = _calculateTFIDFSimilarity(currentVector, noteVector);
      final tagScore = _calculateTagSimilarity(currentTags, noteTags);
      final linkScore = _calculateLinkSimilarity(
        currentNote.id,
        note.id,
        currentLinks,
        noteLinks,
      );
      final timeScore = _calculateTimeScore(note.updatedAt);
      
      // 🔥 加权计算最终分数
      final finalScore = contentScore * 0.4 +
          tagScore * 0.25 +
          linkScore * 0.25 +
          timeScore * 0.1;
      
      if (finalScore > 0.3) {
        results.add(RelatedNote(note: note, similarity: finalScore));
      }
    }
    
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    
    if (kDebugMode && results.isNotEmpty) {
      debugPrint('✅ 找到 ${results.length} 条相关笔记');
      debugPrint('📊 Top 3: ${results.take(3).map((r) => '${(r.similarity * 100).toStringAsFixed(0)}%').join(', ')}');
    }
    
    return results.take(topK).toList();
  }
  
  /// 📊 构建 TF-IDF 模型
  Map<String, Map<String, double>> _buildTFIDF(List<Note> allNotes) {
    final documentFreq = <String, int>{};
    final termFreqs = <String, Map<String, int>>{};
    
    // 统计词频
    for (final note in allNotes) {
      final text = _cleanText(note.content);
      final terms = _extractKeywords(text);
      final uniqueTerms = terms.toSet();
      
      for (final term in uniqueTerms) {
        documentFreq[term] = (documentFreq[term] ?? 0) + 1;
      }
      
      final tf = <String, int>{};
      for (final term in terms) {
        tf[term] = (tf[term] ?? 0) + 1;
      }
      termFreqs[note.id] = tf;
    }
    
    // 计算 TF-IDF
    final tfidf = <String, Map<String, double>>{};
    final totalDocs = allNotes.length;
    
    for (final note in allNotes) {
      final tf = termFreqs[note.id] ?? {};
      final vector = <String, double>{};
      
      for (final entry in tf.entries) {
        final term = entry.key;
        final termFreq = entry.value;
        final docFreq = documentFreq[term] ?? 1;
        final tfidfScore = termFreq * log(totalDocs / docFreq);
        vector[term] = tfidfScore;
      }
      
      tfidf[note.id] = vector;
    }
    
    return tfidf;
  }
  
  /// 🎯 计算 TF-IDF 余弦相似度
  double _calculateTFIDFSimilarity(
    Map<String, double> vector1,
    Map<String, double> vector2,
  ) {
    if (vector1.isEmpty || vector2.isEmpty) return 0.0;
    
    var dotProduct = 0.0;
    var norm1 = 0.0;
    var norm2 = 0.0;
    
    for (final term in vector1.keys) {
      final v1 = vector1[term]!;
      final v2 = vector2[term] ?? 0.0;
      dotProduct += v1 * v2;
      norm1 += v1 * v1;
    }
    
    for (final v2 in vector2.values) {
      norm2 += v2 * v2;
    }
    
    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    return dotProduct / (norm1 * norm2);
  }
  
  /// 🏷️ 计算标签相似度
  double _calculateTagSimilarity(Set<String> tags1, Set<String> tags2) {
    if (tags1.isEmpty && tags2.isEmpty) return 0.0;
    final intersection = tags1.intersection(tags2);
    final union = tags1.union(tags2);
    return union.isEmpty ? 0.0 : intersection.length / union.length;
  }
  
  /// 🔗 计算链接相似度
  double _calculateLinkSimilarity(
    String noteId1,
    String noteId2,
    Set<String> links1,
    Set<String> links2,
  ) {
    // 直接链接
    if (links1.contains(noteId2) || links2.contains(noteId1)) {
      return 1.0;
    }
    
    // 共同链接
    final commonLinks = links1.intersection(links2);
    if (commonLinks.isNotEmpty) {
      final allLinks = links1.union(links2);
      return commonLinks.length / allLinks.length * 0.8;
    }
    
    return 0.0;
  }
  
  /// ⏰ 时间新鲜度
  double _calculateTimeScore(DateTime noteTime) {
    final daysDiff = DateTime.now().difference(noteTime).inDays;
    if (daysDiff <= 7) return 1.0;
    if (daysDiff <= 30) return 0.7;
    if (daysDiff <= 90) return 0.4;
    if (daysDiff <= 180) return 0.2;
    return 0.1;
  }
  
  /// 🔗 提取链接引用
  Set<String> _extractLinks(String content) {
    final links = <String>{};
    final pattern = RegExp(r'\[\[([^\]]+)\]\]');
    for (final match in pattern.allMatches(content)) {
      final link = match.group(1);
      if (link != null && link.isNotEmpty) {
        links.add(link);
      }
    }
    return links;
  }

  /// 提取关键词
  List<String> _extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fa5]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1)
        .where((word) => !_isStopWord(word))
        .toList();

    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    final keywords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return keywords.take(50).map((e) => e.key).toList();
  }

  /// 判断停用词
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
      'but',
      'in',
      'with',
      'to',
      'for',
      'of',
      'as',
      'by',
      'this',
      'that',
      '的',
      '了',
      '和',
      '是',
      '在',
      '我',
      '有',
      '个',
      '就',
      '不',
      '人',
      '都',
      '一',
      '一个',
      '上',
      '也',
      '很',
      '到',
      '说',
      '要',
    };
    return stopWords.contains(word);
  }


  /// 计算余弦相似度
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;

    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (normA * normB);
  }

  /// 清理文本
  String _cleanText(String content) {
    var cleaned = content;

    // 清理 Markdown 链接：[文本](url) -> 文本
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );

    // 清理 Markdown 格式标记
    cleaned = cleaned.replaceAll(RegExp('[*_`#~]'), '');

    // 清理多余的空白
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.trim();
  }

  /// 截断文本
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 缓存结果
  Future<void> _cacheResult(String key, List<RelatedNote> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final data = notes
          .map(
            (n) => {
              'id': n.note.id,
              'similarity': n.similarity,
            },
          )
          .toList();
      await prefs.setString(cacheKey, json.encode(data));
      await prefs.setInt(
        '${cacheKey}_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('⚠️ 缓存失败: $e');
    }
  }

  /// 获取缓存
  Future<List<Map<String, dynamic>>?> _getCachedResult(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final data = prefs.getString(cacheKey);
      final timestamp = prefs.getInt('${cacheKey}_time');

      if (data == null || timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
        await prefs.remove(cacheKey);
        await prefs.remove('${cacheKey}_time');
        return null;
      }

      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      return null;
    }
  }

  /// 解析缓存的笔记
  List<RelatedNote> _parseRelatedNotes(
    List<Map<String, dynamic>> cached,
    List<Note> allNotes,
  ) {
    final results = <RelatedNote>[];
    for (final item in cached) {
      final note = allNotes.firstWhere(
        (n) => n.id == item['id'],
        orElse: () => Note(
          id: '',
          content: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (note.id.isNotEmpty) {
        results.add(
          RelatedNote(
            note: note,
            similarity: item['similarity'] ?? 0.0,
          ),
        );
      }
    }
    return results;
  }

  /// 清除缓存
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('⚠️ 清除缓存失败: $e');
    }
  }
}

/// 相关笔记模型
class RelatedNote {
  RelatedNote({
    required this.note,
    required this.similarity,
  });
  final Note note;
  final double similarity;

  int get similarityPercent => (similarity * 100).round();
}
