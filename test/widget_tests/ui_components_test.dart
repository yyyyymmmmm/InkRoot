// ============================================================
// 第三档测试 · 通用 UI 组件与交互
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/utils/todo_parser.dart';
import 'package:inkroot/widgets/heatmap.dart';
import 'package:intl/intl.dart' as intl;

// ─── 辅助 Widget：笔记标签列表 ───────────────────────────────────────────────

class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Text('无标签', key: Key('noTagsHint'));
    }
    return Wrap(
      spacing: 4,
      children: tags
          .map(
            (t) => Chip(
              key: Key('tag_$t'),
              label: Text('#$t'),
            ),
          )
          .toList(),
    );
  }
}

// ─── 辅助 Widget：待办进度条 ─────────────────────────────────────────────────

class _TodoProgressBar extends StatelessWidget {
  const _TodoProgressBar({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final counts = TodoParser.countTodos(content);
    final total = counts['total']!;
    final completed = counts['completed']!;
    final progress = total == 0 ? 0.0 : completed / total;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          key: const Key('progressBar'),
          value: progress,
        ),
        Text(
          '$completed / $total',
          key: const Key('progressText'),
        ),
      ],
    );
  }
}

// ─── 辅助 Widget：可见性徽章 ─────────────────────────────────────────────────

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.visibility});
  final String visibility;

  @override
  Widget build(BuildContext context) {
    final label = switch (visibility) {
      'PUBLIC' => '公开',
      'PROTECTED' => '受保护',
      _ => '私密',
    };
    final color = switch (visibility) {
      'PUBLIC' => Colors.green,
      'PROTECTED' => Colors.orange,
      _ => Colors.grey,
    };
    return Chip(
      key: Key('badge_$visibility'),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
    );
  }
}

// ─── 辅助 Widget：搜索框 ─────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) => TextField(
        key: const Key('searchField'),
        controller: _ctrl,
        decoration: const InputDecoration(
          hintText: '搜索笔记...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: widget.onSearch,
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
    );

void main() {
  // ─────────────────────────────────────────────────────────
  // 标签组件
  // ─────────────────────────────────────────────────────────
  group('_TagChips — 标签展示', () {
    testWidgets('UI-01 无标签时显示 "无标签" 提示', (tester) async {
      await tester.pumpWidget(_wrap(const _TagChips(tags: [])));
      expect(find.byKey(const Key('noTagsHint')), findsOneWidget);
    });

    testWidgets('UI-02 有标签时每个标签渲染为 Chip', (tester) async {
      await tester.pumpWidget(
        _wrap(const _TagChips(tags: ['Flutter', 'Dart'])),
      );
      expect(find.byKey(const Key('tag_Flutter')), findsOneWidget);
      expect(find.byKey(const Key('tag_Dart')), findsOneWidget);
    });

    testWidgets('UI-03 标签文本包含 # 前缀', (tester) async {
      await tester.pumpWidget(
        _wrap(const _TagChips(tags: ['测试'])),
      );
      expect(find.text('#测试'), findsOneWidget);
    });

    testWidgets('UI-04 多标签全部渲染无崩溃', (tester) async {
      final tags = List.generate(10, (i) => 'tag$i');
      await tester.pumpWidget(_wrap(_TagChips(tags: tags)));
      expect(find.byType(Chip), findsNWidgets(10));
    });
  });

  // ─────────────────────────────────────────────────────────
  // 待办进度条
  // ─────────────────────────────────────────────────────────
  group('_TodoProgressBar — 进度展示', () {
    testWidgets('UI-05 无待办时进度为 0', (tester) async {
      await tester.pumpWidget(
        _wrap(const _TodoProgressBar(content: '没有待办事项')),
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('progressBar')),
      );
      expect(bar.value, 0.0);
    });

    testWidgets('UI-06 全部完成时进度为 1.0', (tester) async {
      await tester.pumpWidget(
        _wrap(const _TodoProgressBar(content: '- [x] 任务一\n- [x] 任务二')),
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('progressBar')),
      );
      expect(bar.value, 1.0);
    });

    testWidgets('UI-07 部分完成时进度居中', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const _TodoProgressBar(content: '- [x] 任务一\n- [ ] 任务二'),
        ),
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('progressBar')),
      );
      expect(bar.value, 0.5);
    });

    testWidgets('UI-08 进度文本格式 "X / Y"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const _TodoProgressBar(content: '- [x] 完成\n- [ ] 未完成\n- [ ] 未完成'),
        ),
      );
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 可见性徽章
  // ─────────────────────────────────────────────────────────
  group('_VisibilityBadge — 可见性展示', () {
    testWidgets('UI-09 PRIVATE 显示 "私密"', (tester) async {
      await tester.pumpWidget(
        _wrap(const _VisibilityBadge(visibility: 'PRIVATE')),
      );
      expect(find.text('私密'), findsOneWidget);
    });

    testWidgets('UI-10 PUBLIC 显示 "公开"', (tester) async {
      await tester.pumpWidget(
        _wrap(const _VisibilityBadge(visibility: 'PUBLIC')),
      );
      expect(find.text('公开'), findsOneWidget);
    });

    testWidgets('UI-11 PROTECTED 显示 "受保护"', (tester) async {
      await tester.pumpWidget(
        _wrap(const _VisibilityBadge(visibility: 'PROTECTED')),
      );
      expect(find.text('受保护'), findsOneWidget);
    });

    testWidgets('UI-12 未知可见性默认显示 "私密"', (tester) async {
      await tester.pumpWidget(
        _wrap(const _VisibilityBadge(visibility: 'UNKNOWN')),
      );
      expect(find.text('私密'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 搜索框
  // ─────────────────────────────────────────────────────────
  group('_SearchBar — 搜索交互', () {
    testWidgets('UI-13 搜索框显示提示语', (tester) async {
      await tester.pumpWidget(_wrap(_SearchBar(onSearch: (_) {})));
      expect(find.text('搜索笔记...'), findsOneWidget);
    });

    testWidgets('UI-14 输入文字触发 onSearch 回调', (tester) async {
      String? received;
      await tester.pumpWidget(
        _wrap(_SearchBar(onSearch: (v) => received = v)),
      );
      await tester.enterText(find.byKey(const Key('searchField')), 'Flutter');
      expect(received, 'Flutter');
    });

    testWidgets('UI-15 搜索框显示搜索图标', (tester) async {
      await tester.pumpWidget(_wrap(_SearchBar(onSearch: (_) {})));
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────
  // 综合场景
  // ─────────────────────────────────────────────────────────
  group('综合场景', () {
    testWidgets('UI-16 带待办的笔记同时展示进度和标签', (tester) async {
      const content = '#Flutter 笔记\n- [x] 任务A\n- [ ] 任务B';
      const tags = ['Flutter'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _TagChips(tags: tags),
                _TodoProgressBar(content: content),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('tag_Flutter')), findsOneWidget);
      expect(find.byKey(const Key('progressBar')), findsOneWidget);
    });

    testWidgets('UI-17 公开的已归档笔记徽章组合展示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                _VisibilityBadge(visibility: 'PUBLIC'),
                Chip(label: Text('已归档')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('公开'), findsOneWidget);
      expect(find.text('已归档'), findsOneWidget);
    });

    testWidgets('UI-18 深色主题下 Widget 不崩溃', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: _TagChips(tags: ['dark', 'theme']),
          ),
        ),
      );
      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('UI-19 RTL 布局不崩溃', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: _TagChips(tags: ['rtl', 'test']),
            ),
          ),
        ),
      );
      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('UI-20 大量标签渲染不溢出', (tester) async {
      final tags = List.generate(20, (i) => 'tag$i');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _TagChips(tags: tags),
            ),
          ),
        ),
      );
      // 测试不崩溃
      expect(find.byType(_TagChips), findsOneWidget);
    });

    testWidgets('UI-21 热力图只按创建日统计，不被更新时间污染', (tester) async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final notes = [
        Note(
          id: 'heatmap-1',
          content: '昨天创建今天更新',
          createdAt: DateTime(yesterday.year, yesterday.month, yesterday.day),
          updatedAt: today,
          tags: const ['old'],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: Heatmap(notes: notes),
          ),
        ),
      );

      final todayLabel = intl.DateFormat('MMM dd, yyyy', 'en_US').format(today);
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Tooltip || widget.message == null) {
            return false;
          }
          return widget.message!.contains(todayLabel) &&
              widget.message!.contains('0 条笔记');
        }),
        findsOneWidget,
      );
    });
  });
}
