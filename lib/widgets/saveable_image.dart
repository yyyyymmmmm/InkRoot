import 'package:flutter/material.dart';
import 'package:inkroot/utils/image_utils.dart';

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
          ImageUtils.showImageSaveDialog(
            context,
            imageUrl,
            headers: headers,
          );
        },
        child: child,
      );
}
