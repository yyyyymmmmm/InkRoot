// 🚀 大厂标准：可观测性服务（Observability）
// 三大支柱：
// 1. Logging（日志）
// 2. Metrics（指标）
// 3. Tracing（链路追踪）

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:inkroot/services/umeng_analytics_service.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 结构化日志
class StructuredLogger {
  static final StructuredLogger _instance = StructuredLogger._internal();
  factory StructuredLogger() => _instance;
  StructuredLogger._internal();

  // 当前日志级别
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  
  // 日志缓存（用于上报）
  final List<Map<String, dynamic>> _logBuffer = [];
  
  // 上下文信息
  String? _userId;
  String? _sessionId;
  Map<String, dynamic> _globalContext = {};

  /// 设置全局上下文
  void setContext({
    String? userId,
    String? sessionId,
    Map<String, dynamic>? extras,
  }) {
    _userId = userId;
    _sessionId = sessionId;
    if (extras != null) {
      _globalContext.addAll(extras);
    }
  }

  /// Debug日志
  void debug(String message, {
    Map<String, dynamic>? context,
    String? category,
  }) {
    _log(LogLevel.debug, message, context: context, category: category);
  }

  /// Info日志
  void info(String message, {
    Map<String, dynamic>? context,
    String? category,
  }) {
    _log(LogLevel.info, message, context: context, category: category);
  }

  /// Warning日志
  void warning(String message, {
    Map<String, dynamic>? context,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      context: context,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error日志
  void error(String message, {
    Map<String, dynamic>? context,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      context: context,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Fatal日志
  void fatal(String message, {
    Map<String, dynamic>? context,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.fatal,
      message,
      context: context,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录日志
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.toString().split('.').last.toUpperCase(),
      'message': message,
      'category': category ?? 'app',
      'user_id': _userId,
      'session_id': _sessionId,
      'context': {
        ..._globalContext,
        ...?context,
      },
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    };

    // 输出到控制台
    _printLog(logEntry);

    // 添加到缓冲区
    _logBuffer.add(logEntry);

    // 保持最近1000条
    if (_logBuffer.length > 1000) {
      _logBuffer.removeAt(0);
    }

    // 错误级别立即上报
    if (level.index >= LogLevel.error.index) {
      _reportError(logEntry);
    }
  }

  /// 打印日志到控制台
  void _printLog(Map<String, dynamic> logEntry) {
    final level = logEntry['level'];
    final message = logEntry['message'];
    final category = logEntry['category'];
    
    // 彩色输出（在支持的终端）
    final emoji = _getLevelEmoji(level);
    final output = '$emoji [$level] [$category] $message';
    
    debugPrint(output);
    
    // 如果有额外上下文，也打印出来
    if (logEntry['context'] != null && (logEntry['context'] as Map).isNotEmpty) {
      debugPrint('  Context: ${jsonEncode(logEntry['context'])}');
    }
  }

  String _getLevelEmoji(String level) {
    switch (level) {
      case 'DEBUG':
        return '🐛';
      case 'INFO':
        return 'ℹ️';
      case 'WARNING':
        return '⚠️';
      case 'ERROR':
        return '❌';
      case 'FATAL':
        return '💀';
      default:
        return '📝';
    }
  }

  /// 上报错误
  void _reportError(Map<String, dynamic> logEntry) {
    // 上报到友盟（如果需要，可以在这里添加实际的上报逻辑）
    // UmengAnalyticsService().trackEvent('app_error', {
    //   'level': logEntry['level'],
    //   'message': logEntry['message'],
    //   'category': logEntry['category'],
    // });
  }

  /// 获取所有日志
  List<Map<String, dynamic>> getLogs() {
    return List.from(_logBuffer);
  }

  /// 清空日志
  void clearLogs() {
    _logBuffer.clear();
  }
}

/// 链路追踪（Distributed Tracing）
class TracingService {
  static final TracingService _instance = TracingService._internal();
  factory TracingService() => _instance;
  TracingService._internal();

  // Span栈（用于嵌套追踪）
  final List<Span> _spanStack = [];
  
  // 完成的Spans
  final List<Span> _completedSpans = [];

  /// 开始一个Span
  Span startSpan(String operationName, {
    Map<String, dynamic>? tags,
    Span? parent,
  }) {
    final span = Span(
      operationName: operationName,
      startTime: DateTime.now(),
      tags: tags ?? {},
      parent: parent ?? (_spanStack.isNotEmpty ? _spanStack.last : null),
    );

    _spanStack.add(span);
    
    StructuredLogger().debug(
      'Trace started: $operationName',
      category: 'tracing',
      context: {'trace_id': span.traceId},
    );

    return span;
  }

  /// 结束一个Span
  void endSpan(Span span, {Map<String, dynamic>? tags}) {
    span.endTime = DateTime.now();
    
    if (tags != null) {
      span.tags.addAll(tags);
    }

    _spanStack.remove(span);
    _completedSpans.add(span);

    final duration = span.endTime!.difference(span.startTime);
    
    StructuredLogger().debug(
      'Trace completed: ${span.operationName} (${duration.inMilliseconds}ms)',
      category: 'tracing',
      context: {
        'trace_id': span.traceId,
        'duration_ms': duration.inMilliseconds,
      },
    );

    // 保持最近100个
    if (_completedSpans.length > 100) {
      _completedSpans.removeAt(0);
    }
  }

  /// 便捷方法：追踪异步操作
  Future<T> trace<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? tags,
  }) async {
    final span = startSpan(operationName, tags: tags);
    
    try {
      final result = await operation();
      span.setTag('success', true);
      return result;
    } catch (e, stackTrace) {
      span.setTag('success', false);
      span.setTag('error', e.toString());
      span.setTag('stack_trace', stackTrace.toString());
      rethrow;
    } finally {
      endSpan(span);
    }
  }

  /// 便捷方法：追踪同步操作
  T traceSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? tags,
  }) {
    final span = startSpan(operationName, tags: tags);
    
    try {
      final result = operation();
      span.setTag('success', true);
      return result;
    } catch (e) {
      span.setTag('success', false);
      span.setTag('error', e.toString());
      rethrow;
    } finally {
      endSpan(span);
    }
  }

  /// 获取所有完成的Spans
  List<Span> getCompletedSpans() {
    return List.from(_completedSpans);
  }

  /// 生成火焰图数据
  Map<String, dynamic> generateFlameGraph() {
    // TODO: 实现火焰图数据生成
    return {};
  }
}

/// Span（跨度/追踪段）
class Span {
  final String traceId;
  final String spanId;
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic> tags;
  final Span? parent;

  Span({
    required this.operationName,
    required this.startTime,
    required this.tags,
    this.parent,
  })  : traceId = parent?.traceId ?? _generateId(),
        spanId = _generateId();

  Duration? get duration => endTime?.difference(startTime);

  void setTag(String key, dynamic value) {
    tags[key] = value;
  }

  Map<String, dynamic> toJson() {
    return {
      'trace_id': traceId,
      'span_id': spanId,
      'parent_span_id': parent?.spanId,
      'operation_name': operationName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_ms': duration?.inMilliseconds,
      'tags': tags,
    };
  }

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}

/// 使用示例
/// 
/// ```dart
/// // 1. 设置日志上下文
/// StructuredLogger().setContext(
///   userId: '12345',
///   sessionId: 'abc-def-ghi',
///   extras: {
///     'app_version': '1.0.5',
///     'platform': Platform.operatingSystem,
///   },
/// );
/// 
/// // 2. 记录结构化日志
/// StructuredLogger().info(
///   'User logged in',
///   category: 'auth',
///   context: {
///     'username': 'john',
///     'login_method': 'password',
///   },
/// );
/// 
/// // 3. 链路追踪
/// await TracingService().trace('fetch_notes', () async {
///   // 1. API调用
///   await TracingService().trace('api_call', () async {
///     return await apiService.fetchNotes();
///   });
///   
///   // 2. 数据库存储
///   await TracingService().trace('db_save', () async {
///     return await dbService.saveNotes(notes);
///   });
///   
///   // 3. UI更新
///   TracingService().traceSync('ui_update', () {
///     notifyListeners();
///   });
/// });
/// 
/// // 4. 查看追踪结果
/// final spans = TracingService().getCompletedSpans();
/// for (final span in spans) {
///   print('${span.operationName}: ${span.duration?.inMilliseconds}ms');
/// }
/// 
/// // 5. 错误日志
/// try {
///   await riskyOperation();
/// } catch (e, stackTrace) {
///   StructuredLogger().error(
///     'Operation failed',
///     category: 'sync',
///     error: e,
///     stackTrace: stackTrace,
///     context: {
///       'operation': 'sync_notes',
///       'retry_count': 3,
///     },
///   );
/// }
/// ```

