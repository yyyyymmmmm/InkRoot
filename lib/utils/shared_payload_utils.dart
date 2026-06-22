String? sharedPayloadToContent(Object? payload) {
  if (payload is String) {
    return payload;
  }
  if (payload is! Map) {
    return null;
  }

  final type = payload['type']?.toString();
  switch (type) {
    case 'text':
      return payload['content']?.toString();
    case 'image':
      final path = payload['path']?.toString();
      if (path == null || path.isEmpty) {
        return null;
      }
      return '来自分享的图片:\n\n![图片](file://$path)';
    case 'images':
      final paths = (payload['paths'] as List?)?.cast<String>() ?? const [];
      if (paths.isEmpty) {
        return null;
      }
      final buffer = StringBuffer('来自分享的图片 (${paths.length}张):\n\n');
      for (final path in paths) {
        buffer.writeln('![图片](file://$path)\n');
      }
      return buffer.toString();
    case 'file':
      final path = payload['path']?.toString();
      if (path == null || path.isEmpty) {
        return null;
      }
      final fileName = path.split('/').last;
      return '分享的文件:\n\n📎 $fileName\n\n路径: $path';
  }
  return null;
}
