import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/models/cloud_verification_models.dart';
import 'package:inkroot/services/cloud_verification_service.dart';

/// 云验证功能 Mixin
///
/// 负责管理应用的云验证相关功能：
/// - 加载和缓存云端配置数据
/// - 检查应用更新（Android使用自有服务器，iOS使用iTunes API）
/// - 获取云端公告
/// - 版本信息管理
mixin AppProviderCloudVerification on ChangeNotifier {
  // ===== 云验证相关服务 =====
  final CloudVerificationService _cloudService = CloudVerificationService();

  // ===== 云验证相关状态变量 =====

  /// 云端应用配置数据
  CloudAppConfigData? _cloudAppConfig;

  /// 云端公告数据
  CloudNoticeData? _cloudNotice;

  /// 上次加载云验证数据的时间 🚀
  DateTime? _lastCloudVerificationTime;

  /// 缓存5分钟 🚀
  static const Duration _cloudVerificationCacheDuration =
      Duration(minutes: 5);

  // ===== Getters =====

  /// 获取云端应用配置
  CloudAppConfigData? get cloudAppConfig => _cloudAppConfig;

  /// 获取云端公告
  CloudNoticeData? get cloudNotice => _cloudNotice;

  // ===== 云验证相关方法 =====

  /// 加载云验证数据（配置和公告）
  Future<void> _loadCloudVerificationData() async {
    try {
      // 🚀 缓存检查：如果5分钟内已加载过，直接跳过
      if (_lastCloudVerificationTime != null) {
        final duration = DateTime.now().difference(_lastCloudVerificationTime!);
        if (duration < _cloudVerificationCacheDuration) {
          return;
        }
      }

      if (kDebugMode) debugPrint('AppProvider: 开始加载云验证数据');

      // 并行加载配置和公告
      final futures = await Future.wait([
        _cloudService.fetchAppConfig(),
        _cloudService.fetchAppNotice(),
      ]);

      final configResponse = futures[0] as CloudAppConfigResponse?;
      final noticeResponse = futures[1] as CloudNoticeResponse?;

      // 处理配置响应
      if (configResponse != null && configResponse.isSuccess) {
        _cloudAppConfig = configResponse.msg;

        // 检查是否需要更新
        await _checkCloudUpdate();
      } else {
        if (kDebugMode) debugPrint('AppProvider: 云配置加载失败');
      }

      // 处理公告响应
      if (noticeResponse != null && noticeResponse.isSuccess) {
        _cloudNotice = noticeResponse.msg;
        // 云公告加载成功
      } else {
        // 云公告加载失败
      }

      // 🚀 更新缓存时间
      _lastCloudVerificationTime = DateTime.now();
    } catch (e) {
      // 加载云验证数据异常
    }
  }

  /// 检查云端更新
  ///
  /// iOS: 通过iTunes API检查App Store版本（符合Apple规范）
  /// Android: 通过自有服务器检查版本
  Future<void> _checkCloudUpdate() async {
    try {
      // ⚠️ iOS平台使用iTunes API，不使用自有服务器
      if (Platform.isIOS) {
        // iOS通过App Store检查更新（在需要时调用）
        // 这里不自动检查，避免启动时频繁访问App Store API
        return;
      }

      // Android平台继续使用原有逻辑
      if (_cloudAppConfig == null) return;

      // 获取当前应用版本
      const currentVersion = Config.AppConfig.appVersion;

      // 比较版本
      final hasUpdate = _cloudService.isVersionNewer(
        currentVersion,
        _cloudAppConfig!.version,
      );

      if (hasUpdate || _cloudAppConfig!.isForceUpdate) {
        debugPrint(
          'AppProvider: 发现云端更新 - 当前版本: $currentVersion, 最新版本: ${_cloudAppConfig!.version}',
        );
        debugPrint('AppProvider: 强制更新: ${_cloudAppConfig!.isForceUpdate}');
      }
    } catch (e) {
      debugPrint('AppProvider: 检查云端更新异常: $e');
    }
  }

  /// 手动刷新云验证数据
  Future<void> refreshCloudData() async {
    await _loadCloudVerificationData();
    notifyListeners();
  }

  /// 获取云端公告内容列表
  List<String> getCloudNotices() => _cloudNotice?.formattedNotices ?? [];

  /// 获取云端版本信息列表
  List<String> getCloudVersionInfo() =>
      _cloudAppConfig?.formattedVersionInfo ?? [];

  /// 是否有云端更新
  Future<bool> hasCloudUpdate() async {
    try {
      if (_cloudAppConfig == null) return false;

      const currentVersion = Config.AppConfig.appVersion;

      return _cloudService.isVersionNewer(
        currentVersion,
        _cloudAppConfig!.version,
      );
    } catch (e) {
      debugPrint('AppProvider: 检查是否有云端更新异常: $e');
      return false;
    }
  }

  /// 是否强制更新
  bool isForceCloudUpdate() => _cloudAppConfig?.isForceUpdate ?? false;
}
