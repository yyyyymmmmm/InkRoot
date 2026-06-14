import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/memos_resource_service.dart';
import 'package:inkroot/utils/image_cache_manager.dart';
import 'package:inkroot/utils/image_utils.dart';
import 'package:provider/provider.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    required this.imagePaths,
    required this.initialIndex,
    super.key,
  });

  final List<String> imagePaths;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<String> imagePaths,
    int initialIndex = 0,
  }) {
    if (imagePaths.isEmpty) {
      return Future.value();
    }

    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imagePaths: imagePaths,
          initialIndex: initialIndex.clamp(0, imagePaths.length - 1),
        ),
      ),
    );
  }

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _currentPageZoomed = false;

  String get _currentImagePath => widget.imagePaths[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _precacheAround(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static ImageProvider getImageProvider(
    String uriString,
    BuildContext context,
  ) {
    try {
      if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
        return CachedNetworkImageProvider(
          uriString,
          cacheManager: ImageCacheManager.authImageCache,
        );
      }

      if (_isServerResourcePath(uriString)) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final token = appProvider.user?.token;
        final fullUrl = _buildFullResourceUrl(appProvider, uriString);
        if (fullUrl == null) {
          return const AssetImage('assets/images/logo.png');
        }

        return CachedNetworkImageProvider(
          fullUrl,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          cacheManager: ImageCacheManager.authImageCache,
        );
      }

      if (uriString.startsWith('file://')) {
        return FileImage(File(uriString.replaceFirst('file://', '')));
      }

      if (uriString.startsWith('resource:')) {
        return AssetImage(uriString.replaceFirst('resource:', ''));
      }

      return const AssetImage('assets/images/logo.png');
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('ImageViewer: provider error: $e');
      }
      return const AssetImage('assets/images/logo.png');
    }
  }

  static bool _isServerResourcePath(String path) =>
      MemosResourceService.isServerResourcePath(path);

  static String? _buildFullResourceUrl(AppProvider appProvider, String path) {
    if (appProvider.resourceService != null) {
      return appProvider.resourceService!.buildImageUrl(path);
    }

    final baseUrl = appProvider.appConfig.lastServerUrl ??
        appProvider.user?.serverUrl ??
        appProvider.appConfig.memosApiUrl ??
        '';
    return baseUrl.isEmpty ? null : '$baseUrl$path';
  }

  String _getFullImageUrl(BuildContext context) {
    if (_currentImagePath.startsWith('http://') ||
        _currentImagePath.startsWith('https://')) {
      return _currentImagePath;
    }

    if (_isServerResourcePath(_currentImagePath)) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      return _buildFullResourceUrl(appProvider, _currentImagePath) ??
          _currentImagePath;
    }

    return _currentImagePath;
  }

  Map<String, String>? _getHeaders(BuildContext context) {
    if (!_isServerResourcePath(_currentImagePath)) {
      return null;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final token = appProvider.user?.token;
    return token != null ? {'Authorization': 'Bearer $token'} : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.34),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.imagePaths.length > 1
                ? '${_currentIndex + 1}/${widget.imagePaths.length}'
                : (AppLocalizationsSimple.of(context)?.viewOriginalImage ??
                    '查看原图'),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: AppLocalizationsSimple.of(context)?.saveImage ?? '保存图片',
              onPressed: () async {
                await ImageUtils.saveImageToGallery(
                  context,
                  _getFullImageUrl(context),
                  headers: _getHeaders(context),
                );
              },
            ),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          physics: _currentPageZoomed
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          itemCount: widget.imagePaths.length,
          onPageChanged: (index) => setState(() {
            _currentIndex = index;
            _currentPageZoomed = false;
            _precacheAround(index);
          }),
          itemBuilder: (context, index) => _ZoomablePhotoPage(
            key: ValueKey(widget.imagePaths[index]),
            imagePath: widget.imagePaths[index],
            onZoomChanged: index == _currentIndex
                ? (isZoomed) {
                    if (_currentPageZoomed == isZoomed) {
                      return;
                    }
                    setState(() => _currentPageZoomed = isZoomed);
                  }
                : null,
          ),
        ),
      );

  void _precacheAround(int index) {
    for (final nextIndex in [index - 1, index + 1]) {
      if (nextIndex < 0 || nextIndex >= widget.imagePaths.length) {
        continue;
      }
      precacheImage(
        getImageProvider(widget.imagePaths[nextIndex], context),
        context,
      );
    }
  }
}

class _ZoomablePhotoPage extends StatefulWidget {
  const _ZoomablePhotoPage({
    required this.imagePath,
    super.key,
    this.onZoomChanged,
  });

  final String imagePath;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<_ZoomablePhotoPage> createState() => _ZoomablePhotoPageState();
}

class _ZoomablePhotoPageState extends State<_ZoomablePhotoPage> {
  final TransformationController _transformationController =
      TransformationController();
  Offset? _doubleTapPosition;
  ImageProvider? _imageProvider;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _viewportSize;
  Size? _displaySize;
  Size? _imageSize;
  Object? _imageError;
  bool _isZoomed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _ZoomablePhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _resolveImage() {
    final provider = _ImageViewerScreenState.getImageProvider(
      widget.imagePath,
      context,
    );
    final stream = provider.resolve(createLocalImageConfiguration(context));

    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }

    _imageProvider = provider;
    _viewportSize = null;
    _displaySize = null;
    _imageSize = null;
    _imageError = null;
    _transformationController.value = Matrix4.identity();
    _isZoomed = false;
    widget.onZoomChanged?.call(false);

    _imageStreamListener = ImageStreamListener(
      (imageInfo, _) {
        if (!mounted) {
          return;
        }
        setState(() {
          _imageSize = Size(
            imageInfo.image.width.toDouble(),
            imageInfo.image.height.toDouble(),
          );
          _imageError = null;
        });
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Full screen image error: $error');
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _imageError = error;
        });
      },
    );

    _imageStream = stream;
    stream.addListener(_imageStreamListener!);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).maybePop();
        },
        onDoubleTapDown: (details) {
          _doubleTapPosition = details.localPosition;
        },
        onDoubleTap: () => _toggleZoom(context, focalPoint: _doubleTapPosition),
        child: ColoredBox(
          color: Colors.black,
          child: SafeArea(
            top: false,
            bottom: false,
            child: _buildZoomableImage(context),
          ),
        ),
      );

  void _toggleZoom(BuildContext context, {Offset? focalPoint}) {
    if (_viewportSize == null || _displaySize == null) {
      return;
    }

    if (_isZoomed) {
      _resetToContained();
      setState(() {
        _isZoomed = false;
      });
      widget.onZoomChanged?.call(false);
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final baseZoom = size.shortestSide < 600 ? 2.4 : 2.0;
    final coverZoom = math.max(
      _viewportSize!.width / _displaySize!.width,
      _viewportSize!.height / _displaySize!.height,
    );
    final zoom = math.min(math.max(baseZoom, coverZoom), 5.0);
    final focal = _effectiveZoomFocal(
      focalPoint,
      viewportSize: _viewportSize!,
      displaySize: _displaySize!,
    );
    final scenePoint = _transformationController.toScene(focal);

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        focal.dx - scenePoint.dx * zoom,
        focal.dy - scenePoint.dy * zoom,
        0,
        1,
      )
      ..scaleByDouble(zoom, zoom, 1, 1);
    _clampPhotoTransform();
    setState(() {
      _isZoomed = true;
    });
    widget.onZoomChanged?.call(true);
  }

  Widget _buildZoomableImage(BuildContext context) {
    if (_imageError != null) {
      return _buildImageError(
        AppLocalizationsSimple.of(context)?.imageLoadError ?? '无法加载图片',
      );
    }

    if (_imageProvider == null || _imageSize == null) {
      return _buildImageLoading(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final displaySize = _containSize(_imageSize!, screenSize);
        _syncPhotoLayout(screenSize, displaySize);

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1,
          maxScale: 5,
          boundaryMargin: EdgeInsets.symmetric(
            horizontal: screenSize.width,
            vertical: screenSize.height,
          ),
          constrained: false,
          onInteractionUpdate: (_) => _updateZoomState(),
          onInteractionEnd: (_) => _settlePhotoTransform(),
          child: SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: Image(
              image: _imageProvider!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }

  Size _containSize(Size source, Size bounds) {
    if (source.width <= 0 || source.height <= 0) {
      return bounds;
    }

    final scale = math.min(
      bounds.width / source.width,
      bounds.height / source.height,
    );
    return Size(source.width * scale, source.height * scale);
  }

  void _syncPhotoLayout(Size viewportSize, Size displaySize) {
    final layoutChanged =
        _viewportSize != viewportSize || _displaySize != displaySize;
    _viewportSize = viewportSize;
    _displaySize = displaySize;

    if (!layoutChanged || _isZoomed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isZoomed ||
          _viewportSize != viewportSize ||
          _displaySize != displaySize) {
        return;
      }
      _resetToContained();
    });
  }

  Matrix4 _containedMatrix(Size viewportSize, Size displaySize) {
    final imageRect = _containedImageRect(viewportSize, displaySize);
    return Matrix4.identity()
      ..translateByDouble(imageRect.left, imageRect.top, 0, 1);
  }

  Rect _containedImageRect(Size viewportSize, Size displaySize) =>
      Rect.fromLTWH(
        (viewportSize.width - displaySize.width) / 2,
        (viewportSize.height - displaySize.height) / 2,
        displaySize.width,
        displaySize.height,
      );

  Offset _effectiveZoomFocal(
    Offset? focalPoint, {
    required Size viewportSize,
    required Size displaySize,
  }) {
    final viewportCenter =
        Offset(viewportSize.width / 2, viewportSize.height / 2);
    if (focalPoint == null) {
      return viewportCenter;
    }

    final imageRect = _containedImageRect(viewportSize, displaySize);
    return imageRect.contains(focalPoint) ? focalPoint : viewportCenter;
  }

  void _resetToContained() {
    if (_viewportSize == null || _displaySize == null) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    _transformationController.value =
        _containedMatrix(_viewportSize!, _displaySize!);
  }

  void _clampPhotoTransform() {
    if (_viewportSize == null || _displaySize == null) {
      return;
    }

    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis().clamp(1.0, 5.0);
    final scaledWidth = _displaySize!.width * scale;
    final scaledHeight = _displaySize!.height * scale;
    final translation = matrix.getTranslation();

    final nextX = _clampAxis(
      translation.x,
      viewportExtent: _viewportSize!.width,
      contentExtent: scaledWidth,
    );
    final nextY = _clampAxis(
      translation.y,
      viewportExtent: _viewportSize!.height,
      contentExtent: scaledHeight,
    );

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(nextX, nextY, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  double _clampAxis(
    double value, {
    required double viewportExtent,
    required double contentExtent,
  }) {
    if (contentExtent <= viewportExtent) {
      return (viewportExtent - contentExtent) / 2;
    }

    return value.clamp(viewportExtent - contentExtent, 0.0);
  }

  void _updateZoomState() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged?.call(zoomed);
    }
  }

  void _settlePhotoTransform() {
    if (_transformationController.value.getMaxScaleOnAxis() <= 1.01) {
      _resetToContained();
      if (_isZoomed && mounted) {
        setState(() => _isZoomed = false);
        widget.onZoomChanged?.call(false);
      }
    } else {
      _clampPhotoTransform();
    }
  }

  Widget _buildImageLoading(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              AppLocalizationsSimple.of(context)?.loadingHDImage ??
                  '正在加载高清原图...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );

  Widget _buildImageError(String message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
}
