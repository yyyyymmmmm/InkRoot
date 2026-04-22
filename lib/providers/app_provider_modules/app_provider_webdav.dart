import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/models/webdav_config.dart';
import 'package:inkroot/services/webdav_service.dart';
import 'package:inkroot/services/webdav_sync_engine.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WebDAV 同步功能模块
///
/// 此 mixin 封装了所有 WebDAV 相关的功能，包括：
/// - WebDAV 配置管理（加载、保存、更新）
/// - WebDAV 服务初始化和销毁
/// - 连接测试
/// - 同步、备份、恢复操作
/// - 自动备份定时器管理
mixin AppProviderWebDav on ChangeNotifier {
  // ==================== 状态变量 ====================

  // 🚀 WebDAV 同步相关
  WebDavConfig _webDavConfig = const WebDavConfig();
  WebDavService? _webDavService;
  WebDavSyncEngine? _webDavSyncEngine;
  Timer? _webDavBackupTimer; // WebDAV 定时备份计时器
  bool _hasPerformedStartupBackup = false; // 是否已执行过启动备份

  // ==================== Getters ====================

  /// 获取 WebDAV 配置
  WebDavConfig get webDavConfig => _webDavConfig;

  /// WebDAV 是否已启用
  bool get isWebDavEnabled => _webDavConfig.enabled;

  // ==================== 抽象属性（由主类提供） ====================

  /// 数据库服务（需要在主类中实现）
  DatabaseService get databaseService;

  // ==================== 配置管理 ====================

  /// 加载 WebDAV 配置
  Future<void> loadWebDavConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('webdav_config');

      if (configJson != null && configJson.isNotEmpty) {
        _webDavConfig = WebDavConfig.fromJson(jsonDecode(configJson));

        // 如果启用了 WebDAV，初始化服务
        if (_webDavConfig.enabled && _webDavConfig.isValid) {
          await _initializeWebDavService();
        }
      }
    } catch (e) {}
  }

  /// 更新 WebDAV 配置
  Future<void> updateWebDavConfig(WebDavConfig config, {bool skipInitialize = false}) async {
    try {
      _webDavConfig = config;

      // 保存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('webdav_config', jsonEncode(config.toJson()));

      // 🔧 改进：保存配置时不立即连接服务器，避免网络问题导致保存失败
      // 只在明确需要时才初始化（如执行备份/恢复操作）
      if (!skipInitialize) {
        // 重新初始化服务（可能抛出网络异常）
        if (config.enabled && config.isValid) {
          await _initializeWebDavService();
        } else {
          _disposeWebDavService();
        }
      } else {
        // 🎯 大厂标准：跳过初始化时，不清理服务，但要重新配置定时备份
        // 避免在更新时间戳等操作时意外停止正在运行的定时备份
        if (config.enabled && config.autoSync) {
          // 如果启用了定时备份，重新启动定时器（使用新配置）
          _startWebDavAutoBackup();
        } else {
          // 如果禁用了定时备份，停止定时器
          _stopWebDavAutoBackup();
        }
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== 服务管理 ====================

  /// 初始化 WebDAV 服务
  Future<void> _initializeWebDavService() async {
    try {
      // 🔧 释放旧服务（但不重置启动备份标志）
      // 避免频繁初始化导致重复备份
      _disposeWebDavService(resetStartupFlag: false);

      // 创建新服务
      _webDavService = WebDavService();
      await _webDavService!.initialize(_webDavConfig);

      // 创建同步引擎
      _webDavSyncEngine = WebDavSyncEngine(_webDavService!, databaseService);
      await _webDavSyncEngine!.initialize();

      // 🚀 如果启用了定时备份，启动定时备份
      if (_webDavConfig.autoSync) {
        _startWebDavAutoBackup();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 释放 WebDAV 服务
  void _disposeWebDavService({bool resetStartupFlag = false}) {
    // 🔧 符合用户体验：默认不重置启动备份标志
    // "启动备份"应该只在应用真正启动时触发一次，而不是每次重新初始化服务时都触发
    // 避免热重载、页面切换、配置修改时重复备份
    _stopWebDavAutoBackup(resetStartupFlag: resetStartupFlag);
    _webDavService?.dispose();
    _webDavService = null;
    _webDavSyncEngine = null;
  }

  // ==================== 连接测试 ====================

  /// 测试 WebDAV 连接
  Future<bool> testWebDavConnection(WebDavConfig config) async {
    try {
      final testService = WebDavService();
      await testService.initialize(config);
      final result = await testService.testConnection();
      testService.dispose();

      return result;
    } catch (e) {
      return false;
    }
  }

  // ==================== 同步操作 ====================

  /// 执行 WebDAV 同步
  Future<SyncStats?> syncWithWebDav() async {
    if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
      return null;
    }

    if (_webDavSyncEngine == null) {
      await _initializeWebDavService();
    }

    try {
      final stats = await _webDavSyncEngine!.sync();

      // 同步完成后重新加载笔记（可能会导致 UI 闪烁）
      // 注意：loadNotesFromLocal 会触发 notifyListeners，可能干扰正在创建笔记的流程
      await loadNotesFromLocal();

      // 更新最后同步时间（跳过初始化，只更新时间戳）
      final updatedConfig = _webDavConfig.copyWith(
        lastSyncTime: DateTime.now(),
      );
      await updateWebDavConfig(updatedConfig, skipInitialize: true);

      return stats;
    } catch (e) {
      rethrow;
    }
  }

  /// 执行 WebDAV 完整备份（单向上传）
  ///
  /// [onProgress] 进度回调：(progress, message) => void
  Future<SyncStats?> backupWithWebDav({
    void Function(double progress, String message)? onProgress,
  }) async {
    if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
      return null;
    }

    if (_webDavSyncEngine == null) {
      await _initializeWebDavService();
    }

    try {
      final stats = await _webDavSyncEngine!.backup(
        onProgress: onProgress,
      );

      // 更新最后备份时间（跳过初始化，只更新时间戳）
      final updatedConfig = _webDavConfig.copyWith(
        lastSyncTime: DateTime.now(),
      );
      await updateWebDavConfig(updatedConfig, skipInitialize: true);

      return stats;
    } catch (e) {
      rethrow;
    }
  }

  /// 从 WebDAV 恢复数据（单向下载）
  ///
  /// [onProgress] 进度回调：(progress, message) => void
  Future<SyncStats?> restoreFromWebDav({
    void Function(double progress, String message)? onProgress,
  }) async {
    if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
      return null;
    }

    if (_webDavSyncEngine == null) {
      await _initializeWebDavService();
    }

    try {
      final stats = await _webDavSyncEngine!.restore(
        onProgress: onProgress,
      );

      // 恢复完成后重新加载笔记
      await loadNotesFromLocal();

      // 更新最后同步时间（跳过初始化，只更新时间戳）
      final updatedConfig = _webDavConfig.copyWith(
        lastSyncTime: DateTime.now(),
      );
      await updateWebDavConfig(updatedConfig, skipInitialize: true);

      return stats;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== 自动备份管理 ====================

  /// 启动 WebDAV 自动备份（参考坚果云、Dropbox等主流软件逻辑）
  void _startWebDavAutoBackup() {
    // 🔧 先停止旧的定时器（不重置启动备份标志）
    // 这样在配置修改、热重载等场景下不会重复触发"启动备份"
    _stopWebDavAutoBackup();

    if (!_webDavConfig.autoSync || !_webDavConfig.enabled) {
      return;
    }

    final interval = _webDavConfig.autoSyncInterval;

    if (interval == 0) {
      // 📱 "启动备份"模式：只在应用真正启动时执行一次
      // ✅ 符合用户预期：启动应用 = 备份一次
      // ❌ 不符合预期：热重载、配置修改、页面切换 = 不应该再次备份
      if (!_hasPerformedStartupBackup) {
        if (kDebugMode) {
          debugPrint('AppProvider: WebDAV 启动备份 - 应用首次启动，立即执行');
        }
        _performWebDavBackup();
        _hasPerformedStartupBackup = true;
      } else {
        if (kDebugMode) {
          debugPrint('AppProvider: WebDAV 启动备份 - 本次会话已执行过，跳过');
        }
      }
    } else {
      // 🚀 大厂标准：定时备份 - 智能判断上次备份时间
      final duration = Duration(minutes: interval);
      final lastBackup = _webDavConfig.lastSyncTime;
      final now = DateTime.now();

      if (kDebugMode) {
        debugPrint('AppProvider: WebDAV 启动定时备份 - 间隔 $interval 分钟');
      }

      // ✅ 智能判断：只有距离上次备份超过间隔时才立即执行
      // 避免频繁修改配置导致频繁备份
      if (lastBackup == null) {
        // 首次启用，立即执行一次
        if (kDebugMode) {
          debugPrint('AppProvider: WebDAV 首次启用定时备份 - 立即执行');
        }
        _performWebDavBackup();
      } else {
        final elapsed = now.difference(lastBackup);
        if (elapsed >= duration) {
          // 距离上次备份已超过间隔，立即执行
          if (kDebugMode) {
            debugPrint('AppProvider: WebDAV 距上次备份已 ${elapsed.inMinutes} 分钟 - 立即执行');
          }
          _performWebDavBackup();
        } else {
          // 距离上次备份未超过间隔，跳过立即执行
          final remaining = duration - elapsed;
          if (kDebugMode) {
            debugPrint('AppProvider: WebDAV 距上次备份仅 ${elapsed.inMinutes} 分钟 - 跳过立即执行，${remaining.inMinutes} 分钟后执行');
          }
        }
      }

      // 启动定时器
      _webDavBackupTimer = Timer.periodic(duration, (_) {
        _performWebDavBackup();
      });
    }
  }

  /// 停止 WebDAV 自动备份
  void _stopWebDavAutoBackup({bool resetStartupFlag = false}) {
    _webDavBackupTimer?.cancel();
    _webDavBackupTimer = null;

    // ✅ 只有在明确需要重置时才重置启动备份标志
    // 避免每次启动定时器都触发一次备份
    if (resetStartupFlag) {
      _hasPerformedStartupBackup = false;
    }

    if (kDebugMode) {
      debugPrint('AppProvider: WebDAV 自动备份已停止');
    }
  }

  /// 执行 WebDAV 备份（内部方法，静默执行）
  Future<void> _performWebDavBackup() async {
    try {
      if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
        return;
      }

      if (kDebugMode) {
        debugPrint('AppProvider: 开始执行 WebDAV 自动备份');
      }

      final stats = await backupWithWebDav();

      if (kDebugMode) {
        debugPrint('AppProvider: WebDAV 自动备份完成 - $stats');
      }

      // 🚀 大厂标准：更新上次备份时间，用于智能判断
      // 注意：backupWithWebDav() 内部已经更新了 lastSyncTime
      // 这里只是确保逻辑清晰
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: WebDAV 自动备份失败: $e');
      }
      // 静默失败，不影响用户使用
    }
  }

  // ==================== 抽象方法（由主类实现） ====================

  /// 从本地数据库加载笔记（需要在主类中实现）
  Future<void> loadNotesFromLocal();
}
