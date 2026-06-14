import 'dart:async';

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
    Object? error, {
    VoidCallback? onRetry,
  }) {
    var userFriendlyMessage = '网络出了点问题，请检查网络连接后重试';

    if (error != null) {
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('networkexception')) {
        userFriendlyMessage = '网络连接失败，请检查手机网络或切换网络后重试';
      } else if (errorString.contains('timeoutexception')) {
        userFriendlyMessage = '连接超时了，请检查网络是否正常，稍后再试';
      } else if (errorString.contains('formatexception')) {
        userFriendlyMessage = '服务器地址可能不对，请确认后重试';
      } else if (errorString.contains('handshakeexception') ||
          errorString.contains('tlsexception')) {
        userFriendlyMessage = '连接安全验证失败，请检查服务器地址是否以 https:// 开头';
      } else if (errorString.contains('unauthorized') ||
          errorString.contains('401')) {
        userFriendlyMessage = '登录信息已过期，请重新登录';
      } else if (errorString.contains('forbidden') ||
          errorString.contains('403')) {
        userFriendlyMessage = '没有访问权限，请联系管理员';
      } else if (errorString.contains('notfound') ||
          errorString.contains('404')) {
        userFriendlyMessage = '找不到服务器，请检查服务器地址是否正确';
      } else if (errorString.contains('500')) {
        userFriendlyMessage = '服务器出了点问题，请稍后再试';
      } else if (errorString.contains('service unavailable') ||
          errorString.contains('503')) {
        userFriendlyMessage = '服务器正在维护中，请稍后再试';
      }
    }

    showError(context, userFriendlyMessage, onRetry: onRetry);
  }

  static void _showErrorWithRetry(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
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
        margin: _floatingMargin(context, compact: false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onRetry();
          },
        ),
      ),
    );
  }

  static void showAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF303236),
        behavior: SnackBarBehavior.floating,
        margin: _floatingMargin(context, compact: false),
        duration: duration,
        persist: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        action: SnackBarAction(
          label: actionLabel,
          textColor: AppTheme.primaryLightColor,
          onPressed: onAction,
        ),
      ),
    );

    unawaited(
      Future<void>.delayed(duration + const Duration(milliseconds: 120), () {
        if (!context.mounted) {
          return;
        }
        messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
      }),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: _floatingMargin(context),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  static EdgeInsets _floatingMargin(
    BuildContext context, {
    bool compact = true,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final horizontal = width < 360
        ? 16.0
        : width < 600
            ? 24.0
            : (width - 420).clamp(24.0, double.infinity) / 2;
    final bottom = mediaQuery.padding.bottom + (compact ? 28.0 : 18.0);
    return EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom);
  }
}
