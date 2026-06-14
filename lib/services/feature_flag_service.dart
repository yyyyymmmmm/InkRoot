// 🚀 大厂标准：功能开关服务（Feature Flag）
// 用途：
// 1. A/B测试
// 2. 灰度发布
// 3. 功能开关
// 4. 应急降级

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 功能开关服务
class FeatureFlagService {
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();
  static final FeatureFlagService _instance = FeatureFlagService._internal();

  static const Logger _log = Logger('FeatureFlag');

  // 本地缓存
  final Map<String, dynamic> _cache = {};

  // 🚀 从配置中心读取默认值
  static Map<String, dynamic> get _defaults => AppConfig.defaultFeatureFlags;

  /// 初始化（从远程配置服务器获取）
  Future<void> init() async {
    await _loadFromLocal();
    await _fetchFromRemote();
  }

  /// 从本地存储加载
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(AppConfig.prefKeyFeatureFlags);

      if (cached != null) {
        final Map<String, dynamic> data = json.decode(cached);
        _cache.addAll(data);
      }
    } on Object catch (e) {
      _log.warning(
        'Failed to load feature flags from local cache',
        data: {'error': e.toString()},
      );
    }
  }

  /// 从远程服务器获取最新配置
  Future<void> _fetchFromRemote() async {
    final uri = _remoteConfigUri(AppConfig.featureFlagServerUrl);
    if (uri == null) {
      return;
    }

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: AppConfig.featureFlagTimeoutSeconds));

      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteConfig = json.decode(response.body);

        // 更新缓存
        _cache.addAll(remoteConfig);

        // 保存到本地
        await _saveToLocal();
      }
    } on Object catch (e) {
      // 静默失败，使用本地缓存或默认值
      _log.debug(
        'Remote feature flags unavailable; using local/default flags',
        data: {'error': e.toString()},
      );
    }
  }

  Uri? _remoteConfigUri(String rawUrl) {
    final remoteUrl = rawUrl.trim();
    if (remoteUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(remoteUrl);
    if (uri == null ||
        !uri.isAbsolute ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _log.debug(
        'Ignored invalid feature flag URL',
        data: {'url': remoteUrl},
      );
      return null;
    }

    return uri;
  }

  /// 保存到本地
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.prefKeyFeatureFlags, json.encode(_cache));
    } on Object catch (e) {
      _log.warning(
        'Failed to save feature flags',
        data: {'error': e.toString()},
      );
    }
  }

  /// 获取布尔类型的功能开关
  bool getBool(String key, {bool? defaultValue}) {
    if (_cache.containsKey(key)) {
      return _cache[key] as bool? ?? defaultValue ?? _defaults[key] ?? false;
    }
    return defaultValue ?? _defaults[key] ?? false;
  }

  /// 获取字符串类型的配置
  String getString(String key, {String? defaultValue}) {
    if (_cache.containsKey(key)) {
      return _cache[key] as String? ?? defaultValue ?? _defaults[key] ?? '';
    }
    return defaultValue ?? _defaults[key] ?? '';
  }

  /// 获取整数类型的配置
  int getInt(String key, {int? defaultValue}) {
    if (_cache.containsKey(key)) {
      return _cache[key] as int? ?? defaultValue ?? _defaults[key] ?? 0;
    }
    return defaultValue ?? _defaults[key] ?? 0;
  }

  /// 获取双精度类型的配置
  double getDouble(String key, {double? defaultValue}) {
    if (_cache.containsKey(key)) {
      return _cache[key] as double? ?? defaultValue ?? _defaults[key] ?? 0.0;
    }
    return defaultValue ?? _defaults[key] ?? 0.0;
  }

  /// 检查功能是否启用
  bool isEnabled(String featureName) => getBool(featureName);

  /// 手动设置功能开关（用于本地测试）
  Future<void> setFlag(String key, Object? value) async {
    _cache[key] = value;
    await _saveToLocal();
  }

  /// 重置所有功能开关为默认值
  Future<void> resetToDefaults() async {
    _cache.clear();
    _cache.addAll(_defaults);
    await _saveToLocal();
  }

  /// 获取所有功能开关
  Map<String, dynamic> getAllFlags() => Map.from(_cache);

  /// 刷新远程配置
  Future<void> refresh() async {
    await _fetchFromRemote();
  }
}

/// 灰度发布控制器
class GrayReleaseController {
  factory GrayReleaseController() => _instance;
  GrayReleaseController._internal();
  static final GrayReleaseController _instance =
      GrayReleaseController._internal();

  /// 检查当前用户是否在灰度范围内
  ///
  /// [featureName] 功能名称
  /// [percentage] 灰度比例（0-100）
  /// [userId] 用户ID（用于一致性哈希）
  bool isInGrayRelease(String featureName, int percentage, String userId) {
    if (percentage <= 0) {
      return false;
    }
    if (percentage >= 100) {
      return true;
    }

    // 使用一致性哈希确保同一用户始终得到相同结果
    final hash = _hashUserId(featureName, userId);
    final bucket = hash % 100;

    return bucket < percentage;
  }

  /// 计算用户ID的哈希值
  int _hashUserId(String featureName, String userId) {
    final combined = '$featureName:$userId';
    return combined.hashCode.abs();
  }

  /// 根据白名单判断
  bool isInWhitelist(String userId, List<String> whitelist) =>
      whitelist.contains(userId);

  /// 根据用户属性判断
  bool matchUserSegment({
    required String userId,
    String? platform, // 'ios' | 'android'
    String? appVersion,
    String? country,
    Map<String, dynamic>? customAttrs,
  }) {
    // 可以根据用户属性进行更精细的控制
    // 例如：只对iOS用户开放、只对特定版本开放等
    return true; // 默认实现
  }
}

/// A/B测试服务
class ABTestService {
  factory ABTestService() => _instance;
  ABTestService._internal();
  static final ABTestService _instance = ABTestService._internal();

  /// 获取A/B测试变体
  ///
  /// [experimentId] 实验ID
  /// [userId] 用户ID
  /// [variants] 变体列表及其权重，例如: {'A': 50, 'B': 50}
  String getVariant(
    String experimentId,
    String userId,
    Map<String, int> variants,
  ) {
    if (variants.isEmpty) {
      return 'default';
    }
    if (variants.length == 1) {
      return variants.keys.first;
    }

    // 计算总权重
    final totalWeight = variants.values.reduce((a, b) => a + b);

    // 使用一致性哈希分桶
    final hash = _hashUserId(experimentId, userId);
    final bucket = hash % totalWeight;

    // 根据权重分配变体
    var cumulative = 0;
    for (final entry in variants.entries) {
      cumulative += entry.value;
      if (bucket < cumulative) {
        return entry.key;
      }
    }

    return variants.keys.first; // 兜底
  }

  int _hashUserId(String experimentId, String userId) {
    final combined = '$experimentId:$userId';
    return combined.hashCode.abs();
  }

  /// 记录实验曝光
  void trackExposure(String experimentId, String variant, String userId) {
    // 后续可接入数据分析平台。
    FeatureFlagService._log.info(
      'AB test exposure',
      data: {
        'experimentId': experimentId,
        'variant': variant,
        'userId': userId,
      },
    );
  }

  /// 记录实验转化
  void trackConversion(
    String experimentId,
    String variant,
    String userId,
    Map<String, dynamic>? metrics,
  ) {
    // 后续可接入转化数据上报。
    FeatureFlagService._log.info(
      'AB test conversion',
      data: {
        'experimentId': experimentId,
        'variant': variant,
        'userId': userId,
        if (metrics != null) 'metrics': metrics,
      },
    );
  }
}

/// 使用示例
///
/// ```dart
/// // 1. 初始化
/// await FeatureFlagService().init();
///
/// // 2. 检查功能是否启用
/// if (FeatureFlagService().isEnabled('enable_new_ui')) {
///   // 显示新UI
/// }
///
/// // 3. 灰度发布（逐步放量）
/// final userId = UserProvider.instance.userId;
/// if (GrayReleaseController().isInGrayRelease('new_feature', 10, userId)) {
///   // 10%用户使用新功能
/// }
///
/// // 4. A/B测试
/// final variant = ABTestService().getVariant(
///   'homepage_redesign',
///   userId,
///   {'A': 50, 'B': 50}, // 50-50分流
/// );
///
/// if (variant == 'A') {
///   // 显示版本A
/// } else {
///   // 显示版本B
/// }
/// ```
