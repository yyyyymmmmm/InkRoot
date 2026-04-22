import 'package:flutter/foundation.dart';

/// 微信读书笔记解析器
class WeReadParser {
  /// 解析微信读书笔记文本
  static WeReadNotesData parse(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      throw Exception('笔记内容为空');
    }
    
    // 解析书名（第一行，去掉《》）
    String bookTitle = lines[0].trim();
    if (bookTitle.startsWith('《') && bookTitle.contains('》')) {
      bookTitle = bookTitle.substring(1, bookTitle.indexOf('》'));
    }
    
    // 解析笔记
    final notes = <WeReadNote>[];
    String? currentChapter;
    String? currentReview;
    String? reviewDate;
    
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 跳过"X个笔记"、"点评"标题和"来自微信读书"
      if (line.contains('个笔记') || 
          line == '点评' || 
          line.contains('来自微信读书') ||
          line.contains('发表想法')) {
        continue;
      }
      
      // 解析点评日期
      if (line.contains('/') && (line.contains('认为') || line.length < 20)) {
        reviewDate = line.split(' ')[0]; // 提取日期
        currentReview = line;
        continue;
      }
      
      // 解析章节标题（数字或包含"第"和"章"）
      if ((line.length <= 3 && RegExp(r'^\d+$').hasMatch(line)) || 
          (line.contains('第') && line.contains('章'))) {
        currentChapter = line.length <= 3 ? '第 $line 部分' : line;
        continue;
      }
      
      // 解析笔记内容（去掉 ◆ 符号）
      String content = line;
      if (content.startsWith('◆ ')) {
        content = content.substring(2).trim();
      }
      
      // 跳过原文标记
      if (content.startsWith('原文：')) {
        continue;
      }
      
      if (content.isNotEmpty && currentChapter != null) {
        notes.add(WeReadNote(
          bookTitle: bookTitle,
          chapter: currentChapter,
          content: content,
          review: currentReview,
          reviewDate: reviewDate,
        ));
        
        // 重置点评（每个笔记只关联一次点评）
        currentReview = null;
        reviewDate = null;
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
  final String bookTitle;
  final List<WeReadNote> notes;
  
  WeReadNotesData({
    required this.bookTitle,
    required this.notes,
  });
}

/// 单条笔记
class WeReadNote {
  final String bookTitle;
  final String chapter;
  final String content;
  final String? review;
  final String? reviewDate;
  
  WeReadNote({
    required this.bookTitle,
    required this.chapter,
    required this.content,
    this.review,
    this.reviewDate,
  });
}
