import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/themes/app_typography.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/widgets/note_card.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:provider/provider.dart';

/// 标签笔记详情页 - 显示某个标签下的所有笔记
/// 采用与主页相同的布局和交互
class TagNotesScreen extends StatefulWidget {
  const TagNotesScreen({
    required this.tagName,
    super.key,
  });

  final String tagName;

  @override
  State<TagNotesScreen> createState() => _TagNotesScreenState();
}

class _TagNotesScreenState extends State<TagNotesScreen> {
  // 不再需要本地状态，直接使用 Consumer 监听 Provider

  @override
  Widget build(BuildContext context) {
    // 🐛 调试日志：打印接收到的标签名
    print('📝 [TagNotesScreen] 收到标签名: "${widget.tagName}"');
    print('📝 [TagNotesScreen] 标签名长度: ${widget.tagName.length}');
    print('📝 [TagNotesScreen] 标签名是否为空: ${widget.tagName.isEmpty}');
    
    // 🛡️ 防御性检查：标签名不能为空
    if (widget.tagName.isEmpty || widget.tagName.trim().isEmpty) {
      print('❌ [TagNotesScreen] 标签名为空，显示错误页面');
      return Scaffold(
        appBar: AppBar(
          title: const Text('错误'),
        ),
        body: const Center(
          child: Text('标签名称无效'),
        ),
      );
    }
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? AppTheme.darkBackgroundColor
        : AppTheme.backgroundColor;

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        // 🎯 计算当前标签的笔记数量（支持层级筛选）
        final notesCount = appProvider.notes
            .where((note) => note.tags.any((tag) =>
                tag == widget.tagName || tag.startsWith('${widget.tagName}/')
            ))
            .length;

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
                size: ResponsiveUtils.responsiveIconSize(context, 20),
                color: isDarkMode 
                    ? AppTheme.primaryLightColor 
                    : AppTheme.primaryColor,
              ),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${widget.tagName}',
                  style: AppTypography.getTitleStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppTheme.darkTextPrimaryColor
                        : AppTheme.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$notesCount ${AppLocalizationsSimple.of(context)?.notes ?? "条笔记"}',
                  style: AppTypography.getCaptionStyle(
                    context,
                    color: isDarkMode
                        ? AppTheme.darkTextSecondaryColor
                        : AppTheme.textSecondaryColor,
                  ).copyWith(fontSize: 12),
                ),
              ],
            ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          // 🐛 调试日志
          print('📝 [TagNotesScreen] 开始筛选笔记');
          print('📝 [TagNotesScreen] 目标标签名: "${widget.tagName}"');
          print('📝 [TagNotesScreen] 总笔记数: ${appProvider.notes.length}');
          
          // 打印前5个笔记的标签
          for (var i = 0; i < appProvider.notes.length && i < 5; i++) {
            print('📝 [TagNotesScreen] 笔记${i + 1}的标签: ${appProvider.notes[i].tags}');
          }
          
          // 🎯 实时监听笔记变化，支持层级标签筛选
          final currentNotes = appProvider.notes
              .where((note) {
                final hasTag = note.tags.any((tag) =>
                    tag == widget.tagName || tag.startsWith('${widget.tagName}/')
                );
                if (hasTag) {
                  print('📝 [TagNotesScreen] 找到匹配笔记，标签: ${note.tags}');
                }
                return hasTag;
              })
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('📝 [TagNotesScreen] 筛选后笔记数: ${currentNotes.length}');

          if (currentNotes.isEmpty) {
            print('📝 [TagNotesScreen] 无匹配笔记，显示空状态');
            return _buildEmptyState(context);
          }

          return ResponsiveLayout(
            mobile: _buildNotesList(context, currentNotes),
            tablet: _buildNotesGrid(context, currentNotes, crossAxisCount: 2),
            desktop: _buildNotesGrid(context, currentNotes, crossAxisCount: 3),
          );
        },
      ),
      // 🎯 右下角添加按钮，默认带当前标签
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNoteDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        tooltip: '创建笔记',
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
        );
      },
    );
  }
  
  // 🎯 显示添加笔记对话框，默认带当前标签
  void _showAddNoteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: '#${widget.tagName} ', // 🎯 预填充当前标签
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              await appProvider.createNote(content);
              
              if (mounted) {
                Navigator.pop(context); // 关闭编辑器
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 笔记已创建'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ 创建失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
  
  // 🎯 显示编辑笔记表单（与主页完全一致）
  void _showEditNoteForm(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: note.content,
        currentNoteId: note.id,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);
              
              // 确保标签更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.notifyListeners();
              });
            } catch (e) {
              if (mounted) {
                SnackBarUtils.showError(
                  context,
                  '更新失败: $e',
                );
              }
            }
          }
        },
      ),
    );
  }

  // 空状态（增强引导）
  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 动画图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note,
              size: 60,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
          Text(
            '还没有带 #${widget.tagName} 的笔记',
            style: AppTypography.getBodyStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '创建新笔记时，在内容中输入 #${widget.tagName} 即可',
              textAlign: TextAlign.center,
              style: AppTypography.getCaptionStyle(
                context,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
              ).copyWith(fontSize: 14, height: 1.5),
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
          // CTA按钮
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: Icon(Icons.add, size: 20),
            label: Text('创建笔记'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端列表布局（与主页完全一致）
  Widget _buildNotesList(BuildContext context, List<Note> notes) {
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero, // 🎯 与主页一致：零padding
        itemCount: notes.length,
        cacheExtent: 1000, // 🚀 性能优化：增加缓存区域
        itemBuilder: (context, index) {
          final note = notes[index];
          return RepaintBoundary(
            key: ValueKey(note.id), // 🚀 性能优化：避免不必要的重建
            child: NoteCard(
              key: ValueKey('card_${note.id}'), // 🚀 与主页一致
              note: note,
              disableTagNavigation: true, // 🎯 在标签详情页中禁用标签点击跳转，避免无限嵌套
              onEdit: () {
                // 🎯 与主页完全一致：弹出底部编辑器
                _showEditNoteForm(note);
              },
              onDelete: () async {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                await appProvider.deleteNote(note.id);
                // Consumer 会自动监听 Provider 变化并更新UI
              },
              onPin: () async {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                await appProvider.togglePinStatus(note);
                // Consumer 会自动监听 Provider 变化并更新UI
              },
            ),
          );
        },
      ),
    );
  }

  // 平板/桌面端列表布局（与主页完全一致）
  Widget _buildNotesGrid(
    BuildContext context,
    List<Note> notes, {
    required int crossAxisCount,
  }) {
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveUtils.responsivePadding(
          context,
          all: 16,
        ),
        itemCount: notes.length,
        cacheExtent: 1000, // 🚀 性能优化：增加缓存区域
        itemBuilder: (context, index) {
          final note = notes[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.responsiveSpacing(context, 16),
            ),
            child: RepaintBoundary(
              key: ValueKey(note.id), // 🚀 性能优化：避免不必要的重建
              child: NoteCard(
                key: ValueKey('card_${note.id}'), // 🚀 与主页一致
                note: note,
                disableTagNavigation: true, // 🎯 在标签详情页中禁用标签点击跳转，避免无限嵌套
                onEdit: () {
                  // 🎯 与主页完全一致：弹出底部编辑器
                  _showEditNoteForm(note);
                },
                onDelete: () async {
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  await appProvider.deleteNote(note.id);
                  // Consumer 会自动监听 Provider 变化并更新UI
                },
                onPin: () async {
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  await appProvider.togglePinStatus(note);
                  // Consumer 会自动监听 Provider 变化并更新UI
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

