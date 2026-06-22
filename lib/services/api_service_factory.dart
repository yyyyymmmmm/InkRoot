import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:inkroot/utils/network_utils.dart';

/// 自定义API错误
class ApiError implements Exception {
  ApiError(this.code, this.message);
  final String message;
  final String code;

  @override
  String toString() => message;
}

/// API服务工厂类，用于创建和管理API服务实例
class ApiServiceFactory {
  // 使用NetworkUtils提供的平台优化超时
  static Duration get _timeout => NetworkUtils.getOptimalTimeout();
  static const int _maxRetries = 3;

  /// 验证API URL是否有效
  /// 依次尝试 v0.22.0+ 端点 (workspace/profile) 和 v0.21.0 端点 (status)
  static Future<void> validateApiUrl(String url, {int retryCount = 0}) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.isAbsolute) {
        throw ApiError('INVALID_URL', '无效的服务器地址格式');
      }

      // Try public version endpoints first, then auth endpoints. Some self-hosted
      // Memos/reverse-proxy deployments hide workspace/profile but still expose
      // auth/me or auth/signin correctly.
      for (final path in ['/api/v1/workspace/profile', '/api/v1/status']) {
        try {
          final response = await NetworkUtils.optimizedGet(
            Uri.parse('$url$path'),
            headers: {'Accept': 'application/json'},
          );
          if (response.statusCode == 200) {
            return;
          }
        } on Object catch (_) {}
      }

      try {
        final response = await NetworkUtils.optimizedGet(
          Uri.parse('$url/api/v1/auth/me'),
          headers: {'Accept': 'application/json'},
        );
        if (response.statusCode == 200 ||
            response.statusCode == 401 ||
            response.statusCode == 403) {
          return;
        }
      } on Object catch (_) {}

      try {
        final response = await http
            .post(
              Uri.parse('$url/api/v1/auth/signin'),
              headers: {'Accept': 'application/json'},
              body: '{}',
            )
            .timeout(_timeout);
        if (response.statusCode != 404 && response.statusCode != 405) {
          return;
        }
      } on Object catch (_) {}

      throw ApiError('SERVER_ERROR', '无法识别 Memos 服务器，请确认地址正确');
    } on SocketException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return validateApiUrl(url, retryCount: retryCount + 1);
      }
      throw ApiError(
          'CONNECTION_ERROR',
          '无法连接到服务器，请检查：\n'
              '1. 服务器地址是否正确\n'
              '2. 服务器是否在线\n'
              '3. 网络连接是否正常');
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return validateApiUrl(url, retryCount: retryCount + 1);
      }
      throw ApiError(
          'TIMEOUT',
          '连接服务器超时，请检查：\n'
              '1. 网络连接是否正常\n'
              '2. 服务器是否响应过慢');
    } on FormatException {
      throw ApiError('INVALID_URL', '无效的服务器地址格式');
    } on Object catch (e) {
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError('UNKNOWN', '未知错误: $e');
    }
  }

  /// 验证Token是否有效
  /// 根据服务器版本选择正确的"当前用户"端点：
  ///   v0.21.0: GET /api/v1/user/me
  ///   v0.22–v0.25: POST /api/v1/auth/status
  ///   v0.26+: GET /api/v1/auth/me
  static Future<void> validateToken(
    String baseUrl,
    String token, {
    int retryCount = 0,
  }) async {
    try {
      final version = await MemosApiServiceFixed.getServerVersion(baseUrl);
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      http.Response response;
      if (version >= 26) {
        response = await http
            .get(Uri.parse('$baseUrl/api/v1/auth/me'), headers: headers)
            .timeout(_timeout);
      } else if (version >= 22) {
        response = await http
            .post(Uri.parse('$baseUrl/api/v1/auth/status'), headers: headers)
            .timeout(_timeout);
      } else {
        response = await http
            .get(Uri.parse('$baseUrl/api/v1/user/me'), headers: headers)
            .timeout(_timeout);
      }

      if (response.statusCode == 401) {
        throw ApiError('INVALID_TOKEN', 'Token无效或已过期，请重新登录');
      } else if (response.statusCode != 200) {
        throw ApiError('SERVER_ERROR', '服务器返回错误: ${response.statusCode}');
      }

      try {
        final data = jsonDecode(response.body);
        if (data == null) {
          throw ApiError('INVALID_RESPONSE', '服务器响应格式错误');
        }
      } on Object catch (e) {
        if (e is ApiError) {
          rethrow;
        }
        throw ApiError('INVALID_RESPONSE', '服务器响应格式错误');
      }
    } on Object catch (e) {
      if (retryCount < _maxRetries && e is! ApiError) {
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return validateToken(baseUrl, token, retryCount: retryCount + 1);
      }
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError('UNKNOWN', '验证Token失败: $e');
    }
  }

  /// 创建API服务实例
  static Future<dynamic> createApiService({
    required String baseUrl,
    String? token,
    int retryCount = 0,
  }) async {
    try {
      debugPrint('ApiServiceFactory: 开始创建API服务 - URL: $baseUrl');

      // 首先验证API URL
      await validateApiUrl(baseUrl);

      // 创建服务实例
      final service = MemosApiServiceFixed(baseUrl: baseUrl, token: token);

      // 如果提供了 token，用版本感知的当前用户接口验证登录态。
      // 不再用 memo 列表作为初始化硬门槛：部分自建 Memos/反向代理会让列表接口
      // 因权限、过滤或版本差异先失败，导致已登录用户被误判为“API服务初始化失败”。
      if (token != null && token.isNotEmpty) {
        await service.getUserInfo();
      }

      return service;
    } on Object catch (e) {
      if (retryCount < _maxRetries && e is! ApiError) {
        // 延迟后重试
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return createApiService(
          baseUrl: baseUrl,
          token: token,
          retryCount: retryCount + 1,
        );
      }
      if (e is ApiError) {
        rethrow;
      }
      throw ApiError('UNKNOWN', '创建API服务失败: $e');
    }
  }

  /// 规范化API URL
  static String normalizeApiUrl(String url) {
    try {
      var normalizedUrl = url;
      // 确保URL以http://或https://开头
      if (!normalizedUrl.startsWith('http://') &&
          !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      // 移除末尾的斜杠
      while (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }

      return normalizedUrl;
    } on Object {
      throw ApiError('INVALID_URL', '无效的服务器地址格式');
    }
  }
}
