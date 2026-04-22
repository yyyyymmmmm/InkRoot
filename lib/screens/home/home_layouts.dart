// 响应式布局模块（从 home_screen.dart 拆分）
// 职责：管理 Mobile、Tablet、Desktop 三种布局模式

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/config/app_theme.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/widgets/note_card.dart';
import 'package:inkroot/widgets/responsive_container.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// 响应式布局管理类
///
/// 负责构建三种布局：
/// 1. Mobile Layout（移动端布局）
/// 2. Tablet Layout（平板布局）
/// 3. Desktop Layout（桌面布局）
class HomeLayouts {
  /// 侧边栏宽度（桌面端可调节）
  double sidebarWidth;

  /// 悬浮按钮动画控制器
  final AnimationController fabAnimationController;

  /// 悬浮按钮缩放动画
  final Animation<double> fabScaleAnimation;

  /// Scaffold Key
  final GlobalKey<ScaffoldState> scaffoldKey;

  /// 搜索控制器
  final TextEditingController searchController;

  /// 滚动控制器
  final ScrollController scrollController;

  HomeLayouts({
    required this.sidebarWidth,
    required this.fabAnimationController,
    required this.fabScaleAnimation,
    required this.scaffoldKey,
    required this.searchController,
    required this.scrollController,
  });

  /// 打开抽屉
  void Function()? onOpenDrawer;

  /// 退出搜索
  void Function()? onExitSearch;

  /// 刷新笔记
  Future<void> Function()? onRefreshNotes;

  /// 显示排序选项
  void Function()? onShowSortOptions;

  /// 显示AI洞察对话框
  void Function()? onShowAiInsightDialog;

  /// 显示添加笔记表单
  void Function()? onShowAddNoteForm;

  /// 显示编辑笔记表单
  void Function(Note)? onShowEditNoteForm;

  /// 执行搜索
  void Function(String)? onPerformSearch;

  /// 显示应用选择器
  void Function()? onShowAppSelector;

  /// 构建通知横幅（占位）
  Widget Function()? buildNotificationBanner;

  /// 构建空状态
  Widget Function()? buildEmptyState;

  /// 构建加载更多指示器
  Widget Function(AppProvider)? buildLoadMoreIndicator;

  /// 构建骨架卡片
  Widget Function()? buildSkeletonCard;

  /// 构建响应式布局（根据屏幕宽度选择布局）
  Widget buildResponsiveLayout({
    required BuildContext context,
    required bool isSearchActive,
    required List<Note> searchResults,
    required int visibleItemsCount,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
    required Function(double) onSidebarWidthChange,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 保存侧边栏宽度变化回调
        final updateSidebarWidth = onSidebarWidthChange;

        if (constraints.maxWidth < 600) {
          // 移动端布局
          return _buildMobileLayout(
            context: context,
            isSearchActive: isSearchActive,
            searchResults: searchResults,
            visibleItemsCount: visibleItemsCount,
            backgroundColor: backgroundColor,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            hintColor: hintColor,
            isDarkMode: isDarkMode,
          );
        } else if (constraints.maxWidth < 1200) {
          // 平板布局
          return _buildTabletLayout(
            context: context,
            isSearchActive: isSearchActive,
            searchResults: searchResults,
            visibleItemsCount: visibleItemsCount,
            backgroundColor: backgroundColor,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            hintColor: hintColor,
            isDarkMode: isDarkMode,
          );
        } else {
          // 桌面布局
          return _buildDesktopLayout(
            context: context,
            isSearchActive: isSearchActive,
            searchResults: searchResults,
            visibleItemsCount: visibleItemsCount,
            backgroundColor: backgroundColor,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            iconColor: iconColor,
            hintColor: hintColor,
            isDarkMode: isDarkMode,
            onSidebarWidthChange: updateSidebarWidth,
          );
        }
      },
    );
  }

  /// 移动端布局
  Widget _buildMobileLayout({
    required BuildContext context,
    required bool isSearchActive,
    required List<Note> searchResults,
    required int visibleItemsCount,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
  }) {
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isDesktop ? null : const Sidebar(),
      drawerEdgeDragWidth: isDesktop ? null : MediaQuery.of(context).size.width * 0.2,
      appBar: _buildMobileAppBar(
        context: context,
        isSearchActive: isSearchActive,
        backgroundColor: backgroundColor,
        cardColor: cardColor,
        textColor: textColor,
        iconColor: iconColor,
        hintColor: hintColor,
        isDarkMode: isDarkMode,
        isDesktop: isDesktop,
      ),
      body: _buildMainContent(
        context: context,
        isSearchActive: isSearchActive,
        searchResults: searchResults,
        visibleItemsCount: visibleItemsCount,
        backgroundColor: backgroundColor,
        cardColor: cardColor,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        iconColor: iconColor,
        hintColor: hintColor,
        isDarkMode: isDarkMode,
      ),
      floatingActionButton: _buildResponsiveFAB(
        context: context,
        isDarkMode: isDarkMode,
      ),
    );
  }

  /// 平板布局
  Widget _buildTabletLayout({
    required BuildContext context,
    required bool isSearchActive,
    required List<Note> searchResults,
    required int visibleItemsCount,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
  }) {
    return Scaffold(
      drawer: const Sidebar(),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
      backgroundColor: backgroundColor,
      appBar: _buildResponsiveAppBar(
        context: context,
        isSearchActive: isSearchActive,
        backgroundColor: backgroundColor,
        cardColor: cardColor,
        textColor: textColor,
        iconColor: iconColor,
        hintColor: hintColor,
        isDarkMode: isDarkMode,
      ),
      body: ResponsiveContainer(
        maxWidth: 800,
        child: _buildMainContent(
          context: context,
          isSearchActive: isSearchActive,
          searchResults: searchResults,
          visibleItemsCount: visibleItemsCount,
          backgroundColor: backgroundColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          iconColor: iconColor,
          hintColor: hintColor,
          isDarkMode: isDarkMode,
        ),
      ),
      floatingActionButton: _buildResponsiveFAB(
        context: context,
        isDarkMode: isDarkMode,
      ),
    );
  }

  /// 桌面布局
  Widget _buildDesktopLayout({
    required BuildContext context,
    required bool isSearchActive,
    required List<Note> searchResults,
    required int visibleItemsCount,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
    required Function(double) onSidebarWidthChange,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // 左侧可调整宽度的侧边栏
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor,
            ),
            child: const Sidebar(isDrawer: false),
          ),
          // 可拖动的分隔条
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final newWidth = (sidebarWidth + details.delta.dx).clamp(200.0, 400.0);
                onSidebarWidthChange(newWidth);
                sidebarWidth = newWidth;
              },
              child: Container(
                width: 1,
                color: isDarkMode ? AppTheme.darkDividerColor : AppTheme.dividerColor,
              ),
            ),
          ),
          // 右侧主内容区域
          Expanded(
            child: Scaffold(
              backgroundColor: backgroundColor,
              appBar: _buildResponsiveAppBar(
                context: context,
                isSearchActive: isSearchActive,
                backgroundColor: backgroundColor,
                cardColor: cardColor,
                textColor: textColor,
                iconColor: iconColor,
                hintColor: hintColor,
                isDarkMode: isDarkMode,
                showDrawerButton: false,
              ),
              body: ResponsiveContainer(
                maxWidth: 1000,
                child: _buildMainContent(
                  context: context,
                  isSearchActive: isSearchActive,
                  searchResults: searchResults,
                  visibleItemsCount: visibleItemsCount,
                  backgroundColor: backgroundColor,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  iconColor: iconColor,
                  hintColor: hintColor,
                  isDarkMode: isDarkMode,
                ),
              ),
              floatingActionButton: _buildResponsiveFAB(
                context: context,
                isDarkMode: isDarkMode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建移动端 AppBar
  AppBar _buildMobileAppBar({
    required BuildContext context,
    required bool isSearchActive,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
    required bool isDesktop,
  }) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: isDesktop ? null : IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 10,
                height: 2,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
        onPressed: onOpenDrawer,
      ),
      title: isSearchActive
          ? Container(
              height: 40,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizationsSimple.of(context)?.searchNotes ?? '搜索笔记...',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: iconColor, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: TextStyle(color: textColor),
                onChanged: onPerformSearch,
              ),
            )
          : GestureDetector(
              onTap: onShowSortOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
      centerTitle: true,
      actions: [
        // AI洞察按钮
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 8)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(ResponsiveUtils.fontScaledBorderRadius(context, 8)),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: ResponsiveUtils.fontScaledIconSize(context, 20),
              color: AppTheme.primaryColor,
            ),
          ),
          tooltip: 'AI洞察',
          onPressed: onShowAiInsightDialog,
        ),
        SizedBox(width: ResponsiveUtils.fontScaledSpacing(context, 5)),
        // 搜索按钮
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(ResponsiveUtils.fontScaledSpacing(context, 8)),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(ResponsiveUtils.fontScaledBorderRadius(context, 8)),
            ),
            child: Icon(
              isSearchActive ? Icons.close : Icons.search,
              size: ResponsiveUtils.fontScaledIconSize(context, 20),
              color: iconColor,
            ),
          ),
          onPressed: () {
            if (isSearchActive) {
              searchController.clear();
            }
            // 触发状态变化（由主文件处理）
          },
        ),
        SizedBox(width: ResponsiveUtils.fontScaledSpacing(context, 8)),
      ],
    );
  }

  /// 构建响应式 AppBar（Tablet/Desktop）
  PreferredSizeWidget _buildResponsiveAppBar({
    required BuildContext context,
    required bool isSearchActive,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
    bool showDrawerButton = true,
  }) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: showDrawerButton
          ? IconButton(
              icon: Container(
                padding: ResponsiveUtils.responsivePadding(context, all: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: ResponsiveUtils.responsive<double>(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      height: 2,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 4)),
                    Container(
                      width: ResponsiveUtils.responsive<double>(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                      height: 2,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: onOpenDrawer,
            )
          : null,
      title: isSearchActive
          ? Container(
              height: ResponsiveUtils.responsive<double>(
                context,
                mobile: 40,
                tablet: 44,
                desktop: 48,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsive<double>(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: onPerformSearch,
                style: TextStyle(
                  color: textColor,
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizationsSimple.of(context)?.searchNotes ?? '搜索笔记...',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                  ),
                  border: InputBorder.none,
                  contentPadding: ResponsiveUtils.responsivePadding(
                    context,
                    horizontal: 16,
                    vertical: 8,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: hintColor,
                    size: ResponsiveUtils.responsiveIconSize(context, 20),
                  ),
                ),
              ),
            )
          : GestureDetector(
              onTap: onShowAppSelector,
              child: Container(
                padding: ResponsiveUtils.responsivePadding(
                  context,
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.responsiveFontSize(context, 18),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 4)),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textColor,
                      size: ResponsiveUtils.responsiveIconSize(context, 20),
                    ),
                  ],
                ),
              ),
            ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: ResponsiveUtils.responsivePadding(context, all: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSearchActive ? Icons.close : Icons.search,
              size: ResponsiveUtils.responsiveIconSize(context, 20),
              color: iconColor,
            ),
          ),
          onPressed: () {
            if (isSearchActive) {
              searchController.clear();
            }
          },
        ),
        SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 8)),
      ],
    );
  }

  /// 构建主内容区域（笔记列表）
  Widget _buildMainContent({
    required BuildContext context,
    required bool isSearchActive,
    required List<Note> searchResults,
    required int visibleItemsCount,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    required Color hintColor,
    required bool isDarkMode,
  }) {
    // 这里返回一个占位 Widget
    // 实际的笔记列表应该由 HomeNoteList 组件构建
    return Center(
      child: Text(
        '主内容区域（将由 HomeNoteList 组件替代）',
        style: TextStyle(color: textColor),
      ),
    );
  }

  /// 构建响应式悬浮操作按钮
  Widget _buildResponsiveFAB({
    required BuildContext context,
    required bool isDarkMode,
  }) {
    final fabSize = ResponsiveUtils.responsive<double>(
      context,
      mobile: 60,
      tablet: 64,
      desktop: 68,
    );

    final iconSize = ResponsiveUtils.responsive<double>(
      context,
      mobile: 32,
      tablet: 34,
      desktop: 36,
    );

    return GestureDetector(
      onTapDown: (_) => fabAnimationController.forward(),
      onTapUp: (_) => fabAnimationController.reverse(),
      onTapCancel: () => fabAnimationController.reverse(),
      child: ScaleTransition(
        scale: fabScaleAnimation,
        child: Container(
          width: fabSize,
          height: fabSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(fabSize / 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onShowAddNoteForm,
              borderRadius: BorderRadius.circular(fabSize / 2),
              splashColor: Colors.white.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
