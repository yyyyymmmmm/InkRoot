import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/random_review_selector_service.dart';
import 'package:inkroot/services/widget_snapshot_service.dart';

void main() {
  Note note({
    required String id,
    required String content,
    required DateTime updatedAt,
  }) =>
      Note(
        id: id,
        content: content,
        createdAt: updatedAt,
        updatedAt: updatedAt,
      );

  group('RandomReviewSelectorService', () {
    test('uses the same time range and tag AND filtering as random review', () {
      final now = DateTime.now();
      final notes = [
        note(
          id: 'recent-work-health',
          content: '今天复盘 #工作 #健康',
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        note(
          id: 'recent-work',
          content: '项目记录 #工作',
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        note(
          id: 'old-work-health',
          content: '很久以前 #工作 #健康',
          updatedAt: now.subtract(const Duration(days: 90)),
        ),
      ];

      final selected = RandomReviewSelectorService.select(
        notes: notes,
        reviewDays: 30,
        reviewCount: 5,
        selectedTags: {'工作', '健康'},
        random: Random(0),
      );

      expect(selected.map((note) => note.id), ['recent-work-health']);
    });

    test('falls back to all notes when the current filter has no matches', () {
      final now = DateTime.now();
      final notes = [
        note(
          id: 'old-a',
          content: '旧笔记 A #生活',
          updatedAt: now.subtract(const Duration(days: 60)),
        ),
        note(
          id: 'old-b',
          content: '旧笔记 B #生活',
          updatedAt: now.subtract(const Duration(days: 80)),
        ),
      ];

      final selected = RandomReviewSelectorService.select(
        notes: notes,
        reviewDays: 7,
        reviewCount: 5,
        random: Random(0),
      );

      expect(selected.map((note) => note.id).toSet(), {'old-a', 'old-b'});
    });

    test('widget mode prefers notes with visible preview text', () {
      final now = DateTime.now();
      final notes = [
        note(
          id: 'image-only',
          content: '![](https://example.com/a.png)',
          updatedAt: now,
        ),
        note(
          id: 'text',
          content: '这条能显示在小组件',
          updatedAt: now,
        ),
      ];

      final selected = RandomReviewSelectorService.select(
        notes: notes,
        reviewCount: 5,
        random: Random(0),
        requireVisibleText: true,
      );

      expect(selected.map((note) => note.id), ['text']);
    });

    test('widget mode falls back to real notes when none has visible text', () {
      final now = DateTime.now();
      final notes = [
        note(
          id: 'image-only',
          content: '![](https://example.com/a.png)',
          updatedAt: now,
        ),
      ];

      final selected = RandomReviewSelectorService.selectWidgetCandidates(
        notes: notes,
        reviewCount: 5,
        random: Random(0),
      );

      expect(selected.map((note) => note.id), ['image-only']);
    });
  });

  group('WidgetSnapshotService', () {
    test('keeps image-only real notes in random review snapshot', () {
      final now = DateTime.now();
      final snapshot = WidgetSnapshotService.debugBuildSnapshot(
        notes: [
          note(
            id: 'image-only',
            content: '![](https://example.com/a.png)',
            updatedAt: now,
          ),
        ],
        isLocalMode: true,
        isLoggedIn: false,
        isSyncing: false,
      );

      final reviewNotes = snapshot['reviewNotes']! as List;
      expect(reviewNotes, hasLength(1));
      expect(reviewNotes.single, containsPair('id', 'image-only'));
      expect(reviewNotes.single, containsPair('preview', '这是一条含图片的笔记'));
    });
  });
}
