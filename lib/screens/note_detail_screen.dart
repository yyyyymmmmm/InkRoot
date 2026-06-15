import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/ai_enhanced_service.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/services/intelligent_related_notes_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/logger.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/utils/todo_parser.dart';
import 'package:inkroot/widgets/annotations_sidebar.dart';
import 'package:inkroot/widgets/intelligent_related_notes_sheet.dart';
import 'package:inkroot/widgets/memos_markdown_renderer.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:inkroot/widgets/note_more_options_menu.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({required this.noteId, super.key});
  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? _note;

  // 🧠 智能相关笔记
  bool _isLoadingRelatedNotes = false;
  final IntelligentRelatedNotesService _intelligentRelatedNotesService =
      IntelligentRelatedNotesService();

  // AI 摘要
  final AIEnhancedService _aiEnhancedService = AIEnhancedService();
  String? _aiSummary;
  bool _isGeneratingSummary = false;
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final note = appProvider.getNoteById(widget.noteId) ??
        await appProvider.databaseService.getNoteById(widget.noteId);
    if (!mounted) {
      return;
    }
    setState(() {
      _note = note;
    });
  }

  // 🔥 处理链接点击
  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) {
      return;
    }

    try {
      // 处理笔记内部引用 [[noteId]]
      if (href.startsWith('[[') && href.endsWith(']]')) {
        final noteId = href.substring(2, href.length - 2);
        if (mounted) {
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NoteDetailScreen(noteId: noteId),
              ),
            ),
          );
        }
        return;
      }

      // 处理外部链接
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${AppLocalizationsSimple.of(context)?.unableToOpenLink ?? '无法打开链接'}: $href',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizationsSimple.of(context)?.linkError ?? '链接错误'}: $e',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // 🔥 AI点评功能 - 大厂风格底部Sheet
  Future<void> _showAiReviewDialog() async {
    if (_note == null) {
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final appConfig = appProvider.appConfig;

    // 检查AI功能是否启用
    if (!appConfig.aiEnabled) {
      if (mounted) {
        SnackBarUtils.showWarning(
          context,
          AppLocalizationsSimple.of(context)?.enableAIFirst ?? '请先在设置中启用AI功能',
        );
      }
      return;
    }

    // 检查API配置
    if (appConfig.aiApiUrl == null ||
        appConfig.aiApiUrl!.isEmpty ||
        appConfig.aiApiKey == null ||
        appConfig.aiApiKey!.isEmpty) {
      if (mounted) {
        SnackBarUtils.showWarning(
          context,
          AppLocalizationsSimple.of(context)?.configureAIFirst ??
              '请先在设置中配置AI API',
        );
      }
      return;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? aiReview;
    var isLoading = true;
    String? errorMessage;

    // 🔥 使用底部Sheet替代Dialog - 更现代的体验
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => StatefulBuilder(
          builder: (context, setState) {
            // 开始AI点评
            if (isLoading && aiReview == null && errorMessage == null) {
              _getAiReview(appConfig, _note!.content).then((result) {
                final (review, error) = result;
                if (mounted && context.mounted) {
                  setState(() {
                    isLoading = false;
                    aiReview = review != null
                        ? _cleanMarkdownForReview(review)
                        : null; // 🔥 清理Markdown符号
                    errorMessage = error;
                  });
                  // 🔥 完成后显示提示
                  if (review != null) {
                    SnackBarUtils.showSuccess(
                      context,
                      AppLocalizationsSimple.of(context)?.aiReviewCompleted ??
                          '✨ AI点评完成！',
                    );
                  }
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
                            AppLocalizationsSimple.of(context)?.aiReviewTitle ??
                                '给你的点评',
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
                                if (mounted && context.mounted) {
                                  SnackBarUtils.showSuccess(
                                    context,
                                    AppLocalizationsSimple.of(context)
                                            ?.reviewCopiedShort ??
                                        '✨ 点评已复制',
                                  );
                                }
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
  Widget _buildReviewContent(String review, bool isDarkMode) =>
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

  // 🔥 清理Markdown符号，转换为纯文本
  String _cleanMarkdownForReview(String text) {
    var cleaned = text;

    // 移除Markdown标题符号 (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

    // 移除加粗符号 (** __ )
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp('__(.*?)__'), r'$1');

    // 移除斜体符号 (* _)
    cleaned = cleaned.replaceAll(
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
      r'$1',
    );
    cleaned =
        cleaned.replaceAll(RegExp('(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'), r'$1');

    // 移除删除线 (~~)
    cleaned = cleaned.replaceAll(RegExp('~~(.*?)~~'), r'$1');

    // 移除代码块符号 (```)
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp('`(.*?)`'), r'$1');

    // 移除链接格式 [text](url)
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

    // 移除图片格式 ![alt](url)
    cleaned = cleaned.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), r'$1');

    // 移除引用符号 (>)
    cleaned = cleaned.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

    // 移除水平线 (--- ***)
    cleaned =
        cleaned.replaceAll(RegExp(r'^[\-\*]{3,}\s*$', multiLine: true), '');

    // 移除列表符号 (- * 1.)
    cleaned = cleaned.replaceAll(RegExp(r'^[\-\*\+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    // 清理多余的空行（保留段落间的单个空行）
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  // 调用AI进行点评 - 优化Prompt为flomo风格
  Future<(String?, String?)> _getAiReview(
    AppConfig appConfig,
    String content,
  ) async {
    try {
      final apiService = DeepSeekApiService(
        apiUrl: appConfig.aiApiUrl!,
        apiKey: appConfig.aiApiKey!,
        model: appConfig.aiModel,
      );

      // 🔥 使用自定义Prompt或系统默认Prompt
      final systemPrompt = appConfig.useCustomPrompt &&
              appConfig.customReviewPrompt != null &&
              appConfig.customReviewPrompt!.isNotEmpty
          ? appConfig.customReviewPrompt!
          : '''
你是一位善于发现价值的笔记评论者，用自然对话方式提供完整的分析闭环。

输出格式要求（重要！）：
- 纯文本，不要用 # * ** 等Markdown符号
- 不要用emoji
- 用"你"称呼用户
- 直接进入内容，不要固定开头
- 3-4句话，控制在80字左右
- 语气自然、坦诚

内容结构（微型闭环）：

第1句 - 核心洞察：
直接指出笔记中最值得关注的点，或提出一个有洞察力的观察。

第2句 - 肯定/改进：
快速指出闪光点或可优化之处（选一个重点说）。用"这里不错"、"或许可以"等自然表述。

第3-4句 - 建议/启发：
给出一个清晰、可操作的建议，或提出启发性思考。

写作风格：
- 像Notion AI那样：直接、专业、有温度
- 坦诚但不批评，简洁但有深度
- 保持对话感，不要说教
''';

      final messages = [
        DeepSeekApiService.buildSystemMessage(systemPrompt),
        DeepSeekApiService.buildUserMessage('请点评这篇笔记（80字左右）：\n\n$content'),
      ];

      return await apiService.chat(messages: messages);
    } on Object catch (e) {
      return (null, 'AI点评失败: $e');
    }
  }

  void _showEditNoteForm(Note note) {
    showModalBottomSheet(
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
              await _loadNote(); // 重新加载笔记
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizationsSimple.of(context)?.noteUpdated ??
                              '笔记已更新',
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            } on Object catch (e) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          '${AppLocalizationsSimple.of(context)?.updateFailed ?? '更新失败'}: $e',
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  // 显示更多选项菜单（统一使用 NoteMoreOptionsMenu）
  void _showMoreOptions(BuildContext btnContext) {
    if (_note == null) {
      return;
    }

    NoteMoreOptionsMenu.show(
      context: btnContext,
      note: _note!,
      onNoteUpdated: _loadNote,
    );
  }

  // 🎯 切换笔记中指定索引的待办事项
  void _toggleTodoInNote(int todoIndex) {
    if (_note == null) {
      return;
    }

    final todos = TodoParser.parseTodos(_note!.content);
    if (todoIndex < 0 || todoIndex >= todos.length) {
      if (kDebugMode) {
        debugPrint('NoteDetailScreen: 待办事项索引越界 $todoIndex/${todos.length}');
      }
      return;
    }

    final todo = todos[todoIndex];
    final newContent =
        TodoParser.toggleTodoAtLine(_note!.content, todo.lineNumber);
    if (kDebugMode) {
      debugPrint(
        'NoteDetailScreen: 切换待办事项 #$todoIndex 行${todo.lineNumber}: "${todo.text}"',
      );
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateNote(_note!, newContent).then((_) {
      if (kDebugMode) {
        debugPrint('NoteDetailScreen: 待办事项状态已更新');
      }
      _loadNote(); // 刷新笔记数据
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('NoteDetailScreen: 更新待办事项失败: $error');
      }
      if (!mounted) {
        return;
      }
      SnackBarUtils.showError(context, '更新失败');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_note == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizationsSimple.of(context)?.noteDetail ?? '笔记详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? Colors.grey[400]! : const Color(0xFF666666);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          AppLocalizationsSimple.of(context)?.noteDetail ?? '笔记详情',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // 📝 AI 摘要按钮
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _showSummary ? iconColor.withValues(alpha: 0.1) : bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.article_outlined, size: 20, color: iconColor),
            ),
            tooltip:
                AppLocalizationsSimple.of(context)?.aiSummary ?? 'AI Summary',
            onPressed: () {
              if (_showSummary && _aiSummary != null) {
                setState(() => _showSummary = false);
              } else {
                _generateAISummary();
              }
            },
          ),
          // 🔥 AI点评按钮
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.psychology_rounded, size: 20, color: iconColor),
            ),
            tooltip: AppLocalizationsSimple.of(context)?.aiReview ?? 'AI点评',
            onPressed: _showAiReviewDialog,
          ),
          // 编辑按钮
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, size: 20, color: iconColor),
            ),
            tooltip: AppLocalizationsSimple.of(context)?.editNote ?? '编辑笔记',
            onPressed: () => _showEditNoteForm(_note!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : double.infinity,
          ),
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Card(
            elevation: isDesktop ? 2 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            ),
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部：时间 + 更多按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(_note!.updatedAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                          if (_note!.reminderTime != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.alarm,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '提醒: ${DateFormat('MM-dd HH:mm').format(_note!.reminderTime!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      Builder(
                        builder: (btnContext) => InkWell(
                          onTap: () => _showMoreOptions(btnContext),
                          child: Icon(
                            Icons.more_horiz,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 中间：笔记内容（双击编辑）
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () {
                        if (kDebugMode) {
                          debugPrint('🖱️ 双击检测到，打开编辑');
                        }
                        _showEditNoteForm(_note!);
                      },
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AI 摘要卡片
                            if (_showSummary)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode
                                        ? [
                                            AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            AppTheme.accentColor
                                                .withValues(alpha: 0.1),
                                          ]
                                        : [
                                            AppTheme.primaryColor
                                                .withValues(alpha: 0.05),
                                            AppTheme.accentColor
                                                .withValues(alpha: 0.05),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: iconColor.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                iconColor,
                                                AppTheme.accentColor,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizationsSimple.of(context)
                                                  ?.aiSummary ??
                                              'AI Summary',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.close, size: 18),
                                          onPressed: () => setState(
                                            () => _showSummary = false,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_isGeneratingSummary)
                                      Center(
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  iconColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '正在生成摘要...',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_aiSummary != null)
                                      Text(
                                        _aiSummary!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.6,
                                          color: textColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            // 原有的笔记内容
                            Builder(
                              builder: (context) {
                                final serverUrl = Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                ).appConfig.memosApiUrl;

                                return MemosMarkdownRenderer.fromNote(
                                  note: _note!,
                                  serverUrl: serverUrl,
                                  onCheckboxTap:
                                      _toggleTodoInNote, // 🎯 复选框点击回调（传递索引）
                                  onTagTap: (tagName) {
                                    // 🎯 大厂导航模式：详情页点击标签 → 返回到标签列表页
                                    // 而不是推入新页面（避免：标签A详情 → 标签B列表 → 标签B详情 → ...）

                                    try {
                                      final currentRoute =
                                          GoRouterState.of(context)
                                              .uri
                                              .toString();

                                      // 如果当前在标签筛选页进入的详情页
                                      if (currentRoute
                                          .contains('/tags/detail')) {
                                        // 策略1：直接返回到标签页（用户可以重新选择标签）
                                        if (mounted) {
                                          context.pop(); // 返回到上一页（标签列表）
                                        }
                                      } else {
                                        // 策略2：从其他入口（如主页）进入，可以跳转到标签页
                                        if (mounted) {
                                          // 使用 go 而不是 push，替换当前页面栈
                                          context.go(
                                            '/tags/detail?tag=${Uri.encodeComponent(tagName)}',
                                          );
                                        }
                                      }
                                    } on Object catch (e, stackTrace) {
                                      Log.ui.error(
                                        'Failed to navigate from note detail tag',
                                        error: e,
                                        stackTrace: stackTrace,
                                        data: {'tagName': tagName},
                                      );
                                    }
                                  },
                                  onLinkTap: _handleLinkTap,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 底部：字数统计 + 批注图标
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 左侧：字数统计
                      Text(
                        '${_note!.content.length} 字',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                      // 右侧：批注图标
                      _buildAnnotationBadge(isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // 🚀 添加魔法棒 FAB
      floatingActionButton: _buildAIRelatedNotesFAB(isDarkMode),
    );
  }

  /// 🧠 查找并显示智能相关笔记（使用最新的智能推荐系统）
  Future<void> _findRelatedNotes() async {
    if (_note == null) {
      return;
    }

    setState(() {
      _isLoadingRelatedNotes = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 🧠 使用智能相关笔记服务进行分析
      final result =
          await _intelligentRelatedNotesService.findIntelligentRelatedNotes(
        currentNote: _note!,
        allNotes: appProvider.notes,
        apiKey: appProvider.appConfig.aiApiKey,
        apiUrl: appProvider.appConfig.aiApiUrl,
        model: appProvider.appConfig.aiModel,
      );

      setState(() {
        _isLoadingRelatedNotes = false;
      });

      // 显示智能相关笔记结果
      if (!mounted) {
        return;
      }

      if (result.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          AppLocalizationsSimple.of(context)?.aiRelatedNotesEmpty ?? '未找到相关笔记',
        );
      } else {
        // 🎨 显示现代化的智能相关笔记抽屉
        await IntelligentRelatedNotesSheet.show(context, result);
      }
    } on Object catch (e) {
      debugPrint('❌ 查找相关笔记失败: $e');
      setState(() {
        _isLoadingRelatedNotes = false;
      });
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '查找相关笔记失败：$e',
        );
      }
    }
  }

  /// 构建 AI 相关笔记 FAB（带脉冲动画）
  Widget _buildAIRelatedNotesFAB(bool isDark) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 1.1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? AppTheme.primaryLightColor
                          : AppTheme.primaryColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _isLoadingRelatedNotes ? null : _findRelatedNotes,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: _isLoadingRelatedNotes
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
        onEnd: () {
          // 反向动画
          if (mounted) {
            setState(() {});
          }
        },
      );

  /// 生成 AI 摘要
  Future<void> _generateAISummary() async {
    if (_note == null || _isGeneratingSummary) {
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
      _showSummary = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 获取 AI 配置
      final apiKey = appProvider.appConfig.aiApiKey;
      final apiUrl = appProvider.appConfig.aiApiUrl;
      final model = appProvider.appConfig.aiModel;

      // 检查配置
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiUrl == null ||
          apiUrl.isEmpty) {
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.aiApiConfigRequired ??
              'Please configure AI API in settings first',
        );
        setState(() {
          _isGeneratingSummary = false;
          _showSummary = false;
        });
        return;
      }

      // 生成摘要
      final (summary, error) = await _aiEnhancedService.generateSummary(
        content: _note!.content,
        apiKey: apiKey,
        apiUrl: apiUrl,
        model: model,
      );

      if (error != null) {
        SnackBarUtils.showError(context, error);
        setState(() {
          _isGeneratingSummary = false;
          _showSummary = false;
        });
        return;
      }

      setState(() {
        _aiSummary = summary;
        _isGeneratingSummary = false;
      });
    } on Object catch (e) {
      debugPrint('❌ 生成摘要失败: $e');
      setState(() {
        _isGeneratingSummary = false;
        _showSummary = false;
      });
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.aiGenerateSummaryFailed ??
            'Failed to generate summary, please try again later',
      );
    }
  }

  // 📝 构建批注图标（右下角）
  Widget _buildAnnotationBadge(bool isDarkMode) {
    final annotationCount = _note!.annotations.length;

    // 如果没有批注，返回空Widget
    if (annotationCount == 0) {
      return const SizedBox.shrink();
    }

    // 返回批注图标（右下角）- 可点击
    return InkWell(
      onTap: _showAnnotationsSidebar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 16,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '$annotationCount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 显示批注侧边栏
  void _showAnnotationsSidebar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AnnotationsSidebar(
          note: _note!,
          onAnnotationTap: _onAnnotationTap,
          onAddAnnotation: _onAddAnnotation,
          onEditAnnotation: _onEditAnnotation,
          onDeleteAnnotation: _onDeleteAnnotation,
          onResolveAnnotation: _onResolveAnnotation,
        ),
      ),
    );
  }

  // 📝 点击批注 - 跳转到对应位置
  void _onAnnotationTap(Annotation annotation) {
    Navigator.pop(context); // 关闭侧边栏
    SnackBarUtils.showSuccess(context, '已定位到批注');
  }

  // 📝 添加批注
  void _onAddAnnotation() {
    Navigator.pop(context); // 关闭侧边栏

    final textController = TextEditingController();
    var selectedType = AnnotationType.comment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_comment, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizationsSimple.of(context)?.addAnnotation ?? '添加批注'),
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
                          Text(annotation.typeText),
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
                    hintText: AppLocalizationsSimple.of(context)
                            ?.annotationPlaceholder ??
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
              child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
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
                    ..._note!.annotations,
                    newAnnotation,
                  ];
                  final updatedNote = _note!.copyWith(
                    annotations: updatedAnnotations,
                    updatedAt: DateTime.now(),
                  );
                  appProvider.updateNote(updatedNote, updatedNote.content);
                  this.setState(() {
                    _note = updatedNote;
                  });
                  Navigator.pop(context);
                  SnackBarUtils.showSuccess(
                    context,
                    AppLocalizationsSimple.of(context)?.annotationAdded ??
                        '批注已添加',
                  );
                }
              },
              child: Text(AppLocalizationsSimple.of(context)?.add ?? '添加'),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 编辑批注
  void _onEditAnnotation(Annotation annotation) {
    Navigator.pop(context); // 关闭侧边栏

    final textController = TextEditingController(text: annotation.content);
    var selectedType = annotation.type;

    showDialog(
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
                  final updatedAnnotations = _note!.annotations.map((a) {
                    if (a.id == annotation.id) {
                      return a.copyWith(
                        content: content,
                        type: selectedType,
                        updatedAt: DateTime.now(),
                      );
                    }
                    return a;
                  }).toList();
                  final updatedNote = _note!.copyWith(
                    annotations: updatedAnnotations,
                    updatedAt: DateTime.now(),
                  );
                  appProvider.updateNote(updatedNote, updatedNote.content);
                  this.setState(() {
                    _note = updatedNote;
                  });
                  Navigator.pop(context);
                  SnackBarUtils.showSuccess(
                    context,
                    AppLocalizationsSimple.of(context)?.annotationUpdated ??
                        '批注已更新',
                  );
                }
              },
              child: Text(AppLocalizationsSimple.of(context)?.save ?? '保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAnnotation(String annotationId) {
    showDialog(
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
              final updatedAnnotations = _note!.annotations
                  .where((annotation) => annotation.id != annotationId)
                  .toList();
              final updatedNote = _note!.copyWith(
                annotations: updatedAnnotations,
                updatedAt: DateTime.now(),
              );

              appProvider.updateNote(updatedNote, updatedNote.content);
              setState(() {
                _note = updatedNote;
              });

              Navigator.pop(context);
              SnackBarUtils.showSuccess(
                context,
                AppLocalizationsSimple.of(context)?.annotationDeleted ??
                    '批注已删除',
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizationsSimple.of(context)?.delete ?? '删除'),
          ),
        ],
      ),
    );
  }

  // 📝 删除批注回调
  void _onDeleteAnnotation(String annotationId) {
    Navigator.pop(context); // 关闭侧边栏
    _deleteAnnotation(annotationId);
  }

  // 📝 标记批注为已解决
  void _onResolveAnnotation(Annotation annotation) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final updatedAnnotations = _note!.annotations.map((a) {
      if (a.id == annotation.id) {
        return a.copyWith(isResolved: true);
      }
      return a;
    }).toList();

    final updatedNote = _note!.copyWith(
      annotations: updatedAnnotations,
      updatedAt: DateTime.now(),
    );

    appProvider.updateNote(updatedNote, updatedNote.content);
    setState(() {
      _note = updatedNote;
    });

    SnackBarUtils.showSuccess(context, '已标记为已解决');
  }
}
