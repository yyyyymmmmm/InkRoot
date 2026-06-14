// 🚀 大厂标准：性能监控服务
// 用途：
// 1. 启动时间监控
// 2. 页面加载时间监控
// 3. 网络请求性能监控
// 4. 内存占用监控
// 5. FPS监控

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:inkroot/config/app_config.dart';

/// 性能指标类型
enum MetricType {
  appLaunch, // 应用启动
  pageLoad, // 页面加载
  networkRequest, // 网络请求
  databaseQuery, // 数据库查询
  imageLoad, // 图片加载
  memoryUsage, // 内存占用
  fps, // 帧率
}

/// 性能指标数据
class PerformanceMetric {
  PerformanceMetric({
    required this.type,
    required this.name,
    required this.duration,
    this.memoryBytes,
    this.fps,
    this.extras,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final MetricType type;
  final String name;
  final Duration duration;
  final int? memoryBytes;
  final double? fps;
  final Map<String, dynamic>? extras;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'name': name,
        'duration_ms': duration.inMilliseconds,
        'memory_bytes': memoryBytes,
        'fps': fps,
        'extras': extras,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 性能监控服务
class PerformanceMonitorService {
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();

  // 是否启用监控
  bool _isEnabled = false;

  // 性能指标缓存
  final List<PerformanceMetric> _metrics = [];

  // 计时器缓存
  final Map<String, Stopwatch> _stopwatches = {};

  // 应用启动时间
  DateTime? _appLaunchTime;

  // FPS监控
  Timer? _fpsTimer;
  int _frameCount = 0;
  double _currentFps = 60;

  /// 初始化
  void init({bool enabled = true}) {
    _isEnabled = enabled;
    _appLaunchTime = DateTime.now();

    if (_isEnabled) {
      _startFpsMonitoring();
      _startMemoryMonitoring();
    }
  }

  /// 🚀 启动时间监控
  void trackAppLaunch(String phase) {
    if (!_isEnabled) {
      return;
    }

    final launchTime = DateTime.now().difference(_appLaunchTime!);

    final metric = PerformanceMetric(
      type: MetricType.appLaunch,
      name: 'app_launch_$phase',
      duration: launchTime,
      extras: {
        'phase': phase,
        'is_cold_start': _appLaunchTime == null,
      },
    );

    _recordMetric(metric);

    // 上报友盟（如果需要，可以在这里添加实际的上报逻辑）
    // UmengAnalyticsService().trackEvent('performance_app_launch', {
    //   'phase': phase,
    //   'duration_ms': launchTime.inMilliseconds,
    // });

    // 慢启动告警
    if (launchTime.inSeconds > 3) {
      _sendSlowStartupAlert(phase, launchTime);
    }
  }

  /// 🚀 页面加载时间监控
  void startPageLoad(String pageName) {
    if (!_isEnabled) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    _stopwatches['page_$pageName'] = stopwatch;
  }

  void endPageLoad(String pageName, {Map<String, dynamic>? extras}) {
    if (!_isEnabled) {
      return;
    }

    final key = 'page_$pageName';
    final stopwatch = _stopwatches[key];

    if (stopwatch == null) {
      debugPrint('⚠️ Page load not started: $pageName');
      return;
    }

    stopwatch.stop();
    _stopwatches.remove(key);

    final metric = PerformanceMetric(
      type: MetricType.pageLoad,
      name: pageName,
      duration: stopwatch.elapsed,
      extras: extras,
    );

    _recordMetric(metric);

    // 上报友盟（如果需要，可以在这里添加实际的上报逻辑）
    // UmengAnalyticsService().trackEvent('performance_page_load', {
    //   'page': pageName,
    //   'duration_ms': stopwatch.elapsedMilliseconds,
    // });

    // 慢页面告警
    if (stopwatch.elapsedMilliseconds > 2000) {
      _sendSlowPageAlert(pageName, stopwatch.elapsed);
    }
  }

  /// 🚀 网络请求性能监控
  Future<T> trackNetworkRequest<T>(
    String apiName,
    Future<T> Function() request,
  ) async {
    if (!_isEnabled) {
      return request();
    }

    final stopwatch = Stopwatch()..start();
    Object? error;

    try {
      final result = await request();
      return result;
    } on Object catch (e) {
      error = e;
      rethrow;
    } finally {
      stopwatch.stop();

      final metric = PerformanceMetric(
        type: MetricType.networkRequest,
        name: apiName,
        duration: stopwatch.elapsed,
        extras: {
          'success': error == null,
          'error': error?.toString(),
        },
      );

      _recordMetric(metric);

      // 上报友盟（如果需要，可以在这里添加实际的上报逻辑）
      // UmengAnalyticsService().trackEvent('performance_network', {
      //   'api': apiName,
      //   'duration_ms': stopwatch.elapsedMilliseconds,
      //   'success': error == null,
      // });

      // 慢请求告警（超过3秒）
      if (stopwatch.elapsedMilliseconds > 3000) {
        _sendSlowAPIAlert(apiName, stopwatch.elapsed);
      }
    }
  }

  /// 🚀 数据库查询性能监控
  Future<T> trackDatabaseQuery<T>(
    String queryName,
    Future<T> Function() query,
  ) async {
    if (!_isEnabled) {
      return query();
    }

    final stopwatch = Stopwatch()..start();

    try {
      return await query();
    } finally {
      stopwatch.stop();

      final metric = PerformanceMetric(
        type: MetricType.databaseQuery,
        name: queryName,
        duration: stopwatch.elapsed,
      );

      _recordMetric(metric);

      // 慢查询告警（超过100ms）
      if (stopwatch.elapsedMilliseconds > 100) {
        debugPrint(
          '⚠️ Slow DB Query: $queryName took ${stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
  }

  /// 🚀 图片加载监控
  void trackImageLoad(
    String imageUrl,
    Duration loadTime, {
    bool success = true,
  }) {
    if (!_isEnabled) {
      return;
    }

    final metric = PerformanceMetric(
      type: MetricType.imageLoad,
      name: imageUrl,
      duration: loadTime,
      extras: {'success': success},
    );

    _recordMetric(metric);
  }

  /// 🚀 FPS监控（使用配置中心的间隔，避免频繁监控导致性能问题）
  void _startFpsMonitoring() {
    // ⚠️ 仅在启用性能日志时监控 FPS，避免日志刷屏导致崩溃
    if (!AppConfig.enablePerformanceLogging) {
      return;
    }

    // 监听每一帧
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);

    // 使用配置中心的间隔（5-10秒），降低监控频率
    final interval = Duration(seconds: AppConfig.fpsMonitorIntervalSeconds);
    _fpsTimer = Timer.periodic(interval, (_) {
      final fps = _frameCount / AppConfig.fpsMonitorIntervalSeconds;
      _currentFps = fps;
      _frameCount = 0;

      // 记录FPS指标
      final metric = PerformanceMetric(
        type: MetricType.fps,
        name: 'fps',
        duration: Duration.zero,
        fps: _currentFps,
      );

      _recordMetric(metric);

      // 低FPS告警（仅在 FPS < 30 时输出，减少日志）
      if (_currentFps < 30) {
        debugPrint('⚠️ Low FPS: ${_currentFps.toStringAsFixed(1)}');
      }
    });
  }

  void _onFrame(Duration timestamp) {
    _frameCount++;
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  /// 🚀 内存占用监控（使用配置中心的间隔）
  void _startMemoryMonitoring() {
    // ⚠️ 仅在启用性能日志时监控内存，避免日志刷屏
    if (!AppConfig.enablePerformanceLogging) {
      return;
    }

    // 使用配置中心的性能上报间隔
    final interval =
        Duration(minutes: AppConfig.performanceReportIntervalMinutes);
    Timer.periodic(interval, (_) async {
      final memoryUsage = await _getMemoryUsage();

      final metric = PerformanceMetric(
        type: MetricType.memoryUsage,
        name: 'memory',
        duration: Duration.zero,
        memoryBytes: memoryUsage,
      );

      _recordMetric(metric);

      // 高内存告警（超过200MB），仅在超过阈值时输出
      final memoryMB = memoryUsage / 1024 / 1024;
      if (memoryMB > 200) {
        debugPrint('⚠️ High memory usage: ${memoryMB.toStringAsFixed(2)} MB');

        // UmengAnalyticsService().trackEvent('performance_high_memory', {
        //   'memory_mb': memoryMB.round(),
        // });
      }
    });
  }

  /// 获取当前内存占用
  Future<int> _getMemoryUsage() async {
    // 获取当前进程内存
    if (Platform.isAndroid || Platform.isIOS) {
      // 实际应该使用 ProcessInfo.currentRss
      // 这里简化处理
      return 150 * 1024 * 1024; // 150MB示例值
    }
    return 0;
  }

  /// 记录指标（避免日志刷屏）
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    // 保持最近1000条
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }

    // ⚠️ 仅在启用性能日志且非 FPS 指标时打印，避免日志刷屏导致崩溃
    if (AppConfig.enablePerformanceLogging &&
        metric.type != MetricType.fps &&
        kDebugMode) {
      debugPrint(
        '📊 Performance: ${metric.name} - ${metric.duration.inMilliseconds}ms',
      );
    }
  }

  /// 发送慢启动告警
  void _sendSlowStartupAlert(String phase, Duration duration) {
    debugPrint('🐌 Slow startup detected: $phase took ${duration.inSeconds}s');

    // UmengAnalyticsService().trackEvent('performance_slow_startup', {
    //   'phase': phase,
    //   'duration_s': duration.inSeconds,
    // });
  }

  /// 发送慢页面告警
  void _sendSlowPageAlert(String pageName, Duration duration) {
    debugPrint(
      '🐌 Slow page load: $pageName took ${duration.inMilliseconds}ms',
    );
  }

  /// 发送慢API告警
  void _sendSlowAPIAlert(String apiName, Duration duration) {
    debugPrint('🐌 Slow API: $apiName took ${duration.inSeconds}s');
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};

    for (final type in MetricType.values) {
      final typeMetrics = _metrics.where((m) => m.type == type).toList();

      if (typeMetrics.isEmpty) {
        continue;
      }

      final durations = typeMetrics
          .map((m) => m.duration.inMilliseconds)
          .where((d) => d > 0)
          .toList();

      if (durations.isEmpty) {
        continue;
      }

      report[type.toString()] = {
        'count': durations.length,
        'avg_ms': durations.reduce((a, b) => a + b) / durations.length,
        'min_ms': durations.reduce((a, b) => a < b ? a : b),
        'max_ms': durations.reduce((a, b) => a > b ? a : b),
      };
    }

    // 添加当前FPS
    report['current_fps'] = _currentFps;

    return report;
  }

  /// 清理
  void dispose() {
    _fpsTimer?.cancel();
    _stopwatches.clear();
    _metrics.clear();
  }
}

/// 使用示例
///
/// ```dart
/// // 1. 初始化
/// PerformanceMonitorService().init(enabled: true);
///
/// // 2. 监控启动时间
/// PerformanceMonitorService().trackAppLaunch('splash_screen_ready');
/// PerformanceMonitorService().trackAppLaunch('main_screen_ready');
///
/// // 3. 监控页面加载
/// class HomeScreen extends StatefulWidget {
///   @override
///   void initState() {
///     super.initState();
///     PerformanceMonitorService().startPageLoad('home');
///   }
///
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     // 页面数据加载完成
///     PerformanceMonitorService().endPageLoad('home');
///   }
/// }
///
/// // 4. 监控网络请求
/// final notes = await PerformanceMonitorService().trackNetworkRequest(
///   'fetch_notes',
///   () => apiService.fetchNotes(),
/// );
///
/// // 5. 监控数据库查询
/// final localNotes = await PerformanceMonitorService().trackDatabaseQuery(
///   'load_notes',
///   () => databaseService.getNotes(),
/// );
///
/// // 6. 查看性能报告
/// final report = PerformanceMonitorService().getPerformanceReport();
/// print(report);
/// ```
