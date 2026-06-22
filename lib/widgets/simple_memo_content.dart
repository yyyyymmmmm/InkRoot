import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/services/memos_resource_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/image_utils.dart';
import 'package:inkroot/utils/memos_content_helper.dart';
import 'package:inkroot/utils/memos_markdown_converter.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/tag_path_utils.dart';
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:inkroot/widgets/animated_checkbox.dart';
import 'package:inkroot/widgets/image_viewer_screen.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SimpleMemoContent extends StatefulWidget {
  // 🎯 大厂标准：直接限制行数（微信朋友圈方案）

  const SimpleMemoContent({
    required this.content,
    super.key,
    this.serverUrl,
    this.onTagTap,
    this.onLinkTap,
    this.selectable = true,
    this.maxLines, // 可选参数，不设置则显示全部内容
    this.note, // 🎯 可选的note对象（用于交互）
    this.onCheckboxTap, // 🎯 复选框点击回调
    this.highlightQuery,
    this.referenceNotes,
    this.compactHeadings = false,
  });
  final String content;
  final String? serverUrl;
  final Function(String)? onTagTap;
  final Function(String)? onLinkTap;
  final bool selectable;
  final int? maxLines;
  final Note? note; // 🎯 可选的note对象
  final Function(int todoIndex)? onCheckboxTap; // 🎯 复选框点击回调，传递待办事项索引
  final String? highlightQuery;
  final List<Note>? referenceNotes;
  final bool compactHeadings;

  @override
  State<SimpleMemoContent> createState() => _SimpleMemoContentState();
}

class _SimpleMemoContentState extends State<SimpleMemoContent> {
  int _checkboxCounter = 0; // 用于追踪当前是第几个复选框

  @override
  void didUpdateWidget(SimpleMemoContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 内容变化时重置计数器
    if (oldWidget.content != widget.content) {
      _checkboxCounter = 0;
    }
  }

  /// 收起状态下截断内容，只取前 N 行和有限字符，避免全量 Markdown 解析
  String _truncateForPreview(String content, int maxLines) {
    const maxChars = 600; // 6行约100字/行，留余量
    if (content.length <= maxChars) {
      return content;
    }

    // 优先按换行截断
    final lines = content.split('\n');
    if (lines.length > maxLines) {
      final preview = lines.take(maxLines + 2).join('\n');
      return preview.length <= maxChars
          ? preview
          : preview.substring(0, maxChars);
    }
    return content.substring(0, maxChars);
  }

  // 🎯 预处理引用：将 [[referenceStr]] 转换为可读的站内笔记链接
  String _preprocessReferencesWithContext(String content, List<Note> notes) {
    final referenceRegex = RegExp(r'\[\[([^\]]+)\]\]');
    return content.replaceAllMapped(referenceRegex, (match) {
      final referenceStr = match.group(1)!;

      // 解析引用格式（支持 id, memos/id, id?text=xxx）
      final parsed = _parseReference(referenceStr);
      final noteId = parsed['id']!;
      final customText = parsed['text'];

      final display = _resolveReferenceDisplay(
        noteId,
        notes,
        customText: customText,
      );

      // 转换为特殊的Markdown链接格式，用 ref: 前缀标识
      final encodedId = Uri.encodeComponent(noteId);
      final escapedText = _escapeMarkdownLinkText(display.text);
      final title = display.isMissing ? 'missing' : 'note';
      return '[$escapedText](ref:$encodedId "$title")';
    });
  }

  // 🎯 解析引用格式（支持 Memos 标准）
  Map<String, String?> _parseReference(String referenceStr) {
    var cleanRef = referenceStr.trim();
    String? customText;

    // 提取 ?text= 参数
    if (cleanRef.contains('?text=')) {
      final parts = cleanRef.split('?text=');
      cleanRef = parts[0];
      if (parts.length > 1 && parts[1].isNotEmpty) {
        try {
          customText = Uri.decodeComponent(parts[1]);
        } on FormatException {
          customText = parts[1];
        }
      }
    }

    // 移除 memos/ 前缀（如果有）
    if (cleanRef.startsWith('memos/')) {
      cleanRef = cleanRef.substring(6);
    }

    return {'id': cleanRef, 'text': customText};
  }

  _ReferenceDisplay _resolveReferenceDisplay(
    String noteId,
    List<Note> notes, {
    String? customText,
  }) {
    final maxChars =
        (widget.compactHeadings || widget.maxLines != null) ? 18 : 30;
    final noteIndex = notes.indexWhere((note) => note.id == noteId);
    final isMissing = noteIndex < 0;

    final alias = customText?.trim();
    if (alias != null && alias.isNotEmpty) {
      return _ReferenceDisplay(
        _sanitizeReferenceDisplayText(alias, maxChars: maxChars),
        isMissing: isMissing,
      );
    }

    if (isMissing) {
      return const _ReferenceDisplay('已删除的笔记', isMissing: true);
    }

    return _ReferenceDisplay(
      _extractDisplayText(notes[noteIndex].content, maxChars: maxChars),
      isMissing: false,
    );
  }

  String _extractDisplayText(String content, {required int maxChars}) {
    if (content.isEmpty) {
      return '空笔记';
    }

    final lines = content.split('\n');
    for (final line in lines) {
      final cleaned = _cleanReferenceLine(line);
      if (cleaned.isEmpty || _isPureTagLine(cleaned)) {
        continue;
      }
      return _truncateReferenceText(cleaned, maxChars: maxChars);
    }

    final hasImage = RegExp(r'!\[[^\]]*\]\([^)]+\)').hasMatch(content);
    return hasImage ? '图片笔记' : '空笔记';
  }

  String _sanitizeReferenceDisplayText(
    String text, {
    required int maxChars,
  }) {
    final cleaned = _cleanReferenceLine(text);
    if (cleaned.isEmpty) {
      return '空笔记';
    }
    return _truncateReferenceText(cleaned, maxChars: maxChars);
  }

  String _cleanReferenceLine(String line) {
    var cleaned = line.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    cleaned = cleaned.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '');
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'<[uU]\b[^>]*>([\s\S]*?)<\/[uU]>'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAll(RegExp('<[^>]+>'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^>\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^[-*+]\s+\[[ xX]\]\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^[-*+]\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^\d+\.\s+'), '');
    cleaned = cleaned.replaceAll(RegExp('[*_`~]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  bool _isPureTagLine(String text) {
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    if (words.isEmpty) {
      return false;
    }
    return words.every((word) => word.startsWith('#') && word.length > 1);
  }

  String _truncateReferenceText(String text, {required int maxChars}) {
    final characters = text.runes.toList();
    if (characters.length <= maxChars) {
      return text;
    }
    return '${String.fromCharCodes(characters.take(maxChars))}...';
  }

  String _escapeMarkdownLinkText(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');

  String _decodeReferenceId(String encodedId) {
    try {
      return Uri.decodeComponent(encodedId);
    } on FormatException {
      return encodedId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 🎯 每次构建时重置复选框计数器
    _checkboxCounter = 0;

    // 收起状态下截断内容再解析，避免对超长笔记做全量 Markdown 渲染
    final rawContent = widget.maxLines != null
        ? _truncateForPreview(widget.content, widget.maxLines!)
        : widget.content;

    // 🎯 预处理：将 [[noteId]] 转换为可读的链接格式
    final referenceNotes = widget.referenceNotes ??
        Provider.of<AppProvider>(context, listen: false).rawNotes;
    final processedContent = _preprocessReferencesWithContext(
      rawContent,
      referenceNotes,
    );

    final converter = MemosMarkdownConverter(serverUrl: widget.serverUrl);
    final convertedContent = converter.convert(processedContent);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 🎯 大厂标准：如果设置了maxLines，用Container限制高度
        final markdownBody = MarkdownBody(
          data: convertedContent,
          selectable: widget.selectable,
          softLineBreak: true, // 单个换行也生效（符合笔记应用习惯）
          extensionSet:
              md.ExtensionSet.gitHubFlavored, // 🎯 启用GitHub风格Markdown（支持待办事项）
          inlineSyntaxes: [UnderlineSyntax()],
          checkboxBuilder: (value) {
            // 🎯 获取当前复选框的索引
            final currentIndex = _checkboxCounter++;

            // 🎯 优雅的动画复选框（参考 Things 3 / Todoist）
            // 包装在 Align 中确保垂直居中对齐
            return Align(
              alignment: Alignment.centerLeft,
              child: AnimatedCheckbox(
                value: value,
                onChanged: widget.onCheckboxTap != null
                    ? (newValue) {
                        // 🎯 如果提供了回调，则可交互
                        if (kDebugMode) {
                          debugPrint(
                            'SimpleMemoContent: 复选框 #$currentIndex 被点击 $value -> $newValue',
                          );
                        }
                        widget.onCheckboxTap?.call(currentIndex);
                      }
                    : null, // 没有回调则只读
                size: 18, // 减小尺寸以更好地与文字对齐
                borderRadius: 5,
              ),
            );
          },
          builders: {
            'a': ReferenceLinkBuilder(
              onReferenceTap: (noteId) =>
                  _handleReferenceNavigation(context, noteId),
            ),
            'u': UnderlineBuilder(),
          },
          onTapText: () {
            // 处理标签点击
            // final tags = MemosMarkdownConverter.extractTags(widget.content);
            // 这里可以添加标签点击逻辑
          },
          onTapLink: (text, href, title) {
            if (href != null && href.isNotEmpty) {
              // 处理标签点击 (#tag格式)
              if (href.startsWith('#') &&
                  text.startsWith('#') &&
                  href.length > 1) {
                // 这是标签，不是普通链接
                final tagPath = normalizeIncomingTagPath(href.substring(1));
                if (tagPath != null) {
                  widget.onTagTap?.call(tagPath);
                }
                return;
              }
              if (href.startsWith('ref:') && href.length > 4) {
                _handleReferenceNavigation(
                  context,
                  _decodeReferenceId(href.substring(4)),
                );
                return;
              }
              widget.onLinkTap?.call(href);
            }
          },
          styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
          styleSheet: MarkdownStyleSheet(
            p: AppTextStyles.bodyLarge(
              context,
              height: 1.6,
              color: isDarkMode ? const Color(0xFFE4E1DA) : Colors.black87,
            ),
            code: AppTextStyles.bodyMedium(
              context,
              color: isDarkMode ? Colors.white : Colors.black87,
            ).copyWith(
              backgroundColor: isDarkMode
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFF5F5F5),
              fontFamily: 'SF Mono',
            ),
            codeblockDecoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            codeblockPadding: const EdgeInsets.all(12),
            blockquote: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFE4E1DA)
                  : const Color(0xFF343A32),
              height: 1.58,
            ),
            blockquoteDecoration: BoxDecoration(
              color: (isDarkMode
                      ? AppTheme.primaryLightColor
                      : AppTheme.primaryColor)
                  .withValues(alpha: isDarkMode ? 0.10 : 0.06),
              border: Border(
                left: BorderSide(
                  color: (isDarkMode
                          ? AppTheme.primaryLightColor
                          : AppTheme.primaryColor)
                      .withValues(alpha: isDarkMode ? 0.70 : 0.45),
                  width: 3,
                ),
              ),
            ),
            blockquotePadding: EdgeInsets.fromLTRB(
              widget.compactHeadings ? 10 : 12,
              widget.compactHeadings ? 6 : 8,
              widget.compactHeadings ? 10 : 12,
              widget.compactHeadings ? 6 : 8,
            ),
            // 笔记流标题不做文档级放大，靠字重和行距表达层级。
            h1: AppTextStyles.custom(
              context,
              widget.compactHeadings ? 17 : 19,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
              height: widget.compactHeadings ? 1.36 : 1.34,
            ),
            h2: AppTextStyles.custom(
              context,
              widget.compactHeadings ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
              height: widget.compactHeadings ? 1.38 : 1.36,
            ),
            h3: AppTextStyles.custom(
              context,
              widget.compactHeadings ? 15.5 : 17,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
              height: 1.4,
            ),
            h4: AppTextStyles.custom(
              context,
              widget.compactHeadings ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
              height: 1.42,
            ),
            h5: AppTextStyles.custom(
              context,
              widget.compactHeadings ? 15 : 15.5,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
              height: 1.44,
            ),
            h6: AppTextStyles.custom(
              context,
              15,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              height: 1.45,
            ),
            a: TextStyle(
              color: isDarkMode
                  ? AppTheme.primaryLightColor
                  : AppTheme.primaryColor,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
            listBullet: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
            // 🎯 已完成任务的文字样式（删除线 + 颜色变浅，保持相同垂直对齐）
            del: AppTextStyles.bodyLarge(
              context,
              height: 1.6,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ).copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              decorationThickness: 2,
              leadingDistribution: TextLeadingDistribution.even, // 确保垂直居中
            ),
            // 🎯 复选框列表项样式（与正文相同大小，确保垂直对齐）
            checkbox: AppTextStyles.bodyLarge(
              context,
              height: 1.6,
              color: isDarkMode ? const Color(0xFFE4E1DA) : Colors.black87,
            ).copyWith(
              leadingDistribution: TextLeadingDistribution.even, // 确保垂直居中
            ),
            tableBody: AppTextStyles.bodyLarge(
              context,
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
            ),
          ),
          imageBuilder: (uri, title, alt) =>
              _buildImage(context, uri, isDarkMode),
        );

        // 🎯 大厂标准：如果设置了maxLines，用Container限制高度（微信朋友圈方案）
        if (widget.maxLines != null) {
          // 🔍 关键：必须与 MarkdownBody 的实际行高匹配
          // bodyLarge: fontSize=15.0, height=1.6 → 单行高度=24.0px
          final fontSize = ResponsiveUtils.responsiveFontSize(context, 15);
          const lineHeightMultiplier = 1.6; // 与 p 标签的 height 保持一致
          final singleLineHeight = fontSize * lineHeightMultiplier;

          // 🔥 修复长URL问题：使用更大的高度余量，避免内容抖动
          const heightAdjustment = 6; // 增加余量，避免半行文字露出

          return Container(
            height: widget.maxLines! * singleLineHeight + heightAdjustment,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: markdownBody,
                ),
                // 🎯 添加渐变遮罩，优化视觉效果
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: singleLineHeight * 0.5, // 半行高度的渐变
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          if (Theme.of(context).brightness == Brightness.dark)
                            AppTheme.darkCardColor.withValues(alpha: 0)
                          else
                            Colors.white.withValues(alpha: 0),
                          if (Theme.of(context).brightness == Brightness.dark)
                            AppTheme.darkCardColor
                          else
                            Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return markdownBody;
      },
    );
  }

  // 构建图片组件 - 支持token认证和缓存
  Widget _buildImage(BuildContext context, Uri uri, bool isDarkMode) {
    final imagePath = uri.toString();

    if (kDebugMode) {
      debugPrint('🖼️ SimpleMemoContent 图片: $imagePath');
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 处理HTTP/HTTPS图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () => _openImageViewer(context, imagePath),
          onLongPress: () {
            // 长按保存图片
            _showImageSaveDialog(context, imagePath);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imagePath,
              cacheManager: ImageCacheManager.authImageCache,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 200,
                color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                // 离线模式fallback
                return FutureBuilder<File?>(
                  future: ImageCacheManager.authImageCache
                      .getFileFromCache(url)
                      .then((info) => info?.file),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.file(snapshot.data!, fit: BoxFit.contain);
                    }
                    return Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizationsSimple.of(context)
                                    ?.imageLoadError ??
                                '图片加载失败',
                            style: AppTextStyles.bodySmall(
                              context,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    // 处理Memos服务器资源路径
    if (MemosResourceService.isServerResourcePath(imagePath)) {
      String fullUrl;
      if (appProvider.resourceService != null) {
        fullUrl = appProvider.resourceService!.buildImageUrl(imagePath);
      } else {
        final baseUrl =
            widget.serverUrl ?? appProvider.appConfig.memosApiUrl ?? '';
        fullUrl = baseUrl.isNotEmpty ? '$baseUrl$imagePath' : imagePath;
      }

      final token = appProvider.user?.token;
      if (kDebugMode) {
        debugPrint(
          '🖼️ Memos图片: $imagePath -> $fullUrl, token=${token != null}',
        );
      }

      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () => _openImageViewer(context, imagePath),
          onLongPress: () {
            // 长按保存图片
            _showImageSaveDialog(context, fullUrl, headers: headers);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: fullUrl,
              cacheManager: ImageCacheManager.authImageCache,
              httpHeaders: headers,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 200,
                color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                if (kDebugMode) {
                  debugPrint('🖼️ 图片加载错误: $error');
                }
                // 离线模式fallback
                return FutureBuilder<File?>(
                  future: ImageCacheManager.authImageCache
                      .getFileFromCache(fullUrl)
                      .then((info) => info?.file),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.file(snapshot.data!, fit: BoxFit.contain);
                    }
                    return Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizationsSimple.of(context)
                                    ?.imageLoadError ??
                                '图片加载失败',
                            style: AppTextStyles.bodySmall(
                              context,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (fullUrl.length < 100)
                            Text(
                              fullUrl,
                              style: AppTextStyles.custom(
                                context,
                                10,
                                color: Colors.grey[500],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    // 处理本地文件（绝对路径）
    if (imagePath.startsWith('file://')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () => _openImageViewer(context, imagePath),
          onLongPress: () {
            // 长按保存图片（本地文件）
            _showImageSaveDialog(context, imagePath);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath.replaceFirst('file://', '')),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) {
                  debugPrint('❌ local file image error: $error for $imagePath');
                }
                return Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizationsSimple.of(context)?.imagePathInvalid ??
                            '图片路径已失效',
                        style: AppTextStyles.bodySmall(
                          context,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // 🎯 大厂标准：处理相对路径（用于Flomo导入等场景，避免绝对路径失效）
    // 相对路径示例：images/flomo_xxx.jpg
    if (imagePath.startsWith('images/') || imagePath.startsWith('assets/')) {
      return FutureBuilder<String>(
        future: _resolveLocalImagePath(imagePath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 200,
              color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final fullPath = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () => _openImageViewer(context, 'file://$fullPath'),
              onLongPress: () {
                _showImageSaveDialog(
                  context,
                  'file://$fullPath',
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(fullPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      debugPrint(
                        '❌ 相对路径图片加载失败: $error for $imagePath -> $fullPath',
                      );
                    }
                    return Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      color: (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizationsSimple.of(context)?.imageNotFound ??
                                '图片不存在',
                            style: AppTextStyles.bodySmall(
                              context,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox();
  }

  void _openImageViewer(BuildContext context, String imagePath) {
    final imagePaths = MemosContentHelper.extractMarkdownImagePaths(
      widget.content,
    );
    final uniquePaths = <String>[];
    for (final path in imagePaths) {
      if (!uniquePaths.contains(path)) {
        uniquePaths.add(path);
      }
    }
    if (!uniquePaths.contains(imagePath)) {
      uniquePaths.add(imagePath);
    }

    ImageViewerScreen.open(
      context,
      imagePaths: uniquePaths,
      initialIndex: uniquePaths.indexOf(imagePath).clamp(0, uniquePaths.length),
    );
  }

  // 🎯 将相对路径转换为绝对路径
  Future<String> _resolveLocalImagePath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$relativePath';
  }

  // 显示图片保存对话框
  void _showImageSaveDialog(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) =>
      ImageUtils.showImageSaveDialog(
        context,
        imageUrl,
        headers: headers,
      );

  // 处理引用导航（直接使用ID跳转）
  void _handleReferenceNavigation(BuildContext context, String noteId) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final noteExists =
        widget.referenceNotes?.any((note) => note.id == noteId) ??
            (appProvider.getNoteById(noteId) != null);

    if (!noteExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizationsSimple.of(context)?.referenceNoteMissing(noteId) ??
                '引用的笔记不存在或已被删除 (ID: $noteId)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => NoteDetailScreen(noteId: noteId),
      ),
    );
  }
}

class _ReferenceDisplay {
  const _ReferenceDisplay(this.text, {required this.isMissing});

  final String text;
  final bool isMissing;
}

class ReferenceLinkBuilder extends MarkdownElementBuilder {
  ReferenceLinkBuilder({
    required this.onReferenceTap,
  });

  final ValueChanged<String> onReferenceTap;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final href = element.attributes['href'];
    if (href == null || !href.startsWith('ref:') || href.length <= 4) {
      return null;
    }

    final noteId = _decodeId(href.substring(4));
    final isMissing = element.attributes['title'] == 'missing';
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primary =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final baseStyle =
        preferredStyle ?? parentStyle ?? DefaultTextStyle.of(context).style;
    final textColor = isMissing
        ? (isDarkMode ? const Color(0xFF969696) : const Color(0xFF80857C))
        : primary;
    final borderColor = isMissing
        ? (isDarkMode ? Colors.white24 : Colors.black12)
        : primary.withValues(alpha: isDarkMode ? 0.34 : 0.22);
    final backgroundColor = isMissing
        ? (isDarkMode ? Colors.white10 : const Color(0xFFF3F4F1))
        : primary.withValues(alpha: isDarkMode ? 0.14 : 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onReferenceTap(noteId),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            child: Text(
              element.textContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseStyle.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.26,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _decodeId(String encodedId) {
    try {
      return Uri.decodeComponent(encodedId);
    } on FormatException {
      return encodedId;
    }
  }
}

class UnderlineBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final baseStyle =
        preferredStyle ?? parentStyle ?? DefaultTextStyle.of(context).style;
    return RichText(
      text: TextSpan(
        text: element.textContent,
        style: baseStyle.copyWith(
          decoration: TextDecoration.combine([
            baseStyle.decoration ?? TextDecoration.none,
            TextDecoration.underline,
          ]),
        ),
      ),
    );
  }
}

class UnderlineSyntax extends md.InlineSyntax {
  UnderlineSyntax()
      : super(r'<[uU]\b[^>]*>([\s\S]*?)<\/[uU]>', startCharacter: 60);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('u', match.group(1) ?? ''));
    return true;
  }
}
