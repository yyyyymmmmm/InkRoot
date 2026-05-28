import 'package:inkroot/models/note_model.dart';

/// 知识图谱数据服务
/// 处理笔记关系数据，转换为图谱可视化所需的节点和边数据
class GraphDataService {
  /// 从笔记列表构建图谱数据
  /// 返回 {nodes: List<GraphNode>, edges: List<GraphEdge>}
  static Map<String, dynamic> buildGraphData(
    List<Note> notes, {
    int maxDepth = 2,
  }) {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];
    final processedNotes = <String>{};

    // 为每个笔记创建节点
    for (final note in notes) {
      if (!processedNotes.contains(note.id)) {
        nodes.add(
          GraphNode(
            id: note.id,
            title: _extractTitle(note.content),
            content: note.content,
            tags: note.tags,
            outgoingCount: _countOutgoingReferences(note),
            incomingCount: _countIncomingReferences(note.id, notes),
            isPinned: note.isPinned,
          ),
        );
        processedNotes.add(note.id);
      }
    }

    // 创建边（引用关系）
    final processedEdges = <String>{}; // 用于去重

    for (final note in notes) {
      for (final relation in note.relations) {
        final type = relation['type'];
        final typeStr = type?.toString().toUpperCase();

        // 只处理 REFERENCE 类型的关系（不处理 REFERENCED_BY，避免重复）
        if (typeStr == 'REFERENCE' || type == 1) {
          final fromId = relation['memoId']?.toString();
          final toId = relation['relatedMemoId']?.toString();

          if (fromId != null && toId != null) {
            // 确保两个节点都存在
            if (processedNotes.contains(fromId) &&
                processedNotes.contains(toId)) {
              final edgeKey = '$fromId->$toId';
              if (!processedEdges.contains(edgeKey)) {
                edges.add(
                  GraphEdge(
                    from: fromId,
                    to: toId,
                  ),
                );
                processedEdges.add(edgeKey);
              }
            }
          }
        }
      }
    }

    return {
      'nodes': nodes,
      'edges': edges,
    };
  }

  /// 获取指定笔记的子图（只包含相关联的笔记）
  static Map<String, dynamic> buildSubGraph(
    String centerNoteId,
    List<Note> allNotes, {
    int depth = 1,
  }) {
    final relatedNoteIds = <String>{centerNoteId};
    final processedIds = <String>{};

    // BFS 搜索相关笔记
    var currentLevel = {centerNoteId};
    for (var d = 0; d < depth; d++) {
      final nextLevel = <String>{};

      for (final noteId in currentLevel) {
        if (processedIds.contains(noteId)) continue;
        processedIds.add(noteId);

        final note = allNotes.firstWhere(
          (n) => n.id == noteId,
          orElse: () => allNotes.first,
        );

        // 查找所有相关笔记
        for (final relation in note.relations) {
          final type = relation['type'];
          if (type == 'REFERENCE' || type == 1 || type == 'REFERENCED_BY') {
            final fromId = relation['memoId']?.toString();
            final toId = relation['relatedMemoId']?.toString();

            if (fromId == noteId && toId != null) {
              relatedNoteIds.add(toId);
              nextLevel.add(toId);
            } else if (toId == noteId && fromId != null) {
              relatedNoteIds.add(fromId);
              nextLevel.add(fromId);
            }
          }
        }
      }

      currentLevel = nextLevel;
    }

    // 只保留相关笔记
    final relatedNotes =
        allNotes.where((n) => relatedNoteIds.contains(n.id)).toList();
    return buildGraphData(relatedNotes);
  }

  /// 按标签筛选笔记
  static Map<String, dynamic> buildGraphByTag(
    String tag,
    List<Note> allNotes,
  ) {
    final filteredNotes = allNotes.where((n) => n.tags.contains(tag)).toList();
    return buildGraphData(filteredNotes);
  }

  /// 提取笔记标题（第一行，最多50字符）
  static String _extractTitle(String content) {
    final lines = content.split('\n');
    final firstLine = lines.isNotEmpty ? lines[0].trim() : 'Untitled'; // 无标题

    // 移除 Markdown 标记
    var title = firstLine
        .replaceAll(RegExp(r'^#+\s*'), '') // 移除标题标记
        .replaceAll(RegExp(r'\*\*'), '') // 移除粗体
        .replaceAll(RegExp(r'\*'), '') // 移除斜体
        .replaceAll(RegExp('`'), '') // 移除代码标记
        .trim();

    if (title.isEmpty) {
      title = content.length > 50 ? '${content.substring(0, 50)}...' : content;
    }

    return title.length > 50 ? '${title.substring(0, 50)}...' : title;
  }

  /// 统计出链数量
  static int _countOutgoingReferences(Note note) => note.relations.where((rel) {
        final type = rel['type'];
        final fromId = rel['memoId']?.toString();
        return (type == 'REFERENCE' || type == 1) && fromId == note.id;
      }).length;

  /// 统计入链数量
  static int _countIncomingReferences(String noteId, List<Note> allNotes) {
    var count = 0;
    for (final note in allNotes) {
      for (final relation in note.relations) {
        final type = relation['type'];
        final toId = relation['relatedMemoId']?.toString();
        if ((type == 'REFERENCE' || type == 1) && toId == noteId) {
          count++;
        }
      }
    }
    return count;
  }
}

/// 图节点数据模型
class GraphNode {
  GraphNode({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    this.outgoingCount = 0,
    this.incomingCount = 0,
    this.isPinned = false,
  });
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final int outgoingCount; // 出链数
  final int incomingCount; // 入链数
  final bool isPinned;

  /// 节点重要性（用于确定节点大小）
  int get importance => outgoingCount + incomingCount * 2;
}

/// 图边数据模型
class GraphEdge {
  GraphEdge({
    required this.from,
    required this.to,
    this.type = 'reference',
  });
  final String from;
  final String to;
  final String type;
}
