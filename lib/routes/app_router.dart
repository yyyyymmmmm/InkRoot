import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/about_screen.dart';
import 'package:inkroot/screens/account_deletion_screen.dart';
import 'package:inkroot/screens/account_info_screen.dart';
import 'package:inkroot/screens/ai_settings_screen.dart';
import 'package:inkroot/screens/data_cleanup_screen.dart';
import 'package:inkroot/screens/feedback_screen.dart';
import 'package:inkroot/screens/flomo_import_screen.dart';
import 'package:inkroot/screens/forgot_password_screen.dart';
import 'package:inkroot/screens/help_screen.dart';
import 'package:inkroot/screens/home_screen.dart';
import 'package:inkroot/screens/import_export_main_screen.dart';
import 'package:inkroot/screens/knowledge_graph_screen_custom.dart';
import 'package:inkroot/screens/laboratory_screen.dart';
import 'package:inkroot/screens/legal_document_screen.dart';
import 'package:inkroot/screens/local_backup_restore_screen.dart';
import 'package:inkroot/screens/login_screen.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/screens/notifications_screen.dart';
import 'package:inkroot/screens/notion_settings_screen.dart';
import 'package:inkroot/screens/onboarding_screen.dart';
import 'package:inkroot/screens/performance_dashboard_screen.dart';
import 'package:inkroot/screens/preferences_screen.dart';
import 'package:inkroot/screens/privacy_policy_screen.dart';
import 'package:inkroot/screens/random_review_screen.dart';
import 'package:inkroot/screens/register_screen.dart';
import 'package:inkroot/screens/server_info_screen.dart';
import 'package:inkroot/screens/settings_screen.dart';
import 'package:inkroot/screens/sidebar_customization_screen.dart';
import 'package:inkroot/screens/tag_notes_screen.dart';
// import 'package:inkroot/screens/splash_screen.dart'; // 🚀 大厂标准：不需要自定义启动页，只用Native Splash
import 'package:inkroot/screens/tags_screen.dart';
import 'package:inkroot/screens/user_preferences_screen.dart'; // 🧠 用户偏好可视化
import 'package:inkroot/screens/webdav_settings_screen.dart';
import 'package:inkroot/screens/weread_import_screen.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/widgets/desktop_layout.dart';

// 自定义路由，用于实现从上往下的返回动画

// 🎯 侧边栏专用页面切换动画 - 纯交叉溶解效果（大厂标准）
// 🔥 核心理念：微信/QQ的做法 - 几乎纯粹的交叉溶解，极小位移
// 关键发现：平级页面切换不应该有明显位移！主要靠透明度变化！
Page<void> buildDrawerTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  // 🔥 在iOS上使用CupertinoPage以支持侧滑返回手势（原生iOS体验）
  if (Platform.isIOS) {
    return CupertinoPage<void>(
      key: state.pageKey,
      child: child,
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 🎨 使用linear曲线（最简单最稳定）
      // 对于交叉溶解，线性变化反而最自然
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.linear, // 线性变化，稳定平滑
        reverseCurve: Curves.linear,
      );

      // 🎨 新页面线性淡入（交叉溶解的核心）
      final newPageFade = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(curve);

      // 💨 旧页面线性淡出（交叉溶解的核心）
      final oldPageFade = Tween<double>(
        begin: 1,
        end: 0,
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.linear,
        ),
      );

      return Stack(
        children: [
          // 旧页面（原地淡出）
          if (secondaryAnimation.status != AnimationStatus.dismissed)
            FadeTransition(
              opacity: oldPageFade,
              child: child,
            ),
          // 新页面（原地淡入）
          FadeTransition(
            opacity: newPageFade,
            child: child,
          ),
        ],
      );
    },
    // ⏱️ 400ms从容的动画时长
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
  );
}

// 🎯 定义统一的侧滑动画 - 大厂级丝滑体验（参考iOS/微信/支付宝标准）
// 📊 动画参数说明：
// - iOS标准：300-350ms，使用spring曲线
// - Material Design 3：300ms，使用emphasized曲线
// - 微信/支付宝/QQ：300-350ms，带视差和弹性效果
// 用途：普通页面跳转（非侧边栏触发）
Page<void> buildSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Offset? begin,
}) {
  // 🔥 在iOS上使用CupertinoPage以支持侧滑返回手势（原生iOS体验）
  if (Platform.isIOS) {
    return CupertinoPage<void>(
      key: state.pageKey,
      child: child,
    );
  }

  // 🎯 Android使用自定义丝滑动画（参考微信/QQ的实现）
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 🎨 主动画曲线：使用fastOutSlowIn（Material推荐）+ 轻微弹性效果
      final primaryCurve = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.4, 0, 0.2, 1), // Material Design 3的emphasized曲线
        reverseCurve: const Cubic(0, 0, 0.2, 1), // 返回时稍快
      );

      // 🎯 新页面滑入动画（从右向左）
      // 参数说明：0.25 = 屏幕宽度的25%，微信标准
      final newPageSlide = Tween<Offset>(
        begin: Offset(begin?.dx ?? 0.25, 0), // 大厂标准：初始偏移25%
        end: Offset.zero,
      ).animate(primaryCurve);

      // 🎨 新页面淡入效果（分阶段）
      // 前70%时间完成淡入，给用户更清晰的反馈
      final newPageFade = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.7, curve: Curves.easeOut),
        ),
      );

      // 🎯 旧页面视差效果（向左移动）
      // 参数说明：-0.12 = 屏幕宽度的12%，视差比例约50%（微信/支付宝标准）
      final oldPageSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.12, 0), // 大厂标准：旧页面移动距离是新页面的50%
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Cubic(0.4, 0, 0.6, 1), // 稍微缓和的曲线
        ),
      );

      // 🎨 旧页面淡出效果（轻微）
      // 不要太暗，保持层次感但不失去可见性
      final oldPageFade = Tween<double>(
        begin: 1,
        end: 0.88, // 大厂标准：保持88%亮度（微信风格）
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOut,
        ),
      );

      // 🌟 添加微妙的缩放效果（仅旧页面）
      // 参数说明：0.98 = 缩小到98%，几乎察觉不到但增强了纵深感
      final oldPageScale = Tween<double>(
        begin: 1,
        end: 0.98, // 微妙的缩放效果，增强纵深感（iOS风格）
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOut,
        ),
      );

      return Stack(
        children: [
          // 🎭 旧页面（带视差、淡出、缩放效果）
          if (secondaryAnimation.status != AnimationStatus.dismissed)
            SlideTransition(
              position: oldPageSlide,
              child: FadeTransition(
                opacity: oldPageFade,
                child: ScaleTransition(
                  scale: oldPageScale,
                  child: child,
                ),
              ),
            ),
          // ✨ 新页面（滑入和淡入）
          SlideTransition(
            position: newPageSlide,
            child: FadeTransition(
              opacity: newPageFade,
              child: child,
            ),
          ),
        ],
      );
    },
    // ⏱️ 大厂标准动画时长
    transitionDuration: const Duration(milliseconds: 350), // iOS/微信标准：350ms
  );
}

class AppRouter {
  AppRouter(this.appProvider);
  final AppProvider appProvider;
  final PreferencesService _preferencesService = PreferencesService();

  late final GoRouter router = GoRouter(
    initialLocation: '/', // 🚀 大厂做法：只用Native Splash，直接进入主页
    routes: [
      // 🚀 大厂标准：移除自定义启动页，只使用系统Native Splash
      // GoRoute(
      //   path: '/splash',
      //   name: 'splash',
      //   pageBuilder: (context, state) => MaterialPage<void>(
      //     key: state.pageKey,
      //     child: const SplashScreen(),
      //   ),
      // ),

      // 🔒 隐私政策页面（大厂标准：首次安装时全屏显示）
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),

      GoRoute(
        path: '/privacy-policy-detail',
        name: 'privacyPolicyDetail',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const LegalDocumentScreen(type: LegalDocumentType.privacy),
        ),
      ),

      GoRoute(
        path: '/user-agreement',
        name: 'userAgreement',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const LegalDocumentScreen(type: LegalDocumentType.agreement),
        ),
      ),

      GoRoute(
        path: '/legal-documents',
        name: 'legalDocuments',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const LegalDocumentsHubScreen(),
        ),
      ),

      GoRoute(
        path: '/account-deletion',
        name: 'accountDeletion',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const AccountDeletionScreen(),
        ),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      // 🎯 主功能页面 - 全部笔记（Tab式主页之一）
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) {
          // 🔥 接收分享的内容
          final extra = state.extra as Map<String, dynamic>?;
          final sharedContent = extra?['sharedContent'] as String?;

          // 桌面端使用NoTransitionPage，移动端使用动画
          final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

          if (isDesktop) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: DesktopLayout(
                child: HomeScreen(sharedContent: sharedContent),
              ),
            );
          }

          return buildSlideTransition(
            context: context,
            state: state,
            begin: const Offset(-0.15, 0),
            child: DesktopLayout(
              child: HomeScreen(sharedContent: sharedContent),
            ),
          );
        },
        routes: [
          // 🔥 子功能页面（需要返回的）
          GoRoute(
            path: 'account-info',
            name: 'accountInfo',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const AccountInfoScreen(),
            ),
          ),

          GoRoute(
            path: 'account-deletion',
            name: 'homeAccountDeletion',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const AccountDeletionScreen(),
            ),
          ),

          GoRoute(
            path: 'server-info',
            name: 'serverInfo',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const ServerInfoScreen(),
            ),
          ),

          GoRoute(
            path: 'data-cleanup',
            name: 'dataCleanup',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const DataCleanupScreen(),
            ),
          ),

          GoRoute(
            path: 'preferences',
            name: 'preferences',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const PreferencesScreen(),
            ),
            routes: [
              // 侧边栏自定义设置
              GoRoute(
                path: 'sidebar-customization',
                name: 'sidebarCustomization',
                pageBuilder: (context, state) => buildSlideTransition(
                  context: context,
                  state: state,
                  child: const SidebarCustomizationScreen(),
                ),
              ),
            ],
          ),

          GoRoute(
            path: 'ai-settings',
            name: 'aiSettings',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const AiSettingsScreen(),
            ),
          ),

          // 🧠 用户偏好可视化
          GoRoute(
            path: 'user-preferences',
            name: 'userPreferences',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const UserPreferencesScreen(),
            ),
          ),

          GoRoute(
            path: 'webdav-settings',
            name: 'webdavSettings',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const WebDavSettingsScreen(),
            ),
          ),

          GoRoute(
            path: 'login',
            name: 'login',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const LoginScreen(showBackButton: true),
            ),
          ),

          GoRoute(
            path: 'register',
            name: 'register',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const RegisterScreen(),
            ),
          ),

          GoRoute(
            path: 'forgot-password',
            name: 'forgotPassword',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const ForgotPasswordScreen(),
            ),
          ),

          GoRoute(
            path: 'notifications',
            name: 'notifications',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const NotificationsScreen(),
            ),
          ),

          // 笔记详情页
          GoRoute(
            path: 'note/:id',
            name: 'noteDetail',
            pageBuilder: (context, state) {
              final noteId = state.pathParameters['id']!;
              return buildSlideTransition(
                context: context,
                state: state,
                child: NoteDetailScreen(noteId: noteId),
              );
            },
            routes: [
              // 🎯 笔记编辑页（实际上就是详情页，详情页内部会处理编辑）
              GoRoute(
                path: 'edit',
                name: 'noteEdit',
                pageBuilder: (context, state) {
                  final noteId = state.pathParameters['id']!;
                  return buildSlideTransition(
                    context: context,
                    state: state,
                    child: NoteDetailScreen(noteId: noteId),
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // 🎯 主功能页面 - 随机回顾（Tab式主页之一）
      // 注意：提升为顶级路由，与home平级，使用侧边栏专用动画
      GoRoute(
        path: '/random-review',
        name: 'randomReview',
        pageBuilder: (context, state) {
          final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

          if (isDesktop) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const DesktopLayout(
                child: RandomReviewScreen(),
              ),
            );
          }

          return buildSlideTransition(
            context: context,
            state: state,
            begin: const Offset(-0.15, 0),
            child: const DesktopLayout(
              child: RandomReviewScreen(),
            ),
          );
        },
      ),

      // 🎯 主功能页面 - 全部标签（Tab式主页之一）
      // 注意：提升为顶级路由，与home平级，使用侧边栏专用动画
      GoRoute(
        path: '/tags',
        name: 'tags',
        pageBuilder: (context, state) {
          final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

          if (isDesktop) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const DesktopLayout(
                child: TagsScreen(),
              ),
            );
          }

          return buildSlideTransition(
            context: context,
            state: state,
            begin: const Offset(-0.15, 0),
            child: const DesktopLayout(
              child: TagsScreen(),
            ),
          );
        },
        routes: [
          // 标签详情页 - 显示某个标签下的所有笔记
          GoRoute(
            path: 'detail',
            name: 'tag-notes',
            pageBuilder: (context, state) {
              try {
                // GoRouter 的 queryParameters 已经是解码后的值。
                final tagName = state.uri.queryParameters['tag']?.trim() ?? '';

                // 🛡️ 防御性检查
                if (tagName.isEmpty || tagName.trim().isEmpty) {
                  return MaterialPage(
                    key: state.pageKey,
                    child: Scaffold(
                      appBar: AppBar(
                        title: Text(
                          AppLocalizationsSimple.of(context)?.routeErrorTitle ??
                              '错误',
                        ),
                      ),
                      body: Center(
                        child: Text(
                          AppLocalizationsSimple.of(context)?.invalidTagName ??
                              '标签名称无效',
                        ),
                      ),
                    ),
                  );
                }

                // 🔥 在iOS上使用CupertinoPage以支持侧滑返回手势
                if (!kIsWeb && Platform.isIOS) {
                  return CupertinoPage<void>(
                    key: state.pageKey,
                    child: TagNotesScreen(tagName: tagName),
                  );
                }

                if (!kIsWeb && (Platform.isMacOS || Platform.isWindows)) {
                  return NoTransitionPage<void>(
                    key: state.pageKey,
                    child: DesktopLayout(
                      child: TagNotesScreen(tagName: tagName),
                    ),
                  );
                }

                // 🎯 Android使用自定义滑动动画
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: TagNotesScreen(tagName: tagName),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              } on Object catch (e) {
                return MaterialPage(
                  key: state.pageKey,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                        AppLocalizationsSimple.of(context)?.routeErrorTitle ??
                            '错误',
                      ),
                    ),
                    body: Center(
                      child: Text(
                        '${AppLocalizationsSimple.of(context)?.pageLoadFailed ?? '页面加载失败'}: $e',
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),

      // 🎯 主功能页面 - 知识图谱（Tab式主页之一）
      // 注意：顶级路由，与home平级，使用侧边栏专用动画
      GoRoute(
        path: '/knowledge-graph',
        name: 'knowledgeGraph',
        pageBuilder: (context, state) {
          final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

          if (isDesktop) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const DesktopLayout(
                child: KnowledgeGraphScreenCustom(),
              ),
            );
          }

          return buildSlideTransition(
            context: context,
            state: state,
            begin: const Offset(-0.15, 0),
            child: const DesktopLayout(
              child: KnowledgeGraphScreenCustom(),
            ),
          );
        },
      ),

      // 🔥 辅助功能页面 - 帮助中心（可返回）
      GoRoute(
        path: '/help',
        name: 'help',
        pageBuilder: (context, state) {
          final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

          if (isDesktop) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const DesktopLayout(
                child: HelpScreen(),
              ),
            );
          }

          return buildSlideTransition(
            context: context,
            state: state,
            child: const DesktopLayout(
              child: HelpScreen(),
            ),
          );
        },
      ),

      // 添加设置路由
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          begin: const Offset(1, 0),
          child: const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'help',
            name: 'settingsHelp',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              begin: const Offset(0.8, 0),
              child: const HelpScreen(showBackButton: true),
            ),
          ),
          GoRoute(
            path: 'about',
            name: 'settingsAbout',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              begin: const Offset(1, 0),
              child: const AboutScreen(),
            ),
          ),

          // 导入导出主页面
          GoRoute(
            path: 'import-export',
            name: 'importExport',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const ImportExportMainScreen(),
            ),
          ),

          // 本地备份/恢复页面
          GoRoute(
            path: 'local-backup-restore',
            name: 'localBackupRestore',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const LocalBackupRestoreScreen(),
            ),
          ),

          // Flomo 导入页面
          GoRoute(
            path: 'flomo-import',
            name: 'flomoImport',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const FlomoImportScreen(),
            ),
          ),

          // 微信读书笔记导入页面
          GoRoute(
            path: 'weread-import',
            name: 'wereadImport',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const WeReadImportScreen(),
            ),
          ),

          // Notion 同步设置页面
          GoRoute(
            path: 'notion-settings',
            name: 'notionSettings',
            pageBuilder: (context, state) => buildSlideTransition(
              context: context,
              state: state,
              child: const NotionSettingsScreen(),
            ),
          ),
        ],
      ),

      // 添加反馈路由
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          begin: const Offset(1, 0),
          child: const FeedbackScreen(),
        ),
      ),

      // 添加实验室路由
      GoRoute(
        path: '/laboratory',
        name: 'laboratory',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          begin: const Offset(1, 0),
          child: const LaboratoryScreen(),
        ),
      ),

      // 🚀 大厂标准：性能监控看板路由
      GoRoute(
        path: '/performance-dashboard',
        name: 'performanceDashboard',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          begin: const Offset(1, 0),
          child: const PerformanceDashboardScreen(),
        ),
      ),

      // 添加通知路由为顶级路由
      GoRoute(
        path: '/notifications',
        name: 'notificationsPage',
        pageBuilder: (context, state) => buildSlideTransition(
          context: context,
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
    ],
    redirect: (context, state) async {
      // 🔒 大厂标准：隐私政策优先级最高（第一次安装时必须先同意）
      final hasAgreedToPrivacy =
          await _preferencesService.hasAgreedToPrivacyPolicy();

      // 如果未同意隐私政策，强制跳转到隐私政策页面
      if (!hasAgreedToPrivacy) {
        const allowedLegalPaths = {
          '/privacy-policy',
          '/privacy-policy-detail',
          '/user-agreement',
          '/legal-documents',
          '/account-deletion',
        };
        if (!allowedLegalPaths.contains(state.matchedLocation)) {
          return '/privacy-policy';
        }
        return null; // 已在隐私政策页面，停止重定向
      }

      // 🚀 大厂做法：隐私政策同意后直接进入主页，不显示引导页
      // 如果已同意隐私政策，但还在隐私政策页面，直接跳转到主页
      if (hasAgreedToPrivacy && state.matchedLocation == '/privacy-policy') {
        return '/';
      }

      // 🚀 移除引导页逻辑，模仿微信/支付宝的简洁启动流程
      // 用户可以在设置中查看帮助和教程
      // if (hasAgreedToPrivacy) {
      //   final isFirstLaunch = await _preferencesService.isFirstLaunch();
      //
      //   if (isFirstLaunch &&
      //       state.matchedLocation != '/onboarding' &&
      //       state.matchedLocation != '/welcome') {
      //     return '/onboarding';
      //   }
      // }

      // 兼容旧路由
      if (state.matchedLocation == '/daily-review') {
        return '/random-review';
      }

      return null;
    },
    errorBuilder: (context, state) {
      if (kDebugMode) {
        debugPrint('GoRouter 404: uri=${state.uri}, error=${state.error}');
      }
      final l10n = AppLocalizationsSimple.of(context);

      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text(l10n?.pageNotFound ?? '页面未找到'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n?.pageLost ?? '哎呀，页面走丢了!'),
                const SizedBox(height: 16),
                Text(
                  l10n?.requestPath(state.uri.toString()) ??
                      '请求路径: ${state.uri}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
