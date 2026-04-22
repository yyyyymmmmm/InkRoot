// 🚀 性能监控看板
// 用于查看应用性能指标

import 'package:flutter/material.dart';
import 'package:inkroot/services/performance_monitor_service.dart';
import 'package:inkroot/services/observability_service.dart';

class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends State<PerformanceDashboardScreen> {
  Map<String, dynamic> _performanceReport = {};
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _performanceReport = PerformanceMonitorService().getPerformanceReport();
      _logs = StructuredLogger().getLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPerformanceSection(),
          const SizedBox(height: 24),
          _buildLogsSection(),
          const SizedBox(height: 24),
          _buildTracingSection(),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '性能指标',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            
            // FPS
            _buildMetricRow(
              '当前FPS',
              '${_performanceReport['current_fps']?.toStringAsFixed(1) ?? '--'}',
              _getFpsColor(_performanceReport['current_fps']),
            ),
            
            // 各类操作平均耗时
            ..._buildMetricsList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetricsList() {
    final metrics = <Widget>[];
    
    _performanceReport.forEach((key, value) {
      if (key == 'current_fps') return;
      if (value is! Map) return;
      
      final avgMs = value['avg_ms'] as num?;
      if (avgMs == null) return;
      
      final label = _formatMetricName(key);
      metrics.add(_buildMetricRow(
        label,
        '${avgMs.toStringAsFixed(0)}ms',
        _getDurationColor(avgMs.toInt()),
      ));
    });
    
    return metrics;
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    final errorLogs = _logs.where((log) => log['level'] == 'ERROR').toList();
    final warningLogs = _logs.where((log) => log['level'] == 'WARNING').toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '日志统计',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            
            _buildLogStatRow('错误', errorLogs.length, Colors.red),
            _buildLogStatRow('警告', warningLogs.length, Colors.orange),
            _buildLogStatRow('总计', _logs.length, Colors.blue),
            
            const SizedBox(height: 16),
            
            // 最近的错误
            if (errorLogs.isNotEmpty) ...[
              const Text('最近错误:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...errorLogs.take(3).map((log) => _buildLogItem(log)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log['message'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            log['timestamp'] as String,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracingSection() {
    final spans = TracingService().getCompletedSpans();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '链路追踪',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            
            Text('最近操作: ${spans.length}个'),
            const SizedBox(height: 16),
            
            ...spans.take(10).map((span) {
              return _buildSpanItem(span);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSpanItem(Span span) {
    final duration = span.duration?.inMilliseconds ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              span.operationName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${duration}ms',
            style: TextStyle(
              color: _getDurationColor(duration),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFpsColor(dynamic fps) {
    if (fps == null) return Colors.grey;
    final fpsValue = fps as double;
    
    if (fpsValue >= 55) return Colors.green;
    if (fpsValue >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getDurationColor(int ms) {
    if (ms < 100) return Colors.green;
    if (ms < 500) return Colors.orange;
    return Colors.red;
  }

  String _formatMetricName(String key) {
    final nameMap = {
      'MetricType.appLaunch': '应用启动',
      'MetricType.pageLoad': '页面加载',
      'MetricType.networkRequest': '网络请求',
      'MetricType.databaseQuery': '数据库查询',
      'MetricType.imageLoad': '图片加载',
    };
    
    return nameMap[key] ?? key.split('.').last;
  }
}

