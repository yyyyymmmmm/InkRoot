import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/ai_review_service.dart';

void main() {
  group('AiReviewService', () {
    test('uses local review when remote AI is disabled', () async {
      final note = Note(
        id: '1',
        content: '今天整理了 WebDAV 图片同步问题 #同步\n- [ ] 补充失败场景',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        tags: const ['同步'],
      );

      final result = await const AiReviewService().generateReview(
        appConfig: AppConfig(),
        note: note,
        allNotes: const [],
      );

      expect(result.source, AiReviewSource.local);
      expect(result.review, contains('下一步'));
      expect(result.review, contains('补充失败场景'));
      expect(result.review, contains('完成标准'));
    });

    test('cleans markdown from remote review text', () {
      final cleaned = AiReviewService.cleanMarkdownForReview(
        '# 标题\n\n**核心判断**：这条笔记有价值。\n- 下一步：补充场景。',
      );

      expect(cleaned, isNot(contains('#')));
      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains('- ')));
      expect(cleaned, contains('核心判断'));
      expect(cleaned, contains('下一步'));
    });
  });
}
