import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/services/user_behavior_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';

/// 🧠 用户偏好可视化页面
class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final UserBehaviorService _behaviorService = UserBehaviorService();
  UserPreference? _preference;
  List<ClickRecord>? _recentClicks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final preference = await _behaviorService.getUserPreference();
    final recentClicks = await _behaviorService.getClickHistory(limit: 10);

    setState(() {
      _preference = preference;
      _recentClicks = recentClicks;
      _isLoading = false;
    });
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('确定要清除所有学习偏好数据吗？这将重置个性化推荐。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _behaviorService.clearAllData();
      if (mounted) {
        SnackBarUtils.showSuccess(context, '已清除所有数据');
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Personalization'),
        backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
        elevation: 0,
        actions: [
          if (_preference != null && _preference!.totalClicks > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearData,
              tooltip: '清除数据',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preference == null || _preference!.totalClicks == 0
              ? _buildEmptyState(isDark, theme)
              : _buildContent(isDark, theme),
    );
  }

  /// 空状态 - 极简设计
  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]?.withOpacity(0.3)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insights_outlined,
              size: 40,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start using AI-powered related notes\nto build your personalization profile',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[600] : Colors.grey[500],
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 主内容
  Widget _buildContent(bool isDark, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 总体统计
        _buildStatisticsCard(isDark, theme),
        const SizedBox(height: 16),

        // 最喜欢的标签
        _buildTopTagsCard(isDark, theme),
        const SizedBox(height: 16),

        // 最喜欢的关系类型
        _buildTopRelationTypesCard(isDark, theme),
        const SizedBox(height: 16),

        // 最近浏览
        _buildRecentClicksCard(isDark, theme),
      ],
    );
  }

  /// 统计卡片 - 🎨 精致设计
  Widget _buildStatisticsCard(bool isDark, ThemeData theme) {
    final pref = _preference!;

    return Container(
      decoration: BoxDecoration(
        // 🌈 渐变背景
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF6366F1).withOpacity(0.12),
                  const Color(0xFF8B5CF6).withOpacity(0.08),
                ]
              : [
                  const Color(0xFF6366F1).withOpacity(0.06),
                  const Color(0xFFF59E0B).withOpacity(0.04),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        // ✨ 精致阴影
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
        // 🪟 玻璃态边框
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 精致的标题
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'USAGE STATS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: isDark
                        ? AppTheme.darkTextPrimaryColor
                        : AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 📊 数据卡片
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    isDark,
                    theme,
                    icon: Icons.touch_app_rounded,
                    label: '总点击',
                    value: '${pref.totalClicks}',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    isDark,
                    theme,
                    icon: Icons.timer_outlined,
                    label: '平均时长',
                    value: '${pref.avgViewDuration.toInt()}s',
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    bool isDark,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // 🌈 渐变背景
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        // ✨ 柔和阴影
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
        // 🪟 玻璃态边框
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 💎 图标容器
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          // 📊 数值
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          // 🏷️ 标签
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Top 标签卡片 - 极简设计
  Widget _buildTopTagsCard(bool isDark, ThemeData theme) {
    final topTags = _preference!.getTopTags(10);

    if (topTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: isDark ? AppTheme.darkCardColor : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TOP TAGS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topTags.map((tag) {
                final count = _preference!.favoriteTags[tag] ?? 0;
                final percent =
                    ((count / _preference!.totalClicks) * 100).toInt();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$percent%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Top 关系类型卡片
  Widget _buildTopRelationTypesCard(bool isDark, ThemeData theme) {
    final topTypes = _preference!.getTopRelationTypes(4);

    if (topTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: isDark ? AppTheme.darkCardColor : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'RELATION TYPES',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topTypes.map((type) {
              final count = _preference!.favoriteRelationTypes[type] ?? 0;
              final percent =
                  ((count / _preference!.totalClicks) * 100).toInt();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getRelationTypeLabel(type),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getRelationTypeColor(type),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 最近浏览卡片
  Widget _buildRecentClicksCard(bool isDark, ThemeData theme) {
    if (_recentClicks == null || _recentClicks!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: isDark ? AppTheme.darkCardColor : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'RECENT ACTIVITY',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentClicks!.take(10).map((click) {
              final timeAgo = _getTimeAgo(click.timestamp);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.teal.withOpacity(0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (click.tags.isNotEmpty)
                            Text(
                              click.tags.take(2).map((t) => '#$t').join(' '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (click.relationType != null)
                            Text(
                              _getRelationTypeLabel(click.relationType!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getRelationTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'CONTINUE':
        return '📚 延续学习';
      case 'COMPLEMENT':
        return '🧩 补充知识';
      case 'COMPARE':
        return '🔄 对比分析';
      case 'QA':
        return '❓ 问答';
      case 'PRACTICE':
        return '🎯 实践';
      default:
        return type;
    }
  }

  Color _getRelationTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CONTINUE':
        return Colors.blue;
      case 'COMPLEMENT':
        return Colors.green;
      case 'COMPARE':
        return Colors.orange;
      case 'QA':
        return Colors.purple;
      case 'PRACTICE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${(diff.inDays / 7).floor()}周前';
  }
}

