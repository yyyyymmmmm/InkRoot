import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/services/umeng_analytics_service.dart';
import 'package:inkroot/themes/app_theme.dart';

/// 首次启动服务与隐私确认页。
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textPrimary =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final textSecondary = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    final accentColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final l10n = AppLocalizationsSimple.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    String text(String zh, String en) => isZh ? zh : en;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    text('服务与隐私提示', 'Service and Privacy'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text(
                      '欢迎使用 ${AppConfig.appName}。开始前，请确认以下必要说明。',
                      'Welcome to ${AppConfig.appName}. Before continuing, please review these essentials.',
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSummaryItem(
                    icon: Icons.edit_note_rounded,
                    title: text('本地优先', 'Local First'),
                    description: text(
                      '笔记默认保存在本机；只有你主动配置同步时，才会发送到你选择的服务。',
                      'Notes are stored on this device by default. Data is sent only when you configure a sync service.',
                    ),
                    color: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 18),
                  _buildSummaryItem(
                    icon: Icons.lock_outline_rounded,
                    title: text('最小必要', 'Minimum Required'),
                    description: text(
                      '服务器地址、登录凭证和权限仅用于连接账号、保存图片、提醒等你主动使用的功能。',
                      'Server details, credentials, and permissions are used only for features you actively enable.',
                    ),
                    color: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 18),
                  _buildSummaryItem(
                    icon: Icons.tune_rounded,
                    title: text('你可控制', 'You Stay in Control'),
                    description: text(
                      '你可以随时导出、删除数据，也可以在设置中调整同步、通知和统计相关选项。',
                      'You can export or delete data at any time, and adjust sync, notifications, and analytics in settings.',
                    ),
                    color: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        text('完整条款请查看', 'Read the full'),
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      _buildInlineLink(
                        context,
                        label: l10n?.userAgreement ??
                            text('用户协议', 'User Agreement'),
                        route: '/user-agreement',
                      ),
                      Text(
                        text('和', 'and'),
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      _buildInlineLink(
                        context,
                        label: l10n?.privacyPolicy ??
                            text('隐私政策', 'Privacy Policy'),
                        route: '/privacy-policy-detail',
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _handleAgree(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        text('同意并继续', 'Agree and Continue'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: SystemNavigator.pop,
                      child: Text(
                        text('不同意并退出', 'Disagree and Exit'),
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildInlineLink(
    BuildContext context, {
    required String label,
    required String route,
  }) =>
      TextButton(
        onPressed: () => context.push(route),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          '《$label》',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      );

  Future<void> _handleAgree(BuildContext context) async {
    final preferencesService = PreferencesService();

    // 保存同意状态
    await preferencesService.setPrivacyPolicyAgreed(true);

    // 初始化友盟统计（仅在同意后初始化）
    await UmengAnalyticsService.init();
    await UmengAnalyticsService.onAppStart();

    debugPrint('✅ 用户已同意隐私政策');

    // 检查是否首次启动
    final isFirstLaunch = await preferencesService.isFirstLaunch();

    if (context.mounted) {
      if (isFirstLaunch) {
        // 首次启动 → 引导页
        context.go('/onboarding');
      } else {
        // 后续启动 → 主界面
        context.go('/');
      }
    }
  }
}
