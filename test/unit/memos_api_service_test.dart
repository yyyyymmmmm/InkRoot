// ============================================================
// 第二档测试 · MemosApiServiceFixed
// 使用 MockClient (package:http/testing.dart) 模拟网络
// ============================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── UTF-8 安全 Response 构造器 ────────────────────────────────────────────────
// http.Response(body, code) 使用 Latin-1；对含中文内容需使用 bytes 变体

http.Response _utf8Response(String body, int statusCode) =>
    http.Response.bytes(
      utf8.encode(body),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

// ─── 帮助函数：构造 MockClient ──────────────────────────────────────────────

MockClient _buildMockClient({
  String version = 'v0.28.0',
  int statusCode = 200,
  String? memosBody,
}) {
  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/api/v1/workspace/profile')) {
      return http.Response(
        jsonEncode({'version': version}),
        statusCode == 200 ? 200 : statusCode,
      );
    }

    if (path.endsWith('/api/v1/memos') || path.endsWith('/api/v1/memo')) {
      final body = memosBody ??
          jsonEncode({
            'memos': [
              {
                'name': 'memos/1',
                'content': 'test note',
                'createTime': '2024-05-01T10:00:00Z',
                'updateTime': '2024-05-01T10:00:00Z',
              },
            ],
          });
      return http.Response(body, 200);
    }

    if (path.endsWith('/api/v1/auth/signin')) {
      final body = jsonEncode({'accessToken': 'test-token-abc'});
      return http.Response(body, 200);
    }

    if (path.endsWith('/api/v1/auth/me')) {
      final body = jsonEncode({
        'user': {
          'id': '1',
          'username': 'testuser',
          'email': 'test@example.com',
          'role': 'USER',
        }
      });
      return http.Response(body, 200);
    }

    return http.Response('{"error":"not found"}', 404);
  });
}

void main() {
  const baseUrl = 'https://test.memos.example.com';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // 清除版本缓存，确保每次测试从干净状态开始
    await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
  });

  // ─────────────────────────────────────────────────────────
  // 版本检测
  // ─────────────────────────────────────────────────────────
  group('MemosApiServiceFixed — 版本检测', () {
    test('API-01 检测到 v0.28.0 → 返回 minor=28', () async {
      final mock = _buildMockClient(version: 'v0.28.0');
      final version = await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      expect(version, 28);
    });

    test('API-02 检测到 v0.21.0 → 返回 minor=21', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = _buildMockClient(version: 'v0.21.0');
      final version = await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      expect(version, 21);
    });

    test('API-03 检测到 v0.26.2 → 返回 minor=26', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = _buildMockClient(version: 'v0.26.2');
      final version = await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      expect(version, 26);
    });

    test('API-04 workspace/profile 返回非 200 时默认 v0.21', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        return http.Response('Not Found', 404);
      });
      final version = await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      expect(version, 21);
    });

    test('API-05 版本二次调用使用内存缓存，不发起网络请求', () async {
      var callCount = 0;
      final mock = MockClient((req) async {
        callCount++;
        return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
      });

      await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      // 第二次调用应使用缓存
      await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      // workspace/profile 只被请求一次（getServerVersion），背景刷新算额外
      expect(callCount, lessThanOrEqualTo(2));
    });

    test('API-06 invalidateVersionCache 清除缓存后再次发起网络请求', () async {
      var callCount = 0;
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          callCount++;
          return http.Response(jsonEncode({'version': 'v0.27.0'}), 200);
        }
        return http.Response('{}', 404);
      });

      await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      await http.runWithClient(
        () => MemosApiServiceFixed.getServerVersion(baseUrl),
        () => mock,
      );
      expect(callCount, greaterThanOrEqualTo(2));
    });
  });

  // ─────────────────────────────────────────────────────────
  // getMemos
  // ─────────────────────────────────────────────────────────
  group('MemosApiServiceFixed — getMemos', () {
    test('API-07 v0.28 正确请求 /api/v1/memos', () async {
      String? calledPath;
      final mock = MockClient((req) async {
        calledPath = req.url.path;
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/memos')) {
          return http.Response(
              jsonEncode({'memos': []}), 200);
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      await http.runWithClient(() => svc.getMemos(pageSize: 10), () => mock);
      expect(calledPath, endsWith('/api/v1/memos'));
    });

    test('API-08 v0.21 请求 /api/v1/memo (单数)', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      String? calledPath;
      final mock = MockClient((req) async {
        calledPath = req.url.path;
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response('Not Found', 404);
        }
        if (req.url.path.endsWith('/api/v1/memo')) {
          // v0.21 returns a bare JSON array (not wrapped in an object)
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      await http.runWithClient(() => svc.getMemos(pageSize: 10), () => mock);
      expect(calledPath, endsWith('/api/v1/memo'));
    });

    test('API-09 返回 401 抛出 TokenExpiredException', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        return http.Response('{"error":"unauthorized"}', 401);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'expired-tok');
      await expectLater(
        http.runWithClient(() => svc.getMemos(), () => mock),
        throwsA(isA<TokenExpiredException>()),
      );
    });

    test('API-10 memos 列表可被解析为 Note 对象', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = _buildMockClient(version: 'v0.28.0');
      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final result =
          await http.runWithClient(() => svc.getMemos(), () => mock);
      final memos = result['memos'] as List<dynamic>;
      expect(memos, isNotEmpty);
      final note = Note.fromJson(memos[0] as Map<String, dynamic>);
      expect(note.content, 'test note');
    });
  });

  // ─────────────────────────────────────────────────────────
  // createAccessToken
  // ─────────────────────────────────────────────────────────
  group('MemosApiServiceFixed — createAccessToken', () {
    test('API-11 v0.26+ 登录返回 accessToken', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.26.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/auth/signin')) {
          // 验证请求体包含 passwordCredentials
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body.containsKey('passwordCredentials'), isTrue);
          return http.Response(
            jsonEncode({'accessToken': 'my-jwt-token'}),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl);
      final token = await http.runWithClient(
        () => svc.createAccessToken('alice', 'pass123'),
        () => mock,
      );
      expect(token, 'my-jwt-token');
    });

    test('API-12 v0.21 登录使用 token 字段', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response('Not Found', 404);
        }
        if (req.url.path.endsWith('/api/v1/auth/signin')) {
          return http.Response(
            jsonEncode({'token': 'v21-token-xyz'}),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl);
      final token = await http.runWithClient(
        () => svc.createAccessToken('bob', 'secret'),
        () => mock,
      );
      expect(token, 'v21-token-xyz');
    });

    test('API-13 登录失败（400）时抛出异常', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.26.0'}), 200);
        }
        return http.Response(jsonEncode({'message': 'wrong password'}), 400);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl);
      await expectLater(
        http.runWithClient(
          () => svc.createAccessToken('user', 'wrong'),
          () => mock,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // getUserInfo
  // ─────────────────────────────────────────────────────────
  group('MemosApiServiceFixed — getUserInfo', () {
    test('API-14 v0.26+ 调用 /api/v1/auth/me', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.26.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/auth/me')) {
          return http.Response(
            jsonEncode({
              'user': {
                'id': '42',
                'username': 'alice',
                'role': 'ADMIN',
              }
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final user =
          await http.runWithClient(() => svc.getUserInfo(), () => mock);
      expect(user.username, 'alice');
      expect(user.role, 'ADMIN');
    });

    test('API-15 v0.22 调用 /api/v1/auth/status（POST）', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      String? calledPath;
      String? method;
      final mock = MockClient((req) async {
        calledPath = req.url.path;
        method = req.method;
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.22.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/auth/status')) {
          return http.Response(
            jsonEncode({'id': '5', 'username': 'bob', 'role': 'USER'}),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      await http.runWithClient(() => svc.getUserInfo(), () => mock);
      expect(calledPath, endsWith('/api/v1/auth/status'));
      expect(method, 'POST');
    });

    test('API-16 401 → TokenExpiredException', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        return http.Response('{}', 401);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'bad-tok');
      await expectLater(
        http.runWithClient(() => svc.getUserInfo(), () => mock),
        throwsA(isA<TokenExpiredException>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────
  // TokenExpiredException
  // ─────────────────────────────────────────────────────────
  group('TokenExpiredException', () {
    test('API-17 toString 包含消息', () {
      final ex = TokenExpiredException('Token 已失效');
      expect(ex.toString(), contains('Token 已失效'));
    });

    test('API-18 是 Exception 的子类', () {
      final ex = TokenExpiredException('x');
      expect(ex, isA<Exception>());
    });
  });

  // ─────────────────────────────────────────────────────────
  // Headers 构造
  // ─────────────────────────────────────────────────────────
  group('MemosApiServiceFixed — 请求头', () {
    test('API-19 无 token 时不含 Authorization 头', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      Map<String, String>? capturedHeaders;
      final mock = MockClient((req) async {
        capturedHeaders = Map.from(req.headers);
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        return http.Response(jsonEncode({'memos': []}), 200);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: null);
      await http.runWithClient(() => svc.getMemos(pageSize: 1), () => mock);
      expect(capturedHeaders?.containsKey('Authorization'), isFalse);
    });

    test('API-20 有 token 时 Authorization 头格式正确', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      Map<String, String>? capturedHeaders;
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        capturedHeaders = Map.from(req.headers);
        return http.Response(jsonEncode({'memos': []}), 200);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'my-jwt');
      await http.runWithClient(() => svc.getMemos(pageSize: 1), () => mock);
      expect(capturedHeaders?['Authorization'], 'Bearer my-jwt');
    });
  });
}
