import 'dart:async'; // 🚀 导入 Timer
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:inkroot/config/app_config.dart'; // 🔥 导入AppConfig
import 'package:inkroot/l10n/app_localizations.dart'; // 🌍 国际化
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/share_image_widget.dart'; // 🔥 导入模板枚举
import 'package:inkroot/utils/share_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareImagePreviewScreen extends StatefulWidget {
  const ShareImagePreviewScreen({
    required this.noteId,
    required this.content,
    required this.timestamp,
    super.key,
  });
  final String noteId;
  final String content;
  final DateTime timestamp;

  @override
  State<ShareImagePreviewScreen> createState() =>
      _ShareImagePreviewScreenState();
}

class _ShareImagePreviewScreenState extends State<ShareImagePreviewScreen> {
  ShareTemplateStyle _currentTemplate = ShareTemplateStyle.simple;
  bool _isGeneratingPreview = true; // 🔥 初始状态改为 true，避免闪现错误页面
  Uint8List? _previewImageBytes;
  double _fontSize = 20; // 🎨 默认字体大小调整为 20

  // 🚀 防抖定时器 - 避免频繁重新生成预览
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // 🔥 立即开始生成预览 - 延迟到 build 完成后
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _generatePreview();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 🎨 生成预览图（使用新方法，支持多模板）
  Future<void> _generatePreview() async {
    setState(() {
      _isGeneratingPreview = true;
    });

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final baseUrl =
          provider.user?.serverUrl ?? provider.appConfig.memosApiUrl;

      // 🔥 修复：从resourceList中提取图片并添加到content（和详情页一样）
      var contentWithImages = widget.content;
      final notes = provider.notes;
      final currentNote = notes.firstWhere(
        (note) => note.id == widget.noteId,
        orElse: () => Note(
          id: widget.noteId,
          content: widget.content,
          createdAt: widget.timestamp,
          updatedAt: widget.timestamp,
        ),
      );

      // 检查content是否已包含图片
      final hasImagesInContent =
          RegExp(r'!\[.*?\]\((.*?)\)').hasMatch(contentWithImages);

      if (!hasImagesInContent && currentNote.resourceList.isNotEmpty) {
        // content中没有图片，但resourceList有，则添加
        final imagePaths = <String>[];
        for (final resource in currentNote.resourceList) {
          final uid = resource['uid'] as String?;
          final type = resource['type'] as String?;
          final filename = resource['filename'] as String?;

          // 🛡️ 过滤掉视频文件，只保留图片
          if (uid != null) {
            // 检查是否为视频文件
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

        if (imagePaths.isNotEmpty) {
          // 在内容末尾添加图片
          contentWithImages += '\n\n';
          for (final path in imagePaths) {
            contentWithImages += '![]($path)\n';
          }
        }
      }

      if (kDebugMode) debugPrint('📄 SharePreview: 开始生成预览图...');

      // 🔥 使用新的预览方法，传递包含图片的content和字体大小
      final imageBytes = await ShareUtils.generatePreviewImageFromWidget(
        context: context,
        content: contentWithImages, // ← 使用包含图片的content
        timestamp: widget.timestamp,
        username: provider.user?.nickname ?? provider.user?.username,
        baseUrl: baseUrl,
        template: _currentTemplate, // 🎨 传递模板参数
        fontSize: _fontSize, // 🎨 传递字体大小
      );

      if (!mounted) {
        if (kDebugMode) debugPrint('⚠️ SharePreview: Widget 已卸载，取消更新状态');
        return;
      }

      if (kDebugMode) debugPrint('🔄 SharePreview: 准备调用 setState...');

      setState(() {
        if (kDebugMode) debugPrint('🔄 SharePreview: setState 内部执行中...');
        _previewImageBytes = imageBytes;
        _isGeneratingPreview = false;
        if (kDebugMode) {
          debugPrint(
            '🔄 SharePreview: setState 内部完成 - _isGeneratingPreview = $_isGeneratingPreview',
          );
        }
      });

      if (kDebugMode) debugPrint('✅ SharePreview: setState 调用完成');

      // 🔧 强制触发下一帧渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kDebugMode) {
          debugPrint('🎬 SharePreview: PostFrameCallback 执行，强制标记需要重建');
        }
        if (mounted) {
          // 再次确保状态已更新
          setState(() {});
        }
      });
    } catch (e) {
      setState(() {
        _isGeneratingPreview = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showError(
          context,
          '${l10n?.shareImageGenerationFailed ?? "预览图生成失败"}: $e',
        );
      }
    }
  }

  // 获取图片路径
  Future<List<String>> _getImagePaths() async {
    final imagePaths = <String>[];

    // 从现有笔记获取图片资源
    final provider = Provider.of<AppProvider>(context, listen: false);
    final notes = provider.notes;
    final currentNote = notes.firstWhere(
      (note) => note.id == widget.noteId,
      orElse: () => Note(
        id: widget.noteId,
        content: widget.content,
        createdAt: widget.timestamp,
        updatedAt: widget.timestamp,
      ),
    );

    for (final resource in currentNote.resourceList) {
      final uid = resource['uid'] as String?;
      final type = resource['type'] as String?;
      final filename = resource['filename'] as String?;

      // 🛡️ 过滤掉视频文件，只保留图片
      if (uid != null) {
        // 检查是否为视频文件
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
          final resourcePath = '/o/r/$uid';
          imagePaths.add(resourcePath);
        }
      }
    }

    // 从content中提取Markdown格式的图片
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final imageMatches = imageRegex.allMatches(widget.content);

    for (final match in imageMatches) {
      final path = match.group(1) ?? '';
      if (path.isNotEmpty && !imagePaths.contains(path)) {
        imagePaths.add(path);
      }
    }

    return imagePaths;
  }

  // 🎨 切换模板（已支持多模板！）
  void _switchTemplate(ShareTemplateStyle template) {
    if (_currentTemplate != template) {
      setState(() {
        _currentTemplate = template;
      });
      _generatePreview();
    }
  }

  // 🎨 构建预览内容
  Widget _buildPreviewContent(AppLocalizations? l10n) {
    // 正在生成预览
    if (_isGeneratingPreview) {
      if (kDebugMode) debugPrint('🎨 显示：加载中');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.shareImageGeneratingPreview ?? '正在生成预览...',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.shareImageLoadingImages ?? '正在加载图片，请稍候...',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 预览图已生成
    if (_previewImageBytes != null) {
      if (kDebugMode) {
        debugPrint('🎨 显示：预览图 (${_previewImageBytes!.length} bytes)');
      }
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _previewImageBytes!,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              gaplessPlayback: true, // 🔥 避免图片闪烁
            ),
          ),
        ),
      );
    }

    // 生成失败
    if (kDebugMode) debugPrint('🎨 显示：错误');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n?.shareImageGenerationFailed ?? '图片生成失败',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 🎨 显示模板选择器（参考备份样式 - 横向滚动）
  void _showTemplateSelector(AppLocalizations? l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor =
            isDarkMode ? AppTheme.darkCardColor : Colors.white;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) =>
              Container(
            height: MediaQuery.of(context).size.height * 0.3, // 固定高度为30%
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // 顶部拖动条
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 模板网格（横向滚动）
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTemplateCard(
                            ShareTemplateStyle.simple,
                            setModalState,
                            l10n,
                          ),
                          const SizedBox(width: 12),
                          _buildTemplateCard(
                            ShareTemplateStyle.card,
                            setModalState,
                            l10n,
                          ),
                          const SizedBox(width: 12),
                          _buildTemplateCard(
                            ShareTemplateStyle.gradient,
                            setModalState,
                            l10n,
                          ),
                          const SizedBox(width: 12),
                          _buildTemplateCard(
                            ShareTemplateStyle.minimal,
                            setModalState,
                            l10n,
                          ),
                          const SizedBox(width: 12),
                          _buildTemplateCard(
                            ShareTemplateStyle.magazine,
                            setModalState,
                            l10n,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 确定按钮
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '确定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎨 构建模板卡片（横向滚动样式）
  Widget _buildTemplateCard(
    ShareTemplateStyle template,
    StateSetter setModalState,
    AppLocalizations? l10n,
  ) {
    // 获取模板名称（带回退文本）
    String title;
    switch (template) {
      case ShareTemplateStyle.simple:
        title = l10n?.shareTemplateSimple ?? '简约';
        break;
      case ShareTemplateStyle.card:
        title = l10n?.shareTemplateCard ?? '卡片';
        break;
      case ShareTemplateStyle.gradient:
        title = l10n?.shareTemplateGradient ?? '渐变';
        break;
      case ShareTemplateStyle.minimal:
        title = l10n?.shareTemplateMinimal ?? '极简';
        break;
      case ShareTemplateStyle.magazine:
        title = l10n?.shareTemplateMagazine ?? '杂志';
        break;
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentTemplate == template;

    return GestureDetector(
      onTap: () {
        // 更新对话框中的状态
        setModalState(() {});
        // 更新主页面状态
        setState(() {
          _currentTemplate = template;
        });
        // 重新生成预览
        _generatePreview();
      },
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // 模板预览
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getTemplatePreviewColor(template),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _getTemplatePreviewContent(template),
                ),
              ),
            ),

            // 模板名称和选中标记
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 14,
                    ),
                  if (isSelected) const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取模板预览颜色
  Color _getTemplatePreviewColor(ShareTemplateStyle template) {
    switch (template) {
      case ShareTemplateStyle.simple:
        return Colors.white;
      case ShareTemplateStyle.card:
        return const Color(0xFFFFF8F0);
      case ShareTemplateStyle.gradient:
        return Colors.purple.shade100;
      case ShareTemplateStyle.minimal:
        return const Color(0xFFFAFAFA);
      case ShareTemplateStyle.magazine:
        return Colors.white;
    }
  }

  // 获取模板预览内容
  Widget _getTemplatePreviewContent(ShareTemplateStyle template) {
    final primaryColor = _getTemplatePrimaryColor(template);

    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 顶部日期和标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 20,
                height: 4,
                color: primaryColor.withOpacity(0.7),
              ),
              Container(
                width: 15,
                height: 4,
                color: primaryColor.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 内容线条
          Container(
            width: double.infinity,
            height: 3,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            height: 3,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity * 0.7,
            height: 3,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          // 底部信息
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 25,
              height: 3,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 获取模板主色调
  Color _getTemplatePrimaryColor(ShareTemplateStyle template) {
    switch (template) {
      case ShareTemplateStyle.simple:
        return Colors.grey.shade400;
      case ShareTemplateStyle.card:
        return Colors.pink.shade300;
      case ShareTemplateStyle.gradient:
        return Colors.purple.shade300;
      case ShareTemplateStyle.minimal:
        return Colors.grey.shade400;
      case ShareTemplateStyle.magazine:
        return AppTheme.primaryColor;
    }
  }

  // 🎨 分享图片（支持多模板）
  Future<void> _shareImage() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    // ✅ 检查预览图是否已生成
    if (_previewImageBytes == null) {
      SnackBarUtils.showWarning(
        context,
        l10n?.shareImageWaitForPreview ?? '请等待预览图生成完成',
      );
      return;
    }

    try {
      if (kDebugMode) debugPrint('📤 开始分享预览图...');

      // ✅ 直接使用已生成的预览图分享（不重新生成！）
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'inkroot_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(_previewImageBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '📝 来自${AppConfig.appName}的分享\n\n${widget.content.length > 100 ? '${widget.content.substring(0, 100)}...' : widget.content}',
      );

      if (kDebugMode) debugPrint('✅ 分享完成');
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '${l10n?.shareImageShareFailed ?? "分享失败"}: $e',
        );
      }
      if (kDebugMode) debugPrint('❌ 分享图片失败: $e');
    }
  }

  // 保存图片
  Future<void> _saveImage() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    if (_previewImageBytes == null) {
      SnackBarUtils.showWarning(
        context,
        l10n?.shareImageWaitForPreview ?? '请等待预览图生成完成',
      );
      return;
    }

    // 缓存需要的国际化文本（带回退）
    final savingText = l10n?.shareImageSaving ?? '正在保存...';
    final savingToAlbumText = l10n?.shareImageSavingToAlbum ?? '正在保存到相册，请稍候';

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkCardColor
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                savingText,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                savingToAlbumText,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 🔥 直接使用预览图片保存
      final result = await ImageGallerySaverPlus.saveImage(
        _previewImageBytes!,
        name: 'inkroot_share_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (result['isSuccess'] == true) {
          SnackBarUtils.showSuccess(
            context,
            l10n?.shareImageSaveSuccess ?? '图片已保存到相册',
          );
        } else {
          SnackBarUtils.showError(
            context,
            l10n?.shareImageSaveFailed ?? '保存失败',
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showError(
          context,
          '${l10n?.shareImageSaveFailed ?? "保存失败"}: $e',
        );
      }
      if (kDebugMode) debugPrint('Error saving image: $e');
    }
  }

  // 🚀 防抖更新字体大小 - 实时预览
  void _updateFontSizeWithDebounce(double newSize) {
    setState(() {
      _fontSize = newSize;
    });

    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 设置新的定时器：用户停止调整600ms后才重新生成预览
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _generatePreview();
      }
    });
  }

  // 🎨 显示字体大小设置 - 实时预览版
  void _showFontSizeSettings(AppLocalizations? l10n) {
    final initialFontSize = _fontSize; // 记录初始值
    var currentFontSize = _fontSize; // 🔥 弹窗内部的字体大小状态

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor =
            isDarkMode ? AppTheme.darkCardColor : Colors.white;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) =>
              WillPopScope(
            onWillPop: () async {
              // 关闭时触发最后一次生成
              _debounceTimer?.cancel();
              if (_fontSize != initialFontSize) {
                _generatePreview();
              }
              return true;
            },
            child: Container(
              height: 240, // 🔧 增加高度避免溢出
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // 顶部拖动条
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 标题和说明
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.text_fields,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.shareImageFontSizeTitle ?? '字体大小',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n?.shareImageFontSizeDesc ?? '调整分享图片中的文字大小',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 当前字体大小显示
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${currentFontSize.toInt()}px',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 字体大小滑块
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_decrease,
                          size: 20,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        Expanded(
                          child: Slider(
                            value: currentFontSize,
                            min: 12,
                            max: 24,
                            divisions: 12,
                            activeColor: AppTheme.primaryColor,
                            label: '${currentFontSize.toInt()}px',
                            onChanged: (value) {
                              // 🔥 更新弹窗内部状态
                              setModalState(() {
                                currentFontSize = value;
                              });
                              // 🔥 同时更新外部状态（立即预览）
                              _updateFontSizeWithDebounce(value);
                            },
                          ),
                        ),
                        Icon(
                          Icons.text_increase,
                          size: 24,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 快捷按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                currentFontSize = 20.0;
                              });
                              _updateFontSizeWithDebounce(20);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(l10n?.shareImageFontSizeReset ?? '重置'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _debounceTimer?.cancel();
                              Navigator.pop(context);
                              if (_fontSize != initialFontSize) {
                                _generatePreview();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(l10n?.shareImageFontSizeDone ?? '完成'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // 弹窗关闭时，确保生成最终预览
      _debounceTimer?.cancel();
      if (_fontSize != initialFontSize) {
        _generatePreview();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 调试：build 方法被调用

    // 🌍 获取国际化对象（使用回退机制）
    final l10n = AppLocalizations.of(context);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.shareImageTitle ?? '分享图片',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // 🎨 更多按钮 - 字体大小调整
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => _showFontSizeSettings(l10n),
            tooltip: l10n?.shareImageFontSettings ?? '字体设置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 预览区域
          Expanded(
            child: _buildPreviewContent(l10n),
          ),

          // 移除初始界面的模板选择区域，只在弹出界面中显示

          // 底部操作栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.white,
              border: Border(
                top: BorderSide(
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // 🎨 更换模板按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTemplateSelector(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? AppTheme.darkCardColor
                          : Colors.grey.shade50,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Text(l10n?.shareImageChangeTemplate ?? '更换模板'),
                  ),
                ),
                const SizedBox(width: 12),
                // 保存图片按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l10n?.shareImageSave ?? '保存'),
                  ),
                ),
                const SizedBox(width: 12),
                // 分享按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shareImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? AppTheme.darkCardColor
                          : Colors.grey.shade100,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Text(l10n?.shareImageShare ?? '分享'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// 🔥 旧代码已删除，新代码在上面

// 🗑️ 以下是旧的废弃代码，保留注释供参考
/*
  // 构建模板选择按钮（已废弃）
  Widget _buildTemplateButton(String title, ShareTemplate template) {
    final isSelected = _currentTemplate == template;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _switchTemplate(template),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white : Colors.black87),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 显示更多模板选项 - 底部弹出式
  void _showMoreTemplateOptions() {
    // 使用底部弹出框而不是全屏对话框
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.3, // 控制高度为屏幕的30%，与参考图一致
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // 顶部拖动条
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 模板网格
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTemplateCardForDialog("简约模板", ShareTemplate.simple, setModalState),
                            const SizedBox(width: 12),
                            _buildTemplateCardForDialog("卡片模板", ShareTemplate.card, setModalState),
                            const SizedBox(width: 12),
                            _buildTemplateCardForDialog("渐变模板", ShareTemplate.gradient, setModalState),
                            const SizedBox(width: 12),
                            _buildTemplateCardForDialog("日记模板", ShareTemplate.diary, setModalState),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 确定按钮
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // 关闭模板选择，回到预览界面
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // 为对话框构建模板卡片
  Widget _buildTemplateCardForDialog(String title, ShareTemplate template, StateSetter setModalState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentTemplate == template;
    
    return GestureDetector(
      onTap: () {
        // 更新对话框中的状态
        setModalState(() {});
        // 更新主页面状态
        setState(() {
          _currentTemplate = template;
        });
        // 重新生成预览
        _generatePreview();
      },
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // 模板预览
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getTemplatePreviewColor(template),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _getTemplatePreviewContent(template),
                ),
              ),
            ),
            
            // 模板名称和选中标记
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 14,
                    ),
                  if (isSelected)
                    const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建简化版模板卡片（横向滚动版本）
  Widget _buildSimpleTemplateCard(String title, ShareTemplate template) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentTemplate == template;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTemplate = template; // 直接更新当前模板
        });
        _generatePreview(); // 重新生成预览
      },
      child: Container(
        width: 100, // 调整宽度，与参考图一致
        height: 140, // 调整高度，与参考图一致
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // 模板预览
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(6), // 减小边距
                decoration: BoxDecoration(
                  color: _getTemplatePreviewColor(template),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _getTemplatePreviewContent(template),
                ),
              ),
            ),
            
            // 模板名称和选中标记
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6), // 减小内边距
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: 14, // 减小图标大小
                    ),
                  if (isSelected)
                    const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11, // 减小字体大小
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取模板预览颜色
  Color _getTemplatePreviewColor(ShareTemplate template) {
    switch (template) {
      case ShareTemplate.simple:
        return Colors.white;
      case ShareTemplate.card:
        return Colors.blue.shade50;
      case ShareTemplate.gradient:
        return Colors.purple.shade100;
      case ShareTemplate.diary:
        return Colors.amber.shade50;
    }
  }

  // 获取模板预览内容
  Widget _getTemplatePreviewContent(ShareTemplate template) {
    // 对所有模板使用相同的预览内容样式，只是颜色和背景不同
    final Color primaryColor = _getTemplatePrimaryColor(template);
    final Color backgroundColor = _getTemplatePreviewColor(template);
    
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 顶部日期和标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 20,
                height: 4,
                color: primaryColor.withOpacity(0.7),
              ),
              Container(
                width: 15,
                height: 4,
                color: primaryColor.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 内容线条
          Container(
            width: double.infinity,
            height: 3,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            height: 3,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity * 0.7,
            height: 3,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          // 底部信息
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 25,
              height: 3,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // 获取模板主色调
  Color _getTemplatePrimaryColor(ShareTemplate template) {
    switch (template) {
      case ShareTemplate.simple:
        return Colors.grey.shade400;
      case ShareTemplate.card:
        return Colors.blue.shade300;
      case ShareTemplate.gradient:
        return Colors.purple.shade300;
      case ShareTemplate.diary:
        return Colors.amber.shade700;
    }
  }

  // 显示选项菜单
  void _showOptionsMenu(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    '显示选项',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 时间显示开关
                  _buildToggleOption(
                    '显示时间',
                    '在分享图片右上角显示时间信息',
                    Icons.access_time,
                    _showTime,
                    (value) {
                      setModalState(() {
                        _showTime = value;
                      });
                      setState(() {
                        _showTime = value;
                      });
                      _generatePreview(); // 重新生成预览
                    },
                    isDarkMode,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 用户名显示开关
                  _buildToggleOption(
                    '显示用户名',
                    '在分享图片左上角显示用户名或InkRoot',
                    Icons.person,
                    _showUser,
                    (value) {
                      setModalState(() {
                        _showUser = value;
                      });
                      setState(() {
                        _showUser = value;
                      });
                      _generatePreview(); // 重新生成预览
                    },
                    isDarkMode,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 品牌信息显示开关
                  _buildToggleOption(
                    '显示版权',
                    '在分享图片右下角显示InkRoot品牌信息',
                    Icons.copyright,
                    _showBrand,
                    (value) {
                      setModalState(() {
                        _showBrand = value;
                      });
                      setState(() {
                        _showBrand = value;
                      });
                      _generatePreview(); // 重新生成预览
                    },
                    isDarkMode,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 关闭按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '完成',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 构建切换选项组件
  Widget _buildToggleOption(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 图标
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 文本信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 开关
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
*/
