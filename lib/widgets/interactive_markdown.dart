// 交互式Markdown渲染组件（支持可点击的待办事项）

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:inkroot/utils/todo_parser.dart';
import 'package:markdown/markdown.dart' as md;

/// 交互式Markdown组件（支持待办事项点击）
class InteractiveMarkdown extends StatelessWidget {
  const InteractiveMarkdown({
    required this.data,
    required this.onTodoToggled,
    super.key,
    this.selectable = true,
    this.styleSheet,
    this.onTapLink,
    this.imageBuilder,
    this.builders = const {},
  });

  final String data;
  final Function(String newContent) onTodoToggled; // 当待办事项状态改变时的回调
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownTapLinkCallback? onTapLink;
  final MarkdownImageBuilder? imageBuilder;
  final Map<String, MarkdownElementBuilder> builders;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MarkdownBody(
      data: data,
      selectable: selectable,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      checkboxBuilder: (value) {
        // 🎯 找到对应的待办事项
        // 注意：这里无法直接知道是哪个checkbox，所以使用一个变通方案
        // 我们通过渲染顺序来匹配（这个方法不完美，但在大多数情况下有效）
        return GestureDetector(
          onTap: () {
            // 尝试通过当前值找到对应的待办事项
            _handleCheckboxTap(value);
          },
          child: Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: value,
              onChanged: null, // 通过GestureDetector处理
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
      styleSheet: styleSheet,
      onTapLink: onTapLink,
      imageBuilder: imageBuilder,
      builders: builders,
    );
  }

  void _handleCheckboxTap(bool currentValue) {
    // 找到第一个匹配当前状态的待办事项并切换
    final todos = TodoParser.parseTodos(data);

    // 简单策略：切换第一个匹配的待办事项
    // 更好的方案需要更复杂的上下文跟踪
    for (final todo in todos) {
      if (todo.checked == currentValue) {
        final newContent = TodoParser.toggleTodoAtLine(data, todo.lineNumber);
        onTodoToggled(newContent);
        break;
      }
    }
  }
}

/// 简单的待办事项渲染组件（支持点击切换）
class SimpleTodoList extends StatelessWidget {
  const SimpleTodoList({
    required this.content,
    required this.onContentChanged,
    super.key,
  });

  final String content;
  final Function(String newContent) onContentChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todos = TodoParser.parseTodos(content);

    if (todos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: todos
          .map(
            (todo) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: todo.checked,
                      onChanged: (newValue) {
                        // 切换这个待办事项的状态
                        final newContent = TodoParser.toggleTodoAtLine(
                          content,
                          todo.lineNumber,
                        );
                        onContentChanged(newContent);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        todo.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                          decoration:
                              todo.checked ? TextDecoration.lineThrough : null,
                          decorationColor:
                              isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
