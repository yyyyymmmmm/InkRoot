import 'package:flutter/material.dart';
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/note_actions_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

/// 🎨 笔记更多选项菜单组件（Popup菜单版）
///
/// 在点击位置附近弹出，符合iOS上下文菜单设计规范
class NoteMoreOptionsMenu {
  /// 显示更多选项菜单（在点击位置附近）
  static Future<void> show({
    required BuildContext context,
    required Note note,
    VoidCallback? onNoteUpdated,
  }) {
    // 自动获取点击按钮的位置
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Offset offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size size = renderBox?.size ?? Size.zero;
    
    // 计算菜单弹出位置（在按钮右下方）
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx + size.width - 200, // 左边距：按钮右边往左200px
      offset.dy + size.height, // 上边距：按钮底部
      offset.dx, // 右边距
      0, // 下边距
    );
    
    return _showMenuAt(
      context: context,
      note: note,
      position: position,
      onNoteUpdated: onNoteUpdated,
    );
  }
  
  /// 内部方法：在指定位置显示菜单
  static Future<void> _showMenuAt({
    required BuildContext context,
    required Note note,
    required RelativeRect position,
    VoidCallback? onNoteUpdated,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizationsSimple.of(context);
    
    // 用于在异步操作后刷新笔记数据
    Future<void> reloadNote() async {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final updatedNote = appProvider.notes.firstWhere(
        (n) => n.id == note.id,
        orElse: () => note,
      );
      note = updatedNote;
    }

    return showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
      items: [
        // 分享
        PopupMenuItem<String>(
          value: 'share',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.ios_share_rounded,
            label: localizations?.share ?? '分享',
            isDarkMode: isDarkMode,
          ),
        ),
        // 编辑
        PopupMenuItem<String>(
          value: 'edit',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.edit_rounded,
            label: localizations?.edit ?? '编辑',
            isDarkMode: isDarkMode,
          ),
        ),
        // 查看批注
        PopupMenuItem<String>(
          value: 'annotations',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.comment_outlined,
            label: localizations?.viewAnnotations ?? '查看批注',
            isDarkMode: isDarkMode,
            trailing: note.annotations.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${note.annotations.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        // 置顶/取消置顶
        PopupMenuItem<String>(
          value: 'pin',
          height: 44,
          child: _buildMenuItem(
            icon: note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: note.isPinned
                ? (localizations?.unpinNote ?? '取消置顶')
                : (localizations?.pinNote ?? '置顶'),
            isDarkMode: isDarkMode,
          ),
        ),
        // AI点评
        PopupMenuItem<String>(
          value: 'ai',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.psychology_rounded,
            label: localizations?.aiReview ?? 'AI点评',
            isDarkMode: isDarkMode,
          ),
        ),
        // 链接
        PopupMenuItem<String>(
          value: 'link',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.link_rounded,
            label: localizations?.linkNote ?? '链接',
            isDarkMode: isDarkMode,
          ),
        ),
        // 引用详情
        PopupMenuItem<String>(
          value: 'reference',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.account_tree_outlined,
            label: localizations?.referenceDetails ?? '引用详情',
            isDarkMode: isDarkMode,
          ),
        ),
        // 提醒设置（根据配置显示）
        if (Config.AppConfig.enableReminders)
          PopupMenuItem<String>(
            value: 'reminder',
            height: 44,
            child: _buildMenuItem(
              icon: Icons.alarm_add,
              label: localizations?.setReminder ?? '提醒设置',
              isDarkMode: isDarkMode,
              trailing: note.reminderTime != null
                  ? Text(
                      localizations?.reminderSet ?? '已设置',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    )
                  : null,
            ),
          ),
        // 可见性
        PopupMenuItem<String>(
          value: 'visibility',
          height: 44,
          child: _buildMenuItem(
            icon: note.isPublic ? Icons.public : Icons.lock_outline,
            label: localizations?.noteVisibility ?? '可见性',
            isDarkMode: isDarkMode,
            trailing: Text(
              note.isPublic
                  ? (localizations?.public ?? '公开')
                  : (localizations?.private ?? '私有'),
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
        ),
        // 修改时间
        PopupMenuItem<String>(
          value: 'change_time',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.access_time_rounded,
            label: localizations?.changeTime ?? '修改时间',
            isDarkMode: isDarkMode,
          ),
        ),
        // 详细信息
        PopupMenuItem<String>(
          value: 'info',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.info_outline,
            label: localizations?.detailedInfo ?? '详细信息',
            isDarkMode: isDarkMode,
          ),
        ),
        // 删除
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          child: _buildMenuItem(
            icon: Icons.delete_rounded,
            label: localizations?.delete ?? '删除',
            isDarkMode: isDarkMode,
            isDanger: true,
          ),
        ),
      ],
    ).then((value) async {
      if (value == null) return;

      switch (value) {
        case 'share':
          await NoteActionsService.showShareOptions(
            context: context,
            note: note,
          );
          break;
        case 'edit':
          await NoteActionsService.editNote(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          break;
        case 'annotations':
          await NoteActionsService.showAnnotations(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          break;
        case 'pin':
          await NoteActionsService.togglePin(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          break;
        case 'ai':
          await NoteActionsService.showAiReview(
            context: context,
            note: note,
          );
          break;
        case 'link':
          await NoteActionsService.copyShareLink(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          break;
        case 'reference':
          await NoteActionsService.showReferences(
            context: context,
            note: note,
          );
          break;
        case 'reminder':
          final result = await NoteActionsService.showReminderSettings(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          // 🔥 显示通知
          if (context.mounted) {
            if (result == true) {
              SnackBarUtils.showSuccess(context, '设置成功');
            } else if (result == false) {
              SnackBarUtils.showError(context, '设置失败');
            }
          }
          break;
        case 'visibility':
          await NoteActionsService.showVisibilitySelector(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          break;
        case 'change_time':
          await _showChangeTimeDialog(
            context: context,
            note: note,
            onUpdated: () {
              reloadNote();
              onNoteUpdated?.call();
            },
          );
          break;
        case 'info':
          await NoteActionsService.showNoteDetails(
            context: context,
            note: note,
          );
          break;
        case 'delete':
          await NoteActionsService.deleteNote(
            context: context,
            note: note,
            onDeleted: () {
              onNoteUpdated?.call();
            },
          );
          break;
      }
    });
  }

  /// 显示修改时间对话框
  static Future<void> _showChangeTimeDialog({
    required BuildContext context,
    required Note note,
    required VoidCallback onUpdated,
  }) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final localizations = AppLocalizationsSimple.of(context);
    
    debugPrint('🕐 [ChangeTime] 开始修改时间');
    debugPrint('🕐 [ChangeTime] 笔记ID: ${note.id}');
    debugPrint('🕐 [ChangeTime] 当前updatedAt: ${note.updatedAt}');
    debugPrint('🕐 [ChangeTime] 当前createdAt: ${note.createdAt}');
    
    DateTime selectedDate = note.updatedAt;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(note.updatedAt);
    
    // 显示日期选择器
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1970), // 允许选择很早的时间
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 允许选择未来10年
      locale: Localizations.localeOf(context), // 明确指定locale
      helpText: localizations?.selectDate ?? '选择日期',
      cancelText: localizations?.cancel ?? '取消',
      confirmText: localizations?.confirm ?? '确定',
      builder: (context, child) {
        // 修复宽度溢出问题
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate == null || !context.mounted) {
      debugPrint('🕐 [ChangeTime] 用户取消选择日期或context已销毁');
      return;
    }
    
    debugPrint('🕐 [ChangeTime] 用户选择的日期: $pickedDate');
    
    // 显示时间选择器
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      helpText: localizations?.selectTime ?? '选择时间',
      cancelText: localizations?.cancel ?? '取消',
      confirmText: localizations?.confirm ?? '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime == null || !context.mounted) {
      debugPrint('🕐 [ChangeTime] 用户取消选择时间或context已销毁');
      return;
    }
    
    debugPrint('🕐 [ChangeTime] 用户选择的时间: $pickedTime');
    
    // 合并日期和时间
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    
    debugPrint('🕐 [ChangeTime] 合并后的新时间: $newDateTime');
    debugPrint('🕐 [ChangeTime] 原始时间: ${note.updatedAt}');
    
    // 更新笔记时间（仅本地操作，不同步到服务器）
    try {
      final updatedNote = note.copyWith(
        updatedAt: newDateTime,
        // ✅ 保持已同步状态，避免触发服务器同步
        // 因为 Memos API 不支持自定义 updatedAt，修改时间是纯本地功能
        isSynced: note.isSynced,
      );
      
      debugPrint('🕐 [ChangeTime] 创建updatedNote，新的updatedAt: ${updatedNote.updatedAt}');
      debugPrint('🕐 [ChangeTime] 直接更新本地数据库和内存，不同步到服务器');
      
      // ✅ 直接更新本地数据库，不触发服务器同步
      await appProvider.updateNoteLocally(updatedNote);
      
      debugPrint('🕐 [ChangeTime] 本地更新完成');
      
      if (context.mounted) {
        SnackBarUtils.showSuccess(
          context,
          localizations?.timeUpdated ?? '时间已更新',
        );
        debugPrint('🕐 [ChangeTime] 调用onUpdated回调');
        onUpdated();
      }
    } catch (e, stackTrace) {
      debugPrint('🕐 [ChangeTime] ❌ 更新失败: $e');
      debugPrint('🕐 [ChangeTime] ❌ 堆栈: $stackTrace');
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          localizations?.timeUpdateFailed ?? '时间更新失败',
        );
      }
    }
  }

  /// 构建菜单项
  static Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    bool isDanger = false,
    Widget? trailing,
  }) {
    final iconColor = isDanger
        ? const Color(0xFFFF3B30)
        : (isDarkMode ? Colors.grey[400]! : Colors.grey[700]!);
    final textColor = isDanger
        ? const Color(0xFFFF3B30)
        : (isDarkMode ? Colors.white : Colors.black);

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
