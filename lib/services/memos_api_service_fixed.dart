import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/user_model.dart';
import 'memos_api_factory.dart';
import 'memos_api_interface.dart';
import 'memos_api_v21.dart';

/// Token过期异常类
class TokenExpiredException implements Exception {
  TokenExpiredException(this.message);
  final String message;

  @override
  String toString() => 'TokenExpiredException: $message';
}

/// 兼容层：保持原有接口，内部使用多版本适配器
/// 支持 Memos v0.21.0 - v0.27.1 所有版本
class MemosApiServiceFixed {
  MemosApiServiceFixed({required this.baseUrl, String? token})
      : _token = token {
    _initialize();
  }

  final String baseUrl;
  String? _token;
  IMemosApi? _api;
  bool _initialized = false;

  /// 获取当前 token
  String? get token => _token ?? _api?.accessToken;

  /// 初始化适配器（异步）
  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      _api = await MemosApiFactory.create(baseUrl);

      // 如果已有 token，设置到适配器
      if (_token != null) {
        _api!.accessToken = _token;
      }

      _initialized = true;
      debugPrint('✅ Memos API 适配器初始化成功 (版本: ${_api!.adapterVersion})');
    } catch (e) {
      debugPrint('⚠️ Memos API 适配器初始化失败，使用降级模式: $e');
      // 降级：使用 v0.21.0 适配器
      _api = MemosApiV21(baseUrl);
      if (_token != null) {
        _api!.accessToken = _token;
      }
      _initialized = true;
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initialize();
    }
  }

  /// 创建请求头，包含授权信息（保留原接口）
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
    await _ensureInitialized();

    try {
      final memoData = await _api!.createMemo(
        content: content,
        visibility: visibility,
      );
      return _convertToNote(memoData);
    } on TokenExpiredException {
      rethrow;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        debugPrint('创建备忘录失败: Token无效或已过期');
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      }
      debugPrint('创建备忘录失败: ${e.statusCode}, ${e.message}');
      throw Exception('创建备忘录失败: ${e.statusCode}');
    } catch (e) {
      debugPrint('V1 API创建备忘录失败: $e');
      throw Exception('创建备忘录失败: $e');
    }
  }

  /// 获取备忘录列表
  Future<Map<String, dynamic>> getMemos() async {
    await _ensureInitialized();

    try {
      final memos = await _api!.getMemos();
      return {'memos': memos};
    } on TokenExpiredException {
      rethrow;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        debugPrint('获取备忘录列表失败: Token无效或已过期');
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      }
      debugPrint('获取备忘录列表失败: ${e.statusCode}, ${e.message}');
      throw Exception('获取备忘录列表失败: ${e.statusCode}');
    } catch (e) {
      debugPrint('V1 API获取备忘录列表失败: $e');
      throw Exception('获取备忘录列表失败: $e');
    }
  }

  /// 获取单个备忘录
  Future<Note> getMemo(String id) async {
    await _ensureInitialized();

    try {
      // 尝试解析为数字 ID，如果解析失败则抛出友好错误
      final memoId = int.tryParse(id);
      if (memoId == null) {
        throw FormatException('Invalid memo ID format: $id');
      }

      final memoData = await _api!.getMemo(memoId);
      return _convertToNote(memoData);
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
    await _ensureInitialized();

    try {
      // 如果是本地ID，需要创建而不是更新
      if (id.startsWith('local_') || id.contains('-')) {
        debugPrint('本地ID，需要创建新备忘录: $id');
        return createMemo(
          content: content,
          visibility: visibility ?? 'PRIVATE',
        );
      }

      // 构建更新数据
      final updates = <String, dynamic>{
        'content': content,
      };

      if (visibility != null) {
        updates['visibility'] = visibility;
      }

      debugPrint('尝试更新备忘录: $baseUrl/api/v1/memo/$id');
      debugPrint('请求体: ${json.encode(updates)}');

      final memoData = await _api!.updateMemo(int.parse(id), updates);

      debugPrint('更新备忘录成功');
      return _convertToNote(memoData);
    } catch (e) {
      debugPrint('V1 API更新备忘录失败: $e');
      throw Exception('更新备忘录失败: $e');
    }
  }

  /// 删除备忘录
  Future<void> deleteMemo(String id) async {
    await _ensureInitialized();

    try {
      // 如果是本地ID，不需要从服务器删除
      if (id.startsWith('local_') || id.contains('-')) {
        debugPrint('本地ID，不需要从服务器删除: $id');
        return;
      }

      debugPrint('MemosApiServiceFixed: 开始删除备忘录 ID: $id');
      await _api!.deleteMemo(int.parse(id));
      debugPrint('MemosApiServiceFixed: 删除备忘录成功');
    } catch (e) {
      debugPrint('MemosApiServiceFixed: 删除备忘录时发生错误: $e');
      throw Exception('删除备忘录失败: $e');
    }
  }

  /// 更新备忘录的组织状态（置顶/取消置顶）
  Future<Note> updateMemoOrganizer(String id, {required bool pinned}) async {
    await _ensureInitialized();

    try {
      // 如果是本地ID，跳过服务器同步
      if (id.startsWith('local_') || id.contains('-')) {
        debugPrint('本地ID，不需要同步组织状态到服务器: $id');
        throw Exception('本地笔记无需同步');
      }

      debugPrint('更新备忘录组织状态: $baseUrl/api/v1/memo/$id/organizer');
      debugPrint('请求体: ${json.encode({'pinned': pinned})}');

      final memoData = await _api!.updateMemoOrganizer(int.parse(id), pinned: pinned);

      debugPrint('更新组织状态成功');
      return _convertToNote(memoData);
    } catch (e) {
      debugPrint('V1 API更新备忘录组织状态失败: $e');
      throw Exception('更新备忘录组织状态失败: $e');
    }
  }

  // ==================== 用户 API ====================

  /// 获取当前用户信息
  Future<User> getUserInfo() async {
    await _ensureInitialized();

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

  /// 创建访问令牌（登录）
  Future<String> createAccessToken(String username, String password) async {
    await _ensureInitialized();

    try {
      final result = await _api!.login(username, password);
      // v0.21.0-v0.25.0 返回 'token'，v0.26.0+ 返回 'accessToken'
      _token = result['accessToken'];
      return _token!;
    } on ApiException catch (e) {
      debugPrint('登录失败: ${e.statusCode}, ${e.message}');
      throw Exception('登录失败: ${e.statusCode}');
    } catch (e) {
      debugPrint('登录失败: $e');
      throw Exception('登录失败: $e');
    }
  }

  /// 更新用户信息
  Future<User> updateUserInfo({
    String? nickname,
    String? email,
    String? avatarUrl,
    String? description,
  }) async {
    await _ensureInitialized();

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

      // 获取 username 用于 v0.27.0 兼容
      final userInfo = await _api!.getCurrentUser();
      final identifier = userInfo['username'] ?? userId;

      final userData = await _api!.updateUser(identifier, body);

      debugPrint('更新用户信息成功');
      return User.fromJson({
        ...userData,
        'token': token, // 保持token不变
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Token无效或已过期，请重新登录');
      } else if (e.statusCode == 400) {
        throw Exception('更新用户信息失败: ${e.message ?? '请求参数错误'}');
      }
      debugPrint('更新用户信息失败: ${e.statusCode}, ${e.message}');
      throw Exception('更新用户信息失败: ${e.statusCode}');
    } catch (e) {
      debugPrint('更新用户信息时发生错误: $e');
      throw Exception('更新用户信息失败: $e');
    }
  }

  /// 退出登录，撤销token
  Future<bool> logout() async {
    await _ensureInitialized();

    try {
      await _api!.logout();
      debugPrint('登出成功');
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
