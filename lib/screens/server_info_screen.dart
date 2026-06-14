import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:inkroot/utils/logger.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ServerInfoScreen extends StatefulWidget {
  const ServerInfoScreen({super.key});

  @override
  State<ServerInfoScreen> createState() => _ServerInfoScreenState();
}

class _ServerInfoScreenState extends State<ServerInfoScreen> {
  final TextEditingController _serverAddressController =
      TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _useHttps = true;
  bool _isSyncing = false;
  bool _isDiagnosing = false;
  bool _isConnectionHealthy = false;
  String _connectionStatus = '';
  String _lastSyncTime = '';
  String _latency = '0 ms';
  List<LogEntry> _logs = [];

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 延迟初始化，避免在 initState 中使用 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);

        // 初始化表单数据
        _initializeFormData(appProvider);

        // 初始化日志
        _initializeLogs();

        // 如果已登录，更新连接状态
        if (appProvider.isLoggedIn) {
          _updateConnectionStatus();
          _startPeriodicStatusCheck();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // 现在可以安全使用context获取本地化文本
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.isLoggedIn) {
        setState(() {
          _connectionStatus =
              AppLocalizationsSimple.of(context)?.connected ?? '已连接';
          _lastSyncTime =
              AppLocalizationsSimple.of(context)?.notSynced ?? '未同步';

          // 更新日志中的本地化文本
          final initialMessage = AppLocalizationsSimple.of(context)
                  ?.initializingServerConnection ??
              '初始化服务器连接页面...';
          if (_logs.isNotEmpty && _logs.first.message == initialMessage) {
            _logs[0] = LogEntry(
              time: _logs[0].time,
              message: initialMessage,
              type: _logs[0].type,
            );
          }
        });
      }
    }
  }

  void _initializeFormData(AppProvider appProvider) {
    final serverUrl = appProvider.appConfig.memosApiUrl ?? '';
    if (serverUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(serverUrl);
        _serverAddressController.text = uri.host;
        _portController.text = uri.port.toString();
        _useHttps = uri.scheme == 'https';
      } on Object catch (e) {
        Log.ui.warning(
          'Failed to parse server URL',
          data: {'error': e.toString()},
        );
      }
    } else {
      _portController.text = '443';
    }
    _apiKeyController.text = appProvider.appConfig.lastToken ?? '';

    // 如果已登录，更新连接状态（延迟到didChangeDependencies）
    if (appProvider.isLoggedIn) {
      _connectionStatus = AppLocalizationsSimple.of(context)?.connected ?? '';
      _isConnectionHealthy = true;
      _updateLastSyncTime(appProvider.user?.lastSyncTime);
    }
  }

  void _updateLastSyncTime(DateTime? lastSync) {
    if (lastSync == null) {
      _lastSyncTime = AppLocalizationsSimple.of(context)?.notSynced ?? '未同步';
      return;
    }

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      _lastSyncTime = AppLocalizationsSimple.of(context)?.justNow ?? '刚刚';
    } else if (diff.inMinutes < 60) {
      _lastSyncTime =
          AppLocalizationsSimple.of(context)?.minutesAgo(diff.inMinutes) ??
              '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      _lastSyncTime =
          AppLocalizationsSimple.of(context)?.hoursAgo(diff.inHours) ??
              '${diff.inHours}小时前';
    } else {
      _lastSyncTime =
          AppLocalizationsSimple.of(context)?.daysAgo(diff.inDays) ??
              '${diff.inDays}天前';
    }
  }

  Timer? _statusCheckTimer;

  void _startPeriodicStatusCheck() {
    // 每30秒检查一次连接状态
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateConnectionStatus();
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _serverAddressController.dispose();
    _portController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _updateConnectionStatus() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.isLoggedIn) {
      return;
    }

    try {
      final response = await _pingMemosApi(appProvider);

      if (response.statusCode == 200) {
        final startTime = DateTime.now();
        await _pingMemosApi(appProvider);
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;

        if (mounted) {
          setState(() {
            _connectionStatus =
                AppLocalizationsSimple.of(context)?.connected ?? '已连接';
            _isConnectionHealthy = true;
            _latency = '$latency ms';
          });
        }
      } else {
        throw Exception('服务器响应错误: ${response.statusCode}');
      }
    } on Object {
      if (mounted) {
        setState(() {
          _connectionStatus =
              AppLocalizationsSimple.of(context)?.connectionAbnormal ?? '连接异常';
          _isConnectionHealthy = false;
          _latency = AppLocalizationsSimple.of(context)?.timeout ?? '超时';
        });
      }
    }
  }

  Future<http.Response> _pingMemosApi(AppProvider appProvider) async {
    final baseUrl = appProvider.appConfig.memosApiUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception(
        AppLocalizationsSimple.of(context)?.serverUrlEmpty ?? '服务器地址为空',
      );
    }

    final headers = {
      'Accept': 'application/json',
      if (appProvider.appConfig.lastToken != null)
        'Authorization': 'Bearer ${appProvider.appConfig.lastToken}',
    };

    http.Response? lastResponse;
    for (final path in ['/api/v1/workspace/profile', '/api/v1/status']) {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return response;
      }
      lastResponse = response;
    }

    return lastResponse!;
  }

  void _initializeLogs() {
    final now = DateTime.now();
    _logs = [];

    // 添加应用启动日志
    _logs.add(
      LogEntry(
        time: _formatTime(now),
        message:
            AppLocalizationsSimple.of(context)?.initializingServerConnection ??
                '初始化服务器连接页面...',
        type: LogType.info,
      ),
    );

    // 检查是否已登录并获取连接信息
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.isLoggedIn) {
      _logs.add(
        LogEntry(
          time: _formatTime(now.subtract(const Duration(milliseconds: 100))),
          message: AppLocalizationsSimple.of(context)?.loggedInStatusDetected ??
              '检测到已登录状态',
          type: LogType.info,
        ),
      );

      if (appProvider.appConfig.memosApiUrl != null) {
        try {
          final uri = Uri.parse(appProvider.appConfig.memosApiUrl!);
          _logs.add(
            LogEntry(
              time:
                  _formatTime(now.subtract(const Duration(milliseconds: 200))),
              message:
                  '${AppLocalizationsSimple.of(context)?.currentServer ?? '当前服务器'}: ${uri.host}:${uri.port}',
              type: LogType.info,
            ),
          );

          _logs.add(
            LogEntry(
              time:
                  _formatTime(now.subtract(const Duration(milliseconds: 300))),
              message:
                  '${AppLocalizationsSimple.of(context)?.usingProtocol ?? '使用协议'}: ${uri.scheme.toUpperCase()}',
              type: LogType.info,
            ),
          );
        } on Object catch (e) {
          _logs.add(
            LogEntry(
              time:
                  _formatTime(now.subtract(const Duration(milliseconds: 200))),
              message:
                  '${AppLocalizationsSimple.of(context)?.parseServerUrlFailed ?? '解析服务器URL失败'}: $e',
              type: LogType.error,
            ),
          );
        }
      }

      // 添加上次同步信息
      if (appProvider.user?.lastSyncTime != null) {
        final lastSync = appProvider.user!.lastSyncTime!;
        final diff = now.difference(lastSync);

        _logs.add(
          LogEntry(
            time: _formatTime(now.subtract(const Duration(milliseconds: 400))),
            message:
                '${AppLocalizationsSimple.of(context)?.lastSync ?? '上次同步'}: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(lastSync)}',
            type: LogType.info,
          ),
        );

        // 如果上次同步超过1小时，添加警告
        if (diff.inHours > 1) {
          _logs.add(
            LogEntry(
              time:
                  _formatTime(now.subtract(const Duration(milliseconds: 500))),
              message: AppLocalizationsSimple.of(context)
                      ?.syncWarning(diff.inHours) ??
                  '同步警告: 距离上次同步已超过${diff.inHours}小时',
              type: LogType.warning,
            ),
          );
        }
      }

      // 添加连接成功记录
      _logs.add(
        LogEntry(
          time: _formatTime(now.subtract(const Duration(milliseconds: 600))),
          message:
              '${AppLocalizationsSimple.of(context)?.connectionStatus ?? '连接状态'}: $_connectionStatus',
          type: _isConnectionHealthy ? LogType.success : LogType.warning,
        ),
      );
    } else {
      _logs.add(
        LogEntry(
          time: _formatTime(now.subtract(const Duration(milliseconds: 100))),
          message: '当前未登录，请配置服务器并登录',
          type: LogType.info,
        ),
      );
    }
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

  void _showToast(String message, ToastType type) {
    if (!mounted) {
      return;
    }

    final Color backgroundColor;
    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xDD34C759);
        break;
      case ToastType.error:
        backgroundColor = const Color(0xDDFF3B30);
        break;
      case ToastType.info:
        backgroundColor = const Color(0xDD007AFF);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 40,
          right: 40,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _syncData() async {
    if (_isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 添加同步日志
      void addLog(String message, [LogType type = LogType.info]) {
        setState(() {
          _logs.insert(
            0,
            LogEntry(
              time: _formatTime(DateTime.now()),
              message: message,
              type: type,
            ),
          );
        });
      }

      addLog('开始同步数据...');

      // 执行实际的同步操作
      if (!appProvider.isLoggedIn) {
        addLog('同步失败: 未登录', LogType.error);
        _showToast('同步失败: 请先登录', ToastType.error);
        return;
      }

      // 首先将本地数据同步到服务器
      addLog('正在同步本地数据到服务器...');
      final syncResult = await appProvider.syncLocalDataToServer();

      // 然后从服务器获取最新数据（包含刚才上传的数据和其他更新）
      addLog('正在从服务器获取最新数据...');
      await appProvider.fetchNotesFromServer();

      final result = syncResult;

      if (result) {
        addLog('同步成功', LogType.success);
        _showToast('同步成功', ToastType.success);

        // 更新上次同步时间
        setState(() {
          _lastSyncTime = '刚刚';
        });

        // 更新用户对象中的同步时间
        if (appProvider.user != null) {
          final updatedUser = appProvider.user!.copyWith(
            lastSyncTime: DateTime.now(),
          );
          await appProvider.setUser(updatedUser);
        }
      } else {
        addLog('同步失败', LogType.error);
        _showToast('同步失败', ToastType.error);
      }
    } on Object catch (e) {
      setState(() {
        _logs.insert(
          0,
          LogEntry(
            time: _formatTime(DateTime.now()),
            message: '同步失败: $e',
            type: LogType.error,
          ),
        );
      });
      _showToast('同步失败: $e', ToastType.error);
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _diagnoseConnection() async {
    if (_isDiagnosing) {
      return;
    }

    setState(() {
      _isDiagnosing = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 添加诊断日志
      void addLog(String message, [LogType type = LogType.info]) {
        setState(() {
          _logs.insert(
            0,
            LogEntry(
              time: _formatTime(DateTime.now()),
              message: message,
              type: type,
            ),
          );
        });
      }

      addLog('开始连接诊断...');

      // 检查是否配置了服务器地址
      if (appProvider.appConfig.memosApiUrl == null ||
          appProvider.appConfig.memosApiUrl!.isEmpty) {
        addLog('未配置服务器地址', LogType.error);
        _showToast('诊断失败: 未配置服务器地址', ToastType.error);
        return;
      }

      // 解析服务器地址
      addLog('解析服务器地址...');
      Uri? uri;
      try {
        uri = Uri.parse(appProvider.appConfig.memosApiUrl!);
        addLog('服务器地址: ${uri.host}', LogType.success);
        addLog('端口: ${uri.port}', LogType.success);
        addLog('协议: ${uri.scheme.toUpperCase()}', LogType.success);
      } on Object catch (e) {
        addLog('解析服务器地址失败: $e', LogType.error);
        _showToast('诊断失败: 服务器地址无效', ToastType.error);
        return;
      }

      // 检查DNS解析
      addLog('检查DNS解析...');

      try {
        // 使用Http.head请求检查连接性
        final dnsStart = DateTime.now();
        await http
            .head(
              Uri.parse('${uri.scheme}://${uri.host}:${uri.port}'),
            )
            .timeout(const Duration(seconds: 5));
        final dnsEnd = DateTime.now();
        final dnsDuration = dnsEnd.difference(dnsStart).inMilliseconds;

        addLog('DNS解析成功，耗时: ${dnsDuration}ms', LogType.success);
      } on Object catch (e) {
        addLog('DNS解析失败: $e', LogType.error);
      }

      // 测试API连接
      addLog('测试API连接...');

      try {
        final apiStart = DateTime.now();
        final response = await _pingMemosApi(appProvider);
        final apiEnd = DateTime.now();
        final apiDuration = apiEnd.difference(apiStart).inMilliseconds;

        if (response.statusCode == 200) {
          addLog('API连接成功，响应时间: ${apiDuration}ms', LogType.success);
          setState(() {
            _connectionStatus =
                AppLocalizationsSimple.of(context)?.connected ?? '已连接';
            _isConnectionHealthy = true;
            _latency = '$apiDuration ms';
          });
        } else {
          addLog('API连接失败: HTTP ${response.statusCode}', LogType.error);
          setState(() {
            _connectionStatus =
                AppLocalizationsSimple.of(context)?.connectionAbnormal ??
                    '连接异常';
            _isConnectionHealthy = false;
            _latency = AppLocalizationsSimple.of(context)?.failed ?? '错误';
          });
        }
      } on Object catch (e) {
        addLog('API连接失败: $e', LogType.error);
        setState(() {
          _connectionStatus =
              AppLocalizationsSimple.of(context)?.connectionAbnormal ?? '连接异常';
          _isConnectionHealthy = false;
          _latency = AppLocalizationsSimple.of(context)?.timeout ?? '超时';
        });
        _showToast('诊断失败: API连接失败', ToastType.error);
        return;
      }

      // 验证Token
      if (appProvider.appConfig.lastToken != null) {
        addLog('验证Token...');

        try {
          final tokenStart = DateTime.now();
          final tokenService = MemosApiServiceFixed(
            baseUrl: appProvider.appConfig.memosApiUrl!,
            token: appProvider.appConfig.lastToken,
          );
          await tokenService.getUserInfo().timeout(const Duration(seconds: 5));
          final tokenEnd = DateTime.now();
          final tokenDuration = tokenEnd.difference(tokenStart).inMilliseconds;

          addLog('Token验证成功，响应时间: ${tokenDuration}ms', LogType.success);
        } on Object catch (e) {
          addLog('Token验证失败: $e', LogType.error);
        }
      }

      // 综合诊断结果
      if (_isConnectionHealthy) {
        addLog('诊断结果: 连接正常', LogType.success);
        _showToast('诊断完成: 连接状态良好', ToastType.success);
      } else {
        addLog('诊断结果: 连接异常', LogType.error);
        _showToast('诊断完成: 连接状态异常', ToastType.error);
      }
    } on Object catch (e) {
      _showToast('诊断失败: $e', ToastType.error);
    } finally {
      setState(() {
        _isDiagnosing = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs = [
        LogEntry(
          time: _formatTime(DateTime.now()),
          message: '日志已清空',
          type: LogType.info,
        ),
      ];
    });
    _showToast('日志已清空', ToastType.info);
  }

  void _copyLogs() {
    // 实现复制日志功能
    _showToast('日志已复制到剪贴板', ToastType.success);
  }

  void _exportLogs() {
    // 实现导出日志功能
    _showToast('日志已导出', ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appProvider = context.watch<AppProvider>();
    final isLoggedIn = appProvider.isLoggedIn;
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Text(
          AppLocalizationsSimple.of(context)?.serverConnection ?? '服务器连接',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 当前状态
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 状态头部
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isConnectionHealthy
                              ? const Color(0xFF34C759).withValues(alpha: 0.15)
                              : const Color(0xFFFF3B30).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isConnectionHealthy
                              ? Icons.show_chart
                              : Icons.error_outline,
                          color: _isConnectionHealthy
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _connectionStatus,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isConnectionHealthy
                                ? (AppLocalizationsSimple.of(context)
                                        ?.connectionNormal ??
                                    '服务器连接正常，数据同步正常')
                                : (AppLocalizationsSimple.of(context)
                                        ?.pleaseCheckServerSettings ??
                                    '请检查服务器设置'),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 服务器详情
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildServerDetail(
                          AppLocalizationsSimple.of(context)?.host ?? '主机地址',
                          _serverAddressController.text,
                        ),
                        const SizedBox(height: 8),
                        _buildServerDetail(
                          AppLocalizationsSimple.of(context)?.port ?? '端口',
                          _portController.text,
                        ),
                        const SizedBox(height: 8),
                        _buildServerDetail(
                          AppLocalizationsSimple.of(context)?.latency ?? '延迟',
                          _latency,
                        ),
                        const SizedBox(height: 8),
                        _buildServerDetail(
                          AppLocalizationsSimple.of(context)?.lastSyncTime ??
                              '上次同步',
                          _lastSyncTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isLoggedIn && !_isSyncing ? _syncData : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSyncing)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const Icon(Icons.sync, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _isSyncing
                                    ? (AppLocalizationsSimple.of(context)
                                            ?.syncing ??
                                        '同步中...')
                                    : (AppLocalizationsSimple.of(context)
                                            ?.syncNowButton ??
                                        '立即同步'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: isLoggedIn && !_isDiagnosing
                              ? _diagnoseConnection
                              : null,
                          style: TextButton.styleFrom(
                            backgroundColor:
                                theme.dividerColor.withValues(alpha: 0.05),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isDiagnosing)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primaryColor,
                                    ),
                                  ),
                                )
                              else
                                const Icon(Icons.add_circle_outline, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _isDiagnosing
                                      ? (AppLocalizationsSimple.of(context)
                                              ?.diagnosing ??
                                          '诊断中...')
                                      : (AppLocalizationsSimple.of(context)
                                              ?.connectionDiagnosis ??
                                          '连接诊断'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔒 只读说明 - 服务器设置已锁定
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizationsSimple.of(context)
                              ?.serverInfoReadOnlyNotice ??
                          '此页面仅用于查看服务器连接状态和同步日志\n服务器设置请在登录页面配置',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 连接日志 - 只读查看
            if (!isLoggedIn)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Text(
                        AppLocalizationsSimple.of(context)
                                ?.connectionInfoReadOnly ??
                            '连接信息（只读）',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildServerDetail(
                            AppLocalizationsSimple.of(context)?.serverAddress ??
                                '服务器地址',
                            _serverAddressController.text.isEmpty
                                ? (AppLocalizationsSimple.of(context)
                                        ?.notConfigured ??
                                    '未配置')
                                : _serverAddressController.text,
                          ),
                          const SizedBox(height: 12),
                          _buildServerDetail(
                            AppLocalizationsSimple.of(context)?.portNumber ??
                                '端口号',
                            _portController.text.isEmpty
                                ? (AppLocalizationsSimple.of(context)
                                        ?.notConfigured ??
                                    '未配置')
                                : _portController.text,
                          ),
                          const SizedBox(height: 12),
                          _buildServerDetail(
                            'HTTPS',
                            _useHttps
                                ? (AppLocalizationsSimple.of(context)
                                        ?.enabled ??
                                    '已启用')
                                : (AppLocalizationsSimple.of(context)
                                        ?.disabled ??
                                    '未启用'),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizationsSimple.of(context)
                                            ?.modifyServerSettingsHint ??
                                        '要修改服务器设置，请退出登录后在登录页面配置',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 连接日志
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      AppLocalizationsSimple.of(context)?.connectionLog ??
                          '连接日志',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizationsSimple.of(context)?.noLogRecords ??
                              '暂无日志记录',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                        /* 这里可以添加实际的日志显示逻辑
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Text(_logs[index]);
                          },
                        ),
                        */
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 连接日志
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      AppLocalizationsSimple.of(context)?.connectionLog ??
                          '连接日志',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '最近连接记录',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.copy_outlined, size: 20),
                                  onPressed: _copyLogs,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    size: 20,
                                  ),
                                  onPressed: _exportLogs,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  onPressed: _clearLogs,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      log.time,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        log.message,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getLogColor(log.type, theme),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerDetail(String label, String value) => Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );

  Color _getLogColor(LogType type, ThemeData theme) {
    switch (type) {
      case LogType.success:
        return const Color(0xFF34C759);
      case LogType.error:
        return const Color(0xFFFF3B30);
      case LogType.warning:
        return const Color(0xFFFF9500);
      case LogType.info:
        return theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
            Colors.grey;
    }
  }
}

enum LogType {
  success,
  error,
  warning,
  info,
}

enum ToastType {
  success,
  error,
  info,
}

class LogEntry {
  LogEntry({
    required this.time,
    required this.message,
    required this.type,
  });
  final String time;
  final String message;
  final LogType type;
}
