import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/sidebar_config.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:provider/provider.dart';

/// 侧边栏自定义设置页面
///
/// 设计理念：
/// - 简洁优雅：遵循Apple/Notion设计规范
/// - 直观操作：拖拽排序+开关切换
/// - 实时预览：修改立即生效
class SidebarCustomizationScreen extends StatefulWidget {
  const SidebarCustomizationScreen({super.key});

  @override
  State<SidebarCustomizationScreen> createState() =>
      _SidebarCustomizationScreenState();
}

class _SidebarCustomizationScreenState
    extends State<SidebarCustomizationScreen> {
  late List<SidebarMenuItem> _items;
  late Set<String> _visibleIds;
  late bool _showHeatmap;
  late bool _showProfile; // 是否显示个人中心
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final config = appProvider.appConfig.sidebarConfig;

    // 初始化状态
    _showHeatmap = config.showHeatmap;
    _showProfile = config.showProfile;
    _visibleIds = Set<String>.from(config.visibleItems);
    _items = config.getOrderedVisibleItems();

    // 确保所有菜单项都在列表中（包括隐藏的）
    for (final menuItem in SidebarMenuItem.values) {
      if (!_items.any((item) => item.id == menuItem.id)) {
        _items.add(menuItem);
      }
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    // 🎯 验证：个人中心和设置菜单至少显示一个
    final settingsVisible = _visibleIds.contains('settings');
    if (!_showProfile && !settingsVisible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizationsSimple.of(context)?.profileOrSettingsRequired ??
                    '个人中心和设置至少保留一个',
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final newConfig = appProvider.appConfig.sidebarConfig.copyWith(
      showHeatmap: _showHeatmap,
      showProfile: _showProfile,
      visibleItems: _visibleIds.toList(),
      itemOrder: _items.map((item) => item.id).toList(),
    );

    // 更新配置
    await appProvider.updateConfig(
      appProvider.appConfig.copyWith(sidebarConfig: newConfig),
    );

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizationsSimple.of(context)?.sidebarConfigSaved ??
                    '侧边栏配置已保存',
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color:
                isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizationsSimple.of(context)?.customizeSidebar ?? '自定义侧边栏',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveConfig,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            // 头部组件显示开关
            _buildSection(
              title: AppLocalizationsSimple.of(context)?.headerComponents ??
                  '头部组件',
              children: [
                _buildSwitchTile(
                  icon: Icons.account_circle_outlined,
                  title:
                      AppLocalizationsSimple.of(context)?.showProfileCenter ??
                          '显示个人中心',
                  subtitle:
                      AppLocalizationsSimple.of(context)?.avatarUsernameLogin ??
                          '头像、用户名和登录按钮',
                  value: _showProfile,
                  onChanged: (value) {
                    // 🎯 验证：如果关闭个人中心，设置菜单必须显示
                    if (!value && !_visibleIds.contains('settings')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizationsSimple.of(context)
                                        ?.profileOrSettingsRequired ??
                                    '个人中心和设置至少保留一个',
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _showProfile = value;
                      _hasChanges = true;
                    });
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  icon: Icons.calendar_today_rounded,
                  title: AppLocalizationsSimple.of(context)?.showActivityLog ??
                      '显示活动记录',
                  subtitle: AppLocalizationsSimple.of(context)
                          ?.showNoteCreationCalendar ??
                      '展示笔记创建活动日历',
                  value: _showHeatmap,
                  onChanged: (value) {
                    setState(() {
                      _showHeatmap = value;
                      _hasChanges = true;
                    });
                  },
                  isDarkMode: isDarkMode,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 菜单项自定义
            _buildSection(
              title: AppLocalizationsSimple.of(context)?.menuItems ?? '菜单项',
              subtitle:
                  AppLocalizationsSimple.of(context)?.longPressDragToReorder ??
                      '长按拖动可调整顺序',
              children: [
                _buildReorderableList(isDarkMode),
              ],
            ),

            const SizedBox(height: 20),

            // 提示信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizationsSimple.of(context)?.allNotesIsDefaultHome ??
                    '💡 "全部笔记"是默认首页，无法隐藏或移动',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 恢复默认按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildResetButton(isDarkMode),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建恢复默认按钮
  Widget _buildResetButton(bool isDarkMode) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showResetConfirmDialog(isDarkMode),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restore_rounded,
                    size: 20,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizationsSimple.of(context)
                            ?.restoreDefaultSettings ??
                        '恢复默认设置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// 显示恢复默认确认对话框
  Future<void> _showResetConfirmDialog(bool isDarkMode) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppLocalizationsSimple.of(context)?.restoreDefaultSettings ??
              '恢复默认设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          AppLocalizationsSimple.of(context)?.confirmResetSidebar ??
              '确定要恢复侧边栏的默认设置吗？\n\n这将重置所有菜单项的显示状态和排序。',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '恢复默认',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if ((result ?? false) && mounted) {
      await _resetToDefault();
    }
  }

  /// 恢复默认设置
  Future<void> _resetToDefault() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 创建默认配置
    final defaultConfig = SidebarConfig();

    // 保存配置
    await appProvider.updateConfig(
      appProvider.appConfig.copyWith(sidebarConfig: defaultConfig),
    );

    // 更新本地状态
    setState(() {
      _showHeatmap = defaultConfig.showHeatmap;
      _showProfile = defaultConfig.showProfile;
      _visibleIds = Set<String>.from(defaultConfig.visibleItems);
      _items = defaultConfig.getOrderedVisibleItems();

      // 确保所有菜单项都在列表中
      for (final menuItem in SidebarMenuItem.values) {
        if (!_items.any((item) => item.id == menuItem.id)) {
          _items.add(menuItem);
        }
      }

      _hasChanges = false;
    });

    // 显示成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                AppLocalizationsSimple.of(context)?.defaultSettingsRestored ??
                    '已恢复默认设置',
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// 构建分组
  Widget _buildSection({
    required String title,
    required List<Widget> children,
    String? subtitle,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      );

  /// 构建开关项
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryColor,
        ),
      );

  /// 构建可排序列表
  Widget _buildReorderableList(bool isDarkMode) => ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
            _hasChanges = true;
          });
        },
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isFirst = index == 0;
          final isLast = index == _items.length - 1;
          final isVisible = _visibleIds.contains(item.id);
          final canHide = item.canHide;

          return _buildMenuItem(
            key: ValueKey(item.id),
            item: item,
            isFirst: isFirst,
            isLast: isLast,
            isVisible: isVisible,
            canHide: canHide,
            isDarkMode: isDarkMode,
            index: index,
          );
        }).toList(),
      );

  /// 构建菜单项
  Widget _buildMenuItem({
    required Key key,
    required SidebarMenuItem item,
    required bool isFirst,
    required bool isLast,
    required bool isVisible,
    required bool canHide,
    required bool isDarkMode,
    required int index,
  }) =>
      DecoratedBox(
        key: key,
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 0.5,
                  ),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动手柄
              if (item.id != 'all_notes') // 全部笔记不可移动
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                  ),
                )
              else
                const SizedBox(width: 32),

              const SizedBox(width: 4),

              // 菜单图标
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isVisible
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon as IconData,
                  size: 18,
                  color: isVisible ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
          title: Text(
            item.getLocalizedLabel(context),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isVisible
                  ? (isDarkMode ? Colors.white : Colors.black87)
                  : Colors.grey[500],
            ),
          ),
          subtitle: item.id == 'all_notes'
              ? Text(
                  AppLocalizationsSimple.of(context)?.defaultHome ?? '默认首页',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              : null,
          trailing: canHide
              ? Switch(
                  value: isVisible,
                  onChanged: (value) {
                    // 🎯 验证：如果是设置菜单，关闭时个人中心必须显示
                    if (item.id == 'settings' && !value && !_showProfile) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizationsSimple.of(context)
                                        ?.profileOrSettingsRequired ??
                                    '个人中心和设置至少保留一个',
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (value) {
                        _visibleIds.add(item.id);
                      } else {
                        _visibleIds.remove(item.id);
                      }
                      _hasChanges = true;
                    });
                  },
                  activeThumbColor: AppTheme.primaryColor,
                )
              : Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: Colors.grey[400],
                ),
        ),
      );
}
