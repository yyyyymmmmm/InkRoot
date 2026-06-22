import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/memos_resource_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/memos_markdown_converter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// 🎨 分享模板枚举
enum ShareTemplateStyle {
  simple, // 简约风格（默认）
  card, // 卡片风格（小红书风格）
  gradient, // 渐变背景风格（Instagram风格）
  minimal, // 极简风格（Notion风格）
  magazine, // 杂志风格（Medium风格）
}

/// 分享图片 Widget - 用于生成分享图
/// 🔥 完全按照详情页的方式渲染，手动处理标签！
class ShareImageWidget extends StatelessWidget {
  // 🎨 自定义字体大小

  const ShareImageWidget({
    required this.content,
    required this.timestamp,
    super.key,
    this.username,
    this.isDarkMode = false,
    this.baseUrl,
    this.template = ShareTemplateStyle.simple,
    this.fontSize = 20.0, // 🎨 默认字体大小调整为 20
  });
  final String content;
  final DateTime timestamp;
  final String? username;
  final bool isDarkMode;
  final String? baseUrl;
  final ShareTemplateStyle template;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // 根据模板类型渲染不同风格
    switch (template) {
      case ShareTemplateStyle.card:
        return _buildCardStyle();
      case ShareTemplateStyle.gradient:
        return _buildGradientStyle();
      case ShareTemplateStyle.minimal:
        return _buildMinimalStyle();
      case ShareTemplateStyle.magazine:
        return _buildMagazineStyle();
      case ShareTemplateStyle.simple:
        return _buildSimpleStyle();
    }
  }

  /// 🎨 简约风格（默认）
  Widget _buildSimpleStyle() {
    final bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF666666);

    return Container(
      width: 600,
      constraints: const BoxConstraints(minHeight: 400), // 🔧 设置最小高度，但允许扩展
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔧 自适应内容高度
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(secondaryTextColor),
          const SizedBox(height: 24),
          // 🔥 使用 CustomizableMemoContent 支持字体大小调整
          CustomizableMemoContent(
            content: content,
            serverUrl: baseUrl,
            fontSize: fontSize, // 🎨 自定义字体大小
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 32),
          _buildFooter(secondaryTextColor),
        ],
      ),
    );
  }

  /// 🎨 卡片风格（小红书风格）
  Widget _buildCardStyle() {
    const secondaryTextColor = Color(0xFF666666);

    return Container(
      width: 600,
      constraints: const BoxConstraints(minHeight: 400), // 🔧 设置最小高度
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8F0),
            Color(0xFFFFF0F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔧 自适应内容高度
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(secondaryTextColor),
            const SizedBox(height: 20),
            CustomizableMemoContent(
              content: content,
              serverUrl: baseUrl,
              fontSize: fontSize, // 🎨 自定义字体大小
            ),
            const SizedBox(height: 24),
            _buildFooter(secondaryTextColor),
          ],
        ),
      ),
    );
  }

  /// 🎨 渐变背景风格（Instagram风格）
  Widget _buildGradientStyle() => Container(
        width: 600,
        constraints: const BoxConstraints(minHeight: 400), // 🔧 设置最小高度
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.8),
              AppTheme.primaryColor.withValues(alpha: 0.5),
              Colors.purple.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔧 自适应内容高度
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 24),
            CustomizableMemoContent(
              content: content,
              serverUrl: baseUrl,
              fontSize: fontSize, // 🎨 自定义字体大小
              isDarkMode: true, // 渐变风格使用深色文字
            ),
            const SizedBox(height: 32),
            _buildFooter(Colors.white.withValues(alpha: 0.8)),
          ],
        ),
      );

  /// 🎨 极简风格（Notion风格）
  Widget _buildMinimalStyle() {
    const bgColor = Color(0xFFFAFAFA);
    const borderColor = Color(0xFFE5E5E5);

    return Container(
      width: 600,
      constraints: const BoxConstraints(minHeight: 400), // 🔧 设置最小高度
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔧 自适应内容高度
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomizableMemoContent(
            content: content,
            serverUrl: baseUrl,
            fontSize: fontSize, // 🎨 自定义字体大小
          ),
          const SizedBox(height: 32),
          const Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                username?.isNotEmpty ?? false ? username! : AppConfig.appName,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                DateFormat('yyyy/MM/dd').format(timestamp),
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 杂志风格（Medium风格）
  Widget _buildMagazineStyle() => Container(
        width: 600,
        constraints: const BoxConstraints(minHeight: 400), // 🔧 设置最小高度
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🔧 自适应内容高度
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 大标题样式
            Container(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppTheme.primaryColor, width: 4),
                ),
              ),
              child: const Text(
                AppConfig.appName,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomizableMemoContent(
              content: content,
              serverUrl: baseUrl,
              fontSize: fontSize, // 🎨 自定义字体大小
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    username?.isNotEmpty ?? false ? username! : '匿名',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy年MM月dd日').format(timestamp),
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildHeader(Color secondaryTextColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            username?.isNotEmpty ?? false ? username! : AppConfig.appName,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            DateFormat('yyyy/MM/dd HH:mm').format(timestamp),
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );

  // 🔥 已删除旧的 _buildContent 方法，现在直接使用 SimpleMemoContent

  Widget _buildFooter(Color secondaryTextColor) => Align(
        alignment: Alignment.centerRight,
        child: Text(
          AppConfig.appName,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      );
}

/// 🎨 自定义字体大小的Memo内容组件（用于分享图片）
class CustomizableMemoContent extends StatelessWidget {
  const CustomizableMemoContent({
    required this.content,
    super.key,
    this.serverUrl,
    this.fontSize = 20.0,
    this.isDarkMode = false,
  });
  final String content;
  final String? serverUrl;
  final double fontSize;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final converter = MemosMarkdownConverter(serverUrl: serverUrl);
    final convertedContent = converter.convert(content);

    return MarkdownBody(
      data: convertedContent,
      softLineBreak: true,
      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isDarkMode ? Colors.grey[300] : Colors.black87,
          fontSize: fontSize, // 🎨 使用自定义字体大小
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
        code: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: fontSize - 1, // 代码字体稍小
          fontFamily: 'SF Mono',
          backgroundColor:
              isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          fontSize: fontSize,
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
        h1: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: fontSize + 3,
          fontWeight: FontWeight.bold,
          height: 1.34,
        ),
        h2: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: fontSize + 2,
          fontWeight: FontWeight.bold,
          height: 1.36,
        ),
        h3: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: fontSize + 1,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        a: TextStyle(
          color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
          fontSize: fontSize,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w500,
        ),
        listBullet: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          fontSize: fontSize,
        ),
        tableBody: TextStyle(
          color: isDarkMode ? Colors.grey[300] : Colors.black87,
          fontSize: fontSize,
        ),
      ),
      imageBuilder: (uri, title, alt) => _buildImage(context, uri),
    );
  }

  Widget _buildImage(BuildContext context, Uri uri) {
    final imagePath = uri.toString();

    // 🔥 不使用 Provider，直接使用传入的参数（解决 Overlay 上下文问题）
    if (kDebugMode) {
      debugPrint('🖼️ ShareImage: 处理图片路径: $imagePath');
    }

    // 处理HTTP/HTTPS图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      if (kDebugMode) {
        debugPrint('🌐 ShareImage: HTTP/HTTPS 图片 $imagePath');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imagePath,
            cacheManager: ImageCacheManager.authImageCache,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              height: 200,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[600], size: 48),
                  const SizedBox(height: 8),
                  Text(
                    '图片加载失败',
                    style: TextStyle(
                      fontSize: fontSize - 3,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 处理Memos服务器资源路径
    if (MemosResourceService.isServerResourcePath(imagePath)) {
      // 🔥 直接使用传入的 baseUrl 和 token（不依赖 Provider）
      final baseUrl = serverUrl ?? '';
      final fullUrl = baseUrl.isNotEmpty
          ? MemosResourceService(baseUrl: baseUrl).buildImageUrl(imagePath)
          : imagePath;

      if (kDebugMode) {
        debugPrint('📦 ShareImage: Memos 资源图片 $imagePath -> $fullUrl');
      }

      // 🔥 从外部获取 token（通过 context 查找，但要安全处理）
      String? token;
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        token = appProvider.user?.token;
        if (kDebugMode) {
          debugPrint('🔑 ShareImage: 获取到 token: ${token != null}');
        }
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ ShareImage: 无法获取 AppProvider，可能在 Overlay 中: $e');
        }
        // 在 Overlay 中无法访问 Provider，但图片可能已经缓存
        token = null;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: fullUrl,
            cacheManager: ImageCacheManager.authImageCache,
            httpHeaders:
                token != null ? {'Authorization': 'Bearer $token'} : {},
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) {
              if (kDebugMode) {
                debugPrint('🖼️ ShareImage: 正在加载图片 $url');
              }
              return Container(
                height: 200,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            imageBuilder: (context, imageProvider) {
              if (kDebugMode) {
                debugPrint('✅ ShareImage: 图片加载成功 $fullUrl');
              }
              return Image(image: imageProvider, fit: BoxFit.contain);
            },
            errorWidget: (context, url, error) {
              if (kDebugMode) {
                debugPrint('❌ ShareImage: 图片加载失败 $url - 错误: $error');
              }
              return Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey[600], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      '图片加载失败',
                      style: TextStyle(
                        fontSize: fontSize - 3,
                        color: Colors.grey[600],
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

    // 处理本地文件
    if (imagePath.startsWith('file://')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imagePath.replaceFirst('file://', '')),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return const SizedBox();
  }
}
