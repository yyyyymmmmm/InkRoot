// ============================================================
// 第二档测试 · User 数据模型
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/user_model.dart';

void main() {
  group('User.fromJson', () {
    test('UM-01 基础字段正确解析', () {
      final user = User.fromJson({
        'id': '1',
        'username': 'alice',
        'email': 'alice@example.com',
        'role': 'USER',
      });
      expect(user.id, '1');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
      expect(user.role, 'USER');
    });

    test('UM-02 int id 转为 String', () {
      final user = User.fromJson({
        'id': 42,
        'username': 'bob',
      });
      expect(user.id, '42');
    });

    test('UM-03 缺少 role 时默认 USER', () {
      final user = User.fromJson({'id': '1', 'username': 'carol'});
      expect(user.role, 'USER');
    });

    test('UM-04 ADMIN 角色正确解析', () {
      final user = User.fromJson({
        'id': '2',
        'username': 'admin',
        'role': 'ADMIN',
      });
      expect(user.isAdmin, isTrue);
      expect(user.isUser, isFalse);
    });

    test('UM-05 HOST 角色正确解析', () {
      final user = User.fromJson({
        'id': '3',
        'username': 'host',
        'role': 'HOST',
      });
      expect(user.isHost, isTrue);
    });

    test('UM-06 token 字段正确解析', () {
      final user = User.fromJson({
        'id': '1',
        'username': 'user',
        'token': 'sample-token',
      });
      expect(user.token, 'sample-token');
      expect(user.isLoggedIn, isTrue);
    });

    test('UM-07 token 为 null 时 isLoggedIn=false', () {
      final user = User.fromJson({'id': '1', 'username': 'user'});
      expect(user.isLoggedIn, isFalse);
    });

    test('UM-08 lastSyncTime ISO 字符串正确解析', () {
      final user = User.fromJson({
        'id': '1',
        'username': 'user',
        'lastSyncTime': '2024-05-01T10:00:00.000Z',
      });
      expect(user.lastSyncTime, isNotNull);
      expect(user.lastSyncTime!.year, 2024);
    });
  });

  group('User.toJson', () {
    test('UM-09 toJson 包含所有基础字段', () {
      final user = User(id: '5', username: 'test');
      final json = user.toJson();
      expect(json['id'], '5');
      expect(json['username'], 'test');
      expect(json['role'], 'USER');
    });

    test('UM-10 toJson/fromJson 往返一致', () {
      final original = User(
        id: '10',
        username: 'roundtrip',
        email: 'rt@example.com',
        nickname: 'RT',
        role: 'ADMIN',
        token: 'tok-abc',
      );
      final json = original.toJson();
      final restored = User.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.email, original.email);
      expect(restored.role, original.role);
      expect(json.containsKey('token'), isFalse);
      expect(restored.token, isNull);
    });

    test('UM-10B toJson 需要显式 includeToken 才输出 token', () {
      final user = User(id: '10', username: 'roundtrip', token: 'tok-abc');
      final json = user.toJson(includeToken: true);
      expect(json['token'], 'tok-abc');
    });
  });

  group('User.copyWith', () {
    test('UM-11 copyWith 修改 token 后原对象不变', () {
      final original = User(id: '1', username: 'u', token: 'old-tok');
      final copy = original.copyWith(token: 'new-tok');
      expect(copy.token, 'new-tok');
      expect(original.token, 'old-tok');
    });

    test('UM-12 copyWith 未指定字段保持原值', () {
      final original =
          User(id: '1', username: 'alice', email: 'a@x.com', role: 'ADMIN');
      final copy = original.copyWith(username: 'alice-v2');
      expect(copy.email, 'a@x.com');
      expect(copy.role, 'ADMIN');
    });
  });

  group('User 角色和状态', () {
    test('UM-13 空 token 时 isLoggedIn=false', () {
      final user = User(id: '1', username: 'u', token: '');
      expect(user.isLoggedIn, isFalse);
    });

    test('UM-14 isUser 仅在 role=USER 时为 true', () {
      expect(User(id: '1', username: 'u').isUser, isTrue);
      expect(User(id: '1', username: 'u', role: 'ADMIN').isUser, isFalse);
    });

    test('UM-15 serverUrl 字段正确存储', () {
      final user = User(
        id: '1',
        username: 'u',
        serverUrl: 'https://memos.example.com',
      );
      expect(user.serverUrl, 'https://memos.example.com');
    });
  });
}
