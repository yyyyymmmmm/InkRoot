import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/services/ai_review_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/widgets/annotations_sidebar.dart';
import 'package:inkroot/widgets/ios_datetime_picker.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:inkroot/widgets/permission_guide_dialog.dart';
import 'package:inkroot/widgets/references_sidebar.dart';
import 'package:inkroot/widgets/share_image_preview_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// 📦 笔记操作服务
///
/// 封装所有笔记相关的业务逻辑：
/// - 编辑、删除、置顶
/// - 分享（文本/图片/链接）
/// - AI点评
/// - 提醒设置
/// - 引用查看
/// - 详情显示
///
/// 所有UI组件都通过这个服务执行笔记操作
class NoteActionsService {
  static const AiReviewService _aiReviewService = AiReviewService();

  /// 编辑笔记
  static Future<void> editNote({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: note.content,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);
              onUpdated();
              if (context.mounted) {
                SnackBarUtils.showSuccess(
                  context,
                  AppLocalizationsSimple.of(context)?.noteUpdated ?? '笔记已更新',
                );
              }
            } on Object catch (e) {
              if (context.mounted) {
                SnackBarUtils.showError(
                  context,
                  '${AppLocalizationsSimple.of(context)?.updatingFailed ?? '更新失败'}: $e',
                );
              }
            }
          }
        },
      ),
    );
  }

  /// 删除笔记（大厂标准：直接删除 + 撤销，无确认对话框）
  static Future<void> deleteNote({
    required BuildContext context,
    required Note note,
    required VoidCallback onDeleted,
  }) async {
    // 🎯 大厂标准（微信/iOS）：立即删除 + 提供撤销按钮
    // 优点：
    // 1. 流畅：无需等待确认对话框
    // 2. 安全：提供3秒撤销时间
    // 3. 批量友好：连续删除不会弹出多个对话框

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 先保存笔记内容（用于撤销）
      final deletedNote = note;

      // 立即删除（乐观更新）
      await appProvider.deleteNote(note.id);
      onDeleted();

      if (context.mounted) {
        // 🎨 显示带撤销按钮的SnackBar（2.5秒，留出操作时间）
        ScaffoldMessenger.of(context).clearSnackBars(); // 🎯 清除之前的通知，避免累积
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.noteDeleted ?? '笔记已删除',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: AppLocalizationsSimple.of(context)?.undo ?? '撤销',
              textColor: Colors.yellow[300],
              onPressed: () async {
                // 🎯 撤销删除：重新创建笔记
                try {
                  await appProvider.createNote(
                    deletedNote.content,
                    createdAt: deletedNote.createdAt,
                    updatedAt: deletedNote.updatedAt,
                  );
                  if (context.mounted) {
                    SnackBarUtils.showSuccess(
                      context,
                      AppLocalizationsSimple.of(context)?.undoDelete ?? '已撤销删除',
                    );
                  }
                } on Object catch (e) {
                  if (context.mounted) {
                    SnackBarUtils.showError(
                      context,
                      '${AppLocalizationsSimple.of(context)?.undoFailed ?? '撤销失败'}: $e',
                    );
                  }
                }
              },
            ),
            backgroundColor: const Color(0xFF2E7D32), // 成功绿色
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2500), // 2.5秒（给用户足够时间撤销）
            persist: false,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          '${AppLocalizationsSimple.of(context)?.deleteFailed ?? '删除失败'}: $e',
        );
      }
    }
  }

  /// 置顶/取消置顶
  static Future<void> togglePin({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      // 🔥 在切换之前判断：如果现在是置顶，操作后就是取消置顶；反之亦然
      final willPin = !note.isPinned; // 切换后的状态
      await appProvider.togglePinStatus(note);
      onUpdated();
      if (context.mounted) {
        SnackBarUtils.showSuccess(
          context,
          // 🔥 显示切换后的状态
          willPin
              ? (AppLocalizationsSimple.of(context)?.pinned ?? '已置顶')
              : (AppLocalizationsSimple.of(context)?.unpinned ?? '已取消置顶'),
        );
      }
    } on Object {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.operationFailed ?? '操作失败',
        );
      }
    }
  }

  /// 显示可见性选择器（公开/私有）
  static Future<void> showVisibilitySelector({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.visibility_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizationsSimple.of(context)?.noteVisibility ??
                        '笔记可见性',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (AppLocalizationsSimple.of(context)?.currentStatus ??
                        '当前：{status}')
                    .replaceAll(
                  '{status}',
                  note.isPublic
                      ? (AppLocalizationsSimple.of(context)?.public ?? '公开')
                      : (AppLocalizationsSimple.of(context)?.private ?? '私有'),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // 私有选项
              _buildVisibilityOption(
                context: context,
                icon: Icons.lock_outline,
                title: AppLocalizationsSimple.of(context)?.private ?? '私有',
                description:
                    AppLocalizationsSimple.of(context)?.privateDesc ?? '仅自己可见',
                isSelected: !note.isPublic,
                isDarkMode: isDarkMode,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  if (!note.isPublic) {
                    navigator.pop();
                    SnackBarUtils.showInfo(
                      context,
                      AppLocalizationsSimple.of(context)?.alreadyPrivate ??
                          '当前已是私有',
                    );
                    return;
                  }
                  // 关闭Sheet
                  navigator.pop();
                  // 执行设置
                  final success = await _setVisibility(
                    context: context,
                    note: note,
                    visibility: 'PRIVATE',
                    onUpdated: onUpdated,
                  );
                  // 显示结果通知
                  if (context.mounted) {
                    if (success) {
                      SnackBarUtils.showSuccess(
                        context,
                        AppLocalizationsSimple.of(context)?.setToPrivate ??
                            '已设为私有',
                      );
                    } else {
                      SnackBarUtils.showError(
                        context,
                        AppLocalizationsSimple.of(context)?.setFailed ?? '设置失败',
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 12),

              // 公开选项
              _buildVisibilityOption(
                context: context,
                icon: Icons.public_rounded,
                title: AppLocalizationsSimple.of(context)?.public ?? '公开',
                description: AppLocalizationsSimple.of(context)?.publicDesc ??
                    '任何人可通过链接查看',
                isSelected: note.isPublic,
                isDarkMode: isDarkMode,
                color: Colors.orange,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  if (note.isPublic) {
                    navigator.pop();
                    SnackBarUtils.showInfo(
                      context,
                      AppLocalizationsSimple.of(context)?.alreadyPublic ??
                          '当前已是公开',
                    );
                    return;
                  }
                  // 关闭Sheet
                  navigator.pop();
                  // 执行设置
                  final success = await _setVisibility(
                    context: context,
                    note: note,
                    visibility: 'PUBLIC',
                    onUpdated: onUpdated,
                  );
                  // 显示结果通知
                  if (context.mounted) {
                    if (success) {
                      SnackBarUtils.showSuccess(
                        context,
                        AppLocalizationsSimple.of(context)?.setToPublic ??
                            '已设为公开',
                      );
                    } else {
                      SnackBarUtils.showError(
                        context,
                        AppLocalizationsSimple.of(context)?.setFailed ?? '设置失败',
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建可见性选项
  static Widget _buildVisibilityOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? optionColor.withValues(alpha: 0.1)
                : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? optionColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: optionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: optionColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? optionColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: optionColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 设置可见性
  // 返回值：true=成功, false=失败
  static Future<bool> _setVisibility({
    required BuildContext context,
    required Note note,
    required String visibility,
    required VoidCallback onUpdated,
  }) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final updatedNote = await appProvider.setNoteVisibility(note, visibility);
      if (updatedNote != null) {
        onUpdated();
        return true;
      }
      return false;
    } on Object {
      return false;
    }
  }

  /// 显示分享选项菜单
  static Future<void> showShareOptions({
    required BuildContext context,
    required Note note,
  }) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareOptionsSheet(note: note, isDarkMode: isDarkMode),
    );
  }

  /// 分享文本
  static Future<void> shareText({
    required BuildContext context,
    required Note note,
  }) async {
    try {
      await Share.share(
        note.content,
        subject: AppLocalizationsSimple.of(context)?.shareNote ?? '分享笔记',
      );
    } on Object catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, '分享失败: $e');
      }
    }
  }

  /// 分享图片
  static Future<void> shareImage({
    required BuildContext context,
    required Note note,
  }) async {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShareImagePreviewScreen(
            noteId: note.id,
            content: note.content,
            timestamp: note.updatedAt,
          ),
          fullscreenDialog: true,
        ),
      ),
    );
  }

  /// 复制分享链接（需要先设为公开）
  static Future<void> copyShareLink({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    if (note.isPublic) {
      // 已经是公开状态，直接复制链接
      _copyShareLinkDirectly(context, note);
    } else {
      // 显示权限确认对话框
      _showPublicPermissionDialog(context, note, onUpdated);
    }
  }

  /// 直接复制分享链接
  static void _copyShareLinkDirectly(BuildContext context, Note note) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final serverUrl = appProvider.appConfig.memosApiUrl;
    final shareUrl = '$serverUrl/m/${note.id}';

    Clipboard.setData(ClipboardData(text: shareUrl));
    SnackBarUtils.showSuccess(
      context,
      AppLocalizationsSimple.of(context)?.linkCopied ?? '链接已复制到剪贴板',
    );
  }

  /// 显示公开权限确认对话框
  static void _showPublicPermissionDialog(
    BuildContext context,
    Note note,
    VoidCallback onUpdated,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.public_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizationsSimple.of(context)
                        ?.sharePermissionConfirmation ??
                    '分享权限确认',
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizationsSimple.of(context)?.sharePermissionMessage ??
              '要分享此笔记，需要将其设置为公开状态。\n任何拥有链接的人都可以查看该笔记的内容。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _proceedWithSharing(context, note, onUpdated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              AppLocalizationsSimple.of(context)?.confirmAndShare ?? '确定并分享',
            ),
          ),
        ],
      ),
    );
  }

  /// 执行分享操作（将笔记设为公开并复制链接）
  static Future<void> _proceedWithSharing(
    BuildContext context,
    Note note,
    VoidCallback onUpdated,
  ) async {
    try {
      // 显示加载对话框
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  AppLocalizationsSimple.of(context)?.generatingShareLink ??
                      '正在生成分享链接...',
                ),
              ],
            ),
          ),
        ),
      );

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final serverUrl =
          appProvider.appConfig.memosApiUrl ?? appProvider.user?.serverUrl;

      if (serverUrl == null || serverUrl.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        if (context.mounted) {
          SnackBarUtils.showError(context, '未登录或服务器配置错误');
        }
        return;
      }

      final updatedNote = await appProvider.setNoteVisibility(note, 'PUBLIC');

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (updatedNote != null) {
        onUpdated();
        final shareUrl = '$serverUrl/m/${updatedNote.id}';
        unawaited(Clipboard.setData(ClipboardData(text: shareUrl)));

        if (context.mounted) {
          SnackBarUtils.showSuccess(
            context,
            AppLocalizationsSimple.of(context)?.linkCopied ?? '链接已复制到剪贴板',
          );
        }
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            AppLocalizationsSimple.of(context)?.generateShareLinkFailed ??
                '生成分享链接失败',
          );
        }
      }
    } on Object catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          '${AppLocalizationsSimple.of(context)?.operationFailed ?? '操作失败'}: $e',
        );
      }
    }
  }

  /// 显示AI点评对话框（完整版 - 从详情页复制）
  static Future<void> showAiReview({
    required BuildContext context,
    required Note note,
  }) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final appConfig = appProvider.appConfig;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? aiReview;
    var isLoading = true;
    String? errorMessage;
    var reviewSource = AiReviewSource.local;

    // 🔥 使用底部Sheet替代Dialog - 更现代的体验
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => StatefulBuilder(
          builder: (context, setState) {
            // 开始点评。AI 未配置或失败时使用本地分析，不阻断用户。
            if (isLoading && aiReview == null && errorMessage == null) {
              _aiReviewService
                  .generateReview(
                appConfig: appConfig,
                note: note,
                allNotes: appProvider.notes,
              )
                  .then((result) {
                setState(() {
                  isLoading = false;
                  aiReview = result.review;
                  reviewSource = result.source;
                  errorMessage = null;
                });
                // 🔥 完成后显示提示
                if (result.usedRemote) {
                  if (!context.mounted) {
                    return;
                  }
                  SnackBarUtils.showSuccess(
                    context,
                    AppLocalizationsSimple.of(context)?.aiReviewCompleted ??
                        '✨ AI点评完成！',
                  );
                } else if (result.usedFallback && context.mounted) {
                  SnackBarUtils.showInfo(
                    context,
                    'AI暂不可用，已使用本地点评',
                  );
                }
              });
            }

            // 🔥 大厂风格的底部Sheet
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDarkMode ? 0.5 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 拖动指示器 - iOS风格
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white : Colors.black)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 🔥 标题栏 - 简洁现代
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        const Text(
                          '💬',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reviewSource == AiReviewSource.remote
                                ? (AppLocalizationsSimple.of(context)
                                        ?.aiReviewTitle ??
                                    '给你的点评')
                                : '本地点评',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : AppTheme.textPrimaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (!isLoading)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: (isDarkMode ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.5),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                  ),

                  // 🔥 内容区域 - flomo风格
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: isLoading
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 60),
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 20),
                                    Text(
                                      AppLocalizationsSimple.of(context)
                                              ?.aiReadingNote ??
                                          'AI正在阅读笔记...',
                                      style: TextStyle(
                                        color: (isDarkMode
                                                ? Colors.white
                                                : Colors.black)
                                            .withValues(alpha: 0.6),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 60,
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildReviewContent(
                                    aiReview!,
                                    isDarkMode,
                                  ),
                                ),
                    ),
                  ),

                  // 🔥 底部按钮 - 简洁设计
                  if (!isLoading && aiReview != null)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            // 复制按钮
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: aiReview!),
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                SnackBarUtils.showSuccess(
                                  context,
                                  AppLocalizationsSimple.of(context)
                                          ?.reviewCopiedShort ??
                                      '✨ 点评已复制',
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: Text(
                                AppLocalizationsSimple.of(context)
                                        ?.copyContent ??
                                    '复制',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: AppTheme.primaryColor,
                                ),
                                foregroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 完成按钮
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '完成',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 🔥 flomo风格的点评内容展示 - 带淡入动画
  static Widget _buildReviewContent(String review, bool isDarkMode) =>
      TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), // 从下往上淡入
            child: child,
          ),
        ),
        child: Text(
          review,
          style: TextStyle(
            fontSize: 16,
            height: 1.8,
            color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            letterSpacing: 0.3,
          ),
        ),
      );

  /// 显示引用详情（侧边栏版本 - 对标批注侧边栏）
  static Future<void> showReferences({
    required BuildContext context,
    required Note note,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReferencesSidebar(
          note: note,
          onNoteTap: (noteId) {
            Navigator.pop(context);
            // 导航到笔记详情页
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailScreen(noteId: noteId),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 显示提醒设置（完整版 - 从详情页复制，包含权限检查和完整UI）
  /// 返回值：true=设置成功, false=设置失败, null=用户取消
  static Future<bool?> showReminderSettings({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    if (Platform.isWindows || Platform.isLinux) {
      SnackBarUtils.showWarning(
        context,
        AppLocalizationsSimple.of(context)?.desktopReminderUnsupported ??
            '当前桌面系统暂不支持系统级定时提醒，请在手机或 macOS 上设置',
      );
      return false;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentReminderTime = note.reminderTime;

    // 🔥 直接进入时间选择，不再显示"修改/取消"选项

    // 🔥 先检查权限，没有权限先显示引导
    // 检查通知权限
    final notificationService = appProvider.notificationService;
    var hasPermission = await notificationService.areNotificationsEnabled();

    if (!hasPermission) {
      if (context.mounted) {
        // 显示权限引导弹窗
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PermissionGuideDialog(),
        );

        // 🔥 权限引导后重新检查权限
        hasPermission = await notificationService.areNotificationsEnabled();

        // 如果还是没有权限，提示用户并返回
        if (!hasPermission) {
          if (context.mounted) {
            SnackBarUtils.showWarning(
              context,
              AppLocalizationsSimple.of(context)?.enableNotificationFirst ??
                  '请先开启通知权限才能设置提醒',
            );
          }
          return null;
        }
      } else {
        return null;
      }
    }

    // 🔥 修复：确保初始时间不早于最小时间
    final now = DateTime.now();
    DateTime initialTime;

    if (currentReminderTime != null && currentReminderTime.isAfter(now)) {
      // 如果已有提醒时间且在未来，使用该时间
      initialTime = currentReminderTime;
    } else {
      // 否则使用1小时后
      initialTime = now.add(const Duration(hours: 1));
    }

    if (!context.mounted) {
      return null;
    }

    final reminderDateTime = await IOSDateTimePicker.show(
      context: context,
      initialDateTime: initialTime,
      minimumDateTime: now,
      maximumDateTime: now.add(const Duration(days: 365)),
      showQuickOptions: false, // 🔥 不显示快捷选择
    );
    if (!context.mounted) {
      return null;
    }

    // 用户取消了时间选择
    if (reminderDateTime == null) {
      return null;
    }

    // 检查时间是否在未来
    if (reminderDateTime.isBefore(DateTime.now())) {
      if (context.mounted) {
        SnackBarUtils.showWarning(
          context,
          AppLocalizationsSimple.of(context)?.reminderTimeMustBeFuture ??
              '提醒时间必须在未来',
        );
      }
      return false;
    }

    // 设置提醒
    try {
      final success =
          await appProvider.setNoteReminder(note.id, reminderDateTime);

      if (!success) {
        return false;
      }

      // 重新加载笔记
      onUpdated();

      return true;
    } on Object {
      return false;
    }
  }

  /// 显示笔记详情信息
  static Future<void> showNoteDetails({
    required BuildContext context,
    required Note note,
  }) async {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(AppLocalizationsSimple.of(context)?.detailedInfo ?? '详细信息'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context,
                AppLocalizationsSimple.of(context)?.characterCount ?? '字数',
                '${note.content.length}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                AppLocalizationsSimple.of(context)?.createdTime ?? '创建时间',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(note.createdAt),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                AppLocalizationsSimple.of(context)?.lastEdited ?? '最后编辑',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(note.updatedAt),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                AppLocalizationsSimple.of(context)?.noteVisibility ?? '笔记状态',
                note.isPublic
                    ? (AppLocalizationsSimple.of(context)?.public ?? '公开')
                    : (AppLocalizationsSimple.of(context)?.private ?? '私有'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizationsSimple.of(context)?.close ?? '关闭'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// 查看批注
  static Future<void> showAnnotations({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AnnotationsSidebar(
          note: note,
          onAnnotationTap: (annotation) {
            Navigator.pop(context);
            final localizations = AppLocalizationsSimple.of(context);
            SnackBarUtils.showSuccess(
              context,
              localizations?.locatedToAnnotation ?? '已定位到批注',
            );
          },
          onAddAnnotation: () {
            Navigator.pop(context);
            _showAddAnnotationDialog(context, note, onUpdated);
          },
          onEditAnnotation: (annotation) {
            Navigator.pop(context);
            _showEditAnnotationDialog(context, note, annotation, onUpdated);
          },
          onDeleteAnnotation: (annotationId) {
            Navigator.pop(context);
            _deleteAnnotation(context, note, annotationId, onUpdated);
          },
          onResolveAnnotation: (annotation) {
            _resolveAnnotation(context, note, annotation, onUpdated);
          },
        ),
      ),
    );
  }

  /// 添加批注对话框
  static Future<void> _showAddAnnotationDialog(
    BuildContext context,
    Note note,
    VoidCallback onUpdated,
  ) async {
    final textController = TextEditingController();
    var selectedType = AnnotationType.comment;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final localizations = AppLocalizationsSimple.of(context);
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.add_comment, size: 20),
                const SizedBox(width: 8),
                Text(localizations?.addAnnotation ?? '添加批注'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.annotationType ?? '批注类型',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AnnotationType.values.map((type) {
                      final annotation = Annotation(
                        id: '',
                        content: '',
                        createdAt: DateTime.now(),
                        type: type,
                      );
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(annotation.typeIcon, size: 16),
                            const SizedBox(width: 4),
                            Text(annotation.getTypeText(context)),
                          ],
                        ),
                        selected: selectedType == type,
                        selectedColor:
                            annotation.typeColor.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 5,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: localizations?.annotationPlaceholder ??
                          '在这里写下你的批注...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.cancel ?? '取消'),
              ),
              FilledButton(
                onPressed: () {
                  final content = textController.text.trim();
                  if (content.isNotEmpty) {
                    final appProvider =
                        Provider.of<AppProvider>(context, listen: false);
                    final newAnnotation = Annotation(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      content: content,
                      createdAt: DateTime.now(),
                      type: selectedType,
                    );
                    final updatedAnnotations = [
                      ...note.annotations,
                      newAnnotation,
                    ];
                    final updatedNote = note.copyWith(
                      annotations: updatedAnnotations,
                      updatedAt: DateTime.now(),
                    );
                    appProvider.updateNote(updatedNote, updatedNote.content);
                    Navigator.pop(context);
                    SnackBarUtils.showSuccess(
                      context,
                      localizations?.annotationAdded ?? '批注已添加',
                    );
                    onUpdated();
                  }
                },
                child: Text(localizations?.addAnnotation ?? '添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 编辑批注对话框
  static Future<void> _showEditAnnotationDialog(
    BuildContext context,
    Note note,
    Annotation annotation,
    VoidCallback onUpdated,
  ) async {
    final textController = TextEditingController(text: annotation.content);
    var selectedType = annotation.type;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizationsSimple.of(context)?.editAnnotation ?? '编辑批注',
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.annotationType ?? '批注类型',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AnnotationType.values.map((type) {
                    final tempAnnotation = Annotation(
                      id: '',
                      content: '',
                      createdAt: DateTime.now(),
                      type: type,
                    );
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tempAnnotation.typeIcon, size: 16),
                          const SizedBox(width: 4),
                          Text(tempAnnotation.typeText),
                        ],
                      ),
                      selected: selectedType == type,
                      selectedColor:
                          tempAnnotation.typeColor.withValues(alpha: 0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedType = type);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizationsSimple.of(context)
                            ?.annotationEditPlaceholder ??
                        '修改批注内容...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
            ),
            FilledButton(
              onPressed: () {
                final content = textController.text.trim();
                if (content.isNotEmpty) {
                  final appProvider =
                      Provider.of<AppProvider>(context, listen: false);
                  final updatedAnnotations = note.annotations.map((a) {
                    if (a.id == annotation.id) {
                      return a.copyWith(
                        content: content,
                        type: selectedType,
                        updatedAt: DateTime.now(),
                      );
                    }
                    return a;
                  }).toList();
                  final updatedNote = note.copyWith(
                    annotations: updatedAnnotations,
                    updatedAt: DateTime.now(),
                  );
                  appProvider.updateNote(updatedNote, updatedNote.content);
                  Navigator.pop(context);
                  SnackBarUtils.showSuccess(
                    context,
                    AppLocalizationsSimple.of(context)?.annotationUpdated ??
                        '批注已更新',
                  );
                  onUpdated();
                }
              },
              child: Text(AppLocalizationsSimple.of(context)?.save ?? '保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 删除批注
  static Future<void> _deleteAnnotation(
    BuildContext context,
    Note note,
    String annotationId,
    VoidCallback onUpdated,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizationsSimple.of(context)?.deleteAnnotation ?? '删除批注',
        ),
        content: Text(
          AppLocalizationsSimple.of(context)?.confirmDeleteAnnotation ??
              '确定要删除这条批注吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
          ),
          FilledButton(
            onPressed: () {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              final updatedAnnotations =
                  note.annotations.where((a) => a.id != annotationId).toList();
              final updatedNote = note.copyWith(
                annotations: updatedAnnotations,
                updatedAt: DateTime.now(),
              );
              appProvider.updateNote(updatedNote, updatedNote.content);
              Navigator.pop(context);
              SnackBarUtils.showSuccess(
                context,
                AppLocalizationsSimple.of(context)?.annotationDeleted ??
                    '批注已删除',
              );
              onUpdated();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizationsSimple.of(context)?.delete ?? '删除'),
          ),
        ],
      ),
    );
  }

  /// 标记批注为已解决
  static void _resolveAnnotation(
    BuildContext context,
    Note note,
    Annotation annotation,
    VoidCallback onUpdated,
  ) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final updatedAnnotations = note.annotations.map((a) {
      if (a.id == annotation.id) {
        return a.copyWith(isResolved: true);
      }
      return a;
    }).toList();
    final updatedNote = note.copyWith(
      annotations: updatedAnnotations,
      updatedAt: DateTime.now(),
    );
    appProvider.updateNote(updatedNote, updatedNote.content);
    SnackBarUtils.showSuccess(context, '已标记为已解决');
    onUpdated();
  }
}

/// 分享选项底部面板
class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet({
    required this.note,
    required this.isDarkMode,
  });
  final Note note;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              AppLocalizationsSimple.of(context)?.shareNote ?? '分享笔记',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // 分享选项
            Row(
              children: [
                Expanded(
                  child: _buildShareOption(
                    context,
                    icon: Icons.text_fields,
                    label: AppLocalizationsSimple.of(context)?.share ?? '分享',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      NoteActionsService.shareText(
                        context: context,
                        note: note,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareOption(
                    context,
                    icon: Icons.image_rounded,
                    label:
                        AppLocalizationsSimple.of(context)?.shareImage ?? '图片',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      NoteActionsService.shareImage(
                        context: context,
                        note: note,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
