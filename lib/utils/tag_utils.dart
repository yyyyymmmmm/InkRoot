// 标签处理工具类
// 提供统一的标签识别和提取逻辑

/// 获取改进的标签正则表达式
/// 
/// 规则（参考Obsidian/Notion/Logseq）：
/// - 排除URL中的#（不在://之后）
/// - 前缀要求：#前面不能是字母、数字、下划线、冒号、斜杠
/// - 排除连续##（Markdown标题）
/// - 标签内容不包含#
RegExp getTagRegex() {
  return RegExp(
    r'(?<![\w:/])(?!##)#([^\s\[\],，、;；:：！!？?\n#]+)',
    unicode: true,
  );
}

/// 提取内容中的所有标签（排除URL中的#）
List<String> extractTagsFromContent(String content) {
  final tagRegex = getTagRegex();
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

/// 检查标签是否在URL中
bool isTagInUrl(String line, int tagStart, int tagEnd) {
  final urlRegex = RegExp(r'[a-zA-Z]+://[^\s\)]+');
  final urlMatches = urlRegex.allMatches(line);
  
  for (final match in urlMatches) {
    if (tagStart >= match.start && tagEnd <= match.end) {
      return true;
    }
  }
  
  return false;
}

