import 'package:inkroot/models/note_model.dart';

class SyncMergePlan {
  SyncMergePlan({required this.toInsert, required this.toUpdate});

  final List<Note> toInsert;
  final List<Note> toUpdate;

  int get newCount => toInsert.length;
  int get updatedCount => toUpdate.length;
}

/// Merge server data into an existing local note without destroying local-only
/// state. Server timestamps win for normal refreshes so backup/restore mistakes
/// can be corrected; local timeline is kept only for offline-created notes that
/// are being acknowledged by the server.
Note mergeServerNoteWithLocalState(
  Note serverNote,
  Note localNote, {
  bool preserveLocalTimeline = false,
}) {
  final serverHasDifferentContent = serverNote.content != localNote.content;
  final serverCreatedAt = _isValidServerTimestamp(serverNote.createdAt)
      ? serverNote.createdAt
      : localNote.createdAt;
  final localPredatesServerCreate = localNote.createdAt.isBefore(
    serverCreatedAt.subtract(const Duration(minutes: 1)),
  );
  final shouldPreserveLocalTimeline = preserveLocalTimeline ||
      (!serverHasDifferentContent &&
          localPredatesServerCreate &&
          localNote.updatedAt.isBefore(
            serverNote.updatedAt.add(const Duration(minutes: 1)),
          ));

  final mergedCreatedAt =
      shouldPreserveLocalTimeline ? localNote.createdAt : serverCreatedAt;
  final serverUpdatedAt = _isValidServerTimestamp(serverNote.updatedAt)
      ? serverNote.updatedAt
      : localNote.updatedAt;
  final mergedUpdatedAt =
      shouldPreserveLocalTimeline ? localNote.updatedAt : serverUpdatedAt;

  return serverNote.copyWith(
    createdAt: mergedCreatedAt,
    updatedAt: mergedUpdatedAt,
    displayTime: shouldPreserveLocalTimeline
        ? localNote.displayTime
        : (serverNote.displayTime == serverNote.updatedAt
            ? mergedUpdatedAt
            : serverNote.displayTime),
    isSynced: true,
    tags: serverHasDifferentContent
        ? serverNote.tags
        : (localNote.tags.isNotEmpty ? localNote.tags : serverNote.tags),
    isPinned: localNote.isPinned,
    relations: localNote.relations.isNotEmpty
        ? localNote.relations
        : serverNote.relations,
    annotations: localNote.annotations,
    reminderTime: localNote.reminderTime,
  );
}

bool _isValidServerTimestamp(DateTime value) =>
    value.millisecondsSinceEpoch > 0;

/// Pure merge planning logic used by incremental sync.
///
/// - Preserves local annotations when updating an existing note.
/// - Extracts tags from content for both insert/update.
/// - Marks notes as synced.
SyncMergePlan planSyncMerge({
  required List<Note> localNotes,
  required List<Note> updatedNotes,
}) {
  final localById = {for (final n in localNotes) n.id: n};

  final toInsert = <Note>[];
  final toUpdate = <Note>[];

  for (final note in updatedNotes) {
    final tags = Note.extractTagsFromContent(note.content);
    final local = localById[note.id];

    if (local != null) {
      toUpdate.add(
        mergeServerNoteWithLocalState(
          note.copyWith(tags: tags),
          local,
        ),
      );
    } else {
      toInsert.add(
        note.copyWith(
          tags: tags,
          isSynced: true,
        ),
      );
    }
  }

  return SyncMergePlan(toInsert: toInsert, toUpdate: toUpdate);
}
