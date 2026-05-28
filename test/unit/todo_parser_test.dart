// ============================================================
// 第一档测试 · TodoParser
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/utils/todo_parser.dart';

void main() {
  // ─────────────────────────────────────────────────────────
  // parseTodos
  // ─────────────────────────────────────────────────────────
  group('TodoParser.parseTodos', () {
    test('TD-01 识别未完成项 "- [ ]"', () {
      const content = '- [ ] 买牛奶';
      final todos = TodoParser.parseTodos(content);
      expect(todos.length, 1);
      expect(todos[0].checked, isFalse);
      expect(todos[0].text, '买牛奶');
    });

    test('TD-02 识别已完成项 "- [x]"', () {
      const content = '- [x] 运动半小时';
      final todos = TodoParser.parseTodos(content);
      expect(todos[0].checked, isTrue);
    });

    test('TD-03 大写 X 也视为已完成', () {
      const content = '- [X] 已完成任务';
      final todos = TodoParser.parseTodos(content);
      expect(todos[0].checked, isTrue);
    });

    test('TD-04 多个待办事项按行顺序返回', () {
      const content = '''- [ ] 任务一
- [x] 任务二
- [ ] 任务三''';
      final todos = TodoParser.parseTodos(content);
      expect(todos.length, 3);
      expect(todos[1].checked, isTrue);
      expect(todos[1].text, '任务二');
    });

    test('TD-05 普通文本行不被解析为待办', () {
      const content = '''普通文字
- [ ] 只有这个是待办
另一行普通文字''';
      final todos = TodoParser.parseTodos(content);
      expect(todos.length, 1);
    });

    test('TD-06 带缩进的待办事项也能解析', () {
      const content = '  - [ ] 缩进待办';
      final todos = TodoParser.parseTodos(content);
      expect(todos.length, 1);
      expect(todos[0].text, '缩进待办');
    });

    test('TD-07 空内容返回空列表', () {
      final todos = TodoParser.parseTodos('');
      expect(todos, isEmpty);
    });

    test('TD-08 lineNumber 从 0 开始正确标注', () {
      const content = '''第0行
- [ ] 第1行待办
第2行''';
      final todos = TodoParser.parseTodos(content);
      expect(todos[0].lineNumber, 1);
    });

    test('TD-09 startIndex 和 endIndex 在合理范围内', () {
      const content = '- [ ] 测试位置';
      final todos = TodoParser.parseTodos(content);
      expect(todos[0].startIndex, greaterThanOrEqualTo(0));
      expect(todos[0].endIndex, greaterThan(todos[0].startIndex));
    });
  });

  // ─────────────────────────────────────────────────────────
  // toggleTodoAtLine
  // ─────────────────────────────────────────────────────────
  group('TodoParser.toggleTodoAtLine', () {
    test('TD-10 未完成 → 已完成', () {
      const content = '- [ ] 任务';
      final result = TodoParser.toggleTodoAtLine(content, 0);
      expect(result, '- [x] 任务');
    });

    test('TD-11 已完成 → 未完成', () {
      const content = '- [x] 任务';
      final result = TodoParser.toggleTodoAtLine(content, 0);
      expect(result, '- [ ] 任务');
    });

    test('TD-12 行号越界时返回原始内容', () {
      const content = '- [ ] 任务';
      final result = TodoParser.toggleTodoAtLine(content, 99);
      expect(result, content);
    });

    test('TD-13 切换正确行，其余行不受影响', () {
      const content = '- [ ] 任务一\n- [ ] 任务二';
      final result = TodoParser.toggleTodoAtLine(content, 1);
      final lines = result.split('\n');
      expect(lines[0], '- [ ] 任务一');
      expect(lines[1], '- [x] 任务二');
    });
  });

  // ─────────────────────────────────────────────────────────
  // countTodos
  // ─────────────────────────────────────────────────────────
  group('TodoParser.countTodos', () {
    test('TD-14 统计完成数和待完成数', () {
      const content = '''- [x] 完成了
- [ ] 没完成
- [x] 也完成了''';
      final counts = TodoParser.countTodos(content);
      expect(counts['total'], 3);
      expect(counts['completed'], 2);
      expect(counts['pending'], 1);
    });

    test('TD-15 空内容时全部为 0', () {
      final counts = TodoParser.countTodos('');
      expect(counts['total'], 0);
      expect(counts['completed'], 0);
      expect(counts['pending'], 0);
    });
  });
}
