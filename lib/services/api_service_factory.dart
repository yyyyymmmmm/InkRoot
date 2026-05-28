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

      // Try the v0.22.0+ endpoint first, then fall back to the old /status
      for (final path in ['/api/v1/workspace/profile', '/api/v1/status']) {
        try {
          final response = await NetworkUtils.optimizedGet(
            Uri.parse('$url$path'),
            headers: {'Accept': 'application/json'},
          );
          if (response.statusCode == 200) return;
        } catch (_) {}
      }

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
    } catch (e) {
      if (e is ApiError) rethrow;
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
        if (data == null) throw ApiError('INVALID_RESPONSE', '服务器响应格式错误');
      } catch (e) {
        if (e is ApiError) rethrow;
        throw ApiError('INVALID_RESPONSE', '服务器响应格式错误');
      }
    } catch (e) {
      if (retryCount < _maxRetries && e is! ApiError) {
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return validateToken(baseUrl, token, retryCount: retryCount + 1);
      }
      if (e is ApiError) rethrow;
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

      // 如果提供了token，验证token
      if (token != null) {
        await validateToken(baseUrl, token);
      }

      // 创建服务实例
      final service = MemosApiServiceFixed(baseUrl: baseUrl, token: token);

      // 验证服务是否正常工作（结果仅用于测试连通性）
      await service.getMemos(pageSize: 1);

      return service;
    } catch (e) {
      if (retryCount < _maxRetries && e is! ApiError) {
        // 延迟后重试
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return createApiService(
          baseUrl: baseUrl,
          token: token,
          retryCount: retryCount + 1,
        );
      }
      if (e is ApiError) rethrow;
      throw ApiError('UNKNOWN', '创建API服务失败: $e');
    }
  }

  /// 规范化API URL
  static String normalizeApiUrl(String url) {
    try {
      // 确保URL以http://或https://开头
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      // 移除末尾的斜杠
      while (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      return url;
    } catch (e) {
      throw ApiError('INVALID_URL', '无效的服务器地址格式');
    }
  }
}
