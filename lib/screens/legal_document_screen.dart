import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';

enum LegalDocumentType {
  privacy,
  agreement,
}

class LegalDocumentsHubScreen extends StatelessWidget {
  const LegalDocumentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final l10n = AppLocalizationsSimple.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.userAgreementAndPrivacy ?? '用户协议与隐私政策',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildEntry(
              context,
              icon: Icons.article_outlined,
              title: l10n?.userAgreement ?? '用户协议',
              subtitle: isZh
                  ? '查看服务说明、用户责任和免责声明'
                  : 'Service terms, user responsibilities, and disclaimers',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LegalDocumentScreen(
                    type: LegalDocumentType.agreement,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildEntry(
              context,
              icon: Icons.privacy_tip_outlined,
              title: l10n?.privacyPolicy ?? '隐私政策',
              subtitle: isZh
                  ? '查看数据处理、第三方服务和你的控制权'
                  : 'Data handling, third-party services, and your controls',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LegalDocumentScreen(
                    type: LegalDocumentType.privacy,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildEntry(
              context,
              icon: Icons.delete_forever_outlined,
              title: isZh ? '账号与数据删除' : 'Account and Data Deletion',
              subtitle: isZh
                  ? '删除本机数据或发起官方服务器账号删除'
                  : 'Delete local data or request official account deletion',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              onTap: () => context.push('/account-deletion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Material(
      color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.type,
    super.key,
  });

  final LegalDocumentType type;

  bool get _isPrivacy => type == LegalDocumentType.privacy;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey.shade50;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final accentColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final title = _isPrivacy
        ? (AppLocalizationsSimple.of(context)?.privacyPolicy ?? '隐私政策')
        : (AppLocalizationsSimple.of(context)?.userAgreement ?? '用户协议');

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.lastUpdated(
                          AppConfig.legalUpdatedYear,
                          AppConfig.legalUpdatedMonth,
                          AppConfig.legalUpdatedDay,
                        ) ??
                        '最后更新日期：${AppConfig.legalUpdatedYear}年${AppConfig.legalUpdatedMonth}月${AppConfig.legalUpdatedDay}日',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                for (final section in _sections(context))
                  _buildSection(
                    section.title,
                    section.content,
                    textColor,
                    accentColor,
                    isHighlight: section.highlight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_LegalSection> _sections(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return _isPrivacy ? _privacySections(isZh) : _agreementSections(isZh);
  }

  List<_LegalSection> _privacySections(bool isZh) => [
        _LegalSection(
          title: isZh ? '我们如何处理数据' : 'How We Handle Data',
          content: isZh
              ? '${AppConfig.appName} 默认以本地优先方式运行。笔记、图片、标签和配置优先保存在你的设备上；当你登录官方服务器、连接自部署 Memos、配置 WebDAV、启用 AI 或提交反馈时，相关数据会按你的操作发送到对应服务。\n\n我们不会出售个人信息，也不会为了广告画像读取或分析你的私人笔记内容。'
              : '${AppConfig.appName} is local-first by default. Notes, images, tags, and settings are stored on your device first. When you sign in to the official server, connect a self-hosted Memos server, configure WebDAV, enable AI, or submit feedback, relevant data is sent to the corresponding service based on your action.\n\nWe do not sell personal information or read/analyze your private notes for advertising profiles.',
          highlight: true,
        ),
        _LegalSection(
          title: isZh ? '可能使用的信息' : 'Information That May Be Used',
          content: isZh
              ? '• 账号资料、邮箱、服务器地址、访问令牌：用于登录和同步你选择的 Memos 服务\n• 笔记、图片、标签、提醒和附件：用于本地记录、同步、备份、导入导出和图片预览\n• WebDAV 地址、用户名、密码：用于你主动配置的备份和恢复\n• AI API 地址、模型名、API Key、待处理文本：用于你主动触发的 AI 功能\n• 相机、相册、麦克风、语音识别、通知权限：用于拍照、选择/保存图片、语音输入和本地提醒\n• 设备、应用版本、错误或反馈内容：仅在你主动反馈或启用相应服务时用于排查问题'
              : '• Account profile, email, server address, and access token: used for sign-in and sync with the Memos service you choose\n• Notes, images, tags, reminders, and attachments: used for local capture, sync, backup, import/export, and image preview\n• WebDAV address, username, and password: used for backup and restore you configure\n• AI API URL, model name, API key, and selected text: used only for AI features you trigger\n• Camera, photo library, microphone, speech recognition, and notification permissions: used for photos, image selection/saving, voice input, and local reminders\n• Device, app version, error, or feedback content: used only when you submit feedback or enable the related service',
        ),
        _LegalSection(
          title: isZh ? '官方服务器与自部署服务' : 'Official and Self-Hosted Services',
          content: isZh
              ? '使用官方服务器时，账号资料、笔记、附件和同步记录会保存在官方服务器上，用于提供登录、同步、公告和必要的服务维护。使用自部署 Memos、WebDAV 或第三方 AI 服务时，相关数据由你选择的服务处理，InkRoot 无法直接管理这些服务中的账号和数据。'
              : 'When you use the official server, account profile, notes, attachments, and sync records are stored on the official server to provide sign-in, sync, notices, and necessary service maintenance. When you use self-hosted Memos, WebDAV, or third-party AI services, the selected service processes the related data, and InkRoot cannot directly manage accounts or data in those services.',
        ),
        _LegalSection(
          title: isZh ? '第三方服务' : 'Third-Party Services',
          content: isZh
              ? 'Android 版本可能接入崩溃诊断或统计 SDK，具体以应用设置和构建配置为准。iOS 版本不启用友盟统计；如构建时配置 Sentry 或其他错误上报服务，将仅用于诊断崩溃和稳定性问题。你配置的 Memos、WebDAV、AI 服务、系统分享或图片保存能力，也可能由相应平台或服务处理数据。'
              : 'The Android version may integrate crash diagnostics or analytics SDKs depending on app settings and build configuration. The iOS version does not enable Umeng analytics. If Sentry or another error reporting service is configured at build time, it is used only for crash and stability diagnostics. Memos, WebDAV, AI services, system sharing, or image saving features you configure may also process data through the corresponding platform or service.',
        ),
        _LegalSection(
          title: isZh ? '本地安全' : 'Local Security',
          content: isZh
              ? '访问令牌、AI API Key 和 WebDAV 密码会尽量使用系统安全存储保存。普通偏好设置不会保存这些敏感字段。重要笔记建议定期导出或使用 WebDAV 备份。'
              : 'Access tokens, AI API keys, and WebDAV passwords are stored with platform secure storage when possible. Normal preferences do not store these sensitive fields. Export or back up important notes regularly.',
        ),
        _LegalSection(
          title: isZh ? '你的控制权' : 'Your Control',
          content: isZh
              ? '你可以在应用中导出、删除和迁移笔记，也可以随时关闭同步、AI、通知等功能。你可以在“设置 - 账号与数据删除”中删除本机数据，或通过 ${AppConfig.accountDeletionUrl} 发起官方服务器账号删除。自部署或第三方服务中的数据，需要到对应服务中删除。卸载应用可能会删除本地数据，请先自行备份重要内容。'
              : 'You can export, delete, and migrate notes in the app, and may disable sync, AI, notifications, and related features at any time. You can delete local data in Settings > Account and Data Deletion, or request official server account deletion at ${AppConfig.accountDeletionUrl}. Data in self-hosted or third-party services must be deleted in those services. Uninstalling the app may remove local data, so back up important content first.',
        ),
        _LegalSection(
          title: isZh ? '联系我们' : 'Contact',
          content: isZh
              ? '如对隐私政策有疑问，请通过应用内反馈或邮箱联系：${AppConfig.supportEmail}'
              : 'For privacy questions, contact us through in-app feedback or email: ${AppConfig.supportEmail}',
        ),
      ];

  List<_LegalSection> _agreementSections(bool isZh) => [
        _LegalSection(
          title: isZh ? '协议接受' : 'Agreement Acceptance',
          content: isZh
              ? '使用 ${AppConfig.appName} 即表示你已阅读并同意本用户协议和隐私政策。如果你不同意，请停止使用并卸载应用。'
              : 'By using ${AppConfig.appName}, you confirm that you have read and agreed to this User Agreement and the Privacy Policy. If you do not agree, stop using and uninstall the app.',
          highlight: true,
        ),
        _LegalSection(
          title: isZh ? '服务说明' : 'Service Description',
          content: isZh
              ? '${AppConfig.appName} 是面向个人记录和 Memos 用户的跨平台客户端，提供笔记创建、编辑、标签、图片、离线记录、同步、备份、导入导出、提醒和可选 AI 辅助功能。你可以使用本地模式、官方服务器或自部署服务。'
              : '${AppConfig.appName} is a cross-platform client for personal capture and Memos users, providing note creation, editing, tags, images, offline capture, sync, backup, import/export, reminders, and optional AI assistance. You can use local mode, the official server, or self-hosted services.',
        ),
        _LegalSection(
          title: isZh ? '用户责任' : 'User Responsibilities',
          content: isZh
              ? '你应确保服务器、账号、Token、API Key 和备份密码安全；对通过应用创建、同步、发布和备份的内容负责；不得使用本应用从事违法、有害或侵犯他人权益的活动。'
              : 'You are responsible for securing servers, accounts, tokens, API keys, and backup passwords; for content created, synced, published, and backed up through the app; and for not using the app for illegal, harmful, or rights-infringing activities.',
        ),
        _LegalSection(
          title: isZh ? '数据所有权' : 'Data Ownership',
          content: isZh
              ? '你的笔记和附件归你所有。应用不会声明对你的内容拥有权利。你应自行备份重要数据；官方服务器、自部署服务、WebDAV、AI 或其他第三方服务中的数据安全和可用性，分别由对应服务规则、服务提供方或你本人负责。'
              : 'Your notes and attachments belong to you. The app does not claim ownership of your content. You should back up important data. Data security and availability in the official server, self-hosted services, WebDAV, AI, or other third-party services are governed by the corresponding service rules, provider, or yourself.',
        ),
        _LegalSection(
          title: isZh ? '账号与数据删除' : 'Account and Data Deletion',
          content: isZh
              ? '你可以在“设置 - 账号与数据删除”中删除本机数据。官方服务器账号删除需通过 ${AppConfig.accountDeletionUrl} 发起申请并完成身份确认。自部署 Memos、WebDAV、AI 或其他第三方服务中的账号和数据，应在对应服务中处理。'
              : 'You can delete local data in Settings > Account and Data Deletion. Official server account deletion must be requested at ${AppConfig.accountDeletionUrl} with identity confirmation. Accounts and data in self-hosted Memos, WebDAV, AI, or other third-party services must be handled in those services.',
        ),
        _LegalSection(
          title: isZh ? '免责声明' : 'Disclaimer',
          content: isZh
              ? '本应用按现状提供。我们会尽力提升稳定性，但不保证服务不中断、无错误或完全满足你的特定需求。因网络、服务器、第三方服务、误操作或未备份造成的数据损失，由用户自行承担。'
              : 'The app is provided as is. We work to improve stability, but do not guarantee uninterrupted, error-free service or suitability for every specific need. Data loss caused by network issues, servers, third-party services, user actions, or lack of backup is your responsibility.',
        ),
        _LegalSection(
          title: isZh ? '协议更新' : 'Agreement Updates',
          content: isZh
              ? '我们可能更新本协议或隐私政策。重大变更会在应用内提示，并可能要求你重新同意后继续使用。当前法律文档版本：${AppConfig.legalDocumentVersion}。'
              : 'We may update this Agreement or Privacy Policy. Major changes will be shown in the app and may require your renewed consent before continued use. Current legal document version: ${AppConfig.legalDocumentVersion}.',
        ),
        _LegalSection(
          title: isZh ? '联系我们' : 'Contact',
          content: isZh
              ? '如对本协议有疑问，请通过应用内反馈或邮箱联系：${AppConfig.supportEmail}'
              : 'For questions about this Agreement, contact us through in-app feedback or email: ${AppConfig.supportEmail}',
        ),
      ];

  Widget _buildSection(
    String title,
    String content,
    Color textColor,
    Color accentColor, {
    bool isHighlight = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: isHighlight ? const EdgeInsets.all(12) : EdgeInsets.zero,
            decoration: isHighlight
                ? BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.3)),
                  )
                : null,
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.content,
    this.highlight = false,
  });

  final String title;
  final String content;
  final bool highlight;
}
