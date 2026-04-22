// 待办事项处理模块（从 note_detail_screen.dart 拆分）
// 职责：处理笔记中的待办事项状态切换

import 'package:flutter/foundation.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/utils/todo_parser.dart';

/// 待办事项处理助手类
///
/// 负责：
/// 1. 切换待办事项状态（[ ] ↔ [x]）
/// 2. 更新笔记内容
/// 3. 同步到数据库
class NoteDetailTodoHandler {
  /// 切换笔记中指定索引的待办事项
  ///
  /// 自动识别待办事项格式：
  /// - [ ] 未完成
  /// - [x] 已完成
  static Future<void> toggleTodoInNote({
    required Note note,
    required int todoIndex,
    required AppProvider appProvider,
  }) async {
    try {
      // 解析待办事项
      final todoItems = TodoParser.parseTodos(note.content);
      if (todoIndex < 0 || todoIndex >= todoItems.length) {
        if (kDebugMode) {
          debugPrint('待办事项索引越界: $todoIndex');
        }
        return;
      }

      // 切换状态
      final targetTodo = todoItems[todoIndex];
      final newContent = note.content.replaceFirst(
        targetTodo.isCompleted ? '[x]' : '[ ]',
        targetTodo.isCompleted ? '[ ]' : '[x]',
      );

      // 更新笔记
      await appProvider.updateNote(note, newContent);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('切换待办事项失败: $e');
      }
    }
  }

  /// 获取笔记中的待办事项列表
  static List<TodoItem> getTodoItems(String content) {
    return TodoParser.parseTodos(content);
  }

  /// 计算待办事项完成进度
  ///
  /// 返回 (已完成数, 总数, 百分比)
  static (int completed, int total, double percentage) calculateProgress(String content) {
    final todos = TodoParser.parseTodos(content);
    if (todos.isEmpty) return (0, 0, 0.0);

    final completed = todos.where((t) => t.isCompleted).length;
    final total = todos.length;
    final percentage = (completed / total * 100);

    return (completed, total, percentage);
  }

  /// 检查笔记是否包含待办事项
  static bool hasTodos(String content) {
    return TodoParser.parseTodos(content).isNotEmpty;
  }

  /// 批量切换所有待办事项状态
  static Future<void> toggleAllTodos({
    required Note note,
    required bool completed,
    required AppProvider appProvider,
  }) async {
    try {
      final marker = completed ? '[x]' : '[ ]';
      final newContent = note.content
          .replaceAll('[ ]', marker)
          .replaceAll('[x]', marker);

      await appProvider.updateNote(note, newContent);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('批量切换待办事项失败: $e');
      }
    }
  }
}
