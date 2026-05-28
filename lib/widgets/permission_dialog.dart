import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/utils/text_style_helper.dart';

/// 权限引导弹窗
class PermissionDialog {
  /// 显示通知权限引导
  static Future<void> showNotificationPermissionDialog(
    BuildContext context,
  ) async =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(AppLocalizationsSimple.of(context)?.notificationPermissionRequired ?? '需要开启通知权限'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.notificationPermissionDesc ?? '为了准时收到笔记提醒，需要开启以下权限：',
                  style: AppTextStyles.titleMedium(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStep(context, '1', AppLocalizationsSimple.of(context)?.allowNotifications ?? '允许通知', AppLocalizationsSimple.of(context)?.allowNotificationsDesc ?? '在通知管理中开启InkRoot的通知权限'),
                const SizedBox(height: 12),
                _buildStep(context, '2', AppLocalizationsSimple.of(context)?.setAlarmsAndReminders ?? '设置闹钟和提醒', AppLocalizationsSimple.of(context)?.setAlarmsDesc ?? '在其他权限中允许设置闹钟'),
                const SizedBox(height: 12),
                _buildStep(context, '3', AppLocalizationsSimple.of(context)?.batterySaver ?? '省电策略', AppLocalizationsSimple.of(context)?.batterySaverDesc ?? '设置为"无限制"，防止后台被杀'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizationsSimple.of(context)?.xiaomiNotificationNote ?? '小米手机默认禁止通知，必须手动开启',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizationsSimple.of(context)?.later ?? '稍后设置'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // 跳转到应用设置
                try {
                  final platform =
                      MethodChannel(AppConfig.channelNativeAlarm);
                  await platform.invokeMethod('openAppSettings');
                } catch (e) {
                  debugPrint('无法打开设置: $e');
                }
              },
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizationsSimple.of(context)?.goToSettings ?? '去设置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

  static Widget _buildStep(BuildContext context, String number, String title, String description) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodyMedium(
                  context,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.custom(
                    context,
                    15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.custom(
                    context,
                    13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
