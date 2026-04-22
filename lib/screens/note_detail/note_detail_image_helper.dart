// 图片处理模块（从 note_detail_screen.dart 拆分）
// 职责：处理笔记中的图片显示、缓存和预览

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/widgets/share_image_preview_screen.dart';

/// 图片处理助手类
///
/// 负责：
/// 1. 从笔记内容中提取图片
/// 2. 构建图片网格
/// 3. 图片缓存管理
/// 4. 图片预览
class NoteDetailImageHelper {
  /// 从笔记内容中提取 Markdown 格式的图片
  static List<String> extractMarkdownImages(String content) {
    final List<String> images = [];
    final regex = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      final url = match.group(1);
      if (url != null && url.isNotEmpty) {
        images.add(url);
      }
    }

    return images;
  }

  /// 从内容中移除图片标记
  static String removeImageMarkdown(String content) {
    return content.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '').trim();
  }

  /// 构建图片网格
  static Widget buildImageGrid(
    BuildContext context,
    List<String> imagePaths, {
    required bool isLoggedIn,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final spacing = 8.0;
        final size = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: imagePaths.map((path) => _buildImageItem(context, path, size, isLoggedIn)).toList(),
        );
      },
    );
  }

  /// 构建单个图片项
  static Widget _buildImageItem(
    BuildContext context,
    String imagePath,
    double size,
    bool isLoggedIn,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ShareImagePreviewScreen(
              imagePath: imagePath,
              isLoggedIn: isLoggedIn,
            ),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildImageWidget(context, imagePath, isLoggedIn),
      ),
    );
  }

  /// 构建图片组件（带缓存）
  static Widget _buildImageWidget(
    BuildContext context,
    String imagePath,
    bool isLoggedIn,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 判断是否为网络图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imagePath,
          cacheManager: ImageCacheManager.instance, // 90天长期缓存
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: isDarkMode ? Colors.white10 : Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // 离线模式或缓存加载失败
            if (!isLoggedIn) {
              return Container(
                color: isDarkMode ? Colors.white10 : Colors.black12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: isDarkMode ? Colors.white38 : Colors.black26,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '离线模式',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              color: isDarkMode ? Colors.white10 : Colors.black12,
              child: Icon(
                Icons.broken_image,
                color: isDarkMode ? Colors.white38 : Colors.black26,
                size: 32,
              ),
            );
          },
        ),
      );
    }

    // 本地图片（暂不支持）
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image,
        color: isDarkMode ? Colors.white38 : Colors.black26,
        size: 32,
      ),
    );
  }
}
