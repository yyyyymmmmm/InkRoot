import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
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
  String? _selectedNodeId;
  String _searchQuery = '';
  bool _initialZoomDone = false;
  bool _showIsolatedNodes = false;
  Size _lastViewportSize = Size.zero;

  // 节点位置映射
  final Map<String, Offset> _nodePositions = {};
  final Set<String> _connectedNodeIds = {};
  final Set<String> _highlightedNodeIds = {};
  final Set<String> _highlightedEdgeKeys = {};

  // 🔧 跟踪笔记数量和引用关系数量，用于检测数据变化
  int _lastNoteCount = 0;
  int _lastRelationCount = 0;
  int _buildGeneration = 0;

  // 缓存图谱数据，避免在 build() 里做重计算
  List<GraphNode> _graphNodes = const [];
  List<GraphNode> _visibleGraphNodes = const [];
  List<GraphEdge> _graphEdges = const [];
  Rect _graphBounds = Rect.zero;
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
    final generation = ++_buildGeneration;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notes = appProvider.notes;

    if (notes.isEmpty) {
      setState(() {
        _graphNodes = const [];
        _visibleGraphNodes = const [];
        _graphEdges = const [];
        _nodePositions.clear();
        _connectedNodeIds.clear();
        _highlightedNodeIds.clear();
        _highlightedEdgeKeys.clear();
        _selectedNodeId = null;
        _graphBounds = Rect.zero;
        _isBuildingGraph = false;
      });
      return;
    }

    final q = _searchQuery.trim().toLowerCase();
    final inputNotes = notes.where((note) {
      final tagMatched =
          _selectedTag == null || note.tags.contains(_selectedTag);
      final queryMatched = q.isEmpty ||
          note.content.toLowerCase().contains(q) ||
          note.tags.any((tag) => tag.toLowerCase().contains(q));
      return tagMatched && queryMatched;
    }).toList(growable: false);

    if (mounted) {
      setState(() {
        _isBuildingGraph = true;
      });
    }

    // 在 isolate 里构建 nodes/edges（避免主线程掉帧）
    final payload = await compute(
      buildGraphPayload,
      {
        'notes': inputNotes
            .map(
              (note) => {
                'id': note.id,
                'content': note.content,
                'tags': note.tags,
                'relations': note.relations,
                'pinned': note.isPinned,
              },
            )
            .toList(growable: false),
      },
    );

    if (!mounted || generation != _buildGeneration) {
      return;
    }

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
        _visibleGraphNodes = const [];
        _graphEdges = const [];
        _nodePositions.clear();
        _connectedNodeIds.clear();
        _highlightedNodeIds.clear();
        _highlightedEdgeKeys.clear();
        _selectedNodeId = null;
        _graphBounds = Rect.zero;
        _isBuildingGraph = false;
      });
      return;
    }

    final connectedNodeIds = <String>{};
    for (final edge in graphEdges) {
      connectedNodeIds.add(edge.from);
      connectedNodeIds.add(edge.to);
    }

    final visibleNodes = graphNodes
        .where(
          (node) => _showIsolatedNodes || connectedNodeIds.contains(node.id),
        )
        .toList(growable: false);

    _nodePositions.clear();
    _nodePositions.addAll(
      _calculateGraphLayout(
        visibleNodes.isEmpty ? graphNodes : visibleNodes,
        graphEdges,
        connectedNodeIds,
      ),
    );

    final selectedStillVisible =
        _selectedNodeId != null && _nodePositions.containsKey(_selectedNodeId);
    final bounds = _calculateGraphBounds(_nodePositions.values);

    setState(() {
      _graphNodes = graphNodes;
      _visibleGraphNodes = visibleNodes;
      _graphEdges = graphEdges;
      _connectedNodeIds
        ..clear()
        ..addAll(connectedNodeIds);
      _graphBounds = bounds;
      if (!selectedStillVisible) {
        _selectedNodeId = null;
      }
      _updateHighlights();
      _isBuildingGraph = false;
    });

    if (!_initialZoomDone) {
      _initialZoomDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitGraphToViewport();
        }
      });
    }
  }

  Map<String, Offset> _calculateGraphLayout(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    Set<String> connectedNodeIds,
  ) {
    const center = Offset(1200, 1200);
    final positions = <String, Offset>{};
    if (nodes.isEmpty) {
      return positions;
    }

    final degreeById = <String, int>{
      for (final node in nodes)
        node.id: node.incomingCount + node.outgoingCount,
    };
    final connectedNodes = nodes
        .where((node) => connectedNodeIds.contains(node.id))
        .toList(growable: false)
      ..sort((a, b) {
        final degreeCompare = (degreeById[b.id] ?? 0).compareTo(
          degreeById[a.id] ?? 0,
        );
        return degreeCompare != 0 ? degreeCompare : a.id.compareTo(b.id);
      });
    final isolatedNodes = nodes
        .where((node) => !connectedNodeIds.contains(node.id))
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));

    if (connectedNodes.isEmpty) {
      _placeRadialNodes(isolatedNodes, positions, center, 260, 90);
      return positions;
    }

    final hubs = connectedNodes.take(math.min(8, connectedNodes.length));
    var hubIndex = 0;
    for (final node in hubs) {
      final angle = _stableAngle(node.id, salt: 3);
      final radius = hubIndex == 0 ? 0.0 : 110 + hubIndex * 18;
      positions[node.id] = center +
          Offset(
            radius * math.cos(angle),
            radius * math.sin(angle),
          );
      hubIndex++;
    }

    final remaining = connectedNodes.skip(hubIndex).toList(growable: false);
    final ringCount = math.max(1, (remaining.length / 28).ceil());
    for (var ring = 0; ring < ringCount; ring++) {
      final start = ring * 28;
      final end = math.min(start + 28, remaining.length);
      final ringNodes = remaining.sublist(start, end);
      final radius = 250.0 + ring * 165.0;
      _placeRadialNodes(
        ringNodes,
        positions,
        center,
        radius,
        28,
        salt: ring + 11,
      );
    }

    if (_showIsolatedNodes && isolatedNodes.isNotEmpty) {
      final outerRadius = 250.0 + ringCount * 165.0 + 160.0;
      _placeRadialNodes(
        isolatedNodes,
        positions,
        center,
        outerRadius,
        48,
        salt: 29,
      );
    }

    return positions;
  }

  void _placeRadialNodes(
    List<GraphNode> nodes,
    Map<String, Offset> positions,
    Offset center,
    double baseRadius,
    int nodesPerRing, {
    int salt = 0,
  }) {
    if (nodes.isEmpty) {
      return;
    }
    for (var i = 0; i < nodes.length; i++) {
      final ring = i ~/ nodesPerRing;
      final indexInRing = i % nodesPerRing;
      final countInRing =
          math.min(nodesPerRing, nodes.length - ring * nodesPerRing);
      final radius = baseRadius + ring * 92;
      final offsetAngle = _stableAngle(nodes[i].id, salt: salt) * 0.08;
      final angle = -math.pi / 2 +
          (indexInRing * 2 * math.pi / math.max(1, countInRing)) +
          offsetAngle;
      positions[nodes[i].id] = center +
          Offset(
            radius * math.cos(angle),
            radius * math.sin(angle),
          );
    }
  }

  double _stableAngle(String id, {int salt = 0}) {
    var hash = 0x811c9dc5 ^ salt;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return (hash % 3600) / 3600 * 2 * math.pi;
  }

  Rect _calculateGraphBounds(Iterable<Offset> positions) {
    final iterator = positions.iterator;
    if (!iterator.moveNext()) {
      return Rect.zero;
    }
    var minX = iterator.current.dx;
    var maxX = iterator.current.dx;
    var minY = iterator.current.dy;
    var maxY = iterator.current.dy;
    while (iterator.moveNext()) {
      final point = iterator.current;
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    return Rect.fromLTRB(minX - 160, minY - 160, maxX + 160, maxY + 160);
  }

  void _fitGraphToViewport() {
    if (_graphBounds.isEmpty || _lastViewportSize == Size.zero) {
      return;
    }

    final viewport = _lastViewportSize;
    final scaleX = viewport.width / _graphBounds.width;
    final scaleY = viewport.height / _graphBounds.height;
    final scale =
        math.min(1.25, math.max(0.22, math.min(scaleX, scaleY) * 0.86));
    final dx = viewport.width / 2 - _graphBounds.center.dx * scale;
    final dy = viewport.height / 2 - _graphBounds.center.dy * scale;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _selectNode(String? nodeId) {
    setState(() {
      _selectedNodeId = nodeId;
      _updateHighlights();
    });
  }

  void _updateHighlights() {
    _highlightedNodeIds.clear();
    _highlightedEdgeKeys.clear();
    final selectedId = _selectedNodeId;
    if (selectedId == null) {
      return;
    }
    _highlightedNodeIds.add(selectedId);
    for (final edge in _graphEdges) {
      if (edge.from == selectedId || edge.to == selectedId) {
        _highlightedNodeIds.add(edge.from);
        _highlightedNodeIds.add(edge.to);
        _highlightedEdgeKeys.add(_edgeKey(edge));
      }
    }
  }

  String _edgeKey(GraphEdge edge) => '${edge.from}->${edge.to}';

  GraphNode? _findNode(String id) {
    for (final node in _graphNodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  GraphNode? _hitTestNode(Offset scenePoint) {
    GraphNode? nearest;
    var nearestDistance = double.infinity;
    for (final node in _visibleGraphNodes) {
      final position = _nodePositions[node.id];
      if (position == null) {
        continue;
      }
      final distance = (scenePoint - position).distance;
      final radius = _nodeRadius(node) + 12;
      if (distance <= radius && distance < nearestDistance) {
        nearest = node;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  double _nodeRadius(GraphNode node) {
    final degree = node.incomingCount + node.outgoingCount;
    return (5.4 +
            math.sqrt(math.max(0, degree)) * 2.2 +
            (node.isPinned ? 2 : 0))
        .clamp(5.4, 16.0);
  }

  int get _isolatedCount =>
      _graphNodes.where((node) => !_connectedNodeIds.contains(node.id)).length;

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
          IconButton(
            tooltip: _showIsolatedNodes
                ? AppLocalizationsSimple.of(context)?.graphHideIsolated ??
                    '隐藏孤立点'
                : AppLocalizationsSimple.of(context)?.graphShowIsolated ??
                    '显示孤立点',
            icon: Icon(
              _showIsolatedNodes
                  ? Icons.scatter_plot_rounded
                  : Icons.scatter_plot_outlined,
              color: _showIsolatedNodes
                  ? (isDarkMode
                      ? AppTheme.primaryLightColor
                      : AppTheme.primaryColor)
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
            onPressed: () {
              setState(() {
                _showIsolatedNodes = !_showIsolatedNodes;
                _selectedNodeId = null;
              });
              _rebuildGraphAndLayout();
            },
          ),
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
            tooltip:
                AppLocalizationsSimple.of(context)?.graphResetView ?? '适配视图',
            icon: Icon(
              Icons.center_focus_strong_rounded,
              color: isDarkMode
                  ? AppTheme.primaryLightColor
                  : AppTheme.primaryColor,
            ),
            onPressed: _fitGraphToViewport,
          ),
        ],
      ),
      body: _graphNodes.isEmpty && _isBuildingGraph
          ? Center(
              child: _buildLoadingIndicator(context),
            )
          : _graphNodes.isEmpty
              ? _buildEmptyState()
              : _buildGraphBody(isDarkMode),
    );
  }

  Widget _buildGraphBody(bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFFAFAF8);
    final selectedNode =
        _selectedNodeId == null ? null : _findNode(_selectedNodeId!);

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastViewportSize = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: backgroundColor,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(900),
                  minScale: 0.18,
                  maxScale: 3.2,
                  constrained: false,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      _selectNode(_hitTestNode(details.localPosition)?.id);
                    },
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 2400,
                        height: 2400,
                        child: CustomPaint(
                          painter: GraphPainter(
                            nodes: _visibleGraphNodes,
                            edges: _graphEdges,
                            nodePositions: _nodePositions,
                            selectedNodeId: _selectedNodeId,
                            highlightedNodeIds: _highlightedNodeIds,
                            highlightedEdgeKeys: _highlightedEdgeKeys,
                            connectedNodeIds: _connectedNodeIds,
                            searchQuery: _searchQuery,
                            isDarkMode: isDarkMode,
                            nodeRadiusResolver: _nodeRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 12,
              child: _buildGraphStatusBar(isDarkMode),
            ),
            if (_isBuildingGraph)
              Positioned(
                top: 62,
                right: 16,
                child: _buildLoadingBadge(context),
              ),
            Positioned(
              right: 14,
              bottom: selectedNode == null
                  ? 20 + MediaQuery.of(context).padding.bottom
                  : 188 + MediaQuery.of(context).padding.bottom,
              child: _buildZoomControls(isDarkMode),
            ),
            if (_visibleGraphNodes.isEmpty && !_showIsolatedNodes)
              Center(
                child: _buildNoConnectionsState(context, isDarkMode),
              ),
            if (selectedNode != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
                child: _buildSelectedNodePanel(
                  selectedNode,
                  isDarkMode,
                  l10n,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGraphStatusBar(bool isDarkMode) {
    final visibleCount = _visibleGraphNodes.length;
    final relationCount = _graphEdges.length;
    final selectedText = _selectedTag == null ? '全部' : '#$_selectedTag';
    final textColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildGraphPill(
          '$visibleCount / ${_graphNodes.length} 节点',
          isDarkMode,
        ),
        _buildGraphPill('$relationCount 引用', isDarkMode),
        _buildGraphPill(selectedText, isDarkMode),
        if (!_showIsolatedNodes && _isolatedCount > 0)
          _buildGraphPill('隐藏 $_isolatedCount 个孤立点', isDarkMode),
        Text(
          _selectedNodeId == null ? '' : '已高亮关联',
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ],
    );
  }

  Widget _buildGraphPill(String text, bool isDarkMode) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppTheme.darkCardColor.withValues(alpha: 0.86)
              : Colors.white.withValues(alpha: 0.92),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : const Color(0xFFE7E8E3),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.1,
              color: isDarkMode
                  ? AppTheme.darkTextSecondaryColor
                  : AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildZoomControls(bool isDarkMode) {
    final surfaceColor = isDarkMode
        ? AppTheme.darkCardColor.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.95);
    final iconColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFE4E6E0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.22 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '放大',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add_rounded, color: iconColor),
            onPressed: () => _zoomGraph(1.22),
          ),
          SizedBox(
            width: 28,
            child: Divider(
              height: 1,
              color: borderColor,
            ),
          ),
          IconButton(
            tooltip: '缩小',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove_rounded, color: iconColor),
            onPressed: () => _zoomGraph(1 / 1.22),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedNodePanel(
    GraphNode node,
    bool isDarkMode,
    AppLocalizationsSimple? l10n,
  ) {
    final surfaceColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFE4E6E0);
    final primary =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.24 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    node.title.isEmpty ? 'Untitled' : node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppTheme.darkTextPrimaryColor
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n?.graphClearSelection ?? '清除选择',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, color: secondaryColor),
                  onPressed: () => _selectNode(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildMetricChip('入链 ${node.incomingCount}', isDarkMode),
                _buildMetricChip('出链 ${node.outgoingCount}', isDarkMode),
                if (node.isPinned) _buildMetricChip('置顶', isDarkMode),
                ...node.tags
                    .take(3)
                    .map((tag) => _buildMetricChip('#$tag', isDarkMode)),
              ],
            ),
            if (node.content.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _previewContent(node.content),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.42,
                  color: secondaryColor,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NoteDetailScreen(noteId: node.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(l10n?.graphOpenNote ?? '打开笔记'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () {
                    _focusSelectedNode(node.id);
                  },
                  icon: const Icon(Icons.center_focus_strong_rounded, size: 17),
                  label: Text(l10n?.graphFocusNode ?? '聚焦关联'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String text, bool isDarkMode) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white10 : const Color(0xFFF4F5F1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.15,
              color: isDarkMode
                  ? AppTheme.darkTextSecondaryColor
                  : AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildLoadingIndicator(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizationsSimple.of(context)?.graphBuilding ?? '正在整理图谱',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );

  Widget _buildLoadingBadge(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkCardColor.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white12
                : const Color(0xFFE4E6E0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
              const SizedBox(width: 7),
              Text(
                AppLocalizationsSimple.of(context)?.graphBuilding ?? '正在整理图谱',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget _buildNoConnectionsState(BuildContext context, bool isDarkMode) {
    final l10n = AppLocalizationsSimple.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 42,
            color: isDarkMode ? Colors.white24 : const Color(0xFFB7BBAF),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.graphNoConnections ?? '还没有引用关系',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? AppTheme.darkTextPrimaryColor
                  : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _showIsolatedNodes = true;
              });
              _rebuildGraphAndLayout();
            },
            child: Text(l10n?.graphShowIsolated ?? '显示孤立点'),
          ),
        ],
      ),
    );
  }

  String _previewContent(String content) {
    final text = content
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp('<[^>]+>'), '')
        .replaceAll(RegExp('[#*_`~>-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= 96) {
      return text;
    }
    return '${text.substring(0, 96)}...';
  }

  void _focusSelectedNode(String nodeId) {
    final position = _nodePositions[nodeId];
    if (position == null || _lastViewportSize == Size.zero) {
      return;
    }
    final scale = _transformationController.value.getMaxScaleOnAxis().clamp(
          0.55,
          1.45,
        );
    final dx = _lastViewportSize.width / 2 - position.dx * scale;
    final dy = _lastViewportSize.height / 2 - position.dy * scale;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _zoomGraph(double factor) {
    if (_lastViewportSize == Size.zero) {
      return;
    }
    final matrix = _transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.18, 3.2);
    final actualFactor = targetScale / currentScale;
    final focalPoint = Offset(
      _lastViewportSize.width / 2,
      _lastViewportSize.height / 2,
    );

    _transformationController.value = matrix
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..scaleByDouble(actualFactor, actualFactor, actualFactor, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);
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
    required this.selectedNodeId,
    required this.highlightedNodeIds,
    required this.highlightedEdgeKeys,
    required this.connectedNodeIds,
    required this.searchQuery,
    required this.isDarkMode,
    required this.nodeRadiusResolver,
  });
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, Offset> nodePositions;
  final String? selectedNodeId;
  final Set<String> highlightedNodeIds;
  final Set<String> highlightedEdgeKeys;
  final Set<String> connectedNodeIds;
  final String searchQuery;
  final bool isDarkMode;
  final double Function(GraphNode node) nodeRadiusResolver;

  @override
  void paint(Canvas canvas, Size size) {
    final hasSelection = selectedNodeId != null;
    final edgePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final nodeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final edge in edges) {
      final fromPos = nodePositions[edge.from];
      final toPos = nodePositions[edge.to];
      if (fromPos == null || toPos == null) {
        continue;
      }

      final key = '${edge.from}->${edge.to}';
      final highlighted = highlightedEdgeKeys.contains(key);
      final alpha = hasSelection ? (highlighted ? 0.76 : 0.08) : 0.28;
      edgePaint
        ..strokeWidth = highlighted ? 1.55 : 0.85
        ..color = _edgeColor(highlighted).withValues(alpha: alpha);
      canvas.drawLine(fromPos, toPos, edgePaint);

      if (highlighted) {
        _drawArrow(canvas, fromPos, toPos, arrowPaint);
      }
    }

    for (final node in nodes) {
      final position = nodePositions[node.id];
      if (position == null) {
        continue;
      }

      final selected = node.id == selectedNodeId;
      final highlighted =
          !hasSelection || highlightedNodeIds.contains(node.id) || selected;
      final queryMatched = searchQuery.trim().isNotEmpty &&
          (node.title
                  .toLowerCase()
                  .contains(searchQuery.trim().toLowerCase()) ||
              node.tags.any(
                (tag) => tag.toLowerCase().contains(
                      searchQuery.trim().toLowerCase(),
                    ),
              ));
      final radius = nodeRadiusResolver(node);
      final color = _nodeColor(node);
      final alpha = highlighted ? 1.0 : 0.18;

      if (selected || queryMatched) {
        nodePaint.color = color.withValues(alpha: selected ? 0.18 : 0.11);
        canvas.drawCircle(position, radius + (selected ? 8 : 5), nodePaint);
      }

      nodePaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(position, radius, nodePaint);

      nodeStrokePaint.color = (selected ? color : _nodeStrokeColor())
          .withValues(alpha: selected ? 0.95 : (highlighted ? 0.42 : 0.16));
      nodeStrokePaint.strokeWidth = selected ? 2 : 1.1;
      canvas.drawCircle(position, radius + 0.6, nodeStrokePaint);
    }

    _paintLabels(canvas);
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.edges != edges ||
      oldDelegate.nodePositions != nodePositions ||
      oldDelegate.selectedNodeId != selectedNodeId ||
      oldDelegate.highlightedNodeIds != highlightedNodeIds ||
      oldDelegate.highlightedEdgeKeys != highlightedEdgeKeys ||
      oldDelegate.connectedNodeIds != connectedNodeIds ||
      oldDelegate.searchQuery != searchQuery ||
      oldDelegate.isDarkMode != isDarkMode;

  Color _edgeColor(bool highlighted) {
    if (highlighted) {
      return isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    }
    return isDarkMode ? const Color(0xFF5E625E) : const Color(0xFFADB3AA);
  }

  Color _nodeColor(GraphNode node) {
    if (node.isPinned) {
      return isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    }
    if (!connectedNodeIds.contains(node.id)) {
      return isDarkMode ? const Color(0xFF767A75) : const Color(0xFFB6BBAF);
    }
    if (node.tags.isEmpty) {
      return isDarkMode ? const Color(0xFFB4B8B2) : const Color(0xFF71786F);
    }
    final palette = isDarkMode
        ? const [
            Color(0xFF83CBB7),
            Color(0xFFB8C98A),
            Color(0xFF9BB8DD),
            Color(0xFFD7B06F),
            Color(0xFFC99AC3),
          ]
        : const [
            Color(0xFF2C9678),
            Color(0xFF6A8F3F),
            Color(0xFF4E78A8),
            Color(0xFFB57A33),
            Color(0xFF9A6794),
          ];
    final hash = node.tags.first.hashCode.abs();
    return palette[hash % palette.length];
  }

  Color _nodeStrokeColor() =>
      isDarkMode ? const Color(0xFF1F2420) : Colors.white;

  void _drawArrow(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint,
  ) {
    final direction = to - from;
    final distance = direction.distance;
    if (distance < 28) {
      return;
    }
    final unit = direction / distance;
    final tip = to - unit * 14;
    final normal = Offset(-unit.dy, unit.dx);
    final p1 = tip - unit * 8 + normal * 4;
    final p2 = tip - unit * 8 - normal * 4;
    paint
      ..strokeWidth = 1.25
      ..color =
          (isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor)
              .withValues(alpha: 0.72);
    canvas
      ..drawLine(tip, p1, paint)
      ..drawLine(tip, p2, paint);
  }

  void _paintLabels(Canvas canvas) {
    final labelNodes = nodes.where((node) {
      final selected = node.id == selectedNodeId;
      final highlighted = highlightedNodeIds.contains(node.id);
      final important =
          node.isPinned || node.incomingCount + node.outgoingCount >= 2;
      final queryMatched = searchQuery.trim().isNotEmpty &&
          (node.title
                  .toLowerCase()
                  .contains(searchQuery.trim().toLowerCase()) ||
              node.tags.any(
                (tag) => tag.toLowerCase().contains(
                      searchQuery.trim().toLowerCase(),
                    ),
              ));
      return selected || highlighted || important || queryMatched;
    }).take(72);

    for (final node in labelNodes) {
      final position = nodePositions[node.id];
      if (position == null || node.title.trim().isEmpty) {
        continue;
      }
      final selected = node.id == selectedNodeId;
      final radius = nodeRadiusResolver(node);
      final text = node.title.length > 18
          ? '${node.title.substring(0, 18)}...'
          : node.title;
      final style = TextStyle(
        color: isDarkMode
            ? Colors.white.withValues(alpha: selected ? 0.96 : 0.78)
            : const Color(0xFF29302B).withValues(alpha: selected ? 0.96 : 0.74),
        fontSize: selected ? 12.5 : 11,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        height: 1.2,
      );
      final span = TextSpan(text: text, style: style);
      final painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: selected ? 150 : 116);
      final offset = Offset(
        position.dx - painter.width / 2,
        position.dy + radius + 6,
      );
      painter.paint(canvas, offset);
    }
  }
}
