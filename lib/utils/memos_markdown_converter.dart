// Memos Markdown转换器
// 将Memos特殊语法转换为flutter_markdown可以渲染的标准格式

class MemosMarkdownConverter {
  MemosMarkdownConverter({this.serverUrl});
  final String? serverUrl;

  /// 转换Memos Markdown为标准Markdown
  String convert(String content) {
    var result = content;

    // 1. 图片URL由imageBuilder处理，这里保持原样

    // 2. 处理高亮 ==text== → 保留原样，用flutter_markdown的builder处理
    // flutter_markdown支持自定义builder

    // 3. 处理数学公式 $formula$ 和 $$formula$$
    // flutter_markdown有math扩展支持

    // 4. 处理Spoiler <span class="spoiler">text</span>
    // 转换为引用格式（近似效果）
    result = result.replaceAllMapped(
      RegExp('<span class="spoiler">([^<]+)</span>'),
      (match) => '||${match.group(1)}||', // 使用Discord风格的spoiler
    );

    // 5. 处理上标 ^text^
    result = result.replaceAllMapped(
      RegExp(r'\^([^\^]+)\^'),
      (match) => '<sup>${match.group(1)}</sup>',
    );

    // 6. 处理下标 ~text~
    result = result.replaceAllMapped(
      RegExp('~([^~]+)~'),
      (match) => '<sub>${match.group(1)}</sub>',
    );

    // 🎯 0. 优先处理待办事项（为已完成的任务添加删除线）
    result = _convertCompletedTodos(result);

    // 7. 标签#tag - 转换为链接格式（可点击，有颜色）
    // 🎯 改进的标签识别规则（参考Obsidian/Notion/Logseq）：
    // - 排除URL中的#：不在://之后
    // - 前缀要求：#前面不能是字母、数字、下划线、冒号、斜杠（避免URL和路径）
    // - 排除连续##（Markdown标题）
    // - 标签内容不包含#（避免## Heading被识别）
    result = _convertTagsToLinks(result);

    return result;
  }

  // 🎯 将已完成的待办事项文字包裹在删除线标记中（~~text~~）
  String _convertCompletedTodos(String content) {
    final lines = content.split('\n');
    final processedLines = <String>[];

    for (var line in lines) {
      // 匹配已完成的待办事项：- [x] 或 - [X] 或 * [x] 等
      final completedTodoRegex = RegExp(r'^(\s*[-*+]\s+\[)[xX](\]\s+)(.+)$');
      final match = completedTodoRegex.firstMatch(line);

      if (match != null) {
        // 提取各部分
        final prefix = match.group(1)!; // "- [" 或 "* ["
        final middle = match.group(2)!; // "] "
        final text = match.group(3)!;   // 任务文字

        // 检查文字是否已经有删除线标记
        if (!text.startsWith('~~') || !text.endsWith('~~')) {
          // 包裹删除线（flutter_markdown会渲染为灰色+删除线）
          processedLines.add('${prefix}x$middle~~$text~~');
        } else {
          processedLines.add(line);
        }
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  /// 智能识别并转换标签为链接（排除URL中的#）
  String _convertTagsToLinks(String content) {
    // 🎯 改进的标签正则：
    // (?<![\w:/]) - 前面不能是字母、数字、下划线、冒号、斜杠
    // (?!#) - 后面不能紧跟#（排除##标题）
    // #([^\s\[\],，、;；:：！!？?\n#]+) - 标签内容，不包含#
    final tagRegex = RegExp(
      r'(?<![\w:/])(?!##)#([^\s\[\],，、;；:：！!？?\n#]+)',
      unicode: true,
    );

    // 先检测是否在URL中（简单启发式：检查是否在包含://的行中）
    final lines = content.split('\n');
    final result = <String>[];

    for (final line in lines) {
      // 如果这行包含URL（http://、https://、ftp://等），需要更谨慎处理
      if (line.contains(RegExp(r'[a-zA-Z]+://'))) {
        // 包含URL的行，只转换明确不在URL中的标签
        result.add(_convertTagsInLineWithUrl(line, tagRegex));
      } else {
        // 没有URL的行，直接转换所有匹配的标签
        result.add(line.replaceAllMapped(
          tagRegex,
          (match) => '[#${match.group(1)}](#${match.group(1)})',
        ));
      }
    }

    return result.join('\n');
  }

  /// 在包含URL的行中谨慎转换标签
  String _convertTagsInLineWithUrl(String line, RegExp tagRegex) {
    // 找出所有URL的位置范围
    final urlRegex = RegExp(r'[a-zA-Z]+://[^\s\)]+');
    final urlMatches = urlRegex.allMatches(line).toList();
    final urlRanges = urlMatches.map((m) => [m.start, m.end]).toList();

    // 找出所有标签的位置
    final tagMatches = tagRegex.allMatches(line).toList();

    // 只转换不在URL范围内的标签
    var result = line;
    var offset = 0;

    for (final tagMatch in tagMatches) {
      final tagStart = tagMatch.start;
      final tagEnd = tagMatch.end;

      // 检查这个标签是否在任何URL范围内
      var inUrl = false;
      for (final range in urlRanges) {
        if (tagStart >= range[0] && tagEnd <= range[1]) {
          inUrl = true;
          break;
        }
      }

      // 如果不在URL中，则转换
      if (!inUrl) {
        final originalTag = tagMatch.group(0)!;
        final tagName = tagMatch.group(1)!;
        final replacement = '[#$tagName](#$tagName)';
        final position = tagMatch.start + offset;
        result = result.replaceRange(
          position,
          position + originalTag.length,
          replacement,
        );
        offset += replacement.length - originalTag.length;
      }
    }

    return result;
  }

  /// 提取所有标签（改进版，排除URL中的#）
  static List<String> extractTags(String content) {
    // 🎯 改进的标签识别规则：
    // - 排除URL中的#
    // - 前缀要求：#前面不能是字母、数字、下划线、冒号、斜杠
    // - 排除连续##（Markdown标题）
    final tagRegex = RegExp(
      r'(?<![\w:/])(?!##)#([^\s\[\],，、;；:：！!？?\n#]+)',
      unicode: true,
    );

    final tags = <String>[];
    final lines = content.split('\n');

    for (final line in lines) {
      // 如果这行包含URL，需要排除URL中的#
      if (line.contains(RegExp(r'[a-zA-Z]+://'))) {
        // 找出所有URL的位置范围
        final urlRegex = RegExp(r'[a-zA-Z]+://[^\s\)]+');
        final urlMatches = urlRegex.allMatches(line).toList();
        final urlRanges = urlMatches.map((m) => [m.start, m.end]).toList();

        // 找出所有标签，但排除在URL范围内的
        final tagMatches = tagRegex.allMatches(line);
        for (final match in tagMatches) {
          var inUrl = false;
          for (final range in urlRanges) {
            if (match.start >= range[0] && match.end <= range[1]) {
              inUrl = true;
              break;
            }
          }
          if (!inUrl) {
            tags.add(match.group(1)!);
          }
        }
      } else {
        // 没有URL的行，直接提取所有标签
        tags.addAll(
          tagRegex.allMatches(line).map((match) => match.group(1)!),
        );
      }
    }

    return tags;
  }

  /// 提取所有图片URL
  static List<String> extractImageUrls(String content) {
    final imgRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');
    return imgRegex
        .allMatches(content)
        .map((match) => match.group(2)!)
        .toList();
  }
}
