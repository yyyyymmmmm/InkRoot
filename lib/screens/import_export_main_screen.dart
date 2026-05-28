import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// 导入导出主页面
/// 提供各种导入导出功能的入口
class ImportExportMainScreen extends StatelessWidget {
  const ImportExportMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizationsSimple.of(context)?.importExport ?? '导入导出',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 本地备份与恢复
          _buildOptionCard(
            context: context,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            icon: Icons.backup_rounded,
            title: AppLocalizationsSimple.of(context)?.localBackupRestore ?? '本地备份与恢复',
            description: AppLocalizationsSimple.of(context)?.localBackupDescription ?? '备份数据到本地文件，或从本地文件恢复数据',
            onTap: () {
              context.push('/settings/local-backup-restore');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Flomo 导入
          _buildOptionCard(
            context: context,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            icon: Icons.file_download_rounded,
            title: AppLocalizationsSimple.of(context)?.flomoImport ?? 'Flomo 笔记导入',
            description: AppLocalizationsSimple.of(context)?.flomoImportDescription ?? '从 Flomo 导出的 HTML 文件导入笔记',
            onTap: () {
              context.push('/settings/flomo-import');
            },
          ),
          
          const SizedBox(height: 16),
          
          // 微信读书笔记导入
          _buildOptionCard(
            context: context,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            icon: Icons.menu_book_rounded,
            title: AppLocalizationsSimple.of(context)?.wereadImportTitle ?? '微信读书笔记导入',
            description: AppLocalizationsSimple.of(context)?.wereadImportDescription ?? '支持从微信读书导出的笔记文本批量导入，自动识别书籍信息和标注内容',
            onTap: () {
              context.push('/settings/weread-import');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Notion 同步
          _buildOptionCard(
            context: context,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            icon: Icons.sync_rounded,
            title: AppLocalizationsSimple.of(context)?.notionSync ?? 'Notion 同步',
            description: AppLocalizationsSimple.of(context)?.notionSyncDescription ?? '将笔记同步到 Notion，支持双向同步和自动同步',
            onTap: () {
              context.push('/settings/notion-settings');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Obsidian 同步
          _buildOptionCard(
            context: context,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            icon: Icons.description_rounded,
            title: AppLocalizationsSimple.of(context)?.obsidianSync ?? 'Obsidian 数据同步',
            description: AppLocalizationsSimple.of(context)?.obsidianSyncDescription ?? '通过第三方插件实现与 Obsidian 笔记应用的双向同步，支持每日笔记自动集成',
            onTap: () async {
              final url = Uri.parse('https://github.com/RyoJerryYu/obsidian-memos-sync');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // 浏览器插件
          _buildOptionCard(
            context: context,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            icon: Icons.extension_rounded,
            title: AppLocalizationsSimple.of(context)?.browserExtension ?? 'Memos 浏览器扩展',
            description: AppLocalizationsSimple.of(context)?.browserExtensionDescription ?? '第三方浏览器扩展程序，支持 Chrome/Edge，可快速收集网页内容至 Memos',
            onTap: () async {
              final url = Uri.parse('https://github.com/lmm214/memos-bber/releases/tag/2023.09.19');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // 提示信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.backupTip ?? '💡 提示：建议定期备份数据，以防数据丢失。导入数据前请仔细检查文件格式。',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
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

  Widget _buildOptionCard({
    required BuildContext context,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}






