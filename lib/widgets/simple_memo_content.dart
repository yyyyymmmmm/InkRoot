// 简单的Memo内容渲染 - 基于flutter_markdown
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/memos_markdown_converter.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:inkroot/widgets/animated_checkbox.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:permission_handler/permission_handler.dart';
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
  });
  final String content;
  final String? serverUrl;
  final Function(String)? onTagTap;
  final Function(String)? onLinkTap;
  final bool selectable;
  final int? maxLines;
  final Note? note; // 🎯 可选的note对象
  final Function(int todoIndex)? onCheckboxTap; // 🎯 复选框点击回调，传递待办事项索引

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
    if (content.length <= maxChars) return content;
    
    // 优先按换行截断
    final lines = content.split('\n');
    if (lines.length > maxLines) {
      final preview = lines.take(maxLines + 2).join('\n');
      return preview.length <= maxChars ? preview : preview.substring(0, maxChars);
    }
    return content.substring(0, maxChars);
  }

  // 🎯 预处理引用：将 [[referenceStr]] 转换为可读的链接格式（Memos 标准）
  String _preprocessReferencesWithContext(String content, List<Note> notes) {
    final referenceRegex = RegExp(r'\[\[([^\]]+)\]\]');
    return content.replaceAllMapped(referenceRegex, (match) {
      final referenceStr = match.group(1)!;

      // 解析引用格式（支持 id, memos/id, id?text=xxx）
      final parsed = _parseReference(referenceStr);
      final noteId = parsed['id']!;
      final customText = parsed['text'];

      // 根据ID提取显示文本
      final displayText =
          customText ?? _extractDisplayTextFromId(noteId, notes);

      // 转换为特殊的Markdown链接格式，用 ref: 前缀标识
      return '[$displayText](ref:$noteId)';
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
      customText = parts.length > 1 ? Uri.decodeComponent(parts[1]) : null;
    }

    // 移除 memos/ 前缀（如果有）
    if (cleanRef.startsWith('memos/')) {
      cleanRef = cleanRef.substring(6);
    }

    return {'id': cleanRef, 'text': customText};
  }

  // 🎯 根据笔记ID提取显示文本（标题或第一行）
  String _extractDisplayTextFromId(String noteId, List<Note> notes) {
    // 查找笔记
    final note = notes.firstWhere(
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

  // 处理引用点击
  void _handleReferenceTap(BuildContext context, String referenceContent) {
    // 这里的引用点击由 CustomLinkBuilder 处理
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 🎯 每次构建时重置复选框计数器
    _checkboxCounter = 0;

    // 收起状态下截断内容再解析，避免对超长笔记做全量 Markdown 渲染
    final rawContent = widget.maxLines != null
        ? _truncateForPreview(widget.content, widget.maxLines!)
        : widget.content;

    // 🎯 预处理：将 [[noteId]] 转换为可读的链接格式
    final processedContent =
        _preprocessReferencesWithContext(rawContent, appProvider.notes);

    final converter = MemosMarkdownConverter(serverUrl: widget.serverUrl);
    final convertedContent = converter.convert(processedContent);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 🎯 大厂标准：如果设置了maxLines，用Container限制高度
        final markdownBody = MarkdownBody(
          data: convertedContent,
          selectable: widget.selectable,
          softLineBreak: true, // 单个换行也生效（符合笔记应用习惯）
          extensionSet: md.ExtensionSet.gitHubFlavored, // 🎯 启用GitHub风格Markdown（支持待办事项）
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
                              'SimpleMemoContent: 复选框 #$currentIndex 被点击 $value -> $newValue');
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
            'a': CustomLinkBuilder(
              isDarkMode: isDarkMode,
              onTagTap: widget.onTagTap,
              onLinkTap: widget.onLinkTap,
              onReferenceTap: _handleReferenceTap,
            ),
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
                widget.onTagTap?.call(href.substring(1));
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
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
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
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                  width: 3,
                ),
              ),
            ),
            // 🎯 大厂标准标题字体大小（参考 Notion/Apple Notes）
            h1: AppTextStyles.headlineMedium(
              context,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ).copyWith(fontSize: ResponsiveUtils.responsiveFontSize(context, 26)),
            h2: AppTextStyles.headlineSmall(
              context,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ).copyWith(fontSize: ResponsiveUtils.responsiveFontSize(context, 22)),
            h3: AppTextStyles.titleLarge(
              context,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ).copyWith(fontSize: ResponsiveUtils.responsiveFontSize(context, 19)),
            a: TextStyle(
              color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
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
              decorationThickness: 2.0,
              leadingDistribution: TextLeadingDistribution.even, // 确保垂直居中
            ),
            // 🎯 复选框列表项样式（与正文相同大小，确保垂直对齐）
            checkbox: AppTextStyles.bodyLarge(
              context,
              height: 1.6,
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
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
          final heightAdjustment = 6; // 增加余量，避免半行文字露出

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
                          Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCardColor.withOpacity(0.0)
                              : Colors.white.withOpacity(0.0),
                          Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCardColor
                              : Colors.white,
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

    if (kDebugMode) debugPrint('🖼️ SimpleMemoContent 图片: $imagePath');

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 处理HTTP/HTTPS图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onLongPress: () {
            // 长按保存图片
            _showImageSaveDialog(context, imagePath, headers: null);
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
    if (imagePath.startsWith('/o/r/') ||
        imagePath.startsWith('/file/') ||
        imagePath.startsWith('/resource/')) {
      String fullUrl;
      if (appProvider.resourceService != null) {
        fullUrl = appProvider.resourceService!.buildImageUrl(imagePath);
      } else {
        final baseUrl = widget.serverUrl ?? appProvider.appConfig.memosApiUrl ?? '';
        fullUrl = baseUrl.isNotEmpty ? '$baseUrl$imagePath' : imagePath;
      }

      final token = appProvider.user?.token;
      if (kDebugMode) {
        debugPrint(
          '🖼️ Memos图片: $imagePath -> $fullUrl, token=${token != null}',
        );
      }

      final headers =
          token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
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
                if (kDebugMode) debugPrint('🖼️ 图片加载错误: $error');
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
          onLongPress: () {
            // 长按保存图片（本地文件）
            _showImageSaveDialog(context, imagePath, headers: null);
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
              onLongPress: () {
                _showImageSaveDialog(context, 'file://$fullPath', headers: null);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(fullPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      debugPrint('❌ 相对路径图片加载失败: $error for $imagePath -> $fullPath');
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
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;

        return Material(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖动条
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 保存按钮
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.blue),
                  title: Text(
                    '保存图片到相册',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _saveImage(context, imageUrl, headers: headers);
                  },
                ),
                const Divider(height: 1),
                // 取消按钮
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: Text(
                    '取消',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // 保存图片
  Future<void> _saveImage(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) async {
    // 使用 ImageUtils 的保存功能
    // 动态导入以避免循环依赖
    final imageUtils = await Future.microtask(() {
      // 延迟导入
      return null;
    });

    // 直接实现保存逻辑
    try {
      // 检查存储权限
      if (Platform.isAndroid || Platform.isIOS) {
        Permission permission;

        if (Platform.isAndroid) {
          // Android 13+ 不需要存储权限，使用 photos 权限
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            permission = Permission.photos;
          } else {
            permission = Permission.storage;
          }
        } else {
          // iOS 使用 photos 权限
          permission = Permission.photos;
        }

        final status = await permission.request();
        if (!status.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要存储权限才能保存图片')),
            );
          }
          return;
        }
      }

      // 显示加载提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在保存图片...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 下载图片数据
      Uint8List? imageBytes;

      // 先尝试从缓存获取
      final cachedFile = await ImageCacheManager.authImageCache
          .getFileFromCache(imageUrl)
          .then((info) => info?.file);

      if (cachedFile != null && await cachedFile.exists()) {
        imageBytes = await cachedFile.readAsBytes();
        if (kDebugMode) {
          debugPrint('📷 从缓存加载图片: ${cachedFile.path}');
        }
      } else {
        // 从网络下载
        if (kDebugMode) {
          debugPrint('📷 从网络下载图片: $imageUrl');
        }
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: headers,
        );

        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        } else {
          throw Exception('下载图片失败: ${response.statusCode}');
        }
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        throw Exception('图片数据为空');
      }

      // 保存到相册
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name: 'inkroot_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 判断保存是否成功
      final success = result is Map
          ? (result['isSuccess'] == true || result['filePath'] != null)
          : result != null;

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片已保存到相册')),
          );
        }
      } else {
        throw Exception('保存失败');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 保存图片失败: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存图片失败: ${e.toString()}')),
        );
      }
    }
  }
}

// 自定义链接构建器 - 区分标签、引用和普通链接
class CustomLinkBuilder extends MarkdownElementBuilder {
  CustomLinkBuilder({
    required this.isDarkMode,
    this.onTagTap,
    this.onLinkTap,
    this.onReferenceTap,
  });
  final bool isDarkMode;
  final Function(String)? onTagTap;
  final Function(String)? onLinkTap;
  final Function(BuildContext, String)? onReferenceTap;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final href = element.attributes['href'];
    final text = element.textContent;

    // 判断类型
    final isTag = href != null &&
        href.isNotEmpty &&
        href.startsWith('#') &&
        text.startsWith('#');
    final isReference = href != null && href.startsWith('ref:');

    return Builder(
      builder: (BuildContext builderContext) => GestureDetector(
        onTap: () {
          if (href != null && href.isNotEmpty) {
            if (isTag && href.length > 1) {
              onTagTap?.call(href.substring(1));
            } else if (isReference) {
              final refContent = href.substring(4); // 移除 'ref:' 前缀
              _handleReferenceNavigation(builderContext, refContent);
            } else if (!isTag) {
              onLinkTap?.call(href);
            }
          }
        },
        child: Transform.translate(
          offset: const Offset(0, -1), // 微调垂直位置，使其与文字基线对齐
          child: Container(
            padding: (isTag || isReference)
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
                : EdgeInsets.zero,
            decoration: (isTag || isReference)
                ? BoxDecoration(
                    color: isReference
                        ? (isDarkMode
                            ? Colors.blue[300]!.withOpacity(0.15)
                            : Colors.blue[700]!.withOpacity(0.1))
                        : (isDarkMode
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : AppTheme.primaryColor.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(4),
                    border: isReference
                        ? Border.all(
                            color: (isDarkMode
                                    ? Colors.blue[300]!
                                    : Colors.blue[700]!)
                                .withOpacity(0.3),
                          )
                        : null,
                  )
                : null,
            child: Text(
              text,
              style: TextStyle(
                color: isReference
                    ? (isDarkMode ? Colors.blue[400] : Colors.blue[600])
                    : (isTag
                        ? (isDarkMode
                            ? AppTheme.primaryColor.withOpacity(0.9)
                            : AppTheme.primaryColor)
                        : (isDarkMode
                            ? Colors.blue[300]
                            : Colors.blue[700])),
                decoration: TextDecoration.none,
                fontWeight: (isTag || isReference) ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
                height: 1.0, // 设置行高为1.0，确保与正文对齐
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  // 处理引用导航（直接使用ID跳转）
  void _handleReferenceNavigation(BuildContext context, String noteId) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('引用的笔记不存在或已被删除 (ID: $noteId)'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 直接用ID跳转到笔记详情
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => NoteDetailScreen(noteId: noteId),
      ),
    );
  }
}
