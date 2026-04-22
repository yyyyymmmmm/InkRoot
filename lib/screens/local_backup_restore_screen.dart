import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LocalBackupRestoreScreen extends StatefulWidget {
  const LocalBackupRestoreScreen({super.key});

  @override
  State<LocalBackupRestoreScreen> createState() => _LocalBackupRestoreScreenState();
}

class _LocalBackupRestoreScreenState extends State<LocalBackupRestoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastBackupTime;
  int _notesCount = 0;
  double _backupSize = 0;
  final List<String> _exportFormats = ['JSON', 'Markdown', 'TXT', 'HTML'];
  String _selectedExportFormat = 'JSON';
  bool _includeImages = true;
  bool _includeTags = true;
  bool _encryptBackup = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();
  List<Map<String, dynamic>> _importHistory = [];

  // 导入选项
  bool _overwriteExisting = false;
  bool _importAsNew = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBackupInfo();
    _loadImportHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 加载导入历史
  Future<void> _loadImportHistory() async {
    final history = await _preferencesService.getImportHistory();
    if (mounted) {
      setState(() {
        _importHistory = history;
      });
    }
  }

  // 加载备份信息
  Future<void> _loadBackupInfo() async {
    try {
      // 获取上次备份时间
      final lastBackup = await _preferencesService.getLastBackupTime();
      var lastBackupStr =
          AppLocalizationsSimple.of(context)?.neverBackedUp ?? '从未备份';
      if (lastBackup != null) {
        final now = DateTime.now();
        final diff = now.difference(lastBackup);

        if (diff.inMinutes < 1) {
          lastBackupStr = AppLocalizationsSimple.of(context)?.justNow ?? '刚刚';
        } else if (diff.inMinutes < 60) {
          lastBackupStr =
              '${diff.inMinutes}${AppLocalizationsSimple.of(context)?.minutesAgo ?? '分钟前'}';
        } else if (diff.inHours < 24) {
          lastBackupStr =
              '${diff.inHours}${AppLocalizationsSimple.of(context)?.hoursAgo ?? '小时前'}';
        } else if (diff.inDays < 30) {
          lastBackupStr =
              '${diff.inDays}${AppLocalizationsSimple.of(context)?.daysAgo ?? '天前'}';
        } else {
          final formatter = DateFormat('yyyy-MM-dd HH:mm');
          lastBackupStr = formatter.format(lastBackup);
        }
      }

      // 获取笔记数量
      final count = await _databaseService.getNotesCount();

      // 获取数据库大小
      final size = await _databaseService.getDatabaseSize();
      final sizeInMB = size / (1024 * 1024);

      if (mounted) {
        setState(() {
          _lastBackupTime = lastBackupStr;
          _notesCount = count;
          _backupSize = sizeInMB;
        });
      }
    } catch (e) {
      debugPrint('加载备份信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final unselectedColor = isDarkMode ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '本地备份/恢复',
          style: TextStyle(color: textColor),
        ),
        elevation: 0,
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : null),
        bottom: TabBar(
          controller: _tabController,
          labelColor: iconColor,
          unselectedLabelColor: unselectedColor,
          indicatorColor: iconColor,
          tabs: [
            Tab(text: AppLocalizationsSimple.of(context)?.exportTab ?? '导出备份'),
            Tab(text: AppLocalizationsSimple.of(context)?.importTab ?? '导入恢复'),
          ],
        ),
      ),
      backgroundColor: backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          // 导出备份标签页
          _buildExportTab(),

          // 导入恢复标签页
          _buildImportTab(),
        ],
      ),
    );
  }

  // 构建导出标签页
  Widget _buildExportTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 备份信息卡片
          _buildInfoCard(),

          const SizedBox(height: 16),

          // 导出选项卡片
          _buildExportOptionsCard(),

          const SizedBox(height: 16),

          // 加密选项卡片
          _buildEncryptionCard(),

          const SizedBox(height: 24),

          // 导出按钮
          _buildExportButton(),

          const SizedBox(height: 16),
        ],
      );

  // 构建导入标签页
  Widget _buildImportTab() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 导入说明卡片
          _buildImportInfoCard(),

          const SizedBox(height: 16),

          // 导入选项卡片
          _buildImportOptionsCard(),

          const SizedBox(height: 16),

          // 导入历史卡片
          _buildImportHistoryCard(),

          const SizedBox(height: 24),

          // 导入按钮
          _buildImportButton(),

          const SizedBox(height: 16),
        ],
      );

  // 备份信息卡片
  Widget _buildInfoCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.backupInfoTitle ?? '备份信息',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(
                Icons.access_time,
                AppLocalizationsSimple.of(context)?.lastBackupTime ?? '上次备份',
                _lastBackupTime ??
                    (AppLocalizationsSimple.of(context)?.neverBackedUp ??
                        '从未备份'),
              ),
              const SizedBox(height: 12),
              _infoRow(
                Icons.note,
                AppLocalizationsSimple.of(context)?.notesCount ?? '笔记数量',
                '$_notesCount ${AppLocalizationsSimple.of(context)?.notesItem ?? '条笔记'}',
              ),
              const SizedBox(height: 12),
              _infoRow(
                Icons.sd_storage,
                AppLocalizationsSimple.of(context)?.backupSizeLabel ?? '备份大小',
                '${_backupSize.toStringAsFixed(1)} MB',
              ),
            ],
          ),
        ),
      );

  // 导出选项卡片
  Widget _buildExportOptionsCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.exportOptionsTitle ??
                    '导出选项',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 导出格式选择
              Text(
                AppLocalizationsSimple.of(context)?.exportFormatLabel ?? '导出格式',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _exportFormats.map((format) {
                  final isSelected = _selectedExportFormat == format;
                  return ChoiceChip(
                    label: Text(format),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedExportFormat = format;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // 包含图片选项
              _buildSwitchOption(
                title: AppLocalizationsSimple.of(context)?.includeImagesLabel ??
                    '包含图片',
                subtitle: AppLocalizationsSimple.of(context)
                        ?.includeImagesDescription ??
                    '将笔记中的图片一同导出',
                value: _includeImages,
                onChanged: (value) {
                  setState(() {
                    _includeImages = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // 包含标签选项
              _buildSwitchOption(
                title: AppLocalizationsSimple.of(context)?.includeTagsLabel ??
                    '包含标签',
                subtitle: AppLocalizationsSimple.of(context)
                        ?.includeTagsDescription ??
                    '保留笔记的标签信息',
                value: _includeTags,
                onChanged: (value) {
                  setState(() {
                    _includeTags = value;
                  });
                },
              ),
            ],
          ),
        ),
      );

  // 加密选项卡片
  Widget _buildEncryptionCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.encryptionOptionsTitle ??
                    '加密选项',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 加密备份选项
              _buildSwitchOption(
                title: AppLocalizationsSimple.of(context)?.encryptBackupLabel ??
                    '加密备份',
                subtitle: AppLocalizationsSimple.of(context)
                        ?.encryptBackupDescription ??
                    '使用密码保护您的备份文件',
                value: _encryptBackup,
                onChanged: (value) {
                  setState(() {
                    _encryptBackup = value;
                  });
                },
              ),

              if (_encryptBackup) ...[
                const SizedBox(height: 16),

                // 密码输入框
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizationsSimple.of(context)?.setPassword ??
                            '设置密码',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),

                const SizedBox(height: 12),

                // 确认密码输入框
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizationsSimple.of(context)?.confirmPassword ??
                            '确认密码',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 8),

                // 密码提示
                Text(
                  AppLocalizationsSimple.of(context)?.rememberPasswordWarning ??
                      '请记住您的密码，如果忘记将无法恢复备份数据',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  // 导出按钮
  Widget _buildExportButton() => ElevatedButton(
        onPressed: _isExporting ? null : _exportData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isExporting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizationsSimple.of(context)?.exporting ?? '导出中...',
                  ),
                ],
              )
            : Text(
                AppLocalizationsSimple.of(context)?.startExportButton ?? '导出备份',
              ),
      );

  // 导入信息卡片
  Widget _buildImportInfoCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.importDescription ?? '导入说明',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizationsSimple.of(context)
                        ?.supportedFormatsDescription ??
                    '支持导入以下格式的备份文件：',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildSupportedFormatItem('JSON', 'InkRoot-墨鸣笔记标准备份格式'),
              _buildSupportedFormatItem(
                'Markdown',
                AppLocalizationsSimple.of(context)?.markdownBatchImport ??
                    '支持批量导入Markdown文件',
              ),
              _buildSupportedFormatItem(
                'TXT',
                AppLocalizationsSimple.of(context)?.txtImportDescription ??
                    '纯文本文件将作为单独笔记导入',
              ),
              _buildSupportedFormatItem(
                'HTML',
                AppLocalizationsSimple.of(context)?.htmlImportDescription ??
                    '支持从其他笔记软件导出的HTML',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizationsSimple.of(context)?.importWarning ??
                            '导入操作可能会影响现有数据，建议先备份当前数据',
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // 导入选项卡片
  Widget _buildImportOptionsCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.importOptions ?? '导入选项',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 覆盖现有笔记选项
              _buildSwitchOption(
                title: AppLocalizationsSimple.of(context)
                        ?.overwriteExistingNotes ??
                    '覆盖现有笔记',
                subtitle:
                    AppLocalizationsSimple.of(context)?.overwriteDescription ??
                        '如果导入的笔记与现有笔记ID相同，则覆盖现有笔记',
                value: _overwriteExisting,
                onChanged: (value) {
                  setState(() {
                    _overwriteExisting = value;
                    if (value) {
                      _importAsNew = false;
                    }
                  });
                },
              ),

              const SizedBox(height: 12),

              // 作为新笔记导入选项
              _buildSwitchOption(
                title: AppLocalizationsSimple.of(context)?.importAsNewNotes ??
                    '作为新笔记导入',
                subtitle: AppLocalizationsSimple.of(context)
                        ?.importAsNewDescription ??
                    '所有导入的笔记将作为新笔记添加，不会影响现有笔记',
                value: _importAsNew,
                onChanged: (value) {
                  setState(() {
                    _importAsNew = value;
                    if (value) {
                      _overwriteExisting = false;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      );

  // 导入历史卡片
  Widget _buildImportHistoryCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizationsSimple.of(context)?.importHistory ?? '导入历史',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_importHistory.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadImportHistory,
                      tooltip: AppLocalizationsSimple.of(context)
                              ?.refreshImportHistory ??
                          '刷新导入历史',
                      iconSize: 20,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_importHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizationsSimple.of(context)?.noImportHistory ??
                          '暂无导入历史记录',
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _importHistory.length,
                  itemBuilder: (context, index) {
                    final history = _importHistory[index];
                    final importDate =
                        DateTime.parse(history['date'] as String);
                    final formattedDate =
                        DateFormat('yyyy-MM-dd HH:mm').format(importDate);
                    final format = history['format'] as String? ??
                        (AppLocalizationsSimple.of(context)?.unknown ?? '未知');

                    IconData formatIcon;
                    switch (format.toLowerCase()) {
                      case 'json':
                        formatIcon = Icons.data_object;
                        break;
                      case 'markdown':
                        formatIcon = Icons.article;
                        break;
                      case 'txt':
                        formatIcon = Icons.text_snippet;
                        break;
                      case 'html':
                        formatIcon = Icons.code;
                        break;
                      default:
                        formatIcon = Icons.insert_drive_file;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(formatIcon, color: AppTheme.primaryColor),
                      ),
                      title: Text(history['source'] as String),
                      subtitle: Text(
                        '$formattedDate · 导入 ${history['count']} 条笔记 · $format',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );

  // 导入按钮
  Widget _buildImportButton() => ElevatedButton(
        onPressed: _isImporting ? null : _showImportOptions,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isImporting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('导入中...'),
                ],
              )
            : Text(
                AppLocalizationsSimple.of(context)?.selectImportMethod ??
                    '选择导入方式',
              ),
      );

  // 支持的格式项
  Widget _buildSupportedFormatItem(String format, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                format,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

  // 信息行
  Widget _infoRow(IconData icon, String title, String value) => Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$title:',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  // 开关选项
  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      );

  // 检查和请求存储权限
  Future<bool> _checkAndRequestStoragePermission() async {
    if (Platform.isAndroid) {
      // 检查 Android 版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        // Android 11 及以上
        // 检查是否有所有文件访问权限
        if (!await Permission.manageExternalStorage.isGranted) {
          // 显示对话框解释为什么需要权限
          final shouldRequest = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('需要存储权限'),
                  content: const Text('为了能够导出备份文件，需要授予"所有文件访问权限"。\n\n'
                      '请在接下来的系统设置页面中：\n'
                      '1. 点击"允许访问所有文件"\n'
                      '2. 找到并允许"InkRoot-墨鸣笔记"的权限'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        AppLocalizationsSimple.of(context)?.cancel ?? '取消',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizationsSimple.of(context)?.goToSettings ??
                            '前往设置',
                      ),
                    ),
                  ],
                ),
              ) ??
              false;

          if (!shouldRequest) {
            return false;
          }

          // 打开系统设置页面
          await openAppSettings();

          // 等待用户从设置页面返回，然后重新检查权限
          if (!await Permission.manageExternalStorage.isGranted) {
            _showErrorDialog(
              AppLocalizationsSimple.of(context)?.allFilesAccessRequired ??
                  '需要"所有文件访问权限"才能导出文件',
            );
            return false;
          }
        }
      } else {
        // Android 10 及以下
        if (!await Permission.storage.isGranted) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            _showErrorDialog(
              AppLocalizationsSimple.of(context)
                      ?.storagePermissionRequiredForExport ??
                  '需要存储权限才能导出文件',
            );
            return false;
          }
        }
      }
    }
    return true;
  }

  // 导出数据
  Future<void> _exportData() async {
    if (_encryptBackup) {
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (password.isEmpty) {
        _showErrorDialog(
          AppLocalizationsSimple.of(context)?.pleaseEnterPassword ?? '请输入密码',
        );
        return;
      }

      if (password != confirmPassword) {
        _showErrorDialog(
          AppLocalizationsSimple.of(context)?.passwordMismatch ?? '两次输入的密码不一致',
        );
        return;
      }
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // 生成备份文件名
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      var fileName =
          'momingbiji_backup_${formatter.format(now)}.$_selectedExportFormat'
              .toLowerCase();

      // 根据选择的格式导出数据
      String fileContent;
      Uint8List fileBytes;
      var notesCount = _notesCount;

      try {
        switch (_selectedExportFormat) {
          case 'JSON':
            fileContent = await _databaseService.exportNotesToJson();
            if (_encryptBackup) {
              fileContent =
                  await _encryptContent(fileContent, _passwordController.text);
            }
            fileBytes = Uint8List.fromList(utf8.encode(fileContent));
            break;

          case 'Markdown':
            final notes = await _databaseService.getNotes();
            notesCount = notes.length;

            // 创建ZIP文件
            final archive = Archive();

            // 每个笔记保存为单独的md文件
            for (var i = 0; i < notes.length; i++) {
              final note = notes[i];
              final noteFileName = 'note_${i + 1}.md';
              final noteContent = note.content;
              final bytes = utf8.encode(noteContent);

              final archiveFile =
                  ArchiveFile(noteFileName, bytes.length, bytes);
              archive.addFile(archiveFile);
            }

            final zipBytes = ZipEncoder().encode(archive);
            fileBytes = Uint8List.fromList(zipBytes ?? []);
            fileName = fileName.replaceAll('.markdown', '.zip');
            break;

          case 'TXT':
            final notes = await _databaseService.getNotes();
            notesCount = notes.length;
            final buffer = StringBuffer();

            for (final note in notes) {
              buffer.writeln('--- 笔记 ${note.id} ---');
              buffer.writeln(
                '创建时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(note.createdAt)}',
              );
              buffer.writeln(
                '更新时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(note.updatedAt)}',
              );
              buffer.writeln('标签: ${note.tags.join(', ')}');
              buffer.writeln('内容:');
              buffer.writeln(note.content);
              buffer.writeln('\n--------------------\n');
            }

            fileContent = buffer.toString();
            if (_encryptBackup) {
              fileContent =
                  await _encryptContent(fileContent, _passwordController.text);
            }
            fileBytes = Uint8List.fromList(utf8.encode(fileContent));
            break;

          case 'HTML':
            final notes = await _databaseService.getNotes();
            notesCount = notes.length;

            final buffer = StringBuffer();
            buffer.writeln('<!DOCTYPE html>');
            buffer.writeln('<html><head>');
            buffer.writeln('<meta charset="UTF-8">');
            buffer.writeln('<title>InkRoot-墨鸣笔记备份</title>');
            buffer.writeln('<style>');
            buffer.writeln(
              'body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }',
            );
            buffer.writeln(
              '.note { border: 1px solid #ddd; padding: 15px; margin-bottom: 20px; border-radius: 5px; }',
            );
            buffer.writeln(
              '.note-meta { color: #666; font-size: 0.9em; margin-bottom: 10px; }',
            );
            buffer.writeln('.note-content { white-space: pre-wrap; }');
            buffer.writeln('.tags { color: #007bff; }');
            buffer.writeln('</style>');
            buffer.writeln('</head><body>');
            buffer.writeln('<h1>InkRoot-墨鸣笔记备份</h1>');
            buffer.writeln(
              '<p>导出时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}</p>',
            );
            buffer.writeln('<p>笔记总数: $notesCount</p>');

            for (final note in notes) {
              buffer.writeln('<div class="note">');
              buffer.writeln('<div class="note-meta">');
              buffer.writeln(
                '创建时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(note.createdAt)}<br>',
              );
              buffer.writeln(
                '更新时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(note.updatedAt)}<br>',
              );
              if (note.tags.isNotEmpty) {
                buffer.writeln(
                  '标签: <span class="tags">${note.tags.map((t) => '#$t').join(' ')}</span>',
                );
              }
              buffer.writeln('</div>');
              buffer.writeln('<div class="note-content">');
              buffer.writeln(
                note.content.replaceAll('<', '&lt;').replaceAll('>', '&gt;'),
              );
              buffer.writeln('</div>');
              buffer.writeln('</div>');
            }

            buffer.writeln('</body></html>');

            fileContent = buffer.toString();
            fileBytes = Uint8List.fromList(utf8.encode(fileContent));
            break;

          default:
            throw Exception(
              AppLocalizationsSimple.of(context)?.unsupportedExportFormat ??
                  '不支持的导出格式',
            );
        }
      } catch (e) {
        throw Exception('生成文件内容失败: $e');
      }

      // 显示导出选项对话框
      final exportChoice = await _showExportChoiceDialog();
      if (exportChoice == null) {
        return; // 用户取消
      }

      if (exportChoice == 'local') {
        // 保存到本地
        await _saveFileWithAndroidOptimization(fileName, fileBytes, notesCount);
      } else if (exportChoice == 'share') {
        // 分享文件
        await _shareToFilesApp(fileName, fileBytes);
      }

      // 保存导出历史记录
      await _preferencesService.saveExportHistory(
        fileName,
        notesCount,
        _selectedExportFormat,
      );

      // 更新上次备份时间
      await _preferencesService.saveLastBackupTime();

      // 重新加载备份信息
      await _loadBackupInfo();
    } catch (e) {
      _showErrorDialog('导出失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // 加密内容
  Future<String> _encryptContent(String content, String password) async {
    // 这里实现加密逻辑
    // 简单示例使用Base64编码，实际应用中应使用更安全的加密算法
    final bytes = utf8.encode(content);
    final passwordBytes = utf8.encode(password);

    // 创建HMAC密钥
    final hmacSha256 = Hmac(sha256, passwordBytes);

    // 使用密钥加密内容
    final digest = hmacSha256.convert(bytes);

    // 将原始内容与加密摘要组合
    final encryptedContent = {
      'content': base64Encode(bytes),
      'signature': digest.toString(),
      'version': '1.0',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(encryptedContent);
  }

  // 显示导入选项
  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择导入方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildImportOption(
              icon: Icons.file_copy,
              title: '从本地文件导入',
              subtitle: '选择设备上的备份文件',
              onTap: () {
                Navigator.pop(context);
                _importFromLocalFile();
              },
            ),
            const Divider(),
            _buildImportOption(
              icon: Icons.cloud_sync,
              title: '从云端同步',
              subtitle: '与云端数据同步',
              onTap: () {
                Navigator.pop(context);
                _syncFromCloud();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建导入选项
  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      );

  // 从本地文件导入
  Future<void> _importFromLocalFile() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // 使用file_picker选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'md', 'txt', 'html', 'zip', 'markdown'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final file = File(result.files.first.path!);
      final fileName =
          file.path.split(Platform.pathSeparator).last.toLowerCase();

      if (!file.existsSync()) {
        throw Exception('文件不存在');
      }

      if (fileName.endsWith('.zip')) {
        // 读取ZIP文件
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final fileNames = <String>[];
        final contents = <String>[];

        for (final archiveFile in archive) {
          if (archiveFile.isFile) {
            final fileName = archiveFile.name.toLowerCase();
            if (fileName.endsWith('.md') || fileName.endsWith('.txt')) {
              fileNames.add(archiveFile.name);
              final content = utf8.decode(archiveFile.content as List<int>);
              contents.add(content);
            }
          }
        }

        if (fileNames.isEmpty) {
          throw Exception('ZIP文件中没有找到支持的文件格式');
        }

        // 导入所有文件
        const format = 'ZIP';
        final importedCount =
            await _databaseService.importNotesFromText(fileNames, contents);

        // 保存导入历史
        await _preferencesService.saveImportHistory(
          fileName,
          importedCount,
          format,
        );

        // 重新加载导入历史
        await _loadImportHistory();

        // 显示导入成功对话框
        if (mounted) {
          _showImportSuccessDialog(importedCount);
        }
        return;
      }

      // 读取文件内容
      final fileContent = await file.readAsString();

      // 根据文件类型导入
      var importedCount = 0;
      var format = 'JSON';

      if (fileName.endsWith('.json')) {
        // 导入JSON格式
        format = 'JSON';
        importedCount = await _databaseService.importNotesFromJson(
          fileContent,
          overwriteExisting: _overwriteExisting,
          asNewNotes: _importAsNew,
        );
      } else if (fileName.endsWith('.md') || fileName.endsWith('.markdown')) {
        // 导入Markdown格式
        format = 'Markdown';
        importedCount = await _databaseService
            .importNotesFromMarkdown([fileName], [fileContent]);
      } else if (fileName.endsWith('.txt')) {
        // 导入TXT格式
        format = 'TXT';
        importedCount = await _databaseService
            .importNotesFromText([fileName], [fileContent]);
      } else {
        // 不支持的格式
        throw Exception('不支持的文件格式');
      }

      // 保存导入历史
      await _preferencesService.saveImportHistory(
        fileName,
        importedCount,
        format,
      );

      // 重新加载导入历史
      await _loadImportHistory();

      // 显示导入成功对话框
      if (mounted) {
        _showImportSuccessDialog(importedCount);
      }
    } catch (e) {
      _showErrorDialog('导入失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  // 从云端同步
  Future<void> _syncFromCloud() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // 检查是否已登录
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (!appProvider.isLoggedIn) {
        throw Exception('请先登录账号');
      }

      // 获取云端数据
      await appProvider.syncWithServer();

      // 获取当前笔记数
      final count = await _databaseService.getNotesCount();

      // 保存导入历史
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final cloudSource = 'cloud_sync_${formatter.format(now)}';
      await _preferencesService.saveImportHistory(cloudSource, count, 'CLOUD');

      // 重新加载导入历史
      await _loadImportHistory();

      // 显示同步成功对话框
      if (mounted) {
        _showSuccessDialog('同步成功', '已完成与云端数据同步');
      }
    } catch (e) {
      _showErrorDialog('同步失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  // 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
          if (message.contains('所有文件访问权限'))
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('打开设置'),
            ),
        ],
      ),
    );
  }

  // 显示导出成功对话框
  void _showExportSuccessDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(AppLocalizationsSimple.of(context)?.exportSuccess ?? '导出成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizationsSimple.of(context)?.backupFileExported ??
                  '备份文件已成功导出',
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizationsSimple.of(context)?.fileName ?? '文件名'}: $fileName',
            ),
            const SizedBox(height: 16),
            Text(AppLocalizationsSimple.of(context)?.youCan ?? '您可以：'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.share, size: 16),
                const SizedBox(width: 8),
                Text(
                  AppLocalizationsSimple.of(context)?.shareBackupFile ??
                      '分享备份文件',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.save, size: 16),
                const SizedBox(width: 8),
                Text(
                  AppLocalizationsSimple.of(context)?.saveToDevice ?? '保存到设备',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizationsSimple.of(context)?.close ?? '关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 分享文件
              final file = File(filePath);
              if (file.existsSync()) {
                Share.shareFiles([filePath], text: 'InkRoot-墨鸣笔记备份');
              } else {
                _showErrorDialog(
                  AppLocalizationsSimple.of(context)?.shareFailed ??
                      '分享失败: 文件不存在',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(AppLocalizationsSimple.of(context)?.share ?? '分享'),
          ),
        ],
      ),
    );
  }

  // 显示导入成功对话框
  void _showImportSuccessDialog(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(AppLocalizationsSimple.of(context)?.importSuccess ?? '导入成功'),
        content: Text(
          '${AppLocalizationsSimple.of(context)?.dataImported ?? '成功导入'} $count ${AppLocalizationsSimple.of(context)?.itemsNote ?? '条笔记'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizationsSimple.of(context)?.confirm ?? '确定'),
          ),
        ],
      ),
    );
  }

  // 显示成功对话框
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示导出选择对话框
  Future<String?> _showExportChoiceDialog() async => showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            AppLocalizationsSimple.of(context)?.selectExportMethod ?? '选择导出方式',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizationsSimple.of(context)
                        ?.selectHowToSaveExportedFile ??
                    '请选择要如何保存导出的文件：',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'share'),
              child: const Text('分享文件'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'local'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('保存到本地'),
            ),
          ],
        ),
      );

  // Android优化的文件保存方法
  Future<void> _saveFileWithAndroidOptimization(
    String fileName,
    Uint8List fileBytes,
    int notesCount,
  ) async {
    try {
      // 首先尝试使用FilePicker的saveFile方法（Android SAF）
      if (Platform.isIOS) {
        // iOS使用FilePicker.platform.saveFile
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: fileName,
          bytes: fileBytes,
        );

        if (result != null) {
          _showLocalSaveSuccessDialog(fileName, result);
        } else {
          throw Exception('用户取消保存');
        }
      } else {
        // Android尝试SAF保存
        try {
          final result = await FilePicker.platform.saveFile(
            dialogTitle: '选择保存位置',
            fileName: fileName,
            bytes: fileBytes,
          );

          if (result != null) {
            _showLocalSaveSuccessDialog(fileName, result);
          } else {
            throw Exception('用户取消保存');
          }
        } catch (e) {
          // SAF失败，fallback到应用私有目录
          await _saveToAppPrivateDirectory(fileName, fileBytes);
        }
      }
    } catch (e) {
      // 如果所有本地保存方法都失败，提供分享选项
      final shouldShare = await _showSaveFailedDialog();
      if (shouldShare ?? false) {
        await _shareToFilesApp(fileName, fileBytes);
      }
    }
  }

  // 保存到应用私有目录
  Future<void> _saveToAppPrivateDirectory(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(fileBytes);

      // 验证文件保存成功
      if (!file.existsSync()) {
        throw Exception('文件保存失败');
      }

      // 显示Android保存替代方案对话框
      _showAndroidSaveAlternativeDialog(fileName, filePath);
    } catch (e) {
      throw Exception('保存到应用目录失败: $e');
    }
  }

  // 分享文件到系统文件应用
  Future<void> _shareToFilesApp(String fileName, Uint8List fileBytes) async {
    try {
      // 创建临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);

      // 使用share_plus分享文件
      await Share.shareFiles(
        [tempFile.path],
        subject: 'InkRoot-墨鸣笔记备份',
        text: '墨鸣笔记导出备份：$fileName',
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, '文件已通过分享发送，您可以选择保存到文件管理器');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '分享失败: $e');
      }
    }
  }

  // 显示本地保存成功对话框
  void _showLocalSaveSuccessDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('文件已成功保存到：'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filePath,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('您可以在文件管理器中找到该文件。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示Android保存替代方案对话框
  void _showAndroidSaveAlternativeDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文件已保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件已保存到应用私有目录：$fileName'),
            const SizedBox(height: 16),
            const Text('由于Android系统限制，建议您通过分享将文件保存到可访问的位置。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // 读取文件并分享
              try {
                final file = File(filePath);
                final bytes = await file.readAsBytes();
                await _shareToFilesApp(fileName, Uint8List.fromList(bytes));
              } catch (e) {
                SnackBarUtils.showError(context, '分享失败: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('立即分享'),
          ),
        ],
      ),
    );
  }

  // 显示保存失败对话框
  Future<bool?> _showSaveFailedDialog() async => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('本地保存失败'),
          content: const Text('无法将文件保存到本地存储。是否改用分享方式，您可以通过分享选择保存位置？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('分享保存'),
            ),
          ],
        ),
      );
}
