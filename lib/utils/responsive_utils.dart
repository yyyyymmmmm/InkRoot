import 'package:flutter/material.dart';

class ResponsiveUtils {
  // 屏幕断点定义 (基于Material Design 3规范)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;

  // 全局字体缩放因子（可通过用户设置调整）
  static double globalFontScale = 1;

  static const double minAppTextScale = 0.8;
  static const double maxAppTextScale = 1.3;

  static double clampAppTextScale(double scale) {
    if (scale < minAppTextScale) {
      return minAppTextScale;
    }
    if (scale > maxAppTextScale) {
      return maxAppTextScale;
    }
    return scale;
  }

  // 获取屏幕类型
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // 检查是否为小屏设备
  static bool isMobile(BuildContext context) =>
      getScreenType(context) == ScreenType.mobile;

  // 检查是否为平板
  static bool isTablet(BuildContext context) =>
      getScreenType(context) == ScreenType.tablet;

  // 检查是否为桌面
  static bool isDesktop(BuildContext context) =>
      getScreenType(context) == ScreenType.desktop;

  // 响应式值选择器
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  // 响应式字体大小（仅屏幕适配，全局字体缩放由MediaQuery.textScaleFactor处理）
  static double responsiveFontSize(BuildContext context, double baseFontSize) {
    final screenType = getScreenType(context);
    double screenMultiplier;
    switch (screenType) {
      case ScreenType.mobile:
        screenMultiplier = 1.0;
        break;
      case ScreenType.tablet:
        screenMultiplier = 1.1;
        break;
      case ScreenType.desktop:
        screenMultiplier = 1.2;
        break;
    }
    // 🔥 只应用屏幕倍数，全局字体缩放由MediaQuery.textScaleFactor统一处理
    // 这样符合Flutter最佳实践和大厂APP的实现方式
    return baseFontSize * screenMultiplier;
  }

  // 响应式间距
  static double responsiveSpacing(BuildContext context, double baseSpacing) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseSpacing;
      case ScreenType.tablet:
        return baseSpacing * 1.2;
      case ScreenType.desktop:
        return baseSpacing * 1.4;
    }
  }

  // 响应式边距
  static EdgeInsets responsivePadding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final multiplier = responsive<double>(
      context,
      mobile: 1,
      tablet: 1.2,
      desktop: 1.4,
    );

    if (all != null) {
      return EdgeInsets.all(all * multiplier);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * multiplier,
      top: (top ?? vertical ?? 0) * multiplier,
      right: (right ?? horizontal ?? 0) * multiplier,
      bottom: (bottom ?? vertical ?? 0) * multiplier,
    );
  }

  // 响应式容器宽度
  static double responsiveContainerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return responsive<double>(
      context,
      mobile: width * 0.9,
      tablet: width * 0.8,
      desktop: width * 0.6,
    );
  }

  // 安全区域感知的高度
  static double safeHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }

  // 安全区域感知的宽度
  static double safeWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right;
  }

  // 响应式按钮尺寸
  static Size responsiveButtonSize(BuildContext context) => responsive<Size>(
        context,
        mobile: const Size(double.infinity, 48),
        tablet: const Size(double.infinity, 52),
        desktop: const Size(double.infinity, 56),
      );

  // 响应式图标大小
  static double responsiveIconSize(BuildContext context, double baseSize) =>
      responsive<double>(
        context,
        mobile: baseSize,
        tablet: baseSize * 1.1,
        desktop: baseSize * 1.2,
      );

  // 获取最大内容宽度
  static double getMaxContentWidth(BuildContext context) => responsive<double>(
        context,
        mobile: double.infinity,
        tablet: 600,
        desktop: 800,
      );

  // ==================== 字体缩放响应式工具（符合大厂标准）====================

  /// 获取当前字体缩放因子（从MediaQuery获取）
  static double getFontScaleFactor(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1);

  /// 响应字体缩放的间距（padding/margin）
  /// 根据字体大小调整间距，保持视觉平衡
  /// 例如：基础间距16，字体放大1.3x，间距变为 16 * 1.15 = 18.4
  static double fontScaledSpacing(BuildContext context, double baseSpacing) {
    final fontScale = getFontScaleFactor(context);
    // 间距缩放系数比字体稍小，避免过度放大
    // 字体1.3x时，间距约1.15x（平方根关系）
    final spacingScale = 0.5 + (fontScale * 0.5);
    return baseSpacing * spacingScale;
  }

  /// 响应字体缩放的内边距
  /// 用法：ResponsiveUtils.fontScaledPadding(context, all: 16)
  static EdgeInsets fontScaledPadding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(fontScaledSpacing(context, all));
    }

    return EdgeInsets.only(
      left: fontScaledSpacing(context, left ?? horizontal ?? 0),
      top: fontScaledSpacing(context, top ?? vertical ?? 0),
      right: fontScaledSpacing(context, right ?? horizontal ?? 0),
      bottom: fontScaledSpacing(context, bottom ?? vertical ?? 0),
    );
  }

  /// 响应字体缩放的按钮高度
  /// 根据字体大小调整按钮高度，保持按钮内文字不拥挤
  /// 基础高度48，字体1.3x时，按钮高度约55
  static double fontScaledButtonHeight(
    BuildContext context, {
    double baseHeight = 48,
  }) {
    final fontScale = getFontScaleFactor(context);
    // 按钮高度缩放系数略大于间距，确保内容不拥挤
    final buttonScale = 0.7 + (fontScale * 0.3);
    return baseHeight * buttonScale;
  }

  /// 响应字体缩放的图标大小（可选功能）
  /// 根据字体大小调整图标，保持视觉协调
  /// 基础20，字体1.3x时，图标约23
  static double fontScaledIconSize(BuildContext context, double baseSize) {
    final fontScale = getFontScaleFactor(context);
    // 图标缩放系数比字体稍小，避免图标过大
    final iconScale = 0.7 + (fontScale * 0.3);
    return baseSize * iconScale;
  }

  /// 响应字体缩放的圆角半径
  /// 保持圆角与组件尺寸的协调性
  static double fontScaledBorderRadius(
    BuildContext context,
    double baseRadius,
  ) {
    final fontScale = getFontScaleFactor(context);
    final radiusScale = 0.8 + (fontScale * 0.2);
    return baseRadius * radiusScale;
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}

// 响应式Widget构建器
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);
    return builder(context, screenType);
  }
}

// 响应式布局Widget
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < ResponsiveUtils.mobileBreakpoint) {
            return mobile;
          } else if (constraints.maxWidth < ResponsiveUtils.tabletBreakpoint) {
            return tablet ?? mobile;
          } else {
            return desktop ?? tablet ?? mobile;
          }
        },
      );
}

// 响应式容器
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth,
    this.padding,
    this.margin,
  });
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.getMaxContentWidth(context),
        ),
        padding: padding ??
            ResponsiveUtils.responsivePadding(
              context,
              horizontal: 16,
            ),
        margin: margin,
        child: child,
      );
}
