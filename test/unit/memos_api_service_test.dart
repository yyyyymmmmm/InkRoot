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

// ─── 帮助函数：构造 MockClient ──────────────────────────────────────────────

MockClient _buildMockClient({
  String version = 'v0.28.0',
  int statusCode = 200,
  String? memosBody,
}) =>
    MockClient((request) async {
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
          },
        });
        return http.Response(body, 200);
      }

      return http.Response('{"error":"not found"}', 404);
    });

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
      final mock = _buildMockClient();
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
      final mock = MockClient((req) async => http.Response('Not Found', 404));
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
    test('API-06z v0.21-v0.29 列表路径矩阵保持兼容', () async {
      final cases = [
        (version: 'v0.21.0', path: '/api/v1/memo'),
        (version: 'v0.22.0', path: '/api/v1/memos'),
        (version: 'v0.25.0', path: '/api/v1/memos'),
        (version: 'v0.26.0', path: '/api/v1/memos'),
        (version: 'v0.27.0', path: '/api/v1/memos'),
        (version: 'v0.29.1', path: '/api/v1/memos'),
      ];

      for (final item in cases) {
        await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
        String? calledPath;
        final mock = MockClient((req) async {
          if (req.url.path.endsWith('/api/v1/workspace/profile')) {
            return http.Response(jsonEncode({'version': item.version}), 200);
          }
          if (req.url.path.endsWith('/api/v1/memos')) {
            calledPath = req.url.path;
            return http.Response(jsonEncode({'memos': []}), 200);
          }
          if (req.url.path.endsWith('/api/v1/memo')) {
            calledPath = req.url.path;
            return http.Response(jsonEncode([]), 200);
          }
          return http.Response('{}', 404);
        });

        final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
        await http.runWithClient(() => svc.getMemos(pageSize: 1), () => mock);

        expect(calledPath, item.path);
      }
    });

    test('API-07 v0.28 正确请求 /api/v1/memos', () async {
      String? calledPath;
      final mock = MockClient((req) async {
        calledPath = req.url.path;
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/memos')) {
          return http.Response(jsonEncode({'memos': []}), 200);
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
        http.runWithClient(svc.getMemos, () => mock),
        throwsA(isA<TokenExpiredException>()),
      );
    });

    test('API-10 memos 列表可被解析为 Note 对象', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = _buildMockClient();
      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final result = await http.runWithClient(svc.getMemos, () => mock);
      final memos = result['memos'] as List<dynamic>;
      expect(memos, isNotEmpty);
      final note = Note.fromJson(memos[0] as Map<String, dynamic>);
      expect(note.content, 'test note');
    });

    test('API-10b v0.22+ 会按 nextPageToken 拉取全部分页', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final requestedTokens = <String?>[];
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/memos')) {
          final token = req.url.queryParameters['pageToken'];
          requestedTokens.add(token);
          if (token == null) {
            return http.Response(
              jsonEncode({
                'memos': [
                  {
                    'name': 'memos/1',
                    'content': 'first',
                    'createTime': '2024-05-01T10:00:00Z',
                    'updateTime': '2024-05-01T10:00:00Z',
                  }
                ],
                'nextPageToken': 'next',
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'memos': [
                {
                  'name': 'memos/2',
                  'content': 'second',
                  'createTime': '2024-05-01T10:01:00Z',
                  'updateTime': '2024-05-01T10:01:00Z',
                }
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final result = await http.runWithClient(
        () => svc.getMemos(pageSize: 1),
        () => mock,
      );

      expect(requestedTokens, [null, 'next']);
      expect(result['isComplete'], isTrue);
      expect(result['memos'], hasLength(2));
    });
  });

  // ─────────────────────────────────────────────────────────
  // createAccessToken
  // ─────────────────────────────────────────────────────────
  group('MemosApiServiceFixed — createAccessToken', () {
    test('API-10z v0.21-v0.29 登录协议矩阵保持兼容', () async {
      final cases = [
        (version: 'v0.21.0', tokenKey: 'token', expectedBody: 'legacy'),
        (version: 'v0.22.0', tokenKey: 'cookie', expectedBody: 'flat'),
        (version: 'v0.25.0', tokenKey: 'cookie', expectedBody: 'flat'),
        (version: 'v0.26.0', tokenKey: 'access_token', expectedBody: 'wrapped'),
        (version: 'v0.27.0', tokenKey: 'access_token', expectedBody: 'wrapped'),
        (version: 'v0.29.1', tokenKey: 'access_token', expectedBody: 'wrapped'),
      ];

      for (final item in cases) {
        await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
        final minor = item.version.split('.')[1];
        final mock = MockClient((req) async {
          if (req.url.path.endsWith('/api/v1/workspace/profile')) {
            return http.Response(jsonEncode({'version': item.version}), 200);
          }
          if (req.url.path.endsWith('/api/v1/auth/signin')) {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            switch (item.expectedBody) {
              case 'legacy':
                expect(body, containsPair('username', 'alice'));
                expect(body, isNot(contains('neverExpire')));
                break;
              case 'flat':
                expect(body, containsPair('username', 'alice'));
                expect(body, containsPair('neverExpire', false));
                break;
              case 'wrapped':
                expect(body['passwordCredentials'], isA<Map>());
                break;
            }

            if (item.tokenKey == 'cookie') {
              return http.Response(
                '{}',
                200,
                headers: {
                  'set-cookie': 'memos.access-token=tok-$minor; Path=/',
                },
              );
            }
            return http.Response(
              jsonEncode({item.tokenKey: 'tok-$minor'}),
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

        expect(token, 'tok-$minor');
      }
    });

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

    test('API-11b v0.29 登录兼容 access_token 字段', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.29.1'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/auth/signin')) {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body.containsKey('passwordCredentials'), isTrue);
          return http.Response(
            jsonEncode({
              'user': {'name': 'users/alice', 'username': 'alice'},
              'access_token': 'memos-v029-token',
            }),
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

      expect(token, 'memos-v029-token');
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
    test('API-13z v0.21-v0.29 当前用户接口矩阵保持兼容', () async {
      final cases = [
        (version: 'v0.21.0', method: 'GET', path: '/api/v1/user/me'),
        (version: 'v0.22.0', method: 'POST', path: '/api/v1/auth/status'),
        (version: 'v0.25.0', method: 'POST', path: '/api/v1/auth/status'),
        (version: 'v0.26.0', method: 'GET', path: '/api/v1/auth/me'),
        (version: 'v0.27.0', method: 'GET', path: '/api/v1/auth/me'),
        (version: 'v0.29.1', method: 'GET', path: '/api/v1/auth/me'),
      ];

      for (final item in cases) {
        await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
        String? called;
        final mock = MockClient((req) async {
          if (req.url.path.endsWith('/api/v1/workspace/profile')) {
            return http.Response(jsonEncode({'version': item.version}), 200);
          }
          if (req.url.path.endsWith(item.path)) {
            called = '${req.method} ${req.url.path}';
            final user = {
              'id': '42',
              'name': 'users/alice',
              'username': 'alice',
              'role': 'USER',
            };
            final body = item.path.endsWith('/auth/me')
                ? jsonEncode({'user': user})
                : jsonEncode(user);
            return http.Response(body, 200);
          }
          return http.Response('{}', 404);
        });

        final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
        final user = await http.runWithClient(svc.getUserInfo, () => mock);

        expect(user.username, 'alice');
        expect(called, '${item.method} ${item.path}');
      }
    });

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
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final user = await http.runWithClient(svc.getUserInfo, () => mock);
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
      await http.runWithClient(svc.getUserInfo, () => mock);
      expect(calledPath, endsWith('/api/v1/auth/status'));
      expect(method, 'POST');
    });

    test('API-15b 版本误判时自动回退到 /api/v1/auth/me', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final calledPaths = <String>[];
      final mock = MockClient((req) async {
        calledPaths.add('${req.method} ${req.url.path}');
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.22.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/auth/status')) {
          return http.Response('Not Found', 404);
        }
        if (req.url.path.endsWith('/api/v1/auth/me')) {
          return http.Response(
            jsonEncode({
              'user': {
                'id': '42',
                'username': 'alice',
                'role': 'ADMIN',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final user = await http.runWithClient(svc.getUserInfo, () => mock);

      expect(user.username, 'alice');
      expect(calledPaths, contains('POST /api/v1/auth/status'));
      expect(calledPaths, contains('GET /api/v1/auth/me'));
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
        http.runWithClient(svc.getUserInfo, () => mock),
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

      final svc = MemosApiServiceFixed(baseUrl: baseUrl);
      await http.runWithClient(() => svc.getMemos(pageSize: 1), () => mock);
      expect(capturedHeaders?.containsKey('Authorization'), isFalse);
    });

    test('API-20 有 token 时 Authorization 和 Cookie 头格式正确', () async {
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
      expect(capturedHeaders?['Cookie'], 'memos.access-token=my-jwt');
    });
  });

  group('MemosApiServiceFixed — updateMemoVisibility', () {
    test('API-21 v0.27 使用 /api/v1/memos/{id} 和 updateMask=content,visibility',
        () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      String? calledPath;
      String? updateMask;
      Map<String, dynamic>? body;
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.27.0'}), 200);
        }
        if (req.url.path.endsWith('/api/v1/memos/42')) {
          calledPath = req.url.path;
          updateMask = req.url.queryParameters['updateMask'];
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'name': 'memos/42',
              'content': body!['content'],
              'visibility': body!['visibility'],
              'createTime': '2024-05-01T10:00:00Z',
              'updateTime': '2024-05-01T10:00:00Z',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final note = await http.runWithClient(
        () => svc.updateMemoVisibility(
          '42',
          content: 'hello',
          visibility: 'PUBLIC',
        ),
        () => mock,
      );

      expect(calledPath, endsWith('/api/v1/memos/42'));
      expect(updateMask, 'content,visibility');
      expect(body?['name'], 'memos/42');
      expect(body?['visibility'], 'PUBLIC');
      expect(note.visibility, 'PUBLIC');
    });
  });

  group('MemosApiServiceFixed — deleteMemo', () {
    test('API-22 删除接口把 200/204/404 视为成功', () async {
      for (final status in [200, 204, 404]) {
        await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
        final mock = MockClient((req) async {
          if (req.url.path.endsWith('/api/v1/workspace/profile')) {
            return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
          }
          if (req.method == 'DELETE' &&
              req.url.path.endsWith('/api/v1/memos/42')) {
            return http.Response('', status);
          }
          return http.Response('{}', 404);
        });

        final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
        await http.runWithClient(() => svc.deleteMemo('42'), () => mock);
      }
    });

    test('API-23 删除接口非幂等错误保留服务端错误信息', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.28.0'}), 200);
        }
        if (req.method == 'DELETE' &&
            req.url.path.endsWith('/api/v1/memos/42')) {
          return http.Response(
            jsonEncode({'message': 'permission denied'}),
            500,
          );
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      await expectLater(
        http.runWithClient(() => svc.deleteMemo('42'), () => mock),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('permission denied'),
          ),
        ),
      );
    });
  });

  group('MemosApiServiceFixed — relations', () {
    test('API-24 v0.24 新增引用使用 List + Set relations', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      final called = <String>[];
      Map<String, dynamic>? patchBody;

      final mock = MockClient((req) async {
        called.add('${req.method} ${req.url.path}');
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.24.0'}), 200);
        }
        if (req.method == 'GET' &&
            req.url.path.endsWith('/api/v1/memos/42/relations')) {
          return http.Response(jsonEncode({'relations': []}), 200);
        }
        if (req.method == 'PATCH' &&
            req.url.path.endsWith('/api/v1/memos/42/relations')) {
          patchBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final ok = await http.runWithClient(
        () => svc.addMemoReference('42', '99'),
        () => mock,
      );

      expect(ok, isTrue);
      expect(called, contains('GET /api/v1/memos/42/relations'));
      expect(called, contains('PATCH /api/v1/memos/42/relations'));
      expect(patchBody?['name'], 'memos/42');
      final relations = patchBody?['relations'] as List<dynamic>;
      expect(relations, hasLength(1));
      expect((relations.first as Map<String, dynamic>)['type'], 'REFERENCE');
      expect(
        ((relations.first as Map<String, dynamic>)['relatedMemo']
            as Map<String, dynamic>)['name'],
        'memos/99',
      );
    });

    test('API-25 v0.27 删除全部引用使用 Set relations 空列表', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      Map<String, dynamic>? patchBody;

      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.27.0'}), 200);
        }
        if (req.method == 'PATCH' &&
            req.url.path.endsWith('/api/v1/memos/42/relations')) {
          patchBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final ok = await http.runWithClient(
        () => svc.deleteAllMemoRelations('42'),
        () => mock,
      );

      expect(ok, isTrue);
      expect(patchBody?['name'], 'memos/42');
      expect(patchBody?['relations'], isEmpty);
    });

    test('API-26 v0.21 新增引用保留 legacy relation 接口', () async {
      await MemosApiServiceFixed.invalidateVersionCache(baseUrl);
      String? calledPath;
      Map<String, dynamic>? body;

      final mock = MockClient((req) async {
        if (req.url.path.endsWith('/api/v1/workspace/profile')) {
          return http.Response(jsonEncode({'version': 'v0.21.0'}), 200);
        }
        if (req.method == 'POST' &&
            req.url.path.endsWith('/api/v1/memo/42/relation')) {
          calledPath = req.url.path;
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      });

      final svc = MemosApiServiceFixed(baseUrl: baseUrl, token: 'tok');
      final ok = await http.runWithClient(
        () => svc.addMemoReference('42', '99'),
        () => mock,
      );

      expect(ok, isTrue);
      expect(calledPath, endsWith('/api/v1/memo/42/relation'));
      expect(body?['relatedMemoId'], 99);
      expect(body?['type'], 'REFERENCE');
    });
  });
}
