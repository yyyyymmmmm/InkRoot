import 'dart:math';

import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/utils/memos_content_helper.dart';
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;

abstract final class RandomReviewSelectorService {
  static const int allDays = 999999;

  static List<Note> select({
    required List<Note> notes,
    int reviewDays = allDays,
    int reviewCount = 1,
    Set<String> selectedTags = const {},
    Random? random,
    bool requireVisibleText = false,
  }) {
    if (notes.isEmpty || reviewCount <= 0) {
      return <Note>[];
    }

    final sourceNotes = requireVisibleText
        ? notes
            .where(
              (note) => MemosContentHelper.previewVisibleText(note.content)
                  .trim()
                  .isNotEmpty,
            )
            .toList()
        : notes;
    if (sourceNotes.isEmpty) {
      return <Note>[];
    }

    final normalizedDays = reviewDays <= 0 ? allDays : reviewDays;
    final cutoffDate = DateTime.now().subtract(Duration(days: normalizedDays));
    var filteredNotes = sourceNotes
        .where((note) => note.updatedAt.isAfter(cutoffDate))
        .toList();

    if (selectedTags.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        final noteTags = tag_utils.extractTagsFromContent(note.content).toSet();
        return selectedTags.every(noteTags.contains);
      }).toList();
    }

    final availableNotes = filteredNotes.isEmpty ? sourceNotes : filteredNotes;
    final shuffled = List<Note>.from(availableNotes)
      ..shuffle(random ?? Random());
    return shuffled.take(reviewCount).toList();
  }

  static List<Note> selectWidgetCandidates({
    required List<Note> notes,
    int reviewDays = allDays,
    int reviewCount = 8,
    Random? random,
  }) {
    final textNotes = select(
      notes: notes,
      reviewDays: reviewDays,
      reviewCount: reviewCount,
      random: random,
      requireVisibleText: true,
    );
    if (textNotes.isNotEmpty) {
      return textNotes;
    }

    return select(
      notes: notes,
      reviewDays: reviewDays,
      reviewCount: reviewCount,
      random: random,
    );
  }
}
