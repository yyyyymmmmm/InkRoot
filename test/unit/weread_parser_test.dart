// ============================================================
// 第一档测试 · WeReadParser
// 覆盖各种格式的微信读书笔记解析
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/weread_parser.dart';

void main() {
  // ─────────────────────────────────────────────────────────
  // 基础解析
  // ─────────────────────────────────────────────────────────
  group('WeReadParser.parse — 基础解析', () {
    test('WR-01 标准格式：书名提取去除《》', () {
      const input = '''
《哲学入门》
作者名
3个笔记
第一章 认识论
◆ 知识是什么
''';
      final result = WeReadParser.parse(input);
      expect(result.bookTitle, '哲学入门');
    });

    test('WR-02 笔记内容以 ◆ 开头正确解析', () {
      const input = '''
《测试书名》
5个笔记
第一章
◆ 第一条笔记内容
◆ 第二条笔记内容
''';
      final result = WeReadParser.parse(input);
      expect(result.notes.length, 2);
      expect(result.notes[0].content, '第一条笔记内容');
    });

    test('WR-03 章节标题正确绑定到笔记', () {
      const input = '''
《测试》
第二章 存在主义
◆ 存在先于本质
''';
      final result = WeReadParser.parse(input);
      expect(result.notes[0].chapter, '第二章 存在主义');
    });

    test('WR-04 无书名《》格式时使用原始第一行作为书名', () {
      const input = '''
无括号书名
第一章
◆ 笔记内容
''';
      final result = WeReadParser.parse(input);
      expect(result.bookTitle, '无括号书名');
    });

    test('WR-05 纯数字短行章节格式化为 "第 N 部分"', () {
      const input = '''
《测试》
1
◆ 第一部分内容
''';
      final result = WeReadParser.parse(input);
      expect(result.notes[0].chapter, '第 1 部分');
    });

    test('WR-06 空内容抛出异常', () {
      expect(() => WeReadParser.parse(''), throwsException);
      expect(() => WeReadParser.parse('   \n  \n  '), throwsException);
    });

    test('WR-07 跳过 "X个笔记" 元数据行', () {
      const input = '''
《书名》
10个笔记
第一章
◆ 实际笔记
''';
      final result = WeReadParser.parse(input);
      // "10个笔记" 不应变成笔记内容或章节
      expect(result.notes.length, 1);
      expect(result.notes[0].chapter, '第一章');
    });

    test('WR-08 跳过 "来自微信读书" 行', () {
      const input = '''
《书名》
第一章
◆ 真实笔记
来自微信读书
''';
      final result = WeReadParser.parse(input);
      expect(result.notes.length, 1);
    });

    test('WR-09 跳过 "原文：" 开头的行', () {
      const input = '''
《书名》
第一章
◆ 原文：这是引用的原文内容
◆ 这是正常笔记
''';
      final result = WeReadParser.parse(input);
      expect(result.notes.length, 1);
      expect(result.notes[0].content, '这是正常笔记');
    });

    test('WR-10 无章节时使用书名作为章节兜底', () {
      const input = '''
《无章节书》
◆ 直接就有笔记没有章节
''';
      final result = WeReadParser.parse(input);
      expect(result.notes.isNotEmpty, isTrue);
      expect(result.notes[0].chapter, '无章节书');
    });

    test('WR-11 多章节多笔记正确分组', () {
      const input = '''
《多章节》
第一章
◆ 笔记A
◆ 笔记B
第二章
◆ 笔记C
''';
      final result = WeReadParser.parse(input);
      expect(result.notes.length, 3);
      expect(result.notes[0].chapter, '第一章');
      expect(result.notes[2].chapter, '第二章');
    });

    test('WR-12 笔记 bookTitle 与根书名一致', () {
      const input = '''
《测试书》
第一章
◆ 笔记内容
''';
      final result = WeReadParser.parse(input);
      expect(result.notes[0].bookTitle, '测试书');
    });
  });

  // ─────────────────────────────────────────────────────────
  // WeReadParser.toMarkdown
  // ─────────────────────────────────────────────────────────
  group('WeReadParser.toMarkdown', () {
    late WeReadNotesData testData;

    setUp(() {
      testData = WeReadParser.parse('''
《测试书名》
第一章
◆ 这是第一条笔记
◆ 这是第二条笔记
''');
    });

    test('WR-13 Markdown 包含书名为 H1 标题', () {
      final md = WeReadParser.toMarkdown(testData);
      expect(md, contains('# 测试书名'));
    });

    test('WR-14 Markdown 包含阅读笔记章节标题', () {
      final md = WeReadParser.toMarkdown(testData);
      expect(md, contains('📖 阅读笔记'));
    });

    test('WR-15 笔记内容使用引用 > 格式', () {
      final md = WeReadParser.toMarkdown(testData);
      expect(md, contains('> 这是第一条笔记'));
    });

    test('WR-16 包含 "导入自微信读书" 尾注', () {
      final md = WeReadParser.toMarkdown(testData);
      expect(md, contains('导入自微信读书'));
    });

    test('WR-17 包含 #微信读书 标签行', () {
      final md = WeReadParser.toMarkdown(testData);
      expect(md, contains('#微信读书'));
    });

    test('WR-18 章节标题使用 ### 格式', () {
      final md = WeReadParser.toMarkdown(testData);
      expect(md, contains('### 第一章'));
    });
  });

  // ─────────────────────────────────────────────────────────
  // 特殊格式兼容
  // ─────────────────────────────────────────────────────────
  group('WeReadParser — 特殊格式兼容', () {
    test('WR-19 章节标题中没有 "第x章" 字样时也能识别', () {
      const input = '''
《哲学书》
快感、幸福和快乐
◆ 斯宾诺莎认为欲望是人的本质
研究快乐的哲学家
◆ 吾之蜜糖，彼之砒霜
''';
      final result = WeReadParser.parse(input);
      expect(result.notes.length, 2);
      expect(result.notes[0].chapter, '快感、幸福和快乐');
      expect(result.notes[1].chapter, '研究快乐的哲学家');
    });

    test('WR-20 ◆ 后有多余空格也能正确截取内容', () {
      const input = '''
《书名》
第一章
◆  有多余空格的笔记内容
''';
      final result = WeReadParser.parse(input);
      expect(result.notes[0].content, '有多余空格的笔记内容');
    });
  });
}
