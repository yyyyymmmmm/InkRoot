import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/tag_ai_service.dart';

void main() {
  group('TagAIService', () {
    test('generates concrete local tag insights without emoji templates', () {
      final notes = List.generate(
        6,
        (index) => Note(
          id: '$index',
          content: 'WebDAV 图片同步失败场景整理，需要补充恢复测试和日志。',
          createdAt: DateTime(2026, 1, index + 1),
          updatedAt: DateTime(2026, 1, index + 1),
          tags: const ['同步'],
        ),
      );

      final insights = TagAIService.generateInsights(
        tagName: '同步',
        tagNotes: notes,
        monthlyStats: const {'2026-01': 6},
        trendData: const {
          'trend': 'increasing',
          'confidence': 80,
          'prediction': 7,
        },
      );

      expect(insights, isNotEmpty);
      expect(insights.join('\n'), contains('同步'));
      expect(insights.join('\n'), contains('复盘'));
      expect(
        RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true)
            .hasMatch(insights.join('\n')),
        isFalse,
      );
      expect(insights.join('\n'), isNot(contains('继续保持记录习惯')));
    });

    test('calculates related tag relevance from co-occurrence', () {
      final notes = [
        Note(
          id: '1',
          content: '同步问题',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          tags: const ['同步', 'WebDAV'],
        ),
        Note(
          id: '2',
          content: '同步图片',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          tags: const ['同步', '图片'],
        ),
        Note(
          id: '3',
          content: 'WebDAV 备份',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          tags: const ['同步', 'WebDAV'],
        ),
      ];

      final scores = TagAIService.calculateTagRelevance(
        currentTag: '同步',
        allNotes: notes,
      );

      expect(scores.keys, contains('WebDAV'));
      expect(scores.keys, contains('图片'));
      expect(scores['WebDAV'], greaterThan(scores['图片']!));
    });
  });
}
