import 'package:flutter/material.dart';
import 'package:inkroot/models/app_config_model.dart';

/// 配置管理 Provider Mixin
///
/// 提供应用配置相关功能：
/// - 主题设置（深色模式、主题选择、主题模式）
/// - 语言设置
mixin AppProviderConfig on ChangeNotifier {
  // ============================================================
  // 抽象属性（需要主类提供）
  // ============================================================

  /// 获取应用配置（由主类提供）
  AppConfig get appConfig;

  /// 更新配置（由主类实现）
  Future<void> updateConfig(AppConfig newConfig);

  // ============================================================
  // Getters
  // ============================================================

  /// 获取当前是否为深色模式
  ///
  /// 优先使用 themeSelection:
  /// - THEME_DARK: 深色模式
  /// - THEME_LIGHT: 浅色模式
  /// - THEME_SYSTEM: 跟随系统
  ///
  /// 兼容旧版本的 isDarkMode 字段
  bool get isDarkMode {
    // 如果themeSelection为空，使用旧版本的isDarkMode
    if (appConfig.themeSelection.isEmpty) {
      return appConfig.isDarkMode;
    }

    // 如果是跟随系统，获取系统设置
    if (appConfig.themeSelection == AppConfig.THEME_SYSTEM) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }

    // 否则根据主题选择返回
    return appConfig.themeSelection == AppConfig.THEME_DARK;
  }

  /// 获取当前主题选择
  String get themeSelection => appConfig.themeSelection;

  /// 获取当前主题模式
  String get themeMode => appConfig.themeMode;

  /// 获取当前语言
  String? get locale => appConfig.locale;

  // ============================================================
  // 配置管理方法
  // ============================================================

  /// 切换深色模式（兼容旧版本）
  ///
  /// 等同于：
  /// - 如果当前是深色 → 切换到浅色
  /// - 如果当前是浅色 → 切换到深色
  Future<void> toggleDarkMode() async {
    final newTheme = isDarkMode ? AppConfig.THEME_LIGHT : AppConfig.THEME_DARK;
    await setThemeSelection(newTheme);
  }

  /// 设置深色模式（兼容旧版本）
  ///
  /// @param value true=深色模式, false=浅色模式
  Future<void> setDarkMode(bool value) async {
    final newTheme = value ? AppConfig.THEME_DARK : AppConfig.THEME_LIGHT;
    await setThemeSelection(newTheme);
  }

  /// 设置主题选择
  ///
  /// @param themeSelection 主题选择（THEME_LIGHT / THEME_DARK / THEME_SYSTEM）
  ///
  /// 会自动更新 isDarkMode 字段以保持向后兼容性
  Future<void> setThemeSelection(String themeSelection) async {
    if (themeSelection == appConfig.themeSelection) return;

    // 同时更新isDarkMode以保持向后兼容
    var isDarkMode = themeSelection == AppConfig.THEME_DARK;
    // 对于跟随系统，需要获取当前系统设置
    if (themeSelection == AppConfig.THEME_SYSTEM) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
    }

    final updatedConfig = appConfig.copyWith(
      themeSelection: themeSelection,
      isDarkMode: isDarkMode,
    );
    await updateConfig(updatedConfig);
  }

  /// 设置主题模式
  ///
  /// @param mode 主题模式（如 "cupertino" / "material"）
  Future<void> setThemeMode(String mode) async {
    if (mode == appConfig.themeMode) return;

    final updatedConfig = appConfig.copyWith(themeMode: mode);
    await updateConfig(updatedConfig);
  }

  /// 设置语言
  ///
  /// @param locale 语言代码（如 "zh" / "en" / null=跟随系统）
  Future<void> setLocale(String? locale) async {
    if (locale == appConfig.locale) return;

    debugPrint('🌍 [AppProviderConfig.setLocale] 准备更新locale: $locale');
    final updatedConfig = appConfig.copyWith(
      locale: locale,
      updateLocale: true, // 明确告知copyWith要更新locale字段
    );
    debugPrint(
      '🌍 [AppProviderConfig.setLocale] 更新后的locale: ${updatedConfig.locale}',
    );
    await updateConfig(updatedConfig);
    debugPrint('🌍 [AppProviderConfig.setLocale] locale已保存到数据库');
  }
}
