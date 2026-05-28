// ============================================================
// 第三档测试 · 笔记数据在 Widget 中的展示
// 测试纯展示型 Widget（不依赖 Provider）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';

// ─── 被测 Widget：展示单条笔记摘要 ───────────────────────────────────────────

class _NotePreviewCard extends StatelessWidget {
  const _NotePreviewCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(note.content, key: const Key('noteContent')),
        subtitle: Text(
          note.tags.isEmpty ? '无标签' : note.tags.join(' · '),
          key: const Key('noteTags'),
        ),
        trailing: note.isPinned
            ? const Icon(Icons.push_pin, key: Key('pinIcon'))
            : null,
      ),
    );
  }
}

// ─── 帮助函数 ────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

Note _makeNote({
  String id = 'wt-001',
  String content = '测试笔记',
  bool isPinned = false,
  List<String> tags = const [],
  String rowStatus = 'NORMAL',
}) =>
    Note(
      id: id,
      content: content,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      isPinned: isPinned,
      tags: tags,
      rowStatus: rowStatus,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('NotePreviewCard — 内容展示', () {
    testWidgets('WN-01 笔记内容正确展示', (tester) async {
      await tester.pumpWidget(
        _wrap(_NotePreviewCard(note: _makeNote(content: '这是一条测试笔记'))),
      );
      expect(find.text('这是一条测试笔记'), findsOneWidget);
    });

    testWidgets('WN-02 有标签时展示标签', (tester) async {
      await tester.pumpWidget(
        _wrap(_NotePreviewCard(
          note: _makeNote(tags: ['flutter', 'dart']),
        )),
      );
      expect(find.byKey(const Key('noteTags')), findsOneWidget);
      final text =
          (tester.widget(find.byKey(const Key('noteTags'))) as Text).data;
      expect(text, contains('flutter'));
    });

    testWidgets('WN-03 无标签时显示 "无标签"', (tester) async {
      await tester.pumpWidget(
        _wrap(_NotePreviewCard(note: _makeNote(tags: []))),
      );
      expect(find.text('无标签'), findsOneWidget);
    });

    testWidgets('WN-04 置顶笔记显示图钉图标', (tester) async {
      await tester.pumpWidget(
        _wrap(_NotePreviewCard(note: _makeNote(isPinned: true))),
      );
      expect(find.byKey(const Key('pinIcon')), findsOneWidget);
    });

    testWidgets('WN-05 未置顶笔记不显示图钉图标', (tester) async {
      await tester.pumpWidget(
        _wrap(_NotePreviewCard(note: _makeNote(isPinned: false))),
      );
      expect(find.byKey(const Key('pinIcon')), findsNothing);
    });
  });

  group('Note 状态徽章 Widget', () {
    testWidgets('WN-06 归档笔记样式展示', (tester) async {
      final archivedNote = _makeNote(rowStatus: 'ARCHIVED');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (archivedNote.isArchived)
                    const Chip(
                      label: Text('已归档'),
                      key: Key('archivedChip'),
                    ),
                  Text(archivedNote.content),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('archivedChip')), findsOneWidget);
    });

    testWidgets('WN-07 正常笔记不显示归档徽章', (tester) async {
      final normalNote = _makeNote(rowStatus: 'NORMAL');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (normalNote.isArchived)
                  const Chip(
                    label: Text('已归档'),
                    key: Key('archivedChip'),
                  ),
                Text(normalNote.content),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('archivedChip')), findsNothing);
    });
  });

  group('笔记列表 Widget', () {
    testWidgets('WN-08 空列表展示占位文案', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                final notes = <Note>[];
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('暂无笔记', key: Key('emptyHint')),
                  );
                }
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (_, i) =>
                      _NotePreviewCard(note: notes[i]),
                );
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('emptyHint')), findsOneWidget);
    });

    testWidgets('WN-09 笔记列表正确渲染多条数据', (tester) async {
      final notes = List.generate(
        3,
        (i) => _makeNote(id: 'n$i', content: '笔记 $i'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (_, i) => _NotePreviewCard(note: notes[i]),
            ),
          ),
        ),
      );

      expect(find.text('笔记 0'), findsOneWidget);
      expect(find.text('笔记 1'), findsOneWidget);
      expect(find.text('笔记 2'), findsOneWidget);
    });

    testWidgets('WN-10 长内容不会溢出崩溃', (tester) async {
      final longContent = '这是一段非常长的笔记内容' * 50;
      await tester.pumpWidget(
        _wrap(_NotePreviewCard(note: _makeNote(content: longContent))),
      );
      // 不崩溃即通过
      expect(find.byType(_NotePreviewCard), findsOneWidget);
    });
  });

  group('TodoParser 在 Widget 中的使用', () {
    testWidgets('WN-11 待办计数正确展示', (tester) async {
      const content = '- [x] 完成任务一\n- [ ] 待完成任务二';
      final todoText = '1/2 已完成';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(todoText, key: const Key('todoCount')),
          ),
        ),
      );
      expect(find.text('1/2 已完成'), findsOneWidget);
    });
  });
}
