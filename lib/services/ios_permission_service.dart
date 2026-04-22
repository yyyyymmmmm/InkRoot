import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// iOS权限管理服务
/// 专门处理iOS平台的权限请求和管理
class IOSPermissionService {
  factory IOSPermissionService() => _instance;
  IOSPermissionService._internal();
  static final IOSPermissionService _instance =
      IOSPermissionService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 检查并请求所有必要的iOS权限
  Future<Map<String, bool>> checkAndRequestAllPermissions() async {
    if (!Platform.isIOS) {
      return {};
    }

    final results = <String, bool>{};

    // 1. 麦克风权限（语音识别必需）
    results['microphone'] = await _checkAndRequestMicrophone();

    // 2. 语音识别权限
    results['speechRecognition'] = await _checkAndRequestSpeechRecognition();

    // 3. 通知权限
    results['notifications'] = await _checkAndRequestNotifications();

    // 4. 相机权限
    results['camera'] = await _checkAndRequestCamera();

    // 5. 相册权限
    results['photos'] = await _checkAndRequestPhotos();

    // 6. 位置权限
    results['location'] = await _checkAndRequestLocation();

    return results;
  }

  /// 检查并请求麦克风权限
  Future<bool> _checkAndRequestMicrophone() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查并请求语音识别权限
  Future<bool> _checkAndRequestSpeechRecognition() async {
    try {
      final status = await Permission.speech.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.speech.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查并请求通知权限
  Future<bool> _checkAndRequestNotifications() async {
    try {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        // 先检查当前权限状态
        final currentPermissions = await iosPlugin.checkPermissions();

        if (currentPermissions != null) {
          // 如果有任何权限被授予，认为通知权限可用
          return true;
        }

        // 请求权限
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        return granted ?? false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查并请求相机权限
  Future<bool> _checkAndRequestCamera() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查并请求相册权限
  Future<bool> _checkAndRequestPhotos() async {
    try {
      final status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查并请求位置权限
  Future<bool> _checkAndRequestLocation() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.locationWhenInUse.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 显示权限设置指导
  void showPermissionGuide(String permissionType) {}

  /// 打开应用设置页面
  Future<void> openAppSettings() async {
    try {
      await Permission.camera.request();
    } catch (e) {}
  }
}
