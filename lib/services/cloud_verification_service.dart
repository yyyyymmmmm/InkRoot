import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/models/cloud_verification_models.dart';

/// 星河云验证服务
class CloudVerificationService {
  /// 获取应用配置
  Future<CloudAppConfigResponse?> fetchAppConfig() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final check = _generateCheck('ini', timestamp);

      final uri = Uri.parse(AppConfig.cloudVerificationUrl).replace(
        queryParameters: {
          'api': 'ini',
          'app': AppConfig.appId,
          'time': timestamp.toString(),
          'check': check,
        },
      );

      debugPrint('CloudVerification: 请求应用配置 - $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('CloudVerification: 应用配置响应状态码 - ${response.statusCode}');
      debugPrint('CloudVerification: 应用配置响应内容 - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CloudAppConfigResponse.fromJson(data);
      } else {
        debugPrint('获取应用配置失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('获取应用配置异常: $e');
      return null;
    }
  }

  /// 获取应用公告
  Future<CloudNoticeResponse?> fetchAppNotice() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final check = _generateCheck('notice', timestamp);

      final uri = Uri.parse(AppConfig.cloudVerificationUrl).replace(
        queryParameters: {
          'api': 'notice',
          'app': AppConfig.appId,
          'time': timestamp.toString(),
          'check': check,
        },
      );

      debugPrint('CloudVerification: 请求应用公告 - $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('CloudVerification: 应用公告响应状态码 - ${response.statusCode}');
      debugPrint('CloudVerification: 应用公告响应内容 - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CloudNoticeResponse.fromJson(data);
      } else {
        debugPrint('获取应用公告失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('获取应用公告异常: $e');
      return null;
    }
  }

  /// 生成校验值
  String _generateCheck(String api, int timestamp) {
    // 按照星河云验证的规则生成check值
    // check = md5(api + app + time + key)
    final source =
        api + AppConfig.appId + timestamp.toString() + AppConfig.appKey;
    final bytes = utf8.encode(source);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 比较版本号
  bool isVersionNewer(String currentVersion, String latestVersion) {
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final latestParts = latestVersion.split('.').map(int.parse).toList();

      final maxLength = currentParts.length > latestParts.length
          ? currentParts.length
          : latestParts.length;

      for (var i = 0; i < maxLength; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) {
          return true;
        } else if (latestPart < currentPart) {
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('版本号比较失败: $e');
      return false;
    }
  }
}
