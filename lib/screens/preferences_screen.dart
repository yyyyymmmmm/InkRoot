import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/sidebar_customization_screen.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final appConfig = appProvider.appConfig;
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
          l10n?.preferences ?? '偏好设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: ListView(
        children: [
          // 外观设置
          _buildSectionHeader(context, l10n?.appearance ?? '外观'),

          // 主题选择
          _buildThemeSelector(context, appProvider, appConfig),

          SizedBox(height: ResponsiveUtils.fontScaledSpacing(context, 4)),

          // 字体大小选择
          _buildFontSizeSelector(context, appProvider, appConfig),

          SizedBox(height: ResponsiveUtils.fontScaledSpacing(context, 4)),

          // 字体家族选择
          _buildFontFamilySelector(context, appProvider, appConfig),

          SizedBox(height: ResponsiveUtils.fontScaledSpacing(context, 4)),

          // 语言选择
          _buildLanguageSelector(context, appProvider, appConfig),

          SizedBox(height: ResponsiveUtils.fontScaledSpacing(context, 4)),

          // 侧边栏自定义
          _buildSidebarCustomizationSelector(context),

          const Divider(),

          // 同步设置
          _buildSectionHeader(context, l10n?.sync ?? '同步'),

          // 自动同步设置
          _buildSwitchItem(
            context,
            icon: Icons.sync,
            title: l10n?.autoSync ?? '自动同步',
            subtitle: l10n?.autoSyncDesc ?? '定期自动同步笔记',
            value: appConfig.autoSyncEnabled,
            onChanged: (value) => _updateAutoSync(appProvider, value),
          ),

          // 同步间隔设置 (仅当自动同步开启时显示)
          if (appConfig.autoSyncEnabled)
            _buildSyncIntervalSetting(context, appProvider, appConfig),

          const Divider(),

          // 隐私设置
          _buildSectionHeader(context, l10n?.privacy ?? '隐私'),

          // 默认笔记可见性设置 (国际化完成)
          _buildDefaultVisibilitySelector(context, appProvider, appConfig),

          const Divider(),

          // 其他设置
          _buildSectionHeader(context, l10n?.other ?? '其他'),

          // 记住密码设置
          _buildSwitchItem(
            context,
            icon: Icons.save_alt,
            title: l10n?.rememberPassword ?? '记住密码',
            subtitle: l10n?.rememberPasswordDesc ?? '保存账号和密码到本地',
            value: appConfig.rememberLogin,
            onChanged: (value) => _updateRememberLogin(appProvider, value),
          ),

          // 自动登录设置
          _buildSwitchItem(
            context,
            icon: Icons.login,
            title: l10n?.autoLogin ?? '自动登录',
            subtitle: l10n?.autoLoginDesc ?? '启动应用时跳过登录页面直接进入',
            value: appConfig.autoLogin,
            onChanged: (value) => _updateAutoLogin(appProvider, value),
          ),

          // 启动自动弹出编辑框设置
          _buildSwitchItem(
            context,
            icon: Icons.edit_note_rounded,
            title: l10n?.autoShowEditor ?? '启动自动弹出编辑框',
            subtitle: l10n?.autoShowEditorDesc ?? '打开应用时自动弹出笔记编辑框，快速记录灵感',
            value: appConfig.autoShowEditorOnLaunch,
            onChanged: (value) => _updateAutoShowEditor(appProvider, value),
          ),
        ],
      ),
    );
  }

  // 构建字体大小选择器
  Widget _buildFontSizeSelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final l10n = AppLocalizationsSimple.of(context);

    // 获取当前字体大小名称
    String getCurrentFontSizeName() {
      if (appConfig.fontScale == AppConfig.FONT_SCALE_MINI) {
        return l10n?.fontSizeMini ?? '极小';
      } else if (appConfig.fontScale == AppConfig.FONT_SCALE_SMALL) {
        return l10n?.fontSizeSmall ?? '小';
      } else if (appConfig.fontScale == AppConfig.FONT_SCALE_LARGE) {
        return l10n?.fontSizeLarge ?? '大';
      } else if (appConfig.fontScale == AppConfig.FONT_SCALE_XLARGE) {
        return l10n?.fontSizeXLarge ?? '特大';
      } else {
        return l10n?.fontSizeNormal ?? '标准';
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFontSizeSelector(context, appProvider, appConfig),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          child: Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : primaryColorWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.text_fields,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // 标题和当前值
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.fontSize ?? '字体大小',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getCurrentFontSizeName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建主题选择器
  Widget _buildThemeSelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final l10n = AppLocalizationsSimple.of(context);

    // 获取当前主题名称
    String getCurrentThemeName() {
      switch (appConfig.themeSelection) {
        case AppConfig.THEME_SYSTEM:
          return l10n?.themeSystem ?? '跟随系统';
        case AppConfig.THEME_LIGHT:
          return l10n?.themeLight ?? '纸白';
        case AppConfig.THEME_DARK:
          return l10n?.themeDark ?? '幽谷';
        default:
          return l10n?.unknown ?? '未知';
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showThemeSelector(context, appProvider, appConfig),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          child: Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.fontScaledBorderRadius(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : primaryColorWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // 标题和当前值
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.themeSelection ?? '主题选择',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getCurrentThemeName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建下拉项
  DropdownMenuItem<String> _buildDropdownItem(
    String label,
    String value,
    bool isDarkMode,
    Color iconColor,
  ) {
    final selectedColor = isDarkMode ? Colors.white : AppTheme.primaryColor;
    final isSelected =
        value == Provider.of<AppProvider>(context).appConfig.themeSelection;

    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (value == AppConfig.THEME_SYSTEM)
            Icon(
              Icons.brightness_auto,
              size: 20,
              color: isSelected ? iconColor : null,
            )
          else if (value == AppConfig.THEME_LIGHT)
            Icon(
              Icons.wb_sunny_outlined,
              size: 20,
              color: isSelected ? iconColor : null,
            )
          else
            Icon(
              Icons.nights_stay_outlined,
              size: 20,
              color: isSelected ? iconColor : null,
            ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : null,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 构建分区标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // 构建开关设置项
  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : primaryColorWithOpacity,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  // 构建同步间隔设置
  Widget _buildSyncIntervalSetting(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    // 定义可选的同步间隔（分钟）
    final syncIntervals = [5, 15, 30, 60, 120];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 56), // 与图标对齐
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.syncInterval ?? '同步间隔',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: syncIntervals.map((interval) {
                    final isSelected =
                        appConfig.syncInterval == interval * 60; // 转换为秒
                    return ChoiceChip(
                      label: Text('$interval分钟'),
                      selected: isSelected,
                      selectedColor: primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? primaryColor
                            : (isDarkMode ? Colors.grey[300] : Colors.black),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _updateSyncInterval(
                            appProvider,
                            interval * 60,
                          ); // 转换为秒
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 更新主题选择
  Future<void> _updateThemeSelection(
    AppProvider appProvider,
    String value,
  ) async {
    await appProvider.setThemeSelection(value);

    if (mounted) {
      String themeName;
      final l10n = AppLocalizationsSimple.of(context);
      switch (value) {
        case AppConfig.THEME_SYSTEM:
          themeName = l10n?.themeSystem ?? '跟随系统';
          break;
        case AppConfig.THEME_LIGHT:
          themeName = l10n?.themeLight ?? '纸白';
          break;
        case AppConfig.THEME_DARK:
          themeName = l10n?.themeDark ?? '幽谷';
          break;
        default:
          themeName = l10n?.unknown ?? '未知';
      }

      SnackBarUtils.showSuccess(context, '主题已切换为$themeName');
    }
  }

  // 更新自动同步设置
  Future<void> _updateAutoSync(AppProvider appProvider, bool value) async {
    final updatedConfig =
        appProvider.appConfig.copyWith(autoSyncEnabled: value);
    await appProvider.updateConfig(updatedConfig);
    setState(() {});

    // 根据设置启动或停止自动同步
    if (value) {
      appProvider.startAutoSync();
    } else {
      appProvider.stopAutoSync();
    }
  }

  // 更新同步间隔
  Future<void> _updateSyncInterval(AppProvider appProvider, int seconds) async {
    final updatedConfig = appProvider.appConfig.copyWith(syncInterval: seconds);
    await appProvider.updateConfig(updatedConfig);

    // 重启自动同步
    if (updatedConfig.autoSyncEnabled) {
      appProvider.stopAutoSync();
      appProvider.startAutoSync();
    }
  }

  // 更新记住登录设置
  Future<void> _updateRememberLogin(AppProvider appProvider, bool value) async {
    final updatedConfig = appProvider.appConfig.copyWith(rememberLogin: value);
    await appProvider.updateConfig(updatedConfig);

    // 如果关闭记住密码，清除保存的登录信息，并关闭自动登录
    if (!value) {
      final newConfig = appProvider.appConfig.copyWith(
        rememberLogin: false,
        autoLogin: false,
      );
      await appProvider.updateConfig(newConfig);
      await appProvider.clearLoginInfo();
    }
  }

  // 更新自动登录设置
  Future<void> _updateAutoLogin(AppProvider appProvider, bool value) async {
    // 如果要开启自动登录，必须先开启记住密码
    if (value && !appProvider.appConfig.rememberLogin) {
      final newConfig = appProvider.appConfig.copyWith(
        rememberLogin: true,
        autoLogin: value,
      );
      await appProvider.updateConfig(newConfig);

      // 显示提示信息
      if (mounted) {
        SnackBarUtils.showInfo(
          context,
          AppLocalizationsSimple.of(context)?.rememberPasswordEnabled ??
              '已同时开启记住密码功能',
        );
      }
    } else {
      final newConfig = appProvider.appConfig.copyWith(
        autoLogin: value,
      );
      await appProvider.updateConfig(newConfig);
    }
  }

  // 更新启动自动弹出编辑框设置
  Future<void> _updateAutoShowEditor(
    AppProvider appProvider,
    bool value,
  ) async {
    final newConfig = appProvider.appConfig.copyWith(
      autoShowEditorOnLaunch: value,
    );
    await appProvider.updateConfig(newConfig);

    // 显示提示信息
    if (mounted) {
      SnackBarUtils.showSuccess(
        context,
        value
            ? (AppLocalizationsSimple.of(context)?.autoShowEditorEnabled ??
                '已开启启动自动弹出编辑框')
            : (AppLocalizationsSimple.of(context)?.autoShowEditorDisabled ??
                '已关闭启动自动弹出编辑框'),
      );
    }
  }

  // 构建默认笔记可见性选择器
  Widget _buildDefaultVisibilitySelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final l10n = AppLocalizationsSimple.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    // 获取当前状态名称
    String getCurrentVisibilityName() =>
        appConfig.defaultNoteVisibility == AppConfig.VISIBILITY_PRIVATE
            ? (l10n?.private ?? '私有')
            : (l10n?.public ?? '公开');

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVisibilitySelector(context, appProvider, appConfig),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          child: Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.fontScaledBorderRadius(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : primaryColorWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.visibility_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // 标题和当前值
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.noteVisibility ?? '默认笔记状态',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getCurrentVisibilityName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建可见性下拉项
  DropdownMenuItem<String> _buildVisibilityDropdownItem(
    String label,
    String value,
    bool isDarkMode,
    Color iconColor,
  ) {
    final isSelected = value ==
        Provider.of<AppProvider>(context).appConfig.defaultNoteVisibility;
    final selectedColor = isDarkMode ? Colors.white : AppTheme.primaryColor;

    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            value == AppConfig.VISIBILITY_PRIVATE
                ? Icons.lock_outline
                : Icons.public_outlined,
            size: 18,
            color: isSelected
                ? iconColor
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? (isDarkMode
                            ? Colors.white
                            : AppTheme.textPrimaryColor)
                        : null,
                  ),
                ),
                Text(
                  value == AppConfig.VISIBILITY_PRIVATE
                      ? '仅自己可见'
                      : '任何人都可通过链接访问',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 更新默认笔记可见性
  Future<void> _updateDefaultVisibility(
    AppProvider appProvider,
    String visibility,
  ) async {
    final newConfig =
        appProvider.appConfig.copyWith(defaultNoteVisibility: visibility);
    await appProvider.updateConfig(newConfig);
    setState(() {});

    // 显示确认消息
    if (mounted) {
      final visibilityName =
          visibility == AppConfig.VISIBILITY_PRIVATE ? '私有' : '公开';
      SnackBarUtils.showSuccess(context, '默认笔记状态已设置为$visibilityName');
    }
  }

  // 显示iOS风格的主题选择器
  void _showThemeSelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final l10n = AppLocalizationsSimple.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n?.selectTheme ?? '选择主题',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  // 选项列表
                  _buildThemeOption(
                    context,
                    icon: Icons.brightness_auto,
                    title: l10n?.themeSystem ?? '跟随系统',
                    subtitle: l10n?.themeSystemDesc ?? '跟随系统设置',
                    value: AppConfig.THEME_SYSTEM,
                    currentValue: appConfig.themeSelection,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      _updateThemeSelection(
                        appProvider,
                        AppConfig.THEME_SYSTEM,
                      );
                      Navigator.pop(context);
                    },
                  ),

                  Divider(
                    height: 1,
                    color: isDarkMode
                        ? AppTheme.darkDividerColor
                        : AppTheme.dividerColor,
                  ),

                  _buildThemeOption(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    title: l10n?.themeLight ?? '纸白',
                    subtitle: l10n?.themeLightDesc ?? '浅色主题',
                    value: AppConfig.THEME_LIGHT,
                    currentValue: appConfig.themeSelection,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      _updateThemeSelection(appProvider, AppConfig.THEME_LIGHT);
                      Navigator.pop(context);
                    },
                  ),

                  Divider(
                    height: 1,
                    color: isDarkMode
                        ? AppTheme.darkDividerColor
                        : AppTheme.dividerColor,
                  ),

                  _buildThemeOption(
                    context,
                    icon: Icons.nightlight_round,
                    title: l10n?.themeDark ?? '幽谷',
                    subtitle: l10n?.themeDarkDesc ?? '深色主题',
                    value: AppConfig.THEME_DARK,
                    currentValue: appConfig.themeSelection,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      _updateThemeSelection(appProvider, AppConfig.THEME_DARK);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建主题选项
  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : secondaryColor,
                  size: 20,
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
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示iOS风格的笔记状态选择器
  void _showVisibilitySelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final l10n = AppLocalizationsSimple.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n?.selectNoteVisibility ?? '选择默认笔记状态',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  // 选项列表
                  _buildVisibilityOption(
                    context,
                    icon: Icons.lock_outline,
                    title: l10n?.private ?? '私有',
                    subtitle: l10n?.privateDesc ?? '仅自己可见',
                    value: AppConfig.VISIBILITY_PRIVATE,
                    currentValue: appConfig.defaultNoteVisibility,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      _updateDefaultVisibility(
                        appProvider,
                        AppConfig.VISIBILITY_PRIVATE,
                      );
                      Navigator.pop(context);
                    },
                  ),

                  Divider(
                    height: 1,
                    color: isDarkMode
                        ? AppTheme.darkDividerColor
                        : AppTheme.dividerColor,
                  ),

                  _buildVisibilityOption(
                    context,
                    icon: Icons.public_outlined,
                    title: l10n?.public ?? '公开',
                    subtitle: l10n?.publicDesc ?? '所有人可见',
                    value: AppConfig.VISIBILITY_PUBLIC,
                    currentValue: appConfig.defaultNoteVisibility,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      _updateDefaultVisibility(
                        appProvider,
                        AppConfig.VISIBILITY_PUBLIC,
                      );
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建笔记状态选项
  Widget _buildVisibilityOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : secondaryColor,
                  size: 20,
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
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示iOS风格的字体大小选择器
  void _showFontSizeSelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final l10n = AppLocalizationsSimple.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n?.selectFontSize ?? '选择字体大小',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  // 选项列表（可滚动）
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFontSizeOption(
                            context,
                            icon: Icons.text_fields,
                            title: l10n?.fontSizeMini ?? '极小',
                            subtitle: l10n?.fontSizeMiniDesc ?? '最小字体，节省空间',
                            value: AppConfig.FONT_SCALE_MINI,
                            currentValue: appConfig.fontScale,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontScale(
                                appProvider,
                                AppConfig.FONT_SCALE_MINI,
                              );
                              Navigator.pop(context);
                            },
                          ),
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),
                          _buildFontSizeOption(
                            context,
                            icon: Icons.text_fields,
                            title: l10n?.fontSizeSmall ?? '小',
                            subtitle: l10n?.fontSizeSmallDesc ?? '适合阅读大量文字',
                            value: AppConfig.FONT_SCALE_SMALL,
                            currentValue: appConfig.fontScale,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontScale(
                                appProvider,
                                AppConfig.FONT_SCALE_SMALL,
                              );
                              Navigator.pop(context);
                            },
                          ),
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),
                          _buildFontSizeOption(
                            context,
                            icon: Icons.text_fields,
                            title: l10n?.fontSizeNormal ?? '标准',
                            subtitle: l10n?.fontSizeNormalDesc ?? '默认字体大小',
                            value: AppConfig.FONT_SCALE_NORMAL,
                            currentValue: appConfig.fontScale,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontScale(
                                appProvider,
                                AppConfig.FONT_SCALE_NORMAL,
                              );
                              Navigator.pop(context);
                            },
                          ),
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),
                          _buildFontSizeOption(
                            context,
                            icon: Icons.text_fields,
                            title: l10n?.fontSizeLarge ?? '大',
                            subtitle: l10n?.fontSizeLargeDesc ?? '更易于阅读',
                            value: AppConfig.FONT_SCALE_LARGE,
                            currentValue: appConfig.fontScale,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontScale(
                                appProvider,
                                AppConfig.FONT_SCALE_LARGE,
                              );
                              Navigator.pop(context);
                            },
                          ),
                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),
                          _buildFontSizeOption(
                            context,
                            icon: Icons.text_fields,
                            title: l10n?.fontSizeXLarge ?? '特大',
                            subtitle: l10n?.fontSizeXLargeDesc ?? '最大字体',
                            value: AppConfig.FONT_SCALE_XLARGE,
                            currentValue: appConfig.fontScale,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontScale(
                                appProvider,
                                AppConfig.FONT_SCALE_XLARGE,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建字体大小选项
  Widget _buildFontSizeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double currentValue,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;
    final fontSize = 16.0 * value; // 预览效果
    final iconSize = 20.0 * value; // 图标按比例缩放
    final containerSize = (iconSize + 16).clamp(40.0, 60.0); // 容器自适应，最小40最大60

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? primaryColor : secondaryColor,
                    size: iconSize,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryColor : textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 更新字体缩放
  Future<void> _updateFontScale(
    AppProvider appProvider,
    double fontScale,
  ) async {
    debugPrint('🔤 [PreferencesScreen] 开始更新字体缩放: $fontScale');

    final updatedConfig = appProvider.appConfig.copyWith(fontScale: fontScale);
    await appProvider.updateConfig(updatedConfig);

    debugPrint(
      '🔤 [PreferencesScreen] 字体缩放已保存到配置，将通过MediaQuery.textScaleFactor全局应用',
    );

    if (mounted) {
      String sizeName;
      if (fontScale == AppConfig.FONT_SCALE_SMALL) {
        sizeName = '小';
      } else if (fontScale == AppConfig.FONT_SCALE_LARGE) {
        sizeName = '大';
      } else if (fontScale == AppConfig.FONT_SCALE_XLARGE) {
        sizeName = '特大';
      } else {
        sizeName = '标准';
      }

      debugPrint('🔤 [PreferencesScreen] 字体大小设置完成: $sizeName (实时生效)');
      SnackBarUtils.showSuccess(context, '字体大小已设置为$sizeName');
    }
  }

  // 构建字体家族选择器
  Widget _buildFontFamilySelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final l10n = AppLocalizationsSimple.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    // 获取当前字体名称
    String getCurrentFontName() {
      switch (appConfig.fontFamily) {
        case AppConfig.FONT_FAMILY_NOTO_SANS:
          return l10n?.fontFamilyNotoSans ?? '思源黑体';
        case AppConfig.FONT_FAMILY_NOTO_SERIF:
          return l10n?.fontFamilyNotoSerif ?? '思源宋体';
        case AppConfig.FONT_FAMILY_MA_SHAN_ZHENG:
          return l10n?.fontFamilyMaShanZheng ?? '楷体风格';
        case AppConfig.FONT_FAMILY_ZCOOL_XIAOWEI:
          return l10n?.fontFamilyZcoolXiaowei ?? '站酷小薇';
        case AppConfig.FONT_FAMILY_ZCOOL_QINGKE:
          return l10n?.fontFamilyZcoolQingke ?? '站酷庆科';
        case AppConfig.FONT_FAMILY_DEFAULT:
        default:
          return l10n?.fontFamilyDefault ?? 'SF Pro Display';
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFontFamilySelector(context, appProvider, appConfig),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          child: Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.fontScaledBorderRadius(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColorWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.font_download_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // 中间文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.fontSelection ?? '字体选择',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getCurrentFontName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示iOS风格的字体家族选择器
  void _showFontFamilySelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final l10n = AppLocalizationsSimple.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n?.selectFont ?? '选择字体',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  // 选项列表（添加滚动支持）
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 选项列表开始
                          _buildFontFamilyOption(
                            context,
                            icon: Icons.text_fields,
                            title: l10n?.fontFamilyDefault ?? 'SF Pro Display',
                            subtitle:
                                l10n?.fontFamilyDefaultDesc ?? '系统默认，清晰现代',
                            value: AppConfig.FONT_FAMILY_DEFAULT,
                            currentValue: appConfig.fontFamily,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontFamily(
                                appProvider,
                                AppConfig.FONT_FAMILY_DEFAULT,
                              );
                              Navigator.pop(context);
                            },
                          ),

                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),

                          _buildFontFamilyOption(
                            context,
                            icon: Icons.format_bold,
                            title: l10n?.fontFamilyNotoSans ?? '思源黑体',
                            subtitle: l10n?.fontFamilyNotoSansDesc ??
                                'Noto Sans SC，现代简洁',
                            value: AppConfig.FONT_FAMILY_NOTO_SANS,
                            currentValue: appConfig.fontFamily,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontFamily(
                                appProvider,
                                AppConfig.FONT_FAMILY_NOTO_SANS,
                              );
                              Navigator.pop(context);
                            },
                          ),

                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),

                          _buildFontFamilyOption(
                            context,
                            icon: Icons.format_quote,
                            title: l10n?.fontFamilyNotoSerif ?? '思源宋体',
                            subtitle: l10n?.fontFamilyNotoSerifDesc ??
                                'Noto Serif SC，优雅复古',
                            value: AppConfig.FONT_FAMILY_NOTO_SERIF,
                            currentValue: appConfig.fontFamily,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontFamily(
                                appProvider,
                                AppConfig.FONT_FAMILY_NOTO_SERIF,
                              );
                              Navigator.pop(context);
                            },
                          ),

                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),

                          _buildFontFamilyOption(
                            context,
                            icon: Icons.brush,
                            title: l10n?.fontFamilyMaShanZheng ?? '楷体风格',
                            subtitle: l10n?.fontFamilyMaShanZhengDesc ??
                                'Ma Shan Zheng，手写风格',
                            value: AppConfig.FONT_FAMILY_MA_SHAN_ZHENG,
                            currentValue: appConfig.fontFamily,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontFamily(
                                appProvider,
                                AppConfig.FONT_FAMILY_MA_SHAN_ZHENG,
                              );
                              Navigator.pop(context);
                            },
                          ),

                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),

                          _buildFontFamilyOption(
                            context,
                            icon: Icons.font_download_outlined,
                            title: l10n?.fontFamilyZcoolXiaowei ?? '站酷小薇',
                            subtitle: l10n?.fontFamilyZcoolXiaoweiDesc ??
                                'Zcool XiaoWei，圆润可爱',
                            value: AppConfig.FONT_FAMILY_ZCOOL_XIAOWEI,
                            currentValue: appConfig.fontFamily,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontFamily(
                                appProvider,
                                AppConfig.FONT_FAMILY_ZCOOL_XIAOWEI,
                              );
                              Navigator.pop(context);
                            },
                          ),

                          Divider(
                            height: 1,
                            color: isDarkMode
                                ? AppTheme.darkDividerColor
                                : AppTheme.dividerColor,
                          ),

                          _buildFontFamilyOption(
                            context,
                            icon: Icons.auto_awesome,
                            title: l10n?.fontFamilyZcoolQingke ?? '站酷庆科',
                            subtitle: l10n?.fontFamilyZcoolQingkeDesc ??
                                'Zcool QingKe，活泼有趣',
                            value: AppConfig.FONT_FAMILY_ZCOOL_QINGKE,
                            currentValue: appConfig.fontFamily,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            secondaryColor: secondaryColor,
                            onTap: () {
                              _updateFontFamily(
                                appProvider,
                                AppConfig.FONT_FAMILY_ZCOOL_QINGKE,
                              );
                              Navigator.pop(context);
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
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

  // 构建字体家族选项
  Widget _buildFontFamilyOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : secondaryColor,
                  size: 22,
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
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 更新字体家族
  Future<void> _updateFontFamily(
    AppProvider appProvider,
    String fontFamily,
  ) async {
    debugPrint('🔤 [PreferencesScreen] 开始更新字体家族: $fontFamily');

    final updatedConfig =
        appProvider.appConfig.copyWith(fontFamily: fontFamily);
    await appProvider.updateConfig(updatedConfig);

    debugPrint('🔤 [PreferencesScreen] 字体家族已保存到配置，将全局应用');

    if (mounted) {
      final l10n = AppLocalizationsSimple.of(context);
      String fontName;
      switch (fontFamily) {
        case AppConfig.FONT_FAMILY_NOTO_SANS:
          fontName = l10n?.fontFamilyNotoSans ?? '思源黑体';
          break;
        case AppConfig.FONT_FAMILY_NOTO_SERIF:
          fontName = l10n?.fontFamilyNotoSerif ?? '思源宋体';
          break;
        case AppConfig.FONT_FAMILY_MA_SHAN_ZHENG:
          fontName = l10n?.fontFamilyMaShanZheng ?? '楷体风格';
          break;
        case AppConfig.FONT_FAMILY_ZCOOL_XIAOWEI:
          fontName = l10n?.fontFamilyZcoolXiaowei ?? '站酷小薇';
          break;
        case AppConfig.FONT_FAMILY_ZCOOL_QINGKE:
          fontName = l10n?.fontFamilyZcoolQingke ?? '站酷庆科';
          break;
        case AppConfig.FONT_FAMILY_DEFAULT:
        default:
          fontName = l10n?.fontFamilyDefault ?? 'SF Pro Display';
      }

      debugPrint('🔤 [PreferencesScreen] 字体家族设置完成: $fontName (实时生效)');
      SnackBarUtils.showSuccess(context, l10n?.fontChanged(fontName) ?? '字体已切换为$fontName');
    }
  }

  // 构建语言选择器
  Widget _buildLanguageSelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final l10n = AppLocalizationsSimple.of(context);

    // 获取当前语言名称
    String getCurrentLanguageName() {
      switch (appConfig.locale) {
        case AppConfig.LOCALE_SYSTEM:
        case null:
          return l10n?.languageSystem ?? '跟随系统';
        case AppConfig.LOCALE_ZH_CN:
          return l10n?.languageChineseSimplified ?? '简体中文';
        case AppConfig.LOCALE_ZH_TW:
          return l10n?.languageChineseTraditionalTW ?? '繁体中文（台湾）';
        case AppConfig.LOCALE_ZH_HK:
          return l10n?.languageChineseTraditionalHK ?? '繁体中文（香港）';
        case AppConfig.LOCALE_EN_US:
        case AppConfig.LOCALE_EN_GB:
          return l10n?.languageEnglish ?? 'English';
        case AppConfig.LOCALE_JA_JP:
          return l10n?.languageJapanese ?? '日本語';
        case AppConfig.LOCALE_KO_KR:
          return l10n?.languageKorean ?? '한국어';
        case AppConfig.LOCALE_FR_FR:
          return l10n?.languageFrench ?? 'Français';
        case AppConfig.LOCALE_DE_DE:
          return l10n?.languageGerman ?? 'Deutsch';
        case AppConfig.LOCALE_ES_ES:
          return l10n?.languageSpanish ?? 'Español';
        case AppConfig.LOCALE_PT_PT:
          return l10n?.languagePortuguesePT ?? 'Português (PT)';
        case AppConfig.LOCALE_PT_BR:
          return l10n?.languagePortugueseBR ?? 'Português (BR)';
        case AppConfig.LOCALE_IT_IT:
          return l10n?.languageItalian ?? 'Italiano';
        case AppConfig.LOCALE_RU_RU:
          return l10n?.languageRussian ?? 'Русский';
        case AppConfig.LOCALE_AR_SA:
          return l10n?.languageArabic ?? 'العربية';
        case AppConfig.LOCALE_TH_TH:
          return l10n?.languageThai ?? 'ไทย';
        case AppConfig.LOCALE_VI_VN:
          return l10n?.languageVietnamese ?? 'Tiếng Việt';
        case AppConfig.LOCALE_ID_ID:
          return l10n?.languageIndonesian ?? 'Bahasa Indonesia';
        case AppConfig.LOCALE_MS_MY:
          return l10n?.languageMalay ?? 'Bahasa Melayu';
        case AppConfig.LOCALE_TR_TR:
          return l10n?.languageTurkish ?? 'Türkçe';
        case AppConfig.LOCALE_PL_PL:
          return l10n?.languagePolish ?? 'Polski';
        case AppConfig.LOCALE_NL_NL:
          return l10n?.languageDutch ?? 'Nederlands';
        case AppConfig.LOCALE_HI_IN:
          return l10n?.languageHindi ?? 'हिन्दी';
        default:
          return l10n?.languageSystem ?? '跟随系统';
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLanguageSelector(context, appProvider, appConfig),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          child: Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.fontScaledBorderRadius(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : primaryColorWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.language,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // 标题和当前值
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.language ?? '语言选择',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getCurrentLanguageName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建侧边栏自定义选择器
  Widget _buildSidebarCustomizationSelector(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColorWithOpacity = AppTheme.primaryColor.withOpacity(0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.fontScaledSpacing(context, 8),
        horizontal: ResponsiveUtils.fontScaledSpacing(context, 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SidebarCustomizationScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.fontScaledBorderRadius(context, 12),
          ),
          child: Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 16)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.fontScaledBorderRadius(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : primaryColorWithOpacity,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.view_sidebar_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // 标题和当前值
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizationsSimple.of(context)?.sidebarCustomization ?? '侧边栏',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizationsSimple.of(context)?.adjustMenuDisplay ?? '调整菜单显示与排序',
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示iOS风格的语言选择器
  void _showLanguageSelector(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final l10n = AppLocalizationsSimple.of(context);

    // 定义支持的语言（仅中英文）
    final languages = [
      {
        'icon': Icons.smartphone,
        'locale': AppConfig.LOCALE_SYSTEM,
        'getter': () => l10n?.languageSystem ?? '跟随系统',
      },
      {
        'icon': Icons.language,
        'locale': AppConfig.LOCALE_ZH_CN,
        'getter': () => l10n?.languageChineseSimplified ?? '简体中文',
      },
      {
        'icon': Icons.language,
        'locale': AppConfig.LOCALE_EN_US,
        'getter': () => l10n?.languageEnglish ?? 'English',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n?.selectLanguage ?? '选择语言',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  // 选项列表（可滚动，支持23种语言）
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < languages.length; i++) ...[
                              _buildLanguageOption(
                                context,
                                icon: languages[i]['icon']! as IconData,
                                title: (languages[i]['getter']! as Function)(),
                                subtitle:
                                    (languages[i]['getter']! as Function)(),
                                value: languages[i]['locale'] as String?,
                                currentValue: appConfig.locale,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                secondaryColor: secondaryColor,
                                onTap: () {
                                  _updateLanguage(
                                    appProvider,
                                    languages[i]['locale'] as String?,
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                              if (i < languages.length - 1)
                                Divider(
                                  height: 1,
                                  color: isDarkMode
                                      ? AppTheme.darkDividerColor
                                      : AppTheme.dividerColor,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建语言选项
  Widget _buildLanguageOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String? value,
    required String? currentValue,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.15)
                      : primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : secondaryColor,
                  size: 20,
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
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 更新语言
  Future<void> _updateLanguage(AppProvider appProvider, String? locale) async {
    debugPrint('🌍 [PreferencesScreen] 开始更新语言: $locale');

    await appProvider.setLocale(locale);

    debugPrint('🌍 [PreferencesScreen] 语言已保存到配置');

    if (mounted) {
      final l10n = AppLocalizationsSimple.of(context);
      final languageName = _getLanguageName(locale, l10n);

      debugPrint('🌍 [PreferencesScreen] 语言设置完成: $languageName (实时生效)');

      // 使用本地化的消息
      if (l10n != null) {
        SnackBarUtils.showSuccess(context, l10n.languageChanged(languageName));
      } else {
        SnackBarUtils.showSuccess(context, '语言已切换为$languageName');
      }
    }
  }

  // 获取语言名称（辅助方法）
  String _getLanguageName(String? locale, AppLocalizationsSimple? l10n) {
    switch (locale) {
      case AppConfig.LOCALE_SYSTEM:
      case null:
        return l10n?.languageSystem ?? '跟随系统';
      case AppConfig.LOCALE_ZH_CN:
        return l10n?.languageChineseSimplified ?? '简体中文';
      case AppConfig.LOCALE_ZH_TW:
        return l10n?.languageChineseTraditionalTW ?? '繁体中文（台湾）';
      case AppConfig.LOCALE_ZH_HK:
        return l10n?.languageChineseTraditionalHK ?? '繁体中文（香港）';
      case AppConfig.LOCALE_EN_US:
      case AppConfig.LOCALE_EN_GB:
        return l10n?.languageEnglish ?? 'English';
      case AppConfig.LOCALE_JA_JP:
        return l10n?.languageJapanese ?? '日本語';
      case AppConfig.LOCALE_KO_KR:
        return l10n?.languageKorean ?? '한국어';
      case AppConfig.LOCALE_FR_FR:
        return l10n?.languageFrench ?? 'Français';
      case AppConfig.LOCALE_DE_DE:
        return l10n?.languageGerman ?? 'Deutsch';
      case AppConfig.LOCALE_ES_ES:
        return l10n?.languageSpanish ?? 'Español';
      case AppConfig.LOCALE_PT_PT:
        return l10n?.languagePortuguesePT ?? 'Português (PT)';
      case AppConfig.LOCALE_PT_BR:
        return l10n?.languagePortugueseBR ?? 'Português (BR)';
      case AppConfig.LOCALE_IT_IT:
        return l10n?.languageItalian ?? 'Italiano';
      case AppConfig.LOCALE_RU_RU:
        return l10n?.languageRussian ?? 'Русский';
      case AppConfig.LOCALE_AR_SA:
        return l10n?.languageArabic ?? 'العربية';
      case AppConfig.LOCALE_TH_TH:
        return l10n?.languageThai ?? 'ไทย';
      case AppConfig.LOCALE_VI_VN:
        return l10n?.languageVietnamese ?? 'Tiếng Việt';
      case AppConfig.LOCALE_ID_ID:
        return l10n?.languageIndonesian ?? 'Bahasa Indonesia';
      case AppConfig.LOCALE_MS_MY:
        return l10n?.languageMalay ?? 'Bahasa Melayu';
      case AppConfig.LOCALE_TR_TR:
        return l10n?.languageTurkish ?? 'Türkçe';
      case AppConfig.LOCALE_PL_PL:
        return l10n?.languagePolish ?? 'Polski';
      case AppConfig.LOCALE_NL_NL:
        return l10n?.languageDutch ?? 'Nederlands';
      case AppConfig.LOCALE_HI_IN:
        return l10n?.languageHindi ?? 'हिन्दी';
      default:
        return l10n?.languageSystem ?? '跟随系统';
    }
  }
}
