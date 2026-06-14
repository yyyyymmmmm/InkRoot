import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/sort_order.dart';

int Function(Note a, Note b) noteComparator(SortOrder order) => (a, b) {
      // pinned first
      if (a.isPinned && !b.isPinned) {
        return -1;
      }
      if (!a.isPinned && b.isPinned) {
        return 1;
      }

      return switch (order) {
        SortOrder.newest => b.createdAt.compareTo(a.createdAt),
        SortOrder.oldest => a.createdAt.compareTo(b.createdAt),
        SortOrder.updated => b.updatedAt.compareTo(a.updatedAt),
      };
    };

List<Note> sortedNotesCopy(List<Note> notes, SortOrder order) {
  final sorted = List<Note>.from(notes);
  sorted.sort(noteComparator(order));
  return sorted;
}

/// Infers current sort order from a list already sorted with pinned notes first.
SortOrder inferCurrentSortOrder(List<Note> notes) {
  if (notes.length < 2) {
    return SortOrder.newest;
  }

  final unpinned = notes.where((n) => !n.isPinned).toList();
  if (unpinned.length < 2) {
    return SortOrder.newest;
  }

  final a = unpinned[0];
  final b = unpinned[1];
  if (a.createdAt.isAfter(b.createdAt)) {
    return SortOrder.newest;
  }
  if (a.createdAt.isBefore(b.createdAt)) {
    return SortOrder.oldest;
  }
  if (a.updatedAt.isAfter(b.updatedAt)) {
    return SortOrder.updated;
  }
  return SortOrder.newest;
}
