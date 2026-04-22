import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';

class PermissionGuideDialog extends StatefulWidget {
  const PermissionGuideDialog({super.key});

  @override
  State<PermissionGuideDialog> createState() => _PermissionGuideDialogState();
}

class _PermissionGuideDialogState extends State<PermissionGuideDialog> {
  static final platform = MethodChannel(AppConfig.channelNativeAlarm);

  Map<String, bool> permissionStatus = {
    'notification': false,
    'alarm': false,
    'battery': false,
  };

  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  // 检查所有权限状态
  Future<void> _checkAllPermissions() async {
    setState(() {
      isChecking = true;
    });

    try {
      final result = await platform.invokeMethod('checkPermissions');

      if (result is Map) {
        setState(() {
          permissionStatus['notification'] = result['notification'] == true;
          permissionStatus['alarm'] = result['alarm'] == true;
          permissionStatus['battery'] = result['battery'] == true;
        });
      }
    } catch (e) {
      debugPrint('权限检查失败: $e');
    }

    setState(() {
      isChecking = false;
    });
  }

  // 打开应用设置
  Future<void> _openAppSettings() async {
    try {
      await platform.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('无法打开设置: $e');
    }
  }

  // 检查是否所有权限都已授予
  bool get allPermissionsGranted =>
      permissionStatus.values.every((granted) => granted);

  // 构建权限项
  Widget _buildPermissionItem({
    required BuildContext context,
    required String title,
    required String description,
    required bool isGranted,
    required IconData icon,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGranted ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGranted ? Colors.green : Colors.orange,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isGranted ? Colors.green.shade100 : Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isGranted ? Colors.green.shade700 : Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isGranted
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isGranted ? Icons.check_circle : Icons.error,
              color: isGranted ? Colors.green : Colors.orange,
              size: 28,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: allPermissionsGranted
                    ? Colors.green.shade50
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    allPermissionsGranted
                        ? Icons.check_circle
                        : Icons.notifications_active,
                    color: allPermissionsGranted
                        ? Colors.green
                        : AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allPermissionsGranted
                              ? (AppLocalizationsSimple.of(context)
                                      ?.permissionsReady ??
                                  '✅ 权限已就绪')
                              : (AppLocalizationsSimple.of(context)
                                      ?.permissionsRequired ??
                                  '需要权限'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: allPermissionsGranted
                                ? Colors.green.shade900
                                : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          allPermissionsGranted
                              ? (AppLocalizationsSimple.of(context)
                                      ?.allPermissionsGrantedMessage ??
                                  '所有权限已开启，可以正常使用提醒功能')
                              : (AppLocalizationsSimple.of(context)
                                      ?.pleaseEnablePermissionsMessage ??
                                  '为了准时收到笔记提醒，请开启以下权限'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 权限列表
            Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 400),
              child: isChecking
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPermissionItem(
                            context: context,
                            title: AppLocalizationsSimple.of(context)
                                    ?.notificationPermission ??
                                '通知权限',
                            description: AppLocalizationsSimple.of(context)
                                    ?.allowAppNotifications ??
                                '允许应用显示通知',
                            isGranted:
                                permissionStatus['notification'] ?? false,
                            icon: Icons.notifications,
                          ),
                          _buildPermissionItem(
                            context: context,
                            title: AppLocalizationsSimple.of(context)
                                    ?.exactAlarm ??
                                '精确闹钟',
                            description: AppLocalizationsSimple.of(context)
                                    ?.allowExactAlarmDescription ??
                                '允许在特定时间触发提醒',
                            isGranted: permissionStatus['alarm'] ?? false,
                            icon: Icons.alarm,
                          ),
                          _buildPermissionItem(
                            context: context,
                            title: AppLocalizationsSimple.of(context)
                                    ?.backgroundRunning ??
                                '后台运行',
                            description: AppLocalizationsSimple.of(context)
                                    ?.allowBackgroundDescription ??
                                '允许应用在后台保持活跃',
                            isGranted: permissionStatus['battery'] ?? false,
                            icon: Icons.battery_charging_full,
                          ),
                          if (!allPermissionsGranted) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizationsSimple.of(context)
                                              ?.openSettingsInstructions ??
                                          '点击下方"打开设置"按钮，在应用设置中开启权限后，点击"重新检查"',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!allPermissionsGranted) ...[
                    ElevatedButton.icon(
                      onPressed: _openAppSettings,
                      icon: const Icon(Icons.settings, size: 20),
                      label: Text(
                        AppLocalizationsSimple.of(context)?.openSettings ??
                            '打开设置',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _checkAllPermissions,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(
                        AppLocalizationsSimple.of(context)?.recheck ?? '重新检查',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      if (!allPermissionsGranted)
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              AppLocalizationsSimple.of(context)
                                      ?.postponeSettings ??
                                  '稍后设置',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      if (allPermissionsGranted)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              AppLocalizationsSimple.of(context)?.confirm ??
                                  '确定',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
