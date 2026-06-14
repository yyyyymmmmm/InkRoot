import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/sort_order.dart';
import 'package:inkroot/services/note_sorting_helper.dart';

Note _n(
  String id, {
  required DateTime created,
  required DateTime updated,
  bool pinned = false,
}) =>
    Note(
      id: id,
      content: id,
      createdAt: created,
      updatedAt: updated,
      isPinned: pinned,
    );

void main() {
  test('SORT-01 pinned notes always come first', () {
    final notes = [
      _n('a', created: DateTime(2024, 1, 2), updated: DateTime(2024, 1, 2)),
      _n(
        'p',
        created: DateTime(2024),
        updated: DateTime(2024),
        pinned: true,
      ),
    ];
    final sorted = sortedNotesCopy(notes, SortOrder.newest);
    expect(sorted.first.id, 'p');
  });

  test('SORT-02 newest sorts by createdAt desc within same pinned group', () {
    final notes = [
      _n('1', created: DateTime(2024), updated: DateTime(2024)),
      _n('2', created: DateTime(2024, 1, 2), updated: DateTime(2024, 1, 2)),
    ];
    final sorted = sortedNotesCopy(notes, SortOrder.newest);
    expect(sorted.map((n) => n.id).toList(), ['2', '1']);
  });

  test('SORT-03 oldest sorts by createdAt asc within same pinned group', () {
    final notes = [
      _n('1', created: DateTime(2024), updated: DateTime(2024)),
      _n('2', created: DateTime(2024, 1, 2), updated: DateTime(2024, 1, 2)),
    ];
    final sorted = sortedNotesCopy(notes, SortOrder.oldest);
    expect(sorted.map((n) => n.id).toList(), ['1', '2']);
  });

  test('SORT-04 updated sorts by updatedAt desc within same pinned group', () {
    final notes = [
      _n('1', created: DateTime(2024), updated: DateTime(2024)),
      _n('2', created: DateTime(2024, 1, 2), updated: DateTime(2024, 1, 3)),
    ];
    final sorted = sortedNotesCopy(notes, SortOrder.updated);
    expect(sorted.map((n) => n.id).toList(), ['2', '1']);
  });

  test('SORT-05 inferCurrentSortOrder ignores pinned notes', () {
    final notes = [
      _n(
        'p',
        created: DateTime(2024, 1, 10),
        updated: DateTime(2024, 1, 10),
        pinned: true,
      ),
      _n('a', created: DateTime(2024, 1, 2), updated: DateTime(2024, 1, 2)),
      _n('b', created: DateTime(2024), updated: DateTime(2024, 1, 5)),
    ];
    // a.created > b.created => newest
    expect(inferCurrentSortOrder(notes), SortOrder.newest);
  });
}
