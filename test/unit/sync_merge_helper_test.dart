import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/sync_merge_helper.dart';

Note _note({
  required String id,
  required String content,
  DateTime? createdAt,
  DateTime? updatedAt,
  List<Annotation>? annotations,
}) =>
    Note(
      id: id,
      content: content,
      createdAt: createdAt ?? DateTime(2024),
      updatedAt: updatedAt ?? DateTime(2024),
      annotations: annotations ?? const [],
    );

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

  test('SYNC-MERGE-02 updates existing notes and preserves local annotations',
      () {
    final localAnnotations = [
      Annotation(
        id: 'a1',
        type: AnnotationType.idea,
        content: 'keep me',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
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

  test('SYNC-MERGE-03 preserves local historical timeline after upload refresh',
      () {
    final local = _note(
      id: 'server-1',
      content: 'old offline note',
      createdAt: DateTime(2021, 5, 1, 8),
      updatedAt: DateTime(2021, 5, 1, 9),
    );
    final server = _note(
      id: 'server-1',
      content: 'old offline note',
      createdAt: DateTime(2026, 6, 14, 10),
      updatedAt: DateTime(2026, 6, 14, 10),
    );

    final merged = mergeServerNoteWithLocalState(server, local);

    expect(merged.createdAt, local.createdAt);
    expect(merged.updatedAt, local.updatedAt);
  });

  test('SYNC-MERGE-03B uses server timeline on normal refresh', () {
    final local = _note(
      id: 'server-1',
      content: 'same content',
      createdAt: DateTime(2026, 6, 14, 10),
      updatedAt: DateTime(2026, 6, 14, 10),
    );
    final server = _note(
      id: 'server-1',
      content: 'same content',
      createdAt: DateTime(2022, 1, 1, 8),
      updatedAt: DateTime(2022, 1, 2, 9),
    );

    final merged = mergeServerNoteWithLocalState(server, local);

    expect(merged.createdAt, server.createdAt);
    expect(merged.updatedAt, server.updatedAt);
  });

  test('SYNC-MERGE-03C explicit upload refresh preserves local timeline', () {
    final local = _note(
      id: 'server-1',
      content: 'offline note',
      createdAt: DateTime(2021, 5, 1, 8),
      updatedAt: DateTime(2021, 5, 1, 9),
    );
    final server = _note(
      id: 'server-1',
      content: 'offline note',
      createdAt: DateTime(2026, 6, 14, 10),
      updatedAt: DateTime(2026, 6, 14, 10),
    );

    final merged = mergeServerNoteWithLocalState(
      server,
      local,
      preserveLocalTimeline: true,
    );

    expect(merged.createdAt, local.createdAt);
    expect(merged.updatedAt, local.updatedAt);
  });

  test('SYNC-MERGE-04 uses server updatedAt when server content really changed',
      () {
    final local = _note(
      id: 'server-2',
      content: 'old content',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024, 1, 2),
    );
    final server = _note(
      id: 'server-2',
      content: 'new remote content',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024, 2),
    );

    final merged = mergeServerNoteWithLocalState(server, local);

    expect(merged.createdAt, local.createdAt);
    expect(merged.updatedAt, server.updatedAt);
    expect(merged.content, server.content);
  });
}
