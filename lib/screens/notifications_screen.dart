import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/announcement_model.dart';
import 'package:inkroot/models/reminder_notification_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/reminder_notification_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/themes/app_typography.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  final ReminderNotificationService _reminderService =
      ReminderNotificationService();

  // 🔥 统一通知列表（合并系统公告和提醒通知）
  List<UnifiedNotification> _unifiedNotifications = [];

  // 动画控制器
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 页面加载后立即刷新通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false)
            .refreshUnreadAnnouncementsCount();
        _loadAllNotifications();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// 🔥 加载所有通知（系统公告 + 提醒通知）
  Future<void> _loadAllNotifications() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 获取系统公告
      final announcements = appProvider.announcements;
      final systemNotifications = <UnifiedNotification>[];

      for (final announcement in announcements) {
        // 🔥 关键修复：使用云公告内容作为ID，与标记已读时保持一致
        final actualId = appProvider.cloudNotice?.appGg ?? announcement.id;
        final isRead = await appProvider.isAnnouncementRead(actualId);
        systemNotifications.add(
          UnifiedNotification.fromAnnouncement(
            announcement.id,
            announcement.title,
            announcement.content,
            announcement.publishDate,
            announcement.type,
            isRead,
            actionUrls: announcement.actionUrls,
            imageUrl: announcement.imageUrl,
          ),
        );
      }

      // 获取提醒通知
      final reminderNotifications =
          await _reminderService.getAllReminderNotifications();
      final reminders =
          reminderNotifications.map(UnifiedNotification.fromReminder).toList();

      // 🔥 市场主流做法：系统通知置顶，然后按已读/未读分组，最后按时间排序
      final combined = [...systemNotifications, ...reminders];
      combined.sort((a, b) {
        // 1. 系统通知优先（置顶）
        if (a.isSystemAnnouncement && !b.isSystemAnnouncement) return -1;
        if (!a.isSystemAnnouncement && b.isSystemAnnouncement) return 1;

        // 2. 同类型通知：未读优先
        if (!a.isRead && b.isRead) return -1;
        if (a.isRead && !b.isRead) return 1;

        // 3. 相同已读状态：按时间倒序
        return b.publishDate.compareTo(a.publishDate);
      });

      if (mounted) {
        setState(() {
          _unifiedNotifications = combined;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('❌ [NotificationsScreen] 加载通知失败: $e');
    }
  }

  /// 🎨 获取时间分组标签
  String _getTimeGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDay = DateTime(date.year, date.month, date.day);

    if (notificationDay == today) {
      return AppLocalizationsSimple.of(context)?.today ?? '今天';
    } else if (notificationDay == yesterday) {
      return AppLocalizationsSimple.of(context)?.yesterday ?? '昨天';
    } else if (now.difference(date).inDays < 7) {
      return AppLocalizationsSimple.of(context)?.thisWeek ?? '本周';
    } else if (now.difference(date).inDays < 30) {
      return AppLocalizationsSimple.of(context)?.thisMonth ?? '本月';
    } else {
      return AppLocalizationsSimple.of(context)?.earlier ?? '更早';
    }
  }

  /// 🎨 构建分组通知列表
  Map<String, List<UnifiedNotification>> _groupNotificationsByTime() {
    final grouped = <String, List<UnifiedNotification>>{};

    for (final notification in _unifiedNotifications) {
      final group = _getTimeGroupLabel(notification.publishDate);
      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(notification);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, isDarkMode),
      tablet: _buildTabletLayout(context, isDarkMode),
      desktop: _buildDesktopLayout(context, isDarkMode),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDarkMode) => Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        appBar: _buildResponsiveAppBar(context),
        body: _buildNotificationsList(context, isDarkMode),
      );

  Widget _buildTabletLayout(BuildContext context, bool isDarkMode) => Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        appBar: _buildResponsiveAppBar(context),
        body: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getMaxContentWidth(context),
            ),
            child: _buildNotificationsList(context, isDarkMode),
          ),
        ),
      );

  Widget _buildDesktopLayout(BuildContext context, bool isDarkMode) => Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        appBar: _buildResponsiveAppBar(context),
        body: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getMaxContentWidth(context),
            ),
            child: _buildNotificationsList(context, isDarkMode),
          ),
        ),
      );

  PreferredSizeWidget _buildResponsiveAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(
        AppLocalizationsSimple.of(context)?.notificationCenter ?? '通知中心',
        style: TextStyle(
          fontSize: ResponsiveUtils.isMobile(context) ? 28 : 34,
          fontWeight: FontWeight.w700,
          color: isDarkMode
              ? AppTheme.darkTextPrimaryColor
              : AppTheme.textPrimaryColor,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor:
          isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      actions: [
        // 🎨 应用风格按钮
        if (!_isLoading) ...[
          // 清除已读
          TextButton(
            onPressed: () => _clearReadNotifications(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              AppLocalizationsSimple.of(context)?.clear ?? '清除',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 全部已读
          TextButton(
            onPressed: () => _markAllAsRead(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              AppLocalizationsSimple.of(context)?.markAllRead ?? '全部已读',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationsList(BuildContext context, bool isDarkMode) {
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    if (_isLoading) {
      return ColoredBox(
        color: backgroundColor,
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (_unifiedNotifications.isEmpty) {
      return ColoredBox(
        color: backgroundColor,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 空状态图标
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: isDarkMode
                        ? AppTheme.primaryLightColor
                        : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizationsSimple.of(context)?.noNotifications ?? '暂无通知',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppTheme.darkTextPrimaryColor
                        : AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '您目前没有新的通知消息',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode
                        ? AppTheme.darkTextSecondaryColor
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 分组通知
    final groupedNotifications = _groupNotificationsByTime();
    final groups = [
      AppLocalizationsSimple.of(context)?.today ?? '今天',
      AppLocalizationsSimple.of(context)?.yesterday ?? '昨天',
      AppLocalizationsSimple.of(context)?.thisWeek ?? '本周',
      AppLocalizationsSimple.of(context)?.thisMonth ?? '本月',
      AppLocalizationsSimple.of(context)?.earlier ?? '更早',
    ];

    return ColoredBox(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: () => _refreshAllNotifications(context),
        color: AppTheme.primaryColor,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.responsiveSpacing(context, 12),
              bottom: ResponsiveUtils.responsiveSpacing(context, 24),
            ),
            itemCount: groups.where(groupedNotifications.containsKey).length,
            itemBuilder: (context, index) {
              final group = groups
                  .where(groupedNotifications.containsKey)
                  .elementAt(index);
              final notifications = groupedNotifications[group]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分组标题
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          ResponsiveUtils.responsiveSpacing(context, 20),
                      vertical: ResponsiveUtils.responsiveSpacing(context, 12),
                    ),
                    child: Text(
                      group,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.responsiveFontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppTheme.darkTextSecondaryColor
                            : AppTheme.textSecondaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // 该组的通知列表
                  ...notifications.asMap().entries.map(
                        (entry) => _buildUnifiedNotificationCard(
                          context,
                          entry.value,
                          isDarkMode,
                          index: entry.key,
                        ),
                      ),
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(context, 8),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 🎨 应用风格通知卡片（带滑动操作）
  Widget _buildUnifiedNotificationCard(
    BuildContext context,
    UnifiedNotification notification,
    bool isDarkMode, {
    int index = 0,
  }) {
    // 应用配色
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.backgroundColor;

    // 🎨 根据通知类型选择颜色
    final Color accentColor;
    final Color iconBgColor;
    if (notification.isReminder) {
      accentColor = AppTheme.accentColor;
      iconBgColor = isDarkMode
          ? AppTheme.accentColor.withOpacity(0.2)
          : AppTheme.accentColor.withOpacity(0.15);
    } else {
      accentColor = AppTheme.primaryColor;
      iconBgColor = isDarkMode
          ? AppTheme.primaryColor.withOpacity(0.2)
          : AppTheme.primaryColor.withOpacity(0.15);
    }

    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveSpacing(context, 16),
          vertical: ResponsiveUtils.responsiveSpacing(context, 6),
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(context, 16),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(
          right: ResponsiveUtils.responsiveSpacing(context, 24),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: ResponsiveUtils.responsiveIconSize(context, 24),
        ),
      ),
      confirmDismiss: (direction) async {
        if (notification.isReminder) {
          // 触觉反馈
          HapticFeedback.mediumImpact();
          return true;
        }
        return false; // 系统公告不允许滑动删除
      },
      onDismissed: (direction) async {
        if (notification.isReminder) {
          await _reminderService.deleteReminderNotification(notification.id);
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          await appProvider.refreshUnreadAnnouncementsCount();
          _loadAllNotifications();
          if (mounted) {
            SnackBarUtils.showSuccess(
              context,
              AppLocalizationsSimple.of(context)?.notificationDeleted ??
                  '已删除通知',
            );
          }
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + index * 50),
        curve: Curves.easeOut,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        ),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.responsiveSpacing(context, 16),
            vertical: ResponsiveUtils.responsiveSpacing(context, 6),
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsiveSpacing(context, 16),
            ),
            boxShadow: AppTheme.neuCardShadow(isDark: isDarkMode),
            border: !notification.isRead
                ? Border.all(
                    color: accentColor.withOpacity(0.2),
                    width: 1.5,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _handleNotificationTap(context, notification);
              },
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.responsiveSpacing(context, 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveUtils.responsiveSpacing(context, 16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎨 应用风格图标
                    Container(
                      width: ResponsiveUtils.responsiveIconSize(context, 48),
                      height: ResponsiveUtils.responsiveIconSize(context, 48),
                      decoration: BoxDecoration(
                        color: notification.isRead ? surfaceColor : iconBgColor,
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.responsiveSpacing(context, 12),
                        ),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification),
                        color: notification.isRead
                            ? secondaryTextColor
                            : accentColor,
                        size: ResponsiveUtils.responsiveIconSize(context, 24),
                      ),
                    ),

                    SizedBox(
                      width: ResponsiveUtils.responsiveSpacing(context, 14),
                    ),

                    // 内容区域
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题和时间
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.responsiveFontSize(
                                      context,
                                      16,
                                    ),
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: notification.isRead
                                        ? secondaryTextColor
                                        : textColor,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveUtils.responsiveSpacing(
                                  context,
                                  8,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(notification.publishDate),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.responsiveFontSize(
                                    context,
                                    12,
                                  ),
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height: ResponsiveUtils.responsiveSpacing(
                              context,
                              6,
                            ),
                          ),

                          // 内容
                          Text(
                            notification.content,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(
                                context,
                                14,
                              ),
                              color: secondaryTextColor,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // 未读指示器
                    if (!notification.isRead) ...[
                      SizedBox(
                        width: ResponsiveUtils.responsiveSpacing(context, 8),
                      ),
                      Container(
                        width: ResponsiveUtils.responsiveIconSize(context, 10),
                        height: ResponsiveUtils.responsiveIconSize(context, 10),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 格式化相对时间（iOS风格）
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return _formatDate(dateTime);
    }
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Announcement announcement,
    bool isRead,
    bool isDarkMode,
  ) {
    final backgroundColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    const accentColor = Colors.teal;
    final titleColor =
        isRead ? (isDarkMode ? Colors.white : Colors.black87) : accentColor;

    final contentColor =
        isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final borderRadius = ResponsiveUtils.responsive<double>(
      context,
      mobile: 12,
      tablet: 16,
      desktop: 20,
    );

    final iconSize = ResponsiveUtils.responsiveIconSize(context, 44);

    return Container(
      margin: ResponsiveUtils.responsivePadding(
        context,
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isRead ? null : Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: ResponsiveUtils.responsiveSpacing(context, 8),
            offset: Offset(0, ResponsiveUtils.responsiveSpacing(context, 2)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: () => _showAnnouncementDetails(context, announcement),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: ResponsiveUtils.responsivePadding(context, all: 16),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.grey.shade200
                        : accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadius * 0.75),
                  ),
                  child: Icon(
                    _getAnnouncementIcon(announcement.type),
                    color: isRead ? Colors.grey.shade500 : accentColor,
                    size: ResponsiveUtils.responsiveIconSize(context, 22),
                  ),
                ),

                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 12)),

                // 中间内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: AppTypography.getTitleStyle(
                                context,
                                fontSize: 16,
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w600,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveUtils.responsiveSpacing(
                              context,
                              8,
                            ),
                          ),
                          Text(
                            _formatDate(announcement.publishDate),
                            style: AppTypography.getCaptionStyle(
                              context,
                              color: contentColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context, 4),
                      ),
                      Text(
                        announcement.content,
                        style: AppTypography.getBodyStyle(
                          context,
                          fontSize: 14,
                          color: contentColor,
                          height: 1.3,
                        ),
                        maxLines: ResponsiveUtils.isMobile(context) ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 右侧状态指示器
                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 12)),
                Column(
                  children: [
                    if (!isRead)
                      Container(
                        width: ResponsiveUtils.responsiveIconSize(context, 8),
                        height: ResponsiveUtils.responsiveIconSize(context, 8),
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      SizedBox(
                        width: ResponsiveUtils.responsiveIconSize(context, 8),
                        height: ResponsiveUtils.responsiveIconSize(context, 8),
                      ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(context, 8),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: ResponsiveUtils.responsiveIconSize(context, 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 获取统一通知的图标
  IconData _getNotificationIcon(UnifiedNotification notification) {
    if (notification.isReminder) {
      return Icons.alarm; // 提醒通知用闹钟图标
    } else {
      // 系统公告根据类型选择图标
      switch (notification.announcementType) {
        case 'update':
          return Icons.system_update_outlined;
        case 'info':
          return Icons.info_outline;
        case 'event':
          return Icons.event_outlined;
        case 'warning':
          return Icons.warning_amber_outlined;
        default:
          return Icons.notifications_none;
      }
    }
  }

  IconData _getAnnouncementIcon(String type) {
    switch (type) {
      case 'update':
        return Icons.system_update_outlined;
      case 'info':
        return Icons.info_outline;
      case 'event':
        return Icons.event_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  /// 🔥 处理通知点击（大厂逻辑：点击后标记已读 + 清除提醒）
  Future<void> _handleNotificationTap(
    BuildContext context,
    UnifiedNotification notification,
  ) async {
    if (notification.isReminder) {
      // 🎯 提醒通知：标记已读 + 清除笔记提醒时间 + 跳转笔记
      await _reminderService.markAsClicked(notification.id);

      // 🔥 清除笔记的提醒时间（包括数据库和系统通知）
      if (notification.noteId != null) {
        try {
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          await appProvider.cancelNoteReminder(notification.noteId!);
          debugPrint('✅ [NotificationsScreen] 已清除笔记提醒: ${notification.noteId}');
        } catch (e) {
          debugPrint('⚠️ [NotificationsScreen] 清除提醒失败: $e');
        }
      }

      // 🎯 刷新未读数量和通知列表（在跳转前完成）
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.refreshUnreadAnnouncementsCount();
        await _loadAllNotifications();
      }

      // 跳转到对应笔记
      if (mounted && notification.noteId != null) {
        context.push('/note/${notification.noteId}');
      }
    } else {
      // 系统公告：显示详情并标记为已读
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final announcement = appProvider.announcements.firstWhere(
        (a) => a.id == notification.id,
        orElse: () => Announcement(
          id: notification.id,
          title: notification.title,
          content: notification.content,
          type: notification.announcementType ?? 'info',
          publishDate: notification.publishDate,
        ),
      );
      _showAnnouncementDetails(context, announcement);
      // 重新加载通知列表
      await _loadAllNotifications();
    }
  }

  /// 🔥 刷新所有通知
  Future<void> _refreshAllNotifications(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.refreshAnnouncements();
      await _loadAllNotifications();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.refreshNotificationsFailed ??
              '刷新通知失败，请检查网络连接',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// 🔥 标记所有通知为已读（包括系统公告和提醒通知）
  Future<void> _markAllAsRead(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      // 标记系统公告为已读
      await appProvider.markAllAnnouncementsAsRead();
      // 标记提醒通知为已读
      await _reminderService.markAllAsRead();
      // 🎯 刷新未读数量（更新侧边栏红点）
      await appProvider.refreshUnreadAnnouncementsCount();
      // 重新加载通知列表
      await _loadAllNotifications();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已全部标记为已读');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '操作失败');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 🔥 清除已读通知（大厂逻辑：只清除已读，保留未读）
  Future<void> _clearReadNotifications(BuildContext context) async {
    if (_isLoading) return;

    // 🎯 统计已读通知数量
    final readCount = _unifiedNotifications.where((n) => n.isRead).length;

    if (readCount == 0) {
      SnackBarUtils.showInfo(
        context,
        AppLocalizationsSimple.of(context)?.noReadNotificationsToDelete ??
            '没有已读通知可清除',
      );
      return;
    }

    // 🎯 应用风格确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizationsSimple.of(context)?.clearReadNotifications ??
                '清除已读通知',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? AppTheme.darkTextPrimaryColor
                  : AppTheme.textPrimaryColor,
            ),
          ),
          content: Text(
            AppLocalizationsSimple.of(context)
                    ?.confirmClearReadNotifications(readCount) ??
                '确定要清除 $readCount 条已读通知吗？此操作不可恢复。',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? AppTheme.darkTextSecondaryColor
                  : AppTheme.textSecondaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context, false);
              },
              child: Text(
                '取消',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? AppTheme.primaryLightColor
                      : AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, true);
              },
              child: Text(
                '确定',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 清除已读的提醒通知
      final readReminders =
          _unifiedNotifications.where((n) => n.isReminder && n.isRead).toList();

      for (final notification in readReminders) {
        await _reminderService.deleteReminderNotification(notification.id);
      }

      // 注意：系统公告不删除，只是标记为已读

      // 🎯 刷新未读数量（虽然清除的是已读，但总数变了）
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.refreshUnreadAnnouncementsCount();

      // 重新加载通知列表
      await _loadAllNotifications();

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          AppLocalizationsSimple.of(context)?.notificationsCleared(readCount) ??
              '已清除 $readCount 条通知',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.clearFailed ?? '清除失败',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAnnouncementDetails(
    BuildContext context,
    Announcement announcement,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final accentColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    final dialogWidth = ResponsiveUtils.responsive<double>(
      context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 500,
      desktop: 600,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(context, 14),
          ),
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              Container(
                padding: ResponsiveUtils.responsivePadding(
                  context,
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Icon(
                      _getAnnouncementIcon(announcement.type),
                      color: accentColor,
                      size: ResponsiveUtils.responsiveIconSize(context, 24),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.responsiveSpacing(context, 12),
                    ),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: AppTypography.getTitleStyle(
                          context,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 分割线
              Container(
                height: 1,
                color: isDarkMode
                    ? AppTheme.darkDividerColor
                    : AppTheme.dividerColor,
                margin: ResponsiveUtils.responsivePadding(
                  context,
                  horizontal: 24,
                ),
              ),

              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  padding: ResponsiveUtils.responsivePadding(
                    context,
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 发布日期
                      Text(
                        _formatDate(announcement.publishDate),
                        style: AppTypography.getCaptionStyle(
                          context,
                          color: isDarkMode
                              ? AppTheme.darkTextSecondaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context, 12),
                      ),

                      // 内容
                      Text(
                        announcement.content,
                        style: AppTypography.getBodyStyle(
                          context,
                          fontSize: 14,
                          color: isDarkMode
                              ? AppTheme.darkTextPrimaryColor
                              : AppTheme.textPrimaryColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 按钮区域
              Container(
                padding: ResponsiveUtils.responsivePadding(
                  context,
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    if (announcement.actionUrls != null &&
                        announcement.actionUrls!.isNotEmpty)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            final isAndroid = Theme.of(context).platform ==
                                TargetPlatform.android;
                            final url = isAndroid
                                ? announcement.actionUrls!['android']
                                : announcement.actionUrls!['ios'];

                            if (url != null) {
                              launchUrl(Uri.parse(url));
                            }
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: ResponsiveUtils.responsivePadding(
                              context,
                              vertical: 12,
                            ),
                            minimumSize: Size(
                              0,
                              ResponsiveUtils.responsiveSpacing(context, 44),
                            ),
                          ),
                          child: Text(
                            announcement.type == 'update'
                                ? (AppLocalizationsSimple.of(context)
                                        ?.updateNow ??
                                    '立即更新')
                                : (AppLocalizationsSimple.of(context)
                                        ?.viewDetails ??
                                    '查看详情'),
                            style: AppTypography.getButtonStyle(
                              context,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    if (announcement.actionUrls != null &&
                        announcement.actionUrls!.isNotEmpty)
                      Container(
                        width: 1,
                        height: ResponsiveUtils.responsiveSpacing(context, 20),
                        color: isDarkMode
                            ? AppTheme.darkDividerColor
                            : AppTheme.dividerColor,
                        margin: ResponsiveUtils.responsivePadding(
                          context,
                          horizontal: 8,
                        ),
                      ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          // 🔥 关闭对话框
                          Navigator.pop(context);

                          // 🔥 标记为已读
                          final appProvider =
                              Provider.of<AppProvider>(context, listen: false);
                          final actualId =
                              appProvider.cloudNotice?.appGg ?? announcement.id;
                          await appProvider.markAnnouncementAsRead(actualId);

                          // 🎯 刷新未读数量
                          await appProvider.refreshUnreadAnnouncementsCount();

                          // 🔥 重新加载通知列表（刷新UI显示已读状态）
                          await _loadAllNotifications();
                        },
                        style: TextButton.styleFrom(
                          padding: ResponsiveUtils.responsivePadding(
                            context,
                            vertical: 12,
                          ),
                          minimumSize: Size(
                            0,
                            ResponsiveUtils.responsiveSpacing(context, 44),
                          ),
                        ),
                        child: Text(
                          '确定',
                          style: AppTypography.getButtonStyle(
                            context,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 🔥 标记为已读逻辑已移到确定按钮的 onPressed 中
  }
}
