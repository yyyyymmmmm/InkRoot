import 'package:flutter/material.dart';
import 'package:inkroot/utils/responsive_utils.dart';

class AppTypography {
  // 基础字体大小
  static const double _baseDisplayLarge = 57;
  static const double _baseDisplayMedium = 45;
  static const double _baseDisplaySmall = 36;
  static const double _baseHeadlineLarge = 32;
  static const double _baseHeadlineMedium = 28;
  static const double _baseHeadlineSmall = 24;
  static const double _baseTitleLarge = 22;
  static const double _baseTitleMedium = 16;
  static const double _baseTitleSmall = 14;
  static const double _baseLabelLarge = 14;
  static const double _baseLabelMedium = 12;
  static const double _baseLabelSmall = 11;
  static const double _baseBodyLarge = 16;
  static const double _baseBodyMedium = 14;
  static const double _baseBodySmall = 12;

  // 字体权重
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // 获取响应式字体主题
  static TextTheme getResponsiveTextTheme(
    BuildContext context, {
    bool isDark = false,
  }) {
    final baseColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.white70 : Colors.black54;

    return TextTheme(
      // Display styles - 用于大标题
      displayLarge: TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, _baseDisplayLarge),
        fontWeight: bold,
        color: baseColor,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, _baseDisplayMedium),
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, _baseDisplaySmall),
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: 0,
        height: 1.22,
      ),

      // Headline styles - 用于页面标题
      headlineLarge: TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, _baseHeadlineLarge),
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, _baseHeadlineMedium),
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, _baseHeadlineSmall),
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: 0,
        height: 1.33,
      ),

      // Title styles - 用于组件标题
      titleLarge: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseTitleLarge),
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseTitleMedium),
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseTitleSmall),
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // Label styles - 用于按钮和标签
      labelLarge: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseLabelLarge),
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseLabelMedium),
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseLabelSmall),
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0.5,
        height: 1.45,
      ),

      // Body styles - 用于正文
      bodyLarge: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseBodyLarge),
        fontWeight: regular,
        color: baseColor,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseBodyMedium),
        fontWeight: regular,
        color: baseColor,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, _baseBodySmall),
        fontWeight: regular,
        color: secondaryColor,
        letterSpacing: 0.4,
        height: 1.33,
      ),
    );
  }

  // 自定义样式获取器
  static TextStyle getDisplayStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          fontSize ?? _baseDisplayLarge,
        ),
        fontWeight: fontWeight ?? bold,
        color: color,
        letterSpacing: letterSpacing ?? -0.25,
        height: height ?? 1.12,
      );

  static TextStyle getHeadlineStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          fontSize ?? _baseHeadlineLarge,
        ),
        fontWeight: fontWeight ?? semiBold,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.25,
      );

  static TextStyle getTitleStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          fontSize ?? _baseTitleLarge,
        ),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.27,
      );

  static TextStyle getBodyStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          fontSize ?? _baseBodyLarge,
        ),
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: letterSpacing ?? 0.15,
        height: height ?? 1.5,
      );

  static TextStyle getLabelStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(
          context,
          fontSize ?? _baseLabelLarge,
        ),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0.1,
        height: height ?? 1.43,
      );

  // 特殊用途样式
  static TextStyle getButtonStyle(
    BuildContext context, {
    bool isLarge = false,
    Color? color,
  }) =>
      TextStyle(
        fontSize:
            ResponsiveUtils.responsiveFontSize(context, isLarge ? 16.0 : 14.0),
        fontWeight: medium,
        color: color,
        letterSpacing: 0.1,
        height: 1.43,
      );

  static TextStyle getCaptionStyle(
    BuildContext context, {
    Color? color,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 12),
        fontWeight: regular,
        color: color,
        letterSpacing: 0.4,
        height: 1.33,
      );

  static TextStyle getOverlineStyle(
    BuildContext context, {
    Color? color,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 10),
        fontWeight: medium,
        color: color,
        letterSpacing: 1.5,
        height: 1.6,
      );

  // 代码样式
  static TextStyle getCodeStyle(
    BuildContext context, {
    Color? color,
    Color? backgroundColor,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
        fontWeight: regular,
        color: color,
        backgroundColor: backgroundColor,
        fontFamily: 'Courier',
        letterSpacing: 0,
        height: 1.4,
      );
}
