import 'dart:ui'; // 🪟 ImageFilter for glassmorphism

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/services/intelligent_related_notes_service.dart';
import 'package:inkroot/services/user_behavior_service.dart'; // 🧠 用户行为记录
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;

/// 🧠 智能相关笔记底部抽屉
/// 
/// 创新点：
/// - 多路径展示（学习、对比、补充）
/// - 可解释推荐（告诉用户"为什么"）
/// - 分类浏览（按关系类型）
class IntelligentRelatedNotesSheet extends StatefulWidget {
  const IntelligentRelatedNotesSheet({
    required this.result,
    super.key,
  });
  
  final RelatedNotesResult result;
  
  static Future<void> show(
    BuildContext context,
    RelatedNotesResult result,
  ) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => IntelligentRelatedNotesSheet(result: result),
      );
  
  @override
  State<IntelligentRelatedNotesSheet> createState() =>
      _IntelligentRelatedNotesSheetState();
}

class _IntelligentRelatedNotesSheetState
    extends State<IntelligentRelatedNotesSheet> {
  RelationType? _selectedType; // null = 显示全部
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 🔝 顶部：拖动条 + 标题
          _buildHeader(isDark, theme),
          
          const Divider(height: 1),
          
          // 🎯 关系类型选择器
          if (widget.result.groupedByType.length > 1)
            _buildRelationTypeSelector(isDark),
          
          // 🎯 学习路径推荐（如果有下一步推荐）
          if (widget.result.nextBestNote != null && _selectedType == null)
            _buildLearningPathCard(isDark, theme),
          
          // 📋 笔记列表
          Expanded(
            child: _buildNotesList(isDark, theme),
          ),
        ],
      ),
    );
  }
  
  /// 🔝 构建头部
  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Column(
        children: [
          // 拖动条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 标题栏
          Row(
            children: [
              // 🧠 智能推荐图标
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
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
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
                      '🧠 智能推荐',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '找到 ${widget.result.allRelations.length} 条相关笔记',
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
        ],
      ),
    );
  }
  
  /// 🎯 学习路径推荐卡片 - 🎨 精致设计
  Widget _buildLearningPathCard(bool isDark, ThemeData theme) {
    final nextNote = widget.result.nextBestNote!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // 🌈 渐变背景（温柔而吸引人）
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF6366F1).withOpacity(0.15),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ]
              : [
                  const Color(0xFF6366F1).withOpacity(0.08),
                  const Color(0xFFF59E0B).withOpacity(0.06),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // 更大圆角，更柔和
        // ✨ 精致的阴影（Apple风格）
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        // 🪟 玻璃态边框
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // 🪟 玻璃态效果
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
            ),
            child: _buildLearningPathContent(isDark, theme, nextNote),
          ),
        ),
      ),
    );
  }
  
  /// 📝 学习路径卡片内容 - 🎨 精致设计
  Widget _buildLearningPathContent(bool isDark, ThemeData theme, IntelligentRelation nextNote) {
    return InkWell(
      onTap: () async {
        // 🧠 记录用户点击行为
        final behaviorService = UserBehaviorService();
        final noteTags = tag_utils.extractTagsFromContent(nextNote.note.content).toList();
        
        await behaviorService.recordClick(
          noteId: nextNote.note.id,
          noteTags: noteTags,
          relationType: nextNote.relationType,
          viewDurationSeconds: 0,
        );
        
        if (!context.mounted) return;
        Navigator.of(context).pop();
        context.push('/note/${nextNote.note.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          // 左侧：简洁的装饰线
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: nextNote.relationType.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 📝 中间：内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行 - 极简设计
                Text(
                  'Recommended Next',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSecondaryColor
                        : AppTheme.textSecondaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // 关系类型标签 - 极简设计
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: nextNote.relationType.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    nextNote.relationType.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: nextNote.relationType.color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 📄 内容预览（更细腻）
                Text(
                  _getPreviewText(nextNote.note.content),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondaryColor.withOpacity(0.8)
                        : AppTheme.textSecondaryColor.withOpacity(0.7),
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          
          // 右侧：简洁箭头
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark
                ? AppTheme.darkTextSecondaryColor.withOpacity(0.4)
                : AppTheme.textSecondaryColor.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
  
  /// 🎯 关系类型选择器
  Widget _buildRelationTypeSelector(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "全部"选项
          _buildTypeChip(
            label: '全部',
            emoji: '📑',
            count: widget.result.allRelations.length,
            isSelected: _selectedType == null,
            onTap: () => setState(() => _selectedType = null),
            isDark: isDark,
          ),
          
          const SizedBox(width: 8),
          
          // 各种关系类型
          ...widget.result.groupedByType.keys.map((type) {
            final count = widget.result.groupedByType[type]!.length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTypeChip(
                label: type.label,
                emoji: type.emoji,
                count: count,
                isSelected: _selectedType == type,
                onTap: () => setState(() => _selectedType = type),
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
  
  /// 🏷️ 类型芯片
  Widget _buildTypeChip({
    required String label,
    required String emoji,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 📋 笔记列表
  Widget _buildNotesList(bool isDark, ThemeData theme) {
    final relations = _selectedType == null
        ? widget.result.allRelations
        : widget.result.groupedByType[_selectedType] ?? [];
    
    if (relations.isEmpty) {
      return Center(
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
              '暂无此类型的相关笔记',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: relations.length,
      itemBuilder: (context, index) {
        final relation = relations[index];
        return _buildNoteItem(relation, isDark, theme);
      },
    );
  }
  
  /// 📝 笔记项
  Widget _buildNoteItem(
    IntelligentRelation relation,
    bool isDark,
    ThemeData theme,
  ) {
    final note = relation.note;
    final previewText = _getPreviewText(note.content);
    
    return InkWell(
      onTap: () async {
        // 🧠 记录用户点击行为
        final behaviorService = UserBehaviorService();
        final noteTags = tag_utils.extractTagsFromContent(note.content).toList();
        
        await behaviorService.recordClick(
          noteId: note.id,
          noteTags: noteTags,
          relationType: relation.relationType,
          viewDurationSeconds: 0, // 初始记录，实际浏览时长由详情页更新
        );
        
        if (!context.mounted) return;
        Navigator.of(context).pop();
        context.push('/note/${note.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: relation.relationType == RelationType.CONTINUE
                ? AppTheme.primaryColor.withOpacity(0.3)
                : (isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor),
            width: relation.relationType == RelationType.CONTINUE ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：关系类型 + 相似度
            Row(
              children: [
                // 关系类型标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRelationTypeColor(relation.relationType)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        relation.relationType.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        relation.relationType.label,
                        style: TextStyle(
                          color: _getRelationTypeColor(relation.relationType),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // 相似度评分
                _buildSimilarityBadge(
                  relation.similarityPercent,
                  isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 笔记内容预览
            Text(
              previewText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextPrimaryColor
                    : AppTheme.textPrimaryColor,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 推荐理由
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.blue[900] : Colors.blue[50])
                    ?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 14,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      relation.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 🎨 获取关系类型颜色
  Color _getRelationTypeColor(RelationType type) {
    switch (type) {
      case RelationType.CONTINUE:
        return AppTheme.primaryColor;
      case RelationType.COMPARE:
        return Colors.orange;
      case RelationType.COMPLEMENT:
        return Colors.purple;
      case RelationType.QA:
        return Colors.green;
      case RelationType.INSPIRE:
        return Colors.pink;
      case RelationType.TEMPORAL:
        return Colors.blue;
    }
  }
  
  /// 🏷️ 相似度徽章
  Widget _buildSimilarityBadge(int similarity, bool isDark) {
    Color color;
    if (similarity >= 80) {
      color = Colors.green;
    } else if (similarity >= 60) {
      color = AppTheme.primaryColor;
    } else {
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$similarity%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 📄 获取预览文本
  String _getPreviewText(String content) {
    var cleaned = content;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAll(RegExp('[*_`#~]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();
    return cleaned.isNotEmpty ? cleaned : '(空笔记)';
  }
}

