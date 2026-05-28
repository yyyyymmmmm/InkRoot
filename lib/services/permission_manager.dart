import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// 统一权限管理服务
/// 在用户使用功能时主动请求权限并提供友好的提示
class PermissionManager {
  factory PermissionManager() => _instance;
  PermissionManager._internal();
  static final PermissionManager _instance = PermissionManager._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 请求麦克风权限（语音识别用）
  Future<bool> requestMicrophonePermission(BuildContext? context) async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // 显示权限说明对话框
        if (context != null) {
          final shouldRequest = await _showPermissionDialog(
            context,
            '麦克风权限',
            '语音识别功能需要访问麦克风来录制您的语音并转换为文字。',
            '🎤',
          );

          if (!shouldRequest) {
            return false;
          }
        }

        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (context != null) {
          await _showSettingsDialog(
            context,
            '麦克风权限被拒绝',
            '请在设置中手动开启麦克风权限以使用语音识别功能。',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 请求语音识别权限
  Future<bool> requestSpeechRecognitionPermission(BuildContext? context) async {
    if (!Platform.isIOS) {
      return true; // Android不需要单独的语音识别权限
    }

    try {
      final status = await Permission.speech.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        if (context != null) {
          final shouldRequest = await _showPermissionDialog(
            context,
            '语音识别权限',
            '应用需要语音识别权限来将您的语音转换为文字。',
            '🗣️',
          );

          if (!shouldRequest) {
            return false;
          }
        }

        final result = await Permission.speech.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (context != null) {
          await _showSettingsDialog(
            context,
            '语音识别权限被拒绝',
            '请在设置中手动开启语音识别权限。',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission(BuildContext? context) async {
    try {
      if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          // 先检查当前权限状态
          final currentPermissions = await iosPlugin.checkPermissions();

          if (currentPermissions != null) {
            return true;
          }

          // 显示权限说明对话框
          if (context != null) {
            final shouldRequest = await _showPermissionDialog(
              context,
              '通知权限',
              '应用需要通知权限来提醒您重要的笔记和待办事项。',
              '🔔',
            );

            if (!shouldRequest) {
              return false;
            }
          }

          // 请求权限
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

          return granted ?? false;
        }
      } else {
        // Android通知权限
        final status = await Permission.notification.status;

        if (status.isGranted) {
          return true;
        }

        if (status.isDenied) {
          if (context != null) {
            final shouldRequest = await _showPermissionDialog(
              context,
              '通知权限',
              '应用需要通知权限来提醒您重要的笔记和待办事项。',
              '🔔',
            );

            if (!shouldRequest) {
              return false;
            }
          }

          final result = await Permission.notification.request();
          return result.isGranted;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 请求相机权限
  Future<bool> requestCameraPermission(BuildContext? context) async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        if (context != null) {
          final shouldRequest = await _showPermissionDialog(
            context,
            '相机权限',
            '拍照功能需要访问相机来拍摄照片。',
            '📷',
          );

          if (!shouldRequest) {
            return false;
          }
        }

        final result = await Permission.camera.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (context != null) {
          await _showSettingsDialog(
            context,
            '相机权限被拒绝',
            '请在设置中手动开启相机权限以使用拍照功能。',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 请求相册权限
  Future<bool> requestPhotosPermission(BuildContext? context) async {
    try {
      final status = await Permission.photos.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        if (context != null) {
          final shouldRequest = await _showPermissionDialog(
            context,
            '相册权限',
            '选择图片功能需要访问相册来选择照片。',
            '📱',
          );

          if (!shouldRequest) {
            return false;
          }
        }

        final result = await Permission.photos.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        if (context != null) {
          await _showSettingsDialog(
            context,
            '相册权限被拒绝',
            '请在设置中手动开启相册权限以使用图片选择功能。',
          );
        }
        return false;
      }

      return false;
    } catch (e) {
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
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('允许'),
            ),
          ],
        ),
      ) ??
      false;

  /// 显示设置对话框
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
            const SizedBox(height: 12),
            const Text(
              '请按以下步骤操作：\n1. 点击"去设置"\n2. 找到相应权限开关\n3. 开启权限后返回应用',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 检查语音识别完整权限
  Future<bool> checkSpeechPermissions(BuildContext? context) async {
    final micPermission = await requestMicrophonePermission(context);
    if (!micPermission) {
      return false;
    }

    final speechPermission = await requestSpeechRecognitionPermission(context);
    return speechPermission;
  }
}
