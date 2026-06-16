import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/intelligent_related_notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('IntelligentRelatedNotesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('finds short related notes by stored tags', () async {
      final current = _note(
        id: '1',
        content: '术后复盘',
        tags: const ['胰腺癌'],
      );
      final related = _note(
        id: '2',
        content: '饮食记录',
        tags: const ['胰腺癌'],
      );
      final unrelated = _note(
        id: '3',
        content: 'Flutter 布局调试',
        tags: const ['开发'],
      );

      final result =
          await IntelligentRelatedNotesService().findIntelligentRelatedNotes(
        currentNote: current,
        allNotes: [current, unrelated, related],
        apiKey: null,
        apiUrl: null,
        model: null,
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.allRelations.first.note.id, related.id);
      expect(result.allRelations.first.reason, contains('共同标签'));
    });

    test('finds related notes that reference the same link domain', () async {
      final current = _note(
        id: '1',
        content: 'Claude 模型地址 https://gpt-agent.cc/v1',
      );
      final related = _note(
        id: '2',
        content: 'AI 设置代理地址 https://gpt-agent.cc/docs',
      );
      final unrelated = _note(
        id: '3',
        content: '今天看了天气预报',
      );

      final result =
          await IntelligentRelatedNotesService().findIntelligentRelatedNotes(
        currentNote: current,
        allNotes: [current, unrelated, related],
        apiKey: null,
        apiUrl: null,
        model: null,
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.allRelations.first.note.id, related.id);
      expect(result.allRelations.first.reason, contains('gpt-agent.cc'));
    });
  });
}

Note _note({
  required String id,
  required String content,
  List<String> tags = const [],
}) =>
    Note(
      id: id,
      content: content,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      tags: tags,
    );
