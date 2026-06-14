import 'package:flutter/foundation.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 🚀 大厂标准：Sentry监控告警服务
class SentryMonitoringService {
  factory SentryMonitoringService() => _instance;
  SentryMonitoringService._internal();
  static final SentryMonitoringService _instance =
      SentryMonitoringService._internal();

  bool _initialized = false;

  /// 初始化Sentry
  Future<void> init({required String dsn}) async {
    if (_initialized) {
      return;
    }

    await SentryFlutter.init(
      (options) {
        options
          ..dsn = dsn
          ..tracesSampleRate = AppConfig.sentrySampleRate
          ..environment = kReleaseMode ? 'production' : 'development'
          ..release = '${AppConfig.appName}@${AppConfig.appVersion}'
          ..dist = AppConfig.buildNumber.toString()
          ..enableAutoSessionTracking = true
          ..attachThreads = true
          ..attachStacktrace = true
          ..sendDefaultPii = false; // 不发送个人身份信息

        // 配置告警阈值
        options.maxBreadcrumbs = 100;
      },
    );

    _initialized = true;
    debugPrint('✅ Sentry监控已初始化');
  }

  /// 手动捕获错误
  void captureError(
    Object exception, {
    StackTrace? stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
  }) {
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'hint': hint}) : null,
      withScope: (scope) {
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setContexts(key, value);
          });
        }
      },
    );

    debugPrint('🚨 [Sentry] Error captured: $exception');
  }

  /// 记录消息
  void captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) {
    Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setContexts(key, value);
          });
        }
      },
    );
  }

  /// 添加面包屑（用户行为轨迹）
  void addBreadcrumb({
    required String message,
    required String category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// 开始性能追踪
  ISentrySpan startTransaction({
    required String name,
    required String operation,
    String? description,
  }) {
    final transaction = Sentry.startTransaction(
      name,
      operation,
      description: description,
      bindToScope: true,
    );

    return transaction;
  }

  /// 设置用户上下文
  void setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          email: email,
          username: username,
          data: extras,
        ),
      );
    });
  }

  /// 清除用户上下文（登出时调用）
  void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// 设置标签
  void setTag(String key, String value) {
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// 设置额外信息
  void setExtra(String key, Object? value) {
    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// 监控网络请求
  void trackNetworkRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? requestSize,
    int? responseSize,
  }) {
    addBreadcrumb(
      message: '$method $url',
      category: 'http',
      data: {
        'method': method,
        'url': url,
        'status_code': statusCode,
        'duration_ms': duration.inMilliseconds,
        if (requestSize != null) 'request_size': requestSize,
        if (responseSize != null) 'response_size': responseSize,
      },
      level: statusCode >= 400 ? SentryLevel.error : SentryLevel.info,
    );

    // 如果是错误请求，发送事件
    if (statusCode >= 500) {
      captureMessage(
        'Server Error: $method $url',
        level: SentryLevel.error,
        extra: {
          'url': url,
          'method': method,
          'status_code': statusCode,
          'duration': duration.inMilliseconds,
        },
      );
    }
  }

  /// 监控应用性能指标
  void trackPerformance({
    required String metricName,
    required num value,
    String? unit,
    Map<String, dynamic>? tags,
  }) {
    // 记录性能指标
    setExtra('metric_$metricName', value);

    if (tags != null) {
      tags.forEach((key, val) {
        setTag('${metricName}_$key', val.toString());
      });
    }

    // 如果超过阈值，发送警告
    // 🚀 从配置中心读取性能阈值
    const thresholds = AppConfig.performanceThresholds;

    final threshold = thresholds[metricName];
    if (threshold != null && value > threshold) {
      captureMessage(
        'Performance Warning: $metricName = $value$unit',
        level: SentryLevel.warning,
        extra: {
          'metric': metricName,
          'value': value,
          'unit': unit,
          'threshold': threshold,
          if (tags != null) 'tags': tags,
        },
      );
    }
  }

  /// 关闭Sentry
  Future<void> close() async {
    await Sentry.close();
    _initialized = false;
  }
}
