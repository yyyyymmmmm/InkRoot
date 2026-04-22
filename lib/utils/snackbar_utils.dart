import 'package:flutter/material.dart';
import 'package:inkroot/themes/app_theme.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      backgroundColor: AppTheme.successColor,
      icon: Icons.check,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    if (onRetry != null) {
      _showErrorWithRetry(context, message, onRetry);
    } else {
      _showCustomSnackBar(
        context,
        message,
        backgroundColor: Colors.red.shade600,
        icon: Icons.close,
      );
    }
  }

  static void showInfo(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _showCustomSnackBar(
      context,
      message,
      backgroundColor:
          isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
      icon: Icons.info,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      backgroundColor: Colors.orange.shade600,
      icon: Icons.warning,
    );
  }

  /// 显示网络错误提示，会自动根据错误类型提供友好的提示信息
  static void showNetworkError(
    BuildContext context,
    error, {
    VoidCallback? onRetry,
  }) {
    // Note: These messages should ideally use localization, but context may not be available
    var userFriendlyMessage =
        'Network connection failed, please check network settings';

    if (error != null) {
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('networkexception')) {
        userFriendlyMessage =
            'Network connection failed, please check network settings';
      } else if (errorString.contains('timeoutexception')) {
        userFriendlyMessage =
            'Connection timeout, please check network or try again later';
      } else if (errorString.contains('formatexception')) {
        userFriendlyMessage =
            'Server response format error, please check server address';
      } else if (errorString.contains('handshakeexception') ||
          errorString.contains('tlsexception')) {
        userFriendlyMessage =
            'SSL connection failed, please check server certificate';
      } else if (errorString.contains('unauthorized') ||
          errorString.contains('401')) {
        userFriendlyMessage = 'Login information expired, please log in again';
      } else if (errorString.contains('forbidden') ||
          errorString.contains('403')) {
        userFriendlyMessage =
            'No access permission, please contact administrator';
      } else if (errorString.contains('notfound') ||
          errorString.contains('404')) {
        userFriendlyMessage =
            'Requested resource does not exist, please check server address';
      } else if (errorString.contains('server') ||
          errorString.contains('500')) {
        userFriendlyMessage = 'Server internal error, please try again later';
      } else if (errorString.contains('service unavailable') ||
          errorString.contains('503')) {
        userFriendlyMessage =
            'Server temporarily unavailable, please try again later';
      }
    }

    showError(context, userFriendlyMessage, onRetry: onRetry);
  }

  static void _showErrorWithRetry(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        action: SnackBarAction(
          label: 'Retry', // 重试
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onRetry();
          },
        ),
      ),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    // 🎯 大厂风格：居中显示，保持彩色背景，无图标
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor, // 使用传入的颜色（绿色成功/红色失败/橙色警告）
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 50),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
