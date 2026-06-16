String? normalizeTagPath(String tag) {
  final parts = tag
      .split('/')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return null;
  }
  return parts.join('/');
}

bool tagPathMatches(String rawTag, String targetPath) {
  final tag = normalizeTagPath(rawTag);
  final target = normalizeTagPath(targetPath);
  if (tag == null || target == null) {
    return false;
  }
  return tag == target || tag.startsWith('$target/');
}
