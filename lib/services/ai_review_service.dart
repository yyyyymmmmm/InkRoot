import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/services/local_note_analysis_service.dart';
import 'package:inkroot/utils/memos_content_helper.dart';

class AiReviewService {
  const AiReviewService({
    this.localAnalysisService = const LocalNoteAnalysisService(),
  });

  final LocalNoteAnalysisService localAnalysisService;

  Future<AiReviewResult> generateReview({
    required AppConfig appConfig,
    required Note note,
    required List<Note> allNotes,
  }) async {
    final localReview = localAnalysisService.generateReview(
      note: note,
      allNotes: allNotes,
    );

    if (!_canUseRemoteAI(appConfig)) {
      return AiReviewResult(
        review: localReview,
        source: AiReviewSource.local,
      );
    }

    try {
      final apiService = DeepSeekApiService(
        apiUrl: appConfig.aiApiUrl!,
        apiKey: appConfig.aiApiKey!,
        model: appConfig.aiModel,
      );
      final messages = [
        DeepSeekApiService.buildSystemMessage(_systemPrompt(appConfig)),
        DeepSeekApiService.buildUserMessage(
          _userPrompt(note: note, allNotes: allNotes),
        ),
      ];
      final (review, error) = await apiService.chat(
        messages: messages,
        temperature: 0.45,
        maxTokens: 520,
      );

      final cleaned = review == null ? null : cleanMarkdownForReview(review);
      if (cleaned == null || cleaned.trim().isEmpty) {
        return AiReviewResult(
          review: localReview,
          source: AiReviewSource.localFallback,
          remoteError: error ?? 'AI点评内容为空',
        );
      }

      return AiReviewResult(
        review: cleaned,
        source: AiReviewSource.remote,
      );
    } on Object catch (e) {
      return AiReviewResult(
        review: localReview,
        source: AiReviewSource.localFallback,
        remoteError: 'AI点评失败: $e',
      );
    }
  }

  bool _canUseRemoteAI(AppConfig appConfig) =>
      appConfig.aiEnabled &&
      appConfig.aiApiUrl != null &&
      appConfig.aiApiUrl!.isNotEmpty &&
      appConfig.aiApiKey != null &&
      appConfig.aiApiKey!.isNotEmpty;

  String _systemPrompt(AppConfig appConfig) {
    if (appConfig.useCustomPrompt &&
        appConfig.customReviewPrompt != null &&
        appConfig.customReviewPrompt!.trim().isNotEmpty) {
      return '${appConfig.customReviewPrompt!.trim()}\n\n'
          '额外硬性要求：不要使用 Markdown 标题、列表符号或 emoji；不要复述原文；'
          '必须给出具体价值判断、一个可执行下一步，并保持克制。';
    }

    return '''
你是 InkRoot 的专业笔记点评顾问。你的任务不是夸奖、摘要或聊天，而是帮用户看见这条笔记真正有用的地方，以及下一步怎么让它产生价值。

输出必须像一个高水准产品经理、写作教练和知识管理顾问的综合判断。

硬性要求：
1. 只输出纯文本，不要 Markdown 标题、编号、项目符号、emoji。
2. 不要说“这篇笔记主要讲了”“写得很好”“继续保持”这种废话。
3. 不要心理诊断，不要过度解读人格，不要替用户下终极结论。
4. 必须具体引用笔记里的关键词或事实，但不要大段复述。
5. 3 到 5 句话，120 到 180 字；短笔记可以更短，但必须有用。
6. 如果存在相关笔记，要点出它和当前笔记的连接价值。

输出结构：
第一句：直接给核心判断，指出这条笔记最值得保留的价值。
第二句：指出一个盲点、缺口或可以增强的地方。
第三句：给一个很小但明确的下一步动作。
第四句可选：如果有相关笔记，说明可以如何放在一起复盘。

质量标准：
好的点评应该让用户觉得“它指出了我没说透但确实重要的点”。
差的点评是泛泛总结、空洞鼓励、套话建议。
''';
  }

  String _userPrompt({
    required Note note,
    required List<Note> allNotes,
  }) {
    final content = note.content.trim();
    final related = localAnalysisService.findRelatedNotes(
      note,
      allNotes,
      limit: 3,
    );
    final relatedBlock = related.isEmpty
        ? '无'
        : related
            .map(
              (item) =>
                  '- ${_formatDate(item.displayTime)}：${_preview(item.content, 90)}',
            )
            .join('\n');

    return '''
请点评下面这条笔记。注意：用户要的是有帮助的判断，不是摘要。

当前笔记：
$content

可能相关的旧笔记：
$relatedBlock

请按系统要求输出最终点评。
''';
  }

  String _preview(String content, int maxLength) {
    final text = MemosContentHelper.previewVisibleText(content)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String cleanMarkdownForReview(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp('__(.*?)__'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
      r'$1',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp('(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp('~~(.*?)~~'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAllMapped(
      RegExp('`(.*?)`'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'^[\-\*]{3,}\s*$', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[\-\*\+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }
}

class AiReviewResult {
  const AiReviewResult({
    required this.review,
    required this.source,
    this.remoteError,
  });

  final String review;
  final AiReviewSource source;
  final String? remoteError;

  bool get usedRemote => source == AiReviewSource.remote;
  bool get usedFallback => source == AiReviewSource.localFallback;
}

enum AiReviewSource {
  remote,
  local,
  localFallback,
}
