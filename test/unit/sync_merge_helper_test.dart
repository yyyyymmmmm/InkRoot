import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/sync_merge_helper.dart';

Note _note({
  required String id,
  required String content,
  List<Annotation>? annotations,
}) {
  return Note(
    id: id,
    content: content,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    annotations: annotations ?? const [],
  );
}

void main() {
  test('SYNC-MERGE-01 inserts new notes and marks as synced', () {
    final local = <Note>[];
    final updated = [
      _note(id: '1', content: 'hello #tag'),
      _note(id: '2', content: 'world'),
    ];

    final plan = planSyncMerge(localNotes: local, updatedNotes: updated);
    expect(plan.newCount, 2);
    expect(plan.updatedCount, 0);
    expect(plan.toInsert.every((n) => n.isSynced), isTrue);
    expect(plan.toInsert.first.tags, contains('tag'));
  });

  test('SYNC-MERGE-02 updates existing notes and preserves local annotations', () {
    final localAnnotations = [
      Annotation(
        id: 'a1',
        type: AnnotationType.idea,
        content: 'keep me',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isResolved: false,
      ),
    ];

    final local = [
      _note(id: '1', content: 'old', annotations: localAnnotations),
    ];
    final updated = [
      _note(id: '1', content: 'new #x'),
    ];

    final plan = planSyncMerge(localNotes: local, updatedNotes: updated);
    expect(plan.newCount, 0);
    expect(plan.updatedCount, 1);
    expect(plan.toUpdate.single.annotations, isNotEmpty);
    expect(plan.toUpdate.single.annotations.first.content, 'keep me');
    expect(plan.toUpdate.single.tags, contains('x'));
  });
}

