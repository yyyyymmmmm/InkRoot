import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 🚀 大厂标准：结构化日志服务
/// 支持日志级别、格式化输出、性能优化
class Logger {
  const Logger(this.tag);
  final String tag;

  /// 日志级别
  static LogLevel _minLevel = kReleaseMode ? LogLevel.none : LogLevel.debug;

  /// 设置最小日志级别
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 是否启用日志
  static bool get isEnabled => _minLevel != LogLevel.none;

  /// Debug - 调试信息（开发时使用）
  void debug(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, data: data);
  }

  /// Info - 一般信息（重要的业务流程）
  void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }

  /// Warning - 警告信息（潜在问题）
  void warning(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Error - 错误信息（需要关注的错误）
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Fatal - 致命错误（导致应用崩溃的错误）
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// 内部日志方法
  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // 检查日志级别
    if (!isEnabled || level.index < _minLevel.index) {
      return;
    }

    // 构建日志消息
    final buffer = StringBuffer();

    // 添加emoji和级别标识
    buffer.write('${level.emoji} [${level.name.toUpperCase()}]');

    // 添加tag
    buffer.write(' [$tag]');

    // 添加消息
    buffer.write(' $message');

    // 添加数据
    if (data != null && data.isNotEmpty) {
      buffer.write('\n  Data: ${_formatData(data)}');
    }

    // 添加错误信息
    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    // 添加堆栈信息（仅错误级别）
    if (stackTrace != null && level.index >= LogLevel.error.index) {
      buffer.write('\n  Stack trace:\n${_formatStackTrace(stackTrace)}');
    }

    // 输出日志
    final logMessage = buffer.toString();

    if (level.index >= LogLevel.error.index) {
      // 错误级别使用 developer.log（在DevTools中更易读）
      developer.log(
        logMessage,
        name: tag,
        level: _mapLogLevel(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // 其他级别使用 debugPrint（避免日志被截断）
      debugPrint(logMessage);
    }
  }

  /// 格式化数据
  String _formatData(Map<String, dynamic> data) {
    final entries = data.entries.map((e) => '${e.key}: ${e.value}');
    return '{${entries.join(', ')}}';
  }

  /// 格式化堆栈信息（只显示关键部分）
  String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');

    // 只显示前10行
    final relevantLines = lines.take(10).where((line) {
      // 过滤框架内部的堆栈
      return !line.contains('dart:') && !line.contains('package:flutter/');
    }).toList();

    return relevantLines.join('\n  ');
  }

  /// 映射日志级别到 developer.log 的级别
  int _mapLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
      case LogLevel.none:
        return 0;
    }
  }
}

/// 日志级别枚举
enum LogLevel {
  debug('🔍'),
  info('ℹ️'),
  warning('⚠️'),
  error('❌'),
  fatal('💀'),
  none('');

  const LogLevel(this.emoji);

  final String emoji;
}

/// 🚀 便捷的全局Logger实例
class Log {
  // 各模块的Logger
  static const database = Logger('Database');
  static const network = Logger('Network');
  static const sync = Logger('Sync');
  static const ui = Logger('UI');
  static const provider = Logger('Provider');
  static const service = Logger('Service');
  static const performance = Logger('Performance');
  static const security = Logger('Security');

  /// 创建自定义Logger
  static Logger custom(String tag) => Logger(tag);
}

/// 使用示例：
///
/// 1. 基础使用
/// ```dart
/// Log.database.debug('Querying notes from database');
/// Log.network.info('API request successful', data: {
///   'endpoint': '/api/v1/notes',
///   'status': 200,
/// });
/// Log.sync.warning('Sync conflict detected', data: {
///   'local_version': 5,
///   'remote_version': 6,
/// });
/// ```
///
/// 2. 错误日志
/// ```dart
/// try {
///   await apiService.fetchNotes();
/// } catch (e, stackTrace) {
///   Log.network.error(
///     'Failed to fetch notes',
///     error: e,
///     stackTrace: stackTrace,
///     data: {'retry_count': 3},
///   );
/// }
/// ```
///
/// 3. 性能日志
/// ```dart
/// final stopwatch = Stopwatch()..start();
/// await _loadNotes();
/// stopwatch.stop();
///
/// Log.performance.debug(
///   'Notes loaded',
///   data: {
///     'duration_ms': stopwatch.elapsedMilliseconds,
///     'count': notes.length,
///   },
/// );
/// ```
///
/// 4. 自定义Logger
/// ```dart
/// final logger = Log.custom('WebDAV');
/// logger.info('Starting backup');
/// ```
///
/// 5. 配置日志级别
/// ```dart
/// // 生产环境只显示警告及以上
/// if (kReleaseMode) {
///   Logger.setMinLevel(LogLevel.warning);
/// }
/// ```
