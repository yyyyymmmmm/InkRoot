import 'package:flutter/foundation.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/services/sentry_monitoring_service.dart';

/// 🚀 大厂标准：告警服务
///
/// 负责监控关键指标并触发告警
class AlertService {
  factory AlertService() => _instance;
  AlertService._internal();
  static final AlertService _instance = AlertService._internal();

  final _sentry = SentryMonitoringService();

  // 🚀 从配置中心读取告警规则
  Map<String, AlertRule> get _rules => {
        'crash_rate': AlertRule(
          name: 'crash_rate',
          threshold: AppConfig.getAlertThreshold('crash_rate') ?? 0.01,
          window: const Duration(minutes: 5),
          severity: AlertSeverity.critical,
        ),
        'api_error_rate': AlertRule(
          name: 'api_error_rate',
          threshold: AppConfig.getAlertThreshold('api_error_rate') ?? 0.05,
          window: const Duration(minutes: 5),
          severity: AlertSeverity.high,
        ),
        'app_start_slow': AlertRule(
          name: 'app_start_slow',
          threshold: AppConfig.getAlertThreshold('app_start_slow') ?? 3000,
          window: const Duration(minutes: 1),
          severity: AlertSeverity.medium,
        ),
        'memory_high': AlertRule(
          name: 'memory_high',
          threshold: AppConfig.getAlertThreshold('memory_high') ?? 200,
          window: const Duration(minutes: 1),
          severity: AlertSeverity.medium,
        ),
      };

  // 统计数据
  final Map<String, _MetricStats> _stats = {};

  /// 初始化告警服务
  void init() {
    debugPrint('✅ 告警服务已初始化');
  }

  /// 记录指标
  void recordMetric(String metricName, num value) {
    final stats = _stats.putIfAbsent(
      metricName,
      _MetricStats.new,
    );

    stats.add(value);

    // 检查是否触发告警
    _checkAlert(metricName, value);
  }

  /// 检查是否需要告警
  void _checkAlert(String metricName, num value) {
    final rule = _rules[metricName];
    if (rule == null) {
      return;
    }

    final stats = _stats[metricName];
    if (stats == null) {
      return;
    }

    // 检查阈值
    var shouldAlert = false;
    var reason = '';

    if (metricName.endsWith('_rate')) {
      // 比率类指标
      final rate = stats.getRate();
      if (rate > rule.threshold) {
        shouldAlert = true;
        reason =
            'Rate: ${(rate * 100).toStringAsFixed(2)}% > ${(rule.threshold * 100).toStringAsFixed(2)}%';
      }
    } else {
      // 数值类指标
      if (value > rule.threshold) {
        shouldAlert = true;
        reason = 'Value: $value > ${rule.threshold}';
      }
    }

    if (shouldAlert) {
      _triggerAlert(rule, reason, value);
    }
  }

  /// 触发告警
  void _triggerAlert(AlertRule rule, String reason, num value) {
    final alert = Alert(
      rule: rule,
      reason: reason,
      value: value,
      timestamp: DateTime.now(),
    );

    debugPrint('🚨 [Alert] ${rule.name}: $reason');

    // 发送到Sentry
    _sentry.captureMessage(
      'Alert: ${rule.name}',
      level: _getSentryLevel(rule.severity),
      extra: {
        'rule': rule.name,
        'reason': reason,
        'value': value,
        'threshold': rule.threshold,
        'severity': rule.severity.toString(),
      },
    );

    // 如果是Critical级别，额外发送错误事件
    if (rule.severity == AlertSeverity.critical) {
      _sentry.captureError(
        AlertException(alert),
        hint: 'Critical alert triggered',
      );
    }
  }

  /// 转换告警级别到Sentry级别
  dynamic _getSentryLevel(AlertSeverity severity) {
    // 返回dynamic以避免导入Sentry类型
    switch (severity) {
      case AlertSeverity.critical:
        return 'error';
      case AlertSeverity.high:
        return 'warning';
      case AlertSeverity.medium:
        return 'info';
      case AlertSeverity.low:
        return 'debug';
    }
  }

  /// 重置统计数据
  void reset() {
    _stats.clear();
  }
}

/// 告警规则
class AlertRule {
  AlertRule({
    required this.name,
    required this.threshold,
    required this.window,
    required this.severity,
  });
  final String name;
  final num threshold;
  final Duration window;
  final AlertSeverity severity;
}

/// 告警级别
enum AlertSeverity {
  critical, // P0 - 需要立即处理
  high, // P1 - 1小时内处理
  medium, // P2 - 当天处理
  low, // P3 - 本周处理
}

/// 告警事件
class Alert {
  Alert({
    required this.rule,
    required this.reason,
    required this.value,
    required this.timestamp,
  });
  final AlertRule rule;
  final String reason;
  final num value;
  final DateTime timestamp;
}

/// 告警异常（用于Sentry错误追踪）
class AlertException implements Exception {
  AlertException(this.alert);
  final Alert alert;

  @override
  String toString() => 'AlertException: ${alert.rule.name} - ${alert.reason}';
}

/// 指标统计
class _MetricStats {
  final List<num> _values = [];
  final List<DateTime> _timestamps = [];
  static const _maxSize = 100;

  void add(num value) {
    _values.add(value);
    _timestamps.add(DateTime.now());

    // 保持最近100个数据点
    if (_values.length > _maxSize) {
      _values.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  num getAverage() {
    if (_values.isEmpty) {
      return 0;
    }
    return _values.reduce((a, b) => a + b) / _values.length;
  }

  num getRate() {
    // 计算比率（用于error rate等指标）
    if (_values.isEmpty) {
      return 0;
    }
    final successCount = _values.where((v) => v == 0).length;
    return 1 - (successCount / _values.length);
  }

  num getMax() {
    if (_values.isEmpty) {
      return 0;
    }
    return _values.reduce((a, b) => a > b ? a : b);
  }
}
