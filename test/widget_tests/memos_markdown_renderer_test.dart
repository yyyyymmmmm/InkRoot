import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/widgets/memos_markdown_renderer.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );

void main() {
  group('MemosMarkdownRenderer', () {
    testWidgets('renders common Memos markdown without exposing controls',
        (tester) async {
      const content = '''
# 标题
#游戏 #GTA
**GTA5 Mods **
<u>下划线</u>
- [x] 已完成
[[missing-note]]
''';

      await tester.pumpWidget(
        _wrap(
          const MemosMarkdownRenderer(
            content: content,
            selectable: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderedText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText())
          .join('\n');

      expect(renderedText, contains('GTA5 Mods'));
      expect(renderedText, contains('下划线'));
      expect(renderedText, isNot(contains('**')));
      expect(renderedText, isNot(contains('<u>')));
      expect(renderedText, isNot(contains('- [x]')));
      expect(renderedText, isNot(contains('[[missing-note]]')));
      expect(renderedText, contains('#游戏'));
      expect(renderedText, contains('#GTA'));
      expect(renderedText, contains('(已删除的笔记)'));

      final underlineSpan = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text)
          .expand(_flattenSpans)
          .where((span) => span.toPlainText() == '下划线')
          .single;
      expect(underlineSpan.style?.decoration, TextDecoration.underline);
    });

    testWidgets('renders bare urls as readable links without shrinking text',
        (tester) async {
      const content = '''
模型地址：claude-sonnet-4-6
网站
https://gpt-agent.cc/v1
#AI
''';

      await tester.pumpWidget(
        _wrap(
          const MemosMarkdownRenderer(
            content: content,
            selectable: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderedText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText())
          .join('\n');

      expect(renderedText, contains('https://gpt-agent.cc/v1'));
      expect(renderedText, contains('#AI'));

      final linkSpan = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text)
          .expand(_flattenSpans)
          .where((span) => span.toPlainText() == 'https://gpt-agent.cc/v1')
          .single;
      expect(linkSpan.style?.fontSize, isNot(13));
      expect(linkSpan.style?.height, isNot(1.0));
    });

    testWidgets('keeps a line break before a bare url link', (tester) async {
      const content = '模型地址：claude-sonnet-4-6\n网站 https://gpt-agent.cc/v1';

      await tester.pumpWidget(
        _wrap(
          const MemosMarkdownRenderer(
            content: content,
            selectable: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderedText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText())
          .join('\n');

      expect(
        renderedText,
        contains('模型地址：claude-sonnet-4-6\n网站 https://gpt-agent.cc/v1'),
      );
    });

    testWidgets(
      'search rendering keeps full note structure around checkbox matches',
      (tester) async {
        const content = '''
1.同步到webdav能否同步图片？或者增加一个选项让用户选择？
- [x] 2.首页现在长按是没有功能的，能否可以考虑直接长按复制？
3.同步到memos后，再同步到思源笔记，通过inkroot发布的图片不显示
''';

        await tester.pumpWidget(
          _wrap(
            const MemosMarkdownRenderer(
              content: content,
              selectable: false,
              highlightQuery: '知道',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final renderedText = tester
            .widgetList<RichText>(find.byType(RichText))
            .map((widget) => widget.text.toPlainText())
            .join('\n');

        expect(renderedText, contains('同步到webdav能否同步图片'));
        expect(renderedText, contains('首页现在长按是没有功能的'));
        expect(renderedText, contains('同步到memos后'));
      },
    );

    testWidgets('homepage preview keeps underline-only note visible',
        (tester) async {
      const content = '<u>主页应该显示这段下划线文字</u>';

      await tester.pumpWidget(
        _wrap(
          const MemosMarkdownRenderer(
            content: content,
            selectable: false,
            mode: MemosMarkdownMode.cardPreview,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderedText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText())
          .join('\n');

      expect(renderedText, contains('主页应该显示这段下划线文字'));
      expect(renderedText, isNot(contains('<u>')));
    });
  });
}

Iterable<TextSpan> _flattenSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _flattenSpans(child);
    }
  }
}
