import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/webdav_config.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class WebDavSettingsScreen extends StatefulWidget {
  const WebDavSettingsScreen({super.key});

  @override
  State<WebDavSettingsScreen> createState() => _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends State<WebDavSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _syncPathController = TextEditingController();

  bool _obscurePassword = true;
  bool _enabled = false;
  bool _autoBackup = false; // 改为自动备份
  String _autoBackupTiming = '每次启动'; // 备份时机
  String _selectedPreset = '自定义';
  bool _isTesting = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _syncPathController.dispose();
    super.dispose();
  }

  void _loadConfig() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final config = appProvider.webDavConfig;

    _serverUrlController.text = config.serverUrl;
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _syncPathController.text = config.syncPath;
    _enabled = config.enabled;
    _autoBackup = config.autoSync; // 兼容旧配置
    // 根据旧的 interval 映射到新的 timing
    _autoBackupTiming = _getTimingFromInterval(config.autoSyncInterval);

    // 检测预设
    _detectPreset(config.serverUrl);
  }

  String _getTimingFromInterval(int interval) {
    if (interval <= 0) return '每次启动';
    if (interval <= 15) return '15分钟';
    if (interval <= 30) return '30分钟';
    return '1小时';
  }

  int _getIntervalFromTiming(String timing) {
    switch (timing) {
      case '每次启动':
        return 0;
      case '15分钟':
        return 15;
      case '30分钟':
        return 30;
      case '1小时':
        return 60;
      default:
        return 0;
    }
  }

  String _getLocalizedTiming(String timing, AppLocalizationsSimple? l10n) {
    switch (timing) {
      case '每次启动':
        return l10n?.everyStartup ?? 'Every Startup';
      case '15分钟':
        return l10n?.every15Minutes ?? '15 Minutes';
      case '30分钟':
        return l10n?.every30Minutes ?? '30 Minutes';
      case '1小时':
        return l10n?.every1Hour ?? '1 Hour';
      default:
        return timing;
    }
  }

  void _detectPreset(String url) {
    for (final entry in WebDavPresets.presets.entries) {
      if (entry.value == url) {
        setState(() => _selectedPreset = entry.key);
        return;
      }
    }
    setState(() => _selectedPreset = '自定义');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final l10n = AppLocalizationsSimple.of(context);

    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isDesktop ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.webdavSync ?? 'WebDAV Sync',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        actions: [
          // 帮助按钮
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDarkMode
                  ? AppTheme.primaryLightColor
                  : AppTheme.primaryColor,
            ),
            onPressed: _showFAQDialog,
          ),
          // 保存按钮
          TextButton(
            onPressed: _saveConfig,
            child: Text(
              l10n?.save ?? '保存',
              style: TextStyle(
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 启用开关
            _buildEnableSwitch(isDarkMode),

            // 只有启用WebDAV后才显示配置项
            if (_enabled) ...[
              const SizedBox(height: 24),

              // 服务器预设
              _buildPresetSelector(isDarkMode, textColor),
              const SizedBox(height: 16),

              // 🎯 大厂标准：只有选择"自定义"时才显示URL输入框
              if (_selectedPreset == '自定义') ...[
                // 服务器地址
                _buildTextField(
                  controller: _serverUrlController,
                  label: l10n?.serverAddress ?? 'Server Address',
                  hint: 'https://dav.jianguoyun.com/dav/',
                  icon: Icons.cloud,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.pleaseEnterServerAddress ??
                          'Please enter server address';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return l10n?.addressMustStartWithHttp ??
                          'Address must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                // 🎯 显示当前选择的服务商信息（只读）
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryLightColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? AppTheme.primaryLightColor.withOpacity(0.3)
                          : AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isDarkMode
                            ? AppTheme.primaryLightColor
                            : AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '已选择：$_selectedPreset',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              WebDavPresets.presets[_selectedPreset] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 用户名
              _buildTextField(
                controller: _usernameController,
                label: l10n?.username ?? 'Username',
                hint: 'your@email.com',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n?.pleaseEnterUsername ?? 'Please enter username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 密码
              _buildPasswordField(isDarkMode),
              const SizedBox(height: 16),

              // 同步路径
              _buildTextField(
                controller: _syncPathController,
                label: l10n?.syncFolder ?? 'Sync Folder',
                hint: '/InkRoot/',
                icon: Icons.folder,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n?.pleaseEnterSyncFolderPath ??
                        'Please enter sync folder path';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 立即测试按钮
              _buildTestButton(isDarkMode),
              const SizedBox(height: 12),

              // 立即备份按钮
              _buildBackupButton(isDarkMode),
              const SizedBox(height: 12),

              // 从 WebDAV 恢复按钮
              _buildRestoreButton(isDarkMode),
              const SizedBox(height: 24),

              // 高级设置
              _buildAdvancedSettings(isDarkMode, textColor),

              const SizedBox(height: 24),

              // 说明文本
              _buildHelpText(textColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSwitch(bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.sync,
            color:
                isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n?.enableWebdavSync ?? 'Enable WebDAV Sync',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppTheme.darkTextPrimaryColor
                    : AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(bool isDarkMode, Color textColor) {
    final l10n = AppLocalizationsSimple.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPreset,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: TextStyle(fontSize: 16, color: textColor),
          items: WebDavPresets.presets.keys.map((String preset) {
            // 如果是"自定义"，则使用国际化文本
            final displayText =
                preset == '自定义' ? (l10n?.custom ?? '自定义') : preset;
            return DropdownMenuItem<String>(
              value: preset,
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _selectedPreset = value;
                // 🎯 大厂标准：切换预设时自动填充对应的URL
                final url = WebDavPresets.presets[value] ?? '';
                if (url.isNotEmpty) {
                  _serverUrlController.text = url;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        color: isDarkMode
            ? AppTheme.darkTextPrimaryColor
            : AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n?.pleaseEnterPassword ?? 'Please enter password';
        }
        return null;
      },
      style: TextStyle(
        color: isDarkMode
            ? AppTheme.darkTextPrimaryColor
            : AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        labelText: l10n?.passwordAppSpecific ?? '密码（应用专用密码）',
        hintText: l10n?.notLoginPassword ?? '⚠️ 不是登录密码！需在服务商处生成',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon:
              Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        helperText: l10n?.clickHelpIcon ?? '💡 点击右上角 ? 查看如何获取',
        helperMaxLines: 2,
      ),
    );
  }

  Widget _buildTestButton(bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isTesting ? null : _testConnection,
        icon: _isTesting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.link),
        label: Text(
          _isTesting
              ? (l10n?.testing ?? 'Testing...')
              : (l10n?.testNow ?? 'Test Now'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupButton(bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed:
            (_isBackingUp || _isRestoring || !_enabled) ? null : _backupNow,
        icon: _isBackingUp
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.backup,
                color: Colors.white,
              ),
        label: Text(
          _isBackingUp
              ? (l10n?.backingUp ?? 'Backing up...')
              : (l10n?.backupNow ?? 'Backup Now'),
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _enabled
              ? (isDarkMode
                  ? AppTheme.primaryLightColor
                  : AppTheme.primaryColor)
              : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed:
            (_isBackingUp || _isRestoring || !_enabled) ? null : _restoreNow,
        icon: _isRestoring
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDarkMode ? Colors.orange[300] : Colors.orange,
                ),
              )
            : Icon(
                Icons.cloud_download,
                color: _enabled
                    ? (isDarkMode ? Colors.orange[300] : Colors.orange)
                    : Colors.grey,
              ),
        label: Text(
          _isRestoring
              ? (l10n?.restoring ?? 'Restoring...')
              : (l10n?.restoreFromWebdav ?? 'Restore from WebDAV'),
          style: TextStyle(
            color: _enabled
                ? (isDarkMode ? Colors.orange[300] : Colors.orange)
                : Colors.grey,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _enabled
                ? (isDarkMode ? Colors.orange[300]! : Colors.orange)
                : Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings(bool isDarkMode, Color textColor) {
    final l10n = AppLocalizationsSimple.of(context);
    return ExpansionTile(
      title: Text(
        '定时备份设置',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      children: [
        SwitchListTile(
          title: Text(l10n?.enableTimedBackup ?? 'Enable Timed Backup'),
          subtitle:
              Text(l10n?.autoBackupToWebdav ?? 'Auto backup notes to WebDAV'),
          value: _autoBackup,
          onChanged: (value) => setState(() => _autoBackup = value),
        ),
        if (_autoBackup)
          ListTile(
            title: Text(l10n?.backupTiming ?? 'Backup Timing'),
            subtitle: Text(_getLocalizedTiming(_autoBackupTiming, l10n)),
            trailing: DropdownButton<String>(
              value: _autoBackupTiming,
              items: [
                DropdownMenuItem(
                  value: '每次启动',
                  child: Text(l10n?.everyStartup ?? 'Every Startup'),
                ),
                DropdownMenuItem(
                  value: '15分钟',
                  child: Text(l10n?.every15Minutes ?? '15 Minutes'),
                ),
                DropdownMenuItem(
                  value: '30分钟',
                  child: Text(l10n?.every30Minutes ?? '30 Minutes'),
                ),
                DropdownMenuItem(
                  value: '1小时',
                  child: Text(l10n?.every1Hour ?? '1 Hour'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _autoBackupTiming = value);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHelpText(Color textColor) {
    final l10n = AppLocalizationsSimple.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n?.help ?? '使用说明',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.webdavHelpText ??
                '• 推荐使用坚果云等专业 WebDAV 服务\n'
                '• ⚠️ 密码栏必须填写"应用专用密码"，不是登录密码！\n'
                '• 点击右上角"?"查看详细配置步骤\n'
                '• 立即测试：验证服务器连接是否正常\n'
                '• 立即备份：单向上传，完整备份所有数据到云端\n'
                '• 从 WebDAV 恢复：下载云端数据到本地（会覆盖本地）\n'
                '• 定时备份：可选择每次启动或定时自动备份',
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isTesting = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final config = WebDavConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        syncPath: _syncPathController.text.trim(),
        enabled: _enabled,
        autoSync: _autoBackup,
        autoSyncInterval: _getIntervalFromTiming(_autoBackupTiming),
      );

      final success = await appProvider.testWebDavConnection(config);

      if (mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, '连接测试成功！');
        } else {
          SnackBarUtils.showError(context, '连接测试失败，请检查配置');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '测试失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final config = WebDavConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        syncPath: _syncPathController.text.trim(),
        enabled: _enabled,
        autoSync: _autoBackup,
        autoSyncInterval: _getIntervalFromTiming(_autoBackupTiming),
      );

      // 🔧 改进：保存配置时跳过服务器连接，避免网络问题导致保存失败
      // 配置保存是纯本地操作，不需要验证服务器连接
      // 用户可以使用"立即测试"按钮来验证连接
      await appProvider.updateWebDavConfig(config, skipInitialize: true);

      if (mounted) {
        final l10n = AppLocalizationsSimple.of(context);
        SnackBarUtils.showSuccess(
          context,
          l10n?.webdavConfigSaved ?? 'WebDAV config saved',
        );
        // 使用 GoRouter 的 pop 方法，避免导航历史为空的错误
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '保存失败: $e');
      }
    }
  }

  Future<void> _backupNow() async {
    if (!_enabled) {
      SnackBarUtils.showWarning(context, '请先启用 WebDAV 同步');
      return;
    }

    setState(() => _isBackingUp = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 确保配置已保存
      final config = WebDavConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        syncPath: _syncPathController.text.trim(),
        enabled: _enabled,
        autoSync: _autoBackup,
        autoSyncInterval: _getIntervalFromTiming(_autoBackupTiming),
      );

      // 保存配置（跳过初始化，备份操作会自动初始化）
      await appProvider.updateWebDavConfig(config, skipInitialize: true);

      // 🎯 大厂标准：显示真实进度对话框
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ProgressDialog(
          title: '正在备份',
          isRestore: false,
          onProgress: (callback) async {
            // 执行备份，传入进度回调
            final stats = await appProvider.backupWithWebDav(
              onProgress: callback,
            );
            
            // 延迟一下让用户看到100%
            await Future.delayed(const Duration(milliseconds: 500));
            
            // 关闭对话框
            if (mounted) {
              Navigator.of(context).pop();
            }

            // 显示结果
            if (mounted) {
              if (stats != null) {
                final message = '✅ 备份完成\n'
                    '📝 笔记: ${stats.uploaded} 条\n'
                    '${stats.errors > 0 ? '⚠️ 错误: ${stats.errors}' : ''}';
                SnackBarUtils.showSuccess(context, message);
              } else {
                SnackBarUtils.showWarning(context, '备份服务未初始化');
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '备份失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  // 显示常见问题对话框
  void _showFAQDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'WebDAV 使用指南',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: secondaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 内容
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFAQItem(
                        context,
                        question: '🤔 什么是 WebDAV？',
                        answer:
                            'WebDAV 是一种网络协议，可以让你将笔记备份到云端服务器。本应用支持使用 WebDAV 进行笔记备份和恢复。',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔑 推荐的 WebDAV 服务？',
                        answer: '• 坚果云（推荐）：国内访问速度快，每月免费1GB流量\n'
                            '• iCloud Drive：苹果用户原生支持\n'
                            '• Nextcloud：开源自建方案\n'
                            '• Synology NAS：自建私有云',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔑 密码不是登录密码！如何获取？',
                        answer: '⚠️ 重要：这里需要填写的是"应用专用密码"，不是账号的登录密码！\n\n'
                            '为什么不能用登录密码？\n'
                            '• 出于安全考虑，WebDAV 服务需要单独的授权密码\n'
                            '• 应用专用密码可以随时删除，不影响账号安全\n'
                            '• 即使密码泄露，也只影响这个应用\n\n'
                            '如何生成应用专用密码（以坚果云为例）：\n'
                            '1. 登录坚果云网页版\n'
                            '2. 右上角头像 → "账户信息"\n'
                            '3. 找到"安全选项"部分\n'
                            '4. 点击"添加应用密码"\n'
                            '5. 应用名称填"IntRoot"或其他名称\n'
                            '6. 点击"生成密码"\n'
                            '7. ✅ 复制生成的密码，粘贴到这里的"密码"栏\n\n'
                            '💡 提示：生成后的密码只显示一次，请立即复制保存！',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🌐 服务器地址和用户名怎么填？',
                        answer: '以坚果云为例：\n\n'
                            '📍 服务器地址（固定的）：\n'
                            'https://dav.jianguoyun.com/dav/\n'
                            '⚠️ 注意：必须以 / 结尾！\n\n'
                            '👤 用户名：\n'
                            '你的坚果云账号邮箱地址（完整邮箱）\n'
                            '例如：zhangsan@example.com\n\n'
                            '🔐 密码：\n'
                            '应用专用密码（参考上一条问题）\n\n'
                            '📁 同步文件夹：\n'
                            '/InkRoot/（推荐）\n'
                            '或自定义任意路径，如 /备份/笔记/\n'
                            '⚠️ 必须以 / 开头和结尾！',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🌰 其他 WebDAV 服务如何配置？',
                        answer: '各服务商配置方法类似：\n\n'
                            '1️⃣ iCloud Drive：\n'
                            '• 服务器：https://contacts.icloud.com/\n'
                            '• 用户名：你的 Apple ID\n'
                            '• 密码：需要在 appleid.apple.com 生成"应用专用密码"\n\n'
                            '2️⃣ Nextcloud（自建）：\n'
                            '• 服务器：https://你的域名/remote.php/dav/files/用户名/\n'
                            '• 用户名：Nextcloud 用户名\n'
                            '• 密码：在 Nextcloud 设置中生成应用密码\n\n'
                            '3️⃣ Synology NAS：\n'
                            '• 服务器：https://你的NAS地址:5006/（推荐HTTPS）\n'
                            '• 用户名：NAS 账号\n'
                            '• 密码：建议在 DSM 中创建专用账号\n\n'
                            '💡 通用原则：大多数服务都需要"应用专用密码"而非登录密码！',
                      ),
                      _buildFAQItem(
                        context,
                        question: '📤 "立即备份"是什么意思？',
                        answer:
                            '立即备份会将所有本地笔记上传到 WebDAV 服务器。这是单向上传操作，不会下载或删除任何本地数据，可以放心使用。',
                      ),
                      _buildFAQItem(
                        context,
                        question: '📥 "从 WebDAV 恢复"会怎样？',
                        answer: '从 WebDAV 恢复会下载云端所有笔记到本地。\n\n⚠️ 注意：\n'
                            '• 如果本地和云端有相同笔记，会保留云端版本\n'
                            '• 建议操作前先做一次备份\n'
                            '• 适合更换设备或数据丢失时使用',
                      ),
                      _buildFAQItem(
                        context,
                        question: '⏰ 定时备份如何工作？',
                        answer: '启用定时备份后，应用会在指定时机自动备份笔记：\n'
                            '• 每次启动：每次打开应用时自动备份\n'
                            '• 15/30/60分钟：后台定期自动备份\n\n建议选择"每次启动"，既保证数据安全又节省流量。',
                      ),
                      _buildFAQItem(
                        context,
                        question: '❌ 常见错误排查',
                        answer: '1. ⚠️ 认证失败 / 401 错误（最常见）\n'
                            '   原因：使用了登录密码而非应用专用密码！\n'
                            '   解决：\n'
                            '   • 坚果云：在网页版生成"应用密码"\n'
                            '   • iCloud：在 Apple ID 网站生成"应用专用密码"\n'
                            '   • Nextcloud：在设置中生成"应用密码"\n'
                            '   ❗ 绝对不要填写登录密码！\n\n'
                            '2. 🔌 连接失败 / 网络错误\n'
                            '   • 检查手机网络连接\n'
                            '   • 确认服务器地址正确且以 / 结尾\n'
                            '   • 检查服务器是否可访问（浏览器打开试试）\n'
                            '   • 如果是自建服务，确认端口和防火墙设置\n\n'
                            '3. 📁 路径错误\n'
                            '   • 同步路径必须以 / 开头和结尾\n'
                            '   • 正确：/InkRoot/ 或 /备份/笔记/\n'
                            '   • 错误：InkRoot 或 /InkRoot\n\n'
                            '4. 👤 用户名错误\n'
                            '   • 坚果云：必须填写完整邮箱\n'
                            '   • 其他服务：填写实际的登录用户名',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔒 数据安全吗？',
                        answer: '• WebDAV 使用 HTTPS 加密传输\n'
                            '• 密码仅存储在本地设备\n'
                            '• 数据存储在你选择的服务器上\n'
                            '• 应用不会收集或上传你的任何数据',
                      ),
                      _buildFAQItem(
                        context,
                        question: '💾 备份包含哪些内容？',
                        answer: '备份会包含：\n'
                            '• 所有笔记内容\n'
                            '• 笔记的创建和修改时间\n'
                            '• 笔记的可见性设置\n'
                            '• 笔记的标签\n\n不包含：\n'
                            '• 应用设置\n'
                            '• 笔记中的图片（建议使用图床）',
                      ),
                      _buildFAQItem(
                        context,
                        question: '📊 流量消耗如何？',
                        answer: '• 纯文本笔记流量消耗很小\n'
                            '• 坚果云免费用户：每月1GB上传流量，3GB下载流量\n'
                            '• 一般用户足够使用\n'
                            '• 建议使用"每次启动"而非高频定时备份',
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '提示：建议先使用"测试连接"确保配置正确，再进行备份操作。',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建FAQ项目
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _restoreNow() async {
    if (!_enabled) {
      SnackBarUtils.showWarning(context, '请先启用 WebDAV 同步');
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 确认恢复'),
        content: const Text(
          '此操作将从 WebDAV 下载所有笔记到本地。\n\n如果本地和远程有相同的笔记，将保留远程版本（覆盖本地）。\n\n是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('确认恢复', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 确保配置已保存
      final config = WebDavConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        syncPath: _syncPathController.text.trim(),
        enabled: _enabled,
        autoSync: _autoBackup,
        autoSyncInterval: _getIntervalFromTiming(_autoBackupTiming),
      );

      // 保存配置（跳过初始化，恢复操作会自动初始化）
      await appProvider.updateWebDavConfig(config, skipInitialize: true);

      // 🎯 大厂标准：显示真实进度对话框
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ProgressDialog(
          title: '正在恢复',
          isRestore: true,
          onProgress: (callback) async {
            // 执行恢复，传入进度回调
            final stats = await appProvider.restoreFromWebDav(
              onProgress: callback,
            );
            
            // 延迟一下让用户看到100%
            await Future.delayed(const Duration(milliseconds: 500));
            
            // 关闭对话框
            if (mounted) {
              Navigator.of(context).pop();
            }

            // 显示结果
            if (mounted) {
              if (stats != null) {
                final message = '✅ 恢复完成\n'
                    '📥 已恢复: ${stats.downloaded} 条笔记';
                SnackBarUtils.showSuccess(context, message);
              } else {
                SnackBarUtils.showWarning(context, '恢复服务未初始化');
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '恢复失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }
}

// 🎯 大厂标准：真实进度对话框（线性进度条 + 百分比）
class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({
    required this.title,
    required this.onProgress,
    this.isRestore = false,
  });

  final String title; // '正在备份' 或 '正在恢复'
  final Future<void> Function(Function(double, String) callback) onProgress;
  final bool isRestore; // 是否为恢复操作（用于显示不同图标）

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  double _progress = 0.0;
  String _message = '';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  Future<void> _startProgress() async {
    try {
      await widget.onProgress((progress, message) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _message = message;
            _isCompleted = progress >= 1.0;
          });
        }
      });
    } catch (e) {
      // 错误处理由外层处理
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return WillPopScope(
      onWillPop: () async => false, // 防止用户关闭
      child: Dialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isCompleted 
                      ? Icons.check_circle_outline 
                      : (widget.isRestore ? Icons.cloud_download_outlined : Icons.cloud_upload_outlined),
                  size: 32,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // 百分比
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),

              // 当前操作描述
              Text(
                _message.isEmpty ? '准备中...' : _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // 提示文本
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '请勿关闭此页面',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
