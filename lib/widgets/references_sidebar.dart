import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:inkroot/providers/app_provider.dart';

/// 引用关系侧边栏 - 对标批注侧边栏的设计
/// 
/// 支持响应式布局：手机、平板、桌面端
class ReferencesSidebar extends StatefulWidget {
  final Note note;
  final Function(String noteId) onNoteTap;

  const ReferencesSidebar({
    super.key,
    required this.note,
    required this.onNoteTap,
  });

  @override
  State<ReferencesSidebar> createState() => _ReferencesSidebarState();
}

class _ReferencesSidebarState extends State<ReferencesSidebar> {
  String _filterType = 'all'; // 'all', 'outgoing', 'incoming'

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: _getResponsiveWidth(screenWidth),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isDarkMode),
          _buildFilterBar(isDarkMode),
          Expanded(
            child: _buildReferencesList(isDarkMode),
          ),
        ],
      ),
    );
  }

  /// 响应式宽度
  double _getResponsiveWidth(double screenWidth) {
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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allReferences = _getAllReferences(appProvider);
    
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
          Icon(
            Icons.account_tree_outlined,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.referenceRelations ?? '引用关系',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${allReferences.length} ${localizations?.referencesCount ?? '个引用'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
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
  Widget _buildFilterBar(bool isDarkMode) {
    final localizations = AppLocalizationsSimple.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: localizations?.all ?? '全部',
              value: 'all',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: localizations?.referencedNotes ?? '引用的笔记',
              value: 'outgoing',
              icon: Icons.arrow_forward,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: localizations?.referencedByNotes ?? '被引用',
              value: 'incoming',
              icon: Icons.arrow_back,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required String value,
    IconData? icon,
    required bool isDarkMode,
  }) {
    final isSelected = _filterType == value;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? AppTheme.primaryColor : (isDarkMode ? Colors.white70 : Colors.black87)),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = value);
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : (isDarkMode ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  /// 构建引用列表
  Widget _buildReferencesList(bool isDarkMode) {
    final appProvider = Provider.of<AppProvider>(context);
    final localizations = AppLocalizationsSimple.of(context);
    
    final outgoingRefs = _getOutgoingReferences(appProvider);
    final incomingRefs = _getIncomingReferences(appProvider);
    
    List<Map<String, dynamic>> displayRefs = [];
    if (_filterType == 'all') {
      displayRefs = [...outgoingRefs, ...incomingRefs];
    } else if (_filterType == 'outgoing') {
      displayRefs = outgoingRefs;
    } else {
      displayRefs = incomingRefs;
    }
    
    if (displayRefs.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayRefs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ref = displayRefs[index];
        final isOutgoing = outgoingRefs.contains(ref);
        return _buildReferenceCard(ref, isOutgoing, isDarkMode, appProvider);
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(bool isDarkMode) {
    final localizations = AppLocalizationsSimple.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _filterType == 'all'
                ? (localizations?.noReferencesYet ?? '还没有引用关系')
                : _filterType == 'outgoing'
                    ? (localizations?.noOutgoingReferences ?? '没有引用其他笔记')
                    : (localizations?.noIncomingReferences ?? '没有被其他笔记引用'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建引用卡片
  Widget _buildReferenceCard(
    Map<String, dynamic> ref,
    bool isOutgoing,
    bool isDarkMode,
    AppProvider appProvider,
  ) {
    final localizations = AppLocalizationsSimple.of(context);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    // 获取关联笔记ID
    final relatedNoteId = isOutgoing
        ? (ref['relatedMemoId']?.toString() ?? '')
        : (ref['memoId']?.toString() ?? '');
    
    // 查找关联笔记
    final relatedNote = appProvider.notes.firstWhere(
      (n) => n.id == relatedNoteId,
      orElse: () => Note(
        id: relatedNoteId,
        content: localizations?.noteNotFound ?? '笔记未找到',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    return InkWell(
      onTap: () => widget.onNoteTap(relatedNoteId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutgoing
                ? Colors.blue.withOpacity(0.3)
                : Colors.green.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型标签
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutgoing
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutgoing ? Icons.arrow_forward : Icons.arrow_back,
                        size: 14,
                        color: isOutgoing ? Colors.blue : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutgoing
                            ? (localizations?.referenced ?? '引用')
                            : (localizations?.referencedBy ?? '被引用'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOutgoing ? Colors.blue : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 笔记内容预览
            Text(
              relatedNote.content.length > 100
                  ? '${relatedNote.content.substring(0, 100)}...'
                  : relatedNote.content,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // 底部信息
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(relatedNote.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取所有引用
  List<Map<String, dynamic>> _getAllReferences(AppProvider appProvider) {
    return widget.note.relations.where((relation) {
      final type = relation['type'];
      return type == 1 || type == 'REFERENCE' || type == 'REFERENCED_BY';
    }).toList();
  }

  /// 获取引用的笔记（正向引用）
  List<Map<String, dynamic>> _getOutgoingReferences(AppProvider appProvider) {
    final outgoingRefs = <Map<String, dynamic>>[];
    
    for (final relation in widget.note.relations) {
      final type = relation['type'];
      final memoId = relation['memoId']?.toString() ?? '';
      final currentId = widget.note.id;
      
      if ((type == 'REFERENCE' || type == 1) && (memoId == currentId || memoId.isEmpty)) {
        outgoingRefs.add(relation);
      }
    }
    
    return outgoingRefs;
  }

  /// 获取被引用（反向引用）
  List<Map<String, dynamic>> _getIncomingReferences(AppProvider appProvider) {
    final incomingRefs = <Map<String, dynamic>>[];
    
    for (final relation in widget.note.relations) {
      final type = relation['type'];
      final relatedMemoId = relation['relatedMemoId']?.toString() ?? '';
      final currentId = widget.note.id;
      
      if (type == 'REFERENCED_BY' && relatedMemoId == currentId) {
        incomingRefs.add(relation);
      }
    }
    
    return incomingRefs;
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}-${date.day}';
    }
  }
}
