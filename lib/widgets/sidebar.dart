import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/sidebar_config.dart';
import 'package:inkroot/models/user_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:inkroot/widgets/cached_avatar.dart';
import 'package:inkroot/widgets/heatmap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 添加一个动画过渡效果组件
class AnimatedMenuWidget extends StatefulWidget {
  const AnimatedMenuWidget({
    required this.child,
    required this.index,
    super.key,
  });
  final Widget child;
  final int index;

  @override
  State<AnimatedMenuWidget> createState() => _AnimatedMenuWidgetState();
}

class _AnimatedMenuWidgetState extends State<AnimatedMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50), // 添加级联效果
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // 自动开始动画
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      );
}

class Sidebar extends StatefulWidget {
  final bool isDrawer;
  
  const Sidebar({super.key, this.isDrawer = true});
  
  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // 🎯 热力图显示状态现在从AppConfig读取（统一管理）
  bool _isLoading = true; // 是否正在加载偏好设置
  
  @override
  void initState() {
    super.initState();
    // 🎯 不再需要单独加载热力图偏好，直接从AppConfig读取
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  

  // 🎯 大厂级丝滑导航：侧边栏与页面切换的黄金节奏（精确调试版）
  // 📊 动画协调说明（Material Design + 实测最佳参数）：
  // - Drawer关闭动画：约250ms（系统默认）
  // - 页面切换动画：400ms（从容的节奏）
  // - 🔥 黄金延迟：120ms（让侧边栏先收回约50%，建立节奏感）
  // - 视觉效果：侧边栏从容收回→页面平滑推进→丝滑衔接✨
  //
  // 为什么是120ms？（经过精确测试的最佳值）
  // - 50ms：太快，两个动画冲突，有闪动感 ❌
  // - 80ms：略快，节奏不够从容 ⚠️
  // - 120ms：侧边栏收回约50%，节奏刚好，最丝滑 ✅
  // - 150ms：稍慢，但也可接受 ⚠️
  // - 200ms：太慢，有停顿感 ❌
  //
  // 时间轴（最佳节奏）：
  // 0ms → 侧边栏开始收回（用户看到动作）
  // 120ms → 页面开始切换（侧边栏已收回50%）
  //         此时用户已看清侧边栏收回
  //         页面开始平滑推进
  // 250ms → 侧边栏完全收回
  // 520ms → 页面切换完成（400ms动画）
  // 总时长：520ms（从容、丝滑、无闪动）
  void _navigateWithSmoothTransition({
    required BuildContext context,
    required String path,
    bool isPushRoute = false,
  }) {
    // 1️⃣ 移动端：关闭侧边栏（触发收回动画）
    if (widget.isDrawer) {
      Navigator.of(context).pop();
    }

  // 2️⃣ 等待后开始页面切换
  // 移动端：等待120ms让侧边栏先收回约50%
  // 桌面端：等待50ms避免Navigator锁定
  final delay = widget.isDrawer ? 120 : 50;
  Future.delayed(Duration(milliseconds: delay), () {
    if (context.mounted) {
      if (isPushRoute) {
        // 🎯 辅助页面（设置/帮助）：可返回
        context.push(path);
      } else {
        // 🎯 主Tab页面（首页/标签/图谱）：平级切换，使用go而不是replace
        context.go(path);
      }
    }
  });
}

  // 构建菜单项
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String path,
    required bool isSelected,
    required int index, // 添加索引参数
    bool isPushRoute = false, // 🔥 新增参数：是否使用push而不是replace
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 🎯 大厂标准：图标和文字使用统一颜色
    final itemColor = isSelected
        ? (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor)
        : (isDarkMode
            ? AppTheme.darkTextPrimaryColor.withOpacity(0.85)
            : AppTheme.textPrimaryColor.withOpacity(0.85));
    final bgColor = isSelected
        ? (isDarkMode
            ? AppTheme.primaryLightColor.withOpacity(0.15)
            : AppTheme.primaryColor.withOpacity(0.1))
        : Colors.transparent;

    final menuItem = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (isDarkMode
                          ? AppTheme.primaryLightColor
                          : AppTheme.primaryColor)
                      .withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 如果不是当前选中项，才执行导航
            if (!isSelected) {
              // 🎯 使用新的丝滑导航方法
              _navigateWithSmoothTransition(
                context: context,
                path: path,
                isPushRoute: isPushRoute,
              );
            } else {
              // 🔧 如果是当前页面，只在移动端（drawer模式）关闭侧边栏
              // 桌面端不需要关闭，避免调用pop导致导航栈为空
              if (widget.isDrawer) {
                Navigator.of(context).pop();
              }
            }
          },
          splashColor:
              (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor)
                  .withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: itemColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: AppTextStyles.titleMedium(
                    context,
                    color: itemColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 使用动画包装菜单项
    return AnimatedMenuWidget(
      index: index,
      child: menuItem,
    );
  }

  // 🎯 动态生成菜单项（基于用户配置）
  List<Widget> _buildDynamicMenuItems(
    BuildContext context,
    String currentPath,
    SidebarConfig config,
  ) {
    final items = <Widget>[];
    final visibleMenuItems = config.getOrderedVisibleItems();
    
    // 从索引3开始（0-2被头部占用）
    int menuIndex = 3;
    
    for (final menuItem in visibleMenuItems) {
      // 决定是否使用 push 路由（辅助功能如"帮助"和"设置"）
      final isPushRoute = menuItem.id == 'help' || menuItem.id == 'settings';
      
      items.add(
        _buildMenuItem(
          context: context,
          icon: menuItem.icon as IconData,
          title: _getMenuItemTitle(context, menuItem),
          path: menuItem.path,
          isSelected: currentPath == menuItem.path,
          index: menuIndex++,
          isPushRoute: isPushRoute,
        ),
      );
    }
    
    return items;
  }

  // 获取菜单项的本地化标题
  String _getMenuItemTitle(BuildContext context, SidebarMenuItem menuItem) {
    final l10n = AppLocalizationsSimple.of(context);
    
    switch (menuItem.id) {
      case 'all_notes':
        return l10n?.allNotes ?? '全部笔记';
      case 'random_review':
        return l10n?.randomReview ?? '随机回顾';
      case 'all_tags':
        return l10n?.allTags ?? '全部标签';
      case 'knowledge_graph':
        return l10n?.knowledgeGraph ?? '知识图谱';
      case 'help':
        return l10n?.help ?? '帮助中心';
      case 'settings':
        return l10n?.settings ?? '设置';
      default:
        return menuItem.label;
    }
  }

  // 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor =
        isDarkMode ? Colors.grey[400] : AppTheme.textSecondaryColor;

    // 显示选项对话框
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.red.shade900.withOpacity(0.2)
                      : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizationsSimple.of(context)?.logoutButton ?? '退出登录',
                style: AppTextStyles.headlineSmall(
                  context,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizationsSimple.of(context)?.logoutDataPrompt ??
                    '退出登录时如何处理本地数据？',
                style: AppTextStyles.bodyMedium(
                  context,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // 清空本地数据
                        _processLogout(
                          context,
                          appProvider,
                          keepLocalData: false,
                        );
                      },
                      child: Text(
                        AppLocalizationsSimple.of(context)?.clearLocalData ??
                            '清空本地数据',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // 保留本地数据
                        _processLogout(
                          context,
                          appProvider,
                          keepLocalData: true,
                        );
                      },
                      child: Text(
                        AppLocalizationsSimple.of(context)?.keepLocalData ??
                            '保留本地数据',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processLogout(
    BuildContext context,
    AppProvider appProvider, {
    required bool keepLocalData,
  }) {
    // 先检查是否有未同步的笔记
    appProvider.logout(keepLocalData: keepLocalData).then((result) {
      final (success, message) = result;

      if (!success && message != null) {
        // 有未同步的笔记，显示确认对话框
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.logoutConfirm ?? '确认退出',
                    style: AppTextStyles.headlineSmall(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium(
                      context,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            AppLocalizationsSimple.of(context)?.cancel ?? '取消',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // 用户确认退出，强制退出
                            Navigator.pop(context);
                            // 强制退出登录
                            appProvider
                                .logout(
                              force: true,
                              keepLocalData: keepLocalData,
                            )
                                .then((_) {
                              context.go('/login');
                            });
                          },
                          child: Text(
                            AppLocalizationsSimple.of(context)?.confirmLogout ??
                                '确定退出',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (success) {
        // 没有未同步的笔记，直接退出
        context.go('/login');
      } else {
        // 退出失败，显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ??
                  (AppLocalizationsSimple.of(context)?.logoutFailed ??
                      '退出登录失败'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // 构建侧边栏头像（使用新的缓存组件）
  Widget _buildSidebarAvatar(User user, BuildContext context) =>
      CachedAvatar.fromUser(
        user,
      );

  // 构建默认侧边栏头像

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final appProvider = Provider.of<AppProvider>(context);
    final isLoggedIn = appProvider.isLoggedIn;
    final user = appProvider.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final dividerColor =
        isDarkMode ? AppTheme.darkDividerColor : Colors.grey.shade200;

    return Drawer(
      // 🔥 大厂标准：侧边栏宽度
      // - 手机：屏幕宽度的 80%
      // - 最大不超过 360dp（Material Design 3 规范）
      width: min(MediaQuery.of(context).size.width * 0.8, 360),
      backgroundColor: isDarkMode
          ? AppTheme.darkSurfaceColor.withOpacity(0.97) // 稍微调整不透明度
          : Colors.white.withOpacity(0.97), // 稍微调整不透明度
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 增强模糊效果
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户信息区域 - 与热力图同样的宽度和样式
                  // 🎯 个人中心组件 - 整体受 showProfile 控制
                  if (appProvider.appConfig.sidebarConfig.showProfile)
                    AnimatedMenuWidget(
                      index: 0,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.neuCardShadow(isDark: isDarkMode),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 左侧：登录按钮或用户名
                            if (!isLoggedIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // 使用统一的丝滑导航方法
                                    _navigateWithSmoothTransition(
                                      context: context,
                                      path: '/login',
                                      isPushRoute: false,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.login_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizationsSimple.of(context)
                                                  ?.login ??
                                              '登录',
                                          style: AppTextStyles.labelLarge(
                                            context,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  splashColor: (isDarkMode
                                          ? AppTheme.primaryLightColor
                                          : AppTheme.primaryColor)
                                      .withOpacity(0.1),
                                  highlightColor: (isDarkMode
                                          ? AppTheme.primaryLightColor
                                          : AppTheme.primaryColor)
                                      .withOpacity(0.05),
                                  onTap: () {
                                    // 点击个人信息栏跳转到账户信息页面
                                    if (widget.isDrawer) {
                                      Navigator.pop(context); // 移动端关闭侧边栏
                                    }
                                    // 添加短暂延迟避免Navigator锁定
                                    Future.delayed(Duration(milliseconds: widget.isDrawer ? 300 : 50), () {
                                      if (context.mounted) {
                                        context.go('/account-info');
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    child: Consumer<AppProvider>(
                                      builder: (context, appProvider, child) {
                                        final currentUser = appProvider.user;
                                        return Row(
                                          children: [
                                            // 用户头像 - 支持真实头像显示
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppTheme.primaryColor
                                                    .withOpacity(0.1),
                                                border: Border.all(
                                                  color: AppTheme.primaryColor
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              child: ClipOval(
                                                child: _buildSidebarAvatar(
                                                  user!,
                                                  context,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    currentUser?.nickname
                                                                ?.isNotEmpty ??
                                                            false
                                                        ? currentUser!.nickname!
                                                        : (currentUser
                                                                ?.username ??
                                                            ''),
                                                    style: AppTextStyles
                                                        .titleMedium(
                                                      context,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDarkMode
                                                          ? AppTheme
                                                              .darkTextPrimaryColor
                                                          : AppTheme
                                                              .textPrimaryColor,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: appProvider
                                                                  .isLoggedIn
                                                              ? Colors.green
                                                              : Colors.red,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        appProvider.isLoggedIn
                                                            ? (AppLocalizationsSimple
                                                                    .of(
                                                                  context,
                                                                )?.online ??
                                                                '在线')
                                                            : (AppLocalizationsSimple
                                                                    .of(
                                                                  context,
                                                                )?.offline ??
                                                                '离线'),
                                                        style: AppTextStyles
                                                            .bodySmall(
                                                          context,
                                                          color: appProvider
                                                                  .isLoggedIn
                                                              ? Colors.green
                                                              : Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 箭头图标提示
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: isDarkMode
                                                  ? AppTheme
                                                      .darkTextSecondaryColor
                                                  : AppTheme.textSecondaryColor,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // 右侧：通知和设置图标
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Consumer<AppProvider>(
                                builder: (context, provider, _) {
                                  // 🎨 iOS风格通知按钮
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.notifications_outlined,
                                          color: isDarkMode
                                              ? AppTheme.primaryLightColor
                                              : AppTheme.primaryColor,
                                        ),
                                        onPressed: () {
                                          // 使用统一的丝滑导航方法
                                          _navigateWithSmoothTransition(
                                            context: context,
                                            path: '/notifications',
                                            isPushRoute: true,
                                          );
                                        },
                                      ),
                                      // iOS风格数字徽章
                                      if (provider.unreadAnnouncementsCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  provider.unreadAnnouncementsCount >
                                                          9
                                                      ? 6
                                                      : 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFF3B30,
                                              ), // iOS红色
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isDarkMode
                                                    ? const Color(0xFF1C1C1E)
                                                    : Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            child: Center(
                                              child: Text(
                                                provider.unreadAnnouncementsCount >
                                                        99
                                                    ? '99+'
                                                    : provider
                                                        .unreadAnnouncementsCount
                                                        .toString(),
                                                style: AppTextStyles.labelSmall(
                                                  context,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              // 🎨 设置按钮
                              IconButton(
                                icon: Icon(
                                  Icons.settings_outlined,
                                  color: isDarkMode
                                      ? AppTheme.primaryLightColor
                                      : AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  // 使用统一的丝滑导航方法
                                  _navigateWithSmoothTransition(
                                    context: context,
                                    path: '/settings',
                                    isPushRoute: true,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 热力图 - 极简版（参考GitHub/Notion设计）- 整体控制显示/隐藏
                  if (!_isLoading && appProvider.appConfig.sidebarConfig.showHeatmap)
                    AnimatedMenuWidget(
                      index: 1,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.neuCardShadow(isDark: isDarkMode),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: (isDarkMode
                                            ? AppTheme.primaryLightColor
                                            : AppTheme.primaryColor)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.insights_rounded,
                                    size: 11,
                                    color: isDarkMode
                                        ? AppTheme.primaryLightColor
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    AppLocalizationsSimple.of(context)
                                            ?.activityLog ??
                                        '活动记录',
                                    style: AppTextStyles.custom(
                                      context,
                                      13,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? AppTheme.darkTextPrimaryColor
                                          : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // 热力图
                            const SizedBox(height: 8),
                            Consumer<AppProvider>(
                              builder: (context, appProvider, _) => Heatmap(
                                notes: appProvider.notes,
                                cellColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                activeColor: isDarkMode
                                    ? AppTheme.primaryLightColor
                                        .withOpacity(0.9)
                                    : AppTheme.primaryColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 分类标题
                  AnimatedMenuWidget(
                    index: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        AppLocalizationsSimple.of(context)?.functionMenu ??
                            '功能菜单',
                        style: AppTextStyles.bodyMedium(
                          context,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppTheme.darkTextPrimaryColor
                                  .withOpacity(0.8) // 使用更亮的颜色提高对比度
                              : AppTheme.textSecondaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // 🎯 动态菜单区（根据用户配置生成）
                  // 参考Apple/Notion：允许用户自定义侧边栏显示
                  ..._buildDynamicMenuItems(
                    context,
                    currentPath,
                    appProvider.appConfig.sidebarConfig,
                  ),

                  // 添加间距，使退出登录按钮位于底部
                  const SizedBox(height: 32),

                  // 退出登录按钮，只在登录模式下显示
                  if (isLoggedIn)
                    AnimatedMenuWidget(
                      index: 8,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // 显示退出登录对话框
                              _showLogoutDialog(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizationsSimple.of(context)
                                            ?.logoutButton ??
                                        '退出登录',
                                    style: AppTextStyles.titleMedium(
                                      context,
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
}
