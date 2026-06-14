import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/memos_resource_service.dart';

void main() {
  group('MemosResourceService.buildResourcePath', () {
    test('优先使用 externalLink', () {
      expect(
        MemosResourceService.buildResourcePath({
          'externalLink': 'https://cdn.example.com/a.png',
          'uid': 'abc',
        }),
        'https://cdn.example.com/a.png',
      );
    });

    test('支持 legacy resource uid', () {
      expect(
        MemosResourceService.buildResourcePath({'uid': 'resource-uid'}),
        '/o/r/resource-uid',
      );
    });

    test('支持新版 attachment name', () {
      expect(
        MemosResourceService.buildResourcePath({
          'name': 'attachments/123',
          'filename': 'photo.png',
        }),
        '/file/attachments/123/photo.png',
      );
    });

    test('新版 attachment 缺少 filename 时降级为 legacy 资源路径', () {
      expect(
        MemosResourceService.buildResourcePath({'name': 'attachments/123'}),
        '/o/r/123',
      );
    });
  });

  group('MemosResourceService.buildImageUrl', () {
    test('支持 attachment 相对路径', () {
      final service = MemosResourceService(
        baseUrl: 'https://memos.example.com',
        token: 'tok',
        serverVersion: 27,
      );

      expect(
        service.buildImageUrl('attachments/123/photo.png'),
        'https://memos.example.com/file/attachments/123/photo.png',
      );
    });

    test('支持新版 /file/attachment 路径', () {
      final service = MemosResourceService(
        baseUrl: 'https://memos.example.com',
        token: 'tok',
        serverVersion: 27,
      );

      expect(
        service.buildImageUrl('/file/attachments/123/photo.png'),
        'https://memos.example.com/file/attachments/123/photo.png',
      );
    });
  });
}
