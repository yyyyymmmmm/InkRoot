import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/services/memos_resource_service.dart';
import 'package:inkroot/services/note_actions_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart'; // 🔥 添加长期缓存管理器
import 'package:inkroot/utils/memos_content_helper.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/utils/tag_path_utils.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:inkroot/utils/todo_parser.dart';
import 'package:inkroot/widgets/annotations_sidebar.dart';
import 'package:inkroot/widgets/image_viewer_screen.dart';
import 'package:inkroot/widgets/memos_markdown_renderer.dart';
import 'package:inkroot/widgets/note_more_options_menu.dart';
import 'package:inkroot/widgets/saveable_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    this.onNoteUpdated, // 新增：笔记更新回调（用于统一组件）
    this.disableTagNavigation = false, // 🎯 是否禁用标签点击跳转（避免无限嵌套）
    this.onTagTap,
    this.highlightQuery,
    this.referenceNotes,
    super.key,
  });
  final Note note; // 🚀 直接传递完整Note对象，避免查找
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback? onNoteUpdated; // 可选的笔记更新回调
  final bool disableTagNavigation; // 是否禁用标签跳转
  final ValueChanged<String>? onTagTap;
  final String? highlightQuery;
  final List<Note>? referenceNotes;

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
  // Feed cards collapse only the text body. Media is laid out separately.
  static const int _maxLines = 6;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final ValueNotifier<bool> _expandedNotifier = ValueNotifier<bool>(false);
  Note? _optimisticNote;

  // 🚀 精确测量文本行数的缓存
  bool? _needsExpansionCache;
  String? _lastMeasuredContent;

  Note get _effectiveNote => _optimisticNote ?? widget.note;

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

  Future<void> _copyNoteContent() async {
    final text = MemosContentHelper.previewVisibleText(widget.content).trim();
    final copyText = text.isEmpty ? widget.content.trim() : text;
    if (copyText.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: copyText));
    if (!mounted) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    SnackBarUtils.showSuccess(context, '已复制笔记内容');
  }

  // 处理标签和Markdown内容
  Widget _buildContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final note = _effectiveNote;

    final imagePaths = MemosContentHelper.extractNoteImagePaths(note);
    final contentWithoutImages =
        MemosContentHelper.removeMarkdownImages(note.content);
    final previewVisibleText =
        MemosContentHelper.previewVisibleText(contentWithoutImages);
    final expansionText =
        MemosContentHelper.previewTextForExpansion(contentWithoutImages);

    // 检查是否有文本内容。渲染时保留用户原始换行/空格，判断时才 trim。
    final hasTextContent = previewVisibleText.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final needsExpansion = _contentMightOverflow(
          expansionText,
          availableWidth,
        );

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
                  ValueListenableBuilder<bool>(
                    valueListenable: _expandedNotifier,
                    builder: (context, isExpanded, child) =>
                        MemosMarkdownRenderer(
                      content: contentWithoutImages,
                      serverUrl:
                          Provider.of<AppProvider>(context, listen: false)
                              .appConfig
                              .memosApiUrl,
                      selectable: false,
                      note: note, // 🎯 传入note对象
                      onCheckboxTap: _toggleTodoItem, // 🎯 复选框点击回调（传递索引）
                      mode: MemosMarkdownMode.cardPreview,
                      highlightQuery: widget.highlightQuery,
                      referenceNotes: widget.referenceNotes,
                      // 🎯 标签点击 - 根据配置决定是否跳转
                      onTagTap: widget.disableTagNavigation
                          ? null
                          : widget.onTagTap ??
                              (tagName) {
                                final tagPath =
                                    normalizeIncomingTagPath(tagName);
                                if (tagPath == null) {
                                  return;
                                }
                                context.pushNamed(
                                  'tag-notes',
                                  queryParameters: {'tag': tagPath},
                                );
                              },
                      // 🎯 链接点击 - 打开浏览器
                      onLinkTap: (url) async {
                        final uri = Uri.tryParse(url);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      maxLines:
                          (!isExpanded && needsExpansion) ? _maxLines : null,
                    ),
                  ),
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
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(imageCount, (index) {
                      final imageItem = SizedBox(
                        width: imageWidth,
                        height: imageWidth,
                        child: _buildUniformImageItem(
                          imagePaths[index],
                          imagePaths: imagePaths,
                          index: index,
                        ),
                      );

                      if (index != 8 || imagePaths.length <= 9) {
                        return imageItem;
                      }

                      return SizedBox(
                        width: imageWidth,
                        height: imageWidth,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            imageItem,
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showAllImages(imagePaths),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
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
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _contentMightOverflow(String visibleText, double maxWidth) {
    if (visibleText.trim().isEmpty || maxWidth <= 0) {
      return false;
    }

    final cacheKey = '$maxWidth\n$visibleText';

    // 🚀 缓存优化：避免重复测量相同内容
    if (_lastMeasuredContent == cacheKey && _needsExpansionCache != null) {
      return _needsExpansionCache!;
    }

    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDarkMode
          ? AppTheme.darkTextPrimaryColor
          : AppTheme.textPrimaryColor;
      final contentStyle = AppTextStyles.bodyLarge(
        context,
        height: 1.6,
        color: textColor,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: visibleText,
          style: contentStyle,
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: _maxLines,
      );

      textPainter.layout(maxWidth: maxWidth);

      // 缓存结果
      _lastMeasuredContent = cacheKey;
      _needsExpansionCache = textPainter.didExceedMaxLines;

      return _needsExpansionCache!;
    } on Object catch (e) {
      // 出错时回退到简单判断
      debugPrint('⚠️ TextPainter测量失败，回退到简单判断：$e');
      return '\n'.allMatches(visibleText).length >= _maxLines;
    }
  }

  // 构建统一大小的单个图片项
  Widget _buildUniformImageItem(
    String imagePath, {
    List<String>? imagePaths,
    int index = 0,
  }) {
    try {
      return GestureDetector(
        onTap: () => _showFullscreenImage(
          imagePath,
          imagePaths: imagePaths,
          initialIndex: index,
        ),
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
    } on Object catch (e) {
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
      ImageViewerScreen.open(context, imagePaths: imagePaths);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing all images: $e');
      }
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.cannotDisplayImage ?? '无法显示图片',
      );
    }
  }

  // 显示全屏图片
  void _showFullscreenImage(
    String imagePath, {
    List<String>? imagePaths,
    int initialIndex = 0,
  }) {
    try {
      final paths = imagePaths ?? [imagePath];
      ImageViewerScreen.open(
        context,
        imagePaths: paths,
        initialIndex: initialIndex,
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing fullscreen image: $e');
      }
      SnackBarUtils.showError(
        context,
        AppLocalizationsSimple.of(context)?.cannotDisplayImage ?? '无法显示图片',
      );
    }
  }

  // 🎯 切换指定索引的待办事项
  void _toggleTodoItem(int todoIndex) {
    final currentNote = _effectiveNote;
    final todos = TodoParser.parseTodos(currentNote.content);
    if (todoIndex < 0 || todoIndex >= todos.length) {
      if (kDebugMode) {
        debugPrint('NoteCard: 待办事项索引越界 $todoIndex/${todos.length}');
      }
      return;
    }

    // 切换待办事项的状态
    final todo = todos[todoIndex];
    final newContent =
        TodoParser.toggleTodoAtLine(currentNote.content, todo.lineNumber);

    if (kDebugMode) {
      debugPrint(
        'NoteCard: 切换待办事项 #$todoIndex 行${todo.lineNumber}: "${todo.text}"',
      );
    }

    setState(() {
      _optimisticNote = currentNote.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
        tags: tag_utils.extractTagsFromContent(newContent),
        isSynced: false,
      );
    });

    // 更新笔记
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateNote(currentNote, newContent).then((success) {
      if (kDebugMode) {
        debugPrint('NoteCard: 待办事项状态已更新 success=$success');
      }
      if (!mounted) {
        return;
      }
      if (!success) {
        setState(() {
          _optimisticNote = null;
        });
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.updateFailed ?? '更新失败',
        );
      }
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('NoteCard: 更新待办事项失败: $error');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _optimisticNote = null;
      });
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
            memCacheWidth: 720,
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
      } else if (MemosResourceService.isServerResourcePath(imagePath)) {
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
            memCacheWidth: 720,
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
    } on Object catch (e) {
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
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('获取缓存图片失败: $e');
      }
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
          if (kDebugMode) {
            debugPrint('找到缓存图片: $url');
          }
          return fileInfo.file;
        }
      }
      return null;
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('查找缓存图片失败: $e');
      }
      return null;
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
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ];
    final cardRadius = BorderRadius.circular(8);
    final borderColor = widget.isPinned
        ? AppTheme.primaryColor.withValues(alpha: isDarkMode ? 0.5 : 0.32)
        : (isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05));

    return Container(
      margin: const EdgeInsets.fromLTRB(
        10,
        0,
        10,
        8,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Slidable(
          key: ValueKey(widget.id),
          dragStartBehavior: DragStartBehavior.start,
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
                    : AppTheme.primaryColor,
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
                  final stableContext =
                      context; // widget 的 context，只要 widget 存在就有效

                  if (widget.note.reminderTime != null) {
                    // 已有提醒，直接取消
                    final appProvider =
                        Provider.of<AppProvider>(stableContext, listen: false);
                    try {
                      await appProvider.cancelNoteReminder(widget.note.id);
                      widget.onNoteUpdated?.call();
                      if (mounted && stableContext.mounted) {
                        SnackBarUtils.showSuccess(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.cancelSuccess ??
                              '取消成功',
                        );
                        // 🔥 延迟后关闭侧滑，确保通知能正常显示
                        await Future.delayed(const Duration(milliseconds: 200));
                        unawaited(slidable?.close());
                      }
                      return; // 取消操作完成，直接返回
                    } on Object {
                      if (mounted && stableContext.mounted) {
                        SnackBarUtils.showError(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.cancelFailed ??
                              '取消失败',
                        );
                        await Future.delayed(const Duration(milliseconds: 200));
                        unawaited(slidable?.close());
                      }
                      return; // 失败也返回
                    }
                  } else {
                    // 没有提醒，打开设置
                    final result =
                        await NoteActionsService.showReminderSettings(
                      context: stableContext,
                      note: widget.note,
                      onUpdated: () {
                        widget.onNoteUpdated?.call();
                      },
                    );

                    // 🔥 使用 widget 的 context 显示通知
                    if (mounted && stableContext.mounted) {
                      if (result ?? false) {
                        SnackBarUtils.showSuccess(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.setSuccess ??
                              '设置成功',
                        );
                      } else if (result == false) {
                        SnackBarUtils.showError(
                          stableContext,
                          AppLocalizationsSimple.of(context)?.setFailed ??
                              '设置失败',
                        );
                      }
                    }
                  }
                  // 🔥 延迟后关闭侧滑，确保通知能正常显示
                  await Future.delayed(const Duration(milliseconds: 200));
                  unawaited(slidable?.close());
                },
                backgroundColor: widget.note.reminderTime != null
                    ? Colors.grey // 已有提醒时显示灰色（表示取消）
                    : const Color(0xFFFF9500), // iOS橙色（表示设置）
                foregroundColor: Colors.white,
                label: widget.note.reminderTime != null
                    ? (AppLocalizationsSimple.of(context)?.cancelReminder ??
                        '取消提醒')
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
                onLongPress: _copyNoteContent,
                onDoubleTap: () {
                  // 🎯 双击：直接编辑笔记
                  widget.onEdit();
                },
                behavior: HitTestBehavior.translucent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: cardRadius,
                    boxShadow: cardShadow,
                    border: Border.all(
                      color: borderColor,
                      width: widget.isPinned ? 1 : 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: cardRadius,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                builder: (btnContext) => SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    tooltip: '更多',
                                    icon: Icon(
                                      Icons.more_horiz,
                                      color: isDarkMode
                                          ? AppTheme.darkTextSecondaryColor
                                          : AppTheme.textTertiaryColor,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () =>
                                        _showMoreOptions(btnContext),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: _buildContent(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: _buildReferences()),
                              _buildAnnotationBadge(),
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
        ), // 🔥 Slidable 结束
      ), // 🔥 ClipRRect 结束
    );
  }

  // 构建引用和被引用的小图标
  Widget _buildReferences() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final referenceColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    final currentNote = widget.note;

    // 如果没有引用关系，返回空Widget
    if (currentNote.relations.isEmpty) {
      return const SizedBox.shrink();
    }

    // 分析引用关系
    final outgoingRefs = <Map<String, dynamic>>[]; // 当前笔记引用的其他笔记（↗）
    final incomingRefs = <Map<String, dynamic>>[]; // 其他笔记引用当前笔记（↖）

    final currentId = widget.id;

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
      constraints: const BoxConstraints(), // 防止溢出
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
                      Icons.north_east, // 右斜上方箭头
                      size: 12,
                      color: referenceColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${outgoingRefs.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: referenceColor,
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
                      Icons.north_west, // 左斜上方箭头
                      size: 12,
                      color: referenceColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${incomingRefs.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: referenceColor,
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
    final currentNote = widget.note;

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
    var selectedType = AnnotationType.comment;

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
                    hintText:
                        localizations?.annotationPlaceholder ?? '在这里写下你的批注...',
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
    SnackBarUtils.showSuccess(
      context,
      localizations?.annotationAdded ?? '批注已添加',
    );
  }

  // 编辑批注对话框
  void _showEditAnnotationDialog(Note note, Annotation annotation) {
    final localizations = AppLocalizationsSimple.of(context);
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
                    hintText:
                        localizations?.annotationEditPlaceholder ?? '修改批注内容...',
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
  void _updateAnnotation(
    Note note,
    String annotationId,
    String newContent,
    AnnotationType newType,
  ) {
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
    SnackBarUtils.showSuccess(
      context,
      localizations?.annotationUpdated ?? '批注已更新',
    );
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
                localizations?.annotationDeleted ?? '批注已删除',
              );
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
    SnackBarUtils.showSuccess(
      context,
      localizations?.markedAsResolved ?? '已标记为已解决',
    );
  }

  // 📝 显示引用关系侧边栏
  void _showReferencesSheet(Note note) {
    NoteActionsService.showReferences(
      context: context,
      note: note,
    );
  }
}
