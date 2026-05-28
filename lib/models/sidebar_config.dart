import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';

/// 侧边栏菜单项枚举
enum SidebarMenuItem {
  allNotes('all_notes', '全部笔记', '/', Icons.grid_view_rounded, false), // 不可隐藏
  randomReview('random_review', '随机回顾', '/random-review', Icons.shuffle_rounded, true),
  allTags('all_tags', '全部标签', '/tags', Icons.local_offer_outlined, true),
  knowledgeGraph('knowledge_graph', '知识图谱', '/knowledge-graph', Icons.account_tree_rounded, true),
  help('help', '帮助中心', '/help', Icons.help_outline_rounded, true),
  settings('settings', '设置', '/settings', Icons.settings_outlined, true);

  const SidebarMenuItem(
    this.id,
    this.label,
    this.path,
    this.icon,
    this.canHide,
  );

  final String id;
  final String label;
  final String path;
  final dynamic icon; // IconData
  final bool canHide; // 是否可以隐藏
  
  /// 获取国际化的标签文本
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    switch (id) {
      case 'all_notes':
        return l10n?.allNotes ?? label;
      case 'random_review':
        return l10n?.randomReview ?? label;
      case 'all_tags':
        return l10n?.allTags ?? label;
      case 'knowledge_graph':
        return l10n?.knowledgeGraph ?? label;
      case 'help':
        return l10n?.help ?? label;
      case 'settings':
        return l10n?.settings ?? label;
      default:
        return label;
    }
  }
  
  static SidebarMenuItem? fromId(String id) {
    try {
      return SidebarMenuItem.values.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// 侧边栏配置
class SidebarConfig {
  SidebarConfig({
    this.showHeatmap = true,
    this.showProfile = true,
    List<String>? visibleItems,
    List<String>? itemOrder,
  }) : visibleItems = visibleItems ?? _defaultVisibleItems(),
       itemOrder = itemOrder ?? _defaultItemOrder();

  final bool showHeatmap; // 是否显示活动记录
  final bool showProfile; // 是否显示个人中心
  final List<String> visibleItems; // 可见的菜单项ID列表
  final List<String> itemOrder; // 菜单项排序（ID列表）

  /// 默认可见菜单项
  static List<String> _defaultVisibleItems() {
    return SidebarMenuItem.values.map((item) => item.id).toList();
  }

  /// 默认排序
  static List<String> _defaultItemOrder() {
    return SidebarMenuItem.values.map((item) => item.id).toList();
  }

  /// 从JSON创建
  factory SidebarConfig.fromJson(Map<String, dynamic> json) {
    // 🎯 加载保存的配置
    List<String>? savedVisibleItems = (json['visibleItems'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    List<String>? savedItemOrder = (json['itemOrder'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    
    // 🎯 迁移逻辑：确保新增的菜单项（如 settings）被添加到旧配置中
    if (savedVisibleItems != null) {
      final allItemIds = SidebarMenuItem.values.map((item) => item.id).toList();
      for (final itemId in allItemIds) {
        if (!savedVisibleItems.contains(itemId)) {
          // 新增的菜单项默认添加到可见列表
          savedVisibleItems.add(itemId);
        }
      }
    }
    
    if (savedItemOrder != null) {
      final allItemIds = SidebarMenuItem.values.map((item) => item.id).toList();
      for (final itemId in allItemIds) {
        if (!savedItemOrder.contains(itemId)) {
          // 新增的菜单项添加到顺序列表末尾
          savedItemOrder.add(itemId);
        }
      }
    }
    
    return SidebarConfig(
      showHeatmap: json['showHeatmap'] ?? true,
      showProfile: json['showProfile'] ?? true,
      visibleItems: savedVisibleItems,
      itemOrder: savedItemOrder,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'showHeatmap': showHeatmap,
      'showProfile': showProfile,
      'visibleItems': visibleItems,
      'itemOrder': itemOrder,
    };
  }

  /// 复制并修改
  SidebarConfig copyWith({
    bool? showHeatmap,
    bool? showProfile,
    List<String>? visibleItems,
    List<String>? itemOrder,
  }) {
    return SidebarConfig(
      showHeatmap: showHeatmap ?? this.showHeatmap,
      showProfile: showProfile ?? this.showProfile,
      visibleItems: visibleItems ?? this.visibleItems,
      itemOrder: itemOrder ?? this.itemOrder,
    );
  }

  /// 检查菜单项是否可见
  bool isItemVisible(String itemId) {
    return visibleItems.contains(itemId);
  }

  /// 获取排序后的可见菜单项
  List<SidebarMenuItem> getOrderedVisibleItems() {
    final items = <SidebarMenuItem>[];
    
    // 按照 itemOrder 的顺序添加可见的菜单项
    for (final itemId in itemOrder) {
      if (visibleItems.contains(itemId)) {
        final menuItem = SidebarMenuItem.fromId(itemId);
        if (menuItem != null) {
          items.add(menuItem);
        }
      }
    }
    
    // 添加任何在 visibleItems 中但不在 itemOrder 中的项
    for (final itemId in visibleItems) {
      if (!itemOrder.contains(itemId)) {
        final menuItem = SidebarMenuItem.fromId(itemId);
        if (menuItem != null) {
          items.add(menuItem);
        }
      }
    }
    
    return items;
  }
}

