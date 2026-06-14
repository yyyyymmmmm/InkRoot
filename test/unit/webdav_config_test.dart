import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/models/webdav_config.dart';

void main() {
  group('WebDavConfig.backupImages', () {
    test('默认开启图片附件备份', () {
      const config = WebDavConfig();

      expect(config.backupImages, isTrue);
      expect(config.syncPath, AppConfig.defaultWebDavPath);
    });

    test('JSON 序列化保留 backupImages 开关', () {
      const config = WebDavConfig(
        serverUrl: 'https://dav.example.com',
        username: 'alice',
        password: 'secret',
        backupImages: false,
      );

      final restored = WebDavConfig.fromJson(config.toJson());

      expect(restored.backupImages, isFalse);
      expect(restored.serverUrl, 'https://dav.example.com');
    });

    test('旧配置缺少 backupImages 时按默认开启处理', () {
      final restored = WebDavConfig.fromJson({
        'serverUrl': 'https://dav.example.com',
        'username': 'alice',
        'password': 'secret',
      });

      expect(restored.backupImages, isTrue);
    });

    test('copyWith 可以关闭图片附件备份', () {
      final config = const WebDavConfig().copyWith(backupImages: false);

      expect(config.backupImages, isFalse);
    });

    test('默认要求 HTTPS 或本机/内网 HTTP', () {
      expect(
        const WebDavConfig(serverUrl: 'https://dav.example.com')
            .usesSecureTransport,
        isTrue,
      );
      expect(
        const WebDavConfig(serverUrl: 'http://127.0.0.1:8080')
            .usesSecureTransport,
        isTrue,
      );
      expect(
        const WebDavConfig(serverUrl: 'http://192.168.1.20:5005')
            .usesSecureTransport,
        isTrue,
      );
      expect(
        const WebDavConfig(serverUrl: 'http://dav.example.com')
            .usesSecureTransport,
        isFalse,
      );
    });
  });
}
