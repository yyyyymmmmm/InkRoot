import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:inkroot/config/app_identity.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 统一日志服务
/// 集成 Sentry 错误追踪，提供结构化日志
class LoggerService {
  static const String _tag = AppIdentity.name;

  /// 是否启用详细日志
  static bool verbose = kDebugMode;

  /// 调试日志
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (!kDebugMode) {
      return;
    }

    final logTag = tag ?? _tag;
    final logMessage = _formatMessage(message, data);

    developer.log(
      logMessage,
      name: logTag,
      level: 500, // Debug level
    );

    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('🐛 [$logTag] $logMessage');
    }
  }

  /// 信息日志
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    final logTag = tag ?? _tag;
    final logMessage = _formatMessage(message, data);

    developer.log(
      logMessage,
      name: logTag,
      level: 800, // Info level
    );

    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('ℹ️ [$logTag] $logMessage');
    }

    // 发送到 Sentry 作为 breadcrumb
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: logTag,
        level: SentryLevel.info,
        data: data,
      ),
    );
  }

  /// 警告日志
  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final logTag = tag ?? _tag;
    final logMessage = _formatMessage(message, data);

    developer.log(
      logMessage,
      name: logTag,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );

    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('⚠️ [$logTag] $logMessage');
      if (error != null) {
        // ignore: avoid_print
        debugPrint('   Error: $error');
      }
    }

    // 发送到 Sentry 作为 breadcrumb
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: logTag,
        level: SentryLevel.warning,
        data: {
          if (data != null) ...data,
          if (error != null) 'error': error.toString(),
        },
      ),
    );
  }

  /// 错误日志
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    bool fatal = false,
  }) {
    final logTag = tag ?? _tag;
    final logMessage = _formatMessage(message, data);

    developer.log(
      logMessage,
      name: logTag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );

    // ignore: avoid_print
    debugPrint('❌ [$logTag] $logMessage');
    if (error != null) {
      // ignore: avoid_print
      debugPrint('   Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      // ignore: avoid_print
      debugPrint('   Stack: $stackTrace');
    }

    // 上报到 Sentry
    _reportToSentry(
      message: message,
      error: error,
      stackTrace: stackTrace,
      tag: logTag,
      data: data,
      fatal: fatal,
    );
  }

  /// 性能追踪
  static Future<T> trace<T>(
    String operation,
    Future<T> Function() function, {
    Map<String, dynamic>? data,
  }) async {
    final transaction = Sentry.startTransaction(
      operation,
      'task',
      bindToScope: true,
    );

    try {
      final result = await function();
      transaction.status = const SpanStatus.ok();
      return result;
    } on Object catch (error, stackTrace) {
      transaction.status = const SpanStatus.internalError();
      transaction.throwable = error;

      LoggerService.error(
        'Operation failed: $operation',
        error: error,
        stackTrace: stackTrace,
        data: data,
      );

      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  /// 性能计时
  static PerformanceTimer startTimer(String name) => PerformanceTimer(name);

  /// 设置用户信息（用于错误追踪）
  static void setUser(String? userId, {String? username, String? email}) {
    Sentry.configureScope((scope) {
      if (userId != null) {
        scope.setUser(
          SentryUser(
            id: userId,
            username: username,
            email: email,
          ),
        );
      } else {
        scope.setUser(null);
      }
    });
  }

  /// 设置自定义标签
  static void setTag(String key, String value) {
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// 设置自定义上下文
  static void setContext(String key, Map<String, dynamic> context) {
    Sentry.configureScope((scope) {
      scope.setContexts(key, context);
    });
  }

  /// 格式化消息
  static String _formatMessage(String message, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return message;
    }

    final dataStr = data.entries.map((e) => '${e.key}=${e.value}').join(', ');

    return '$message [$dataStr]';
  }

  /// 上报到 Sentry
  static Future<void> _reportToSentry({
    required String message,
    required String tag,
    error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    bool fatal = false,
  }) async {
    try {
      await Sentry.captureException(
        error ?? Exception(message),
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': message,
          'tag': tag,
          if (data != null) 'data': data,
          'fatal': fatal,
        }),
      );
    } on Object catch (e) {
      // 如果 Sentry 上报失败，不要影响主流程
      if (kDebugMode) {
        // ignore: avoid_print
        debugPrint('Failed to report to Sentry: $e');
      }
    }
  }
}

/// 性能计时器
class PerformanceTimer {
  PerformanceTimer(this.name)
      : _stopwatch = Stopwatch()..start(),
        _span = Sentry.getSpan()?.startChild(name);
  final String name;
  final Stopwatch _stopwatch;
  final ISentrySpan? _span;

  /// 停止计时并记录
  void stop({Map<String, dynamic>? data}) {
    _stopwatch.stop();
    final duration = _stopwatch.elapsedMilliseconds;

    LoggerService.debug(
      'Performance: $name completed in ${duration}ms',
      data: data,
    );

    _span?.finish(status: const SpanStatus.ok());

    // 如果时间过长，记录警告
    if (duration > 1000) {
      LoggerService.warning(
        'Slow operation: $name took ${duration}ms',
        data: {'duration_ms': duration, ...?data},
      );
    }
  }

  /// 记录失败
  void fail(Object? error, StackTrace? stackTrace) {
    _stopwatch.stop();
    _span?.finish(status: const SpanStatus.internalError());

    LoggerService.error(
      'Performance: $name failed after ${_stopwatch.elapsedMilliseconds}ms',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// 性能监控扩展
extension PerformanceExtensions on Future {
  /// 包装 Future 以自动追踪性能
  Future<T> withPerformanceTracking<T>(String operationName) async =>
      LoggerService.trace(operationName, () => this as Future<T>);
}
