import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/utils/logger.dart';
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
        builder: (context) {
          final l10n = AppLocalizationsSimple.of(context);
          return AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(l10n?.needNotificationPermission ?? '需要开启通知权限'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.pleaseEnablePermissionsMessage ??
                        '为了准时收到笔记提醒，请开启以下权限',
                    style: AppTextStyles.titleMedium(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    context,
                    '1',
                    l10n?.allowAppNotifications ?? '允许通知',
                    l10n?.allowAppNotifications ?? '允许应用显示通知',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    context,
                    '2',
                    l10n?.exactAlarm ?? '设置闹钟和提醒',
                    l10n?.allowExactAlarmDescription ?? '在其他权限中允许设置闹钟',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    context,
                    '3',
                    l10n?.batteryOptimization ?? '省电策略',
                    l10n?.allowBackgroundDescription ?? '允许应用在后台保持活跃',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n?.openSettingsInstructions ??
                                '点击下方按钮，在应用设置中开启权限后返回',
                            style: const TextStyle(
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
                child: Text(l10n?.postponeSettings ?? '稍后设置'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    const platform =
                        MethodChannel(AppConfig.channelNativeAlarm);
                    await platform.invokeMethod('openAppSettings');
                  } on Object catch (e) {
                    Log.ui.warning(
                      'Failed to open app settings',
                      data: {'error': e.toString()},
                    );
                  }
                },
                icon: const Icon(Icons.settings),
                label: Text(l10n?.goToSettings ?? '去设置'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );

  static Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) =>
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
