import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/utils/memos_content_helper.dart';
import 'package:inkroot/utils/text_analysis_utils.dart';
import 'package:inkroot/utils/todo_parser.dart';

class LocalNoteAnalysisService {
  const LocalNoteAnalysisService();

  String generateReview({
    required Note note,
    List<Note> allNotes = const [],
  }) {
    final visibleText = MemosContentHelper.previewVisibleText(note.content);
    final plainText = visibleText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plainText.isEmpty && note.resourceList.isEmpty) {
      return '本地点评只看到附件，没有读到正文。建议补一句这张图或这个文件要解决什么问题，否则以后只能按图片回找。';
    }

    final todos = TodoParser.parseTodos(note.content);
    final pendingTodos = todos.where((todo) => !todo.checked).length;
    final firstPendingTodo = todos
        .where((todo) => !todo.checked && todo.text.trim().isNotEmpty)
        .map((todo) => todo.text.trim())
        .firstOrNull;
    final tags = note.tags.isNotEmpty
        ? note.tags
        : Note.extractTagsFromContent(note.content);
    final linkMatches = RegExp(r'https?://[^\s)]+').allMatches(note.content);
    final links = linkMatches.length;
    final firstLinkHost = _firstLinkHost(linkMatches);
    final images = MemosContentHelper.extractNoteImagePaths(note).length;
    final related = _findRelatedNotes(note, allNotes);
    final terms = TextAnalysisUtils.extractTerms(plainText);
    final keywords = _topKeywords(terms);
    final evidence = _bestEvidenceLine(plainText);

    final core = _buildCoreSentence(
      plainText: plainText,
      tags: tags,
      keywords: keywords,
      evidence: evidence,
      pendingTodos: pendingTodos,
      firstPendingTodo: firstPendingTodo,
      links: links,
      firstLinkHost: firstLinkHost,
      images: images,
    );
    final action = _buildActionSentence(
      plainText: plainText,
      evidence: evidence,
      pendingTodos: pendingTodos,
      firstPendingTodo: firstPendingTodo,
      links: links,
      firstLinkHost: firstLinkHost,
      images: images,
      tags: tags,
      related: related,
    );
    final connection = _buildConnectionSentence(related, keywords);

    return [core, action, connection]
        .where((item) => item.isNotEmpty)
        .join(' ');
  }

  List<Note> findRelatedNotes(
    Note currentNote,
    List<Note> allNotes, {
    int limit = 5,
  }) =>
      _findRelatedNotes(currentNote, allNotes).take(limit).toList();

  String _buildCoreSentence({
    required String plainText,
    required List<String> tags,
    required List<String> keywords,
    required String evidence,
    required int pendingTodos,
    required String? firstPendingTodo,
    required int links,
    required String? firstLinkHost,
    required int images,
  }) {
    if (pendingTodos > 0) {
      final todoText = firstPendingTodo == null
          ? '$pendingTodos 个未完成待办'
          : '「${_clip(firstPendingTodo, 18)}」';
      return '这条笔记已经有明确动作：$todoText。';
    }
    if (links > 0) {
      final target = firstLinkHost ?? '$links 个链接';
      final prefix = evidence.isEmpty ? '' : '「${_clip(evidence, 24)}」旁边';
      return '这条笔记保存了$prefix来自 $target 的资料入口。';
    }
    if (images > 0 && plainText.length < 30) {
      return '这条笔记主要靠图片承载信息，文字里只有「${_clip(evidence, 18)}」。';
    }
    if (tags.isNotEmpty) {
      return '这条笔记落在「${tags.take(2).join('、')}」下，最具体的句子是「${_clip(evidence, 24)}」。';
    }
    if (keywords.isNotEmpty) {
      return '本地能抓到的核心词是「${keywords.take(2).join('、')}」，对应原文「${_clip(evidence, 24)}」。';
    }
    if (plainText.length < 30) {
      return '这条笔记很短，当前能保留下来的只有「${_clip(evidence, 24)}」。';
    }
    return '这条笔记最值得保留的是「${_clip(evidence, 30)}」。';
  }

  String _buildActionSentence({
    required String plainText,
    required String evidence,
    required int pendingTodos,
    required String? firstPendingTodo,
    required int links,
    required String? firstLinkHost,
    required int images,
    required List<String> tags,
    required List<Note> related,
  }) {
    if (pendingTodos > 0) {
      final target = firstPendingTodo == null
          ? '这些待办'
          : '「${_clip(firstPendingTodo, 18)}」';
      return '下一步不是继续点评，而是给$target补完成标准或时间。';
    }
    if (links > 0) {
      final target = firstLinkHost ?? '这个链接';
      return '如果 $target 是资料来源，建议补一句它支持哪个判断，避免以后只剩收藏入口。';
    }
    if (images > 0 && plainText.length < 20) {
      return '图片内容不会天然进入搜索，建议补一句图里最重要的对象或结论。';
    }
    if (!_hasConclusionCue(plainText) && plainText.length > 80) {
      return '目前还缺一句自己的判断，可以直接接在「${_clip(evidence, 18)}」后面写“所以...”。';
    }
    if (plainText.length < 30) {
      return '建议补一个背景词，比如时间、项目或场景，让这句话以后还能被理解。';
    }
    if (tags.isEmpty) {
      return '建议补一个真实主题词，不要只靠全文搜索。';
    }
    if (related.isNotEmpty) {
      return '下一步可以先和旧笔记对照，判断它是新想法还是同一问题的延续。';
    }
    return '可以补一个追问：这条记录以后要帮你做什么决定。';
  }

  String _buildConnectionSentence(List<Note> related, List<String> keywords) {
    if (related.isEmpty) {
      return '';
    }
    final topic = keywords.isEmpty ? '' : '，共同关键词是「${keywords.first}」';
    if (related.length == 1) {
      return '它和旧笔记「${_previewTitle(related.first)}」有关$topic。';
    }
    return '还找到 ${related.length} 条相近旧笔记$topic，值得一起看而不是单条判断。';
  }

  List<String> _topKeywords(List<String> terms) {
    final counts = <String, int>{};
    for (final term in terms) {
      if (term.length < 2) {
        continue;
      }
      counts[term] = (counts[term] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return b.key.length.compareTo(a.key.length);
      });
    return entries.take(4).map((entry) => entry.key).toList();
  }

  List<Note> _findRelatedNotes(Note currentNote, List<Note> allNotes) {
    final currentTerms =
        TextAnalysisUtils.extractTerms(currentNote.content).toSet();
    final currentTags = currentNote.tags.toSet();
    final scored = <_ScoredNote>[];

    for (final note in allNotes) {
      if (note.id == currentNote.id || note.content.trim().isEmpty) {
        continue;
      }

      final noteTerms = TextAnalysisUtils.extractTerms(note.content).toSet();
      final noteTags = note.tags.toSet();
      final termScore =
          TextAnalysisUtils.jaccardSimilarity(currentTerms, noteTerms);
      final tagScore =
          TextAnalysisUtils.jaccardSimilarity(currentTags, noteTags);
      final days =
          currentNote.updatedAt.difference(note.updatedAt).inDays.abs();
      final timeScore = days <= 7
          ? 0.3
          : days <= 30
              ? 0.16
              : 0.05;
      final score = termScore * 0.55 + tagScore * 0.35 + timeScore;

      if (score > 0.12) {
        scored.add(_ScoredNote(note, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((item) => item.note).toList();
  }

  String _previewTitle(Note note) {
    final text = MemosContentHelper.previewVisibleText(note.content)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) {
      return '图片笔记';
    }
    return text.length <= 12 ? text : '${text.substring(0, 12)}...';
  }

  String _bestEvidenceLine(String text) {
    final lines = text
        .split(RegExp(r'[\n。！？!?]'))
        .map((line) => line.trim())
        .where(
          (line) =>
              line.isNotEmpty &&
              !line.startsWith('#') &&
              !RegExp('^https?://').hasMatch(line),
        )
        .toList();
    if (lines.isEmpty) {
      return text.trim();
    }
    lines.sort((a, b) {
      final aScore = _evidenceScore(a);
      final bScore = _evidenceScore(b);
      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      }
      return b.length.compareTo(a.length);
    });
    return lines.first;
  }

  int _evidenceScore(String line) {
    var score = line.length.clamp(0, 40);
    const cues = ['因为', '所以', '但是', '问题', '需要', '失败', '不能', '建议', '结论'];
    for (final cue in cues) {
      if (line.contains(cue)) {
        score += 12;
      }
    }
    return score;
  }

  String? _firstLinkHost(Iterable<RegExpMatch> matches) {
    for (final match in matches) {
      final raw = match.group(0);
      final uri = raw == null ? null : Uri.tryParse(raw);
      if (uri != null && uri.host.isNotEmpty) {
        return uri.host;
      }
    }
    return null;
  }

  String _clip(String text, int maxLength) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxLength)}...';
  }

  bool _hasConclusionCue(String text) =>
      text.contains('所以') ||
      text.contains('结论') ||
      text.contains('总结') ||
      text.contains('下一步') ||
      text.toLowerCase().contains('todo');
}

class _ScoredNote {
  const _ScoredNote(this.note, this.score);

  final Note note;
  final double score;
}
