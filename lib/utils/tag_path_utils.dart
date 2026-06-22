import 'dart:convert';

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

String? normalizeIncomingTagPath(String tag) {
  var value = tag.trim();
  if (value.isEmpty) {
    return null;
  }

  for (var i = 0; i < 2; i += 1) {
    final decoded = _tryDecodeComponent(value);
    if (decoded == null || decoded == value) {
      break;
    }
    value = decoded;
  }

  return normalizeTagPath(value);
}

bool tagPathMatches(String rawTag, String targetPath) {
  final tag = normalizeIncomingTagPath(rawTag);
  final target = normalizeIncomingTagPath(targetPath);
  if (tag == null || target == null) {
    return false;
  }
  return tag == target || tag.startsWith('$target/');
}

String? _tryDecodeComponent(String value) {
  if (!value.contains('%')) {
    return value;
  }
  return _decodePercentEscapes(value);
}

String _decodePercentEscapes(String value) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < value.length) {
    if (value.codeUnitAt(index) == 0x25 && index + 2 < value.length) {
      final bytes = <int>[];
      var cursor = index;

      while (cursor + 2 < value.length && value.codeUnitAt(cursor) == 0x25) {
        final high = _hexValue(value.codeUnitAt(cursor + 1));
        final low = _hexValue(value.codeUnitAt(cursor + 2));
        if (high == null || low == null) {
          break;
        }
        bytes.add((high << 4) + low);
        cursor += 3;
      }

      if (bytes.isNotEmpty) {
        buffer.write(utf8.decode(bytes, allowMalformed: true));
        index = cursor;
        continue;
      }
    }

    buffer.write(value[index]);
    index += 1;
  }

  return buffer.toString();
}

int? _hexValue(int codeUnit) {
  if (codeUnit >= 0x30 && codeUnit <= 0x39) {
    return codeUnit - 0x30;
  }
  if (codeUnit >= 0x41 && codeUnit <= 0x46) {
    return codeUnit - 0x41 + 10;
  }
  if (codeUnit >= 0x61 && codeUnit <= 0x66) {
    return codeUnit - 0x61 + 10;
  }
  return null;
}
