import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/utils/tag_path_utils.dart';

void main() {
  group('normalizeIncomingTagPath', () {
    test('keeps plain Chinese tags readable', () {
      expect(normalizeIncomingTagPath('中文'), '中文');
    });

    test('decodes percent encoded Chinese tags', () {
      expect(normalizeIncomingTagPath('%E4%B8%AD%E6%96%87'), '中文');
    });

    test('decodes tags that were encoded twice', () {
      expect(
        normalizeIncomingTagPath('%25E4%25B8%25AD%25E6%2596%2587'),
        '中文',
      );
    });

    test('normalizes nested Chinese tag paths', () {
      expect(normalizeIncomingTagPath('父/%E5%AD%90'), '父/子');
      expect(normalizeIncomingTagPath(' 父 // 子 '), '父/子');
    });

    test('returns null for empty paths', () {
      expect(normalizeIncomingTagPath('  /  '), isNull);
    });
  });

  group('tagPathMatches', () {
    test('matches encoded child tags against readable parent path', () {
      expect(tagPathMatches('%E4%B8%AD%E6%96%87/子', '中文'), isTrue);
    });

    test('does not match similar prefix tags as children', () {
      expect(tagPathMatches('中文化/子', '中文'), isFalse);
    });
  });
}
