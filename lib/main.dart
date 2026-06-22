import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/routes/app_router.dart';
import 'package:inkroot/services/app_info_service.dart';
import 'package:inkroot/services/feature_flag_service.dart';
import 'package:inkroot/services/notification_service.dart';
import 'package:inkroot/services/observability_service.dart';
import 'package:inkroot/services/performance_monitor_service.dart';
import 'package:inkroot/themes/app_theme.dart';
// 🚀 大厂标准：新增工具
import 'package:inkroot/utils/error_handler.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/logger.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/tag_path_utils.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

// 🔥 全局NavigatorKey，用于通知点击跳转
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 需要在任何平台通道调用前初始化（package_info_plus 等）
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.AppConfig.isReleaseBuild) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // 🚀 大厂标准：初始化错误监控
  GlobalErrorCatcher.initialize();

  // 单一真源：初始化版本信息（来自 pubspec.yaml）
  await AppInfoService.init();

  // 🚀 大厂标准：Sentry错误监控（仅Android平台，iOS不使用以符合App Store审核）
  if (Platform.isAndroid) {
    await SentryFlutter.init(
      (options) {
        // ✅ 从配置中心读取Sentry配置
        options.dsn = Config.AppConfig.sentryDsn;
        options.tracesSampleRate = Config.AppConfig.sentrySampleRate;
        options.environment = Config.AppConfig.environment;
        options.release =
            '${Config.AppConfig.appName}@${Config.AppConfig.appVersion}';
        options.enableAutoSessionTracking = true;
        options.attachStacktrace = true;
        options.sendDefaultPii = false; // 不发送个人信息

        // 🔥 关键修复：禁用 Firebase 集成（避免 Firebase 未初始化错误）
        options.enableAutoPerformanceTracing = false; // 禁用自动性能追踪（需要 Firebase）
      },
      appRunner: () async {
        await _runApp();
      },
    );
  } else {
    // iOS平台：不使用Sentry，直接运行应用
    await _runApp();
  }
}

// 提取应用初始化逻辑到独立函数
Future<void> _runApp() async {
  // 🚀 初始化 Flutter 绑定并保留原生启动页
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 🚀 大厂标准：初始化日志系统
  Log.database.info('App starting...');
  Log.performance.debug('Flutter binding initialized');

  // 🚀 大厂标准：性能监控服务（默认关闭，避免日志刷屏影响用户体验）
  // 如需启用性能监控，请在 AppConfig 中设置 enablePerformanceLogging = true
  if (Config.AppConfig.enablePerformanceLogging) {
    PerformanceMonitorService().init();
    Log.performance.info('Performance monitor started');
  }

  // 设置全局 Flutter 错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Log.custom('FlutterError').error(
      'Unhandled Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );

    // 🚀 大厂标准：错误日志记录
    StructuredLogger().error(
      'Flutter Error',
      category: 'system',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );

    // 🚀 发送到Sentry（仅Android）
    if (Platform.isAndroid) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    }
  };

  await _initializeApp();
}

/// 初始化应用
Future<void> _initializeApp() async {
  // 🚀 大厂标准：记录应用启动开始
  PerformanceMonitorService().trackAppLaunch('init_start');

  // 🚀 大厂标准：启用功能开关
  await FeatureFlagService().init();
  Log.service.info('Feature flag service initialized');

  // 🚀 大厂标准：设置结构化日志上下文
  StructuredLogger().setContext(
    extras: {
      'app_version': Config.AppConfig.appVersion,
      'platform': Platform.operatingSystem,
      'platform_version': Platform.version,
    },
  );
  Log.service.info('Observability service initialized');

  // 记录应用启动日志
  StructuredLogger().info(
    'InkRoot application starting',
    category: 'startup',
    context: {
      'version': Config.AppConfig.appVersion,
      'platform': Platform.operatingSystem,
    },
  );

  // 初始化中文日期格式支持
  await initializeDateFormatting('zh_CN');

  // 初始化timeago库，添加中文支持
  timeago.setLocaleMessages('zh', timeago.ZhCnMessages());
  timeago.setDefaultLocale('zh');

  // 初始化图片缓存管理器
  await ImageCacheManager.initialize();

  // 🚀 大厂标准：记录初始化完成
  PerformanceMonitorService().trackAppLaunch('init_completed');

  // 🔥 权限按需请求策略（模仿微信/支付宝）
  // ✅ 麦克风权限：用户点击语音识别按钮时请求
  // ✅ 通知权限：用户设置提醒时请求
  // ✅ 相机权限：用户点击拍照按钮时请求
  // ✅ 相册权限：用户选择图片时请求
  // ❌ 不在启动时请求任何权限！

  // 设置全局的页面转换配置，使所有动画更平滑
  // 🔥 提前设置状态栏样式，避免启动时闪烁
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // 默认深色图标（浅色背景）
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 创建主应用提供器
  final appProvider = AppProvider();

  // 创建路由器（需要在通知服务和 MethodChannel 回调中使用）
  final appRouter = AppRouter(appProvider);

  // 🔥 关键：设置全局Router和AppProvider供NotificationService使用
  NotificationService.setGlobalRouter(appRouter.router);
  NotificationService.setGlobalAppProvider(appProvider);

  // 🚀 完全延迟初始化通知服务（只在用户设置提醒时才初始化）
  // 微信/支付宝的做法：按需请求权限，启动时不做任何权限相关操作
  // 通知服务将在用户第一次设置提醒时自动初始化

  // 🔥 监听来自原生的通知点击和分享事件
  const platform = MethodChannel(Config.AppConfig.channelNativeAlarm);
  platform.setMethodCallHandler((call) async {
    // 🔥🔥🔥 市场主流做法：通知触发时立即保存到数据库
    if (call.method == 'saveReminderNotification') {
      try {
        final data = call.arguments as Map;
        final noteId = data['noteId'] as int;
        final title = data['title'] as String;
        final body = data['body'] as String;
        final triggerTime = data['triggerTime'] as int;

        Log.service.debug(
          'Native reminder notification callback',
          data: {
            'noteId': noteId,
            'title': title,
            'triggerTime':
                DateTime.fromMillisecondsSinceEpoch(triggerTime).toString(),
          },
        );

        // 从映射中获取真实的noteId字符串
        final noteIdString = NotificationService.noteIdMapping[noteId];
        if (noteIdString != null) {
          // 保存到数据库
          await appProvider.saveReminderNotificationToDatabase(
            noteIdString: noteIdString,
            title: title,
            body: body,
            triggerTime: DateTime.fromMillisecondsSinceEpoch(triggerTime),
          );
        }
      } on Object catch (_) {
        // Best-effort native callback handling; never break app startup.
      }
    }
    // 🔥 处理通知点击（用户查看通知）
    else if (call.method == 'openNote') {
      // 🔥 关键修复：iOS传递的是字符串payload，Android传递的是int hashCode
      final noteIdString = call.arguments is String
          ? call.arguments as String
          : (call.arguments is int
              ? NotificationService.noteIdMapping[call.arguments as int]
              : null);

      if (noteIdString == null) {
        return;
      }

      // 等待一小段时间确保应用完全启动
      await Future.delayed(const Duration(milliseconds: 500));

      // 🔥 使用GoRouter实例直接导航（不需要context）
      try {
        appRouter.router.go('/note/$noteIdString');

        // 🔥 取消该笔记的提醒（通知已查看）
        try {
          final note =
              appProvider.notes.firstWhere((n) => n.id == noteIdString);
          if (note.reminderTime != null) {
            await appProvider.cancelNoteReminder(noteIdString);
          }
        } on Object catch (_) {
          // The note may no longer exist locally; navigation already succeeded.
        }
      } on Object catch (_) {
        // Native notification routing is best-effort.
      }
    }
    // 🔥 处理分享的文本
    else if (call.method == 'onSharedText') {
      final sharedText = call.arguments as String;

      // 等待应用完全启动
      await Future.delayed(const Duration(milliseconds: 500));

      // 跳转到主页并打开笔记编辑器（内容预填充）
      appRouter.router.go('/', extra: {'sharedContent': sharedText});
    }
    // 🔥 处理分享的单张图片
    else if (call.method == 'onSharedImage') {
      final imagePath = call.arguments as String;

      await Future.delayed(const Duration(milliseconds: 500));

      // 跳转到主页并打开编辑器
      final content = '来自分享的图片:\n\n![图片](file://$imagePath)';
      appRouter.router.go('/', extra: {'sharedContent': content});
    }
    // 🔥 处理分享的多张图片
    else if (call.method == 'onSharedImages') {
      final imagePaths = (call.arguments as List).cast<String>();

      await Future.delayed(const Duration(milliseconds: 500));

      // 跳转到主页并打开编辑器
      final buffer = StringBuffer();
      buffer.writeln('来自分享的图片 (${imagePaths.length}张):\n');
      for (final path in imagePaths) {
        buffer.writeln('![图片](file://$path)\n');
      }
      appRouter.router.go('/', extra: {'sharedContent': buffer.toString()});
    }
    // 🔥 处理分享的文件
    else if (call.method == 'onSharedFile') {
      final filePath = call.arguments as String;

      await Future.delayed(const Duration(milliseconds: 500));

      // 跳转到主页并打开编辑器
      final fileName = filePath.split('/').last;
      final content = '分享的文件:\n\n📎 $fileName\n\n路径: $filePath';
      appRouter.router.go('/', extra: {'sharedContent': content});
    } else if (call.method == 'openDeepLink') {
      final rawUrl = call.arguments as String?;
      if (rawUrl == null || rawUrl.isEmpty) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 250));
      _handleInkRootDeepLink(appRouter, rawUrl);
    }
  });

  // 🔥 关键：检查应用是否从通知点击冷启动（模仿Android的getInitialNoteId）
  try {
    final initialPayload = await platform.invokeMethod('getInitialPayload');
    if (initialPayload != null && initialPayload is String) {
      // 延迟跳转，确保应用完全初始化
      Future.delayed(const Duration(seconds: 1), () {
        appRouter.router.go('/note/$initialPayload');
        appProvider.cancelNoteReminder(initialPayload).catchError((_) {});
      });
    }
  } on Object catch (_) {
    // Cold-start payload is optional and may be unavailable on some platforms.
  }

  try {
    final initialDeepLink = await platform.invokeMethod('getInitialDeepLink');
    if (initialDeepLink != null && initialDeepLink is String) {
      Future.delayed(const Duration(milliseconds: 700), () {
        _handleInkRootDeepLink(appRouter, initialDeepLink);
      });
    }
  } on Object catch (_) {
    // Cold-start deep link is optional and may be unavailable on some platforms.
  }

  // 🚀 大厂标准：记录主应用创建
  PerformanceMonitorService().trackAppLaunch('app_created');

  // 运行应用
  runApp(MyApp(appProvider: appProvider, appRouter: appRouter));

  // 🚀 大厂标准：记录应用运行
  PerformanceMonitorService().trackAppLaunch('app_running');
}

void _handleInkRootDeepLink(AppRouter appRouter, String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    return;
  }

  final action = uri.host.isNotEmpty
      ? uri.host
      : uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : '';

  switch (action) {
    case 'quick-note':
      final quickNoteTag =
          normalizeIncomingTagPath(uri.queryParameters['tag'] ?? '');
      appRouter.router.go(
        Uri(
          path: '/',
          queryParameters: <String, String>{
            'quickNote': '1',
            'quickNoteAction': DateTime.now().millisecondsSinceEpoch.toString(),
            if (quickNoteTag != null) 'tag': quickNoteTag,
          },
        ).toString(),
      );
      return;
    case 'random-review':
      appRouter.router.go('/random-review');
      return;
    case 'note':
      final noteId = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : uri.queryParameters['id'];
      if (noteId != null && noteId.trim().isNotEmpty) {
        appRouter.router.go('/note/${Uri.encodeComponent(noteId.trim())}');
      }
      return;
    case 'tag':
      final tag = uri.pathSegments.length > 1
          ? uri.pathSegments.last
          : uri.queryParameters['name'];
      final tagPath = tag == null ? null : normalizeIncomingTagPath(tag);
      if (tagPath != null) {
        appRouter.router.go(
          Uri(
            path: '/tags/detail',
            queryParameters: {'tag': tagPath},
          ).toString(),
        );
      }
      return;
  }
}

// 创建自定义页面切换动画
class FadeTransitionPageRoute<T> extends PageRouteBuilder<T> {
  FadeTransitionPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            final tween = Tween(begin: begin, end: end);
            final fadeAnimation = animation.drive(tween);

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
  final Widget page;
}

class MyApp extends StatefulWidget {
  const MyApp({required this.appProvider, required this.appRouter, super.key});
  final AppProvider appProvider;
  final AppRouter appRouter;

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 🚀 缓存主题对象，避免每次build都重新创建（大厂优化技巧）
class _ThemeCache {
  static final Map<String, ThemeData> _cache = {};

  static ThemeData getTheme(String mode, bool isDark, String fontFamily) {
    final key = '${mode}_${isDark}_$fontFamily';
    if (!_cache.containsKey(key)) {
      _cache[key] = AppTheme.getTheme(mode, isDark, fontFamily: fontFamily);
    }
    return _cache[key]!;
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 首屏渲染完成后立即移除启动页，减少用户感知启动时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      // 获取当前版本
      final currentVersion = Config.AppConfig.appVersion;

      // 获取服务器版本
      final response =
          await http.get(Uri.parse(Config.AppConfig.getCloudNoticeUrl()));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final versionInfo = data['versionInfo'] as Map<String, dynamic>;
        final serverVersion = versionInfo['versionName'] as String;

        // 比较版本号
        if (_shouldUpdate(currentVersion, serverVersion)) {
          if (mounted) {
            _showUpdateDialog(versionInfo);
          }
        }
      }
    } on Object {
      // 检查更新失败，静默处理
    }
  }

  bool _shouldUpdate(String currentVersion, String serverVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final server = serverVersion.split('.').map(int.parse).toList();

      // 确保两个列表长度相同
      while (current.length < server.length) {
        current.add(0);
      }
      while (server.length < current.length) {
        server.add(0);
      }

      // 比较每个版本号部分
      for (var i = 0; i < current.length; i++) {
        if (server[i] > current[i]) {
          return true;
        }
        if (server[i] < current[i]) {
          return false;
        }
      }

      return false;
    } on Object {
      return false;
    }
  }

  void _showUpdateDialog(Map<String, dynamic> versionInfo) {
    final forceUpdate = versionInfo['forceUpdate'] as bool? ?? false;
    final releaseNotes =
        (versionInfo['releaseNotes'] as List<dynamic>?) ?? <dynamic>[];

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (context) {
          final l10n = AppLocalizationsSimple.of(context);
          return AlertDialog(
            title: Text(l10n?.newVersionAvailable ?? 'New Version Available'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.updateAvailableMessage ??
                      'A new version is available. Update now to experience new features!',
                ),
                const SizedBox(height: 16),
                Text(l10n?.updateNotes ?? "What's New:"),
                ...releaseNotes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $note'),
                  ),
                ),
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n?.remindMeLater ?? 'Remind Me Later'),
                ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final downloadUrls =
                      versionInfo['downloadUrls'] as Map<String, dynamic>;
                  final url = downloadUrls['android'] as String;
                  try {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } on Object {
                    // 启动下载链接失败，静默处理
                  }
                },
                child: Text(l10n?.updateNow ?? 'Update Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: widget.appProvider,
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            // 获取主题选择和深色模式状态
            final isDarkMode = provider.isDarkMode;
            final themeSelection = provider.themeSelection;
            final themeMode = provider.themeMode;
            final fontScale = provider.appConfig.fontScale;
            final fontFamily = provider.appConfig.fontFamily;
            final locale = provider.locale;

            // 🚀 优化：立即设置状态栏，避免延迟导致的闪烁
            final statusBarColor =
                isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDarkMode ? Brightness.light : Brightness.dark,
                systemNavigationBarColor: statusBarColor,
                systemNavigationBarIconBrightness:
                    isDarkMode ? Brightness.light : Brightness.dark,
              ),
            );

            // 🚀 使用缓存主题，避免重复创建（大厂优化）
            final theme =
                _ThemeCache.getTheme(themeMode, false, fontFamily); // 亮色主题
            final darkTheme =
                _ThemeCache.getTheme(themeMode, true, fontFamily); // 深色主题

            // 根据主题选择设置ThemeMode
            ThemeMode appThemeMode;
            if (themeSelection == AppConfig.THEME_SYSTEM) {
              appThemeMode = ThemeMode.system;
            } else if (themeSelection == AppConfig.THEME_LIGHT) {
              appThemeMode = ThemeMode.light;
            } else if (themeSelection == AppConfig.THEME_DARK) {
              appThemeMode = ThemeMode.dark;
            } else {
              appThemeMode = ThemeMode.system;
            }

            // 解析locale字符串为Locale对象
            // 🌍 null表示跟随系统语言（大厂标准实现，支持23种语言）
            Locale? appLocale;
            if (locale == null || locale == 'system') {
              // 跟随系统：不设置locale，Flutter会自动使用系统语言
              appLocale = null;
            } else {
              // 解析语言代码 (格式: zh_CN, en_US, ja_JP等)
              final parts = locale.split('_');
              if (parts.length == 2) {
                appLocale = Locale(parts[0], parts[1]);
              } else if (parts.length == 1) {
                appLocale = Locale(parts[0]);
              } else {
                // 格式不正确，跟随系统
                appLocale = null;
              }
            }

            return MaterialApp.router(
              key: ValueKey(
                'app_${themeSelection}_$locale',
              ), // 主题和语言需要重建；字体缩放交给MediaQuery局部生效，避免路由树抖动
              title: 'InkRoot-墨鸣笔记',
              themeMode: appThemeMode,
              theme: theme,
              darkTheme: darkTheme,
              debugShowCheckedModeBanner: false,
              // 配置本地化
              localizationsDelegates: const [
                AppLocalizationsSimple.delegate, // 应用自定义本地化
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'),
                Locale('en', 'US'),
              ],
              locale: appLocale, // 使用用户选择的语言
              // 🌍 添加locale解析回调，确保正确匹配系统语言
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                // 如果用户明确设置了语言（locale不为null且不为'system'），使用用户设置
                if (locale != null && locale != 'system') {
                  // 用户明确选择了语言，返回用户选择的locale
                  return appLocale;
                }

                // 用户选择了"跟随系统"，根据设备语言匹配
                if (deviceLocale != null) {
                  // 优先完全匹配（语言+地区）
                  for (final supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode ==
                            deviceLocale.languageCode &&
                        supportedLocale.countryCode ==
                            deviceLocale.countryCode) {
                      return supportedLocale;
                    }
                  }

                  // 其次只匹配语言代码
                  for (final supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode ==
                        deviceLocale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }

                // 如果没有匹配，使用简体中文作为默认（因为app主要面向中文用户）
                return const Locale('zh', 'CN');
              },
              routerConfig: widget.appRouter.router,
              // 添加全局页面切换配置
              builder: (context, child) {
                final clampedFontScale =
                    ResponsiveUtils.clampAppTextScale(fontScale);
                final routeChild = AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: child ?? const SizedBox.shrink(),
                );

                if (_usesDesktopVisualScale) {
                  return _DesktopVisualScale(
                    scale: clampedFontScale,
                    mediaQueryData: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.noScaling,
                    ),
                    child: routeChild,
                  );
                }

                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(clampedFontScale),
                  ),
                  child: routeChild,
                );
              },
            );
          },
        ),
      );
}

bool get _usesDesktopVisualScale =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

class _DesktopVisualScale extends StatelessWidget {
  const _DesktopVisualScale({
    required this.scale,
    required this.mediaQueryData,
    required this.child,
  });

  final double scale;
  final MediaQueryData mediaQueryData;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale == 1) {
      return MediaQuery(data: mediaQueryData, child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return MediaQuery(data: mediaQueryData, child: child);
        }

        final logicalSize = Size(
          constraints.maxWidth / scale,
          constraints.maxHeight / scale,
        );
        final scaledMediaQuery = mediaQueryData.copyWith(
          size: logicalSize,
          padding: _scaleEdgeInsets(mediaQueryData.padding),
          viewPadding: _scaleEdgeInsets(mediaQueryData.viewPadding),
          viewInsets: _scaleEdgeInsets(mediaQueryData.viewInsets),
          systemGestureInsets:
              _scaleEdgeInsets(mediaQueryData.systemGestureInsets),
        );

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: logicalSize.width,
            maxWidth: logicalSize.width,
            minHeight: logicalSize.height,
            maxHeight: logicalSize.height,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: scaledMediaQuery,
                child: SizedBox(
                  width: logicalSize.width,
                  height: logicalSize.height,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _scaleEdgeInsets(EdgeInsets insets) => EdgeInsets.fromLTRB(
        insets.left / scale,
        insets.top / scale,
        insets.right / scale,
        insets.bottom / scale,
      );
}
