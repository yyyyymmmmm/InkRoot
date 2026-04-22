// 笔记表单模块（从 home_screen.dart 拆分）
// 职责：处理添加和编辑笔记的表单逻辑

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:provider/provider.dart';

/// 笔记表单助手类
///
/// 负责显示和处理：
/// 1. 添加笔记表单
/// 2. 编辑笔记表单
/// 3. 带初始内容的添加表单（用于分享接收）
class HomeNoteFormHelper {
  /// 退出搜索回调
  void Function()? onExitSearch;

  /// 滚动到顶部回调
  void Function()? onScrollToTop;

  /// 更新可见笔记数量回调
  void Function(int)? onUpdateVisibleCount;

  /// 显示添加笔记表单
  void showAddNoteForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final note = await appProvider.createNote(content);

              // 退出搜索模式
              onExitSearch?.call();

              // 更新可见笔记数量
              if (onUpdateVisibleCount != null) {
                final newCount = appProvider.notes.length >= 10 ? 10 : appProvider.notes.length;
                onUpdateVisibleCount!(newCount);
              }

              // 滚动到顶部
              onScrollToTop?.call();

              // 如果用户已登录但笔记未同步，尝试再次同步
              if (appProvider.isLoggedIn && !note.isSynced) {
                appProvider.syncNotesWithServer();
              }
            } catch (e) {
              if (kDebugMode) debugPrint('创建笔记失败: $e');
              if (context.mounted) {
                SnackBarUtils.showError(
                  context,
                  '${AppLocalizationsSimple.of(context)?.createNoteFailed ?? '创建笔记失败'}: $e',
                );
              }
            }
          }
        },
      ),
    );
  }

  /// 显示添加笔记表单（带初始内容）
  ///
  /// 用于分享接收场景
  void showAddNoteFormWithContent(BuildContext context, String initialContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: initialContent,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final note = await appProvider.createNote(content);

              // 退出搜索模式
              onExitSearch?.call();

              // 更新可见笔记数量
              if (onUpdateVisibleCount != null) {
                final newCount = appProvider.notes.length >= 10 ? 10 : appProvider.notes.length;
                onUpdateVisibleCount!(newCount);
              }

              // 滚动到顶部
              onScrollToTop?.call();

              // 如果用户已登录但笔记未同步，尝试再次同步
              if (appProvider.isLoggedIn && !note.isSynced) {
                appProvider.syncNotesWithServer();
              }

              // 显示成功提示
              if (context.mounted) {
                SnackBarUtils.showSuccess(
                  context,
                  AppLocalizationsSimple.of(context)?.addedFromShare ?? '已添加来自分享的笔记',
                );
              }
            } catch (e) {
              if (kDebugMode) debugPrint('创建笔记失败: $e');
              if (context.mounted) {
                SnackBarUtils.showError(
                  context,
                  '${AppLocalizationsSimple.of(context)?.createNoteFailed ?? '创建笔记失败'}: $e',
                );
              }
            }
          }
        },
      ),
    );
  }

  /// 显示编辑笔记表单
  void showEditNoteForm(BuildContext context, Note note) {
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
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);

              // 确保标签更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.notifyListeners();
              });
            } catch (e) {
              if (kDebugMode) debugPrint('更新笔记失败: $e');
              if (context.mounted) {
                SnackBarUtils.showError(
                  context,
                  '${AppLocalizationsSimple.of(context)?.updateFailed ?? '更新失败'}: $e',
                );
              }
            }
          }
        },
      ),
    );
  }
}
