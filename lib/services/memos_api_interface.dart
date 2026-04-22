/// Memos API 抽象接口
/// 定义所有版本必须实现的统一 API 接口
abstract class IMemosApi {
  String get baseUrl;
  String? get accessToken;

  // ==================== 认证相关 ====================

  /// 登录获取 Access Token
  /// 返回 {accessToken, refreshToken?, expiresAt?}
  Future<Map<String, dynamic>> login(String username, String password);

  /// 登出
  Future<void> logout();

  /// 刷新 Token（v0.26.0+）
  Future<Map<String, dynamic>>? refreshToken(String refreshToken);

  // ==================== 用户相关 ====================

  /// 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser();

  /// 更新用户信息
  /// identifier: v0.21.0-v0.26.0 使用数字 ID，v0.27.0+ 使用 username
  Future<Map<String, dynamic>> updateUser(
    String identifier,
    Map<String, dynamic> updates,
  );

  // ==================== 备忘录相关 ====================

  /// 创建备忘录
  Future<Map<String, dynamic>> createMemo({
    required String content,
    String? visibility,
    List<int>? resourceIdList,
    Map<String, dynamic>? relationList,
  });

  /// 获取备忘录列表
  Future<List<Map<String, dynamic>>> getMemos({
    int? creatorId,
    String? rowStatus,
    String? pinned,
    String? tag,
    String? visibility,
    int? limit,
    int? offset,
  });

  /// 获取单个备忘录
  Future<Map<String, dynamic>> getMemo(int memoId);

  /// 更新备忘录
  Future<Map<String, dynamic>> updateMemo(
    int memoId,
    Map<String, dynamic> updates,
  );

  /// 删除备忘录
  Future<void> deleteMemo(int memoId);

  /// 更新备忘录组织器（置顶/取消置顶）
  Future<Map<String, dynamic>> updateMemoOrganizer(
    int memoId, {
    required bool pinned,
  });

  // ==================== 资源相关 ====================

  /// 上传资源（图片、文件等）
  Future<Map<String, dynamic>> uploadResource(
    String filePath, {
    String? filename,
  });

  /// 获取资源列表
  Future<List<Map<String, dynamic>>> getResources({
    int? limit,
    int? offset,
  });

  /// 删除资源
  Future<void> deleteResource(int resourceId);

  // ==================== 标签相关 ====================

  /// 获取所有标签
  Future<List<String>> getTags();

  /// 删除标签
  Future<void> deleteTag(String tag);

  // ==================== 版本信息 ====================

  /// 获取服务器版本信息
  Future<String> getServerVersion();

  /// 获取适配器版本名称
  String get adapterVersion;
}

/// 版本检测异常
class VersionDetectionException implements Exception {
  final String message;
  VersionDetectionException(this.message);

  @override
  String toString() => 'VersionDetectionException: $message';
}

/// Token 过期异常
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);

  @override
  String toString() => 'TokenExpiredException: $message';
}

/// API 错误异常
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errorData;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorData,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
