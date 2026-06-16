import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/local_note_analysis_service.dart';

void main() {
  group('LocalNoteAnalysisService', () {
    test('generates a local review without AI configuration', () {
      final note = Note(
        id: '1',
        content: '今天整理了胰腺癌治疗资料 #医学\n- [ ] 继续看指南',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        tags: const ['医学'],
      );

      final review =
          const LocalNoteAnalysisService().generateReview(note: note);

      expect(review, contains('下一步'));
      expect(review, contains('完成标准'));
      expect(review, contains('继续看指南'));
      expect(review, isNot(contains('资料卡')));
      expect(review, isNot(contains('真正的价值')));
    });

    test('finds related Chinese notes without spaces', () {
      final current = Note(
        id: '1',
        content: '胰腺癌治疗方案和术后复盘',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final related = Note(
        id: '2',
        content: '胰腺癌术后饮食和治疗记录',
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      );
      final unrelated = Note(
        id: '3',
        content: 'Flutter 布局调试记录',
        createdAt: DateTime(2026, 1, 3),
        updatedAt: DateTime(2026, 1, 3),
      );

      final notes = const LocalNoteAnalysisService().findRelatedNotes(
        current,
        [current, unrelated, related],
      );

      expect(notes.first.id, '2');
    });

    test('local review cites concrete link and avoids generic template wording',
        () {
      final current = Note(
        id: '1',
        content: 'Claude 模型地址，后面要接到 AI 设置里\nhttps://gpt-agent.cc/v1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final related = Note(
        id: '2',
        content: 'AI 设置页面允许用户自己输入模型和 API 地址',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final review = const LocalNoteAnalysisService().generateReview(
        note: current,
        allNotes: [current, related],
      );

      expect(review, contains('gpt-agent.cc'));
      expect(review, contains('Claude 模型地址'));
      expect(review, isNot(contains('真正的价值在于')));
      expect(review, isNot(contains('这条笔记更像一张资料卡')));
    });
  });
}
