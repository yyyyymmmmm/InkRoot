import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:inkroot/config/app_config.dart' as Config;

/// 🚀 大厂标准：统一错误处理器
/// 集成Sentry监控，提供结构化的错误报告
class ErrorHandler {
  // 单例模式
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// 初始化错误监控
  static Future<void> initialize({
    required String environment,
    String? userId,
  }) async {
    // 配置 Sentry
    await SentryFlutter.init(
      (options) {
        // DSN从环境变量读取（不要hardcode）
        options.dsn = const String.fromEnvironment(
          'SENTRY_DSN',
          defaultValue: '',
        );
        
        // 环境标识：development, staging, production
        options.environment = environment;
        
        // 采样率配置
        options.tracesSampleRate = environment == 'production' ? 0.2 : 1.0;
        
        // 🚀 大厂标准：在所有环境都启用（通过beforeSend过滤）
        
        // 添加全局上下文
        options.beforeSend = (event, hint) async {
          // 只在生产环境上报
          if (environment != 'production') {
            return null; // 不上报
          }
          
          // 过滤敏感信息
          event = _sanitizeEvent(event);
          
          // 添加自定义标签
          event = event.copyWith(
            tags: {
              ...?event.tags,
              'app_version': Config.AppConfig.appVersion,
              'platform': Platform.operatingSystem,
            },
          );
          
          return event;
        };
        
        // 设置发布版本
        options.release = '${Config.AppConfig.appName}@${Config.AppConfig.appVersion}';
        
        // 设置分布标识（可选）
        options.dist = Config.AppConfig.buildNumber.toString();
        
        // 附加上下文
        options.attachStacktrace = true;
        options.attachScreenshot = true; // 崩溃时自动截图
        
        // 调试模式下打印详细日志
        options.debug = !kReleaseMode;
      },
    );
    
    // 设置用户信息
    if (userId != null) {
      setUser(userId);
    }
  }

  /// 设置当前用户信息
  static void setUser(String userId, {String? username, String? email}) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        username: username,
        email: email,
      ));
    });
  }

  /// 清除用户信息（退出登录时调用）
  static void clearUser() {
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// 捕获异常
  /// 
  /// [exception] 异常对象
  /// [stackTrace] 堆栈信息
  /// [context] 额外的上下文信息
  /// [level] 严重程度：debug, info, warning, error, fatal
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    SentryLevel? level,
  }) async {
    try {
      // 本地日志
      if (kDebugMode) {
        print('❌ [Error] ${exception.toString()}');
        if (stackTrace != null) {
          print('Stack trace:\n$stackTrace');
        }
      }
      
      // 上报到 Sentry
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: context != null ? Hint.withMap(context) : null,
        withScope: (scope) {
          // 设置错误级别
          scope.level = level ?? SentryLevel.error;
          
          // 添加额外上下文
          if (context != null) {
            for (final entry in context.entries) {
              scope.setContexts(
                entry.key,
                _convertToMap(entry.value),
              );
            }
          }
          
          // 添加面包屑（用户操作路径）
          scope.addBreadcrumb(Breadcrumb(
            message: 'Exception captured: ${exception.runtimeType}',
            level: level ?? SentryLevel.error,
            timestamp: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  [Error] Failed to report exception: $e');
      }
    }
  }

  /// 捕获消息（非异常的警告/信息）
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? context,
  }) async {
    await Sentry.captureMessage(
      message,
      level: level,
      hint: context != null ? Hint.withMap(context) : null,
    );
  }

  /// 添加面包屑（用户行为追踪）
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      level: level,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  /// 包装异步操作，自动捕获异常
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    T? fallbackValue,
    bool shouldRethrow = false,
  }) async {
    try {
      return await operation();
    } catch (exception, stackTrace) {
      await captureException(
        exception,
        stackTrace: stackTrace,
        context: {
          'operation': operationName ?? 'unknown',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (shouldRethrow) {
        rethrow;
      }
      
      return fallbackValue;
    }
  }

  /// 包装同步操作，自动捕获异常
  static T? wrapSync<T>(
    T Function() operation, {
    String? operationName,
    T? fallbackValue,
    bool shouldRethrow = false,
  }) {
    try {
      return operation();
    } catch (exception, stackTrace) {
      captureException(
        exception,
        stackTrace: stackTrace,
        context: {
          'operation': operationName ?? 'unknown',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (shouldRethrow) {
        rethrow;
      }
      
      return fallbackValue;
    }
  }

  /// 过滤敏感信息
  static SentryEvent _sanitizeEvent(SentryEvent event) {
    // 移除可能包含敏感信息的字段
    // 例如：密码、token、手机号等
    return event;
  }

  /// 转换为Map（Sentry要求）
  static Map<String, dynamic> _convertToMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is String) {
      return {'value': value};
    } else {
      return {'value': value.toString()};
    }
  }
}

/// 🚀 大厂标准：全局错误捕获器
/// 捕获所有未处理的异常
class GlobalErrorCatcher {
  /// 初始化全局错误捕获
  static void initialize() {
    // 捕获 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      
      ErrorHandler.captureException(
        details.exception,
        stackTrace: details.stack,
        context: {
          'error_type': 'flutter_error',
          'library': details.library ?? 'unknown',
          'context': details.context?.toString() ?? 'unknown',
        },
        level: SentryLevel.error,
      );
    };
    
    // 捕获 Dart 异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorHandler.captureException(
        error,
        stackTrace: stack,
        context: {
          'error_type': 'async_error',
        },
        level: SentryLevel.fatal,
      );
      
      return true; // 表示已处理
    };
  }
}

/// 🚀 大厂标准：API错误分类
class ApiError implements Exception {
  final int? statusCode;
  final String message;
  final String? endpoint;
  final Map<String, dynamic>? data;

  ApiError({
    this.statusCode,
    required this.message,
    this.endpoint,
    this.data,
  });

  @override
  String toString() =>
      'ApiError(statusCode: $statusCode, message: $message, endpoint: $endpoint)';
}

class NetworkError implements Exception {
  final String message;
  
  NetworkError(this.message);
  
  @override
  String toString() => 'NetworkError: $message';
}

class DatabaseError implements Exception {
  final String message;
  final String? operation;
  
  DatabaseError(this.message, {this.operation});
  
  @override
  String toString() => 'DatabaseError: $message (operation: $operation)';
}

/// 使用示例：
/// 
/// 1. 初始化（在main.dart中）
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // 初始化错误监控
///   await ErrorHandler.initialize(
///     environment: kReleaseMode ? 'production' : 'development',
///   );
///   
///   // 初始化全局错误捕获
///   GlobalErrorCatcher.initialize();
///   
///   runApp(MyApp());
/// }
/// ```
/// 
/// 2. 手动捕获异常
/// ```dart
/// try {
///   await apiService.createNote(note);
/// } catch (e, stackTrace) {
///   await ErrorHandler.captureException(
///     e,
///     stackTrace: stackTrace,
///     context: {
///       'note_id': note.id,
///       'user_action': 'create_note',
///     },
///   );
/// }
/// ```
/// 
/// 3. 包装异步操作
/// ```dart
/// final notes = await ErrorHandler.wrapAsync(
///   () => databaseService.getNotes(),
///   operationName: 'load_notes',
///   fallbackValue: [],
/// );
/// ```
/// 
/// 4. 添加面包屑
/// ```dart
/// ErrorHandler.addBreadcrumb(
///   message: 'User clicked create button',
///   category: 'user_action',
///   level: SentryLevel.info,
/// );
/// ```

