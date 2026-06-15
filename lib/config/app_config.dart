import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:inkroot/config/app_identity.dart';
import 'package:inkroot/services/app_info_service.dart';

/// 🚀 大厂标准：应用配置中心
/// 统一管理所有配置常量，便于维护和切换环境
class AppConfig {
  // ==================== 应用基本信息 ====================

  /// 应用名称
  static const String appName = AppIdentity.name;

  /// 应用展示名称
  static const String appDisplayName = AppIdentity.displayName;

  /// 应用完整名称
  static const String appFullName = AppIdentity.fullName;

  /// 应用版本（单一真源：来自打包元数据 / pubspec.yaml）
  static String get appVersion => AppInfoService.version;

  /// 构建号（单一真源：来自打包元数据 / pubspec.yaml）
  static int get buildNumber => int.tryParse(AppInfoService.buildNumber) ?? 0;

  /// 应用ID
  static const String appId = String.fromEnvironment(
    'CLOUD_VERIFY_APP_ID',
  );

  /// 应用密钥
  static const String appKey = String.fromEnvironment(
    'CLOUD_VERIFY_APP_KEY',
  );

  /// 应用包名
  static const String packageName = AppIdentity.packageName;

  /// 默认 WebDAV 同步路径
  static const String defaultWebDavPath = AppIdentity.defaultWebDavPath;

  // ==================== 环境配置 ====================

  /// 当前环境（development, staging, production）
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// 是否生产环境
  static bool get isProduction => environment == 'production';

  /// 是否开发环境
  static bool get isDevelopment => environment == 'development';

  /// 是否为正式发布构建。
  /// Release 包必须默认关闭调试输出，不能依赖额外 dart-define。
  static bool get isReleaseBuild => kReleaseMode;

  // ==================== 服务器配置 ====================

  /// 官方Memos服务器地址
  static const String officialMemosServer = 'https://memos.didichou.site';

  /// API基础地址
  static const String apiBaseUrl = 'https://api.didichou.site';

  /// 云验证API地址
  static const String cloudVerificationUrl = '$apiBaseUrl/api.php';

  /// 应用更新检查地址
  static const String appUpdateUrl = '$apiBaseUrl/admin/applist.php';

  /// 云公告URL
  static String getCloudNoticeUrl() => '$apiBaseUrl/notice.php';

  // ==================== 🚀 Sentry监控配置 ====================

  /// Sentry DSN（错误追踪）
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
  );

  /// Sentry追踪采样率
  static double get sentrySampleRate => isProduction ? 0.2 : 1.0;

  /// Sentry性能分析采样率
  static double get sentryProfilesSampleRate => isProduction ? 0.2 : 1.0;

  // ==================== 🚀 性能监控配置 ====================

  /// 性能监控阈值
  static const Map<String, num> performanceThresholds = {
    'app_start_time': 3000, // 启动时间阈值：3秒
    'page_load_time': 2000, // 页面加载阈值：2秒
    'api_response_time': 5000, // API响应阈值：5秒
    'memory_usage_mb': 200, // 内存使用阈值：200MB
    'fps_drop': 45, // FPS掉帧阈值：45
  };

  // ==================== 🚀 告警配置 ====================

  /// 告警阈值规则
  static const Map<String, num> alertThresholds = {
    'crash_rate': 0.01, // 崩溃率 > 1% 告警
    'api_error_rate': 0.05, // API错误率 > 5% 告警
    'app_start_slow': 3000, // 启动 > 3秒告警
    'memory_high': 200, // 内存 > 200MB告警
  };

  /// 告警窗口时间（分钟）
  static const int alertWindowMinutes = 5;

  // ==================== 🚀 功能开关配置 ====================

  /// 功能开关服务器地址（可选，不使用可不设置）
  /// 用途：远程动态控制功能开关，比如临时关闭某个出问题的功能
  /// 现在不需要：功能开关存在本地就够用了
  static const String featureFlagServerUrl = String.fromEnvironment(
    'FEATURE_FLAG_URL',
  );

  /// 默认功能开关
  static const Map<String, bool> defaultFeatureFlags = {
    'dark_mode': true,
    'ai_assistant': true,
    'webdav_sync': true,
    'local_reference': true,
    'graph_view': true,
    'speech_to_text': false,
  };

  // ==================== 🚀 友盟统计配置 ====================

  /// 友盟 Android AppKey。正式构建通过 dart-define/Gradle 属性注入；
  /// 源码不保留生产统计密钥。
  static const String umengAndroidAppKey = String.fromEnvironment(
    'UMENG_ANDROID_APPKEY',
  );

  /// 友盟 iOS AppKey。当前 iOS 端不启用友盟统计。
  static const String umengIOSAppKey = String.fromEnvironment(
    'UMENG_IOS_APPKEY',
  );

  /// 友盟渠道号
  static const String umengChannel = String.fromEnvironment(
    'UMENG_CHANNEL',
    defaultValue: 'default',
  );

  /// 是否启用友盟统计
  static bool get enableUmengAnalytics =>
      enableAnalytics &&
      (umengAndroidAppKey.isNotEmpty || umengIOSAppKey.isNotEmpty);

  // ==================== 🚀 百度语音识别配置 ====================

  /// 百度语音识别 API Key
  /// 应用名称：墨根
  /// 应用描述：用于语音识别
  /// 应用ID：7257984
  static const String baiduSpeechApiKey = String.fromEnvironment(
    'BAIDU_SPEECH_API_KEY',
  );

  /// 百度语音识别 Secret Key
  static const String baiduSpeechSecretKey = String.fromEnvironment(
    'BAIDU_SPEECH_SECRET_KEY',
  );

  /// 百度语音识别应用ID
  static const String baiduSpeechAppId = String.fromEnvironment(
    'BAIDU_SPEECH_APP_ID',
  );

  /// 是否启用百度语音识别
  static const bool enableBaiduSpeech = bool.fromEnvironment(
    'ENABLE_BAIDU_SPEECH',
  );

  // ==================== 🚀 AI配置 ====================

  /// AI模型常量
  static const String aiModelDeepSeek = 'deepseek-chat';
  static const String aiModelGPT35 = 'gpt-3.5-turbo';
  static const String aiModelGPT4 = 'gpt-4';

  /// 默认AI模型
  static const String defaultAIModel = aiModelDeepSeek;

  /// AI请求超时时间（秒）
  static const int aiRequestTimeoutSeconds = 30;

  /// AI最大token数
  static const int aiMaxTokens = 2000;

  // ==================== 🚀 Native通信配置 ====================

  /// MethodChannel名称 - 通知/闹钟
  static const String channelNativeAlarm = 'com.didichou.inkroot/native_alarm';

  /// MethodChannel名称 - 友盟统计
  static const String channelUmeng = 'com.didichou.inkroot/umeng';

  // ==================== 🚀 同步配置 ====================

  /// 默认同步间隔（秒）
  static const int defaultSyncIntervalSeconds = 300; // 5分钟

  /// 最小同步间隔（秒）
  static const int minSyncIntervalSeconds = 60; // 1分钟

  /// 最大同步间隔（秒）
  static const int maxSyncIntervalSeconds = 3600; // 1小时

  // ==================== 🚀 灰度发布配置 ====================

  /// 灰度发布阶段
  static const List<int> canaryStages = [1, 5, 10, 50, 100];

  /// 当前灰度百分比
  static const int canaryPercentage = int.fromEnvironment(
    'CANARY_PERCENTAGE',
    defaultValue: 100,
  );

  // ==================== 🚀 数据库配置 ====================

  /// 数据库名称
  static const String databaseName = 'notes.db';

  /// 数据库版本
  static const int databaseVersion = 8;

  /// 表名 - 笔记表
  static const String tableNotes = 'notes';

  /// 表名 - 提醒通知表
  static const String tableReminders = 'reminder_notifications';

  // ==================== 🚀 SharedPreferences Keys ====================

  /// 配置键 - 应用配置
  static const String prefKeyAppConfig = 'app_config';

  /// 配置键 - 用户信息
  static const String prefKeyUserInfo = 'user_info';

  /// 配置键 - 首次启动
  static const String prefKeyFirstLaunch = 'first_launch';

  /// 配置键 - 认证令牌
  static const String prefKeyAuthToken = 'auth_token';

  /// 配置键 - 刷新令牌
  static const String prefKeyRefreshToken = 'refresh_token';

  /// 配置键 - 服务器地址
  static const String prefKeyServerUrl = 'server_url';

  /// 配置键 - 用户名
  static const String prefKeyUsername = 'username';

  /// 配置键 - 密码
  static const String prefKeyPassword = 'password';

  /// 配置键 - 隐私政策同意
  static const String prefKeyPrivacyPolicy = 'privacy_policy_agreed';

  /// 配置键 - 已同意法律文档版本
  static const String prefKeyLegalAcceptedVersion = 'legal_accepted_version';

  /// 配置键 - 法律文档同意时间
  static const String prefKeyLegalAcceptedAt = 'legal_accepted_at';

  /// 配置键 - 上次同步时间
  static const String prefKeyLastSyncTime = 'last_sync_time';

  /// 配置键 - 功能开关
  static const String prefKeyFeatureFlags = 'feature_flags';

  // ==================== 🚀 AI提示词模板 ====================

  /// AI默认系统提示词
  static const String aiDefaultPrompt = '''
你是一个专业的笔记助手，帮助用户更好地管理和理解他们的笔记。
你的任务包括：
1. 帮助用户总结和提炼笔记内容
2. 回答用户关于笔记内容的问题
3. 提供写作建议和改进意见
4. 帮助用户建立知识之间的联系

请用简洁、专业的语言回复，保持友好和有帮助的态度。''';

  /// AI总结提示词
  static const String aiSummaryPrompt = '''
你是一个专业的内容总结专家。
请用简洁的语言总结用户提供的内容，突出要点和关键信息。
总结应该：
1. 简明扼要，不超过原文的30%
2. 保留关键信息和要点
3. 使用清晰的结构（如使用序号或要点）
4. 使用中文回复''';

  /// AI扩展提示词
  static const String aiExpandPrompt = '''
你是一个专业的内容扩展专家。
请帮助用户扩展和丰富他们的笔记内容。
扩展时应该：
1. 补充相关的背景信息
2. 提供更多的细节和例子
3. 增加深度和广度
4. 保持内容的连贯性和逻辑性
5. 使用中文回复''';

  /// AI改进提示词
  static const String aiImprovePrompt = '''
你是一个专业的写作顾问。
请帮助用户改进他们的笔记内容。
改进建议应该：
1. 指出表达不清晰的地方
2. 提供更好的表达方式
3. 改善文章结构和逻辑
4. 纠正错误并提升质量
5. 使用中文回复''';

  // ==================== 🚀 超时与延迟配置 ====================

  /// 功能开关加载超时（秒）
  static const int featureFlagTimeoutSeconds = 5;

  /// FPS监控间隔（秒）- 生产环境建议 5-10 秒，避免性能开销
  static int get fpsMonitorIntervalSeconds => isProduction ? 10 : 5;

  /// 性能上报间隔（分钟）- 生产环境建议 5-10 分钟
  static int get performanceReportIntervalMinutes => isProduction ? 10 : 5;

  /// Snackbar显示时长（秒）
  static const int snackbarDurationSeconds = 3;

  /// Toast显示时长（秒）
  static const int toastDurationSeconds = 2;

  /// 页面切换延迟（毫秒）
  static const int pageTransitionDelayMs = 300;

  // ==================== 🚀 通知配置 ====================

  /// Android通知渠道ID
  static const String notificationChannelId = 'note_reminders_v2';

  /// 通知渠道名称
  static const String notificationChannelName = '笔记提醒';

  /// 通知渠道描述
  static const String notificationChannelDesc = '用于笔记定时提醒通知';

  // ==================== 缓存配置 ====================

  /// 图片缓存最大数量
  static const int maxImageCacheCount = 100;

  /// 图片缓存最大大小（MB）
  static const int maxImageCacheSizeMB = 200;

  /// 笔记缓存过期时间（小时）
  static const int noteCacheExpiryHours = 24;

  /// AI相关笔记缓存时间（小时）
  static const int aiRelatedNotesCacheHours = 6;

  /// 缓存键前缀
  static const String cacheKeyPrefix = 'inkroot_';

  /// 笔记相关缓存前缀
  static const String noteCachePrefix = 'note_related_';

  /// 统计数据缓存时间（分钟）
  static const int statsCacheMinutes = 5;

  // ==================== 🚀 错误消息模板 ====================

  /// 网络超时错误
  static const String errorNetworkTimeout = '网络请求超时，请检查网络连接';

  /// 服务器错误
  static const String errorServerError = '服务器错误，请稍后重试';

  /// 认证失败
  static const String errorInvalidCredentials = '用户名或密码错误';

  /// 权限不足
  static const String errorPermissionDenied = '权限不足，请联系管理员';

  /// 数据未找到
  static const String errorNotFound = '请求的数据不存在';

  /// 请求过于频繁
  static const String errorTooManyRequests = '请求过于频繁，请稍后再试';

  /// 未知错误
  static const String errorUnknown = '发生未知错误，请重试';

  // ==================== 🚀 日志配置 ====================

  /// 是否启用详细日志（开发环境可能导致性能问题，建议关闭）
  static bool get enableVerboseLogging => false; // 改为 false 避免日志刷屏

  /// 日志文件最大大小（MB）
  static const int maxLogFileSizeMB = 10;

  /// 日志保留天数
  static const int logRetentionDays = 7;

  /// 是否启用性能日志（开发环境可能导致崩溃，建议关闭）
  static bool get enablePerformanceLogging => false; // 改为 false 避免性能开销

  /// 是否启用网络日志（大量网络请求时会导致日志刷屏）
  static bool get enableNetworkLogging => false; // 改为 false 避免日志刷屏

  // ==================== 网络配置 ====================

  /// 网络请求超时时间（秒）
  static const int requestTimeoutSeconds = 30;

  /// 最大重试次数
  static const int maxRetries = 3;

  /// 文件上传最大大小（MB）
  static const int maxUploadSizeMB = 32;

  // ==================== 反馈与支持 ====================

  /// 反馈邮箱
  static const String supportEmail = 'inkroot2025@gmail.com';

  /// 官方网站
  static const String officialWebsite = 'https://inkroot.cn/';

  /// 用户反馈地址
  static const String feedbackUrl = '$apiBaseUrl/feedback';

  /// 帮助文档地址
  static const String helpDocUrl = '$officialWebsite/help';

  /// GitHub仓库地址
  static const String githubRepo = 'https://github.com/yyyyymmmmm/InkRoot';

  // ==================== 法律文档 ====================

  /// 当前法律文档版本。修改协议或隐私政策时更新该值，用于触发重新确认。
  static const String legalDocumentVersion = '2026-06-15';

  /// 法律文档固定更新日期，避免页面每天显示伪更新。
  static const int legalUpdatedYear = 2026;
  static const int legalUpdatedMonth = 6;
  static const int legalUpdatedDay = 15;

  /// 隐私政策地址
  static const String privacyPolicyUrl = '${officialWebsite}privacy.html';

  /// 隐私政策 Uri
  static Uri get privacyPolicyUri => Uri.parse(privacyPolicyUrl);

  /// 用户协议地址
  static const String userAgreementUrl = '${officialWebsite}agreement.html';

  /// 用户协议 Uri
  static Uri get userAgreementUri => Uri.parse(userAgreementUrl);

  /// 账号与数据删除说明/申请地址
  static const String accountDeletionUrl =
      '${officialWebsite}account-deletion.html';

  /// 账号与数据删除 Uri
  static Uri get accountDeletionUri => Uri.parse(accountDeletionUrl);

  /// 开源协议地址
  static const String licenseUrl = '$githubRepo/blob/main/LICENSE';

  // ==================== 企业信息 ====================

  /// 公司名称
  static const String companyName = AppIdentity.name;

  /// 公司全称
  static const String companyFullName = AppIdentity.fullName;

  /// 公司地址
  static const String companyAddress = '陕西省西安市雁塔区';

  /// ICP备案号
  static const String icpLicense = '陕ICP备 20002445号-7A';

  /// 版权年份
  static const String copyrightYear = '2025';

  /// 版权声明
  static const String copyrightText = '© $copyrightYear $companyName';

  // ==================== 应用商店信息 ====================

  /// App Store ID（iOS）
  static const String appStoreId = '';

  /// Google Play包名（Android）
  static const String googlePlayPackage = packageName;

  // ==================== 功能开关 ====================

  /// 是否启用云验证
  /// 公告/配置接口依赖构建时注入的应用 ID 和密钥。
  /// iOS 仍不使用自有更新检查，但可以读取后端公告。
  static bool get enableCloudVerification =>
      appId.isNotEmpty && appKey.isNotEmpty;

  /// 是否启用自动更新检查
  /// ⚠️ iOS平台禁用（Apple要求更新必须通过App Store）
  static bool get enableAutoUpdate => Platform.isAndroid;

  /// 是否启用崩溃报告（Sentry）
  /// ⚠️ iOS平台禁用，Android平台可用
  static bool get enableCrashReporting => Platform.isAndroid;

  /// 是否启用用户行为分析
  static const bool enableAnalytics = false;

  /// 是否启用提醒功能（定时提醒）
  /// ⚠️ 设置为 false 可以禁用提醒功能
  /// 注意：这不影响系统通知功能，只是隐藏笔记的提醒设置菜单
  static const bool enableReminders = true;

  // ==================== 调试配置 ====================

  /// 是否启用调试模式
  static const bool debugMode = false;

  // ==================== 工具方法 ====================

  /// 获取完整的版本信息
  static String getFullVersionInfo() => '$appVersion+$buildNumber';

  /// 获取应用标识
  static String getAppIdentifier() => '$appName v$appVersion';

  /// 用于网络层（例如 User-Agent）
  static String get userAgent => AppInfoService.userAgent;

  /// 获取完整的版权信息
  static String getFullCopyrightInfo() =>
      '$copyrightText\n$companyFullName\n$icpLicense';

  /// 获取应用信息映射
  static Map<String, dynamic> getAppInfo() => {
        'appName': appName,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'packageName': packageName,
        'environment': environment,
        'isProduction': isProduction,
      };

  /// 获取监控配置
  static Map<String, dynamic> getMonitoringConfig() => {
        'sentryDsn': sentryDsn,
        'sentrySampleRate': sentrySampleRate,
        'performanceThresholds': performanceThresholds,
        'alertThresholds': alertThresholds,
      };

  /// 检查功能是否启用
  static bool isFeatureEnabled(String feature) =>
      defaultFeatureFlags[feature] ?? false;

  /// 获取性能阈值
  static num? getPerformanceThreshold(String metric) =>
      performanceThresholds[metric];

  /// 获取告警阈值
  static num? getAlertThreshold(String metric) => alertThresholds[metric];

  /// 获取友盟AppKey（根据平台）
  static String getUmengAppKey(bool isAndroid) =>
      isAndroid ? umengAndroidAppKey : umengIOSAppKey;

  /// 检查友盟是否已配置
  static bool get isUmengConfigured =>
      umengAndroidAppKey.isNotEmpty || umengIOSAppKey.isNotEmpty;

  /// 获取MethodChannel名称
  static String getChannelName(String channelType) {
    switch (channelType) {
      case 'alarm':
        return channelNativeAlarm;
      case 'umeng':
        return channelUmeng;
      default:
        return '';
    }
  }
}
