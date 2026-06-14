import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:permission_handler/permission_handler.dart';

/// 简化的权限服务
/// 直接使用permission_handler和flutter_local_notifications
class SimplePermissionService {
  factory SimplePermissionService() => _instance;
  SimplePermissionService._internal();
  static final SimplePermissionService _instance =
      SimplePermissionService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 请求语音识别权限（麦克风 + 语音识别）
  Future<bool> requestSpeechPermissions(BuildContext? context) async {
    try {
      // 1. 先显示权限说明对话框
      if (context != null) {
        final shouldRequest = await _showPermissionDialog(
          context,
          AppLocalizationsSimple.of(context)?.speechPermissionTitle ?? '语音识别权限',
          AppLocalizationsSimple.of(context)?.speechPermissionMessage ??
              '语音识别功能需要访问您的麦克风来录制语音并转换为文字。\n\n这将帮助您快速输入笔记内容。',
          '🎤',
        );

        if (!shouldRequest) {
          return false;
        }
        if (!context.mounted) {
          return false;
        }
      }

      // 2. 请求麦克风权限
      final micStatus = await Permission.microphone.status;

      if (micStatus.isDenied || micStatus.isRestricted) {
        final micResult = await Permission.microphone.request();

        if (!micResult.isGranted) {
          if (context != null && context.mounted) {
            await _showSettingsDialog(
              context,
              AppLocalizationsSimple.of(context)?.microphonePermissionDenied ??
                  '麦克风权限被拒绝',
              AppLocalizationsSimple.of(context)?.microphoneSettingsMessage ??
                  '请在设置中手动开启麦克风权限以使用语音识别功能。',
            );
          }
          return false;
        }
      }

      // 3. iOS还需要语音识别权限
      if (Platform.isIOS) {
        final speechStatus = await Permission.speech.status;

        if (speechStatus.isDenied || speechStatus.isRestricted) {
          final speechResult = await Permission.speech.request();

          if (!speechResult.isGranted) {
            if (context != null && context.mounted) {
              await _showSettingsDialog(
                context,
                AppLocalizationsSimple.of(context)?.speechPermissionDenied ??
                    '语音识别权限被拒绝',
                AppLocalizationsSimple.of(context)?.speechSettingsMessage ??
                    '请在设置中手动开启语音识别权限。',
              );
            }
            return false;
          }
        }
      }

      return true;
    } on Object {
      return false;
    }
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermissions(BuildContext? context) async {
    try {
      // 1. 先显示权限说明对话框
      if (context != null) {
        final shouldRequest = await _showPermissionDialog(
          context,
          AppLocalizationsSimple.of(context)?.notificationPermission ?? '通知权限',
          AppLocalizationsSimple.of(context)?.permissionInstructions ??
              '应用需要通知权限来提醒您重要的笔记和待办事项。\n\n这将帮助您不错过重要的提醒。',
          '🔔',
        );

        if (!shouldRequest) {
          return false;
        }
        if (!context.mounted) {
          return false;
        }
      }

      // 2. iOS使用flutter_local_notifications请求权限
      if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          // 先检查当前权限状态
          final currentPermissions = await iosPlugin.checkPermissions();

          // 如果已经有权限，直接返回成功
          if (currentPermissions != null) {
            return true;
          }

          // 请求权限

          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

          if (granted != true) {
            if (context != null && context.mounted) {
              await _showSettingsDialog(
                context,
                AppLocalizationsSimple.of(context)?.permissionRequired ??
                    '通知权限被拒绝',
                AppLocalizationsSimple.of(context)?.permissionInstructions ??
                    '通知功能需要通知权限。请在设置中手动开启通知权限。',
              );
            }
            return false;
          }

          return true;
        }
      } else {
        // Android使用permission_handler
        final notificationStatus = await Permission.notification.status;

        if (notificationStatus.isDenied || notificationStatus.isRestricted) {
          final notificationResult = await Permission.notification.request();

          if (!notificationResult.isGranted) {
            if (context != null && context.mounted) {
              await _showSettingsDialog(
                context,
                AppLocalizationsSimple.of(context)?.permissionRequired ??
                    '通知权限被拒绝',
                AppLocalizationsSimple.of(context)?.permissionInstructions ??
                    '通知功能需要通知权限。请在设置中手动开启通知权限。',
              );
            }
            return false;
          }
        }

        return true;
      }

      return false;
    } on Object {
      return false;
    }
  }

  /// 显示权限请求对话框
  Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    String emoji,
  ) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizationsSimple.of(context)?.permissionTip ??
                      '💡 提示：授权后可以正常使用相关功能',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizationsSimple.of(context)?.denyPermission ?? '暂不授权',
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppLocalizationsSimple.of(context)?.authorizeNow ?? '立即授权',
              ),
            ),
          ],
        ),
      ) ??
      false;

  /// 显示设置引导对话框
  Future<void> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
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
                    AppLocalizationsSimple.of(context)?.permissionStepGeneral ??
                        '1. 点击"去设置"按钮\n2. 找到相应权限开关\n3. 开启权限后返回应用\n4. 重新尝试使用功能',
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
