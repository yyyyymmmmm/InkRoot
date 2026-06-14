import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/utils/memos_markdown_converter.dart';

void main() {
  group('MemosMarkdownConverter', () {
    test('normalizes loose strong delimiters for display', () {
      final converter = MemosMarkdownConverter();

      expect(
        converter.convert('**GTA5 Mods **'),
        '**GTA5 Mods** ',
      );
    });

    test('does not normalize loose strong delimiters inside code fences', () {
      final converter = MemosMarkdownConverter();

      const content = '''
```dart
final value = "**GTA5 Mods **";
```
''';

      expect(converter.convert(content), content);
    });

    test('keeps bare urls unchanged for display rendering', () {
      final converter = MemosMarkdownConverter();

      expect(
        converter.convert('网站\nhttps://gpt-agent.cc/v1'),
        '网站\nhttps://gpt-agent.cc/v1',
      );
    });

    test('preserves inline bare url position', () {
      final converter = MemosMarkdownConverter();

      expect(
        converter.convert('模型地址：claude-sonnet-4-6 https://gpt-agent.cc/v1'),
        '模型地址：claude-sonnet-4-6 https://gpt-agent.cc/v1',
      );
    });

    test('does not convert existing markdown links or code spans', () {
      final converter = MemosMarkdownConverter();

      expect(
        converter.convert('[官网](https://gpt-agent.cc/v1)'),
        '[官网](https://gpt-agent.cc/v1)',
      );
      expect(
        converter.convert('`https://gpt-agent.cc/v1`'),
        '`https://gpt-agent.cc/v1`',
      );
    });

    test('does not convert bare urls inside code fences', () {
      final converter = MemosMarkdownConverter();

      const content = '''
```
https://gpt-agent.cc/v1
```
''';

      expect(converter.convert(content), content);
    });

    test('converts tags to same-text markdown links outside urls and code', () {
      final converter = MemosMarkdownConverter();

      expect(
        converter.convert('#AI https://example.com/#section `#code`'),
        '[#AI](#AI) https://example.com/#section `#code`',
      );
    });
  });
}
