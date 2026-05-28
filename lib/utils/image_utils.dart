import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:inkroot/config/asset_config.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ImageUtils {
  // 默认缓存管理器
  static final fcm.DefaultCacheManager _cacheManager = fcm.DefaultCacheManager();

  // 加载网络图片（带缓存）
  static Widget loadNetworkImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) =>
      CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            errorWidget ?? const Icon(Icons.error),
        cacheManager: _cacheManager,
      );

  // 加载主题相关图片
  static Widget loadThemeImage(
    BuildContext context, {
    bool isDarkMode = false,
    bool useLocal = false,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final imageUrl =
        AssetConfig.getThemeImageUrl(isDarkMode, useLocal: useLocal);

    if (useLocal) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return loadNetworkImage(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
    );
  }

  // 清除图片缓存
  static Future<void> clearImageCache() async {
    await _cacheManager.emptyCache();
    // 清除Flutter默认图片缓存
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  // 预加载图片
  static Future<void> preloadImage(String url) async {
    await _cacheManager.downloadFile(url);
  }

  // 保存图片到相册
  static Future<bool> saveImageToGallery(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) async {
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
            SnackBarUtils.showError(context, '需要存储权限才能保存图片');
          }
          return false;
        }
      }

      // 显示加载提示
      if (context.mounted) {
        SnackBarUtils.showInfo(context, '正在保存图片...');
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

      if (imageBytes.isEmpty) {
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
          SnackBarUtils.showSuccess(context, '图片已保存到相册');
        }
        return true;
      } else {
        throw Exception('保存失败');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 保存图片失败: $e');
      }
      if (context.mounted) {
        SnackBarUtils.showError(context, '保存图片失败: ${e.toString()}');
      }
      return false;
    }
  }

  // 显示图片保存对话框（现代化设计）
  static void showImageSaveDialog(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) {
    if (Platform.isIOS) {
      // iOS 风格 - 使用 CupertinoActionSheet
      showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text(
            '图片操作',
            style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
          ),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await saveImageToGallery(context, imageUrl, headers: headers);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_down_circle, size: 22),
                  SizedBox(width: 8),
                  Text('保存到相册', style: TextStyle(fontSize: 17)),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await _shareImage(context, imageUrl, headers: headers);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share, size: 22),
                  SizedBox(width: 8),
                  Text('分享图片', style: TextStyle(fontSize: 17)),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(fontSize: 17)),
          ),
        ),
      );
    } else {
      // Android 风格 - 现代化设计
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
          final textColor = isDarkMode ? Colors.white : Colors.black87;
          final iconColor = Theme.of(context).primaryColor;

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动条
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '图片操作',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // 操作按钮网格
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 保存按钮
                        _buildActionButton(
                          icon: Icons.download_rounded,
                          label: '保存',
                          color: iconColor,
                          onTap: () async {
                            Navigator.pop(context);
                            await saveImageToGallery(context, imageUrl, headers: headers);
                          },
                        ),
                        // 分享按钮
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          label: '分享',
                          color: iconColor,
                          onTap: () async {
                            Navigator.pop(context);
                            await _shareImage(context, imageUrl, headers: headers);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 取消按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  /// 构建操作按钮（用于Android风格）
  static Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分享图片
  static Future<void> _shareImage(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) async {
    try {
      // 显示加载提示
      if (context.mounted) {
        SnackBarUtils.showInfo(context, '准备分享图片...');
      }

      // 获取图片文件
      File? imageFile;
      
      // 先尝试从缓存获取
      final cachedFile = await ImageCacheManager.authImageCache
          .getFileFromCache(imageUrl)
          .then((info) => info?.file);
      
      if (cachedFile != null && await cachedFile.exists()) {
        imageFile = cachedFile;
      } else {
        // 从网络下载到临时文件
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: headers,
        );
        
        if (response.statusCode == 200) {
          final tempDir = Directory.systemTemp;
          final fileName = 'inkroot_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
          imageFile = File('${tempDir.path}/$fileName');
          await imageFile.writeAsBytes(response.bodyBytes);
        }
      }

      if (imageFile != null && await imageFile.exists()) {
        // 使用 share_plus 直接分享
        await Share.shareXFiles([XFile(imageFile.path)], text: '来自 InkRoot 的图片分享');
      } else {
        throw Exception('无法获取图片文件');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, '分享失败: ${e.toString()}');
      }
      if (kDebugMode) {
        debugPrint('❌ 分享图片失败: $e');
      }
    }
  }
}
