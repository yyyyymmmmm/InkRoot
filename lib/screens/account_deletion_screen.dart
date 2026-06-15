import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool _isClearingLocalData = false;
  bool _isOpeningRequest = false;

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  String get _title => _isZh ? '账号与数据删除' : 'Account and Data Deletion';

  String get _localClearTitle =>
      _isZh ? '删除本机数据' : 'Delete data on this device';

  String get _officialDeletionTitle =>
      _isZh ? '删除官方服务器账号' : 'Delete official server account';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.user;
    final serverUrl =
        user?.serverUrl ?? appProvider.appConfig.memosApiUrl ?? '';
    final isOfficialServer = _isOfficialServer(serverUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _InfoPanel(
            icon: Icons.verified_user_outlined,
            title: _isZh ? '删除范围说明' : 'Deletion scope',
            body: _isZh
                ? '你可以在这里删除本机笔记、图片缓存、登录凭证和应用设置；如果你使用官方服务器账号，也可以发起账号及关联服务器数据删除申请。自部署 Memos、WebDAV、AI 服务中的数据由对应服务保存，需要在相应服务中删除。'
                : 'You can delete local notes, image cache, login credentials, and app settings here. If you use the official server account, you can also initiate deletion of the account and associated server-side data. Data stored in self-hosted Memos, WebDAV, or AI services must be deleted in those services.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: _isZh ? '当前状态' : 'Current status',
            children: [
              _StatusRow(
                label: _isZh ? '登录账号' : 'Account',
                value: user == null
                    ? (_isZh ? '未登录 / 本地模式' : 'Not signed in / local mode')
                    : user.username,
              ),
              _StatusRow(
                label: _isZh ? '服务器' : 'Server',
                value: serverUrl.isEmpty
                    ? (_isZh ? '未连接' : 'Not connected')
                    : serverUrl,
              ),
              _StatusRow(
                label: _isZh ? '服务器类型' : 'Server type',
                value: isOfficialServer
                    ? (_isZh ? '官方服务器' : 'Official server')
                    : (_isZh ? '本地或自部署服务' : 'Local or self-hosted'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: _localClearTitle,
            children: [
              Text(
                _isZh
                    ? '删除本机数据会清空设备上的笔记数据库、提醒记录、账号信息和安全凭证。此操作不会删除 Memos、WebDAV、AI 或其他第三方服务中的远端数据。'
                    : 'Deleting local data clears notes, reminder records, account information, and secure credentials on this device. This does not delete remote data stored in Memos, WebDAV, AI, or other third-party services.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                    _isClearingLocalData ? null : _confirmAndClearLocalData,
                icon: _isClearingLocalData
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                label: Text(
                  _isClearingLocalData
                      ? (_isZh ? '正在删除...' : 'Deleting...')
                      : _localClearTitle,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: _officialDeletionTitle,
            children: [
              Text(
                isOfficialServer
                    ? (_isZh
                        ? '官方服务器账号删除会进入网页表单完成身份确认和删除申请。申请提交后，我们会按隐私政策处理账号资料、服务端笔记、附件和相关日志。'
                        : 'Official server account deletion opens a web form for identity confirmation and deletion request submission. After submission, account profile, server-side notes, attachments, and related logs will be processed according to the privacy policy.')
                    : (_isZh
                        ? '当前不是官方服务器。InkRoot 无法直接删除你自部署服务中的账号或数据，请在你的 Memos、WebDAV 或其他服务管理后台处理。你仍可打开说明页查看官方服务器删除流程。'
                        : 'The current server is not the official server. InkRoot cannot directly delete accounts or data in your self-hosted services. Please manage deletion in your Memos, WebDAV, or other service admin panels. You can still open the information page for the official deletion process.'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isOpeningRequest ? null : _openDeletionRequest,
                icon: _isOpeningRequest
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new_rounded),
                label: Text(
                  _isZh ? '打开删除申请页面' : 'Open deletion request page',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _copyDeletionRequestTemplate,
                icon: const Icon(Icons.copy_rounded),
                label: Text(
                  _isZh ? '复制删除申请信息' : 'Copy deletion request details',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoPanel(
            icon: Icons.info_outline_rounded,
            title: _isZh ? '删除前建议' : 'Before deleting',
            body: _isZh
                ? '如需保留资料，请先在导入导出或 WebDAV 备份中完成备份。删除账号或本机数据后，部分内容可能无法恢复。'
                : 'Export or back up important data before deleting. Some content may not be recoverable after account or local data deletion.',
          ),
        ],
      ),
    );
  }

  bool _isOfficialServer(String serverUrl) {
    if (serverUrl.trim().isEmpty) {
      return false;
    }
    try {
      final configured = Uri.parse(serverUrl);
      final official = Uri.parse(AppConfig.officialMemosServer);
      return configured.host.toLowerCase() == official.host.toLowerCase();
    } on Object {
      return false;
    }
  }

  Future<void> _confirmAndClearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_localClearTitle),
        content: Text(
          _isZh
              ? '此操作会删除本机保存的笔记、提醒、登录凭证和应用数据。远端服务器数据不会被删除。确定继续吗？'
              : 'This will delete notes, reminders, login credentials, and app data stored on this device. Remote server data will not be deleted. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(_isZh ? '删除本机数据' : 'Delete local data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isClearingLocalData = true);
    try {
      final appProvider = context.read<AppProvider>();
      final (success, message) = await appProvider.logout(
        force: true,
        keepLocalData: false,
      );
      if (!mounted) {
        return;
      }
      if (success) {
        SnackBarUtils.showSuccess(
          context,
          _isZh ? '本机数据已删除' : 'Local data deleted',
        );
        context.go('/login');
      } else {
        SnackBarUtils.showError(
          context,
          message ?? (_isZh ? '删除失败' : 'Deletion failed'),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '${_isZh ? '删除失败' : 'Deletion failed'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearingLocalData = false);
      }
    }
  }

  Future<void> _openDeletionRequest() async {
    setState(() => _isOpeningRequest = true);
    try {
      final appProvider = context.read<AppProvider>();
      final user = appProvider.user;
      final serverUrl =
          user?.serverUrl ?? appProvider.appConfig.memosApiUrl ?? '';
      final email = user?.email?.trim();
      final uri = AppConfig.accountDeletionUri.replace(
        queryParameters: {
          'source': 'app',
          'platform': defaultTargetPlatform.name,
          'version': AppConfig.getFullVersionInfo(),
          if (user != null && user.username.trim().isNotEmpty)
            'username': user.username,
          if (email != null && email.isNotEmpty) 'email': email,
          if (serverUrl.trim().isNotEmpty) 'server': serverUrl,
        },
      );

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        await _copyDeletionRequestTemplate();
      }
    } on Object catch (_) {
      if (mounted) {
        await _copyDeletionRequestTemplate();
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningRequest = false);
      }
    }
  }

  Future<void> _copyDeletionRequestTemplate() async {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.user;
    final serverUrl =
        user?.serverUrl ?? appProvider.appConfig.memosApiUrl ?? '';
    final text = _isZh
        ? '''
账号与数据删除申请

账号：${user?.username ?? '未登录'}
邮箱：${user?.email ?? '未设置'}
服务器：${serverUrl.isEmpty ? '未连接' : serverUrl}
应用版本：${AppConfig.getFullVersionInfo()}
平台：${defaultTargetPlatform.name}

我申请删除官方服务器账号及与该账号关联的数据。
'''
        : '''
Account and data deletion request

Account: ${user?.username ?? 'Not signed in'}
Email: ${user?.email ?? 'Not set'}
Server: ${serverUrl.isEmpty ? 'Not connected' : serverUrl}
App version: ${AppConfig.getFullVersionInfo()}
Platform: ${defaultTargetPlatform.name}

I request deletion of my official server account and associated data.
''';

    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (mounted) {
      SnackBarUtils.showSuccess(
        context,
        _isZh ? '删除申请信息已复制' : 'Deletion request details copied',
      );
    }
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
