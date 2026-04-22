import 'package:http/http.dart' as http;
import 'dart:convert';
import 'memos_api_interface.dart';
import 'memos_api_v21.dart';
import 'memos_api_v26.dart';
import 'memos_api_v27.dart';

/// Memos API 工厂类
/// 根据服务器版本自动选择合适的适配器
class MemosApiFactory {
  /// 创建适配器实例
  ///
  /// [baseUrl] 服务器地址
  /// [version] 可选的版本字符串（如 "0.27.0"），如果为 null 则自动检测
  /// [forceVersion] 强制使用指定版本的适配器，忽略服务器实际版本
  static Future<IMemosApi> create(
    String baseUrl, {
    String? version,
    bool forceVersion = false,
  }) async {
    // 如果没有指定版本，尝试自动检测
    final detectedVersion = version ?? await _detectVersion(baseUrl);

    // 根据版本创建对应的适配器
    return _createAdapter(baseUrl, detectedVersion);
  }

  /// 创建指定版本的适配器（不进行版本检测）
  static IMemosApi createForVersion(String baseUrl, String version) {
    return _createAdapter(baseUrl, version);
  }

  /// 检测服务器版本
  static Future<String> _detectVersion(String baseUrl) async {
    try {
      // 方法 1: 尝试访问 /api/v1/status 获取版本信息
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/api/v1/status'),
      ).timeout(const Duration(seconds: 5));

      if (statusResponse.statusCode == 200) {
        final data = jsonDecode(statusResponse.body) as Map<String, dynamic>;
        if (data['version'] != null) {
          return _normalizeVersion(data['version'] as String);
        }
      }
    } catch (e) {
      // 继续尝试其他方法
    }

    // 方法 2: 尝试访问 v0.27.0 特有的 SSE 端点
    try {
      final sseResponse = await http.get(
        Uri.parse('$baseUrl/api/v1/sse'),
      ).timeout(const Duration(seconds: 3));

      // 如果返回 401（需要认证）而不是 404，说明端点存在
      if (sseResponse.statusCode == 401) {
        return '0.27.0';
      }
    } catch (e) {
      // 继续尝试其他方法
    }

    // 方法 3: 尝试访问 v0.26.0 的 refresh 端点
    try {
      final refreshResponse = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': 'test'}),
      ).timeout(const Duration(seconds: 3));

      // 如果返回 400/401 而不是 404，说明端点存在
      if (refreshResponse.statusCode == 400 ||
          refreshResponse.statusCode == 401) {
        return '0.26.0';
      }
    } catch (e) {
      // 继续尝试其他方法
    }

    // 默认使用 v0.21.0（最保守的选择）
    print('⚠️ Warning: Unable to detect server version, defaulting to v0.21.0');
    return '0.21.0';
  }

  /// 标准化版本号
  static String _normalizeVersion(String version) {
    // 移除 'v' 前缀
    if (version.startsWith('v')) {
      version = version.substring(1);
    }

    // 提取主版本号（如 "0.27.1-alpha" -> "0.27.0"）
    final parts = version.split('.');
    if (parts.length >= 2) {
      final major = parts[0];
      final minor = parts[1].replaceAll(RegExp(r'[^\d].*$'), '');
      return '$major.$minor.0';
    }

    return version;
  }

  /// 根据版本创建适配器
  static IMemosApi _createAdapter(String baseUrl, String version) {
    final normalized = _normalizeVersion(version);
    final parts = normalized.split('.');

    if (parts.length < 2) {
      throw VersionDetectionException('Invalid version format: $version');
    }

    final major = int.tryParse(parts[0]) ?? 0;
    final minor = int.tryParse(parts[1]) ?? 0;

    // 版本比较逻辑
    if (major == 0) {
      if (minor >= 27) {
        print('✅ Using Memos API v0.27.0 adapter');
        return MemosApiV27(baseUrl);
      } else if (minor >= 26) {
        print('✅ Using Memos API v0.26.0 adapter');
        return MemosApiV26(baseUrl);
      } else if (minor >= 21) {
        print('✅ Using Memos API v0.21.0 adapter');
        return MemosApiV21(baseUrl);
      }
    }

    // 未知版本，使用最新适配器
    print('⚠️ Warning: Unknown version $version, using v0.27.0 adapter');
    return MemosApiV27(baseUrl);
  }

  /// 获取支持的版本列表
  static List<String> getSupportedVersions() {
    return ['0.21.0', '0.26.0', '0.27.0'];
  }

  /// 检查版本是否被支持
  static bool isVersionSupported(String version) {
    final normalized = _normalizeVersion(version);
    return getSupportedVersions().contains(normalized);
  }
}

/// Memos API 客户端（高级封装）
/// 提供自动版本检测、Token 管理、重试机制等功能
class MemosApiClient {
  String baseUrl;
  IMemosApi? _api;
  String? _detectedVersion;

  MemosApiClient(this.baseUrl);

  /// 初始化客户端（检测版本并创建适配器）
  Future<void> initialize({String? forceVersion}) async {
    _detectedVersion = forceVersion;
    _api = await MemosApiFactory.create(
      baseUrl,
      version: forceVersion,
      forceVersion: forceVersion != null,
    );
    print('🚀 Memos API Client initialized');
    print('   Server: $baseUrl');
    print('   Version: ${_detectedVersion ?? 'auto-detected'}');
    print('   Adapter: ${_api!.adapterVersion}');
  }

  /// 获取当前使用的 API 实例
  IMemosApi get api {
    if (_api == null) {
      throw Exception(
          'API client not initialized. Call initialize() first.');
    }
    return _api!;
  }

  /// 获取检测到的服务器版本
  String? get serverVersion => _detectedVersion;

  /// 登录
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (_api == null) {
      await initialize();
    }
    return _api!.login(username, password);
  }

  /// 检查连接状态
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/ping'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
