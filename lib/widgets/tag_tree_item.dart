import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';

/// 标签树节点
class TagNode {
  final String name; // 当前层级的名称
  final String fullPath; // 完整路径
  final List<TagNode> children; // 子节点
  final int noteCount; // 笔记数量
  
  TagNode({
    required this.name,
    required this.fullPath,
    this.children = const [],
    this.noteCount = 0,
  });
  
  /// 从标签列表构建树结构
  static List<TagNode> buildTree(List<String> tags) {
    if (tags.isEmpty) return [];

    // 统计每个标签（及其父标签）的笔记数
    final Map<String, int> tagCounts = {};
    for (final tag in tags) {
      final parts = tag.split('/');
      for (int i = 0; i < parts.length; i++) {
        final path = parts.sublist(0, i + 1).join('/');
        tagCounts[path] = (tagCounts[path] ?? 0) + 1;
      }
    }

    // 构建树结构
    final Map<String, List<TagNode>> childrenMap = {};
    final Set<String> allPaths = {};

    for (final tag in tags) {
      final parts = tag.split('/');
      for (int i = 0; i < parts.length; i++) {
        final path = parts.sublist(0, i + 1).join('/');
        allPaths.add(path);

        if (i < parts.length - 1) {
          final childPath = parts.sublist(0, i + 2).join('/');
          final parentPath = path;
          if (!childrenMap.containsKey(parentPath)) {
            childrenMap[parentPath] = [];
          }
        }
      }
    }

    // 创建节点
    final Map<String, TagNode> nodeMap = {};
    for (final path in allPaths.toList()..sort()) {
      final parts = path.split('/');
      final name = parts.last;
      final children = childrenMap[path]
              ?.map((childPath) => nodeMap[childPath]!)
              .toList() ??
          [];

      nodeMap[path] = TagNode(
        name: name,
        fullPath: path,
        children: children,
        noteCount: tagCounts[path] ?? 0,
      );
    }

    // 返回根节点
    final rootNodes = allPaths
        .where((path) => !path.contains('/'))
        .map((path) => nodeMap[path]!)
        .toList();

    // 重新构建子节点关系
    for (final path in allPaths) {
      final parts = path.split('/');
      if (parts.length > 1) {
        final parentPath = parts.sublist(0, parts.length - 1).join('/');
        if (nodeMap.containsKey(parentPath)) {
          final parent = nodeMap[parentPath]!;
          final child = nodeMap[path]!;
          if (!parent.children.contains(child)) {
            (parent.children as List<TagNode>).add(child);
          }
        }
      }
    }

    return rootNodes;
  }
}

/// 标签树项目 Widget
class TagTreeItem extends StatefulWidget {
  final TagNode node;
  final String? selectedTag;
  final Function(String) onTagSelect;
  final Function(String) onTagTap;
  final bool expandAll;
  
  const TagTreeItem({
    super.key,
    required this.node,
    this.selectedTag,
    required this.onTagSelect,
    required this.onTagTap,
    this.expandAll = false,
  });
  
  @override
  State<TagTreeItem> createState() => _TagTreeItemState();
}

class _TagTreeItemState extends State<TagTreeItem> {
  late bool _isExpanded;
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandAll;
  }
  
  @override
  void didUpdateWidget(TagTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandAll != oldWidget.expandAll) {
    setState(() {
        _isExpanded = widget.expandAll;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.node.children.isNotEmpty;
    final isSelected = widget.node.fullPath == widget.selectedTag;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            // 🎯 优化交互：有子节点时点击展开/折叠，无子节点时点击查看笔记
            onTap: hasChildren
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : () => widget.onTagTap(widget.node.fullPath),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // 展开/折叠图标
                  if (hasChildren)
                    Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        _isExpanded
                            ? Icons.folder_open_rounded
                            : Icons.folder_rounded,
                        size: 18,
                        color: isDarkMode
                            ? AppTheme.primaryLightColor
                            : AppTheme.primaryColor,
                      ),
                    )
                  else
                    Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: isDarkMode
                          ? Colors.grey[500]
                          : Colors.grey[400],
                    ),
                  const SizedBox(width: 10),
                  // 标签名称
                  Expanded(
                    child: Text(
                      widget.node.name,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDarkMode ? Colors.grey[300] : Colors.grey[800]),
                        fontWeight: isSelected || hasChildren
                            ? FontWeight.w600
                            : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  // 笔记数量徽章 - 点击可查看该标签的所有笔记
                  GestureDetector(
                    onTap: () => widget.onTagTap(widget.node.fullPath),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.node.noteCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hasChildren) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 子节点
        if (hasChildren && _isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
                      child: Column(
              children: widget.node.children
                  .map((child) => TagTreeItem(
                        key: ValueKey(child.fullPath),
                            node: child,
                            selectedTag: widget.selectedTag,
                            onTagSelect: widget.onTagSelect,
                        onTagTap: widget.onTagTap,
                        expandAll: widget.expandAll,
                      ))
                  .toList(),
          ),
          ),
      ],
    );
  }
}
