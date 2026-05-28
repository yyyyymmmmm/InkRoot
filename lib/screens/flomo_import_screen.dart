import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:inkroot/providers/app_provider.dart';

/// 🔥 重复处理模式
enum DuplicateHandleMode {
  autoSkip,   // 自动跳过重复
  askMe,      // 询问我
  importAll,  // 全部导入
}

/// 🔥 重复类型
enum DuplicateType {
  exact,      // 精确匹配（内容和时间都相同）
  contentOnly, // 仅内容相同
}

/// 🔥 重复笔记信息
class DuplicateInfo {
  final Map<String, dynamic> newNote; // 待导入的笔记
  final Note existingNote;            // 已存在的笔记
  final DuplicateType type;           // 重复类型
  bool shouldImport;                  // 是否应该导入

  DuplicateInfo({
    required this.newNote,
    required this.existingNote,
    required this.type,
    this.shouldImport = false,
  });
}

/// Flomo 笔记导入页面
/// 支持从 Flomo 导出的 HTML 文件导入笔记
class FlomoImportScreen extends StatefulWidget {
  const FlomoImportScreen({super.key});

  @override
  State<FlomoImportScreen> createState() => _FlomoImportScreenState();
}

class _FlomoImportScreenState extends State<FlomoImportScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();
  
  bool _isImporting = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _selectedDirPath; // 选择的目录路径
  int _previewNoteCount = 0;
  List<Map<String, dynamic>> _previewNotes = [];
  
  // 导入选项
  bool _preserveTags = true;
  bool _preserveTime = true;
  bool _importAsNew = true;
  bool _importImages = true; // 是否导入图片
  
  // 🔥 重复检测选项
  bool _enableDuplicateCheck = true; // 是否启用重复检测
  DuplicateHandleMode _duplicateMode = DuplicateHandleMode.askMe; // 重复处理模式
  
  // 图片验证状态
  int _totalImageCount = 0; // HTML中检测到的图片总数
  int _existingImageCount = 0; // 实际存在的图片数
  bool _hasCheckedImages = false; // 是否已检查图片
  
  // 🔥 重复检测结果
  List<DuplicateInfo> _duplicates = []; // 检测到的重复笔记
  int _skippedCount = 0; // 跳过的重复笔记数

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizationsSimple.of(context)?.flomoNoteImport ?? 'Flomo 笔记导入',
          style: TextStyle(color: textColor),
        ),
        elevation: 0,
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : null),
      ),
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 说明卡片
          _buildInfoCard(isDarkMode, cardColor, textColor),

          const SizedBox(height: 16),

          // 选择文件卡片
          _buildFileSelectionCard(isDarkMode, cardColor, textColor, iconColor),

          const SizedBox(height: 16),

          // 导入选项
          if (_selectedFilePath != null) ...[
            _buildImportOptionsCard(isDarkMode, cardColor, textColor),
            const SizedBox(height: 16),
          ],

          // 图片状态警告卡片
          if (_hasCheckedImages && _totalImageCount > 0 && _existingImageCount < _totalImageCount) ...[
            _buildImageWarningCard(isDarkMode, cardColor),
            const SizedBox(height: 16),
          ],

          // 预览卡片
          if (_previewNotes.isNotEmpty) ...[
            _buildPreviewCard(isDarkMode, cardColor, textColor),
            const SizedBox(height: 16),
          ],

          // 导入按钮
          if (_selectedFilePath != null)
            _buildImportButton(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode, Color cardColor, Color textColor) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDarkMode
                      ? AppTheme.primaryLightColor
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizationsSimple.of(context)?.importInstructions ?? '导入说明',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${AppLocalizationsSimple.of(context)?.flomoImportStep1 ?? '1. 在 Flomo 应用中，进入"设置 > 账号详情 > 导出所有数据"'}\n'
              '${AppLocalizationsSimple.of(context)?.flomoImportStep2 ?? '2. 导出后会得到一个包含 HTML 文件和 file 目录的文件夹'}\n'
              '${Platform.isIOS ? '3. 📁 解压导出的ZIP文件到"文件"App中（必须包含完整的file目录）' : (AppLocalizationsSimple.of(context)?.flomoImportStep3 ?? '3. 📁 将整个导出文件夹保存到"文件"App中（iCloud Drive或本地）')}\n'
              '${Platform.isIOS ? '4. 点击下方按钮，选择解压后的HTML文件（图片会自动从同目录的file文件夹读取）' : (AppLocalizationsSimple.of(context)?.flomoImportStep4 ?? '4. 点击下方"选择Flomo导出文件夹"按钮')}\n'
              '${AppLocalizationsSimple.of(context)?.flomoImportStep5 ?? '5. 标签会自动识别（以 # 开头的文本）'}',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            // iOS 特别提示
            if (Platform.isIOS) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '📱 iOS重要提示',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ iOS图片导入限制说明：\n\n'
                      '🔒 iOS沙盒限制（系统安全机制）：\n'
                      '当您选择HTML文件时，系统只授权访问该文件，\n'
                      '无法访问同级的file文件夹（即使它们在同一目录）\n\n'
                      '✅ 推荐方案：关闭"导入图片"开关\n'
                      '• 笔记文本、标签、时间全部保留\n'
                      '• 导入速度快、不会出错\n'
                      '• 大厂App（印象笔记等）也是优先导入文本\n\n'
                      '💡 如需图片：\n'
                      '1. 在Flomo中重新导出（选择"包含图片URL"）\n'
                      '2. 或导入后手动添加重要图片\n\n'
                      '📱 技术原因：\n'
                      'iOS的UIDocumentPicker只能访问用户明确选择的文件，\n'
                      '这是苹果的安全设计，所有第三方App都有此限制',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizationsSimple.of(context)?.flomoExportWarning ?? 'Flomo 每 7 天只能导出一次，请妥善保管导出的文件',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 12,
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
  }

  Widget _buildFileSelectionCard(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color iconColor,
  ) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizationsSimple.of(context)?.selectFile ?? '选择文件',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFilePath == null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _selectFolder,
                  icon: Icon(Platform.isIOS ? Icons.insert_drive_file : Icons.folder_open),
                  label: Text(
                    Platform.isIOS 
                      ? (AppLocalizationsSimple.of(context)?.selectFlomoHtmlFile ?? '选择 Flomo HTML 文件')
                      : (AppLocalizationsSimple.of(context)?.selectFlomoExportFolder ?? '选择 Flomo 导出文件夹')
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (_previewNoteCount > 0)
                            Text(
                              '预计导入 $_previewNoteCount 条笔记',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          if (_hasCheckedImages && _totalImageCount > 0)
                            Text(
                              '包含 $_totalImageCount 张图片${_existingImageCount < _totalImageCount ? ' (⚠️ ${_totalImageCount - _existingImageCount} 张缺失)' : ' ✓'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _existingImageCount < _totalImageCount
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                                fontWeight: _existingImageCount < _totalImageCount
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilePath = null;
                          _selectedFileName = null;
                          _previewNoteCount = 0;
                          _previewNotes.clear();
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWarningCard(bool isDarkMode, Color cardColor) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizationsSimple.of(context)?.imageFileMissing ?? '图片文件缺失',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image_not_supported, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '检测到 $_totalImageCount 张图片，但只找到 $_existingImageCount 张',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizationsSimple.of(context)?.possibleReasons ?? '可能原因：'}\n'
                    '${AppLocalizationsSimple.of(context)?.htmlAndFileSeparated ?? '• HTML文件和file目录不在同一位置'}\n'
                    '${AppLocalizationsSimple.of(context)?.fileFolderMoved ?? '• file目录被移动或删除'}\n'
                    '${AppLocalizationsSimple.of(context)?.exportDataIncomplete ?? '• 导出数据不完整'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizationsSimple.of(context)?.solutionTip ?? '💡 解决方法：'}\n'
                    '${AppLocalizationsSimple.of(context)?.ensureHtmlAndFile ?? '1. 确保Flomo导出的HTML文件和file目录在同一文件夹中'}\n'
                    '${AppLocalizationsSimple.of(context)?.reselectFolder ?? '2. 重新点击"选择Flomo导出文件夹"，选择包含HTML和file目录的整个文件夹'}\n'
                    '${AppLocalizationsSimple.of(context)?.doNotMoveFiles ?? '3. 不要单独移动HTML文件或file目录'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
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

  Widget _buildImportOptionsCard(
    bool isDarkMode,
    Color cardColor,
    Color textColor,
  ) {
    return Card(
      elevation: 1,
      color: cardColor,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchOption(
              title: AppLocalizationsSimple.of(context)?.preserveTags ?? '保留标签',
              subtitle: AppLocalizationsSimple.of(context)?.preserveTagsDesc ?? '将 Flomo 中的 # 标签导入为笔记标签',
              value: _preserveTags,
              onChanged: (value) {
                setState(() {
                  _preserveTags = value;
                });
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildSwitchOption(
              title: AppLocalizationsSimple.of(context)?.preserveTime ?? '保留时间',
              subtitle: AppLocalizationsSimple.of(context)?.preserveTimeDesc ?? '尽可能保留笔记的创建时间',
              value: _preserveTime,
              onChanged: (value) {
                setState(() {
                  _preserveTime = value;
                });
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildSwitchOption(
              title: AppLocalizationsSimple.of(context)?.importAsNew ?? '作为新笔记导入',
              subtitle: AppLocalizationsSimple.of(context)?.importAsNewDesc ?? '所有导入的笔记将作为新笔记添加',
              value: _importAsNew,
              onChanged: (value) {
                setState(() {
                  _importAsNew = value;
                });
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildSwitchOption(
              title: AppLocalizationsSimple.of(context)?.importImages ?? '导入图片',
              subtitle: AppLocalizationsSimple.of(context)?.importImagesDesc ?? '导入笔记中的图片附件（图片会被复制到本地存储）',
              value: _importImages,
              onChanged: (value) {
                setState(() {
                  _importImages = value;
                });
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // 🔥 重复检测选项
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizationsSimple.of(context)?.smartDeduplication ?? '智能去重',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSwitchOption(
              title: AppLocalizationsSimple.of(context)?.detectDuplicates ?? '检测重复笔记',
              subtitle: AppLocalizationsSimple.of(context)?.detectDuplicatesDesc ?? '基于内容和时间智能识别重复笔记',
              value: _enableDuplicateCheck,
              onChanged: (value) {
                setState(() {
                  _enableDuplicateCheck = value;
                });
              },
              isDarkMode: isDarkMode,
            ),
            if (_enableDuplicateCheck) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizationsSimple.of(context)?.whenDuplicatesFound ?? '发现重复笔记时：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildRadioOption(
                title: AppLocalizationsSimple.of(context)?.autoSkip ?? '自动跳过',
                subtitle: AppLocalizationsSimple.of(context)?.autoSkipDesc ?? '静默跳过所有重复笔记',
                value: DuplicateHandleMode.autoSkip,
                groupValue: _duplicateMode,
                onChanged: (value) {
                  setState(() {
                    _duplicateMode = value!;
                  });
                },
                isDarkMode: isDarkMode,
              ),
              _buildRadioOption(
                title: AppLocalizationsSimple.of(context)?.askMe ?? '询问我',
                subtitle: AppLocalizationsSimple.of(context)?.askMeDesc ?? '让我选择要导入哪些重复笔记（推荐）',
                value: DuplicateHandleMode.askMe,
                groupValue: _duplicateMode,
                onChanged: (value) {
                  setState(() {
                    _duplicateMode = value!;
                  });
                },
                isDarkMode: isDarkMode,
              ),
              _buildRadioOption(
                title: AppLocalizationsSimple.of(context)?.importAll ?? '全部导入',
                subtitle: AppLocalizationsSimple.of(context)?.importAllDesc ?? '忽略重复检测，全部作为新笔记导入',
                value: DuplicateHandleMode.importAll,
                groupValue: _duplicateMode,
                onChanged: (value) {
                  setState(() {
                    _duplicateMode = value!;
                  });
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(bool isDarkMode, Color cardColor, Color textColor) {
    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizationsSimple.of(context)?.notePreview ?? '笔记预览（前5条）',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _previewNotes.length > 5 ? 5 : _previewNotes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final note = _previewNotes[index];
                final content = note['content'] as String;
                final tags = note['tags'] as List<String>;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.length > 100
                            ? '${content.substring(0, 100)}...'
                            : content,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: tags.map((tag) {
                            return Chip(
                              label: Text(
                                '#$tag',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(bool isDarkMode) {
    return ElevatedButton(
      onPressed: _isImporting ? null : _startImport,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode
            ? AppTheme.primaryLightColor
            : AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isImporting
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
                Text(AppLocalizationsSimple.of(context)?.importing ?? '导入中...'),
              ],
            )
          : Text(AppLocalizationsSimple.of(context)?.startImport ?? '开始导入'),
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    return Row(
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
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
  }

  // 🔥 构建单选选项
  Widget _buildRadioOption<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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

  // 选择文件夹（新方法）
  Future<void> _selectFolder() async {
    try {
      debugPrint('📂 [FlomoImport] 开始选择文件夹');
      debugPrint('📂 [FlomoImport] 平台: ${Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : "其他"}');
      
      // 🔥 iOS 不支持文件夹选择，使用文件选择
      if (Platform.isIOS) {
        debugPrint('📂 [FlomoImport] iOS平台，使用文件选择');
        await _selectFile();
        return;
      }
      
      // Android/Desktop: 使用目录选择器
      debugPrint('📂 [FlomoImport] 调用文件夹选择器');
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      
      debugPrint('📂 [FlomoImport] 选择结果: ${directoryPath ?? "用户取消"}');
      
      if (directoryPath == null) {
        debugPrint('📂 [FlomoImport] 用户取消选择');
        return;
      }

      debugPrint('📂 [FlomoImport] 选择的路径: $directoryPath');
      final directory = Directory(directoryPath);
      
      if (!await directory.exists()) {
        if (mounted) {
          SnackBarUtils.showError(context, AppLocalizationsSimple.of(context)?.dirNotExist ?? '目录不存在');
        }
        return;
      }

      // 在目录中查找HTML文件（支持递归查找）
      debugPrint('🔍 [FlomoImport] 开始扫描文件夹: $directoryPath');
      
      List<FileSystemEntity> files = [];
      try {
        files = await directory.list(recursive: true, followLinks: false).toList();
        debugPrint('🔍 [FlomoImport] 文件夹中共有 ${files.length} 个项目（包含子文件夹）');
      } catch (e) {
        debugPrint('❌ [FlomoImport] 扫描文件夹失败: $e');
        if (mounted) {
          SnackBarUtils.showError(context, '扫描文件夹失败: $e');
        }
        return;
      }
      
      File? htmlFile;
      
      for (final entity in files) {
        debugPrint('🔍 [FlomoImport] 检查项目: ${entity.path}');
        debugPrint('🔍 [FlomoImport] 项目类型: ${entity is File ? "文件" : entity is Directory ? "文件夹" : "未知"}');
        
        if (entity is File) {
          final fileName = path.basename(entity.path);
          debugPrint('🔍 [FlomoImport] 文件名: $fileName');
          debugPrint('🔍 [FlomoImport] 小写文件名: ${fileName.toLowerCase()}');
          debugPrint('🔍 [FlomoImport] 是否以.html结尾: ${fileName.toLowerCase().endsWith('.html')}');
          debugPrint('🔍 [FlomoImport] 是否以.htm结尾: ${fileName.toLowerCase().endsWith('.htm')}');
          
          if (fileName.toLowerCase().endsWith('.html') || 
              fileName.toLowerCase().endsWith('.htm')) {
            htmlFile = entity;
            debugPrint('✅ [FlomoImport] 找到HTML文件: $fileName');
            debugPrint('✅ [FlomoImport] HTML文件完整路径: ${entity.path}');
            break;
          }
        }
      }

      if (htmlFile == null) {
        debugPrint('❌ [FlomoImport] 未找到HTML文件！');
        debugPrint('❌ [FlomoImport] 扫描的文件列表:');
        for (final entity in files) {
          debugPrint('   - ${path.basename(entity.path)} (${entity is File ? "文件" : "文件夹"})');
        }
        
        if (mounted) {
          // 提示用户可以直接选择HTML文件
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('未找到HTML文件'),
              content: const Text(
                '在选择的文件夹中未找到HTML文件。\n\n'
                '这可能是Android文件访问权限问题。\n\n'
                '建议：请直接选择HTML文件而不是文件夹。'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _selectFile(); // 直接选择文件
                  },
                  child: const Text('选择HTML文件'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      debugPrint('✅ [FlomoImport] 成功选择HTML文件: ${htmlFile.path}');

      setState(() {
        _selectedDirPath = directoryPath;
        _selectedFilePath = htmlFile!.path;
        _selectedFileName = path.basename(htmlFile.path);
        // 重置图片验证状态
        _totalImageCount = 0;
        _existingImageCount = 0;
        _hasCheckedImages = false;
      });

      // 预览文件
      await _previewFile(htmlFile);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.selectFolderFailed ?? '选择文件夹失败'}: $e');
      }
    }
  }

  // 选择文件（保留作为备用方案）
  Future<void> _selectFile() async {
    try {
      // 🎯 iOS: 允许访问父文件夹（大厂标准做法）
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
        allowMultiple: false,
        withData: false, // 不加载文件内容到内存
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = File(result.files.first.path!);
      
      if (!file.existsSync()) {
        if (mounted) {
          SnackBarUtils.showError(context, AppLocalizationsSimple.of(context)?.fileNotExist ?? '文件不存在');
        }
        return;
      }

      setState(() {
        _selectedFilePath = file.path;
        _selectedFileName = file.path.split(Platform.pathSeparator).last;
        // 🔥 设置为文件所在目录，以便查找图片
        _selectedDirPath = path.dirname(file.path);
        // 重置图片验证状态
        _totalImageCount = 0;
        _existingImageCount = 0;
        _hasCheckedImages = false;
      });

      // 预览文件
      await _previewFile(file);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.selectFileFailed ?? '选择文件失败'}: $e');
      }
    }
  }

  // 预览文件
  Future<void> _previewFile(File file) async {
    try {
      final content = await file.readAsString();
      final notes = _parseFlomoHtml(content);
      
      // 验证图片文件是否存在
      await _validateImages(file, notes);
      
      setState(() {
        _previewNoteCount = notes.length;
        _previewNotes = notes;
      });

      if (notes.isEmpty) {
        if (mounted) {
          SnackBarUtils.showWarning(context, AppLocalizationsSimple.of(context)?.noValidNotesInFile ?? '文件中没有找到有效的笔记内容');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.previewFileFailed ?? '预览文件失败'}: $e');
      }
    }
  }
  
  // 验证图片文件是否存在
  Future<void> _validateImages(File htmlFile, List<Map<String, dynamic>> notes) async {
    try {
      // 优先使用选择的目录路径，否则使用HTML文件所在目录
      final baseDir = _selectedDirPath ?? path.dirname(htmlFile.path);
      var totalImages = 0;
      var existingImages = 0;
      
      // 🚨 iOS临时目录检测
      final isTempDir = Platform.isIOS && baseDir.contains('/tmp');
      
      if (kDebugMode) {
        debugPrint('📁 图片验证基础目录: $baseDir');
        if (isTempDir) {
          debugPrint('⚠️ 检测到iOS临时目录！图片可能无法访问');
        }
      }
      
      for (final noteData in notes) {
        final imagePaths = noteData['imagePaths'] as List<String>? ?? [];
        totalImages += imagePaths.length;
        
        for (final relativeImagePath in imagePaths) {
          final sourceImagePath = path.join(baseDir, relativeImagePath);
          final sourceImageFile = File(sourceImagePath);
          
          if (await sourceImageFile.exists()) {
            existingImages++;
            if (kDebugMode) {
              debugPrint('✅ 图片文件存在: $sourceImagePath');
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ 图片文件不存在: $sourceImagePath');
            }
          }
        }
      }
      
      setState(() {
        _totalImageCount = totalImages;
        _existingImageCount = existingImages;
        _hasCheckedImages = true;
      });
      
      if (kDebugMode) {
        debugPrint('📊 图片验证结果: 总计 $totalImages 张，找到 $existingImages 张');
      }
      
      // 🚨 iOS临时目录警告
      if (Platform.isIOS && isTempDir && totalImages > 0 && existingImages == 0 && mounted) {
        SnackBarUtils.showError(
          context, 
          '⚠️ 文件在临时目录，无法访问图片！\n'
          '请先将整个Flomo导出文件夹移动到"文件"App中，\n'
          '然后重新选择HTML文件',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 验证图片失败: $e');
      }
    }
  }

  // 解析 Flomo HTML 文件
  List<Map<String, dynamic>> _parseFlomoHtml(String htmlContent) {
    final notes = <Map<String, dynamic>>[];

    try {
      final document = html_parser.parse(htmlContent);
      
      // Flomo 导出的 HTML 结构：
      // <div class="memo">
      //   <div class="time">2025-10-27 11:22:09</div>
      //   <div class="content"><p>内容</p></div>
      //   <div class="files"><img src="file/2025-09-14/xxx.jpg" /></div>
      // </div>
      
      final memoElements = document.querySelectorAll('.memo');
      
      if (memoElements.isEmpty) {
        debugPrint('未找到 .memo 元素，尝试其他选择器');
        return notes;
      }

      for (final memoElement in memoElements) {
        // 提取时间
        DateTime? createdAt;
        if (_preserveTime) {
          final timeElement = memoElement.querySelector('.time');
          if (timeElement != null) {
            final timeText = timeElement.text.trim();
            try {
              // Flomo 时间格式：2025-10-27 11:22:09
              createdAt = DateTime.parse(timeText);
            } catch (e) {
              debugPrint('解析时间失败: $timeText, 错误: $e');
            }
          }
        }

        // 提取内容
        final contentElement = memoElement.querySelector('.content');
        if (contentElement == null) continue;

        // 获取所有 p 标签的文本，用换行连接
        final paragraphs = contentElement.querySelectorAll('p');
        final contentParts = <String>[];
        
        for (final p in paragraphs) {
          final text = p.text.trim();
          if (text.isNotEmpty) {
            contentParts.add(text);
          }
        }
        
        if (contentParts.isEmpty) continue;
        
        final content = contentParts.join('\n');

        // 🖼️ 提取图片路径（相对于HTML文件的路径）
        final imagePaths = <String>[];
        if (_importImages) {
          final filesElement = memoElement.querySelector('.files');
          if (filesElement != null) {
            final imgElements = filesElement.querySelectorAll('img');
            for (final img in imgElements) {
              final src = img.attributes['src'];
              if (src != null && src.isNotEmpty) {
                imagePaths.add(src);
                if (kDebugMode) debugPrint('找到图片: $src');
              }
            }
          }
        }

        // 提取标签（以 # 开头的文本）
        final tags = <String>[];
        if (_preserveTags) {
          // 匹配 #标签 或 #标签/子标签 格式
          // 排除中文标点符号：，。！？；：、""''（）【】《》
          final tagRegex = RegExp(r'#([^\s#，。！？；：、""''（）【】《》\.,!?;:\(\)\[\]<>]+)');
          final matches = tagRegex.allMatches(content);
          
          if (kDebugMode) {
            debugPrint('📝 笔记内容预览: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
            debugPrint('🔍 找到 ${matches.length} 个标签匹配');
          }
          
          for (final match in matches) {
            var tag = match.group(1);
            if (tag != null) {
              // 移除标签末尾可能的标点符号
              tag = tag.replaceAll(RegExp(r'[，。！？；：、""''（）【】《》\.,!?;:\(\)\[\]<>]+\$'), '');
              if (tag.isNotEmpty && !tags.contains(tag)) {
                tags.add(tag);
                if (kDebugMode) debugPrint('  ✅ 提取标签: #$tag');
              }
            }
          }
          
          if (kDebugMode && tags.isEmpty && content.contains('#')) {
            debugPrint('  ⚠️ 内容包含#但未提取到标签');
          }
        }

        // 从内容中移除标签行（如果整行只有标签）
        var cleanContent = content;
        if (_preserveTags && tags.isNotEmpty) {
          // 如果某一行只包含标签，可以选择移除
          final lines = cleanContent.split('\n');
          final cleanLines = lines.where((line) {
            final trimmed = line.trim();
            // 保留不是纯标签的行
            return !RegExp(r'^#[^\s#]+(\s+#[^\s#]+)*$').hasMatch(trimmed);
          }).toList();
          
          if (cleanLines.isNotEmpty) {
            cleanContent = cleanLines.join('\n');
          }
        }

        // 如果清理后内容为空，使用原内容
        if (cleanContent.trim().isEmpty) {
          cleanContent = content;
        }

        notes.add({
          'content': cleanContent.trim(),
          'tags': tags,
          'createdAt': createdAt,
          'imagePaths': imagePaths, // 添加图片路径列表
        });
      }
    } catch (e) {
      debugPrint('解析 Flomo HTML 失败: $e');
    }

    return notes;
  }

  // 开始导入
  Future<void> _startImport() async {
    if (_selectedFilePath == null) {
      SnackBarUtils.showError(context, AppLocalizationsSimple.of(context)?.pleaseSelectFileFirst ?? '请先选择文件');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final file = File(_selectedFilePath!);
      final content = await file.readAsString();
      final notes = _parseFlomoHtml(content);

      if (notes.isEmpty) {
        throw Exception(AppLocalizationsSimple.of(context)?.noValidNotesInFile ?? '文件中没有找到有效的笔记内容');
      }

      // 🔥 重复检测
      List<Map<String, dynamic>> notesToImport = notes;
      final skippedDuplicates = <DuplicateInfo>[];

      if (_enableDuplicateCheck && _duplicateMode != DuplicateHandleMode.importAll) {
        if (kDebugMode) {
          debugPrint('🔍 开始重复检测...');
        }

        // 获取现有笔记
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final existingNotes = appProvider.notes;

        // 检测重复
        final duplicates = await _detectDuplicates(notes, existingNotes);

        if (duplicates.isNotEmpty) {
          if (_duplicateMode == DuplicateHandleMode.autoSkip) {
            // 自动跳过所有重复
            skippedDuplicates.addAll(duplicates);
            final duplicateContents = duplicates.map((d) => d.newNote['content'] as String).toSet();
            notesToImport = notes.where((n) => !duplicateContents.contains(n['content'])).toList();
            
            if (kDebugMode) {
              debugPrint('⏭️ 自动跳过 ${duplicates.length} 条重复笔记');
            }
          } else if (_duplicateMode == DuplicateHandleMode.askMe) {
            // 询问用户
            final result = await _showDuplicateDialog(duplicates);
            
            if (result == null) {
              // 用户取消
              throw Exception(AppLocalizationsSimple.of(context)?.userCancelledImport ?? '用户取消导入');
            }

            // 处理用户选择
            final toSkip = result.where((d) => !d.shouldImport).toList();
            final toImport = result.where((d) => d.shouldImport).toList();
            
            skippedDuplicates.addAll(toSkip);
            
            // 过滤要导入的笔记
            final skipContents = toSkip.map((d) => d.newNote['content'] as String).toSet();
            notesToImport = notes.where((n) => !skipContents.contains(n['content'])).toList();
            
            if (kDebugMode) {
              debugPrint('⏭️ 用户选择跳过 ${toSkip.length} 条，导入 ${toImport.length} 条重复笔记');
            }
          }
        }
      }

      // 获取HTML文件所在目录（用于定位图片文件）
      // 优先使用选择的目录路径，否则使用HTML文件所在目录
      final htmlDir = _selectedDirPath ?? path.dirname(_selectedFilePath!);
      
      if (kDebugMode) {
        debugPrint('📁 导入基础目录: $htmlDir');
      }
      
      // 获取应用图片存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 导入笔记
      const uuid = Uuid();
      var importedCount = 0;
      var importedImageCount = 0;
      
      for (final noteData in notesToImport) {
        try {
          final now = DateTime.now();
          final createdAt = noteData['createdAt'] as DateTime? ?? now;
          var noteContent = noteData['content'] as String;
          
          // 🖼️ 处理图片
          final imagePaths = noteData['imagePaths'] as List<String>? ?? [];
          if (imagePaths.isNotEmpty && _importImages) {
            final imageMarkdowns = <String>[];
            
            for (final relativeImagePath in imagePaths) {
              try {
                // 构建源图片的完整路径
                final sourceImagePath = path.join(htmlDir, relativeImagePath);
                final sourceImageFile = File(sourceImagePath);
                
                if (await sourceImageFile.exists()) {
                  // 生成新的图片文件名
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final extension = path.extension(relativeImagePath);
                  final newFileName = 'flomo_${timestamp}_${importedImageCount}$extension';
                  final targetImagePath = path.join(imagesDir.path, newFileName);
                  
                  // 复制图片到应用目录
                  await sourceImageFile.copy(targetImagePath);
                  importedImageCount++;
                  
                  // 生成Markdown图片引用（使用相对路径，避免升级后路径失效）
                  // ⚠️ 重要：不要使用绝对路径，因为iOS应用容器UUID会在每次安装时改变
                  final mdCode = '![图片](images/$newFileName)';
                  imageMarkdowns.add(mdCode);
                  
                  if (kDebugMode) {
                    debugPrint('✅ 成功导入图片: $relativeImagePath -> $newFileName');
                  }
                } else {
                  if (kDebugMode) {
                    debugPrint('⚠️ 图片文件不存在: $sourceImagePath');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ 复制图片失败: $relativeImagePath, 错误: $e');
                }
              }
            }
            
            // 将图片Markdown添加到笔记内容末尾
            if (imageMarkdowns.isNotEmpty) {
              noteContent = '$noteContent\n\n${imageMarkdowns.join('\n')}';
            }
          }
          
          final note = Note(
            id: uuid.v4(),
            content: noteContent,
            createdAt: createdAt,
            updatedAt: createdAt, // 使用原始创建时间作为更新时间，保持时间一致性
            tags: noteData['tags'] as List<String>,
          );
          
          await _databaseService.saveNote(note);
          importedCount++;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('导入笔记失败: $e');
          }
        }
      }

      // 保存导入历史
      await _preferencesService.saveImportHistory(
        _selectedFileName ?? 'flomo_export.html',
        importedCount,
        'Flomo HTML',
      );

      // 🔥 刷新笔记列表（关键！否则主页看不到新笔记）
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.loadNotesFromLocal();
        
        if (kDebugMode) {
          debugPrint('✅ 已刷新笔记列表，主页将显示最新导入的笔记');
        }
      }

      if (mounted) {
        // 显示成功对话框
        final missingImageCount = _totalImageCount - importedImageCount;
        final skippedCount = skippedDuplicates.length;
        
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizationsSimple.of(context)?.importSuccessful ?? '导入成功'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.importedFromFlomo ?? '成功从 Flomo 导入：',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow(Icons.description, '$importedCount 条笔记', Colors.blue),
                if (_importImages && _totalImageCount > 0) ...[
                  const SizedBox(height: 8),
                  _buildStatRow(
                    Icons.image,
                    '$importedImageCount 张图片${_totalImageCount > 0 ? ' (共 $_totalImageCount 张)' : ''}',
                    importedImageCount == _totalImageCount ? Colors.green : Colors.orange,
                  ),
                ],
                // 🔥 重复笔记统计
                if (skippedCount > 0) ...[
                  const SizedBox(height: 8),
                  _buildStatRow(
                    Icons.filter_alt_outlined,
                    '跳过重复 $skippedCount 条',
                    Colors.grey,
                  ),
                ],
                if (missingImageCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$missingImageCount 张图片未找到',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // 🔥 查看重复详情按钮
                if (skippedCount > 0) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSkippedDetailsDialog(skippedDuplicates);
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: Text(AppLocalizationsSimple.of(context)?.viewSkippedDuplicates ?? '查看跳过的重复笔记'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // 返回到上一页
                },
                child: Text(AppLocalizationsSimple.of(context)?.confirm ?? '确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.importFailed ?? '导入失败'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
  
  // 构建统计行组件
  Widget _buildStatRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // 🔥 计算笔记内容哈希（用于重复检测）
  String _calculateContentHash(String content) {
    // 标准化内容：去除首尾空格、统一换行符
    final normalized = content.trim().replaceAll('\r\n', '\n');
    final bytes = utf8.encode(normalized);
    final hash = md5.convert(bytes);
    return hash.toString();
  }

  // 🔥 检测重复笔记
  Future<List<DuplicateInfo>> _detectDuplicates(
    List<Map<String, dynamic>> notesToImport,
    List<Note> existingNotes,
  ) async {
    final duplicates = <DuplicateInfo>[];

    for (final noteData in notesToImport) {
      final content = noteData['content'] as String;
      final createdAt = noteData['createdAt'] as DateTime?;
      final contentHash = _calculateContentHash(content);

      for (final existingNote in existingNotes) {
        final existingHash = _calculateContentHash(existingNote.content);

        // 检测内容是否相同
        if (contentHash == existingHash) {
          DuplicateType type;

          // 检测时间是否也相同
          if (createdAt != null && 
              existingNote.createdAt.difference(createdAt).abs().inSeconds < 60) {
            // 时间差小于1分钟，认为是精确匹配
            type = DuplicateType.exact;
          } else {
            // 仅内容相同
            type = DuplicateType.contentOnly;
          }

          duplicates.add(DuplicateInfo(
            newNote: noteData,
            existingNote: existingNote,
            type: type,
          ));

          break; // 找到重复就跳出内层循环
        }
      }
    }

    if (kDebugMode) {
      debugPrint('🔍 重复检测结果: 发现 ${duplicates.length} 条重复笔记');
      for (final dup in duplicates) {
        final content = dup.newNote['content'].toString();
        final preview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
        debugPrint('  - ${dup.type == DuplicateType.exact ? '精确匹配' : '仅内容相同'}: $preview');
      }
    }

    return duplicates;
  }

  // 🔥 显示重复笔记确认对话框
  Future<List<DuplicateInfo>?> _showDuplicateDialog(
    List<DuplicateInfo> duplicates,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<List<DuplicateInfo>>(
      context: context,
      builder: (context) => _DuplicateConfirmDialog(
        duplicates: duplicates,
        isDarkMode: isDarkMode,
      ),
    );
  }

  // 🔥 显示跳过的重复笔记详情
  void _showSkippedDetailsDialog(List<DuplicateInfo> skipped) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(AppLocalizationsSimple.of(context)?.skippedDuplicates ?? '跳过的重复笔记'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: skipped.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final dup = skipped[index];
              final content = dup.newNote['content'] as String;
              final newTime = dup.newNote['createdAt'] as DateTime?;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dup.type == DuplicateType.exact
                        ? Colors.red.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    dup.type == DuplicateType.exact
                        ? Icons.check_circle_outline
                        : Icons.content_copy,
                    color: dup.type == DuplicateType.exact
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                ),
                title: Text(
                  content.length > 40 ? '${content.substring(0, 40)}...' : content,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      dup.type == DuplicateType.exact ? '精确匹配' : '内容相同',
                      style: TextStyle(
                        fontSize: 12,
                        color: dup.type == DuplicateType.exact
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (newTime != null)
                      Text(
                        '时间: ${DateFormat('yyyy-MM-dd HH:mm').format(newTime)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizationsSimple.of(context)?.close ?? '关闭'),
          ),
        ],
      ),
    );
  }
}

// 🔥 重复笔记确认对话框
class _DuplicateConfirmDialog extends StatefulWidget {
  final List<DuplicateInfo> duplicates;
  final bool isDarkMode;

  const _DuplicateConfirmDialog({
    required this.duplicates,
    required this.isDarkMode,
  });

  @override
  State<_DuplicateConfirmDialog> createState() => _DuplicateConfirmDialogState();
}

class _DuplicateConfirmDialogState extends State<_DuplicateConfirmDialog> {
  late List<DuplicateInfo> _duplicates;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _duplicates = List.from(widget.duplicates);
  }

  @override
  Widget build(BuildContext context) {
    final exactCount = _duplicates.where((d) => d.type == DuplicateType.exact).length;
    final contentOnlyCount = _duplicates.where((d) => d.type == DuplicateType.contentOnly).length;
    final selectedCount = _duplicates.where((d) => d.shouldImport).length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '发现重复笔记',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共 ${_duplicates.length} 条 (精确: $exactCount, 内容相同: $contentOnlyCount)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 说明文字
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '选中的笔记将被导入，未选中的将跳过',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 全选按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CheckboxListTile(
              value: _selectAll,
              onChanged: (value) {
                setState(() {
                  _selectAll = value ?? false;
                  for (final dup in _duplicates) {
                    dup.shouldImport = _selectAll;
                  }
                });
              },
              title: Text(
                _selectAll ? '取消全选' : '全选',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.primaryColor,
            ),
          ),

          const Divider(height: 1),

          // 重复笔记列表
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _duplicates.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
              itemBuilder: (context, index) {
                final dup = _duplicates[index];
                final newContent = dup.newNote['content'] as String;
                final existingContent = dup.existingNote.content;
                final newTime = dup.newNote['createdAt'] as DateTime?;

                return CheckboxListTile(
                  value: dup.shouldImport,
                  onChanged: (value) {
                    setState(() {
                      dup.shouldImport = value ?? false;
                      _selectAll = _duplicates.every((d) => d.shouldImport);
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.primaryColor,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dup.type == DuplicateType.exact
                              ? Colors.red.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dup.type == DuplicateType.exact ? '精确匹配' : '内容相同',
                          style: TextStyle(
                            fontSize: 11,
                            color: dup.type == DuplicateType.exact
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          newContent.length > 30
                              ? '${newContent.substring(0, 30)}...'
                              : newContent,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (newTime != null)
                        Text(
                          '待导入: ${DateFormat('yyyy-MM-dd HH:mm').format(newTime)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      Text(
                        '已存在: ${DateFormat('yyyy-MM-dd HH:mm').format(dup.existingNote.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 底部按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // 全部跳过
                        for (final dup in _duplicates) {
                          dup.shouldImport = false;
                        }
                        Navigator.pop(context, _duplicates);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(AppLocalizationsSimple.of(context)?.skipAll ?? '全部跳过'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _duplicates);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      selectedCount > 0 ? '导入选中 ($selectedCount)' : '确定',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

