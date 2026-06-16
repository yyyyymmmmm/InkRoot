import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/widgets/memo_editing_controller.dart';

void main() {
  group('MemoEditingController', () {
    test('decodes markdown into visual text and serializes back', () {
      final controller = MemoEditingController(
        markdown: '**GTA5 Mods**\n- [ ] 下载模组\n- 列表项',
      );

      expect(controller.text, contains('GTA5 Mods'));
      expect(controller.text, contains('☐ 下载模组'));
      expect(controller.text, contains('• 列表项'));
      expect(controller.text, isNot(contains('**')));
      expect(controller.text, isNot(contains('- [ ]')));

      expect(
        controller.toMarkdown(),
        '**GTA5 Mods**\n- [ ] 下载模组\n- 列表项',
      );
    });

    test('bold toggle stores style without exposing markdown syntax', () {
      final controller = MemoEditingController(markdown: 'hello world');
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);

      controller.toggleMark(MemoTextMark.bold);

      expect(controller.text, 'hello world');
      expect(controller.text, isNot(contains('**')));
      expect(controller.toMarkdown(), '**hello** world');
    });

    test('underline toggle stores style and renders as Memos compatible html',
        () {
      final controller = MemoEditingController(markdown: 'hello world');
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);

      controller.toggleMark(MemoTextMark.underline);

      expect(controller.text, 'hello world');
      expect(controller.text, isNot(contains('<u>')));
      expect(controller.toMarkdown(), '<u>hello</u> world');
    });

    test('active underline applies to subsequently typed text', () {
      final controller = MemoEditingController();
      controller.selection = const TextSelection.collapsed(offset: 0);

      controller.toggleMark(MemoTextMark.underline);
      controller.insertPlainText('下划线文字');

      expect(controller.text, '下划线文字');
      expect(controller.toMarkdown(), '<u>下划线文字</u>');
    });

    test('keeps user authored leading, trailing, and blank lines', () {
      final controller = MemoEditingController(
        markdown: '\n  第一行\n\n第二行  \n',
      );

      expect(controller.toMarkdown(), '\n  第一行\n\n第二行  \n');
    });

    test('preserves existing heading levels when saving', () {
      final controller = MemoEditingController(
        markdown: '## 二级标题\n### 三级标题',
      );

      expect(controller.text, '二级标题\n三级标题');
      expect(controller.toMarkdown(), '## 二级标题\n### 三级标题');
    });

    test('active bold applies to subsequently typed text', () {
      final controller = MemoEditingController();
      controller.toggleMark(MemoTextMark.bold);
      controller.insertPlainText('加粗');

      expect(controller.text, '加粗');
      expect(controller.toMarkdown(), '**加粗**');
    });

    test('visual todo and list prefixes serialize to Memos markdown', () {
      final controller = MemoEditingController(
        markdown: '☐ 任务\n☑ 完成\n• 列表\n│ 引用',
      );

      expect(
        controller.toMarkdown(),
        '- [ ] 任务\n- [x] 完成\n- 列表\n> 引用',
      );
    });

    test('links keep visual label and save as markdown link', () {
      final controller = MemoEditingController(markdown: '查看');
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 2);

      controller.insertLink('官网', 'https://example.com');

      expect(controller.text, '官网');
      expect(controller.toMarkdown(), '[官网](https://example.com)');
    });
  });
}
