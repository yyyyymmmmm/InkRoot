import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:inkroot/services/graph_data_service.dart';
import 'package:inkroot/services/graph_isolate_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:provider/provider.dart';

class KnowledgeGraphScreenCustom extends StatefulWidget {
  const KnowledgeGraphScreenCustom({super.key});

  @override
  State<KnowledgeGraphScreenCustom> createState() =>
      _KnowledgeGraphScreenCustomState();
}

class _KnowledgeGraphScreenCustomState
    extends State<KnowledgeGraphScreenCustom> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedTag;
  String _searchQuery = '';
  bool _initialZoomDone = false;

  // 节点位置映射
  final Map<String, Offset> _nodePositions = {};

  // 🔧 跟踪笔记数量和引用关系数量，用于检测数据变化
  int _lastNoteCount = 0;
  int _lastRelationCount = 0;

  // 缓存图谱数据，避免在 build() 里做重计算
  List<GraphNode> _graphNodes = const [];
  List<GraphEdge> _graphEdges = const [];
  bool _isBuildingGraph = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildGraphAndLayout();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 构建图谱数据 + 计算节点位置（从 build() 挪出去，避免切换路由时掉帧）
  void _scheduleRebuildGraphAndLayout() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        _rebuildGraphAndLayout();
      }
    });
  }

  Future<void> _rebuildGraphAndLayout() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notes = appProvider.notes;

    if (notes.isEmpty) {
      setState(() {
        _graphNodes = const [];
        _graphEdges = const [];
        _nodePositions.clear();
      });
      return;
    }

    // 过滤候选 notes（搜索/标签）
    final List<Note> inputNotes;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      inputNotes =
          notes.where((n) => n.content.toLowerCase().contains(q)).toList();
    } else if (_selectedTag != null) {
      inputNotes = notes.where((n) => n.tags.contains(_selectedTag)).toList();
    } else {
      inputNotes = notes;
    }

    setState(() {
      _isBuildingGraph = true;
    });

    // 在 isolate 里构建 nodes/edges（避免主线程掉帧）
    final payload = await compute(
      buildGraphPayload,
      {
        'notes': inputNotes.map((n) => n.toJson()).toList(growable: false),
      },
    );

    final rawNodes = (payload['nodes'] as List?) ?? const [];
    final rawEdges = (payload['edges'] as List?) ?? const [];

    final graphNodes = rawNodes
        .whereType<Map>()
        .map(
          (m) => GraphNode(
            id: m['id']?.toString() ?? '',
            title: m['title']?.toString() ?? '',
            content: m['content']?.toString() ?? '',
            tags:
                (m['tags'] as List?)?.whereType<String>().toList() ?? const [],
            outgoingCount: (m['outgoingCount'] as int?) ?? 0,
            incomingCount: (m['incomingCount'] as int?) ?? 0,
            isPinned: m['isPinned'] == true,
          ),
        )
        .where((n) => n.id.isNotEmpty)
        .toList();

    final graphEdges = rawEdges
        .whereType<Map>()
        .map(
          (m) => GraphEdge(
            from: m['from']?.toString() ?? '',
            to: m['to']?.toString() ?? '',
          ),
        )
        .where((e) => e.from.isNotEmpty && e.to.isNotEmpty)
        .toList();

    if (graphNodes.isEmpty) {
      setState(() {
        _graphNodes = const [];
        _graphEdges = const [];
        _nodePositions.clear();
        _isBuildingGraph = false;
      });
      return;
    }

    // 画布中心
    const double centerX = 1500;
    const double centerY = 1500;

    // 分离有连接的节点和孤立节点
    final connectedNodeIds = <String>{};
    for (final edge in graphEdges) {
      connectedNodeIds.add(edge.from);
      connectedNodeIds.add(edge.to);
    }

    final connectedNodes =
        graphNodes.where((n) => connectedNodeIds.contains(n.id)).toList();
    final isolatedNodes =
        graphNodes.where((n) => !connectedNodeIds.contains(n.id)).toList();

    _nodePositions.clear();

    // 1. 有连接的节点：放在中心区域（圆形布局）
    if (connectedNodes.isNotEmpty) {
      final radius = math.min(600, connectedNodes.length * 80.0);
      for (var i = 0; i < connectedNodes.length; i++) {
        final angle = (i * 2 * math.pi) / connectedNodes.length;
        final x = centerX + radius * math.cos(angle);
        final y = centerY + radius * math.sin(angle);
        _nodePositions[connectedNodes[i].id] = Offset(x, y);
      }
    }

    // 2. 孤立节点：围绕外圈随机分布（星系效果）
    if (isolatedNodes.isNotEmpty) {
      final random = math.Random();
      const outerRadius = 1000.0;

      for (var i = 0; i < isolatedNodes.length; i++) {
        // 在外圈区域随机分布
        final angle = (i * 2 * math.pi) / isolatedNodes.length +
            random.nextDouble() * 0.5;
        final r = outerRadius + random.nextDouble() * 300;
        final x = centerX + r * math.cos(angle);
        final y = centerY + r * math.sin(angle);
        _nodePositions[isolatedNodes[i].id] = Offset(x, y);
      }
    }

    // 初始缩放
    if (!_initialZoomDone) {
      _initialZoomDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nodeCount = graphNodes.length;
        var initialScale = 0.3;
        if (nodeCount > 100) {
          initialScale = 0.15;
        } else if (nodeCount > 50) {
          initialScale = 0.2;
        } else if (nodeCount > 20) {
          initialScale = 0.25;
        }
        _transformationController.value = Matrix4.identity()
          ..scaleByDouble(initialScale, initialScale, initialScale, 1);
      });
    }

    setState(() {
      _graphNodes = graphNodes;
      _graphEdges = graphEdges;
      _isBuildingGraph = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context);
    final notes = appProvider.notes;

    // 🔧 检测数据变化时重新计算节点位置（仅在真正变化时触发一次）
    final currentRelationCount =
        notes.fold<int>(0, (sum, note) => sum + note.relations.length);
    final dataChanged = notes.length != _lastNoteCount ||
        currentRelationCount != _lastRelationCount;

    if (dataChanged) {
      _lastNoteCount = notes.length;
      _lastRelationCount = currentRelationCount;
      // 使用 post-frame 触发一次重建，避免在 build 内做大量计算
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleRebuildGraphAndLayout();
        }
      });
    }

    final allTags = _getAllTags();

    final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : const Sidebar(),
      drawerEdgeDragWidth:
          isDesktop ? null : MediaQuery.of(context).size.width * 0.2,
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppTheme.primaryLightColor
                              : AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 10,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppTheme.primaryLightColor
                              : AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          // 标签筛选
          if (allTags.isNotEmpty)
            PopupMenuButton<String?>(
              icon: Icon(
                Icons.filter_list_rounded,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
              ),
              onSelected: (tag) {
                setState(() {
                  _selectedTag = tag;
                });
                _scheduleRebuildGraphAndLayout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.showAll ?? '显示全部',
                  ),
                ),
                ...allTags.map(
                  (tag) => PopupMenuItem(
                    value: tag,
                    child: Text('#$tag'),
                  ),
                ),
              ],
            ),
          // 刷新
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode
                  ? AppTheme.primaryLightColor
                  : AppTheme.primaryColor,
            ),
            onPressed: _rebuildGraphAndLayout,
          ),
          // 重置缩放
          IconButton(
            icon: Icon(
              Icons.center_focus_strong_rounded,
              color: isDarkMode
                  ? AppTheme.primaryLightColor
                  : AppTheme.primaryColor,
            ),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: _isBuildingGraph
          ? const Center(child: CircularProgressIndicator())
          : _graphNodes.isEmpty
              ? _buildEmptyState()
              : InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.1,
                  maxScale: 4,
                  constrained: false,
                  child: SizedBox(
                    width: 3000,
                    height: 3000,
                    child: CustomPaint(
                      painter: GraphPainter(
                        nodes: _graphNodes,
                        edges: _graphEdges,
                        nodePositions: _nodePositions,
                        isDarkMode: isDarkMode,
                      ),
                      child: Stack(
                        children: _graphNodes.map((node) {
                          final pos =
                              _nodePositions[node.id] ?? const Offset(0, 0);
                          return Positioned(
                            left: pos.dx - 50,
                            top: pos.dy - 50,
                            child: _buildNodeWidget(node, isDarkMode),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildNodeWidget(GraphNode node, bool isDarkMode) {
    final importance = node.incomingCount + node.outgoingCount;
    const baseSize = 80.0;
    final size = baseSize + (importance * 10.0).clamp(0.0, 40.0);
    final color = _getNodeColor(node, isDarkMode);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(noteId: node.id),
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: node.isPinned ? 3 : 2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          node.isPinned ? FontWeight.bold : FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (importance > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '↓${node.incomingCount} ↑${node.outgoingCount}',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '孤立',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(GraphNode node, bool isDarkMode) {
    if (node.tags.isEmpty) {
      return isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    }

    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.green,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    final hash = node.tags.first.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText:
              AppLocalizationsSimple.of(context)?.searchNotes ?? '搜索笔记...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _scheduleRebuildGraphAndLayout();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _scheduleRebuildGraphAndLayout();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_rounded,
            size: 80,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizationsSimple.of(context)?.noNotesYet ?? '暂无笔记',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getAllTags() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allTags = <String>{};
    for (final note in appProvider.notes) {
      allTags.addAll(note.tags);
    }
    return allTags.toList()..sort();
  }
}

/// 自定义画笔：绘制连接线
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.isDarkMode,
  });
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Offset> nodePositions;
  final bool isDarkMode;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode ? Colors.grey[700]! : Colors.grey[400]!)
          .withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 绘制所有边
    for (final edge in edges) {
      final fromPos = nodePositions[edge.from];
      final toPos = nodePositions[edge.to];

      if (fromPos != null && toPos != null) {
        canvas.drawLine(fromPos, toPos, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) => true;
}
