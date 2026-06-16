import 'package:flutter/material.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/tag_path_utils.dart';

/// 标签树节点
class TagNode {
  // 笔记数量

  TagNode({
    required this.name,
    required this.fullPath,
    this.children = const [],
    this.noteCount = 0,
  });
  final String name; // 当前层级的名称
  final String fullPath; // 完整路径
  final List<TagNode> children; // 子节点
  final int noteCount;

  /// 从标签列表构建树结构
  static List<TagNode> buildTree(List<String> tags) {
    final noteTags = tags.map((tag) => [tag]).toList();
    return buildTreeFromNoteTags(noteTags);
  }

  /// 从每条笔记的标签集合构建树结构，并按笔记数计数。
  static List<TagNode> buildTreeFromNoteTags(Iterable<Iterable<String>> notes) {
    final normalizedNotes = notes
        .map(
          (tags) => tags.map(normalizeTagPath).whereType<String>().toSet(),
        )
        .where((tags) => tags.isNotEmpty)
        .toList();
    if (normalizedNotes.isEmpty) {
      return [];
    }

    // 构建树结构
    final childrenMap = <String, List<String>>{};
    final allPaths = <String>{};
    final tagCounts = <String, int>{};

    for (final tags in normalizedNotes) {
      final notePaths = <String>{};
      for (final tag in tags) {
        final parts = tag.split('/');
        for (var i = 0; i < parts.length; i++) {
          final path = parts.sublist(0, i + 1).join('/');
          allPaths.add(path);
          notePaths.add(path);

          if (i < parts.length - 1) {
            childrenMap.putIfAbsent(path, () => []);
          }
        }
      }
      for (final path in notePaths) {
        tagCounts[path] = (tagCounts[path] ?? 0) + 1;
      }
    }

    // 创建节点
    final nodeMap = <String, TagNode>{};
    for (final path in allPaths.toList()..sort()) {
      final parts = path.split('/');
      final name = parts.last;
      final children =
          childrenMap[path]?.map((childPath) => nodeMap[childPath]!).toList() ??
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
            parent.children.add(child);
          }
        }
      }
    }

    sortNodes(rootNodes);
    return rootNodes;
  }

  static void sortNodes(List<TagNode> nodes) {
    nodes.sort((a, b) {
      final byCount = b.noteCount.compareTo(a.noteCount);
      if (byCount != 0) {
        return byCount;
      }
      return a.fullPath.compareTo(b.fullPath);
    });
    for (final node in nodes) {
      sortNodes(node.children);
    }
  }
}

/// 标签树项目 Widget
class TagTreeItem extends StatefulWidget {
  const TagTreeItem({
    required this.node,
    required this.onTagSelect,
    required this.onTagTap,
    super.key,
    this.selectedTag,
    this.expandAll = false,
  });
  final TagNode node;
  final String? selectedTag;
  final Function(String) onTagSelect;
  final Function(String) onTagTap;
  final bool expandAll;

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
            onTap: _openTag,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                        .withValues(alpha: isDarkMode ? 0.2 : 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  if (hasChildren)
                    InkResponse(
                      onTap: _toggleExpanded,
                      radius: 18,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          size: 22,
                          color: isDarkMode
                              ? AppTheme.primaryLightColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.tag_rounded,
                        size: 16,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  const SizedBox(width: 6),
                  // 标签名称
                  Expanded(
                    child: Text(
                      widget.node.name,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[800]),
                        fontWeight: isSelected || hasChildren
                            ? FontWeight.w600
                            : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.node.noteCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: '查看标签笔记',
                    child: InkResponse(
                      onTap: _openTag,
                      radius: 18,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[400]),
                        ),
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
                  .map(
                    (child) => TagTreeItem(
                      key: ValueKey(child.fullPath),
                      node: child,
                      selectedTag: widget.selectedTag,
                      onTagSelect: widget.onTagSelect,
                      onTagTap: widget.onTagTap,
                      expandAll: widget.expandAll,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _openTag() {
    widget.onTagTap(widget.node.fullPath);
  }
}
