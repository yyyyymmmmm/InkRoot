import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:intl/intl.dart';

/// 批注侧边栏 - 专业版
///
/// 对标 Notion、Obsidian 的批注系统
/// 支持响应式布局：手机、平板、桌面端
class AnnotationsSidebar extends StatefulWidget {
  const AnnotationsSidebar({
    required this.note,
    required this.onAnnotationTap,
    required this.onAddAnnotation,
    required this.onEditAnnotation,
    required this.onDeleteAnnotation,
    required this.onResolveAnnotation,
    super.key,
  });

  final Note note;
  final Function(Annotation) onAnnotationTap;
  final VoidCallback onAddAnnotation;
  final Function(Annotation) onEditAnnotation;
  final Function(String) onDeleteAnnotation;
  final Function(Annotation) onResolveAnnotation;

  @override
  State<AnnotationsSidebar> createState() => _AnnotationsSidebarState();
}

class _AnnotationsSidebarState extends State<AnnotationsSidebar> {
  AnnotationType? _filterType;
  bool _showResolved = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // 📱 响应式宽度
    final sidebarWidth = _getSidebarWidth(screenWidth);

    // 过滤批注
    var annotations = widget.note.annotations;
    if (_filterType != null) {
      annotations = annotations.where((a) => a.type == _filterType).toList();
    }
    if (!_showResolved) {
      annotations = annotations.where((a) => !a.isResolved).toList();
    }

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头部
          _buildHeader(isDarkMode),

          // 筛选栏
          _buildFilterBar(isDarkMode),

          // 批注列表
          Expanded(
            child: annotations.isEmpty
                ? _buildEmptyState(isDarkMode)
                : _buildAnnotationList(annotations, isDarkMode),
          ),
        ],
      ),
    );
  }

  /// 📱 响应式宽度计算
  double _getSidebarWidth(double screenWidth) {
    if (screenWidth < 600) {
      // 手机：全屏
      return screenWidth;
    } else if (screenWidth < 1024) {
      // 平板：80%
      return screenWidth * 0.8;
    } else {
      // 桌面：固定400px
      return 400;
    }
  }

  /// 构建头部
  Widget _buildHeader(bool isDarkMode) {
    final localizations = AppLocalizationsSimple.of(context);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final count = widget.note.annotations.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.comment_outlined,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.annotations ?? '批注',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '$count ${localizations?.annotationCount ?? '条批注'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 添加按钮
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primaryColor,
            onPressed: widget.onAddAnnotation,
            tooltip: localizations?.addAnnotation ?? '添加批注',
          ),
          // 关闭按钮
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.grey[600],
            onPressed: () => Navigator.pop(context),
            tooltip: localizations?.cancel ?? '关闭',
          ),
        ],
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar(bool isDarkMode) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型筛选
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: AppLocalizationsSimple.of(context)?.all ?? '全部',
                    isSelected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(width: 8),
                  ...AnnotationType.values.map((type) {
                    final annotation = Annotation(
                      id: '',
                      content: '',
                      createdAt: DateTime.now(),
                      type: type,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: annotation.getTypeText(context),
                        icon: annotation.typeIcon,
                        color: annotation.typeColor,
                        isSelected: _filterType == type,
                        onTap: () => setState(() => _filterType = type),
                        isDarkMode: isDarkMode,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 显示已解决
            Row(
              children: [
                Checkbox(
                  value: _showResolved,
                  onChanged: (value) => setState(() => _showResolved = value!),
                  activeColor: AppTheme.primaryColor,
                ),
                Text(
                  AppLocalizationsSimple.of(context)?.showResolved ?? '显示已解决',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
    IconData? icon,
    Color? color,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppTheme.primaryColor).withValues(alpha: 0.15)
                : (isDarkMode ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppTheme.primaryColor)
                  : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? (color ?? AppTheme.primaryColor)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (color ?? AppTheme.primaryColor)
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      );

  /// 构建空状态
  Widget _buildEmptyState(bool isDarkMode) {
    final localizations = AppLocalizationsSimple.of(context);
    return GestureDetector(
      // ✅ 点击空白区域关闭侧边栏
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_bank_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _filterType == null
                  ? (localizations?.noAnnotations ?? '还没有批注')
                  : (localizations?.noAnnotationsOfType ?? '没有此类型的批注'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.noAnnotationsHint ?? '点击右上角 + 添加批注',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建批注列表
  Widget _buildAnnotationList(List<Annotation> annotations, bool isDarkMode) =>
      ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: annotations.length + 1, // ✅ 多加一个空白占位符
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // ✅ 最后一项是可点击的空白占位符
          if (index == annotations.length) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 200, // 足够的高度确保能点击
                color: Colors.transparent,
              ),
            );
          }

          final annotation = annotations[index];
          return _buildAnnotationCard(annotation, isDarkMode);
        },
      );

  /// 构建批注卡片
  Widget _buildAnnotationCard(Annotation annotation, bool isDarkMode) {
    final localizations = AppLocalizationsSimple.of(context);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return InkWell(
      onTap: () => widget.onAnnotationTap(annotation),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: annotation.typeColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：类型 + 时间 + 操作
            Row(
              children: [
                // 类型图标
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: annotation.typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    annotation.typeIcon,
                    size: 16,
                    color: annotation.typeColor,
                  ),
                ),
                const SizedBox(width: 8),
                // 类型文本
                Text(
                  annotation.getTypeText(context),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: annotation.typeColor,
                  ),
                ),
                const Spacer(),
                // 已解决标记
                if (annotation.isResolved)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          localizations?.resolved ?? '已解决',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // 更多操作
                PopupMenuButton<String>(
                  icon:
                      Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
                  itemBuilder: (context) => [
                    if (annotation.type == AnnotationType.question &&
                        !annotation.isResolved)
                      PopupMenuItem(
                        value: 'resolve',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(localizations?.markAsResolved ?? '标记为已解决'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(localizations?.edit ?? '编辑'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(localizations?.delete ?? '删除'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'resolve':
                        widget.onResolveAnnotation(annotation);
                        break;
                      case 'edit':
                        widget.onEditAnnotation(annotation);
                        break;
                      case 'delete':
                        widget.onDeleteAnnotation(annotation.id);
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 高亮文本（如果有）
            if (annotation.highlightedText != null &&
                annotation.highlightedText!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: annotation.typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: annotation.typeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '"${annotation.highlightedText}"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 批注内容
            Text(
              annotation.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
            ),

            // 底部：时间 + 回复数
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(annotation.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (annotation.replies.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.reply,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${annotation.replies.length} ${localizations?.replies ?? '条回复'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final localizations = AppLocalizationsSimple.of(context);
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return localizations?.justNow ?? '刚刚';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return localizations != null
          ? localizations.minutesAgo(minutes)
          : '$minutes 分钟前';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return localizations != null
          ? localizations.hoursAgo(hours)
          : '$hours 小时前';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return localizations != null ? localizations.daysAgo(days) : '$days 天前';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }
}
