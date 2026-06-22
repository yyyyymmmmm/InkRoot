import 'package:inkroot/utils/tag_path_utils.dart';

/// Lightweight tag statistics for sidebar/tags page.
///
/// NOTE: when used with `compute()`, input/output MUST be JSON-like objects.
class TagStatsSnapshot {
  const TagStatsSnapshot({
    required this.counts,
    required this.topTags,
    required this.totalUniqueTags,
  });

  final Map<String, int> counts;
  final List<String> topTags;
  final int totalUniqueTags;
}

/// Isolate-friendly tag stats computation.
///
/// Returns:
/// - counts: Map<String,int>
/// - topTags: List<String>
/// - totalUniqueTags: int
Map<String, dynamic> buildTagStatsPayloadFromNoteJson(
  List<Map<String, dynamic>> notesJson, {
  int topN = 20,
}) {
  final counts = <String, int>{};

  for (final n in notesJson) {
    final rawTags = n['tags'];
    if (rawTags is! List) {
      continue;
    }

    final noteTags = <String>{};
    for (final t in rawTags) {
      if (t is! String) {
        continue;
      }
      final tag = normalizeIncomingTagPath(t);
      if (tag == null) {
        continue;
      }
      noteTags.add(tag);
    }

    for (final tag in noteTags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) {
        return byCount;
      }
      return a.key.compareTo(b.key);
    });

  final limit = topN < 0
      ? 0
      : topN > sorted.length
          ? sorted.length
          : topN;
  final topTags = sorted.take(limit).map((e) => e.key).toList();

  return {
    'counts': counts,
    'topTags': topTags,
    'totalUniqueTags': counts.length,
  };
}

/// Convenience wrapper for `compute()` (must be a top-level function).
Map<String, dynamic> buildTop30TagStatsPayload(
  List<Map<String, dynamic>> notesJson,
) =>
    buildTagStatsPayloadFromNoteJson(notesJson, topN: 30);

Map<String, dynamic> buildTagTreePayloadFromNoteJson(
  List<Map<String, dynamic>> notesJson,
) {
  final nodeMap = <String, Map<String, dynamic>>{};
  final noteKeysByPath = <String, Set<String>>{};

  void ensureNode(String path) {
    if (nodeMap.containsKey(path)) {
      return;
    }
    final parts = path.split('/');
    nodeMap[path] = {
      'name': parts.isNotEmpty ? parts.last : path,
      'path': path,
      'children': <String>[],
    };
  }

  void addChild(String parent, String child) {
    final children = nodeMap[parent]!['children'] as List<String>;
    if (!children.contains(child)) {
      children.add(child);
    }
  }

  for (var noteIndex = 0; noteIndex < notesJson.length; noteIndex++) {
    final note = notesJson[noteIndex];
    final rawTags = note['tags'];
    if (rawTags is! List) {
      continue;
    }

    final noteKey = (note['id'] ?? noteIndex).toString();
    final noteTags = <String>{};
    for (final t in rawTags) {
      if (t is! String) {
        continue;
      }
      final tag = normalizeIncomingTagPath(t);
      if (tag == null) {
        continue;
      }
      noteTags.add(tag);
    }

    for (final tag in noteTags) {
      final parts = tag.split('/');
      for (var i = 0; i < parts.length; i++) {
        final path = parts.sublist(0, i + 1).join('/');
        ensureNode(path);
        noteKeysByPath.putIfAbsent(path, () => <String>{}).add(noteKey);

        if (i > 0) {
          final parent = parts.sublist(0, i).join('/');
          ensureNode(parent);
          addChild(parent, path);
        }
      }
    }
  }

  final roots = nodeMap.keys.where((p) => !p.contains('/')).toList()..sort();

  int countFor(String path) => noteKeysByPath[path]?.length ?? 0;

  int comparePath(String a, String b) {
    final byCount = countFor(b).compareTo(countFor(a));
    if (byCount != 0) {
      return byCount;
    }
    return a.compareTo(b);
  }

  Map<String, dynamic> buildNode(String path) {
    final n = nodeMap[path]!;
    final children = List<String>.from(n['children'] as List<String>)
      ..sort(comparePath);
    return {
      'name': n['name'],
      'path': path,
      'count': countFor(path),
      'children': children.map(buildNode).toList(growable: false),
    };
  }

  return {
    'totalUniqueTags': nodeMap.length,
    'roots': roots.map(buildNode).toList(growable: false),
  };
}

TagStatsSnapshot tagStatsSnapshotFromPayload(Map<String, dynamic> payload) {
  final countsRaw = payload['counts'];
  final counts = <String, int>{};
  if (countsRaw is Map) {
    for (final e in countsRaw.entries) {
      final k = e.key?.toString();
      final v = e.value;
      if (k == null || k.isEmpty) {
        continue;
      }
      if (v is int) {
        counts[k] = v;
      } else if (v is num) {
        counts[k] = v.toInt();
      }
    }
  }

  final topTags =
      (payload['topTags'] as List?)?.whereType<String>().toList() ?? const [];
  final totalUniqueTags = (payload['totalUniqueTags'] as int?) ?? counts.length;
  return TagStatsSnapshot(
    counts: counts,
    topTags: topTags,
    totalUniqueTags: totalUniqueTags,
  );
}
