import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:inkroot/config/asset_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ImageUtils {
  // 默认缓存管理器
  static final fcm.DefaultCacheManager _cacheManager =
      fcm.DefaultCacheManager();

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

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static String _defaultImageFileName([String? source]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _imageExtensionFromSource(source);
    return 'inkroot_$timestamp.$extension';
  }

  static String _imageExtensionFromSource(String? source) {
    final path = Uri.tryParse(source ?? '')?.path.toLowerCase() ?? '';
    for (final extension in ['jpg', 'jpeg', 'png', 'webp', 'gif']) {
      if (path.endsWith('.$extension')) {
        return extension;
      }
    }
    return 'png';
  }

  static Future<Uint8List> _loadImageBytes(
    String imageUrl, {
    Map<String, String>? headers,
    String? downloadImageFailed,
  }) async {
    if (imageUrl.startsWith('file://')) {
      final file = File(Uri.parse(imageUrl).toFilePath());
      if (await file.exists()) {
        return file.readAsBytes();
      }
    }

    final localFile = File(imageUrl);
    if (await localFile.exists()) {
      return localFile.readAsBytes();
    }

    final cachedFile = await ImageCacheManager.authImageCache
        .getFileFromCache(imageUrl)
        .then((info) => info?.file);

    if (cachedFile != null && await cachedFile.exists()) {
      if (kDebugMode) {
        debugPrint('📷 从缓存加载图片: ${cachedFile.path}');
      }
      return cachedFile.readAsBytes();
    }

    if (kDebugMode) {
      debugPrint('📷 从网络下载图片: $imageUrl');
    }
    final response = await http.get(
      Uri.parse(imageUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    throw Exception(
      '${downloadImageFailed ?? '下载图片失败'}: ${response.statusCode}',
    );
  }

  static Future<bool> saveImageBytes(
    BuildContext context,
    Uint8List imageBytes, {
    String? fileName,
  }) async {
    final l10n = AppLocalizationsSimple.of(context);
    final storagePermissionRequiredForImage =
        l10n?.storagePermissionRequiredForImage ?? '需要存储权限才能保存图片';
    final imageDataEmpty = l10n?.imageDataEmpty ?? '图片数据为空';
    final imageSavedToGallery = l10n?.imageSavedToGallery ?? '图片已保存到相册';
    final imageSavedToDevice = l10n?.imageSavedToDevice ?? '图片已保存到设备';
    final savingFailed = l10n?.savingFailed ?? '保存失败';
    final saveImageFailed = l10n?.saveImageFailed ?? '保存图片失败';

    try {
      if (imageBytes.isEmpty) {
        throw Exception(imageDataEmpty);
      }

      if (_isDesktop) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: l10n?.chooseSaveLocation ?? '选择保存位置',
          fileName: fileName ?? _defaultImageFileName(),
        );

        if (path == null) {
          return false;
        }

        final savedFile = File(path);
        await savedFile.writeAsBytes(imageBytes, flush: true);
        if (!await savedFile.exists() || await savedFile.length() == 0) {
          throw Exception(saveImageFailed);
        }

        if (context.mounted) {
          SnackBarUtils.showSuccess(context, imageSavedToDevice);
        }
        return true;
      }

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 28) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (context.mounted) {
              SnackBarUtils.showError(
                context,
                storagePermissionRequiredForImage,
              );
            }
            return false;
          }
        }
      } else {
        final status = await Permission.photosAddOnly.request();
        if (!status.isGranted && !status.isLimited) {
          if (context.mounted) {
            SnackBarUtils.showError(context, storagePermissionRequiredForImage);
          }
          return false;
        }
      }

      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name: (fileName ?? _defaultImageFileName()).replaceAll(
          RegExp(r'\.[^.]+$'),
          '',
        ),
      );

      if (kDebugMode) {
        debugPrint('📷 保存结果: $result');
      }

      final success = result is Map
          ? (result['isSuccess'] == true || result['filePath'] != null)
          : result != null;

      if (!success) {
        throw Exception(savingFailed);
      }

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, imageSavedToGallery);
      }
      return true;
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 保存图片失败: $e');
      }
      if (context.mounted) {
        SnackBarUtils.showError(context, '$saveImageFailed: $e');
      }
      return false;
    }
  }

  // 移动端保存到相册，桌面端弹出文件保存位置。
  static Future<bool> saveImageToGallery(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) async {
    final l10n = AppLocalizationsSimple.of(context);
    final savingImage = l10n?.savingImage ?? '正在保存图片...';
    final downloadImageFailed = l10n?.downloadImageFailed ?? '下载图片失败';
    final saveImageFailed = l10n?.saveImageFailed ?? '保存图片失败';
    try {
      if (context.mounted) {
        SnackBarUtils.showInfo(
          context,
          savingImage,
        );
      }

      final imageBytes = await _loadImageBytes(
        imageUrl,
        headers: headers,
        downloadImageFailed: downloadImageFailed,
      );
      if (!context.mounted) {
        return false;
      }
      return saveImageBytes(
        context,
        imageBytes,
        fileName: _defaultImageFileName(imageUrl),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 保存图片失败: $e');
      }
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          '$saveImageFailed: $e',
        );
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
    final l10n = AppLocalizationsSimple.of(context);
    if (Platform.isIOS) {
      // iOS 风格 - 使用 CupertinoActionSheet
      showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text(
            l10n?.imageActionsTitle ?? '图片操作',
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await saveImageToGallery(context, imageUrl, headers: headers);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.arrow_down_circle, size: 22),
                  const SizedBox(width: 8),
                  Text(l10n?.saveImage ?? '保存图片'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await _shareImage(context, imageUrl, headers: headers);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.share, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.shareImage ?? '分享图片',
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n?.cancel ?? '取消',
              style: const TextStyle(fontSize: 17),
            ),
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

          return DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n?.imageActionsTitle ?? '图片操作',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // 操作按钮网格
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 保存按钮
                        _buildActionButton(
                          icon: Icons.download_rounded,
                          label: l10n?.saveAction ?? '保存',
                          color: iconColor,
                          onTap: () async {
                            Navigator.pop(context);
                            await saveImageToGallery(
                              context,
                              imageUrl,
                              headers: headers,
                            );
                          },
                        ),
                        // 分享按钮
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          label: l10n?.share ?? '分享',
                          color: iconColor,
                          onTap: () async {
                            Navigator.pop(context);
                            await _shareImage(
                              context,
                              imageUrl,
                              headers: headers,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 取消按钮
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          l10n?.cancel ?? '取消',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withValues(alpha: 0.7),
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
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
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

  /// 分享图片
  static Future<void> _shareImage(
    BuildContext context,
    String imageUrl, {
    Map<String, String>? headers,
  }) async {
    final l10n = AppLocalizationsSimple.of(context);
    final preparingShareImage = l10n?.preparingShareImage ?? '准备分享图片...';
    final imageShareText = l10n?.imageShareText ?? '来自 InkRoot 的图片分享';
    final cannotGetImageFile = l10n?.cannotGetImageFile ?? '无法获取图片文件';
    final shareImageFailed = l10n?.shareImageFailed ?? '分享图片失败';
    try {
      // 显示加载提示
      if (context.mounted) {
        SnackBarUtils.showInfo(
          context,
          preparingShareImage,
        );
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
          final fileName =
              'inkroot_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
          imageFile = File('${tempDir.path}/$fileName');
          await imageFile.writeAsBytes(response.bodyBytes);
        }
      }

      if (imageFile != null && await imageFile.exists()) {
        // 使用 share_plus 直接分享
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: imageShareText,
        );
      } else {
        throw Exception(cannotGetImageFile);
      }
    } on Object catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          '$shareImageFailed: $e',
        );
      }
      if (kDebugMode) {
        debugPrint('❌ 分享图片失败: $e');
      }
    }
  }
}
