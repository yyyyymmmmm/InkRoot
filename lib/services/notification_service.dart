import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/reminder_notification_model.dart';
import 'package:inkroot/services/reminder_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

/// 通知服务 - 使用原生Android AlarmManager实现
abstract class NotificationAppProviderBridge {
  Future<void> cancelNoteReminder(String noteId);

  Future<void> refreshUnreadAnnouncementsCount();
}

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // 🔥 原生Android AlarmManager Method Channel
  static const platform = MethodChannel(AppConfig.channelNativeAlarm);

  // 通知点击回调
  Function(int noteId)? _onNotificationTapped;

  // 🔥 简单方案：自己维护提醒列表和定时器
  final Map<int, Timer> _activeTimers = {};
  final Map<int, DateTime> _scheduledReminders = {};

  // 🔥 noteId hashCode到原始字符串ID的映射（用于通知点击查找笔记）
  static final Map<int, String> noteIdMapping = {};

  // 🔥 全局GoRouter引用，用于通知点击跳转
  static GoRouter? _globalRouter;
  static NotificationAppProviderBridge?
      _globalAppProvider; // 🔥 全局AppProvider引用

  // 🔥 提醒通知服务
  final ReminderNotificationService _reminderNotificationService =
      ReminderNotificationService();

  /// 设置全局GoRouter引用
  static void setGlobalRouter(GoRouter router) {
    _globalRouter = router;
  }

  /// 设置全局AppProvider引用
  static void setGlobalAppProvider(NotificationAppProviderBridge appProvider) {
    _globalAppProvider = appProvider;
  }

  /// 设置通知点击回调
  void setNotificationTapCallback(Function(int noteId) callback) {
    _onNotificationTapped = callback;
  }

  /// 清理无效的测试提醒（noteId=0等）
  Future<void> clearInvalidReminders() async {
    try {
      // 🔥 取消 noteId=0 的测试提醒（Android AlarmManager）
      if (Platform.isAndroid) {
        try {
          await platform.invokeMethod('cancelAlarm', {'noteId': 0});
        } on PlatformException {
          // The test alarm may not exist on this device.
        }
      }

      // 🔥 取消 flutter_local_notifications 中的 noteId=0 通知
      await _notifications.cancel(0);
    } on Object catch (_) {
      // Invalid-reminder cleanup must not block notification initialization.
    }
  }

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    debugPrint('🔔 [NotificationService] 初始化通知服务');

    // 🔥 首先清理无效的测试提醒
    await clearInvalidReminders();

    // 初始化时区数据，使用设备本地时区
    tz.initializeTimeZones();

    // 根据设备UTC偏移量设置正确的时区
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;

    // 尝试常见时区名称（优先使用地理位置时区）
    String? locationName;
    if (hours == 8) {
      locationName = 'Asia/Shanghai'; // UTC+8
    } else if (hours == 9) {
      locationName = 'Asia/Tokyo'; // UTC+9
    } else if (hours == -5) {
      locationName = 'America/New_York'; // UTC-5
    } else if (hours == -8) {
      locationName = 'America/Los_Angeles'; // UTC-8
    }

    if (locationName != null) {
      try {
        tz.setLocalLocation(tz.getLocation(locationName));
        debugPrint(
          '📍 使用时区: $locationName (UTC${hours >= 0 ? '+' : ''}$hours)',
        );
      } on Object catch (_) {
        // Fall through to the Etc/GMT fallback below.
      }
    }

    // 备选方案：使用Etc/GMT时区（注意符号是反的！）
    // GMT+8 实际表示 UTC-8，GMT-8 表示 UTC+8
    try {
      final sign = hours >= 0 ? '-' : '+'; // 符号相反！
      final tzName = 'Etc/GMT$sign${hours.abs()}';
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('📍 使用时区: $tzName (UTC${hours >= 0 ? '+' : ''}$hours)');
    } on Object {
      // 最后的备选：直接使用Asia/Shanghai
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    // Android初始化配置
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS初始化配置
    // 🔥 关键：不要在初始化时自动请求权限！
    // 应该在用户真正需要时（设置提醒时）才请求
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // 改为false，避免过早请求
      requestBadgePermission: false, // 改为false
      requestSoundPermission: false, // 改为false
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    // 初始化，并设置通知点击回调
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // 🔥 处理通知点击 - 标记为已读并跳转
        final payload = response.payload;
        if (payload != null) {
          // 🔥 修复：payload现在是原始的noteId字符串，不再是hashCode
          final noteIdString = payload;
          final noteHashCode = noteIdString.hashCode;

          // 🔥 标记提醒通知为已点击（在数据库中查找并更新）
          try {
            final allReminders = await _reminderNotificationService
                .getReminderNotificationsByNoteId(noteIdString);
            if (allReminders.isNotEmpty) {
              // 找到最近触发的未读通知并标记为已点击
              final unreadReminder = allReminders.firstWhere(
                (r) => !r.isClicked,
                orElse: () => allReminders.first,
              );
              await _reminderNotificationService
                  .markAsClicked(unreadReminder.id);
            }
          } on Object catch (_) {
            // Marking a notification as clicked is best-effort.
          }

          // 🎯 清除笔记的提醒时间并刷新未读数（大厂逻辑：点击系统通知=已查看）
          final appProvider = _globalAppProvider;
          if (appProvider != null) {
            try {
              await appProvider.cancelNoteReminder(noteIdString);
              await appProvider.refreshUnreadAnnouncementsCount();
            } on Object catch (_) {
              // Note reminder cleanup is best-effort after notification tap.
            }
          }

          // 🔥 市面上常见做法：点击通知后立即取消该通知
          unawaited(_notifications.cancel(noteHashCode));
          _scheduledReminders.remove(noteHashCode);
          _activeTimers.remove(noteHashCode);

          // 🔥 直接使用全局Router跳转
          if (_globalRouter != null) {
            await Future.delayed(const Duration(milliseconds: 300));
            try {
              _globalRouter!.go('/note/$noteIdString');
            } on Object catch (_) {
              // Navigation can fail if the router is not ready yet.
            }
          }

          // 调用回调（如果有的话）
          if (_onNotificationTapped != null) {
            _onNotificationTapped!(noteHashCode);
          }
        }
      },
    );

    // 🔥 关键：提前创建通知渠道（小米设备必须！）
    await _createNotificationChannel();

    // 🍎 iOS：注册通知分类和动作
    await _registerIOSNotificationCategories();

    _initialized = true;
  }

  /// 注册iOS通知分类（实现iOS原生风格）
  Future<void> _registerIOSNotificationCategories() async {
    if (!Platform.isIOS) {
      return;
    }

    // 这里不做权限请求，只在实际设置提醒时请求
    // iOS的通知分类可以在Info.plist中配置，或在首次请求权限时自动注册
  }

  /// 创建通知渠道（小米等设备必须提前创建）
  Future<void> _createNotificationChannel() async {
    debugPrint('📢 [NotificationService] 创建通知渠道');

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 创建通知渠道
      const channel = AndroidNotificationChannel(
        'note_reminders', // 渠道ID（必须与发送通知时一致）
        '笔记提醒', // 渠道名称
        description: '笔记定时提醒通知',
        importance: Importance.high, // 高重要性
      );

      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// 检查通知权限是否已授予
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.areNotificationsEnabled();
          return granted ?? false;
        }
      } else if (Platform.isIOS) {
        // iOS权限检查
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          try {
            final granted = await iosPlugin.checkPermissions();
            // 检查是否有任何通知权限被授予
            return granted != null;
          } on Object {
            return false;
          }
        }
      }

      return false;
    } on Object {
      return false;
    }
  }

  /// 确保时区正确设置（每次都强制重新初始化，防止热重载和其他问题）
  void _ensureTimezoneInitialized() {
    try {
      // 确保时区数据库已初始化
      tz.initializeTimeZones();

      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;

      // 每次都根据设备偏移量重新设置时区
      if (hours == 8) {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      } else if (hours == 9) {
        tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
      } else if (hours == -5) {
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      } else if (hours == -8) {
        tz.setLocalLocation(tz.getLocation('America/Los_Angeles'));
      } else {
        // 使用 Etc/GMT 时区（注意符号相反！）
        // GMT+8 实际表示 UTC-8，GMT-8 表示 UTC+8
        final sign = hours >= 0 ? '-' : '+';
        final tzName = 'Etc/GMT$sign${hours.abs()}';
        try {
          tz.setLocalLocation(tz.getLocation(tzName));
        } on Object catch (_) {
          // 最后的fallback
          tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
        }
      }

      // 验证设置结果
    } on Object {
      // 尝试使用UTC作为最后的fallback
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } on Object catch (_) {
        // No further fallback is available.
      }
    }
  }

  /// 检查并请求精确闹钟权限
  Future<bool> checkAndRequestExactAlarmPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 尝试请求精确闹钟权限
      final hasPermission = await androidPlugin.requestExactAlarmsPermission();

      if (hasPermission ?? false) {
        return true;
      } else {
        debugPrint('   Settings → Apps → InkRoot → Alarms & reminders');
        debugPrint('   开启 "Allow setting alarms and reminders"');
        return false;
      }
    }
    return true;
  }

  /// 🔥 简单方案：设置笔记提醒（使用 Timer 而不是系统调度）
  Future<bool> scheduleNoteReminder({
    required int noteId,
    required String noteIdString,
    required String title,
    required String body,
    required DateTime reminderTime,
    BuildContext? context,
  }) async {
    await initialize();
    final now = DateTime.now();
    if (reminderTime.isBefore(now)) {
      return false;
    }

    // 取消旧的 Timer（如果存在）
    _activeTimers[noteId]?.cancel();
    _scheduledReminders.remove(noteId);

    // 🔥 关键：使用系统调度（zonedSchedule）而不是Timer
    // 这样即使应用在后台或锁屏，系统也会触发通知
    _ensureTimezoneInitialized();

    // 创建调度时间（使用本地时区）
    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    debugPrint('📅 调度时间: $scheduledDate');

    // 配置Android通知详情（带锁屏显示）
    final androidDetails = AndroidNotificationDetails(
      'note_reminders',
      '笔记提醒',
      channelDescription: '笔记定时提醒通知',
      icon: '@mipmap/ic_launcher', // 应用图标
      largeIcon: const DrawableResourceAndroidBitmap(
        '@mipmap/ic_launcher',
      ), // 大图标（显示logo）
      importance: Importance.max, // 最高重要性
      priority: Priority.max, // 最高优先级
      enableLights: true,
      // 🔥 关键：锁屏通知配置
      visibility: NotificationVisibility.public, // 在锁屏上完全显示
      fullScreenIntent: true, // 全屏提示
      category: AndroidNotificationCategory.alarm, // 闹钟类别（最高优先级）
      when: reminderTime.millisecondsSinceEpoch,
    );

    // iOS通知详情 - 符合iOS原生提醒风格
    // 🔥 不设置badgeNumber，让系统自动管理角标（累加未读数量）
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, // 显示横幅通知
      presentBadge: false, // 🔥 改为false，不显示角标，避免误导
      presentSound: true, // 播放声音
      sound: 'default', // 使用系统默认提醒音
      threadIdentifier: 'note_reminders', // 通知分组
      // 🔥 关键：时间敏感通知可以在专注模式下突破
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: const LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      ),
    );

    try {
      // 🔥 关键：检查精确闹钟权限（仅Android小米设备必须）
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final canSchedule = await androidPlugin.canScheduleExactNotifications();

        if (canSchedule != true) {
          debugPrint('');
          debugPrint('   1. 打开"设置"');
          debugPrint('   2. 搜索"闹钟"或进入"应用设置" → "应用管理"');
          debugPrint('   3. 找到"InkRoot" → "其他权限"');
          debugPrint('   4. 开启"设置闹钟和提醒"权限');
          debugPrint('   5. 返回应用重新设置提醒');
          debugPrint('');
          debugPrint('═══════════════════════════════════════\n');
          return false;
        }
      }

      // 🔥 保存映射关系（重要：用于通知点击时反查笔记）
      NotificationService.noteIdMapping[noteId] = noteIdString;

      // iOS/macOS 使用 flutter_local_notifications，Android 使用原生 AlarmManager。
      if (Platform.isIOS || Platform.isMacOS) {
        try {
          // 🔥 关键：先验证权限状态
          final iosPlugin = Platform.isIOS
              ? _notifications.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              : null;
          final macOSPlugin = Platform.isMacOS
              ? _notifications.resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin>()
              : null;

          if (iosPlugin == null && macOSPlugin == null) {
            return false;
          }

          final granted = Platform.isIOS
              ? await iosPlugin!.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                )
              : await macOSPlugin!.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                );

          // 检查是否授权
          if (granted != true) {
            // 引导用户到设置
            if (context != null && context.mounted) {
              _showPermissionDeniedDialog(
                context,
                '需要通知权限',
                '为了准时提醒您，InkRoot 需要发送通知。请在系统设置中为 InkRoot 开启通知权限。',
              );
            }
            return false;
          }

          // 🔥 确认有权限后，开始调度通知
          _ensureTimezoneInitialized(); // 确保时区正确

          final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
          final now = tz.TZDateTime.now(tz.local);

          // 检查时间是否有效
          if (!tzReminderTime.isAfter(now)) {
            return false;
          }

          // 调度通知
          try {
            await _notifications.zonedSchedule(
              noteId,
              title,
              body,
              tzReminderTime,
              details,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: noteIdString, // 🔥 修复：直接传递原始字符串ID，不用hashCode
            );
          } on Object {
            return false;
          }

          _scheduledReminders[noteId] = reminderTime;

          // 🔥 验证通知是否真的被调度
          await Future.delayed(const Duration(milliseconds: 500));
          final pending = await _notifications.pendingNotificationRequests();
          final found = pending.any((n) => n.id == noteId);

          if (found) {
            // 🔥 iOS：调度成功后立即保存提醒记录到数据库（市场主流做法）
            try {
              final reminderNotification = ReminderNotification(
                id: const Uuid().v4(),
                noteId: noteIdString,
                noteTitle: title,
                noteContent: body,
                reminderTime: reminderTime,
                triggeredAt: DateTime.now(), // 记录为当前时间，实际触发时间在reminderTime
              );
              await _reminderNotificationService
                  .saveReminderNotification(reminderNotification);
            } on Object catch (_) {
              // The reminder itself is scheduled; DB history is best-effort.
            }

            return true;
          } else {
            return false;
          }
        } on Object {
          return false;
        }
      } else if (Platform.isAndroid) {
        // Android使用原生AlarmManager
        try {
          final success = await platform.invokeMethod('scheduleAlarm', {
            'noteId': noteId,
            'title': title,
            'body': body,
            'triggerTime': reminderTime.millisecondsSinceEpoch,
          });

          if (success == true) {
            _scheduledReminders[noteId] = reminderTime;

            // 🔥 Android的保存逻辑在AlarmReceiver中触发时保存
            // 这里只记录调度成功，不保存到数据库

            return true;
          }
          return false;
        } on PlatformException {
          return false;
        }
      }
      return false;
    } on Object {
      debugPrint('═══════════════════════════════════════\n');
      return false;
    }
  }

  /// 取消笔记提醒
  Future<void> cancelNoteReminder(int noteId) async {
    try {
      // 清理记录
      _scheduledReminders.remove(noteId);
      _activeTimers.remove(noteId);

      // Android取消原生AlarmManager调度
      if (Platform.isAndroid) {
        try {
          await platform.invokeMethod('cancelAlarm', {'noteId': noteId});
        } on PlatformException {
          // The native alarm may already have been removed.
        }
      }

      // iOS和Android都取消flutter_local_notifications的通知
      await _notifications.cancel(noteId);
    } on Object catch (_) {
      // Cancel is idempotent and can safely fail for missing notifications.
    }
  }

  /// 显示权限被拒绝的对话框
  void _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizationsSimple.of(context)?.permissionStepTitle ??
                        '操作步骤：',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizationsSimple.of(context)
                            ?.permissionStepNotification ??
                        '1. 点击"去设置"按钮\n2. 找到"通知"权限\n3. 开启权限开关\n4. 返回应用重试',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child:
                Text(AppLocalizationsSimple.of(context)?.goToSettings ?? '去设置'),
          ),
        ],
      ),
    );
  }
}
