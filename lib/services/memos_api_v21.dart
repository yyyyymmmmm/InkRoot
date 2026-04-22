import 'dart:convert';
import 'package:http/http.dart' as http;
import 'memos_api_interface.dart';

/// Memos API v0.21.0 实现
/// 支持 Session Cookie + Access Token 认证
class MemosApiV21 implements IMemosApi {
  @override
  final String baseUrl;

  @override
  String? accessToken;

  String? _refreshToken;
  DateTime? _tokenExpiresAt;

  MemosApiV21(this.baseUrl);

  @override
  String get adapterVersion => 'v0.21.0';

  // ==================== 辅助方法 ====================

  /// 构建请求头
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// 提取错误信息
  String _extractErrorMessage(Map<String, dynamic> errorData) {
    // v0.21.0-v0.25.0: {"error": "..."}
    // v0.26.0+: {"code": "...", "message": "..."}
    return errorData['message'] ?? errorData['error'] ?? 'Unknown error';
  }

  /// 处理 HTTP 响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // 处理错误
    Map<String, dynamic>? errorData;
    try {
      errorData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      errorData = {'error': response.body};
    }

    final message = _extractErrorMessage(errorData);

    // 检查是否是 Token 过期
    if (response.statusCode == 401) {
      throw TokenExpiredException(message);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errorData: errorData,
    );
  }

  // ==================== 认证相关 ====================

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: _buildHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    // v0.21.0-v0.25.0: {"user": {...}, "token": "..."}
    // v0.26.0+: {"user": {...}, "accessToken": "...", "refreshToken": "...", "expiresAt": ...}
    accessToken = data['accessToken'] ?? data['token'];
    _refreshToken = data['refreshToken'];

    if (data['expiresAt'] != null) {
      _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(
        data['expiresAt'] * 1000,
      );
    }

    return {
      'accessToken': accessToken,
      'refreshToken': _refreshToken,
      'expiresAt': _tokenExpiresAt?.toIso8601String(),
      'user': data['user'],
    };
  }

  @override
  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signout'),
      headers: _buildHeaders(),
    );

    _handleResponse(response);

    accessToken = null;
    _refreshToken = null;
    _tokenExpiresAt = null;
  }

  @override
  Future<Map<String, dynamic>>? refreshToken(String refreshToken) {
    // v0.21.0 不支持 Refresh Token
    return null;
  }

  // ==================== 用户相关 ====================

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/user/me'),
      headers: _buildHeaders(),
    );

    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> updateUser(
    String identifier,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/user/$identifier'),
      headers: _buildHeaders(),
      body: jsonEncode(updates),
    );

    return _handleResponse(response);
  }

  // ==================== 备忘录相关 ====================

  @override
  Future<Map<String, dynamic>> createMemo({
    required String content,
    String? visibility,
    List<int>? resourceIdList,
    Map<String, dynamic>? relationList,
  }) async {
    final body = <String, dynamic>{
      'content': content,
    };

    if (visibility != null) body['visibility'] = visibility;
    if (resourceIdList != null) body['resourceIdList'] = resourceIdList;
    if (relationList != null) body['relationList'] = relationList;

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/memo'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getMemos({
    int? creatorId,
    String? rowStatus,
    String? pinned,
    String? tag,
    String? visibility,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};

    if (creatorId != null) queryParams['creatorId'] = creatorId.toString();
    if (rowStatus != null) queryParams['rowStatus'] = rowStatus;
    if (pinned != null) queryParams['pinned'] = pinned;
    if (tag != null) queryParams['tag'] = tag;
    if (visibility != null) queryParams['visibility'] = visibility;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final uri = Uri.parse('$baseUrl/api/v1/memo').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: _buildHeaders(),
    );

    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'] ?? data);
  }

  @override
  Future<Map<String, dynamic>> getMemo(int memoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/memo/$memoId'),
      headers: _buildHeaders(),
    );

    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> updateMemo(
    int memoId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/memo/$memoId'),
      headers: _buildHeaders(),
      body: jsonEncode(updates),
    );

    return _handleResponse(response);
  }

  @override
  Future<void> deleteMemo(int memoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/memo/$memoId'),
      headers: _buildHeaders(),
    );

    _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> updateMemoOrganizer(
    int memoId, {
    required bool pinned,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/memo/$memoId/organizer'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'pinned': pinned,
      }),
    );

    return _handleResponse(response);
  }

  // ==================== 资源相关 ====================

  @override
  Future<Map<String, dynamic>> uploadResource(
    String filePath, {
    String? filename,
  }) async {
    // 实现文件上传逻辑
    throw UnimplementedError('uploadResource not yet implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getResources({
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};

    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final uri = Uri.parse('$baseUrl/api/v1/resource').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: _buildHeaders(),
    );

    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'] ?? data);
  }

  @override
  Future<void> deleteResource(int resourceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/resource/$resourceId'),
      headers: _buildHeaders(),
    );

    _handleResponse(response);
  }

  // ==================== 标签相关 ====================

  @override
  Future<List<String>> getTags() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/tag'),
      headers: _buildHeaders(),
    );

    final data = _handleResponse(response);
    return List<String>.from(data['data'] ?? data);
  }

  @override
  Future<void> deleteTag(String tag) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/tag/$tag'),
      headers: _buildHeaders(),
    );

    _handleResponse(response);
  }

  // ==================== 版本信息 ====================

  @override
  Future<String> getServerVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/status'),
        headers: _buildHeaders(includeAuth: false),
      );

      final data = _handleResponse(response);
      return data['version'] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}
