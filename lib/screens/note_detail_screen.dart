import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/widgets/annotations_sidebar.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/ai_enhanced_service.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/services/intelligent_related_notes_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart'; // 🔥 添加长期缓存
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/utils/todo_parser.dart';
import 'package:inkroot/widgets/intelligent_related_notes_sheet.dart';
import 'package:inkroot/widgets/ios_datetime_picker.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:inkroot/widgets/note_more_options_menu.dart';
import 'package:inkroot/widgets/permission_guide_dialog.dart';
import 'package:inkroot/widgets/share_image_preview_screen.dart';
import 'package:inkroot/widgets/simple_memo_content.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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
    final note = appProvider.getNoteById(widget.noteId);
    setState(() {
      _note = note;
    });
  }

  // 🔥 处理链接点击
  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) return;

    try {
      // 处理笔记内部引用 [[noteId]]
      if (href.startsWith('[[') && href.endsWith(']]')) {
        final noteId = href.substring(2, href.length - 2);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: noteId),
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
    } catch (e) {
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
    if (_note == null) return;

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
              if (mounted) {
                setState(() {
                  isLoading = false;
                  aiReview = review != null
                      ? _cleanMarkdownForReview(review)
                      : null; // 🔥 清理Markdown符号
                  errorMessage = error;
                });
                // 🔥 完成后显示提示
                if (review != null) {
                  SnackBarUtils.showSuccess(context, '✨ AI点评完成！');
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
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
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
                        .withOpacity(0.2),
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
                                .withOpacity(0.5),
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
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 20),
                                  Text(
                                    'AI正在阅读笔记...',
                                    style: TextStyle(
                                      color: (isDarkMode
                                              ? Colors.white
                                              : Colors.black)
                                          .withOpacity(0.6),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 60),
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
                                child:
                                    _buildReviewContent(aiReview!, isDarkMode),
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
                              if (mounted) {
                                SnackBarUtils.showSuccess(context, '✨ 点评已复制');
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('复制'),
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
    } catch (e) {
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
              if (mounted) {
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
            } catch (e) {
              if (mounted) {
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

  // 构建笔记内容（参考随机回顾样式）
  Widget _buildNoteContent(Note note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : const Color(0xFF333333);
    final secondaryTextColor =
        isDarkMode ? Colors.grey[400] : const Color(0xFF666666);
    final codeBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

    final content = note.content;

    // 🔥 从resourceList中提取图片
    final imagePaths = <String>[];
    for (final resource in note.resourceList) {
      final uid = resource['uid'] as String?;
      if (uid != null) {
        imagePaths.add('/o/r/$uid');
      }
    }

    // 从content中提取Markdown格式的图片
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final imageMatches = imageRegex.allMatches(content);
    for (final match in imageMatches) {
      final path = match.group(1) ?? '';
      if (path.isNotEmpty && !imagePaths.contains(path)) {
        imagePaths.add(path);
      }
    }

    // 将图片从内容中移除
    var contentWithoutImages = content;
    for (final match in imageMatches) {
      contentWithoutImages =
          contentWithoutImages.replaceAll(match.group(0) ?? '', '');
    }
    contentWithoutImages = contentWithoutImages.trim();

    // 🎯 优化正则表达式：支持更多字符，包括点号、书名号、数字、字母、中文等
    final tagRegex = RegExp(r'#([^\s\[\],，、;；:：！!？?\n]+)', unicode: true);
    final parts = contentWithoutImages.split(tagRegex);
    final matches = tagRegex.allMatches(contentWithoutImages);

    final contentWidgets = <Widget>[];
    var matchIndex = 0;

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        contentWidgets.add(
          MarkdownBody(
            data: parts[i],
            selectable: true,
            onTapLink: (text, href, title) => _handleLinkTap(href),
            imageBuilder: (uri, title, alt) {
              // 🔥 自定义图片构建器，使用90天缓存
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              final imagePath = uri.toString();

              if (imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://')) {
                return CachedNetworkImage(
                  imageUrl: imagePath,
                  cacheManager: ImageCacheManager.authImageCache, // 90天缓存
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const SizedBox(),
                  ),
                  errorWidget: (context, url, error) {
                    // 🔥 离线模式
                    return FutureBuilder<File?>(
                      future: ImageCacheManager.authImageCache
                          .getFileFromCache(url)
                          .then((info) => info?.file),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            snapshot.data!,
                            fit: BoxFit.contain,
                          );
                        }
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    );
                  },
                );
              } else if (imagePath.startsWith('/o/r/') ||
                  imagePath.startsWith('/file/') ||
                  imagePath.startsWith('/resource/')) {
                // 🔥 即使退出登录也能加载缓存
                String fullUrl;
                if (appProvider.resourceService != null) {
                  fullUrl =
                      appProvider.resourceService!.buildImageUrl(imagePath);
                } else {
                  final serverUrl = appProvider.appConfig.lastServerUrl ??
                      appProvider.appConfig.memosApiUrl ??
                      '';
                  fullUrl = serverUrl.isNotEmpty
                      ? '$serverUrl$imagePath'
                      : 'https://memos.didichou.site$imagePath';
                }
                final token = appProvider.user?.token;
                return CachedNetworkImage(
                  imageUrl: fullUrl,
                  cacheManager: ImageCacheManager.authImageCache, // 90天缓存
                  httpHeaders:
                      token != null ? {'Authorization': 'Bearer $token'} : {},
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const SizedBox(),
                  ),
                  errorWidget: (context, url, error) {
                    // 🔥 离线模式
                    return FutureBuilder<File?>(
                      future: ImageCacheManager.authImageCache
                          .getFileFromCache(fullUrl)
                          .then((info) => info?.file),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            snapshot.data!,
                            fit: BoxFit.contain,
                          );
                        }
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    );
                  },
                );
              } else if (imagePath.startsWith('file://')) {
                return Image.file(
                  File(imagePath.replaceFirst('file://', '')),
                  fit: BoxFit.contain,
                );
              }
              return const SizedBox();
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
              ),
              h1: TextStyle(
                fontSize: 20,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                fontSize: 18,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              code: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                backgroundColor: codeBgColor,
                fontFamily: 'monospace',
              ),
              blockquote: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2,
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }

      // 添加标签
      if (matchIndex < matches.length && i < parts.length - 1) {
        final tag = matches.elementAt(matchIndex).group(1)!;
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        matchIndex++;
      }
    }

    // 构建最终内容，包括文本和图片
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contentWidgets.isNotEmpty)
          Wrap(
            spacing: 2,
            runSpacing: 4,
            children: contentWidgets,
          ),
        // 🔥 显示图片网格
        if (imagePaths.isNotEmpty) ...[
          if (contentWidgets.isNotEmpty) const SizedBox(height: 12),
          _buildImageGrid(imagePaths),
        ],
      ],
    );
  }

  // 🔥 构建图片网格
  Widget _buildImageGrid(List<String> imagePaths) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 4.0;
          final imageWidth = (constraints.maxWidth - spacing * 2) / 3;
          final imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(imageCount, (index) {
              final imagePath = imagePaths[index];
              return _buildImageItem(imagePath, imageWidth);
            }),
          );
        },
      );

  // 🔥 构建单个图片项
  Widget _buildImageItem(String imagePath, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildImageWidget(imagePath),
        ),
      );

  // 🔥 构建图片组件
  Widget _buildImageWidget(String imagePath) {
    try {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          cacheManager: ImageCacheManager.authImageCache,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const SizedBox(),
          ),
          errorWidget: (context, url, error) => FutureBuilder<File?>(
            future: ImageCacheManager.authImageCache
                .getFileFromCache(url)
                .then((info) => info?.file),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.file(snapshot.data!, fit: BoxFit.cover);
              }
              return Center(
                child: Icon(Icons.broken_image, color: Colors.grey[600]),
              );
            },
          ),
        );
      } else if (imagePath.startsWith('/o/r/') ||
          imagePath.startsWith('/file/') ||
          imagePath.startsWith('/resource/')) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        String fullUrl;
        if (appProvider.resourceService != null) {
          fullUrl = appProvider.resourceService!.buildImageUrl(imagePath);
        } else {
          final serverUrl = appProvider.appConfig.lastServerUrl ??
              appProvider.appConfig.memosApiUrl ??
              '';
          fullUrl = serverUrl.isNotEmpty
              ? '$serverUrl$imagePath'
              : 'https://memos.didichou.site$imagePath';
        }
        final token = appProvider.user?.token;
        return CachedNetworkImage(
          imageUrl: fullUrl,
          cacheManager: ImageCacheManager.authImageCache,
          httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const SizedBox(),
          ),
          errorWidget: (context, url, error) => FutureBuilder<File?>(
            future: ImageCacheManager.authImageCache
                .getFileFromCache(fullUrl)
                .then((info) => info?.file),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.file(snapshot.data!, fit: BoxFit.cover);
              }
              return Center(
                child: Icon(Icons.broken_image, color: Colors.grey[600]),
              );
            },
          ),
        );
      } else if (imagePath.startsWith('file://')) {
        return Image.file(
          File(imagePath.replaceFirst('file://', '')),
          fit: BoxFit.cover,
        );
      }
      return const SizedBox();
    } catch (e) {
      debugPrint('Error in _buildImageWidget: $e');
      return Center(child: Icon(Icons.broken_image, color: Colors.grey[600]));
    }
  }

  // 删除笔记
  Future<void> _deleteNote(Note note) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 🚀 使用乐观删除（立即更新UI）
      await appProvider.deleteNote(note.id);

      if (mounted) {
        // 先返回主页
        Navigator.of(context).pop();

        // 显示带撤销按钮的美化提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.noteDeleted ?? '笔记已删除',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizationsSimple.of(context)?.undo ?? '撤销',
              textColor: Colors.white,
              backgroundColor: Colors.transparent,
              disabledTextColor: Colors.white70,
              onPressed: () async {
                // 撤销删除
                await appProvider.restoreNote();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.restore,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizationsSimple.of(context)
                                      ?.noteRestored ??
                                  '笔记已恢复',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blue.shade600,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '${AppLocalizationsSimple.of(context)?.deleteFailed ?? '删除失败'}: $e',
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 显示更多选项菜单（统一使用 NoteMoreOptionsMenu）
  void _showMoreOptions(BuildContext btnContext) {
    if (_note == null) return;
    
    NoteMoreOptionsMenu.show(
      context: btnContext,
      note: _note!,
      onNoteUpdated: () {
        _loadNote(); // 刷新笔记数据
      },
    );
  }

  // 🎯 切换笔记中指定索引的待办事项
  void _toggleTodoInNote(int todoIndex) {
    if (_note == null) return;
    
    final todos = TodoParser.parseTodos(_note!.content);
    if (todoIndex < 0 || todoIndex >= todos.length) {
      if (kDebugMode) {
        debugPrint('NoteDetailScreen: 待办事项索引越界 $todoIndex/${todos.length}');
      }
      return;
    }

    final todo = todos[todoIndex];
    final newContent = TodoParser.toggleTodoAtLine(_note!.content, todo.lineNumber);
    if (kDebugMode) {
      debugPrint('NoteDetailScreen: 切换待办事项 #$todoIndex 行${todo.lineNumber}: "${todo.text}"');
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
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

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
                color: _showSummary ? iconColor.withOpacity(0.1) : bgColor,
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
                      if (kDebugMode) debugPrint('🖱️ 双击检测到，打开编辑');
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
                                              .withOpacity(0.1),
                                          AppTheme.accentColor.withOpacity(0.1),
                                        ]
                                      : [
                                          AppTheme.primaryColor
                                              .withOpacity(0.05),
                                          AppTheme.accentColor
                                              .withOpacity(0.05),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: iconColor.withOpacity(0.3),
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
                                        icon: const Icon(Icons.close, size: 18),
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
                                                  AlwaysStoppedAnimation<Color>(
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

                              // 从resourceList提取图片并添加到content
                              var contentWithImages = _note!.content;

                              // 检查content是否已包含图片
                              final hasImagesInContent =
                                  RegExp(r'!\[.*?\]\((.*?)\)')
                                      .hasMatch(contentWithImages);

                              if (!hasImagesInContent &&
                                  _note!.resourceList.isNotEmpty) {
                                // content中没有图片，但resourceList有，则添加
                                final imagePaths = <String>[];
                                for (final resource in _note!.resourceList) {
                                  final uid = resource['uid'] as String?;
                                  if (uid != null) {
                                    imagePaths.add('/o/r/$uid');
                                  }
                                }

                                if (imagePaths.isNotEmpty) {
                                  // 在内容末尾添加图片
                                  contentWithImages += '\n\n';
                                  for (final path in imagePaths) {
                                    contentWithImages += '![]($path)\n';
                                  }
                                  if (kDebugMode) {
                                    debugPrint(
                                      '📄 NoteDetail: 添加了${imagePaths.length}张图片到content',
                                    );
                                  }
                                }
                              }

                              return SimpleMemoContent(
                                content: contentWithImages,
                                serverUrl: serverUrl,
                                note: _note, // 🎯 传入note对象
                                onCheckboxTap: _toggleTodoInNote, // 🎯 复选框点击回调（传递索引）
                                onTagTap: (tagName) {
                                  // 🎯 大厂导航模式：详情页点击标签 → 返回到标签列表页
                                  // 而不是推入新页面（避免：标签A详情 → 标签B列表 → 标签B详情 → ...）
                                  
                                  try {
                                    final currentRoute = GoRouterState.of(context).uri.toString();
                                    
                                    // 如果当前在标签筛选页进入的详情页
                                    if (currentRoute.contains('/tags/detail')) {
                                      // 策略1：直接返回到标签页（用户可以重新选择标签）
                                      if (mounted) {
                                        context.pop(); // 返回到上一页（标签列表）
                                      }
                                    } else {
                                      // 策略2：从其他入口（如主页）进入，可以跳转到标签页
                                      if (mounted) {
                                        // 使用 go 而不是 push，替换当前页面栈
                                        context.go('/tags/detail?tag=${Uri.encodeComponent(tagName)}');
                                      }
                                    }
                                  } catch (e) {
                                    print('❌ [详情页] 标签导航失败: $e');
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

  // 🚀 快速操作卡片
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

  // 📋 菜单选项
  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
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
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );

  // 📏 菜单分割线
  Widget _buildMenuDivider(bool isDarkMode) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              if (isDarkMode)
                Colors.white.withOpacity(0.1)
              else
                Colors.black.withOpacity(0.08),
              Colors.transparent,
            ],
          ),
        ),
      );

  // ⏰ 提醒菜单选项
  Widget _buildReminderMenuOption(
    BuildContext context, {
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    // 获取当前笔记的提醒时间
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final reminderTime = _note?.reminderTime;

    // 🔥 参考大厂应用：实时检查提醒是否已过期
    // 过期的提醒不显示图标，视为未设置
    final now = DateTime.now();
    final hasValidReminder = reminderTime != null && reminderTime.isAfter(now);

    return _buildMenuOption(
      context,
      icon: hasValidReminder ? Icons.alarm : Icons.alarm_add,
      title: hasValidReminder
          ? (AppLocalizationsSimple.of(context)?.reminderSet ?? '提醒已设置')
          : (AppLocalizationsSimple.of(context)?.setReminder ?? '设置提醒'),
      subtitle: hasValidReminder
          ? (AppLocalizationsSimple.of(context)?.clickToModifyOrCancel ??
              '点击修改或取消提醒')
          : (AppLocalizationsSimple.of(context)?.setNoteReminderTime ??
              '设置笔记提醒时间'),
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      primaryColor: hasValidReminder ? Colors.orange : primaryColor,
      onTap: () {
        Navigator.pop(context);
        _showReminderDialog(context);
      },
    );
  }

  // 🔍 可见性菜单选项
  Widget _buildVisibilityMenuOption(
    BuildContext context, {
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) =>
      _buildMenuOption(
        context,
        icon: Icons.visibility,
        title: AppLocalizationsSimple.of(context)?.shareSettings ?? '分享设置',
        subtitle: AppLocalizationsSimple.of(context)?.manageNoteVisibility ??
            '管理笔记可见性',
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryColor: primaryColor,
        onTap: () {
          Navigator.pop(context);
          _showShareOptions(context);
        },
      );

  // 📊 笔记详情弹窗
  void _showNoteDetails(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary =
        isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryColor = AppTheme.primaryColor;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizationsSimple.of(context)?.noteDetail ?? '笔记详情',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  AppLocalizationsSimple.of(context)?.creationTime ?? '创建时间',
                  DateFormat('yyyy-MM-dd HH:mm').format(_note!.createdAt),
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  AppLocalizationsSimple.of(context)?.lastEdited ?? '最后编辑',
                  DateFormat('yyyy-MM-dd HH:mm').format(_note!.updatedAt),
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  AppLocalizationsSimple.of(context)?.characterCountLabel ??
                      '字符数量',
                  '${_note!.content.length} ${AppLocalizationsSimple.of(context)?.charactersUnit ?? '字符'}',
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  AppLocalizationsSimple.of(context)?.tagsCountLabel ?? '标签数量',
                  '${_note!.tags.length} ${AppLocalizationsSimple.of(context)?.tagsUnit ?? '个标签'}',
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppLocalizationsSimple.of(context)?.close ?? '关闭',
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📋 详情行
  Widget _buildDetailRow(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  // 显示分享选项菜单
  void _showShareOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildIOSStyleShareOptions(context, isDarkMode),
    );
  }

  Widget _buildIOSStyleShareOptions(BuildContext context, bool isDarkMode) {
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? AppTheme.darkTextSecondaryColor : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // 🎯 点击空白区域关闭
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onTap: () {}, // 阻止内部点击冒泡
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部拖拽指示器
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 标题
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    AppLocalizationsSimple.of(context)?.shareNote ?? '分享笔记',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),

                // 分享方式选项 - 网格布局
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildShareOptionCard(
                          context,
                          icon: Icons.link_rounded,
                          title:
                              AppLocalizationsSimple.of(context)?.shareLink ??
                                  '分享链接',
                          subtitle: AppLocalizationsSimple.of(context)
                                  ?.generateShareLink ??
                              '生成分享链接',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            _showPublicPermissionDialog();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildShareOptionCard(
                          context,
                          icon: Icons.image_rounded,
                          title:
                              AppLocalizationsSimple.of(context)?.shareImage ??
                                  '分享图片',
                          subtitle: AppLocalizationsSimple.of(context)
                                  ?.generateImageShare ??
                              '生成图片分享',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _shareImage();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 底部安全区域
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ), // GestureDetector 结束 (内层)
      ), // GestureDetector 结束 (外层)
    );
  }

  Widget _buildShareOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  // 分享图片
  Future<void> _shareImage() async {
    // 显示图片分享模板选择界面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShareImagePreviewScreen(
          noteId: _note!.id,
          content: _note!.content,
          timestamp: _note!.updatedAt,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // 显示权限确认对话框
  void _showPublicPermissionDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 警告图标区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizationsSimple.of(context)
                              ?.sharePermissionConfirmation ??
                          '分享权限确认',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizationsSimple.of(context)
                              ?.sharePermissionMessage ??
                          '要分享此笔记，需要将其设置为公开状态。\n任何拥有链接的人都可以查看该笔记的内容。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: (isDarkMode
                                ? Colors.white
                                : AppTheme.textPrimaryColor)
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // 按钮区域
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppTheme.darkSurfaceColor
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () => Navigator.of(context).pop(),
                            child: Center(
                              child: Text(
                                AppLocalizationsSimple.of(context)?.cancel ??
                                    '取消',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              Navigator.of(context).pop();
                              _proceedWithSharing();
                            },
                            child: Center(
                              child: Text(
                                AppLocalizationsSimple.of(context)
                                        ?.confirmAndShare ??
                                    '确定并分享',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 执行分享操作
  Future<void> _proceedWithSharing() async {
    try {
      // 显示加载状态
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在生成分享链接...'),
            ],
          ),
        ),
      );

      // 获取分享链接
      final shareUrl = await _getShareUrl();

      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      if (shareUrl != null) {
        // 显示分享链接对话框
        _showShareLinkDialog(shareUrl);
      } else {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            AppLocalizationsSimple.of(context)?.generateShareLinkFailed ??
                '生成分享链接失败，请稍后再试',
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      if (kDebugMode) debugPrint('Error sharing link: $e');
      if (mounted) SnackBarUtils.showError(context, '分享失败: $e');
    }
  }

  // 获取分享URL
  Future<String?> _getShareUrl() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final baseUrl = appProvider.user?.serverUrl ??
          appProvider.appConfig.memosApiUrl ??
          '';
      final token = appProvider.user?.token;

      if (baseUrl.isEmpty) {
        throw Exception(
          AppLocalizationsSimple.of(context)?.serverUrlEmpty ?? '服务器地址为空',
        );
      }

      // 首先需要将笔记设置为公开，然后获取分享链接
      final uid = await _setMemoPublic();
      if (uid == null) {
        throw Exception(
          AppLocalizationsSimple.of(context)?.cannotMakeNotePublic ??
              '无法将笔记设置为公开',
        );
      }

      // 构建公开访问链接，使用返回的UID
      final cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/api/v\d+/?$'), '');
      final shareUrl = '$cleanBaseUrl/m/$uid';

      return shareUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting share URL: $e');
      return null;
    }
  }

  // 将笔记设置为公开，返回UID
  Future<String?> _setMemoPublic() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final baseUrl = appProvider.user?.serverUrl ??
          appProvider.appConfig.memosApiUrl ??
          '';
      final token = appProvider.user?.token;

      if (baseUrl.isEmpty || token == null) {
        return null;
      }

      final url = '$baseUrl/api/v1/memo/${_note!.id}';
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final body = {
        'visibility': 'PUBLIC', // v1 API使用字符串格式
      };

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // 解析v1 API响应，获取UID
        final responseData = jsonDecode(response.body);
        // v1 API响应格式可能不同，先尝试直接获取uid
        final uid = responseData['uid'] ??
            responseData['name']?.toString().replaceAll('memos/', '');
        if (kDebugMode) debugPrint('Extracted UID (v1): $uid');
        return uid;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error setting memo public: $e');
      return null;
    }
  }

  // 显示分享链接对话框
  void _showShareLinkDialog(String shareUrl) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 优雅的标题区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.link,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizationsSimple.of(context)?.shareLinkTitle ??
                          '分享链接',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizationsSimple.of(context)?.noteMadePublic ??
                          '您的笔记已设置为公开，任何人都可以通过链接访问',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDarkMode
                                ? Colors.white
                                : AppTheme.textPrimaryColor)
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // 链接展示区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.darkSurfaceColor
                        : AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: SelectableText(
                    shareUrl,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color:
                          isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),

              // 按钮区域
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: shareUrl),
                          );
                          if (context.mounted) {
                            SnackBarUtils.showSuccess(
                              context,
                              AppLocalizationsSimple.of(context)
                                      ?.linkCopiedToClipboard ??
                                  '链接已复制到剪贴板',
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(
                          AppLocalizationsSimple.of(context)?.copyLink ??
                              '复制链接',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Share.share(shareUrl, subject: '来自 InkRoot 的笔记分享');
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: Text(
                          AppLocalizationsSimple.of(context)?.shareAction ??
                              '分享',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 直接复制分享链接（用于已经是公开状态的笔记）
  Future<void> _copyShareLinkDirectly() async {
    try {
      final shareUrl = await _getShareUrl();
      if (shareUrl != null) {
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (context.mounted) {
          SnackBarUtils.showSuccess(
            context,
            AppLocalizationsSimple.of(context)?.linkCopied ?? '链接已复制',
          );
        }
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            AppLocalizationsSimple.of(context)?.generateShareLinkFailed ??
                '生成分享链接失败，请稍后再试',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error copying share link: $e');
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.copyLinkFailed ?? '复制链接失败，请稍后再试',
        );
      }
    }
  }

  // ⏰ 显示提醒设置对话框（iOS风格）
  Future<void> _showReminderDialog(BuildContext menuContext) async {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentReminderTime = _note?.reminderTime;

    // 如果已有提醒，先显示选项：修改或取消
    if (currentReminderTime != null) {
      if (!mounted) return;

      final action =
          await _showReminderOptionsSheet(context, currentReminderTime);

      if (!mounted) return;

      // 用户点击了关闭或返回
      if (action == null) return;

      // 用户选择取消提醒
      if (action == 'cancel') {
        try {
          await appProvider.cancelNoteReminder(_note!.id);
          await _loadNote(); // 重新加载笔记
          if (!mounted) return;
          if (context.mounted) {
            SnackBarUtils.showSuccess(
              context,
              AppLocalizationsSimple.of(context)?.reminderCancelled ?? '已取消提醒',
            );
          }
        } catch (e) {
          if (!mounted) return;
          if (context.mounted) {
            SnackBarUtils.showError(context, '取消失败: $e');
          }
        }
        return;
      }

      // 用户选择修改提醒时间，继续往下执行
    }

    // 🔥 先检查权限，没有权限先显示引导
    if (!mounted) return;

    // 检查通知权限
    final notificationService = appProvider.notificationService;
    var hasPermission = await notificationService.areNotificationsEnabled();

    if (!hasPermission) {
      if (!mounted) return;
      if (context.mounted) {
        // 显示权限引导弹窗
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PermissionGuideDialog(),
        );

        // 🔥 权限引导后重新检查权限
        if (!mounted) return;
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
          return;
        }
      } else {
        return;
      }
    }

    if (!mounted) return;

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

    final reminderDateTime = await IOSDateTimePicker.show(
      context: context,
      initialDateTime: initialTime,
      minimumDateTime: now,
      maximumDateTime: now.add(const Duration(days: 365)),
    );

    // 检查widget是否还存在
    if (!mounted) {
      return;
    }

    // 用户取消了时间选择
    if (reminderDateTime == null) {
      return;
    }

    // 检查时间是否在未来
    if (reminderDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      if (context.mounted) {
        SnackBarUtils.showWarning(
          context,
          AppLocalizationsSimple.of(context)?.reminderTimeMustBeFuture ??
              '提醒时间必须在未来',
        );
      }
      return;
    }

    // 设置提醒
    try {
      final success =
          await appProvider.setNoteReminder(_note!.id, reminderDateTime);

      if (!mounted) return;

      if (!success) {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            AppLocalizationsSimple.of(context)?.setReminderFailedRetry ??
                '设置提醒失败，请稍后重试',
          );
        }
        return;
      }

      // 重新加载笔记
      await _loadNote();

      if (context.mounted) {
        // 🎯 简洁的成功提示（参考大厂风格）
        final timeStr = DateFormat('MM-dd HH:mm').format(reminderDateTime);
        SnackBarUtils.showSuccess(context, '提醒已设置 $timeStr');
      }
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        // 🎯 简洁的错误提示（不显示技术细节）
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.setReminderFailed ?? '设置提醒失败',
        );
      }
    }
  }

  // 显示提醒选项（修改或取消）
  Future<String?> _showReminderOptionsSheet(
    BuildContext context,
    DateTime currentTime,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(), // 🎯 点击空白区域关闭
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {}, // 阻止内部点击冒泡
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖拽指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 当前提醒时间
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.alarm, color: Colors.orange, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizationsSimple.of(context)
                                  ?.currentReminderTime ??
                              '当前提醒时间',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(currentTime),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 选项按钮
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF007AFF)),
                    title: Text(
                      AppLocalizationsSimple.of(context)?.modifyReminderTime ??
                          '修改提醒时间',
                    ),
                    onTap: () => Navigator.pop(context, 'edit'),
                  ),

                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(
                      AppLocalizationsSimple.of(context)?.cancelReminder ??
                          '取消提醒',
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () => Navigator.pop(context, 'cancel'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ), // GestureDetector 结束
      ), // GestureDetector 结束
    );
  }

  // 显示查看引用对话框
  void _showViewReferencesDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notes = appProvider.notes;

    // 过滤出所有引用类型的关系，包括正向和反向
    final allReferences = _note!.relations.where((relation) {
      final type = relation['type'];
      return type == 1 ||
          type == 'REFERENCE' ||
          type == 'REFERENCED_BY'; // 包含所有引用类型
    }).toList();

    // 分类引用关系
    final outgoingRefs = <Map<String, dynamic>>[];
    final incomingRefs = <Map<String, dynamic>>[];

    for (final relation in allReferences) {
      final type = relation['type'];
      final memoId = relation['memoId']?.toString() ?? '';
      final relatedMemoId = relation['relatedMemoId']?.toString() ?? '';
      final currentId = _note!.id;

      if (type == 'REFERENCED_BY') {
        // 这是一个被引用关系，其他笔记引用了当前笔记
        // REFERENCED_BY: memoId是引用者，relatedMemoId是被引用者（当前笔记）
        if (relatedMemoId == currentId) {
          incomingRefs.add(relation);
        }
      } else if (type == 'REFERENCE' || type == 1) {
        // 这是一个引用关系，当前笔记引用了其他笔记
        // REFERENCE: memoId是引用者（当前笔记），relatedMemoId是被引用者
        if (memoId == currentId || memoId.isEmpty) {
          outgoingRefs.add(relation);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppTheme.primaryColor.withOpacity(0.08)
                      : AppTheme.primaryColor.withOpacity(0.04),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.account_tree_outlined,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizationsSimple.of(context)?.referenceRelations ??
                          '引用关系',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizationsSimple.of(context)?.viewAllReferences ??
                          '查看此笔记的所有引用关系',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDarkMode
                                ? Colors.white
                                : AppTheme.textPrimaryColor)
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // 引用列表
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(16),
                child: allReferences.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.link_off,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizationsSimple.of(context)
                                      ?.noReferences ??
                                  '暂无引用关系',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizationsSimple.of(context)
                                      ?.canAddReferencesWhenEditing ??
                                  '在编辑笔记时可以添加引用关系',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 引用的笔记部分
                            if (outgoingRefs.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.north_east,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '引用的笔记 (${outgoingRefs.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...outgoingRefs.map(
                                (relation) => _buildReferenceItem(
                                  relation,
                                  notes,
                                  isDarkMode,
                                  true,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 被引用部分
                            if (incomingRefs.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.north_west,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '被引用 (${incomingRefs.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...incomingRefs.map(
                                (relation) => _buildReferenceItem(
                                  relation,
                                  notes,
                                  isDarkMode,
                                  false,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),

              // 底部按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isDarkMode
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '关闭',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建单个引用项目
  Widget _buildReferenceItem(
    Map<String, dynamic> relation,
    List<Note> notes,
    bool isDarkMode,
    bool isOutgoing,
  ) {
    final relatedMemoId = relation['relatedMemoId']?.toString() ?? '';
    final memoId = relation['memoId']?.toString() ?? '';
    final currentId = _note!.id;

    // 根据引用方向确定要显示的笔记ID
    String targetNoteId;
    if (isOutgoing) {
      // 显示被引用的笔记
      targetNoteId = relatedMemoId;
    } else {
      // 显示引用该笔记的笔记
      targetNoteId = memoId;
    }

    // 查找关联的笔记
    final relatedNote = notes.firstWhere(
      (note) => note.id == targetNoteId,
      orElse: () => Note(
        id: targetNoteId,
        content: '笔记不存在 (ID: $targetNoteId)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final preview = relatedNote.content.length > 40
        ? '${relatedNote.content.substring(0, 40)}...'
        : relatedNote.content;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // 跳转到引用的笔记
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: targetNoteId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isOutgoing ? Colors.blue : Colors.orange).withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (isOutgoing ? Colors.blue : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.note_outlined,
                  color: isOutgoing ? Colors.blue : Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm')
                          .format(relatedNote.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: (isDarkMode
                                ? AppTheme.darkTextSecondaryColor
                                : AppTheme.textSecondaryColor)
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isOutgoing ? Icons.north_east : Icons.north_west,
                size: 16,
                color: isOutgoing ? Colors.blue : Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧠 查找并显示智能相关笔记（使用最新的智能推荐系统）
  Future<void> _findRelatedNotes() async {
    if (_note == null) return;

    setState(() {
      _isLoadingRelatedNotes = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 🧠 使用智能相关笔记服务进行分析
      final result = await _intelligentRelatedNotesService.findIntelligentRelatedNotes(
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
      if (!mounted) return;
      
      if (result.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          AppLocalizationsSimple.of(context)?.aiRelatedNotesEmpty ??
              '未找到相关笔记',
        );
      } else {
        // 🎨 显示现代化的智能相关笔记抽屉
        await IntelligentRelatedNotesSheet.show(context, result);
      }
    } catch (e) {
      debugPrint('❌ 查找相关笔记失败: $e');
      setState(() {
        _isLoadingRelatedNotes = false;
      });
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '查找相关笔记失败：${e.toString()}',
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
                      .withOpacity(0.3),
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
    if (_note == null || _isGeneratingSummary) return;

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
    } catch (e) {
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
            width: 1,
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

  // 📝 构建批注区域
  Widget _buildAnnotationsSection(bool isDarkMode, Color textColor, Color secondaryTextColor) {
    final localizations = AppLocalizationsSimple.of(context);
    final annotations = _note!.annotations;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 批注标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 18,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations?.annotations ?? '批注'} (${annotations.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddAnnotationDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(localizations?.addAnnotation ?? '添加批注'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

          // 批注列表
          if (annotations.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_bank_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations?.noAnnotations ?? '还没有批注',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations?.noAnnotationsHint ?? '点击上方按钮添加批注，记录你的思考',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: annotations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final annotation = annotations[index];
                return _buildAnnotationItem(
                  annotation,
                  isDarkMode,
                  textColor,
                  secondaryTextColor,
                );
              },
            ),
        ],
      ),
    );
  }

  // 📝 构建单个批注项
  Widget _buildAnnotationItem(
    Annotation annotation,
    bool isDarkMode,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey.shade900.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 批注内容
          Text(
            annotation.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          // 底部信息栏
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(annotation.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
              const Spacer(),
              // 编辑按钮
              InkWell(
                onTap: () => _showEditAnnotationDialog(annotation),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 删除按钮
              InkWell(
                onTap: () => _deleteAnnotation(annotation.id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📝 显示添加批注对话框
  void _showAddAnnotationDialog() {
    final textController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.comment_outlined, size: 20),
            SizedBox(width: 8),
            Text('添加批注'),
          ],
        ),
        content: TextField(
          controller: textController,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '在这里写下你的思考、补充或评论...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final content = textController.text.trim();
              if (content.isNotEmpty) {
                _addAnnotation(content);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // 📝 显示编辑批注对话框
  void _showEditAnnotationDialog(Annotation annotation) {
    final textController = TextEditingController(text: annotation.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, size: 20),
            SizedBox(width: 8),
            Text('编辑批注'),
          ],
        ),
        content: TextField(
          controller: textController,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '修改批注内容...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final content = textController.text.trim();
              if (content.isNotEmpty) {
                _updateAnnotation(annotation.id, content);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 📝 添加批注
  void _addAnnotation(String content) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    final newAnnotation = Annotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
    );

    final updatedAnnotations = [..._note!.annotations, newAnnotation];
    final updatedNote = _note!.copyWith(
      annotations: updatedAnnotations,
      updatedAt: DateTime.now(),
    );

    appProvider.updateNote(updatedNote, updatedNote.content);
    setState(() {
      _note = updatedNote;
    });

    SnackBarUtils.showSuccess(context, '批注已添加');
  }

  // 📝 更新批注
  void _updateAnnotation(String annotationId, String newContent) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    final updatedAnnotations = _note!.annotations.map((annotation) {
      if (annotation.id == annotationId) {
        return annotation.copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        );
      }
      return annotation;
    }).toList();

    final updatedNote = _note!.copyWith(
      annotations: updatedAnnotations,
      updatedAt: DateTime.now(),
    );

    appProvider.updateNote(updatedNote, updatedNote.content);
    setState(() {
      _note = updatedNote;
    });

    SnackBarUtils.showSuccess(context, '批注已更新');
  }

  // 📝 删除批注
  void _deleteAnnotation(String annotationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除批注'),
        content: const Text('确定要删除这条批注吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              
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
              SnackBarUtils.showSuccess(context, '批注已删除');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 📝 显示批注侧边栏
  void _showAnnotationsSidebar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,  // ✅ 允许点击空白区域关闭
      enableDrag: true,      // ✅ 允许下拉关闭
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
    AnnotationType selectedType = AnnotationType.comment;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_comment, size: 20),
              SizedBox(width: 8),
              Text('添加批注'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('批注类型', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      selectedColor: annotation.typeColor.withOpacity(0.2),
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
                    hintText: '在这里写下你的批注...',
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
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final content = textController.text.trim();
                if (content.isNotEmpty) {
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  final newAnnotation = Annotation(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    content: content,
                    createdAt: DateTime.now(),
                    type: selectedType,
                  );
                  final updatedAnnotations = [..._note!.annotations, newAnnotation];
                  final updatedNote = _note!.copyWith(
                    annotations: updatedAnnotations,
                    updatedAt: DateTime.now(),
                  );
                  appProvider.updateNote(updatedNote, updatedNote.content);
                  this.setState(() {
                    _note = updatedNote;
                  });
                  Navigator.pop(context);
                  SnackBarUtils.showSuccess(context, '批注已添加');
                }
              },
              child: const Text('添加'),
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
    AnnotationType selectedType = annotation.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 8),
              Text('编辑批注'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('批注类型', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      selectedColor: tempAnnotation.typeColor.withOpacity(0.2),
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
                    hintText: '修改批注内容...',
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
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final content = textController.text.trim();
                if (content.isNotEmpty) {
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
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
                  SnackBarUtils.showSuccess(context, '批注已更新');
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
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
