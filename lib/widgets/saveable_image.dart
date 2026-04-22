import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';

/// 可长按保存的图片组件
/// 
/// 用法：
/// ```dart
/// SaveableImage(
///   imageUrl: 'https://example.com/image.jpg',
///   headers: {'Authorization': 'Bearer token'},
///   child: CachedNetworkImage(imageUrl: '...'),
/// )
/// ```
class SaveableImage extends StatelessWidget {
  const SaveableImage({
    required this.imageUrl,
    required this.child,
    super.key,
    this.headers,
  });

  final String imageUrl;
  final Widget child;
  final Map<String, String>? headers;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPress: () {
          _showImageSaveDialog(context);
        },
        child: child,
      );

  // 显示图片保存对话框
  void _showImageSaveDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
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
                    await _saveImage(context);
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
  Future<void> _saveImage(BuildContext context) async {
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

      if (kDebugMode) {
        debugPrint('📷 保存结果: $result');
      }

      // 判断保存是否成功
      final success = result is Map
          ? (result['isSuccess'] == true || result['filePath'] != null)
          : result != null;

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已保存到相册'),
              backgroundColor: Colors.green,
            ),
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
          SnackBar(
            content: Text('保存图片失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


