import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/user_model.dart';

/// Token过期异常类
class TokenExpiredException implements Exception {
  TokenExpiredException(this.message);
  final String message;

  @override
  String toString() => 'TokenExpiredException: $message';
}

/// 修复版本的Memos API服务类 - 基于Memos 0.21.0 API
class MemosApiServiceFixed {
  MemosApiServiceFixed({required this.baseUrl, this.token});
  final String baseUrl;
  final String? token;

  /// 创建请求头，包含授权信息
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ==================== 备忘录 API ====================

  /// 创建备忘录
  Future<Note> createMemo({
    required String content,
    String visibility = 'PRIVATE',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/memo'),
        headers: _getHeaders(),
        body: json.encode({
          'content': content,
          'visibility': visibility,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint('创建备忘录失败: Token无效或已过期');
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      } else {
        debugPrint('创建备忘录失败: ${response.statusCode}, ${response.body}');
        throw Exception('创建备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow; // 重新抛出Token过期异常
      }
      debugPrint('V1 API创建备忘录失败: $e');
      throw Exception('创建备忘录失败: $e');
    }
  }

  /// 获取备忘录列表
  Future<Map<String, dynamic>> getMemos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/memo'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final memos = data.map((item) => item as Map<String, dynamic>).toList();
        return {'memos': memos};
      } else if (response.statusCode == 401) {
        debugPrint('获取备忘录列表失败: Token无效或已过期');
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      } else {
        debugPrint('获取备忘录列表失败: ${response.statusCode}, ${response.body}');
        throw Exception('获取备忘录列表失败: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow; // 重新抛出Token过期异常
      }
      debugPrint('V1 API获取备忘录列表失败: $e');
      throw Exception('获取备忘录列表失败: $e');
    }
  }

  /// 获取单个备忘录
  Future<Note> getMemo(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/memo/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _convertToNote(responseData);
      } else {
        debugPrint('获取备忘录失败: ${response.statusCode}, ${response.body}');
        throw Exception('获取备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('V1 API获取备忘录失败: $e');
      throw Exception('获取备忘录失败: $e');
    }
  }

  /// 更新备忘录
  Future<Note> updateMemo(
    String id, {
    required String content,
    String? visibility,
  }) async {
    try {
      // 如果是本地ID，需要创建而不是更新
      if (id.startsWith('local_') || id.contains('-')) {
        debugPrint('本地ID，需要创建新备忘录: $id');
        return createMemo(
          content: content,
          visibility: visibility ?? 'PRIVATE',
        );
      }

      // 构建请求体
      final body = <String, dynamic>{
        'content': content,
      };

      if (visibility != null) {
        body['visibility'] = visibility;
      }

      debugPrint('尝试更新备忘录: $baseUrl/api/v1/memo/$id');
      debugPrint('请求体: ${json.encode(body)}');

      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/memo/$id'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      debugPrint('更新备忘录响应状态码: ${response.statusCode}');
      debugPrint('更新备忘录响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data);
      } else {
        throw Exception('更新备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('V1 API更新备忘录失败: $e');
      throw Exception('更新备忘录失败: $e');
    }
  }

  /// 删除备忘录
  Future<void> deleteMemo(String id) async {
    try {
      // 如果是本地ID，不需要从服务器删除
      if (id.startsWith('local_') || id.contains('-')) {
        debugPrint('本地ID，不需要从服务器删除: $id');
        return;
      }

      debugPrint('MemosApiServiceFixed: 开始删除备忘录 ID: $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/memo/$id'),
        headers: _getHeaders(),
      );

      debugPrint('MemosApiServiceFixed: 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
      } else {
        debugPrint('V1 API删除备忘录失败: ${response.statusCode}, ${response.body}');
        throw Exception('删除备忘录失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MemosApiServiceFixed: 删除备忘录时发生错误: $e');
      throw Exception('删除备忘录失败: $e');
    }
  }

  /// 更新备忘录的组织状态（置顶/取消置顶）
  /// 
  /// Memos 使用独立的 memo_organizer 表来存储用户的个性化设置
  Future<Note> updateMemoOrganizer(String id, {required bool pinned}) async {
    try {
      // 如果是本地ID，跳过服务器同步
      if (id.startsWith('local_') || id.contains('-')) {
        debugPrint('本地ID，不需要同步组织状态到服务器: $id');
        throw Exception('本地笔记无需同步');
      }

      final body = {'pinned': pinned};

      debugPrint('更新备忘录组织状态: $baseUrl/api/v1/memo/$id/organizer');
      debugPrint('请求体: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/memo/$id/organizer'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      debugPrint('更新组织状态响应码: ${response.statusCode}');
      debugPrint('更新组织状态响应: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Note.fromJson(data);
      } else {
        throw Exception('更新备忘录组织状态失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('V1 API更新备忘录组织状态失败: $e');
      throw Exception('更新备忘录组织状态失败: $e');
    }
  }

  // ==================== 用户 API ====================

  /// 获取当前用户信息
  Future<User> getUserInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/user/me'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return _convertApiUserToUser(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Token无效或已过期，请重新登录');
    } else {
      debugPrint('获取用户信息失败: ${response.statusCode}, ${response.body}');
      throw Exception('获取用户信息失败: ${response.statusCode}');
    }
  }

  /// 创建访问令牌
  Future<String> createAccessToken(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      debugPrint('登录失败: ${response.statusCode}, ${response.body}');
      throw Exception('登录失败: ${response.statusCode}');
    }
  }

  /// 更新用户信息
  Future<User> updateUserInfo({
    String? nickname,
    String? email,
    String? avatarUrl,
    String? description,
  }) async {
    try {
      if (token == null || token!.isEmpty) {
        throw Exception('未登录，无法更新用户信息');
      }

      // 获取当前用户信息
      final currentUser = await getUserInfo();

      // 构建请求体
      final body = <String, dynamic>{};

      if (nickname != null) body['nickname'] = nickname;
      if (email != null) body['email'] = email;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
      if (description != null) body['description'] = description;

      final userId = currentUser.id;
      final apiUrl = '$baseUrl/api/v1/user/$userId';

      debugPrint('尝试更新用户信息: $apiUrl');
      debugPrint('请求体: ${json.encode(body)}');

      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      debugPrint('更新用户信息响应状态码: ${response.statusCode}');
      debugPrint('更新用户信息响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson({
          ...data,
          'token': token, // 保持token不变
        });
      } else if (response.statusCode == 401) {
        throw Exception('Token无效或已过期，请重新登录');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('更新用户信息失败: ${error['message'] ?? '请求参数错误'}');
      } else {
        debugPrint('更新用户信息失败: ${response.statusCode}, ${response.body}');
        throw Exception('更新用户信息失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('更新用户信息时发生错误: $e');
      throw Exception('更新用户信息失败: $e');
    }
  }

  /// 退出登录，撤销token
  Future<bool> logout() async {
    try {
      // 尝试撤销当前token
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/signout'),
        headers: _getHeaders(),
      );

      debugPrint('登出API响应状态码: ${response.statusCode}');
      debugPrint('登出API响应内容: ${response.body}');

      // 不管服务器响应如何，都认为登出成功
      // 因为客户端会清除本地token
      return true;
    } catch (e) {
      debugPrint('调用登出API失败: $e');
      // 即使API调用失败，也返回true，因为客户端会清除本地token
      return true;
    }
  }

  // ==================== 工具方法 ====================

  /// 将API返回的用户数据转换为User模型
  User _convertApiUserToUser(Map<String, dynamic> apiUser) => User(
        id: apiUser['id'].toString(),
        username: apiUser['username'] ?? '',
        email: apiUser['email'],
        nickname: apiUser['nickname'] ?? apiUser['username'],
        token: token,
        role: apiUser['role'] ?? 'USER',
      );

  /// 将API返回的备忘录数据转换为Note模型
  Note _convertToNote(Map<String, dynamic> memo) {
    // 提取ID
    final id = memo['id'].toString();

    // 处理时间戳 - Memos API 返回的是秒级时间戳，需要转换为毫秒
    final createdTsSeconds = memo['createdTs'] as int;
    final updatedTsSeconds = memo['updatedTs'] as int;

    // 转换为毫秒级时间戳
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(createdTsSeconds * 1000);
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(updatedTsSeconds * 1000);

    // 提取内容和可见性
    final String content = memo['content'] ?? '';
    final String visibility = memo['visibility'] ?? 'PRIVATE';

    // 提取创建者
    final creator = memo['creatorId']?.toString() ?? '';

    // 创建Note对象
    return Note(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      displayTime: updatedAt,
      creator: creator,
      visibility: visibility,
      tags: Note.extractTagsFromContent(content),
      isSynced: true,
      isPinned: memo['pinned'] ?? false,
    );
  }
}
