import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/note_sorting_helper.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/themes/app_typography.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/utils/tag_path_utils.dart';
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

  void _switchTag(String tagName) {
    final nextTag = normalizeTagPath(tagName);
    final currentTag = _normalizedTagName;
    if (nextTag == null || nextTag == currentTag) {
      return;
    }
    context.pushNamed(
      'tag-notes',
      queryParameters: {'tag': nextTag},
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tags');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ 防御性检查：标签名不能为空
    final tagName = _normalizedTagName;
    if (tagName.isEmpty) {
      final l10n = AppLocalizationsSimple.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.routeErrorTitle ?? '错误'),
        ),
        body: Center(
          child: Text(l10n?.invalidTagName ?? '标签名称无效'),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final currentNotes = _notesForCurrentTag(appProvider);
        final childCount = currentNotes
            .where(
              (note) => note.tags.any(
                (tag) {
                  final normalizedTag = normalizeTagPath(tag);
                  return normalizedTag != null &&
                      normalizedTag.startsWith('$tagName/');
                },
              ),
            )
            .length;
        final notesCount = currentNotes.length;

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
              onPressed: _handleBack,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tagName',
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
                  childCount > 0
                      ? '$notesCount ${AppLocalizationsSimple.of(context)?.notes ?? "条笔记"} · 含子标签'
                      : '$notesCount ${AppLocalizationsSimple.of(context)?.notes ?? "条笔记"}',
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
          body: currentNotes.isEmpty
              ? _buildEmptyState(context)
              : ResponsiveLayout(
                  mobile: _buildNotesList(context, currentNotes),
                  tablet: _buildNotesGrid(
                    context,
                    currentNotes,
                    crossAxisCount: 2,
                  ),
                  desktop: _buildNotesGrid(
                    context,
                    currentNotes,
                    crossAxisCount: 3,
                  ),
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

  String get _normalizedTagName => normalizeTagPath(widget.tagName) ?? '';

  List<Note> _notesForCurrentTag(AppProvider appProvider) =>
      appProvider.notes.where((note) {
        return note.tags.any(
          (tag) => tagPathMatches(tag, _normalizedTagName),
        );
      }).toList()
        ..sort(noteComparator(appProvider.sortOrder));

  // 🎯 显示添加笔记对话框，默认带当前标签
  void _showAddNoteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: '#$_normalizedTagName ', // 🎯 预填充当前标签
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              await appProvider.createNote(content);

              if (mounted && context.mounted) {
                Navigator.pop(context); // 关闭编辑器
                SnackBarUtils.showSuccess(
                  context,
                  AppLocalizationsSimple.of(context)?.noteCreatedSuccess ??
                      '笔记已创建',
                );
              }
            } on Object catch (e) {
              if (mounted && context.mounted) {
                SnackBarUtils.showError(
                  context,
                  '${AppLocalizationsSimple.of(context)?.createFailed ?? '创建失败'}: $e',
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
            } on Object catch (e) {
              if (mounted && context.mounted) {
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
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note,
              size: 60,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
          Text(
            '还没有带 #$_normalizedTagName 的笔记',
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
              '创建一条笔记会自动带上 #$_normalizedTagName',
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
            onPressed: () => _showAddNoteDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              '创建带 #$_normalizedTagName 的笔记',
            ),
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
  Widget _buildNotesList(BuildContext context, List<Note> notes) =>
      SlidableAutoCloseBehavior(
        child: ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.pixels(1000),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero, // 🎯 与主页一致：零padding
          itemCount: notes.length, // 🚀 性能优化：增加缓存区域
          itemBuilder: (context, index) {
            final note = notes[index];
            return RepaintBoundary(
              key: ValueKey(note.id), // 🚀 性能优化：避免不必要的重建
              child: NoteCard(
                key: ValueKey('card_${note.id}'), // 🚀 与主页一致
                note: note,
                onTagTap: _switchTag,
                onEdit: () {
                  // 🎯 与主页完全一致：弹出底部编辑器
                  _showEditNoteForm(note);
                },
                onDelete: () async {
                  final appProvider =
                      Provider.of<AppProvider>(context, listen: false);
                  await appProvider.deleteNote(note.id);
                  // Consumer 会自动监听 Provider 变化并更新UI
                },
                onPin: () async {
                  final appProvider =
                      Provider.of<AppProvider>(context, listen: false);
                  await appProvider.togglePinStatus(note);
                  // Consumer 会自动监听 Provider 变化并更新UI
                },
              ),
            );
          },
        ),
      );

  // 平板/桌面端列表布局（与主页完全一致）
  Widget _buildNotesGrid(
    BuildContext context,
    List<Note> notes, {
    required int crossAxisCount,
  }) =>
      SlidableAutoCloseBehavior(
        child: ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.pixels(1000),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsiveUtils.responsivePadding(
            context,
            all: 16,
          ),
          itemCount: notes.length, // 🚀 性能优化：增加缓存区域
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
                  onTagTap: _switchTag,
                  onEdit: () {
                    // 🎯 与主页完全一致：弹出底部编辑器
                    _showEditNoteForm(note);
                  },
                  onDelete: () async {
                    final appProvider =
                        Provider.of<AppProvider>(context, listen: false);
                    await appProvider.deleteNote(note.id);
                    // Consumer 会自动监听 Provider 变化并更新UI
                  },
                  onPin: () async {
                    final appProvider =
                        Provider.of<AppProvider>(context, listen: false);
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
