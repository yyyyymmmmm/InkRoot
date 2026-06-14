/// Graph build optimized for isolate execution.
///
/// Input/output MUST be JSON-like objects for `compute()`:
/// - primitives, List, Map with String keys.
library;

Map<String, dynamic> buildGraphPayload(Map<String, dynamic> request) {
  final notes = (request['notes'] as List?) ?? const [];
  final nodeById = <String, Map<String, dynamic>>{};
  final processedEdges = <String>{};
  final edges = <Map<String, dynamic>>[];

  // 1) Create nodes
  for (final raw in notes) {
    if (raw is! Map) {
      continue;
    }
    final id = raw['id']?.toString();
    if (id == null || id.isEmpty) {
      continue;
    }

    final content = raw['content']?.toString() ?? '';
    final tagsRaw = raw['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t is String && t.trim().isNotEmpty) {
          tags.add(t);
        }
      }
    }
    final pinned = raw['pinned'] == true;

    nodeById[id] = {
      'id': id,
      'title': _extractTitle(content),
      'content': content,
      'tags': tags,
      'outgoingCount': 0,
      'incomingCount': 0,
      'isPinned': pinned,
    };
  }

  // 2) Build edges and counts (O(nodes + edges))
  for (final raw in notes) {
    if (raw is! Map) {
      continue;
    }
    final fromId = raw['id']?.toString();
    if (fromId == null || fromId.isEmpty) {
      continue;
    }
    if (!nodeById.containsKey(fromId)) {
      continue;
    }

    final relations = raw['relationList'] ?? raw['relations'];
    if (relations is! List) {
      continue;
    }

    for (final rel in relations) {
      if (rel is! Map) {
        continue;
      }
      final type = rel['type'];
      final typeStr = type?.toString().toUpperCase();
      final isReference = typeStr == 'REFERENCE' || type == 1;
      if (!isReference) {
        continue;
      }

      final relFrom = rel['memoId']?.toString();
      final relTo = rel['relatedMemoId']?.toString();
      if (relFrom == null || relTo == null) {
        continue;
      }
      if (!nodeById.containsKey(relFrom) || !nodeById.containsKey(relTo)) {
        continue;
      }

      final key = '$relFrom->$relTo';
      if (processedEdges.contains(key)) {
        continue;
      }
      processedEdges.add(key);

      edges.add({'from': relFrom, 'to': relTo});
      nodeById[relFrom]!['outgoingCount'] =
          (nodeById[relFrom]!['outgoingCount'] as int) + 1;
      nodeById[relTo]!['incomingCount'] =
          (nodeById[relTo]!['incomingCount'] as int) + 1;
    }
  }

  return {
    'nodes': nodeById.values.toList(growable: false),
    'edges': edges,
  };
}

String _extractTitle(String content) {
  final lines = content.split('\n');
  final firstLine = lines.isNotEmpty ? lines[0].trim() : 'Untitled';

  var title = firstLine
      .replaceAll(RegExp(r'^#+\s*'), '')
      .replaceAll(RegExp(r'\*\*'), '')
      .replaceAll(RegExp(r'\*'), '')
      .replaceAll(RegExp('`'), '')
      .trim();

  if (title.isEmpty) {
    title = content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }
  return title.length > 50 ? '${title.substring(0, 50)}...' : title;
}
