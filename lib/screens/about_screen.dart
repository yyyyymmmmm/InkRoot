import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/screens/feedback_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Text(
          AppLocalizationsSimple.of(context)?.aboutUs ?? '关于 InkRoot',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 应用信息
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C9678), Color(0xFF46B696)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C9678).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 背景装饰
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // 内容
                  Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        AppConfig.appName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizationsSimple.of(context)?.version ?? '版本'} ${AppConfig.appVersion}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizationsSimple.of(context)?.appTagline ??
                            '静待沉淀，蓄势而鸣。\n你的每一次落笔，都是未来生长的根源。',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 应用介绍
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizationsSimple.of(context)?.aboutInkRoot ??
                            '关于InkRoot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.appIntroduction ??
                        'InkRoot-墨鸣笔记是一款面向个人记录与知识沉淀的跨平台笔记应用。它保留轻量记录的速度，也提供标签、搜索、回顾、备份和同步能力，让零散内容逐步沉淀成可回看的资料库。',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.technicalDetails ??
                        '当前支持 Android、iOS、macOS、Windows 和 Linux。应用提供富文本式编辑、Markdown 渲染、图片、标签、搜索、提醒、随机回顾、WebDAV 备份、导入导出和可选 AI 功能。',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.securityCommitment ??
                        '笔记优先保存在本机。登录、同步、WebDAV 和 AI 相关配置由你主动设置；自部署服务中的数据由对应服务器保存和管理。',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),

            // 核心功能
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_outline,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizationsSimple.of(context)?.coreFeaturesTitle ??
                            '核心功能',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.appTechDescription ??
                        '这些是当前版本已经开放的主要能力。不同 Memos 服务器版本的接口能力不同，应用会按服务器版本自动适配并尽量降级处理。',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)
                                ?.memosExclusiveVersion ??
                            'Memos 多版本适配',
                        Icons.verified_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        '官方/自部署服务',
                        Icons.cloud_queue_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.markdownSupport ??
                            'Markdown支持',
                        Icons.code,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)
                                ?.intelligentTagSystem ??
                            '层级标签',
                        Icons.local_offer_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.fullTextSearch ??
                            '全文搜索',
                        Icons.search_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)
                                ?.randomReviewFeature ??
                            '随机回顾',
                        Icons.shuffle_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.dataStatistics ??
                            '数据统计',
                        Icons.analytics_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.realtimeSync ??
                            '实时同步',
                        Icons.sync_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.localEncryption ??
                            '本地加密',
                        Icons.security_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.multiTheme ??
                            '多主题切换',
                        Icons.palette_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        '移动端和桌面端',
                        Icons.devices_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.offlineUse ??
                            '离线使用',
                        Icons.offline_bolt_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.dataExport ??
                            '数据导出',
                        Icons.download_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.imageManagement ??
                            '图片管理',
                        Icons.image_outlined,
                      ),
                      _buildFeatureTag(
                        context,
                        AppLocalizationsSimple.of(context)?.privateDeployment ??
                            '私有化部署',
                        Icons.cloud_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 联系方式
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizationsSimple.of(context)?.contactUs ?? '联系我们',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.contactMessage ??
                        '我们非常重视用户的反馈和建议。如果您有任何问题、意见或合作意向，请随时与我们联系。',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    context,
                    icon: Icons.feedback_outlined,
                    label: AppLocalizationsSimple.of(context)
                            ?.feedbackSuggestions ??
                        '反馈建议',
                    value: AppLocalizationsSimple.of(context)
                            ?.clickToSubmitFeedback ??
                        '点击提交反馈建议',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.email_outlined,
                    label: AppLocalizationsSimple.of(context)?.emailAddress ??
                        '电子邮件',
                    value: AppConfig.supportEmail,
                    onTap: () => _launchURL('mailto:${AppConfig.supportEmail}'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.language_outlined,
                    label:
                        AppLocalizationsSimple.of(context)?.officialWebsite ??
                            '官方网站',
                    value: AppConfig.officialWebsite,
                    onTap: () => _launchURL(AppConfig.officialWebsite),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    label: AppLocalizationsSimple.of(context)?.privacyPolicy ??
                        '隐私政策',
                    value: AppConfig.privacyPolicyUrl,
                    onTap: () => _launchURL(AppConfig.privacyPolicyUrl),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.description_outlined,
                    label: AppLocalizationsSimple.of(context)?.userAgreement ??
                        '用户协议',
                    value: AppConfig.userAgreementUrl,
                    onTap: () => _launchURL(AppConfig.userAgreementUrl),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.delete_outline,
                    label: '账号与数据删除',
                    value: AppConfig.accountDeletionUrl,
                    onTap: () => _launchURL(AppConfig.accountDeletionUrl),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.code_outlined,
                    label: '开源仓库',
                    value: AppConfig.githubRepo,
                    onTap: () => _launchURL(AppConfig.githubRepo),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.location_on_outlined,
                    label: AppLocalizationsSimple.of(context)
                            ?.communicationAddress ??
                        '联系地址',
                    value: AppConfig.companyAddress,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // 版权信息
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  const Text(
                    AppConfig.copyrightText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppConfig.companyFullName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  if (AppConfig.icpLicense.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      AppConfig.icpLicense,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '版本 ${AppConfig.getFullVersionInfo()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(BuildContext context, String label, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
