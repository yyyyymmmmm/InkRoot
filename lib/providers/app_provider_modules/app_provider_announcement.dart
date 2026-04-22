import 'package:flutter/foundation.dart';
import 'package:inkroot/models/announcement_model.dart';
import 'package:inkroot/models/cloud_verification_models.dart';
import 'package:inkroot/services/announcement_service.dart';
import 'package:inkroot/services/reminder_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 公告管理 Mixin
///
/// 负责处理应用公告相关的所有功能：
/// - 公告列表管理
/// - 未读数量统计
/// - 已读状态管理
/// - 云端公告同步
mixin AppProviderAnnouncement on ChangeNotifier {
  // ===== 需要在主 Provider 中提供的依赖 =====

  /// 子类需要提供的服务依赖
  AnnouncementService get announcementService;
  ReminderNotificationService get reminderNotificationService;

  /// 子类需要提供的云验证数据访问
  CloudNoticeData? get cloudNotice;

  /// 子类需要提供的刷新云数据方法
  Future<void> refreshCloudData();

  /// 子类需要提供的缓存时间和持续时间
  DateTime? get lastCloudVerificationTime;
  Duration get cloudVerificationCacheDuration;

  // ===== 公告相关状态变量 =====

  /// 未读公告数量
  int _unreadAnnouncementsCount = 0;

  /// 公告列表
  final List<Announcement> _announcements = [];

  // ===== Getters =====

  /// 获取未读公告数量
  int get unreadAnnouncementsCount => _unreadAnnouncementsCount;

  /// 获取公告列表
  List<Announcement> get announcements => _announcements;

  // ===== 公告初始化方法 =====

  /// 初始化通知并检查更新
  Future<void> initializeAnnouncements() async {
    try {
      // 使用云验证数据检查更新
      await checkForUpdatesOnStartup();

      // 🔄 使用新的状态管理机制设置通知数量
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('初始化通知异常: $e');
    }
  }

  /// 启动时检查更新
  ///
  /// 注意：这个方法需要在主 Provider 中实现或提供相应的依赖
  Future<void> checkForUpdatesOnStartup() async {
    // 由主 Provider 实现
    debugPrint('checkForUpdatesOnStartup 需要在主 Provider 中实现');
  }

  // ===== 公告刷新方法 =====

  /// 刷新未读通知数量
  Future<void> refreshUnreadAnnouncementsCount() async {
    try {
      // 🚀 不立即刷新云验证数据，而是检查缓存
      // 只有当缓存过期时才刷新（避免启动时网络请求）
      if (lastCloudVerificationTime == null ||
          DateTime.now().difference(lastCloudVerificationTime!) >
              cloudVerificationCacheDuration) {
        await refreshCloudData();
      }

      // 🔄 使用新的状态管理机制更新通知数量
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('刷新未读通知数量异常: $e');
    }
  }

  /// 刷新公告列表
  Future<void> refreshAnnouncements() async {
    await refreshCloudData();

    // 🚀 大厂标准：从云验证公告数据创建 Announcement 对象（不拆分，保持完整）
    _announcements.clear();
    if (cloudNotice?.appGg.isNotEmpty ?? false) {
      // ✅ 保持应用公告为一条完整通知，不拆分
      final announcement = Announcement(
        id: 'cloud_notice_${DateTime.now().millisecondsSinceEpoch}',
        title: '应用公告',
        content: cloudNotice!.appGg, // 完整内容，不拆分
        type: 'info', // 使用 info 类型，以便在登录页面显示（update 类型专用于版本更新）
        publishDate: DateTime.now(),
      );
      _announcements.add(announcement);
    }
    notifyListeners();
  }

  // ===== 公告已读状态管理方法 =====

  /// 标记单个公告为已读
  Future<void> markAnnouncementAsRead(String id) async {
    try {
      // 🔄 新实现：真正的已读状态管理
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      if (!readNotifications.contains(id)) {
        readNotifications.add(id);
        await prefs.setStringList('read_notifications', readNotifications);
        if (kDebugMode) debugPrint('AppProvider: 通知 $id 已标记为已读');
      }

      // 重新计算未读数量
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 标记通知已读失败: $e');
    }
  }

  /// 标记所有公告为已读
  Future<void> markAllAnnouncementsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      // 🔄 新实现：标记当前所有通知为已读
      final currentAnnouncementId = cloudNotice?.appGg ?? '';
      if (currentAnnouncementId.isNotEmpty &&
          !readNotifications.contains(currentAnnouncementId)) {
        readNotifications.add(currentAnnouncementId);
        await prefs.setStringList('read_notifications', readNotifications);
        if (kDebugMode) debugPrint('AppProvider: 所有通知已标记为已读');
      }

      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 标记所有通知已读失败: $e');
    }
  }

  /// 检查公告是否已读
  Future<bool> isAnnouncementRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];
      return readNotifications.contains(id);
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 检查通知已读状态失败: $e');
      return false;
    }
  }

  // ===== 私有辅助方法 =====

  /// 🆕 统一的未读数量更新方法（包括系统公告和提醒通知）
  Future<void> _updateUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      final currentAnnouncementId = cloudNotice?.appGg ?? '';

      // 🔥 计算系统公告未读数量
      var systemUnreadCount = 0;
      if (currentAnnouncementId.isNotEmpty &&
          !readNotifications.contains(currentAnnouncementId)) {
        systemUnreadCount = 1;
      }

      // 🔥 计算提醒通知未读数量
      var reminderUnreadCount = 0;
      try {
        reminderUnreadCount =
            await reminderNotificationService.getUnreadCount();
      } catch (e) {
        if (kDebugMode) debugPrint('AppProvider: 获取提醒通知未读数量失败: $e');
      }

      // 🔥 合并两种通知的未读数量
      _unreadAnnouncementsCount = systemUnreadCount + reminderUnreadCount;
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 更新未读数量失败: $e');
      _unreadAnnouncementsCount = 0;
    }
  }
}
