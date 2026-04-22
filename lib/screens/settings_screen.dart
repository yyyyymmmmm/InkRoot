import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/screens/account_info_screen.dart';
import 'package:inkroot/screens/server_info_screen.dart';
import 'package:inkroot/screens/preferences_screen.dart';
import 'package:inkroot/screens/ai_settings_screen.dart';
import 'package:inkroot/screens/webdav_settings_screen.dart';
import 'package:inkroot/screens/import_export_main_screen.dart';
import 'package:inkroot/screens/data_cleanup_screen.dart';
import 'package:inkroot/screens/laboratory_screen.dart';
import 'package:inkroot/screens/feedback_screen.dart';
import 'package:inkroot/screens/help_screen.dart';
import 'package:inkroot/screens/about_screen.dart';

enum SettingsPage {
  none,
  accountInfo,
  serverInfo,
  preferences,
  aiSettings,
  webdavSync,
  importExport,
  dataCleanup,
  laboratory,
  feedback,
  help,
  about,
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsPage _selectedPage = SettingsPage.none;
  double _menuWidth = 240; // 左侧菜单宽度（可拖动调整）

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final l10n = AppLocalizationsSimple.of(context);
    
    // 桌面端（macOS和Windows）使用Master-Detail布局
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    if (isDesktop) {
      // macOS: Master-Detail布局
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // 左侧可调整宽度的菜单栏
            Container(
              width: _menuWidth,
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkCardColor : const Color(0xFFF5F5F5),
              ),
              child: Column(
                children: [
                  // 标题栏
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => context.go('/'),
                          color: textColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.settings ?? '设置',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 菜单列表
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.account_circle,
                          title: l10n?.accountInfo ?? '账户信息',
                          isSelected: _selectedPage == SettingsPage.accountInfo,
                          onTap: () => setState(() => _selectedPage = SettingsPage.accountInfo),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.cloud,
                          title: l10n?.serverUrl ?? '服务器连接',
                          isSelected: _selectedPage == SettingsPage.serverInfo,
                          onTap: () => setState(() => _selectedPage = SettingsPage.serverInfo),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.settings,
                          title: l10n?.preferences ?? '偏好设置',
                          isSelected: _selectedPage == SettingsPage.preferences,
                          onTap: () => setState(() => _selectedPage = SettingsPage.preferences),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.psychology,
                          title: l10n?.aiSettings ?? 'AI 助手',
                          isSelected: _selectedPage == SettingsPage.aiSettings,
                          onTap: () => setState(() => _selectedPage = SettingsPage.aiSettings),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.cloud_sync,
                          title: l10n?.webdavSync ?? 'WebDAV 同步',
                          isSelected: _selectedPage == SettingsPage.webdavSync,
                          onTap: () => setState(() => _selectedPage = SettingsPage.webdavSync),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.import_export,
                          title: l10n?.importExport ?? '导入导出',
                          isSelected: _selectedPage == SettingsPage.importExport,
                          onTap: () => setState(() => _selectedPage = SettingsPage.importExport),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.cleaning_services,
                          title: l10n?.dataCleanup ?? '数据清理',
                          isSelected: _selectedPage == SettingsPage.dataCleanup,
                          onTap: () => setState(() => _selectedPage = SettingsPage.dataCleanup),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.science,
                          title: l10n?.laboratory ?? '实验室',
                          isSelected: _selectedPage == SettingsPage.laboratory,
                          onTap: () => setState(() => _selectedPage = SettingsPage.laboratory),
                        ),
                        const Divider(height: 16),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.feedback_rounded,
                          title: l10n?.feedback ?? '意见反馈',
                          isSelected: _selectedPage == SettingsPage.feedback,
                          onTap: () => setState(() => _selectedPage = SettingsPage.feedback),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.help,
                          title: l10n?.help ?? '帮助',
                          isSelected: _selectedPage == SettingsPage.help,
                          onTap: () => setState(() => _selectedPage = SettingsPage.help),
                        ),
                        _buildMasterMenuItem(
                          context,
                          icon: Icons.info,
                          title: l10n?.about ?? '关于',
                          isSelected: _selectedPage == SettingsPage.about,
                          onTap: () => setState(() => _selectedPage = SettingsPage.about),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 可拖动的分隔条
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _menuWidth = (_menuWidth + details.delta.dx).clamp(180.0, 320.0);
                  });
                },
                child: Container(
                  width: 1,
                  color: isDarkMode ? AppTheme.darkDividerColor : const Color(0xFFE0E0E0),
                ),
              ),
            ),
            // 右侧内容区域
            Expanded(
              child: _buildDetailContent(context),
            ),
          ],
        ),
      );
    }

    // 移动端: 原有的列表布局
    final double maxWidth = ResponsiveUtils.getMaxContentWidth(context);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : null,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.settings ?? '设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: ListView(
            children: [
              // 顶部标语
              Container(
                padding: ResponsiveUtils.responsivePadding(
                  context,
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            l10n?.waitPatiently ?? '静待沉淀',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                26,
                              ),
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveUtils.responsiveSpacing(context, 12),
                        ),
                        Flexible(
                          child: Text(
                            l10n?.poiseToResound ?? '蓄势鸣响',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                26,
                              ),
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppTheme.primaryLightColor
                                  : AppTheme.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(context, 8),
                    ),
                    Text(
                      l10n?.focusAndAccumulate ?? '你的每一次落笔，都是未来成长的根源！',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.responsiveFontSize(context, 16),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 设置项列表
              _buildSettingsItem(
                context,
                icon: Icons.account_circle,
                title: l10n?.accountInfo ?? '账户信息',
                onTap: () => context.push('/account-info'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.cloud,
                title: l10n?.serverUrl ?? '服务器连接',
                onTap: () => context.push('/server-info'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.settings,
                title: l10n?.preferences ?? '偏好设置',
                onTap: () => context.push('/preferences'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.psychology,
                title: l10n?.aiSettings ?? 'AI 助手',
                onTap: () => context.push('/ai-settings'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.cloud_sync,
                title: AppLocalizationsSimple.of(context)?.webdavSync ??
                    'WebDAV Sync',
                onTap: () => context.push('/webdav-settings'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.import_export,
                title: l10n?.importExport ?? '导入导出',
                onTap: () => context.push('/settings/import-export'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.cleaning_services,
                title: l10n?.dataCleanup ?? '数据清理',
                onTap: () => context.push('/data-cleanup'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.science,
                title: l10n?.laboratory ?? '实验室',
                onTap: () => context.push('/laboratory'),
              ),
              // 分隔线
              Container(
                height: 8,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                margin: ResponsiveUtils.responsivePadding(context, vertical: 8),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.feedback_rounded,
                title: l10n?.feedback ?? '意见反馈',
                onTap: () => context.push('/feedback'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.help,
                title: l10n?.help ?? '帮助',
                onTap: () => context.push('/settings/help'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.info,
                title: l10n?.about ?? '关于',
                onTap: () => context.push('/settings/about'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建右侧详情内容
  Widget _buildDetailContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_selectedPage == SettingsPage.none) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 80,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                '请从左侧选择设置项',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 根据选中的页面，直接显示对应的设置页面内容
    // 使用Navigator包装，这样子页面可以有自己的导航
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _getPageContent(),
        );
      },
    );
  }
  
  // 获取对应页面的内容
  Widget _getPageContent() {
    // 直接返回对应的设置页面Widget
    switch (_selectedPage) {
      case SettingsPage.accountInfo:
        return const AccountInfoScreen();
      case SettingsPage.serverInfo:
        return const ServerInfoScreen();
      case SettingsPage.preferences:
        return const PreferencesScreen();
      case SettingsPage.aiSettings:
        return const AiSettingsScreen();
      case SettingsPage.webdavSync:
        return const WebDavSettingsScreen();
      case SettingsPage.importExport:
        return const ImportExportMainScreen();
      case SettingsPage.dataCleanup:
        return const DataCleanupScreen();
      case SettingsPage.laboratory:
        return const LaboratoryScreen();
      case SettingsPage.feedback:
        return const FeedbackScreen();
      case SettingsPage.help:
        return const HelpScreen();
      case SettingsPage.about:
        return const AboutScreen();
      default:
        return _buildPlaceholderContent();
    }
  }
  
  // 占位内容
  Widget _buildPlaceholderContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String pageTitle = '';
    String route = '';
    
    switch (_selectedPage) {
      case SettingsPage.importExport:
        pageTitle = '导入导出';
        route = '/settings/import-export';
        break;
      case SettingsPage.dataCleanup:
        pageTitle = '数据清理';
        route = '/data-cleanup';
        break;
      case SettingsPage.laboratory:
        pageTitle = '实验室';
        route = '/laboratory';
        break;
      case SettingsPage.feedback:
        pageTitle = '意见反馈';
        route = '/feedback';
        break;
      case SettingsPage.help:
        pageTitle = '帮助';
        route = '/settings/help';
        break;
      case SettingsPage.about:
        pageTitle = '关于';
        route = '/settings/about';
        break;
      default:
        pageTitle = '未知页面';
        break;
    }
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
      body: Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 60,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                '$pageTitle - 页面开发中',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor,
                ),
              ),
              if (route.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push(route),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('在新窗口打开'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // macOS Master菜单项
  Widget _buildMasterMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final selectedColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? selectedColor.withOpacity(0.15) : selectedColor.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? selectedColor : textColor.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? selectedColor : textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : null;
    final arrowColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final bool isMacOS = !kIsWeb && Platform.isMacOS;

    final content = Row(
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.responsiveIconSize(context, 24),
          color: iconColor,
        ),
        SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                  color: textColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, 12),
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: arrowColor,
          size: ResponsiveUtils.responsiveIconSize(context, 20),
        ),
      ],
    );

    if (isMacOS) {
      // macOS: 使用卡片样式
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: content,
          ),
        ),
      );
    } else {
      // 移动端: 使用列表样式
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: ResponsiveUtils.responsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
          ),
          child: content,
        ),
      );
    }
  }
}
