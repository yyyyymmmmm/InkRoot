import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:go_router/go_router.dart';
import 'package:inkroot/utils/todo_parser.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/widgets/annotations_sidebar.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/services/local_reference_service.dart';
import 'package:inkroot/services/note_actions_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart'; // 🔥 添加长期缓存管理器
import 'package:inkroot/utils/image_utils.dart';
import 'package:inkroot/utils/share_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:inkroot/widgets/animated_checkbox.dart';
import 'package:inkroot/widgets/ios_datetime_picker.dart';
import 'package:inkroot/widgets/note_more_options_menu.dart';
import 'package:inkroot/widgets/permission_guide_dialog.dart';
import 'package:inkroot/services/note_actions_service.dart';
import 'package:inkroot/widgets/saveable_image.dart';
import 'package:inkroot/widgets/share_image_preview_screen.dart';
import 'package:inkroot/widgets/simple_memo_content.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

// 辅助类用于解析内容中的标签和引用
class _ParseMatch {
  _ParseMatch(this.start, this.end, this.type, this.content);
  final int start;
  final int end;
  final String type; // 'tag' or 'reference'
  final String content;
}

class NoteCard extends StatefulWidget {
  const NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    this.onNoteUpdated, // 新增：笔记更新回调（用于统一组件）
    this.disableTagNavigation = false, // 🎯 是否禁用标签点击跳转（避免无限嵌套）
    super.key,
  });
  final Note note; // 🚀 直接传递完整Note对象，避免查找
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback? onNoteUpdated; // 可选的笔记更新回调
  final bool disableTagNavigation; // 是否禁用标签跳转

  // 🚀 便捷访问属性
  String get content => note.content;
  DateTime get timestamp => note.updatedAt;
  List<String> get tags => note.tags;
  bool get isPinned => note.isPinned;
  String get id => note.id;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  // 🎯 大厂标准：6行阈值（微信朋友圈、微博、小红书都是6行）
  static const int _maxLines = 6;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ValueNotifier<bool> _expandedNotifier = ValueNotifier<bool>(false);

  // 🚀 精确测量文本行数的缓存
  bool? _needsExpansionCache;
  String? _lastMeasuredContent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _expandedNotifier.dispose();
    super.dispose();
  }

  // 🎯 基础内容样式（用于TextPainter测量）
  // 注意：这里用于测量判断，实际渲染使用 SimpleMemoContent 的样式
  static const TextStyle _contentStyle = TextStyle(
    fontSize: 15, // 与 SimpleMemoContent 的 bodyLarge 保持一致
    height: 1.6, // 与 SimpleMemoContent 的 p 标签保持一致
    letterSpacing: 0.15,
  );

  // 🚀 计算单行高度（用于精确测量）
  static const double _lineHeight = 15.0 * 1.6; // fontSize * height = 24.0

  // 处理标签和Markdown内容
  Widget _buildContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    // 🚀 从resourceList和content中提取图片链接（优化：直接使用传入的Note对象）
    final imagePaths = <String>[];

    // 从resourceList中获取图片资源（无需查找，直接使用）
    for (final resource in widget.note.resourceList) {
      final uid = resource['uid'] as String?;
      final type = resource['type'] as String?;
      final filename = resource['filename'] as String?;

      // 🛡️ 过滤掉视频文件，只保留图片
      if (uid != null) {
        var isVideo = false;
        if (type != null && type.toLowerCase().startsWith('video')) {
          isVideo = true;
        } else if (filename != null) {
          final ext = filename.toLowerCase();
          if (ext.endsWith('.mov') ||
              ext.endsWith('.mp4') ||
              ext.endsWith('.avi') ||
              ext.endsWith('.mkv') ||
              ext.endsWith('.webm') ||
              ext.endsWith('.flv')) {
            isVideo = true;
          }
        }

        if (!isVideo) {
          imagePaths.add('/o/r/$uid');
        }
      }
    }

    // 然后从content中提取Markdown格式的图片（兼容性处理）
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final imageMatches = imageRegex.allMatches(widget.content);

    for (final match in imageMatches) {
      final path = match.group(1) ?? '';
      if (path.isNotEmpty && !imagePaths.contains(path)) {
        imagePaths.add(path);
        // if (kDebugMode) debugPrint('NoteCard: 从content添加图片: $path');
      }
    }

    // if (kDebugMode) debugPrint('NoteCard: 最终图片路径列表: $imagePaths');

    // 将图片Markdown代码从内容中移除
    var contentWithoutImages = widget.content;
    for (final match in imageMatches) {
      contentWithoutImages =
          contentWithoutImages.replaceAll(match.group(0) ?? '', '');
    }
    contentWithoutImages = contentWithoutImages.trim();

    // 检查是否有文本内容
    final hasTextContent = contentWithoutImages.isNotEmpty;

    // 检查文本是否需要展开按钮
    final needsExpansion = _contentMightOverflow(contentWithoutImages);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // 计算图片网格尺寸
        const spacing = 4.0;
        final imageWidth = (availableWidth - spacing * 2) / 3;
        final imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;
        final rowsNeeded = ((imageCount - 1) ~/ 3 + 1).clamp(0, 3);
        final gridHeight = rowsNeeded * imageWidth + (rowsNeeded - 1) * spacing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTextContent)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎯 大厂标准：直接用maxLines限制行数（微信朋友圈/微博方案）
                  ValueListenableBuilder<bool>(
                    valueListenable: _expandedNotifier,
                    builder: (context, isExpanded, child) => SimpleMemoContent(
                      content: contentWithoutImages,
                      serverUrl:
                          Provider.of<AppProvider>(context, listen: false)
                              .appConfig
                              .memosApiUrl,
                      selectable: false,
                      note: widget.note, // 🎯 传入note对象
                      onCheckboxTap: _toggleTodoItem, // 🎯 复选框点击回调（传递索引）
                      // 🎯 标签点击 - 根据配置决定是否跳转
                      onTagTap: widget.disableTagNavigation
                          ? null // 禁用标签跳转（避免在标签详情页中无限嵌套）
                          : (tagName) {
                              context.pushNamed(
                                'tag-notes',
                                queryParameters: {'tag': tagName},
                              );
                            },
                      // 🎯 链接点击 - 打开浏览器
                      onLinkTap: (url) async {
                        final uri = Uri.tryParse(url);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      // 🎯 大厂标准：收起时限制6行，展开时不限制
                      maxLines:
                          (!isExpanded && needsExpansion) ? _maxLines : null,
                    ),
                  ),

                  // 🎯 展开/收起按钮（微信朋友圈风格）
                  if (needsExpansion)
                    ValueListenableBuilder<bool>(
                      valueListenable: _expandedNotifier,
                      builder: (context, isExpanded, _) => GestureDetector(
                        onTap: () {
                          // 🎯 切换展开/收起状态
                          _expandedNotifier.value = !_expandedNotifier.value;
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded
                                    ? (AppLocalizationsSimple.of(context)
                                            ?.collapse ??
                                        '收起')
                                    : (AppLocalizationsSimple.of(context)
                                            ?.fullText ??
                                        '全文'), // 🎯 微信用"全文"而不是"展开"
                                style: AppTextStyles.bodyMedium(
                                  context,
                                  color: isDarkMode
                                      ? AppTheme.primaryLightColor
                                      : AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                                color: isDarkMode
                                    ? AppTheme.primaryLightColor
                                    : AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            if (imagePaths.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: hasTextContent ? 8.0 : 0),
                child: SizedBox(
                  width: availableWidth,
                  height: gridHeight,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    cacheExtent: 500, // 🚀 预加载缓存（抖音方案）
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: imageCount,
                    itemBuilder: (context, index) {
                      if (index == 8 && imagePaths.length > 9) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildUniformImageItem(imagePaths[index]),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showAllImages(imagePaths),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+${imagePaths.length - 8}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return _buildUniformImageItem(imagePaths[index]);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 🎯 大厂标准：使用TextPainter精确测量文本行数（微信朋友圈做法）
  //
  // 为什么要精确测量？
  // 1. 估算不准确：不同字体、字号、设备宽度都会影响实际行数
  // 2. 用户体验差：文本明明只有5行却显示"展开"，或8行却不显示
  // 3. 大厂都这么做：微信、微博、小红书都用TextPainter精确测量
  //
  // TextPainter工作原理：
  // 1. 模拟实际渲染过程，计算文本布局
  // 2. 考虑字体、字号、行高、设备宽度等所有因素
  // 3. 返回精确的行数，100%准确
  bool _contentMightOverflow(String content) {
    // 🚀 缓存优化：避免重复测量相同内容
    if (_lastMeasuredContent == content && _needsExpansionCache != null) {
      return _needsExpansionCache!;
    }

    try {
      // 获取屏幕宽度和内边距
      final screenWidth = MediaQuery.of(context).size.width;
      // 卡片内边距：16(屏幕边距) + 16(卡片padding) = 32 * 2 = 64
      final maxWidth = screenWidth - 64;

      // 获取主题样式
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDarkMode
          ? AppTheme.darkTextPrimaryColor
          : AppTheme.textPrimaryColor;

      // 🎨 创建TextPainter（模拟实际渲染）
      final textPainter = TextPainter(
        text: TextSpan(
          text: content,
          style: _contentStyle.copyWith(color: textColor),
        ),
        textDirection: ui.TextDirection.ltr,
        // 🔥 关键修复：设置文本对齐方式，匹配 Markdown 渲染
        textAlign: TextAlign.start,
        // 🔥 关键修复：考虑长单词（长URL）的换行
        maxLines: 999, // 先设置一个很大的值
      );

      // 📐 布局文本（让TextPainter计算实际需要多少行）
      textPainter.layout(maxWidth: maxWidth);

      // 🎯 精确判断：计算实际行数
      final lines = textPainter.computeLineMetrics();
      final actualLines = lines.length;
      
      // 🐛 特殊处理：如果内容很短但行数很多，可能是长URL导致的
      // 长URL会被强制换行，但实际显示可能很紧凑
      if (content.length < 300 && actualLines > 10) {
        // 检查是否包含长URL
        final hasLongUrl = content.contains(RegExp(r'https?://[^\s]{50,}'));
        if (hasLongUrl) {
          // 长URL的情况，使用更保守的判断
          final manualLineBreaks = '\n'.allMatches(content).length + 1;
          return manualLineBreaks > _maxLines;
        }
      }

      // 缓存结果
      _lastMeasuredContent = content;
      _needsExpansionCache = actualLines > _maxLines;

      return _needsExpansionCache!;
    } catch (e) {
      // 出错时回退到简单判断
      debugPrint('⚠️ TextPainter测量失败，回退到简单判断：$e');
      return content.length > 200 ||
          '\n'.allMatches(content).length >= _maxLines;
    }
  }

  // 构建富文本内容
  Widget _buildRichContent(String content) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? (Colors.grey[400] ?? Colors.grey)
        : const Color(0xFF666666);
    final codeBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

    // 解析内容，包括标签和引用
    final contentWidgets = _parseContentWithTagsAndReferences(
      content,
      textColor,
      secondaryTextColor,
      codeBgColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: contentWidgets,
          ),
        ),
      ),
    );
  }

  // 解析内容，同时处理标签和引用
  List<Widget> _parseContentWithTagsAndReferences(
    String content,
    Color textColor,
    Color secondaryTextColor,
    Color codeBgColor,
  ) {
    final widgets = <Widget>[];

    // 定义正则表达式
    // 🎯 改进的标签识别规则（参考Obsidian/Notion/Logseq，排除URL中的#）
    final tagRegex = tag_utils.getTagRegex();
    // 引用正则：匹配所有的 [[内容]]
    final referenceRegex = RegExp(r'\[\[([^\]]+)\]\]');

    // 分段处理内容
    var lastIndex = 0;
    final allMatches = <_ParseMatch>[];

    // 收集所有匹配
    for (final match in tagRegex.allMatches(content)) {
      allMatches
          .add(_ParseMatch(match.start, match.end, 'tag', match.group(1)!));
    }
    for (final match in referenceRegex.allMatches(content)) {
      allMatches.add(
        _ParseMatch(match.start, match.end, 'reference', match.group(1)!),
      );
    }

    // 按位置排序
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    for (final match in allMatches) {
      // 添加匹配前的普通文本
      if (match.start > lastIndex) {
        final plainText = content.substring(lastIndex, match.start);
        if (plainText.isNotEmpty) {
          widgets.add(
            _buildMarkdownText(
              plainText,
              textColor,
              secondaryTextColor,
              codeBgColor,
            ),
          );
        }
      }

      // 添加特殊格式的组件
      if (match.type == 'tag') {
        widgets.add(_buildTagWidget(match.content));
      } else if (match.type == 'reference') {
        widgets.add(_buildReferenceWidget(match.content));
      }

      lastIndex = match.end;
    }

    // 添加剩余的普通文本
    if (lastIndex < content.length) {
      final plainText = content.substring(lastIndex);
      if (plainText.isNotEmpty) {
        widgets.add(
          _buildMarkdownText(
            plainText,
            textColor,
            secondaryTextColor,
            codeBgColor,
          ),
        );
      }
    }

    return widgets;
  }

  // 构建标签组件
  Widget _buildTagWidget(String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  // 构建引用组件（Memos 标准：蓝色下划线链接）
  Widget _buildReferenceWidget(String referenceStr) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDarkMode ? Colors.blue[400]! : Colors.blue[600]!;

    // 🎯 解析引用格式：支持 [[id]] 或 [[memos/id]] 或 [[id?text=xxx]]
    final parsed = _parseReference(referenceStr);
    final noteId = parsed['id']!;
    final customText = parsed['text'];

    // 根据ID查找笔记并提取显示文本
    final displayText = customText ?? _getDisplayTextFromNoteId(noteId);

    return GestureDetector(
      onTap: () => _onReferenceTap(noteId),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              displayText,
              style: TextStyle(
                color: linkColor,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_forward_ios,
            size: 10,
            color: linkColor,
          ),
        ],
      ),
    );
  }

  // 🎯 解析引用格式（支持 Memos 标准）
  Map<String, String?> _parseReference(String referenceStr) {
    // 支持格式：
    // 1. [[id]]
    // 2. [[memos/id]]
    // 3. [[id?text=xxx]]
    // 4. [[memos/id?text=xxx]]

    var cleanRef = referenceStr.trim();
    String? customText;

    // 提取 ?text= 参数
    if (cleanRef.contains('?text=')) {
      final parts = cleanRef.split('?text=');
      cleanRef = parts[0];
      customText = parts.length > 1 ? Uri.decodeComponent(parts[1]) : null;
    }

    // 移除 memos/ 前缀（如果有）
    if (cleanRef.startsWith('memos/')) {
      cleanRef = cleanRef.substring(6);
    }

    return {'id': cleanRef, 'text': customText};
  }

  // 🎯 根据笔记ID提取显示文本（标题或第一行）
  String _getDisplayTextFromNoteId(String noteId) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 查找笔记
    final note = appProvider.notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => Note(
        id: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (note.id.isEmpty) {
      // 未找到笔记，显示友好提示
      return '(已删除的笔记)';
    }

    // 提取显示文本
    return _extractDisplayText(note.content);
  }

  // 提取显示文本（Memos 标准：前12字符，清理 Markdown 格式）
  String _extractDisplayText(String content) {
    if (content.isEmpty) return '(空笔记)';

    // 🎯 清理 Markdown 格式标记
    var cleaned = content.trim();
    // 移除 Markdown 标记：** _ ` # [ ] ( ) ~
    cleaned = cleaned.replaceAll(RegExp(r'[*_`#\[\]\(\)~]'), '');
    // 移除多余的空格
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Memos 标准：显示前12个字符
    if (cleaned.length > 12) {
      return '${cleaned.substring(0, 12)}...';
    }
    return cleaned.isNotEmpty ? cleaned : '(空笔记)';
  }

  // 处理引用点击（直接使用ID跳转）
  Future<void> _onReferenceTap(String noteId) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 🔍 调试：打印所有笔记ID和查找的ID
    debugPrint('🔍 查找笔记ID: $noteId');
    debugPrint('📋 现有笔记数量: ${appProvider.notes.length}');
    if (appProvider.notes.length < 10) {
      debugPrint('📋 所有笔记ID: ${appProvider.notes.map((n) => n.id).join(", ")}');
    } else {
      debugPrint(
        '📋 前10个笔记ID: ${appProvider.notes.take(10).map((n) => n.id).join(", ")}',
      );
    }

    // 验证笔记是否存在
    final noteExists = appProvider.notes.any((note) => note.id == noteId);
    debugPrint('✅ 笔记存在: $noteExists');

    if (!noteExists) {
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)
                ?.referencedNoteNotFound
                .replaceAll('{id}', noteId) ??
            '引用的笔记不存在或已被删除 (ID: $noteId)',
      );
      return;
    }

    // 直接用ID跳转到笔记详情
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(noteId: noteId),
      ),
    );
  }

  // 构建普通Markdown文本
  Widget _buildMarkdownText(
    String text,
    Color textColor,
    Color secondaryTextColor,
    Color codeBgColor,
  ) =>
      MarkdownBody(
        data: text,
        extensionSet: md.ExtensionSet.gitHubFlavored, // 🎯 启用GitHub风格Markdown（支持待办事项）
        checkboxBuilder: (value) {
          // 🎯 优雅的动画复选框（参考 Things 3 / Todoist）
          return GestureDetector(
            onTap: () {
              // 🎯 直接在这里处理点击
              if (kDebugMode) {
                debugPrint('NoteCard: 复选框被点击');
              }
              _handleCheckboxTap(text, value ?? false);
            },
            behavior: HitTestBehavior.opaque, // 拦截事件不让外层GestureDetector收到
            child: AnimatedCheckbox(
              value: value ?? false,
              onChanged: null, // 交互由外层 GestureDetector 处理
              size: 18,
              borderRadius: 5,
            ),
          );
        },
        styleSheet: MarkdownStyleSheet(
          p: _contentStyle.copyWith(color: textColor),
          h1: _contentStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          h2: _contentStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          h3: _contentStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          code: _contentStyle.copyWith(
            backgroundColor: codeBgColor,
            color: textColor,
            fontFamily: 'monospace',
          ),
          blockquote: _contentStyle.copyWith(
            color: secondaryTextColor,
            fontStyle: FontStyle.italic,
          ),
          // 🎯 已完成任务的文字样式（删除线 + 灰色）
          del: _contentStyle.copyWith(
            color: secondaryTextColor.withOpacity(0.6),
            decoration: TextDecoration.lineThrough,
            decorationColor: secondaryTextColor,
            decorationThickness: 2.0,
          ),
        ),
        softLineBreak: true,
      );

  // 构建统一大小的图片网格
  Widget _buildUniformImageGrid(List<String> imagePaths) {
    final imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final gridWidth = screenWidth * 0.7;

    return SizedBox(
      width: gridWidth,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: imageCount,
        itemBuilder: (context, index) {
          if (index == 8 && imagePaths.length > 9) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildUniformImageItem(imagePaths[index]),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAllImages(imagePaths),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+${imagePaths.length - 8}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _buildUniformImageItem(imagePaths[index]);
        },
      ),
    );
  }

  // 构建统一大小的单个图片项
  Widget _buildUniformImageItem(String imagePath) {
    try {
      return GestureDetector(
        onTap: () => _showFullscreenImage(imagePath),
        child: Container(
          width: double.infinity,
          height: 120, // 添加明确的高度
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildImageWidget(imagePath, context),
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error building image item: $e for path $imagePath');
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600])),
      );
    }
  }

  // 显示所有图片
  void _showAllImages(List<String> imagePaths) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _AllImagesScreen(imagePaths: imagePaths),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error showing all images: $e');
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.cannotDisplayImage ?? '无法显示图片',
      );
    }
  }

  // 显示全屏图片
  void _showFullscreenImage(String imagePath) {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _ImageViewerScreen(imagePath: imagePath),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error showing fullscreen image: $e');
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.cannotDisplayImage ?? '无法显示图片',
      );
    }
  }

  // 🎯 切换指定索引的待办事项
  void _toggleTodoItem(int todoIndex) {
    final todos = TodoParser.parseTodos(widget.note.content);
    if (todoIndex < 0 || todoIndex >= todos.length) {
      if (kDebugMode) {
        debugPrint('NoteCard: 待办事项索引越界 $todoIndex/${todos.length}');
      }
      return;
    }

    // 切换待办事项的状态
    final todo = todos[todoIndex];
    final newContent = TodoParser.toggleTodoAtLine(widget.note.content, todo.lineNumber);
    
    if (kDebugMode) {
      debugPrint('NoteCard: 切换待办事项 #$todoIndex 行${todo.lineNumber}: "${todo.text}"');
    }

    // 更新笔记
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateNote(widget.note, newContent).then((_) {
      if (kDebugMode) {
        debugPrint('NoteCard: 待办事项状态已更新');
      }
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('NoteCard: 更新待办事项失败: $error');
      }
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.updateFailed ?? '更新失败',
      );
    });
  }

  // 🎯 处理复选框点击（切换待办事项状态）
  void _handleCheckboxTap(String text, bool currentValue) {
    if (kDebugMode) {
      debugPrint('NoteCard: 复选框GestureDetector触发，当前值=$currentValue');
    }

    // 解析待办事项
    final todos = TodoParser.parseTodos(widget.note.content);
    if (todos.isEmpty) return;

    // 找到第一个匹配当前状态的待办事项
    TodoItem? targetTodo;
    for (final todo in todos) {
      if (todo.checked == currentValue) {
        targetTodo = todo;
        break;
      }
    }

    if (targetTodo == null) return;

    // 切换状态
    final newContent =
        TodoParser.toggleTodoAtLine(widget.note.content, targetTodo.lineNumber);

    if (kDebugMode) {
      debugPrint(
        'NoteCard: 切换待办事项 行${targetTodo.lineNumber}: "${targetTodo.text}"',
      );
    }

    // 更新笔记
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateNote(widget.note, newContent).then((_) {
      if (kDebugMode) {
        debugPrint('NoteCard: 待办事项状态已更新');
      }
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('NoteCard: 更新待办事项失败: $error');
      }
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.updateFailed ?? '更新失败',
      );
    });
  }

  // 构建图片组件，支持不同类型的图片源，支持长按保存
  Widget _buildImageWidget(String imagePath, BuildContext context) {
    try {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        // 🚀 网络图片 - 90天长期缓存，支持长按保存
        return SaveableImage(
          imageUrl: imagePath,
          child: CachedNetworkImage(
            imageUrl: imagePath,
            cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
            fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: const Duration(milliseconds: 50),
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const SizedBox(),
          ),
          errorWidget: (context, url, error) {
            // 🔥 离线模式：即使网络失败，也尝试从缓存加载
            return FutureBuilder<File?>(
              future: _getCachedImageFile(url),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(snapshot.data!, fit: BoxFit.cover);
                }
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                );
              },
            );
          },
          ),
        );
      } else if (imagePath.startsWith('/o/r/') ||
          imagePath.startsWith('/file/') ||
          imagePath.startsWith('/resource/')) {
        // Memos服务器资源路径
        final appProvider = Provider.of<AppProvider>(context, listen: false);

        // 🔥 构建完整URL（即使退出登录也能访问缓存）
        String fullUrl;
        if (appProvider.resourceService != null) {
          fullUrl = appProvider.resourceService!.buildImageUrl(imagePath);
        } else {
          // 退出登录后，尝试从缓存的服务器URL构建
          final serverUrl = appProvider.appConfig.lastServerUrl ??
              appProvider.appConfig.memosApiUrl ??
              '';
          if (serverUrl.isNotEmpty) {
            fullUrl = '$serverUrl$imagePath';
          } else {
            // 无法构建URL，尝试直接从缓存加载
            return FutureBuilder<File?>(
              future: _findImageInCache(imagePath),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(snapshot.data!, fit: BoxFit.cover);
                }
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                );
              },
            );
          }
        }

        final token = appProvider.user?.token;
        final headers = <String, String>{};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        // 🚀 使用90天长期缓存，支持长按保存
        return SaveableImage(
          imageUrl: fullUrl,
          headers: headers,
          child: CachedNetworkImage(
            imageUrl: fullUrl,
            cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
            httpHeaders: headers,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            fadeOutDuration: const Duration(milliseconds: 50),
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const SizedBox(),
            ),
            errorWidget: (context, url, error) {
              // 🔥 离线模式：即使网络失败，也尝试从缓存加载
              return FutureBuilder<File?>(
                future: _getCachedImageFile(fullUrl),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.file(snapshot.data!, fit: BoxFit.cover);
                  }
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  );
                },
              );
            },
          ),
        );
      } else if (imagePath.startsWith('file://')) {
        // 本地文件
        final filePath = imagePath.replaceFirst('file://', '');
        return Image.file(
          File(filePath),
          key: ValueKey(filePath), // 添加key强制刷新
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint('Local file image error: $error for $filePath');
            }
            // 如果图片文件不存在，尝试触发刷新来获取修复后的路径
            return Center(
              child: Icon(Icons.broken_image, color: Colors.grey[600]),
            );
          },
        );
      }

      // 默认情况
      // if (kDebugMode) debugPrint('NoteCard: 未知图片路径格式: $imagePath');
      return Center(child: Icon(Icons.broken_image, color: Colors.grey[600]));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _buildImageWidget: $e for $imagePath');
      }
      return Center(child: Icon(Icons.broken_image, color: Colors.grey[600]));
    }
  }

  // 🔥 从缓存获取图片文件（离线模式）
  Future<File?> _getCachedImageFile(String url) async {
    try {
      final fileInfo =
          await ImageCacheManager.authImageCache.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      if (kDebugMode) debugPrint('获取缓存图片失败: $e');
      return null;
    }
  }

  // 🔥 在缓存中查找图片（通过路径片段匹配）
  Future<File?> _findImageInCache(String imagePath) async {
    try {
      // 尝试多个可能的服务器URL前缀
      final possibleUrls = [
        'https://memos.didichou.site$imagePath',
        'http://localhost$imagePath',
      ];

      for (final url in possibleUrls) {
        final fileInfo =
            await ImageCacheManager.authImageCache.getFileFromCache(url);
        if (fileInfo != null) {
          if (kDebugMode) debugPrint('找到缓存图片: $url');
          return fileInfo.file;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('查找缓存图片失败: $e');
      return null;
    }
  }

  // 根据URI获取适当的ImageProvider
  ImageProvider _getImageProvider(String uriString, BuildContext context) {
    try {
      if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
        // 网络图片
        return NetworkImage(uriString);
      } else if (uriString.startsWith('/o/r/') ||
          uriString.startsWith('/file/') ||
          uriString.startsWith('/resource/')) {
        // Memos服务器资源路径，支持多种路径格式
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        if (appProvider.resourceService != null) {
          final fullUrl = appProvider.resourceService!.buildImageUrl(uriString);
          final token = appProvider.user?.token;
          // if (kDebugMode) debugPrint('NoteCard: 加载Memos图片 - 原路径: $uriString, URL: $fullUrl, 有Token: ${token != null}');
          if (token != null) {
            return CachedNetworkImageProvider(
              fullUrl,
              headers: {'Authorization': 'Bearer $token'},
            );
          } else {
            return CachedNetworkImageProvider(fullUrl);
          }
        } else {
          // 如果没有资源服务，尝试使用基础URL
          final baseUrl = appProvider.user?.serverUrl ??
              appProvider.appConfig.memosApiUrl ??
              '';
          if (baseUrl.isNotEmpty) {
            final token = appProvider.user?.token;
            final fullUrl = '$baseUrl$uriString';
            // if (kDebugMode) debugPrint('NoteCard: 加载Memos图片(fallback) - URL: $fullUrl, 有Token: ${token != null}');
            if (token != null) {
              return CachedNetworkImageProvider(
                fullUrl,
                headers: {'Authorization': 'Bearer $token'},
              );
            } else {
              return CachedNetworkImageProvider(fullUrl);
            }
          }
        }
        return const AssetImage('assets/images/logo.png');
      } else if (uriString.startsWith('file://')) {
        // 本地文件
        final filePath = uriString.replaceFirst('file://', '');
        return FileImage(File(filePath));
      } else if (uriString.startsWith('resource:')) {
        // 资源图片
        final assetPath = uriString.replaceFirst('resource:', '');
        return AssetImage(assetPath);
      } else {
        // 未知路径格式，记录并使用默认图片
        // if (kDebugMode) debugPrint('NoteCard: 未知图片路径格式: $uriString');
        return const AssetImage('assets/images/logo.png');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error in _getImageProvider: $e');
      return const AssetImage('assets/images/logo.png');
    }
  }

  // 显示更多选项菜单（使用统一组件，和详情页完全相同的功能）
  void _showMoreOptions(BuildContext context) {
    NoteMoreOptionsMenu.show(
      context: context,
      note: widget.note,
      onNoteUpdated: widget.onNoteUpdated, // 传递回调
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final cardShadow = isDarkMode
        ? null
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    return Container(
      margin: const EdgeInsets.only(
        left: 8, // 左边距8px
        right: 8, // 右边距8px
        bottom: 5, // 底部间距5px，这样两个卡片之间的间距就是5px
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // 🔥 确保侧滑背景也有圆角
        clipBehavior: Clip.antiAlias, // 强制裁剪
        child: Slidable(
          key: ValueKey(widget.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(), // 🔥 类似微信的抽屉效果
            extentRatio: 0.55, // 🔥 侧滑区域占55%宽度，完美显示3个按钮
            children: [
              // 🎯 置顶按钮
              SlidableAction(
                onPressed: (context) {
                  // 🔥 先保存侧滑上下文
                  final slidableContext = Slidable.of(context);
                  widget.onPin();
                  // 🔥 操作后自动关闭侧滑
                  slidableContext?.close();
                },
                backgroundColor: widget.isPinned
                    ? Colors.grey.shade600
                    : const Color(0xFF007AFF), // iOS蓝
                foregroundColor: Colors.white,
                label: widget.isPinned
                    ? (AppLocalizationsSimple.of(context)?.unpinAction ??
                        '取消置顶')
                    : (AppLocalizationsSimple.of(context)?.pinAction ?? '置顶'),
                padding: EdgeInsets.zero,
              ),
              // 🎯 提醒按钮（如果已有提醒则直接取消，否则设置）
              SlidableAction(
                onPressed: (slidableContext) async {
                  // 🔥 保存侧滑上下文和稳定的 widget context
                  final slidable = Slidable.of(slidableContext);
                  final stableContext = context; // widget 的 context，只要 widget 存在就有效
                  
                  if (widget.note.reminderTime != null) {
                    // 已有提醒，直接取消
                    final appProvider = Provider.of<AppProvider>(stableContext, listen: false);
                    try {
                      await appProvider.cancelNoteReminder(widget.note.id);
                      widget.onNoteUpdated?.call();
                      if (mounted) {
                        SnackBarUtils.showSuccess(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.cancelSuccess ?? '取消成功',
                        );
                        // 🔥 延迟后关闭侧滑，确保通知能正常显示
                        await Future.delayed(const Duration(milliseconds: 200));
                        slidable?.close();
                      }
                      return; // 取消操作完成，直接返回
                    } catch (e) {
                      if (mounted) {
                        SnackBarUtils.showError(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.cancelFailed ?? '取消失败',
                        );
                        await Future.delayed(const Duration(milliseconds: 200));
                        slidable?.close();
                      }
                      return; // 失败也返回
                    }
                  } else {
                    // 没有提醒，打开设置
                    final result = await NoteActionsService.showReminderSettings(
                      context: stableContext,
                      note: widget.note,
                      onUpdated: () {
                        widget.onNoteUpdated?.call();
                      },
                    );
                    
                    // 🔥 使用 widget 的 context 显示通知
                    if (mounted) {
                      if (result == true) {
                        SnackBarUtils.showSuccess(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.setSuccess ?? '设置成功',
                        );
                      } else if (result == false) {
                        SnackBarUtils.showError(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.setFailed ?? '设置失败',
                        );
                      }
                    }
                  }
                  // 🔥 延迟后关闭侧滑，确保通知能正常显示
                  await Future.delayed(const Duration(milliseconds: 200));
                  slidable?.close();
                },
                backgroundColor: widget.note.reminderTime != null
                    ? Colors.grey // 已有提醒时显示灰色（表示取消）
                    : const Color(0xFFFF9500), // iOS橙色（表示设置）
                foregroundColor: Colors.white,
                label: widget.note.reminderTime != null
                    ? (AppLocalizationsSimple.of(context)?.cancelReminder ?? '取消提醒')
                    : (AppLocalizationsSimple.of(context)?.setReminder ?? '提醒'),
                padding: EdgeInsets.zero,
              ),
              // 🎯 删除按钮
              SlidableAction(
                onPressed: (context) {
                  widget.onDelete();
                  // 删除不需要关闭，因为项目会被移除
                },
                backgroundColor: const Color(0xFFFF3B30), // iOS红色
                foregroundColor: Colors.white,
                label: AppLocalizationsSimple.of(context)?.deleteAction ?? '删除',
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: 1.0 - (_scaleAnimation.value * 0.03),
              child: GestureDetector(
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                onTap: () {
                  // 🎯 单击：跳转到笔记详情页（查看模式）
                  context.push('/note/${widget.id}');
                },
                onDoubleTap: () {
                  // 🎯 双击：直接编辑笔记
                  widget.onEdit();
                },
                behavior: HitTestBehavior.translucent,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: cardShadow,
                      border: widget.isPinned
                          ? Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias, // 强制裁剪
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 顶部栏：时间和更多按钮
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(widget.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Builder(
                                  builder: (btnContext) => Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: (isDarkMode
                                              ? AppTheme.darkBackgroundColor
                                              : AppTheme.backgroundColor)
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.more_horiz,
                                        color: isDarkMode
                                            ? AppTheme.darkTextSecondaryColor
                                            : Colors.grey[600],
                                        size: 14,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          _showMoreOptions(btnContext),
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                                ],
                              ),
                              const SizedBox(height: 8), // 减小顶部和内容之间的间距
                              Flexible(
                                fit: FlexFit.loose,
                                child: _buildContent(),
                              ),
                              // 底部：引用和批注图标
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: _buildReferences(), // 引用显示功能（左下角）
                                  ),
                                  _buildAnnotationBadge(), // 批注图标（右下角）
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ), // 🔥 Slidable 结束
      ), // 🔥 ClipRRect 结束
    );
  }

  // 构建引用和被引用的小图标
  Widget _buildReferences() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context, listen: true);
    final notes = appProvider.notes;
    
    // 获取当前笔记的信息
    final currentNote = notes.firstWhere(
      (note) => note.id == widget.id.toString(),
      orElse: () => Note(
        id: widget.id.toString(),
        content: widget.content,
        createdAt: widget.timestamp,
        updatedAt: widget.timestamp,
      ),
    );
    
    // 如果没有引用关系，返回空Widget
    if (currentNote.relations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 分析引用关系
    final outgoingRefs = <Map<String, dynamic>>[];  // 当前笔记引用的其他笔记（↗）
    final incomingRefs = <Map<String, dynamic>>[];  // 其他笔记引用当前笔记（↖）
    
    final currentId = widget.id.toString();
    
    // 检查当前笔记的引用关系
    for (final relation in currentNote.relations) {
      final type = relation['type'];
      if (type == 1 || type == 'REFERENCE') {
        final memoId = relation['memoId']?.toString();
        if (memoId == currentId || memoId == null || memoId.isEmpty) {
          outgoingRefs.add(relation);
        }
      }
    }
    
    // 检查当前笔记的被引用关系
    for (final relation in currentNote.relations) {
      final type = relation['type'];
      if (type == 'REFERENCED_BY') {
        final relatedMemoId = relation['relatedMemoId']?.toString();
        if (relatedMemoId == currentId) {
          incomingRefs.add(relation);
        }
      }
    }
    
    if (outgoingRefs.isEmpty && incomingRefs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 返回简洁的角标样式（只显示引用图标）
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxWidth: double.infinity), // 防止溢出
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 引用其他笔记的图标（↗）
          if (outgoingRefs.isNotEmpty)
            InkWell(
              onTap: () => _showReferencesSheet(currentNote),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.north_east,  // 右斜上方箭头
                      size: 12,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${outgoingRefs.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 被其他笔记引用的图标（↖）
          if (incomingRefs.isNotEmpty)
            InkWell(
              onTap: () => _showReferencesSheet(currentNote),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.north_west,  // 左斜上方箭头
                      size: 12,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${incomingRefs.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建批注图标（右下角）
  Widget _buildAnnotationBadge() {
    final appProvider = Provider.of<AppProvider>(context, listen: true);
    final notes = appProvider.notes;
    
    // 获取当前笔记的信息
    final currentNote = notes.firstWhere(
      (note) => note.id == widget.id.toString(),
      orElse: () => Note(
        id: widget.id.toString(),
        content: widget.content,
        createdAt: widget.timestamp,
        updatedAt: widget.timestamp,
      ),
    );
    
    // 获取批注数量
    final annotationCount = currentNote.annotations.length;
    
    // 如果没有批注，返回空Widget
    if (annotationCount == 0) {
      return const SizedBox.shrink();
    }
    
    // 返回批注图标（右下角）- 可点击
    return InkWell(
      onTap: () => _showAnnotationsSidebar(currentNote),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              size: 14,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '$annotationCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示批注侧边栏
  void _showAnnotationsSidebar(Note note) {
    // 在主页直接显示批注侧边栏
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
          note: note,
          onAnnotationTap: (annotation) {
            // 关闭侧边栏并跳转到笔记详情
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailScreen(noteId: note.id),
              ),
            );
          },
          onAddAnnotation: () {
            Navigator.pop(context);
            _showAddAnnotationDialog(note);
          },
          onEditAnnotation: (annotation) {
            Navigator.pop(context);
            _showEditAnnotationDialog(note, annotation);
          },
          onDeleteAnnotation: (annotationId) {
            Navigator.pop(context);
            _deleteAnnotation(note, annotationId);
          },
          onResolveAnnotation: (annotation) {
            _resolveAnnotation(note, annotation);
          },
        ),
      ),
    );
  }

  // 添加批注对话框
  void _showAddAnnotationDialog(Note note) {
    final localizations = AppLocalizationsSimple.of(context);
    final textController = TextEditingController();
    AnnotationType selectedType = AnnotationType.comment;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    hintText: localizations?.annotationPlaceholder ?? '在这里写下你的批注...',
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
                  _addAnnotation(note, content, selectedType);
                  Navigator.pop(context);
                }
              },
              child: Text(localizations?.addAnnotation ?? '添加'),
            ),
          ],
        ),
      ),
    );
  }

  // 添加批注
  void _addAnnotation(Note note, String content, AnnotationType type) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    final newAnnotation = Annotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      type: type,
    );

    final updatedAnnotations = [...note.annotations, newAnnotation];
    final updatedNote = note.copyWith(
      annotations: updatedAnnotations,
      updatedAt: DateTime.now(),
    );

    appProvider.updateNote(updatedNote, updatedNote.content);
    final localizations = AppLocalizationsSimple.of(context);
    SnackBarUtils.showSuccess(context, localizations?.annotationAdded ?? '批注已添加');
  }

  // 编辑批注对话框
  void _showEditAnnotationDialog(Note note, Annotation annotation) {
    final localizations = AppLocalizationsSimple.of(context);
    final textController = TextEditingController(text: annotation.content);
    AnnotationType selectedType = annotation.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(localizations?.editAnnotation ?? '编辑批注'),
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
                          Text(tempAnnotation.getTypeText(context)),
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
                    hintText: localizations?.annotationEditPlaceholder ?? '修改批注内容...',
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
                  _updateAnnotation(note, annotation.id, content, selectedType);
                  Navigator.pop(context);
                }
              },
              child: Text(localizations?.save ?? '保存'),
            ),
          ],
        ),
      ),
    );
  }

  // 更新批注
  void _updateAnnotation(Note note, String annotationId, String newContent, AnnotationType newType) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    final updatedAnnotations = note.annotations.map((a) {
      if (a.id == annotationId) {
        return a.copyWith(
          content: newContent,
          type: newType,
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
    final localizations = AppLocalizationsSimple.of(context);
    SnackBarUtils.showSuccess(context, localizations?.annotationUpdated ?? '批注已更新');
  }

  // 删除批注
  void _deleteAnnotation(Note note, String annotationId) {
    final localizations = AppLocalizationsSimple.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteAnnotation ?? '删除批注'),
        content: Text(localizations?.confirmDeleteAnnotation ?? '确定要删除这条批注吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? '取消'),
          ),
          FilledButton(
            onPressed: () {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              
              final updatedAnnotations = note.annotations
                  .where((a) => a.id != annotationId)
                  .toList();

              final updatedNote = note.copyWith(
                annotations: updatedAnnotations,
                updatedAt: DateTime.now(),
              );

              appProvider.updateNote(updatedNote, updatedNote.content);
              Navigator.pop(context);
              SnackBarUtils.showSuccess(context, localizations?.annotationDeleted ?? '批注已删除');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(localizations?.delete ?? '删除'),
          ),
        ],
      ),
    );
  }

  // 标记批注为已解决
  void _resolveAnnotation(Note note, Annotation annotation) {
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
    final localizations = AppLocalizationsSimple.of(context);
    SnackBarUtils.showSuccess(context, localizations?.markedAsResolved ?? '已标记为已解决');
  }

  // 📝 显示引用关系侧边栏
  void _showReferencesSheet(Note note) {
    NoteActionsService.showReferences(
      context: context,
      note: note,
    );
  }
}

// 图片查看器页面
class _ImageViewerScreen extends StatefulWidget {
  const _ImageViewerScreen({required this.imagePath});
  final String imagePath;

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  // 🚀 大厂标准：默认填满屏幕无黑边
  BoxFit _boxFit = BoxFit.cover; // 默认填满屏幕
  DateTime? _lastTapTime;

  // 静态图片处理方法
  static ImageProvider _getImageProvider(
    String uriString,
    BuildContext context,
  ) {
    try {
      if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
        // 网络图片
        return NetworkImage(uriString);
      } else if (uriString.startsWith('/o/r/') ||
          uriString.startsWith('/file/') ||
          uriString.startsWith('/resource/')) {
        // Memos服务器资源路径，支持多种路径格式
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        if (appProvider.resourceService != null) {
          final fullUrl = appProvider.resourceService!.buildImageUrl(uriString);
          final token = appProvider.user?.token;
          // if (kDebugMode) debugPrint('ImageViewer: 加载Memos图片 - 原路径: $uriString, URL: $fullUrl, 有Token: ${token != null}');
          if (token != null) {
            return CachedNetworkImageProvider(
              fullUrl,
              headers: {'Authorization': 'Bearer $token'},
            );
          } else {
            return CachedNetworkImageProvider(fullUrl);
          }
        } else {
          // 如果没有资源服务，尝试使用基础URL
          final baseUrl = appProvider.user?.serverUrl ??
              appProvider.appConfig.memosApiUrl ??
              '';
          if (baseUrl.isNotEmpty) {
            final token = appProvider.user?.token;
            final fullUrl = '$baseUrl$uriString';
            // if (kDebugMode) debugPrint('ImageViewer: 加载Memos图片(fallback) - URL: $fullUrl, 有Token: ${token != null}');
            if (token != null) {
              return CachedNetworkImageProvider(
                fullUrl,
                headers: {'Authorization': 'Bearer $token'},
              );
            } else {
              return CachedNetworkImageProvider(fullUrl);
            }
          }
        }
        return const AssetImage('assets/images/logo.png');
      } else if (uriString.startsWith('file://')) {
        // 本地文件
        final filePath = uriString.replaceFirst('file://', '');
        return FileImage(File(filePath));
      } else if (uriString.startsWith('resource:')) {
        // 资源图片
        final assetPath = uriString.replaceFirst('resource:', '');
        return AssetImage(assetPath);
      } else {
        // 未知路径格式，记录并使用默认图片
        // if (kDebugMode) debugPrint('NoteCard: 未知图片路径格式: $uriString');
        return const AssetImage('assets/images/logo.png');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error in _getImageProvider: $e');
      return const AssetImage('assets/images/logo.png');
    }
  }

  // 获取完整的图片URL（用于保存）
  String _getFullImageUrl(BuildContext context) {
    if (widget.imagePath.startsWith('http://') || widget.imagePath.startsWith('https://')) {
      return widget.imagePath;
    } else if (widget.imagePath.startsWith('/o/r/') ||
        widget.imagePath.startsWith('/file/') ||
        widget.imagePath.startsWith('/resource/')) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.resourceService != null) {
        return appProvider.resourceService!.buildImageUrl(widget.imagePath);
      } else {
        final baseUrl = appProvider.user?.serverUrl ??
            appProvider.appConfig.memosApiUrl ??
            '';
        if (baseUrl.isNotEmpty) {
          return '$baseUrl${widget.imagePath}';
        }
      }
    }
    return widget.imagePath;
  }

  // 获取请求头（用于需要认证的图片）
  Map<String, String>? _getHeaders(BuildContext context) {
    if (widget.imagePath.startsWith('/o/r/') ||
        widget.imagePath.startsWith('/file/') ||
        widget.imagePath.startsWith('/resource/')) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final token = appProvider.user?.token;
      if (token != null) {
        return {'Authorization': 'Bearer $token'};
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        // 🚀 大厂标准：使用透明背景，实现沉浸式全屏体验
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true, // AppBar透明，内容延伸到状态栏
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.3), // 半透明背景
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            AppLocalizationsSimple.of(context)?.viewOriginalImage ?? '查看原图', // 🚀 提示用户这是高清原图
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            // 保存图片按钮
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: AppLocalizationsSimple.of(context)?.saveImage ?? '保存图片',
              onPressed: () async {
                final fullUrl = _getFullImageUrl(context);
                final headers = _getHeaders(context);
                
                // 使用 ImageUtils 保存图片
                final success = await ImageUtils.saveImageToGallery(
                  context,
                  fullUrl,
                  headers: headers,
                );
                
                if (success && context.mounted) {
                  // 可以添加额外的成功提示或操作
                }
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            // 🚀 大厂标准：双击切换填充模式（contain <-> cover）
            final now = DateTime.now();
            if (_lastTapTime != null &&
                now.difference(_lastTapTime!).inMilliseconds < 300) {
              // 双击
              setState(() {
                _boxFit = _boxFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
              });
              // 显示提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _boxFit == BoxFit.cover 
                        ? (AppLocalizationsSimple.of(context)?.fillScreen ?? '填满屏幕')
                        : (AppLocalizationsSimple.of(context)?.fitScreen ?? '适应屏幕'),
                  ),
                  duration: const Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
                ),
              );
            } else {
              // 单击退出
              Navigator.of(context).pop();
            }
            _lastTapTime = now;
          },
          child: Container(
            // 🚀 大厂标准：全屏黑色背景，无边距
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildCachedImage(context),
              ),
            ),
          ),
        ),
      );

  // 🚀 构建带缓存的图片（微信方案：磁盘+内存双缓存）
  Widget _buildCachedImage(BuildContext context) {
    // 处理网络图片 - 全屏原图（90天缓存）
    if (widget.imagePath.startsWith('http://') || widget.imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: widget.imagePath,
        cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
        fit: _boxFit,
        placeholder: (context, url) => Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                AppLocalizationsSimple.of(context)?.loadingHDImage ?? '正在加载高清原图...',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        errorWidget: (context, url, error) {
          if (kDebugMode) debugPrint('Full screen image error: $error');
          // 🔥 离线模式：尝试从缓存加载
          return FutureBuilder<File?>(
            future: ImageCacheManager.authImageCache
                .getFileFromCache(url)
                .then((info) => info?.file),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.file(snapshot.data!, fit: _boxFit);
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.imageLoadError ?? '无法加载图片',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizationsSimple.of(context)?.networkFailedNoCache ?? '网络连接失败且无缓存',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    // 处理 Memos 服务器资源
    if (widget.imagePath.startsWith('/o/r/') ||
        widget.imagePath.startsWith('/file/') ||
        widget.imagePath.startsWith('/resource/')) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.resourceService != null) {
        final fullUrl = appProvider.resourceService!.buildImageUrl(widget.imagePath);
        final token = appProvider.user?.token;

        final headers = <String, String>{};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        return CachedNetworkImage(
          imageUrl: fullUrl,
          cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
          httpHeaders: headers,
          fit: _boxFit,
          placeholder: (context, url) => Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  AppLocalizationsSimple.of(context)?.loadingHDImage ?? '正在加载高清原图...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          errorWidget: (context, url, error) {
            if (kDebugMode) debugPrint('Full screen image error: $error');
            // 🔥 离线模式：尝试从缓存加载
            return FutureBuilder<File?>(
              future: ImageCacheManager.authImageCache
                  .getFileFromCache(fullUrl)
                  .then((info) => info?.file),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.file(snapshot.data!, fit: _boxFit);
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizationsSimple.of(context)?.imageLoadError ?? '无法加载图片',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizationsSimple.of(context)?.authFailedNoCache ?? '认证失败且无缓存',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }

    // 处理本地文件
    if (widget.imagePath.startsWith('file://')) {
      final filePath = widget.imagePath.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        fit: _boxFit,
        errorBuilder: (context, error, stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              '无法加载图片',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 未知格式
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(
          AppLocalizationsSimple.of(context)?.unsupportedImageFormat ?? '不支持的图片格式',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

// 全部图片页面
class _AllImagesScreen extends StatelessWidget {
  const _AllImagesScreen({required this.imagePaths});
  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            AppLocalizationsSimple.of(context)
                    ?.allImagesCount
                    .replaceAll('{count}', '${imagePaths.length}') ??
                '全部图片 (${imagePaths.length})',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        _ImageViewerScreen(imagePath: imagePaths[index]),
                  ),
                );
              },
              child: _buildGridItem(imagePaths[index], context),
            ),
          ),
        ),
      );

  Widget _buildGridItem(String path, BuildContext context) {
    final imageProvider = _ImageViewerScreenState._getImageProvider(path, context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: Colors.grey[800],
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) debugPrint('Grid image error: $error for $path');
            return Container(
              color: Colors.grey[800],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            );
          },
        ),
      ),
    );
  }
}
