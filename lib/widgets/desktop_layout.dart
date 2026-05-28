import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/widgets/sidebar.dart';

/// 桌面端固定侧边栏布局
/// 侧边栏保持不动，只更新右侧内容
class DesktopLayout extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const DesktopLayout({
    super.key,
    required this.child,
    this.appBar,
    this.backgroundColor,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  static double _sidebarWidth = 280; // 使用static保持宽度

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.backgroundColor ??
        (isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor);

    // 检测是否为桌面端
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    if (!isDesktop) {
      // 移动端直接返回子组件
      return widget.child;
    }

    // 桌面端使用固定侧边栏布局
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // 固定侧边栏 - 使用RepaintBoundary隔离重绘
          RepaintBoundary(
            child: SizedBox(
              width: _sidebarWidth,
              child: ColoredBox(
                color: isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor,
                child: const Sidebar(isDrawer: false),
              ),
            ),
          ),
          // 可拖动的分隔条
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(200.0, 400.0);
                });
              },
              child: Container(
                width: 1,
                color: isDarkMode
                    ? AppTheme.darkDividerColor
                    : AppTheme.dividerColor,
              ),
            ),
          ),
          // 右侧内容区域 - 直接切换，无动画
          Expanded(
            child: widget.appBar != null
                ? Scaffold(
                    backgroundColor: backgroundColor,
                    appBar: widget.appBar,
                    body: widget.child,
                  )
                : widget.child,
          ),
        ],
      ),
    );
  }
}
