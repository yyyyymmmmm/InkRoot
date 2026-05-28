import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 网络工具类，针对不同平台优化网络请求
class NetworkUtils {
  /// 获取适合当前平台的HTTP客户端
  static http.Client createOptimizedClient() {
    final client = http.Client();
    return client;
  }

  /// 创建标准HTTP客户端（允许代理）
  static http.Client createDirectClient() {
    // 使用标准客户端，允许通过代理连接
    // 这样服务器端的代理设置可以正常工作
    return http.Client();
  }

  /// 获取适合当前平台的超时时长
  static Duration getOptimalTimeout() {
    if (Platform.isAndroid) {
      // Android需要更长的超时时间，因为网络栈可能较慢
      return const Duration(seconds: 20);
    } else if (Platform.isIOS) {
      // iOS网络栈更高效，可以使用较短超时
      return const Duration(seconds: 10);
    } else {
      // 其他平台使用中等超时
      return const Duration(seconds: 15);
    }
  }

  /// 获取适合当前平台的重试次数
  static int getOptimalRetries() {
    if (Platform.isAndroid) {
      // Android可能需要更多重试
      return 3;
    } else {
      return 2;
    }
  }

  /// 针对平台优化的GET请求
  static Future<http.Response> optimizedGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final client = createOptimizedClient();
    final timeout = getOptimalTimeout();

    try {
      if (kDebugMode && Platform.isAndroid) {
        debugPrint('NetworkUtils: Android优化请求 - $uri');
        debugPrint('NetworkUtils: 超时设置 - ${timeout.inSeconds}秒');
      }

      final response = await client.get(uri, headers: headers).timeout(timeout);

      if (kDebugMode && Platform.isAndroid) {
        debugPrint('NetworkUtils: 请求完成 - 状态码: ${response.statusCode}');
      }

      return response;
    } finally {
      client.close();
    }
  }

  /// 针对平台优化的POST请求
  static Future<http.Response> optimizedPost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final client = createOptimizedClient();
    final timeout = getOptimalTimeout();

    try {
      if (kDebugMode && Platform.isAndroid) {
        debugPrint('NetworkUtils: Android优化POST请求 - $uri');
      }

      final response = await client
          .post(
            uri,
            headers: headers,
            body: body,
            encoding: encoding,
          )
          .timeout(timeout);

      return response;
    } finally {
      client.close();
    }
  }

  /// 专门用于引用关系的POST请求（允许代理）
  static Future<http.Response> directPost(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final client = createDirectClient();
    final timeout = getOptimalTimeout();

    try {
      final response = await client
          .post(
            uri,
            headers: headers,
            body: body,
            encoding: encoding,
          )
          .timeout(timeout);

      return response;
    } finally {
      client.close();
    }
  }

  /// 标准DELETE请求（允许代理）
  static Future<http.Response> directDelete(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final client = createDirectClient();
    final timeout = getOptimalTimeout();

    try {
      final response = await client
          .delete(
            uri,
            headers: headers,
          )
          .timeout(timeout);

      return response;
    } finally {
      client.close();
    }
  }
}
