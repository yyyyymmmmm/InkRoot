import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;
import 'package:intl/intl.dart';

/// ShareTemplateSimple - Simple 分享模板
///
/// 提供简约风格的分享图片生成功能
/// - flomo 风格的简洁设计
/// - 支持富文本 Markdown 渲染
/// - 支持多图垂直布局
/// - 支持深色/浅色主题适配
class ShareTemplateSimple {
  /// 主题感知颜色配置类
  /// 解决白天模式下文字和背景都是白色的问题
  static ShareThemeColors _getThemeColors({ShareThemeColors? themeColors}) {
    return themeColors ?? ShareThemeColors(isDarkMode: false);
  }

  /// 绘制 Simple 模板主函数
  ///
  /// 参数说明：
  /// - [canvas] - 画布对象
  /// - [size] - 画布尺寸
  /// - [content] - 笔记内容（支持 Markdown）
  /// - [timestamp] - 时间戳
  /// - [imagePaths] - 图片路径列表（可选）
  /// - [baseUrl] - Memos 服务器基础 URL（可选）
  /// - [token] - 认证 Token（可选）
  /// - [username] - 用户名（可选）
  /// - [showTime] - 是否显示时间
  /// - [showUser] - 是否显示用户名
  /// - [showBrand] - 是否显示品牌信息
  /// - [themeColors] - 主题颜色配置（可选）
  static Future<void> drawSimpleTemplate(
    Canvas canvas,
    Size size,
    String content,
    DateTime timestamp,
    List<String>? imagePaths,
    String? baseUrl,
    String? token, {
    String? username,
    bool showTime = true,
    bool showUser = true,
    bool showBrand = true,
    ShareThemeColors? themeColors,
  }) async {
    // 主题感知背景 - flomo风格
    final colors = _getThemeColors(themeColors: themeColors);
    final backgroundPaint = Paint()..color = colors.backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // 使用flomo风格统一布局
    await _drawFlomoStyleLayout(
      canvas,
      size,
      content,
      timestamp,
      imagePaths,
      baseUrl,
      token,
      username: username,
      showTime: showTime,
      showUser: showUser,
      showBrand: showBrand,
      themeColors: colors,
    );
  }

  /// 绘制 flomo 风格布局
  static Future<void> _drawFlomoStyleLayout(
    Canvas canvas,
    Size size,
    String content,
    DateTime timestamp,
    List<String>? imagePaths,
    String? baseUrl,
    String? token, {
    String? username,
    bool showTime = true,
    bool showUser = true,
    bool showBrand = true,
    ShareThemeColors? themeColors,
  }) async {
    const margin = 32.0; // 增加边距，更有呼吸感
    final contentWidth = size.width - margin * 2;

    var currentY = margin + 20; // 顶部留白

    final colors = _getThemeColors(themeColors: themeColors);

    // 1. 顶部用户名和时间 - 轻量化显示
    await _drawFlomoDate(
      canvas,
      timestamp,
      margin,
      contentWidth,
      currentY,
      username: username,
      showTime: showTime,
      showUser: showUser,
      themeColors: colors,
    );
    currentY += 40;

    // 2. 主要内容区域 - 统一的卡片容器
    final contentHeight = await _calculateFlomoContentHeight(
      content,
      imagePaths,
      contentWidth,
      baseUrl: baseUrl,
      token: token,
    );
    final contentRect =
        Rect.fromLTWH(margin, currentY, contentWidth, contentHeight);

    // 绘制统一的内容卡片
    await _drawFlomoContentCard(
      canvas,
      contentRect,
      content,
      imagePaths,
      baseUrl,
      token,
      themeColors: colors,
    );
    currentY += contentHeight + 32;

    // 3. 底部品牌信息 - 融入整体
    await _drawFlomoBrand(
      canvas,
      size,
      margin,
      contentWidth,
      currentY,
      showBrand: showBrand,
      themeColors: colors,
    );
  }

  /// 绘制 flomo 风格头部信息（用户名和时间）
  static Future<void> _drawFlomoDate(
    Canvas canvas,
    DateTime timestamp,
    double margin,
    double width,
    double y, {
    String? username,
    bool showTime = true,
    bool showUser = true,
    ShareThemeColors? themeColors,
  }) async {
    if (!showTime && !showUser) return;

    final colors = _getThemeColors(themeColors: themeColors);
    final textStyle = ui.TextStyle(
      color: colors.timestampTextColor,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    // 左上角用户名
    if (showUser) {
      final displayName =
          username?.isNotEmpty ?? false ? username! : AppConfig.appName;
      final userParagraph =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.left))
            ..pushStyle(textStyle)
            ..addText(displayName);
      final userText = userParagraph.build()
        ..layout(ui.ParagraphConstraints(width: width * 0.5));

      canvas.drawParagraph(userText, Offset(margin, y));
    }

    // 右上角时间
    if (showTime) {
      final time = DateFormat('yyyy/MM/dd HH:mm').format(timestamp);
      final timeParagraph =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
            ..pushStyle(textStyle)
            ..addText(time);
      final timeText = timeParagraph.build()
        ..layout(ui.ParagraphConstraints(width: width * 0.5));

      canvas.drawParagraph(timeText, Offset(margin + width * 0.5, y));
    }
  }

  /// 计算 flomo 内容高度（优化版 - 并发加载图片）
  static Future<double> _calculateFlomoContentHeight(
    String content,
    List<String>? imagePaths,
    double width, {
    String? baseUrl,
    String? token,
  }) async {
    double height = 40; // 顶部内边距

    // 文本高度计算
    final processedContent = _processContentForDisplay(content);
    if (processedContent.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: processedContent,
          style: const TextStyle(
            fontSize: 17,
            height: 1.5,
            color: Color(0xFF333333),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 64); // 减去内边距
      height += textPainter.height + 24; // 文本 + 间距
    }

    // 垂直排列多图片高度计算 - 使用并发加载
    if (imagePaths != null && imagePaths.isNotEmpty) {
      final imageWidth = width - 64; // 减去内边距
      const gap = 12.0;

      // 并发加载所有图片
      final images = await _loadImagesParallel(imagePaths, baseUrl, token);

      // 计算所有图片的总高度
      for (var i = 0; i < images.length; i++) {
        if (i > 0) {
          height += gap; // 图片间隙
        }

        final image = images[i];
        if (image != null) {
          final imageHeight =
              (image.height.toDouble() / image.width.toDouble()) * imageWidth;
          height += imageHeight;
        } else {
          height += imageWidth * 0.6; // 默认比例
        }
      }

      height += 24; // 底部间距
    }

    height += 40; // 底部内边距
    return height;
  }

  /// 绘制 flomo 风格内容卡片
  static Future<void> _drawFlomoContentCard(
    Canvas canvas,
    Rect cardRect,
    String content,
    List<String>? imagePaths,
    String? baseUrl,
    String? token, {
    bool isGlassStyle = false,
    ShareThemeColors? themeColors,
  }) async {
    final colors = _getThemeColors(themeColors: themeColors);

    // 定义边框画笔，供图片绘制使用
    final borderPaint = Paint()
      ..color =
          colors.isDarkMode ? const Color(0xFF444444) : const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 只在非毛玻璃模式下绘制背景
    if (!isGlassStyle) {
      // 统一的卡片背景 - 极简设计
      final cardPaint = Paint()
        ..color = colors.cardBackgroundColor
        ..style = PaintingStyle.fill;

      final cardRRect =
          RRect.fromRectAndRadius(cardRect, const Radius.circular(16));

      // 绘制卡片
      canvas.drawRRect(cardRRect, cardPaint);
      canvas.drawRRect(cardRRect, borderPaint);
    }

    // 内容区域
    const padding = 32.0;
    var currentY = cardRect.top + padding;
    final contentWidth = cardRect.width - padding * 2;

    // 绘制富文本内容
    final processedContent = _processContentForDisplay(content);
    if (processedContent.isNotEmpty) {
      await _drawRichText(
        canvas,
        processedContent,
        cardRect.left + padding,
        currentY,
        contentWidth,
        isGlassStyle: isGlassStyle,
      );

      // 计算文本高度以更新currentY
      final textPainter = TextPainter(
        text: TextSpan(
          text: processedContent,
          style: const TextStyle(fontSize: 17, height: 1.5),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout(maxWidth: contentWidth);
      currentY += textPainter.height + 24;
    }

    // 绘制多张图片 - 网格布局
    if (imagePaths != null && imagePaths.isNotEmpty) {
      await _drawMultipleImages(
        canvas,
        cardRect.left + padding,
        currentY,
        contentWidth,
        imagePaths,
        baseUrl,
        token,
        borderPaint,
      );
    }
  }

  /// 绘制 flomo 风格品牌信息
  static Future<void> _drawFlomoBrand(
    Canvas canvas,
    Size size,
    double margin,
    double width,
    double y, {
    bool showBrand = true,
    ShareThemeColors? themeColors,
  }) async {
    if (!showBrand) return; // 如果隐藏品牌，直接返回

    final colors = _getThemeColors(themeColors: themeColors);

    // 品牌标识 - 右下角显示InkRoot
    final brandStyle = ui.TextStyle(
      color: colors.secondaryTextColor,
      fontSize: 12,
      fontWeight: FontWeight.w300,
    );

    final brandParagraph =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
          ..pushStyle(brandStyle)
          ..addText(AppConfig.appName);
    final brandText = brandParagraph.build()
      ..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(brandText, Offset(margin, y));
  }

  // ==================== 图片加载与缓存 ====================

  /// 简单的图片缓存（避免重复加载）
  static final Map<String, ui.Image> _imageCache = <String, ui.Image>{};
  static int _cacheSize = 0;
  static const int _maxCacheSize = 20; // 最多缓存20张图片

  /// 并发加载多张图片（性能优化）
  static Future<List<ui.Image?>> _loadImagesParallel(
    List<String> imagePaths,
    String? baseUrl,
    String? token,
  ) async {
    if (imagePaths.isEmpty) return [];

    // 创建并发任务
    final futures = imagePaths.map((imagePath) async {
      // 检查缓存
      if (_imageCache.containsKey(imagePath)) {
        return _imageCache[imagePath];
      }

      // 加载图片
      final image = await _loadImage(imagePath, baseUrl, token);

      // 添加到缓存
      if (image != null) {
        _addToCache(imagePath, image);
      }

      return image;
    });

    // 等待所有图片加载完成
    return Future.wait(futures);
  }

  /// 添加图片到缓存
  static void _addToCache(String key, ui.Image image) {
    if (_cacheSize >= _maxCacheSize) {
      // 简单的缓存清理：移除前5个
      final keys = _imageCache.keys.take(5).toList();
      for (final k in keys) {
        _imageCache.remove(k);
      }
      _cacheSize -= 5;
    }

    _imageCache[key] = image;
    _cacheSize++;
  }

  /// 清理图片缓存 - 可在内存紧张时调用
  static void clearImageCache() {
    _imageCache.clear();
    _cacheSize = 0;
    if (kDebugMode) debugPrint('ShareTemplateSimple: 图片缓存已清理');
  }

  /// 获取当前缓存状态 - 用于调试
  static Map<String, dynamic> getCacheInfo() => {
        'cacheSize': _cacheSize,
        'maxCacheSize': _maxCacheSize,
        'cachedImages': _imageCache.keys.length,
      };

  /// 加载单张图片
  static Future<ui.Image?> _loadImage(
    String imagePath,
    String? baseUrl,
    String? token,
  ) async {
    try {
      if (imagePath.startsWith('file://')) {
        // 本地文件
        final filePath = imagePath.replaceFirst('file://', '');
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return await decodeImageFromList(bytes);
        }
      } else if (imagePath.startsWith('http://') ||
          imagePath.startsWith('https://')) {
        // 网络图片
        final headers = <String, String>{};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        final response = await http.get(Uri.parse(imagePath), headers: headers);
        if (response.statusCode == 200) {
          return await decodeImageFromList(response.bodyBytes);
        }
      } else if ((imagePath.startsWith('/o/r/') ||
              imagePath.startsWith('/file/') ||
              imagePath.startsWith('/resource/')) &&
          baseUrl != null) {
        // Memos服务器资源路径
        final fullUrl = '$baseUrl$imagePath';
        final headers = <String, String>{};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        final response = await http.get(Uri.parse(fullUrl), headers: headers);
        if (response.statusCode == 200) {
          return await decodeImageFromList(response.bodyBytes);
        }
      }
      // 其他情况暂时不处理，返回null
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading image: $e for path: $imagePath');
      }
      return null;
    }
  }

  // ==================== 图片绘制 ====================

  /// 绘制多张图片 - 垂直排列布局（优化版 - 使用预加载的图片）
  static Future<void> _drawMultipleImages(
    Canvas canvas,
    double x,
    double y,
    double maxWidth,
    List<String> imagePaths,
    String? baseUrl,
    String? token,
    Paint borderPaint,
  ) async {
    if (imagePaths.isEmpty) return;

    const gap = 12.0; // 图片间隙
    var currentY = y;

    // 预加载所有图片（并发加载，提升性能）
    final images = await _loadImagesParallel(imagePaths, baseUrl, token);

    // 垂直排列所有图片，宽度统一
    for (var i = 0; i < imagePaths.length; i++) {
      if (i > 0) {
        currentY += gap; // 添加间隙
      }

      final imageHeight = _drawPreloadedImageAndGetHeight(
        canvas,
        x,
        currentY,
        maxWidth,
        images[i],
        borderPaint,
      );

      currentY += imageHeight;
    }
  }

  /// 绘制预加载的图片并返回高度（性能优化版）
  static double _drawPreloadedImageAndGetHeight(
    Canvas canvas,
    double x,
    double y,
    double width,
    ui.Image? image,
    Paint borderPaint,
  ) {
    if (image != null) {
      final imageHeight =
          (image.height.toDouble() / image.width.toDouble()) * width;

      final srcRect =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dstRect = Rect.fromLTWH(x, y, width, imageHeight);
      final imageRRect =
          RRect.fromRectAndRadius(dstRect, const Radius.circular(12));

      // 绘制图片
      canvas.saveLayer(dstRect, Paint());
      canvas.drawRRect(imageRRect, Paint()..color = Colors.white);
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint()..blendMode = BlendMode.srcIn,
      );
      canvas.restore();

      // 边框
      canvas.drawRRect(
        imageRRect,
        Paint()
          ..color = const Color(0xFFE8E8E8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      return imageHeight;
    }

    // 占位符
    final placeholderHeight = width * 0.6;
    final placeholderRect = Rect.fromLTWH(x, y, width, placeholderHeight);
    final placeholderRRect =
        RRect.fromRectAndRadius(placeholderRect, const Radius.circular(12));

    canvas.drawRRect(
      placeholderRRect,
      Paint()..color = const Color(0xFFF0F0F0),
    );
    canvas.drawRRect(placeholderRRect, borderPaint);

    return placeholderHeight;
  }

  // ==================== 内容处理 ====================

  /// 处理内容显示 - 保留原始Markdown格式，让富文本渲染器处理
  static String _processContentForDisplay(String content) {
    var processedContent = content;

    // 只移除图片语法，因为图片单独处理
    processedContent =
        processedContent.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');

    // 处理链接语法 [text](url) - 只保留文本
    processedContent =
        processedContent.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');

    // 清理多余的空行
    processedContent =
        processedContent.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

    return processedContent.trim();
  }

  /// 绘制富文本内容 - 重新设计的Markdown渲染器
  static Future<void> _drawRichText(
    Canvas canvas,
    String content,
    double x,
    double y,
    double maxWidth, {
    bool isGlassStyle = false,
  }) async {
    final spans = _parseMarkdownToSpans(content, isGlassStyle: isGlassStyle);

    final textPainter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    textPainter.paint(canvas, Offset(x, y));
  }

  /// 解析Markdown为TextSpan列表 - 使用位置索引方式（修复$1乱码问题）
  static List<TextSpan> _parseMarkdownToSpans(
    String content, {
    bool isGlassStyle = false,
  }) {
    if (kDebugMode) {
      debugPrint(
        'ShareTemplateSimple: 开始解析Markdown内容: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."',
      );
    }

    // 🔧 修复：使用位置索引方式，避免split()对捕获组的错误处理
    // 🎯 改进的标签识别规则（参考Obsidian/Notion/Logseq，排除URL中的#）
    final tagRegex = tag_utils.getTagRegex();
    final matches = tagRegex.allMatches(content).toList();

    final spans = <TextSpan>[];
    var lastIndex = 0;

    for (final match in matches) {
      // 添加标签前的普通文本
      if (match.start > lastIndex) {
        final plainText = content.substring(lastIndex, match.start);
        if (plainText.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              'ShareTemplateSimple: 解析普通文本: "${plainText.length > 20 ? plainText.substring(0, 20) : plainText}..."',
            );
          }
          spans.addAll(
            _parseMarkdownContent(plainText, isGlassStyle: isGlassStyle),
          );
        }
      }

      // 添加标签
      final tagText = '【${match.group(1)!}】';
      if (kDebugMode) {
        debugPrint('ShareTemplateSimple: 解析到标签: "$tagText"');
      }
      spans.add(_createTagTextSpan(tagText, isGlassStyle: isGlassStyle));

      lastIndex = match.end;
    }

    // 添加剩余的普通文本
    if (lastIndex < content.length) {
      final remainingText = content.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            'ShareTemplateSimple: 解析剩余文本: "${remainingText.length > 20 ? remainingText.substring(0, 20) : remainingText}..."',
          );
        }
        spans.addAll(
          _parseMarkdownContent(remainingText, isGlassStyle: isGlassStyle),
        );
      }
    }

    if (kDebugMode) {
      debugPrint(
        'ShareTemplateSimple: 解析完成，共生成 ${spans.length} 个span',
      );
    }
    return spans;
  }

  /// 完整的Markdown解析 - 支持标题、粗体、斜体、代码等
  static List<TextSpan> _parseMarkdownContent(
    String text, {
    bool isGlassStyle = false,
  }) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // 检查是否是标题
      if (line.startsWith('#')) {
        final titleMatch = RegExp(r'^(#{1,6})\s*(.+)').firstMatch(line);
        if (titleMatch != null) {
          final level = titleMatch.group(1)!.length;
          final titleText = titleMatch.group(2)!;
          debugPrint('ShareTemplateSimple: 解析到H$level标题: "$titleText"');

          // 标题内容也要进行行内Markdown解析（粗体、斜体等）
          final titleSpans = _parseInlineMarkdown(titleText);
          for (final span in titleSpans) {
            // 将标题中的span都转换为标题样式，但保留粗体、斜体等
            spans.add(_createTitleStyledSpan(span, level));
          }

          if (lineIndex < lines.length - 1) {
            spans.add(_createNormalTextSpan('\n'));
          }
          continue;
        }
      }

      // 处理行内格式：粗体、斜体、代码
      spans.addAll(_parseInlineMarkdown(line));

      // 如果不是最后一行，添加换行
      if (lineIndex < lines.length - 1) {
        spans.add(_createNormalTextSpan('\n'));
      }
    }

    return spans;
  }

  /// 解析行内Markdown格式
  static List<TextSpan> _parseInlineMarkdown(String text) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (char == '*' && i + 1 < text.length) {
        // 检查粗体 **text**
        if (text[i + 1] == '*') {
          final endIndex = _findMarkdownEnd(text, i + 2, '**');
          if (endIndex != -1) {
            if (buffer.isNotEmpty) {
              spans.add(_createNormalTextSpan(buffer.toString()));
              buffer.clear();
            }
            final boldText = text.substring(i + 2, endIndex);
            debugPrint('ShareTemplateSimple: 解析到粗体: "$boldText"');
            spans.add(_createBoldTextSpan(boldText));
            i = endIndex + 1;
            continue;
          }
        } else {
          // 检查斜体 *text*
          final endIndex = _findMarkdownEnd(text, i + 1, '*');
          if (endIndex != -1) {
            if (buffer.isNotEmpty) {
              spans.add(_createNormalTextSpan(buffer.toString()));
              buffer.clear();
            }
            final italicText = text.substring(i + 1, endIndex);
            debugPrint('ShareTemplateSimple: 解析到斜体: "$italicText"');
            spans.add(_createItalicTextSpan(italicText));
            i = endIndex;
            continue;
          }
        }
      } else if (char == '`') {
        // 检查代码 `code`
        final endIndex = _findMarkdownEnd(text, i + 1, '`');
        if (endIndex != -1) {
          if (buffer.isNotEmpty) {
            spans.add(_createNormalTextSpan(buffer.toString()));
            buffer.clear();
          }
          final codeText = text.substring(i + 1, endIndex);
          debugPrint('ShareTemplateSimple: 解析到代码: "$codeText"');
          spans.add(_createCodeTextSpan(codeText));
          i = endIndex;
          continue;
        }
      }

      // 普通字符
      buffer.write(char);
    }

    // 添加剩余的普通文本
    if (buffer.isNotEmpty) {
      spans.add(_createNormalTextSpan(buffer.toString()));
    }

    return spans;
  }

  /// 查找Markdown标记的结束位置
  static int _findMarkdownEnd(String content, int start, String endMark) {
    for (var i = start; i <= content.length - endMark.length; i++) {
      if (content.substring(i, i + endMark.length) == endMark) {
        return i;
      }
    }
    return -1;
  }

  // ==================== TextSpan 样式创建 ====================

  /// 创建普通文本样式
  static TextSpan _createNormalTextSpan(String text) => TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      );

  /// 创建粗体文本样式
  static TextSpan _createBoldTextSpan(String text) => TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      );

  /// 创建斜体文本样式
  static TextSpan _createItalicTextSpan(String text) => TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 17,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      );

  /// 创建标签文本样式
  static TextSpan _createTagTextSpan(
    String text, {
    bool isGlassStyle = false,
  }) =>
      TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF007AFF),
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      );

  /// 创建代码文本样式
  static TextSpan _createCodeTextSpan(String text) => TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Courier',
        ),
      );

  /// 创建标题文本样式
  static TextSpan _createTitleTextSpan(String text, [int level = 1]) {
    double fontSize;
    switch (level) {
      case 1:
        fontSize = 20.0;
        break;
      case 2:
        fontSize = 18.0;
        break;
      case 3:
        fontSize = 16.0;
        break;
      default:
        fontSize = 15.0;
        break;
    }

    return TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF333333),
        fontSize: fontSize,
        height: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 创建标题样式的span，但保留原有的粗体、斜体等样式
  static TextSpan _createTitleStyledSpan(TextSpan originalSpan, int level) {
    double fontSize;
    switch (level) {
      case 1:
        fontSize = 20.0;
        break;
      case 2:
        fontSize = 18.0;
        break;
      case 3:
        fontSize = 16.0;
        break;
      default:
        fontSize = 15.0;
        break;
    }

    // 保留原有样式，但应用标题字体大小
    final originalStyle = originalSpan.style ?? const TextStyle();

    return TextSpan(
      text: originalSpan.text,
      style: originalStyle.copyWith(
        fontSize: fontSize,
        height: 1.5,
        // 如果原来没有颜色，使用标题颜色
        color: originalStyle.color ?? const Color(0xFF333333),
        // 如果原来没有字重，使用标题字重
        fontWeight: originalStyle.fontWeight ?? FontWeight.bold,
      ),
    );
  }
}

/// 主题感知颜色配置类
/// 解决白天模式下文字和背景都是白色的问题
class ShareThemeColors {
  ShareThemeColors({required this.isDarkMode});
  final bool isDarkMode;

  /// 获取背景颜色
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  /// 获取卡片背景颜色
  Color get cardBackgroundColor =>
      isDarkMode ? const Color(0xFF2D2D2D) : Colors.white;

  /// 获取主要文字颜色
  Color get primaryTextColor =>
      isDarkMode ? Colors.white.withOpacity(0.9) : const Color(0xFF1A1A1A);

  /// 获取次要文字颜色
  Color get secondaryTextColor =>
      isDarkMode ? Colors.white.withOpacity(0.7) : const Color(0xFF666666);

  /// 获取毛玻璃效果颜色
  Color get glassEffectColor => isDarkMode
      ? Colors.black.withOpacity(0.15)
      : Colors.white.withOpacity(0.15);

  /// 获取毛玻璃边框颜色
  Color get glassBorderColor => isDarkMode
      ? Colors.white.withOpacity(0.1)
      : Colors.white.withOpacity(0.2);

  /// 获取阴影颜色
  Color get shadowColor => isDarkMode
      ? Colors.black.withOpacity(0.5)
      : Colors.black.withOpacity(0.15);

  /// 获取时间戳文字颜色
  Color get timestampTextColor =>
      isDarkMode ? Colors.white.withOpacity(0.6) : const Color(0xFF999999);

  /// 从BuildContext获取主题颜色
  static ShareThemeColors fromContext(BuildContext? context) {
    if (context == null) {
      // 默认使用亮色主题
      return ShareThemeColors(isDarkMode: false);
    }

    final brightness = Theme.of(context).brightness;
    return ShareThemeColors(isDarkMode: brightness == Brightness.dark);
  }

  /// 从主题模式字符串获取颜色配置
  static ShareThemeColors fromThemeMode(String? themeMode) {
    // 根据系统主题或用户设置判断
    final isDark = themeMode == 'dark' ||
        (themeMode == 'system' &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    return ShareThemeColors(isDarkMode: isDark);
  }
}
