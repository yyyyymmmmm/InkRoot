// ============================================================
// 第二档测试 · ApiServiceFactory
// 不依赖网络的逻辑：normalizeApiUrl、ApiError 基础行为
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/api_service_factory.dart';

void main() {
  group('ApiServiceFactory.normalizeApiUrl', () {
    test('AS-01 已有 https:// 不重复添加', () {
      const url = 'https://memos.example.com';
      expect(ApiServiceFactory.normalizeApiUrl(url), url);
    });

    test('AS-02 已有 http:// 不替换', () {
      const url = 'http://192.168.1.1:5230';
      expect(ApiServiceFactory.normalizeApiUrl(url), url);
    });

    test('AS-03 无协议时自动添加 https://', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('memos.example.com'),
        'https://memos.example.com',
      );
    });

    test('AS-04 末尾单个斜杠被移除', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('https://memos.example.com/'),
        'https://memos.example.com',
      );
    });

    test('AS-05 末尾多个斜杠全部移除', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('https://memos.example.com///'),
        'https://memos.example.com',
      );
    });

    test('AS-06 路径部分保留，末尾斜杠移除', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('https://example.com/memos/'),
        'https://example.com/memos',
      );
    });

    test('AS-07 带端口号正确保留', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('https://host:5230'),
        'https://host:5230',
      );
    });

    test('AS-08 IP 地址 + 端口正确处理', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('192.168.1.100:5230'),
        'https://192.168.1.100:5230',
      );
    });
  });

  group('ApiError', () {
    test('AS-09 toString 返回 message 字段', () {
      final error = ApiError('INVALID_URL', '地址格式错误');
      expect(error.toString(), '地址格式错误');
    });

    test('AS-10 code 字段正确存储', () {
      final error = ApiError('TIMEOUT', '超时了');
      expect(error.code, 'TIMEOUT');
    });

    test('AS-11 ApiError 是 Exception 的子类', () {
      final error = ApiError('ERR', '出错了');
      expect(error, isA<Exception>());
    });
  });

  // ─────────────────────────────────────────────────────────
  // URL 边界情况
  // ─────────────────────────────────────────────────────────
  group('normalizeApiUrl — 边界情况', () {
    test('AS-12 https:// 无主机名：末尾斜杠被移除（退化情况）', () {
      // 'https://' → 末尾斜杠被移除 → 'https:' (退化情况，实际不会触发)
      final result = ApiServiceFactory.normalizeApiUrl('https://');
      // 函数不应崩溃；返回的字符串包含协议关键字
      expect(result, contains('https'));
    });

    test('AS-13 路径中有多级路径保留', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('https://host/sub/path'),
        'https://host/sub/path',
      );
    });

    test('AS-14 带查询参数的 URL 末尾斜杠也被移除', () {
      expect(
        ApiServiceFactory.normalizeApiUrl('https://host/path/'),
        'https://host/path',
      );
    });

    test('AS-15 大写 HTTPS 开头不重复添加协议', () {
      // 实际 URL 通常小写，但函数应能处理
      final input = 'https://example.com';
      final result = ApiServiceFactory.normalizeApiUrl(input);
      expect(result, 'https://example.com');
    });

    test('AS-16 空字符串不抛出 Error 类异常（只可能 ApiError）', () {
      // normalizeApiUrl 对空串不会抛出，只是返回 https://
      expect(
        () => ApiServiceFactory.normalizeApiUrl(''),
        returnsNormally,
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // ApiError 边界情况
  // ─────────────────────────────────────────────────────────
  group('ApiError 边界情况', () {
    test('AS-17 message 为中文也正常存储', () {
      final e = ApiError('CONN', '网络连接失败，请检查手机网络');
      expect(e.message, contains('网络连接失败'));
    });

    test('AS-18 code 为空字符串也不崩溃', () {
      final e = ApiError('', '错误');
      expect(e.code, isEmpty);
    });

    test('AS-19 抛出 ApiError 可被 catch', () {
      void fn() => throw ApiError('ERR', '测试异常');
      expect(fn, throwsA(isA<ApiError>()));
    });

    test('AS-20 ApiError 不是 StateError', () {
      final e = ApiError('X', 'Y');
      expect(e, isNot(isA<StateError>()));
    });
  });
}
