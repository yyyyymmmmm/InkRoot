import 'package:flutter/foundation.dart';

/// 微信读书笔记解析器
class WeReadParser {
  /// 解析微信读书笔记文本
  static WeReadNotesData parse(String content) {
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (lines.isEmpty) {
      throw Exception('笔记内容为空');
    }

    // 解析书名（第一行，去掉《》）
    var bookTitle = lines[0].trim();
    if (bookTitle.startsWith('《') && bookTitle.contains('》')) {
      bookTitle = bookTitle.substring(1, bookTitle.indexOf('》'));
    }

    // 解析笔记
    final notes = <WeReadNote>[];
    String? currentChapter;
    String? currentReview;
    String? reviewDate;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      // 跳过已知元数据行
      if (line.contains('个笔记') ||
          line == '点评' ||
          line.contains('来自微信读书') ||
          line.contains('发表想法')) {
        continue;
      }

      // 解析点评日期（格式如 "2024/01/01 xxx认为"）
      if (line.contains('/') && (line.contains('认为') || line.length < 20)) {
        reviewDate = line.split(' ')[0];
        currentReview = line;
        continue;
      }

      // 解析笔记内容（以 ◆ 开头）
      if (line.startsWith('◆')) {
        final content = line.replaceFirst(RegExp(r'^◆\s*'), '').trim();
        if (content.startsWith('原文：') || content.isEmpty) {
          continue;
        }

        notes.add(
          WeReadNote(
            bookTitle: bookTitle,
            chapter: currentChapter ?? bookTitle, // 无章节时用书名兜底
            content: content,
            review: currentReview,
            reviewDate: reviewDate,
          ),
        );
        currentReview = null;
        reviewDate = null;
        continue;
      }

      // 其余所有非空行均视为章节标题
      // 兼容："第一章 标题"、"1"、"快感、幸福和快乐"、"斯宾诺莎的解放之路" 等各种格式
      if (line.isNotEmpty) {
        // 纯数字短行格式化显示
        if (line.length <= 3 && RegExp(r'^\d+$').hasMatch(line)) {
          currentChapter = '第 $line 部分';
        } else {
          currentChapter = line;
        }
      }
    }

    debugPrint('解析完成: 书名=$bookTitle, 笔记数=${notes.length}');

    return WeReadNotesData(
      bookTitle: bookTitle,
      notes: notes,
    );
  }

  /// 转换为 Markdown 格式
  static String toMarkdown(WeReadNotesData data) {
    final buffer = StringBuffer();

    // 书名作为标题
    buffer.writeln('# ${data.bookTitle}\n');

    // 添加标签
    buffer.writeln('#资源/工具库/anki #翻译/能力/阅读理解 #微信读书\n');

    // 如果有总体点评
    if (data.notes.any((n) => n.review != null)) {
      final firstReview = data.notes.firstWhere((n) => n.review != null);
      buffer.writeln('## 📝 阅读点评\n');
      buffer.writeln('${firstReview.review}\n');
    }

    // 按章节分组
    final chapterMap = <String, List<WeReadNote>>{};
    for (final note in data.notes) {
      chapterMap.putIfAbsent(note.chapter, () => []).add(note);
    }

    // 输出笔记
    buffer.writeln('## 📖 阅读笔记\n');
    chapterMap.forEach((chapter, notes) {
      buffer.writeln('### $chapter\n');
      for (final note in notes) {
        // 使用引用格式
        buffer.writeln('> ${note.content}\n');
      }
    });

    buffer.writeln('---');
    buffer.writeln('*导入自微信读书*');

    return buffer.toString();
  }
}

/// 微信读书笔记数据
class WeReadNotesData {
  WeReadNotesData({
    required this.bookTitle,
    required this.notes,
  });
  final String bookTitle;
  final List<WeReadNote> notes;
}

/// 单条笔记
class WeReadNote {
  WeReadNote({
    required this.bookTitle,
    required this.chapter,
    required this.content,
    this.review,
    this.reviewDate,
  });
  final String bookTitle;
  final String chapter;
  final String content;
  final String? review;
  final String? reviewDate;
}
