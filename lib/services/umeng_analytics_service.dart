import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';

/// 友盟统计服务
/// ⚠️ 注意：仅在Android平台启用，iOS平台已禁用（符合App Store审核要求）
class UmengAnalyticsService {
  static final MethodChannel _channel =
      MethodChannel(AppConfig.channelUmeng);

  static bool _initialized = false;

  /// 初始化友盟统计
  ///
  /// 注意：
  /// 1. 只有用户同意隐私政策后才能调用此方法
  /// 2. 仅在Android平台有效，iOS平台会直接返回false
  static Future<bool> init() async {
    // ⚠️ iOS平台不使用友盟统计
    if (Platform.isIOS) {
      debugPrint('⚠️ [UmengAnalytics] iOS平台已禁用友盟统计（符合App Store审核要求）');
      return false;
    }
    
    if (_initialized) {
      debugPrint('⚠️ 友盟统计已初始化，跳过重复初始化');
      return true;
    }

    try {
      debugPrint('🔄 [UmengAnalytics] 开始初始化友盟统计...');
      debugPrint('🔄 [UmengAnalytics] 平台: Android');

      final result = await _channel.invokeMethod('init');
      _initialized = result == true;

      if (_initialized) {
        debugPrint('✅ [UmengAnalytics] 友盟统计初始化成功！');
      } else {
        debugPrint('❌ [UmengAnalytics] 友盟统计初始化失败（返回值: $result）');
      }

      return _initialized;
    } on PlatformException catch (e) {
      debugPrint('❌ [UmengAnalytics] 友盟统计初始化失败（平台异常）');
      debugPrint('   错误代码: ${e.code}');
      debugPrint('   错误信息: ${e.message}');
      debugPrint('   错误详情: ${e.details}');
      debugPrint('   ⚠️  请检查：');
      debugPrint('   1. Android: build.gradle 中是否添加了友盟依赖');
      return false;
    } catch (e) {
      debugPrint('❌ [UmengAnalytics] 友盟统计初始化失败（未知错误）: $e');
      return false;
    }
  }

  /// 记录自定义事件
  ///
  /// [eventId] 事件ID，例如：'button_click', 'page_view'
  /// 注意：iOS平台会静默忽略，不会记录任何事件
  static Future<void> onEvent(String eventId) async {
    // ⚠️ iOS平台不记录友盟事件
    if (Platform.isIOS) {
      return;
    }
    
    if (!_initialized) {
      debugPrint('⚠️ [UmengAnalytics] 友盟统计未初始化，跳过事件记录: $eventId');
      debugPrint('   请先调用 UmengAnalyticsService.init() 初始化友盟统计');
      return;
    }

    try {
      await _channel.invokeMethod('onEvent', eventId);
      debugPrint('📊 [UmengAnalytics] 友盟事件已记录: $eventId');
    } on PlatformException catch (e) {
      debugPrint('❌ [UmengAnalytics] 友盟事件记录失败（平台异常）: $eventId');
      debugPrint('   错误代码: ${e.code}');
      debugPrint('   错误信息: ${e.message}');
    } catch (e) {
      debugPrint('❌ [UmengAnalytics] 友盟事件记录失败: $eventId - $e');
    }
  }

  /// 记录带参数的自定义事件
  ///
  /// [eventId] 事件ID
  /// [params] 事件参数，例如：{'button_name': 'login', 'screen': 'home'}
  /// 注意：iOS平台会静默忽略，不会记录任何事件
  static Future<void> onEventWithMap(
    String eventId,
    Map<String, String> params,
  ) async {
    // ⚠️ iOS平台不记录友盟事件
    if (Platform.isIOS) {
      return;
    }
    
    if (!_initialized) {
      debugPrint('⚠️ 友盟统计未初始化，跳过事件记录: $eventId');
      return;
    }

    try {
      await _channel.invokeMethod('onEventWithMap', {
        'eventId': eventId,
        'params': params,
      });
      debugPrint('📊 友盟事件已记录: $eventId, 参数: $params');
    } catch (e) {
      debugPrint('❌ 友盟事件记录失败: $e');
    }
  }

  /// 常用事件 - 应用启动
  static Future<void> onAppStart() async {
    await onEvent('app_start');
  }

  /// 常用事件 - 用户登录
  static Future<void> onUserLogin() async {
    await onEvent('user_login');
  }

  /// 常用事件 - 创建笔记
  static Future<void> onNoteCreated() async {
    await onEvent('note_created');
  }

  /// 常用事件 - 编辑笔记
  static Future<void> onNoteEdited() async {
    await onEvent('note_edited');
  }

  /// 常用事件 - 删除笔记
  static Future<void> onNoteDeleted() async {
    await onEvent('note_deleted');
  }

  /// 常用事件 - 同步笔记
  static Future<void> onNoteSynced(String syncType) async {
    await onEventWithMap('note_synced', {'sync_type': syncType});
  }

  /// 常用事件 - 功能使用
  static Future<void> onFeatureUsed(String featureName) async {
    await onEventWithMap('feature_used', {'feature': featureName});
  }

  /// 是否已初始化
  static bool get isInitialized => _initialized;
}
