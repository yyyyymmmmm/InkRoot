// ignore_for_file: avoid_classes_with_only_static_members

import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/memos_resource_service.dart';
import 'package:inkroot/utils/memos_markdown_converter.dart';
import 'package:markdown/markdown.dart' as md;

abstract final class MemosContentHelper {
  static final RegExp markdownImageRegex = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');

  static List<String> extractMarkdownImagePaths(String content) =>
      markdownImageRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .where((path) => path.isNotEmpty)
          .toList();

  static String removeMarkdownImages(String content) {
    var result = content;
    for (final match in markdownImageRegex.allMatches(content)) {
      result = result.replaceAll(match.group(0) ?? '', '');
    }
    return result;
  }

  static String previewVisibleText(String content) {
    final withoutImages = removeMarkdownImages(content);
    if (withoutImages.trim().isEmpty) {
      return '';
    }

    final converted = MemosMarkdownConverter().convert(
      _normalizeInlineHtmlForPreview(withoutImages),
    );
    final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final nodes = document.parse(converted);

    return nodes
        .map(_visibleTextFromNode)
        .where((text) => text.trim().isNotEmpty)
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trimRight();
  }

  static String previewTextForExpansion(String content) {
    final lines = previewVisibleText(content).split('\n');

    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }

    while (lines.isNotEmpty && _isTrailingMetadataLine(lines.last)) {
      lines.removeLast();
      while (lines.isNotEmpty && lines.last.trim().isEmpty) {
        lines.removeLast();
      }
    }

    return lines.join('\n').trimRight();
  }

  static String _visibleTextFromNode(md.Node node) {
    if (node is md.Text) {
      return node.text;
    }
    if (node is! md.Element) {
      return node.textContent;
    }

    switch (node.tag) {
      case 'img':
      case 'hr':
        return '';
      case 'br':
        return '\n';
      case 'li':
        return node.children?.map(_visibleTextFromNode).join() ?? '';
      default:
        return node.children?.map(_visibleTextFromNode).join() ??
            node.textContent;
    }
  }

  static bool _isTrailingMetadataLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return true;
    }

    return trimmed.startsWith('#');
  }

  static String _normalizeInlineHtmlForPreview(String content) =>
      content.replaceAllMapped(
        RegExp(r'<[uU]\b[^>]*>([\s\S]*?)<\/[uU]>'),
        (match) => match.group(1) ?? '',
      );

  static List<String> extractResourceImagePaths(
    List<Map<String, dynamic>> resources,
  ) {
    final paths = <String>[];

    for (final resource in resources) {
      if (_isVideoResource(resource)) {
        continue;
      }

      final externalLink = resource['externalLink']?.toString();
      if (externalLink != null && externalLink.isNotEmpty) {
        paths.add(externalLink);
        continue;
      }

      final name = resource['name']?.toString();
      final filename = resource['filename']?.toString();
      if (name != null && name.startsWith('attachments/')) {
        paths.add(
          filename != null && filename.isNotEmpty
              ? '/file/$name/$filename'
              : name,
        );
        continue;
      }

      final uid = resource['uid']?.toString() ?? name?.split('/').last;
      if (uid == null || uid.isEmpty) {
        continue;
      }

      paths.add('/o/r/$uid');
    }

    return paths;
  }

  static bool isMemosResourcePath(String path) =>
      MemosResourceService.isServerResourcePath(path);

  static List<String> extractNoteImagePaths(Note note) {
    final paths = <String>[];

    for (final path in extractResourceImagePaths(note.resourceList)) {
      if (!paths.contains(path)) {
        paths.add(path);
      }
    }

    for (final path in extractMarkdownImagePaths(note.content)) {
      if (!paths.contains(path)) {
        paths.add(path);
      }
    }

    return paths;
  }

  static String contentWithResourceImages(Note note) {
    final imagePaths = extractResourceImagePaths(note.resourceList);
    if (imagePaths.isEmpty) {
      return note.content;
    }

    final existingPaths = extractMarkdownImagePaths(note.content).toSet();
    final missingPaths = imagePaths
        .where((path) => path.isNotEmpty && !existingPaths.contains(path))
        .toList();
    if (missingPaths.isEmpty) {
      return note.content;
    }

    final buffer = StringBuffer(note.content.trimRight());
    if (buffer.isNotEmpty) {
      buffer.write('\n\n');
    }
    for (final path in missingPaths) {
      buffer.writeln('![]($path)');
    }
    return buffer.toString().trimRight();
  }

  static bool _isVideoResource(Map<String, dynamic> resource) {
    final type = resource['type'] as String?;
    final filename = resource['filename'] as String?;

    if (type != null && type.toLowerCase().startsWith('video')) {
      return true;
    }
    if (filename == null) {
      return false;
    }

    final ext = filename.toLowerCase();
    return ext.endsWith('.mov') ||
        ext.endsWith('.mp4') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm') ||
        ext.endsWith('.flv');
  }
}
