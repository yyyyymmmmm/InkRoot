import 'package:flutter/material.dart';
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
              ? '${AppConfig.appName} 默认以本地优先方式运行。笔记内容、图片、标签和配置主要保存在你的设备或你自行配置的 Memos/WebDAV/AI 服务中。\n\n我们不会运营集中式笔记服务器，也不会主动收集、读取、出售或分析你的个人笔记内容。'
              : '${AppConfig.appName} is local-first by default. Notes, images, tags, and settings are primarily stored on your device or in the Memos, WebDAV, or AI services you configure.\n\nWe do not operate a centralized note server and do not proactively collect, read, sell, or analyze your personal note content.',
          highlight: true,
        ),
        _LegalSection(
          title: isZh ? '可能使用的信息' : 'Information That May Be Used',
          content: isZh
              ? '• 服务器地址、用户名、访问令牌：用于连接你选择的 Memos 服务\n• WebDAV 地址、用户名、密码：用于备份和恢复数据\n• AI API 地址、模型名、API Key：用于你主动触发的 AI 功能\n• 图片和文件访问权限：用于选择、保存、上传或备份图片\n• 通知权限：用于本地提醒\n• 反馈内容：仅在你主动提交反馈时发送'
              : '• Server address, username, and access token: used to connect to the Memos service you choose\n• WebDAV address, username, and password: used for backup and restore\n• AI API URL, model name, and API key: used only for AI features you trigger\n• Image and file permissions: used to select, save, upload, or back up images\n• Notification permission: used for local reminders\n• Feedback content: sent only when you submit feedback',
        ),
        _LegalSection(
          title: isZh ? '第三方服务' : 'Third-Party Services',
          content: isZh
              ? '当你配置 Memos、WebDAV、AI 服务、系统分享或图片保存能力时，相关数据会发送到你选择的第三方或自建服务。请自行确认这些服务的隐私政策、安全性和可用性。'
              : 'When you configure Memos, WebDAV, AI services, system sharing, or image saving, relevant data may be sent to the third-party or self-hosted services you choose. Please review their privacy policies, security, and availability.',
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
              ? '你可以在应用中导出、删除和迁移笔记，也可以随时关闭同步、AI、通知等功能。卸载应用可能会删除本地数据，请先自行备份重要内容。'
              : 'You can export, delete, and migrate notes in the app, and you may disable sync, AI, notifications, and related features at any time. Uninstalling the app may remove local data, so back up important content first.',
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
              ? '${AppConfig.appName} 是面向 Memos 用户的跨平台客户端，提供笔记创建、编辑、标签、图片、离线记录、同步、备份、导入导出和可选 AI 辅助功能。'
              : '${AppConfig.appName} is a cross-platform client for Memos users, providing note creation, editing, tags, images, offline capture, sync, backup, import/export, and optional AI assistance.',
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
              ? '你的笔记和附件归你所有。应用不会声明对你的内容拥有权利。你应自行备份重要数据，第三方或自建服务中的数据安全由相应服务提供方或你本人负责。'
              : 'Your notes and attachments belong to you. The app does not claim ownership of your content. You should back up important data, and data security in third-party or self-hosted services is the responsibility of that provider or yourself.',
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
