// Memos Markdown转换器
// 将Memos特殊语法转换为flutter_markdown可以渲染的标准格式

class MemosMarkdownConverter {
  MemosMarkdownConverter({this.serverUrl});
  final String? serverUrl;

  /// 转换Memos Markdown为标准Markdown
  String convert(String content) {
    var result = content;

    // 1. 图片URL由imageBuilder处理，这里保持原样

    // 1.1 兼容导入/同步中常见的宽松 Markdown：如 **标题 **。
    // GFM 不会把结尾空格包在强调标记内的文本识别为粗体，这里只在渲染前归一化。
    result = _normalizeLooseStrongDelimiters(result);

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

    // 7. 标签 #tag 转成标准 Markdown 链接。显示文本不变，避免用独立组件破坏原排版。
    result = _convertTagsToLinks(result);

    return result;
  }

  String _normalizeLooseStrongDelimiters(String content) {
    final lines = content.split('\n');
    var inFence = false;

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trimLeft();
      final isFence = trimmed.startsWith('```') || trimmed.startsWith('~~~');

      if (!inFence && !isFence && !lines[i].contains('`')) {
        lines[i] = lines[i].replaceAllMapped(
          RegExp(r'\*\*([ \t]*)([^*\n]*?[^*\s])([ \t]*)\*\*'),
          (match) {
            final leadingSpace = match.group(1) ?? '';
            final text = match.group(2) ?? '';
            final trailingSpace = match.group(3) ?? '';
            return '$leadingSpace**$text**$trailingSpace';
          },
        );
      }

      if (isFence) {
        inFence = !inFence;
      }
    }

    return lines.join('\n');
  }

  // 🎯 将已完成的待办事项文字包裹在删除线标记中（~~text~~）
  String _convertCompletedTodos(String content) {
    final lines = content.split('\n');
    final processedLines = <String>[];

    for (final line in lines) {
      // 匹配已完成的待办事项：- [x] 或 - [X] 或 * [x] 等
      final completedTodoRegex = RegExp(r'^(\s*[-*+]\s+\[)[xX](\]\s+)(.+)$');
      final match = completedTodoRegex.firstMatch(line);

      if (match != null) {
        // 提取各部分
        final prefix = match.group(1)!; // "- [" 或 "* ["
        final middle = match.group(2)!; // "] "
        final text = match.group(3)!; // 任务文字

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

  String _convertTagsToLinks(String content) {
    final lines = content.split('\n');
    final result = <String>[];
    var inFence = false;

    for (final line in lines) {
      final trimmedLeft = line.trimLeft();
      final isFence =
          trimmedLeft.startsWith('```') || trimmedLeft.startsWith('~~~');

      if (inFence || isFence) {
        result.add(line);
        if (isFence) {
          inFence = !inFence;
        }
        continue;
      }

      result.add(_convertTagsInLine(line));
    }

    return result.join('\n');
  }

  String _convertTagsInLine(String line) {
    final tagRegex = RegExp(
      r'#([^\s\[\]\(\),，、;；:：！!？?\n#]+)',
      unicode: true,
    );
    final linkRanges = RegExp(r'!?\[[^\]]*\]\([^\)]*\)')
        .allMatches(line)
        .map((match) => [match.start, match.end])
        .toList();
    final urlRanges = RegExp(r'[a-zA-Z]+://[^\s\)]*')
        .allMatches(line)
        .map((match) => [match.start, match.end])
        .toList();

    return line.replaceAllMapped(tagRegex, (match) {
      final tag = match.group(1) ?? '';
      if (tag.isEmpty ||
          _hasInvalidTagPrefix(line, match.start) ||
          _isInsideAnyRange(match.start, linkRanges) ||
          _isInsideAnyRange(match.start, urlRanges) ||
          _isInsideCodeSpan(line, match.start)) {
        return match.group(0) ?? '';
      }

      return '[#$tag](#$tag)';
    });
  }

  bool _hasInvalidTagPrefix(String line, int index) {
    if (index == 0) {
      return false;
    }

    final previous = line[index - 1];
    return RegExp(r'[\w:/\[\(]').hasMatch(previous);
  }

  bool _isInsideAnyRange(int index, List<List<int>> ranges) {
    for (final range in ranges) {
      if (index >= range[0] && index < range[1]) {
        return true;
      }
    }
    return false;
  }

  bool _isInsideCodeSpan(String line, int index) {
    var inCodeSpan = false;
    for (var i = 0; i < index; i++) {
      if (line.codeUnitAt(i) == 0x60) {
        inCodeSpan = !inCodeSpan;
      }
    }
    return inCodeSpan;
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
      if (line.contains(RegExp('[a-zA-Z]+://'))) {
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
