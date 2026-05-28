import 'package:flutter/material.dart';
import 'package:inkroot/utils/responsive_utils.dart';

/// Helper class for text styles with convenient static methods
class AppTextStyles {
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Display styles
  static TextStyle displayLarge(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 57),
        fontWeight: fontWeight ?? bold,
        color: color,
        letterSpacing: letterSpacing ?? -0.25,
        height: height ?? 1.12,
      );

  static TextStyle displayMedium(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 45),
        fontWeight: fontWeight ?? semiBold,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.16,
      );

  static TextStyle displaySmall(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 36),
        fontWeight: fontWeight ?? semiBold,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.22,
      );

  // Headline styles
  static TextStyle headlineLarge(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 32),
        fontWeight: fontWeight ?? semiBold,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.25,
      );

  static TextStyle headlineMedium(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 28),
        fontWeight: fontWeight ?? semiBold,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.29,
      );

  static TextStyle headlineSmall(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 24),
        fontWeight: fontWeight ?? semiBold,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.33,
      );

  // Title styles
  static TextStyle titleLarge(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 22),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0,
        height: height ?? 1.27,
      );

  static TextStyle titleMedium(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 15),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0.15,
        height: height ?? 1.5,
      );

  static TextStyle titleSmall(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 13),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0.1,
        height: height ?? 1.43,
      );

  // Label styles
  static TextStyle labelLarge(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 13),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0.1,
        height: height ?? 1.43,
      );

  static TextStyle labelMedium(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 11),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0.5,
        height: height ?? 1.33,
      );

  static TextStyle labelSmall(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 10),
        fontWeight: fontWeight ?? medium,
        color: color,
        letterSpacing: letterSpacing ?? 0.5,
        height: height ?? 1.45,
      );

  // Body styles
  static TextStyle bodyLarge(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 15),
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: letterSpacing ?? 0.15,
        height: height ?? 1.5,
      );

  static TextStyle bodyMedium(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 13),
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: letterSpacing ?? 0.25,
        height: height ?? 1.43,
      );

  static TextStyle bodySmall(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, 11),
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: letterSpacing ?? 0.4,
        height: height ?? 1.33,
      );

  // Custom style with specific font size
  static TextStyle custom(
    BuildContext context,
    double fontSize, {
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    String? fontFamily,
    Color? backgroundColor,
  }) =>
      TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(context, fontSize),
        fontWeight: fontWeight ?? regular,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontFamily: fontFamily,
        backgroundColor: backgroundColor,
      );

  // Special purpose styles
  static TextStyle button(
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

  static TextStyle caption(
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

  static TextStyle code(
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
