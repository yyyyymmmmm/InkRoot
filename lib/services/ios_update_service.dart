import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// iOS应用更新服务（符合App Store审核要求）
/// 
/// Apple允许的做法：
/// ✅ 检查版本号
/// ✅ 提示用户有新版本
/// ✅ 引导用户去App Store更新
/// 
/// Apple禁止的做法：
/// ❌ 下载安装包
/// ❌ 热更新代码
/// ❌ 强制更新导致应用无法使用
class iOSUpdateService {
  /// 检查App Store上是否有新版本
  /// 
  /// 使用iTunes API查询版本信息
  /// 文档：https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/
  static Future<AppStoreVersionInfo?> checkAppStoreVersion() async {
    if (!Platform.isIOS) {
      return null; // 仅iOS平台使用
    }

    try {
      // 如果没有配置App Store ID，跳过检查
      if (AppConfig.appStoreId.isEmpty) {
        debugPrint('⚠️ [iOSUpdate] 未配置App Store ID，跳过版本检查');
        return null;
      }

      // 使用iTunes API查询应用信息
      final url = Uri.parse(
        'https://itunes.apple.com/lookup?id=${AppConfig.appStoreId}&country=cn',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['resultCount'] > 0) {
          final appInfo = data['results'][0];
          
          return AppStoreVersionInfo(
            version: appInfo['version'] ?? '',
            releaseNotes: appInfo['releaseNotes'] ?? '',
            trackViewUrl: appInfo['trackViewUrl'] ?? '',
            currentVersionReleaseDate: appInfo['currentVersionReleaseDate'] ?? '',
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ [iOSUpdate] 检查App Store版本失败: $e');
      return null;
    }
  }

  /// 比较版本号
  /// 
  /// 返回：
  /// - true: 有新版本
  /// - false: 当前是最新版本或版本号格式错误
  static bool hasNewVersion(String currentVersion, String appStoreVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final store = _parseVersion(appStoreVersion);

      // 比较主版本号
      if (store[0] > current[0]) return true;
      if (store[0] < current[0]) return false;

      // 比较次版本号
      if (store[1] > current[1]) return true;
      if (store[1] < current[1]) return false;

      // 比较修订版本号
      if (store[2] > current[2]) return true;

      return false;
    } catch (e) {
      debugPrint('⚠️ [iOSUpdate] 版本号比较失败: $e');
      return false;
    }
  }

  /// 解析版本号字符串
  /// 例如：1.0.6 -> [1, 0, 6]
  static List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.parse(parts.isNotEmpty ? parts[0] : '0'),
      int.parse(parts.length > 1 ? parts[1] : '0'),
      int.parse(parts.length > 2 ? parts[2] : '0'),
    ];
  }

  /// 打开App Store应用页面
  /// 
  /// 注意：必须引导用户手动去App Store更新，不能自动下载安装
  static Future<void> openAppStore() async {
    if (AppConfig.appStoreId.isEmpty) {
      debugPrint('⚠️ [iOSUpdate] 未配置App Store ID');
      return;
    }

    // App Store链接
    final url = Uri.parse(
      'https://apps.apple.com/cn/app/id${AppConfig.appStoreId}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('❌ [iOSUpdate] 无法打开App Store');
      }
    } catch (e) {
      debugPrint('❌ [iOSUpdate] 打开App Store失败: $e');
    }
  }

  /// 显示更新提示对话框（符合Apple规范）
  /// 
  /// 特点：
  /// - 用户可以选择"稍后"（不能强制更新）
  /// - 点击"更新"跳转到App Store
  /// - 不阻止用户继续使用应用
  static Future<void> showUpdateDialog(
    BuildContext context,
    AppStoreVersionInfo versionInfo,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true, // 允许点击外部关闭
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 8),
            Text('发现新版本'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最新版本：${versionInfo.version}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (versionInfo.releaseNotes.isNotEmpty) ...[
              const Text(
                '更新内容：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  versionInfo.releaseNotes,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // ✅ 必须提供"稍后"选项，不能强制更新
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppStore();
            },
            child: const Text('前往更新'),
          ),
        ],
      ),
    );
  }
}

/// App Store版本信息
class AppStoreVersionInfo {
  final String version;
  final String releaseNotes;
  final String trackViewUrl;
  final String currentVersionReleaseDate;

  AppStoreVersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.trackViewUrl,
    required this.currentVersionReleaseDate,
  });
}

