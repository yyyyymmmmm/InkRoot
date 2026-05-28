import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/services/ai_related_notes_service.dart';
import 'package:inkroot/themes/app_theme.dart';

/// 相关笔记底部抽屉
///
/// 展示 AI 智能推荐的相关笔记列表
class RelatedNotesBottomSheet extends StatelessWidget {
  const RelatedNotesBottomSheet({
    required this.relatedNotes,
    super.key,
  });
  final List<RelatedNote> relatedNotes;

  /// 显示底部抽屉
  static Future<void> show(
    BuildContext context,
    List<RelatedNote> relatedNotes,
  ) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RelatedNotesBottomSheet(
          relatedNotes: relatedNotes,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                // 魔法棒图标
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppTheme.primaryLightColor, AppTheme.accentColor]
                          : [
                              AppTheme.primaryColor,
                              AppTheme.accentColor,
                              AppTheme.primaryLightColor,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? AppTheme.primaryLightColor
                                : AppTheme.primaryColor)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // 标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizationsSimple.of(context)
                                ?.aiRelatedNotesTitle ??
                            'Related Notes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${relatedNotes.length} ${AppLocalizationsSimple.of(context)?.aiRelatedNotes ?? 'related notes found'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // 关闭按钮
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? AppTheme.darkTextSecondaryColor
                        : AppTheme.textSecondaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 相关笔记列表
          Expanded(
            child: relatedNotes.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: relatedNotes.length,
                    itemBuilder: (context, index) {
                      final relatedNote = relatedNotes[index];
                      return _buildNoteItem(
                        context,
                        relatedNote,
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, bool isDark) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_satisfied,
              size: 64,
              color: isDark
                  ? AppTheme.darkTextTertiaryColor
                  : AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizationsSimple.of(context)?.aiRelatedNotesEmpty ??
                  'No related notes found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondaryColor
                        : AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                '尝试创建更多笔记，AI 会为你发现知识之间的关联',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextTertiaryColor
                          : AppTheme.textTertiaryColor,
                    ),
              ),
            ),
          ],
        ),
      );

  /// 构建笔记项
  Widget _buildNoteItem(
    BuildContext context,
    RelatedNote relatedNote,
    bool isDark,
  ) {
    final note = relatedNote.note;
    final similarity = relatedNote.similarityPercent;

    // 提取笔记预览文本
    final previewText = _getPreviewText(note.content);

    // 相似度颜色
    final similarityColor = _getSimilarityColor(similarity, isDark);

    return InkWell(
      onTap: () {
        // 关闭底部抽屉
        Navigator.of(context).pop();

        // 跳转到笔记详情页
        context.push('/note/${note.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 笔记内容预览
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextPrimaryColor
                              : AppTheme.textPrimaryColor,
                          height: 1.5,
                        ),
                  ),
                ),

                const SizedBox(width: 12),

                // 相似度评分
                _buildSimilarityBadge(
                  context,
                  similarity,
                  similarityColor,
                  isDark,
                ),
              ],
            ),

            // 标签和时间
            if (note.tags.isNotEmpty || note.createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // 标签
                  if (note.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: note.tags
                            .take(3)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppTheme.primaryLightColor
                                          : AppTheme.primaryColor)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.primaryLightColor
                                        : AppTheme.primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  // 时间
                  Text(
                    _formatTime(note.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextTertiaryColor
                              : AppTheme.textTertiaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建相似度徽章
  Widget _buildSimilarityBadge(
    BuildContext context,
    int similarity,
    Color color,
    bool isDark,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$similarity%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  /// 获取预览文本
  String _getPreviewText(String content) {
    // 移除 Markdown 标记
    var cleaned = content;

    // 清理 Markdown 链接：[文本](url) -> 文本
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );

    // 清理 Markdown 格式标记
    cleaned = cleaned.replaceAll(RegExp('[*_`#~]'), '');

    // 清理多余的空白
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();

    return cleaned.isNotEmpty ? cleaned : '(空笔记)';
  }

  /// 获取相似度颜色
  Color _getSimilarityColor(int similarity, bool isDark) {
    if (similarity >= 80) {
      // 高相关度 - 深绿松石
      return isDark ? AppTheme.primaryLightColor : AppTheme.primaryDarkColor;
    } else if (similarity >= 60) {
      // 中等相关度 - 标准绿松石
      return AppTheme.primaryColor;
    } else {
      // 低相关度 - 浅绿松石
      return isDark ? AppTheme.accentColor : AppTheme.primaryLightColor;
    }
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
