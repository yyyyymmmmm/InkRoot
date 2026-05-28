// ⚠️ 移除Firebase依赖，使用轻量级本地性能追踪
// iOS版本不需要Firebase Performance
import 'package:flutter/foundation.dart';

/// 🚀 轻量级性能追踪工具类（无Firebase依赖）
/// 用于监控关键操作的性能指标（仅本地日志，不上报）
class PerformanceTracker {
  // 单例模式
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  // 存储活跃的追踪
  final Map<String, _TraceData> _activeTraces = {};

  /// 开始追踪一个操作
  Future<void> startTrace(
    String name, {
    Map<String, String>? attributes,
  }) async {
    try {
      final trace = _TraceData(
        name: name,
        attributes: attributes ?? {},
        stopwatch: Stopwatch()..start(),
      );
      
      _activeTraces[name] = trace;
      
      if (kDebugMode) {
        print('📊 [Performance] Started tracking: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Performance] Failed to start trace $name: $e');
      }
    }
  }

  /// 停止追踪一个操作
  Future<void> stopTrace(
    String name, {
    bool success = true,
    Map<String, int>? metrics,
  }) async {
    try {
      final trace = _activeTraces[name];
      
      if (trace == null) {
        if (kDebugMode) {
          print('⚠️ [Performance] Trace not found: $name');
        }
        return;
      }
      
      trace.stopwatch.stop();
      
      if (kDebugMode) {
        print(
          '📊 [Performance] Stopped tracking: $name '
          '(${trace.stopwatch.elapsedMilliseconds}ms, '
          'status: ${success ? 'success' : 'failure'})',
        );
        
        if (metrics != null) {
          print('   Metrics: $metrics');
        }
      }
      
      _activeTraces.remove(name);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Performance] Failed to stop trace $name: $e');
      }
    }
  }

  /// 追踪一个异步操作
  Future<T> trackAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    await startTrace(name, attributes: attributes);
    
    try {
      final result = await operation();
      await stopTrace(name, success: true);
      return result;
    } catch (e) {
      await stopTrace(name, success: false);
      rethrow;
    }
  }

  /// 追踪一个同步操作
  T trackSync<T>(
    String name,
    T Function() operation, {
    Map<String, String>? attributes,
  }) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      if (kDebugMode) {
        print(
          '📊 [Performance] $name completed in ${stopwatch.elapsedMilliseconds}ms',
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        print(
          '📊 [Performance] $name failed after ${stopwatch.elapsedMilliseconds}ms',
        );
      }
      
      rethrow;
    }
  }
}

/// 内部追踪数据类
class _TraceData {
  final String name;
  final Map<String, String> attributes;
  final Stopwatch stopwatch;

  _TraceData({
    required this.name,
    required this.attributes,
    required this.stopwatch,
  });
}

/// 🚀 轻量级页面性能追踪
class ScreenPerformanceTracker {
  final String screenName;
  final Stopwatch _stopwatch = Stopwatch();

  ScreenPerformanceTracker._(this.screenName);

  /// 创建并开始追踪
  static Future<ScreenPerformanceTracker> start(String screenName) async {
    final tracker = ScreenPerformanceTracker._(screenName);
    tracker._stopwatch.start();
    
    if (kDebugMode) {
      print('📊 [Screen] Started tracking: $screenName');
    }
    
    return tracker;
  }

  /// 标记首次渲染完成
  void markFirstRender() {
    if (kDebugMode) {
      print(
        '📊 [Screen] $screenName first render: ${_stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  /// 标记数据加载完成
  void markDataLoaded({int? itemCount}) {
    if (kDebugMode) {
      print(
        '📊 [Screen] $screenName data loaded: ${_stopwatch.elapsedMilliseconds}ms '
        '(items: $itemCount)',
      );
    }
  }

  /// 停止追踪
  Future<void> stop() async {
    _stopwatch.stop();
    
    if (kDebugMode) {
      print(
        '📊 [Screen] Stopped tracking: $screenName '
        '(total: ${_stopwatch.elapsedMilliseconds}ms)',
      );
    }
  }
}
