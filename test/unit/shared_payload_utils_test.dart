import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/utils/shared_payload_utils.dart';

void main() {
  group('sharedPayloadToContent', () {
    test('keeps shared text content unchanged', () {
      expect(
        sharedPayloadToContent({
          'type': 'text',
          'content': '摘录内容\nhttps://inkroot.cn',
        }),
        '摘录内容\nhttps://inkroot.cn',
      );
    });

    test('turns one shared image into markdown image content', () {
      expect(
        sharedPayloadToContent({
          'type': 'image',
          'path': '/tmp/shared.jpg',
        }),
        contains('![图片](file:///tmp/shared.jpg)'),
      );
    });

    test('turns multiple shared images into markdown image content', () {
      final content = sharedPayloadToContent({
        'type': 'images',
        'paths': ['/tmp/a.jpg', '/tmp/b.png'],
      });

      expect(content, contains('2张'));
      expect(content, contains('file:///tmp/a.jpg'));
      expect(content, contains('file:///tmp/b.png'));
    });

    test('tolerates non-string path values from platform channels', () {
      final content = sharedPayloadToContent({
        'type': 'images',
        'paths': ['/tmp/a.jpg', 42, null],
      });

      expect(content, contains('file:///tmp/a.jpg'));
      expect(content, contains('file://42'));
    });

    test('turns shared file into readable file placeholder', () {
      final content = sharedPayloadToContent({
        'type': 'file',
        'path': '/tmp/report.pdf',
      });

      expect(content, contains('report.pdf'));
      expect(content, contains('/tmp/report.pdf'));
    });

    test('returns null for empty or unsupported payload', () {
      expect(sharedPayloadToContent({'type': 'image'}), isNull);
      expect(sharedPayloadToContent({'type': 'images', 'paths': []}), isNull);
      expect(sharedPayloadToContent({'type': 'unknown'}), isNull);
      expect(sharedPayloadToContent(null), isNull);
    });
  });
}
