// 待办事项解析和处理工具类

import 'package:flutter/foundation.dart';

/// 待办事项信息
class TodoItem {
  TodoItem({
    required this.checked,
    required this.text,
    required this.startIndex,
    required this.endIndex,
    required this.lineNumber,
  });
  final bool checked;
  final String text;
  final int startIndex; // 在原文中的起始位置
  final int endIndex; // 在原文中的结束位置
  final int lineNumber; // 行号（从0开始）

  @override
  String toString() =>
      'TodoItem(checked: $checked, text: "$text", line: $lineNumber)';
}

/// 待办事项解析器
class TodoParser {
  /// 从内容中提取所有待办事项
  static List<TodoItem> parseTodos(String content) {
    final todos = <TodoItem>[];
    final lines = content.split('\n');

    var currentIndex = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineStartIndex = currentIndex;
      currentIndex += line.length + 1; // +1 for newline

      // 匹配待办事项：- [ ] 或 - [x] 或 - [X]
      final todoRegex = RegExp(r'^(\s*)-\s+\[([ xX])\]\s+(.+)$');
      final match = todoRegex.firstMatch(line);

      if (match != null) {
        final indent = match.group(1)!;
        final checkStatus = match.group(2)!;
        final text = match.group(3)!;
        final checked = checkStatus.toLowerCase() == 'x';

        final checkboxStartIndex =
            lineStartIndex + indent.length; // "- [ ] " 的起始位置
        final checkboxEndIndex = currentIndex - 1;

        todos.add(
          TodoItem(
            checked: checked,
            text: text,
            startIndex: checkboxStartIndex,
            endIndex: checkboxEndIndex,
            lineNumber: i,
          ),
        );
      }
    }

    return todos;
  }

  /// 切换指定行的待办事项状态
  static String toggleTodoAtLine(String content, int lineNumber) {
    final lines = content.split('\n');
    if (lineNumber < 0 || lineNumber >= lines.length) {
      if (kDebugMode) {
        debugPrint('TodoParser: 行号越界 $lineNumber');
      }
      return content;
    }

    final line = lines[lineNumber];
    final todoRegex = RegExp(r'^(\s*-\s+)\[([ xX])\](\s+.+)$');
    final match = todoRegex.firstMatch(line);

    if (match != null) {
      final prefix = match.group(1)!; // "- "
      final checkStatus = match.group(2)!;
      final suffix = match.group(3)!; // " text"

      // 切换状态
      final newStatus = checkStatus.trim().isEmpty ? 'x' : ' ';
      lines[lineNumber] = '$prefix[$newStatus]$suffix';

      if (kDebugMode) {
        debugPrint(
          'TodoParser: 切换待办事项 $lineNumber: "${checkStatus.isEmpty ? "未完成" : "已完成"}" -> "${newStatus == "x" ? "已完成" : "未完成"}"',
        );
      }
    }

    return lines.join('\n');
  }

  /// 切换指定位置的待办事项状态（通过startIndex查找）
  static String toggleTodoAtIndex(String content, int startIndex) {
    // 找到这个index对应的行号
    var currentIndex = 0;
    var lineNumber = 0;
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final lineStartIndex = currentIndex;
      final lineEndIndex = currentIndex + lines[i].length;

      if (startIndex >= lineStartIndex && startIndex <= lineEndIndex) {
        lineNumber = i;
        break;
      }

      currentIndex = lineEndIndex + 1; // +1 for newline
    }

    return toggleTodoAtLine(content, lineNumber);
  }

  /// 统计待办事项
  static Map<String, int> countTodos(String content) {
    final todos = parseTodos(content);
    final completed = todos.where((t) => t.checked).length;
    final total = todos.length;

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }
}

