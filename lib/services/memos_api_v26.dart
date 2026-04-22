import 'memos_api_v21.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Memos API v0.26.0 实现
/// 继承 v0.21.0，添加 Refresh Token 支持
class MemosApiV26 extends MemosApiV21 {
  MemosApiV26(String baseUrl) : super(baseUrl);

  @override
  String get adapterVersion => 'v0.26.0';

  // ==================== 认证相关（覆盖） ====================

  @override
  Future<Map<String, dynamic>>? refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/refresh'),
      headers: _buildHeaders(includeAuth: false),
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    );

    final data = _handleResponse(response);

    // 更新 Token
    accessToken = data['accessToken'];
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
    };
  }

  /// 自动刷新 Token 的包装器
  Future<T> _withAutoRefresh<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TokenExpiredException {
      // Token 过期，尝试刷新
      if (_refreshToken != null) {
        await refreshToken(_refreshToken!);
        // 重试请求
        return await request();
      }
      rethrow;
    }
  }

  // ==================== 覆盖所有需要认证的方法以支持自动刷新 ====================

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    return _withAutoRefresh(() => super.getCurrentUser());
  }

  @override
  Future<Map<String, dynamic>> updateUser(
    String identifier,
    Map<String, dynamic> updates,
  ) async {
    return _withAutoRefresh(() => super.updateUser(identifier, updates));
  }

  @override
  Future<Map<String, dynamic>> createMemo({
    required String content,
    String? visibility,
    List<int>? resourceIdList,
    Map<String, dynamic>? relationList,
  }) async {
    return _withAutoRefresh(() => super.createMemo(
          content: content,
          visibility: visibility,
          resourceIdList: resourceIdList,
          relationList: relationList,
        ));
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
    return _withAutoRefresh(() => super.getMemos(
          creatorId: creatorId,
          rowStatus: rowStatus,
          pinned: pinned,
          tag: tag,
          visibility: visibility,
          limit: limit,
          offset: offset,
        ));
  }

  @override
  Future<Map<String, dynamic>> getMemo(int memoId) async {
    return _withAutoRefresh(() => super.getMemo(memoId));
  }

  @override
  Future<Map<String, dynamic>> updateMemo(
    int memoId,
    Map<String, dynamic> updates,
  ) async {
    return _withAutoRefresh(() => super.updateMemo(memoId, updates));
  }

  @override
  Future<void> deleteMemo(int memoId) async {
    return _withAutoRefresh(() => super.deleteMemo(memoId));
  }

  @override
  Future<Map<String, dynamic>> updateMemoOrganizer(
    int memoId, {
    required bool pinned,
  }) async {
    return _withAutoRefresh(
        () => super.updateMemoOrganizer(memoId, pinned: pinned));
  }

  @override
  Future<List<Map<String, dynamic>>> getResources({
    int? limit,
    int? offset,
  }) async {
    return _withAutoRefresh(() => super.getResources(
          limit: limit,
          offset: offset,
        ));
  }

  @override
  Future<void> deleteResource(int resourceId) async {
    return _withAutoRefresh(() => super.deleteResource(resourceId));
  }

  @override
  Future<List<String>> getTags() async {
    return _withAutoRefresh(() => super.getTags());
  }

  @override
  Future<void> deleteTag(String tag) async {
    return _withAutoRefresh(() => super.deleteTag(tag));
  }
}
