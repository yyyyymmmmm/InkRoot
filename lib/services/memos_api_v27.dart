import 'memos_api_v26.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Memos API v0.27.0 实现
/// 继承 v0.26.0，修改用户资源名称格式（使用 username 而非数字 ID）
class MemosApiV27 extends MemosApiV26 {
  // 缓存当前用户信息
  Map<String, dynamic>? _cachedUser;

  MemosApiV27(String baseUrl) : super(baseUrl);

  @override
  String get adapterVersion => 'v0.27.0';

  // ==================== 用户相关（覆盖） ====================

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    _cachedUser = await super.getCurrentUser();
    return _cachedUser!;
  }

  @override
  Future<Map<String, dynamic>> updateUser(
    String identifier,
    Map<String, dynamic> updates,
  ) async {
    // v0.27.0 使用 users/{username} 格式
    String username;

    // 如果传入的是数字 ID，需要先获取 username
    if (RegExp(r'^\d+$').hasMatch(identifier)) {
      // 数字 ID，需要转换为 username
      if (_cachedUser == null) {
        await getCurrentUser();
      }

      if (_cachedUser?['id'].toString() == identifier) {
        username = _cachedUser!['username'];
      } else {
        // 不是当前用户，抛出错误（v0.27.0 只能更新自己）
        throw ApiException(
          statusCode: 403,
          message: 'v0.27.0 only supports updating current user',
        );
      }
    } else {
      // 已经是 username
      username = identifier;
    }

    // v0.27.0 使用 /api/v1/users/{username} 格式
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/users/$username'),
      headers: _buildHeaders(),
      body: jsonEncode(updates),
    );

    return _handleResponse(response);
  }

  // ==================== SSE（Server-Sent Events）支持 ====================

  /// 订阅 SSE 事件流
  /// v0.27.0 新增功能
  Stream<Map<String, dynamic>> subscribeToEvents() async* {
    final uri = Uri.parse('$baseUrl/api/v1/sse');
    final request = http.Request('GET', uri);
    request.headers.addAll(_buildHeaders());

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to connect to SSE',
      );
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      // 解析 SSE 数据
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          try {
            final event = jsonDecode(data) as Map<String, dynamic>;
            yield event;
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    }
  }

  // ==================== 语音笔记（Voice Note）====================

  /// 创建语音笔记
  /// v0.27.0 新增功能
  Future<Map<String, dynamic>> createVoiceNote({
    required String audioFilePath,
    bool transcribe = true,
  }) async {
    // 实现语音笔记上传和转录
    throw UnimplementedError('createVoiceNote not yet implemented');
  }

  // ==================== 分享链接 ====================

  /// 创建分享链接
  /// v0.27.0 新增功能
  Future<Map<String, dynamic>> createMemoShare(
    int memoId, {
    DateTime? expiresAt,
  }) async {
    final body = <String, dynamic>{};

    if (expiresAt != null) {
      body['expiresAt'] = expiresAt.millisecondsSinceEpoch ~/ 1000;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/memo/$memoId/share'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// 获取分享的备忘录（无需认证）
  Future<Map<String, dynamic>> getSharedMemo(String shareKey) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/share/$shareKey'),
      headers: _buildHeaders(includeAuth: false),
    );

    return _handleResponse(response);
  }

  /// 删除分享链接
  Future<void> deleteMemoShare(int memoId, String shareKey) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/memo/$memoId/share/$shareKey'),
      headers: _buildHeaders(),
    );

    _handleResponse(response);
  }
}
