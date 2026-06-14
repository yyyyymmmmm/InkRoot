// ============================================================
// 第一档测试 · TagUtils（tag_utils.dart）
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/utils/tag_utils.dart';

void main() {
  group('extractTagsFromContent', () {
    test('TAG-01 基础标签提取', () {
      final tags = extractTagsFromContent('今天学 #Flutter 真好玩');
      expect(tags, contains('Flutter'));
    });

    test('TAG-02 多个标签全部提取', () {
      final tags = extractTagsFromContent('笔记 #工作 #生活 #2024');
      expect(tags.length, 3);
      expect(tags, containsAll(['工作', '生活', '2024']));
    });

    test('TAG-03 URL 中的 # 不被提取', () {
      final tags =
          extractTagsFromContent('https://example.com/page#anchor 是一个链接');
      expect(tags, isEmpty);
    });

    test('TAG-04 URL 内 # 和文本标签共存时正确区分', () {
      final tags =
          extractTagsFromContent('看链接 https://example.com#section 和标签 #笔记');
      expect(tags, contains('笔记'));
      expect(tags, isNot(contains('section')));
    });

    test('TAG-05 ## Markdown 标题不被提取', () {
      final tags = extractTagsFromContent('## 这是标题\n#这是标签');
      expect(tags, contains('这是标签'));
      // 不应包含 "这是标题" 或空字符串
      expect(tags, isNot(contains('这是标题')));
    });

    test('TAG-06 标签紧跟换行符也能识别', () {
      final tags = extractTagsFromContent('#Flutter\n#Dart');
      expect(tags, containsAll(['Flutter', 'Dart']));
    });

    test('TAG-07 空内容返回空列表', () {
      expect(extractTagsFromContent(''), isEmpty);
    });

    test('TAG-08 标签以字母开头正确提取', () {
      final tags = extractTagsFromContent('记录 #work #life');
      expect(tags, containsAll(['work', 'life']));
    });
  });

  group('isTagInUrl', () {
    test('TAG-09 标签在 URL 内返回 true', () {
      const line = 'https://example.com/page#anchor';
      // anchor 的 # 在 url 范围内
      final hashIdx = line.indexOf('#');
      final result = isTagInUrl(line, hashIdx, line.length);
      expect(result, isTrue);
    });

    test('TAG-10 标签不在 URL 内返回 false', () {
      const line = '查看 https://example.com 和标签 #笔记';
      final tagIdx = line.indexOf('#笔记');
      final result = isTagInUrl(line, tagIdx, tagIdx + 3);
      expect(result, isFalse);
    });
  });
}
