import 'package:inkroot/models/note_model.dart';

class SyncMergePlan {
  SyncMergePlan({required this.toInsert, required this.toUpdate});

  final List<Note> toInsert;
  final List<Note> toUpdate;

  int get newCount => toInsert.length;
  int get updatedCount => toUpdate.length;
}

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
        note.copyWith(
          tags: tags,
          isSynced: true,
          annotations: local.annotations,
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

