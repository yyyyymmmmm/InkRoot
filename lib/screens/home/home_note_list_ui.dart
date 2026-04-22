// 笔记列表 UI 组件（从 home_screen.dart 拆分）
// 职责：构建笔记列表相关的 UI 组件

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_theme.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:provider/provider.dart';

/// 笔记列表 UI 组件助手类
///
/// 负责构建：
/// 1. 空状态（没有笔记时的提示）
/// 2. 通知横幅（未读消息提醒）
/// 3. 骨架屏（加载占位符）
/// 4. 加载更多指示器
class HomeNoteListUI {
  /// 构建空状态
  static Widget buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final cardShadow = AppTheme.neuCardShadow(isDark: isDarkMode);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(60),
              boxShadow: cardShadow,
            ),
            child: Center(
              child: Icon(
                Icons.note_add_rounded,
                size: 48,
                color: iconColor.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizationsSimple.of(context)?.noNotesYet ?? '还没有笔记',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizationsSimple.of(context)?.clickToCreate ?? '点击右下角的按钮开始创建',
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建通知横幅
  static Widget buildNotificationBanner(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context);

    // 如果没有未读通知，则不显示通知栏
    if (appProvider.unreadAnnouncementsCount <= 0) {
      return const SizedBox.shrink();
    }

    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = Colors.blue.shade600;
    final iconColor = Colors.blue.shade600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (context.mounted) {
              context.pushNamed('notifications');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.black).withOpacity(isDarkMode ? 0.3 : 0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizationsSimple.of(context)?.unreadNotificationsCount(appProvider.unreadAnnouncementsCount) ??
                        '${appProvider.unreadAnnouncementsCount}条未读信息',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
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

  /// 构建骨架屏占位符
  static Widget buildSkeletonCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题骨架
          Container(
            height: 16,
            width: double.infinity * 0.7,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // 内容骨架
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: double.infinity * 0.85,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载更多指示器
  static Widget buildLoadMoreIndicator(BuildContext context, AppProvider appProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;

    // 如果还有更多数据，显示加载中
    if (appProvider.hasMoreData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizationsSimple.of(context)?.loading ?? '加载中...',
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ],
        ),
      );
    }

    // 没有更多数据，显示已加载全部
    if (appProvider.notes.length > 10) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          (AppLocalizationsSimple.of(context)?.loadedAll ?? '已加载全部 {count} 条笔记').replaceAll('{count}', '${appProvider.notes.length}'),
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.6),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
