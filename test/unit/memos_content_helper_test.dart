import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/utils/memos_content_helper.dart';

void main() {
  group('MemosContentHelper', () {
    test('removes markdown images from preview text', () {
      const content = '正文\n![cover](https://example.com/a.png)\n结尾';

      expect(
        MemosContentHelper.removeMarkdownImages(content),
        '正文\n\n结尾',
      );
    });

    test('keeps user whitespace while removing markdown images', () {
      const content = '\n  正文\n\n![cover](https://example.com/a.png)\n  结尾  \n';

      expect(
        MemosContentHelper.removeMarkdownImages(content),
        '\n  正文\n\n\n  结尾  \n',
      );
    });

    test('preview visible text ignores markdown image and link destination',
        () {
      final longUrl = 'https://example.com/${List.filled(120, 'a').join()}';
      const content = '''
一个苹果端TG的第三方软件，TF测试名额获取
https://testflight.apple.com/join/e1v9O7jC
[Message link](__LONG_URL__)
![cover](https://example.com/a.png)
''';

      expect(
        MemosContentHelper.previewVisibleText(
          content.replaceFirst('__LONG_URL__', longUrl),
        ),
        [
          '一个苹果端TG的第三方软件，TF测试名额获取',
          'https://testflight.apple.com/join/e1v9O7jC',
          'Message link',
        ].join('\n'),
      );
    });

    test('expansion preview ignores trailing metadata tag lines', () {
      const content = '''
> 成长的代价就是失去原有的样子，不管你现在混成什么样子，都要觉得自己前途无量，没人扶的时候，自己要站稳，路是走出来的，越低谷的时候越要撑起自己，要赢得起，也要输得起，一直在学走路，总有一天会站起来，成长会把你们带动下一个旅程。

#微信读书 #权力巅峰 1+2全本 苹果导入番茄看（1）
''';

      expect(
        MemosContentHelper.previewTextForExpansion(content),
        '成长的代价就是失去原有的样子，不管你现在混成什么样子，都要觉得自己前途无量，没人扶的时候，自己要站稳，路是走出来的，越低谷的时候越要撑起自己，要赢得起，也要输得起，一直在学走路，总有一天会站起来，成长会把你们带动下一个旅程。',
      );
    });

    test('extracts note images from resources and markdown without duplicates',
        () {
      final note = Note(
        id: '1',
        content: '正文\n![cover](/o/r/res-1)\n![local](file:///tmp/a.png)',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        resourceList: [
          {'uid': 'res-1', 'type': 'image/png', 'filename': 'a.png'},
          {'uid': 'video-1', 'type': 'video/mp4', 'filename': 'a.mp4'},
        ],
      );

      expect(
        MemosContentHelper.extractNoteImagePaths(note),
        ['/o/r/res-1', 'file:///tmp/a.png'],
      );
    });

    test('appends resource images when content has no markdown images', () {
      final note = Note(
        id: '1',
        content: '只有正文',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        resourceList: [
          {'uid': 'res-1', 'type': 'image/png', 'filename': 'a.png'},
        ],
      );

      expect(
        MemosContentHelper.contentWithResourceImages(note),
        '只有正文\n\n![](/o/r/res-1)',
      );
    });

    test('appends only missing resource images when content already has images',
        () {
      final note = Note(
        id: '1',
        content: '正文\n![](/o/r/res-1)',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        resourceList: [
          {'uid': 'res-1', 'type': 'image/png', 'filename': 'a.png'},
          {'uid': 'res-2', 'type': 'image/png', 'filename': 'b.png'},
        ],
      );

      expect(
        MemosContentHelper.contentWithResourceImages(note),
        '正文\n![](/o/r/res-1)\n\n![](/o/r/res-2)',
      );
    });
  });
}
