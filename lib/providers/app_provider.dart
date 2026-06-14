import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 添加http包
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/models/annotation_model.dart'; // ✅ 新增：批注模型
import 'package:inkroot/models/announcement_model.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/cloud_verification_models.dart';
import 'package:inkroot/models/load_more_state.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/reminder_notification_model.dart';
import 'package:inkroot/models/sort_order.dart';
import 'package:inkroot/models/user_model.dart';
import 'package:inkroot/models/webdav_config.dart';
import 'package:inkroot/services/api_service.dart';
import 'package:inkroot/services/api_service_factory.dart';
import 'package:inkroot/services/cloud_verification_service.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/incremental_sync_service.dart';
import 'package:inkroot/services/local_reference_service.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart'; // 使用修复版API服务
import 'package:inkroot/services/memos_resource_service.dart'; // 图片上传服务
import 'package:inkroot/services/note_sorting_helper.dart';
import 'package:inkroot/services/note_tags_helper.dart' as note_tags;
import 'package:inkroot/services/notes_pagination_helper.dart' as paging;
import 'package:inkroot/services/notification_service.dart';
import 'package:inkroot/services/notion_sync_service.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/services/reminder_notification_service.dart';
import 'package:inkroot/services/sync_merge_helper.dart' as sync_merge;
import 'package:inkroot/services/sync_status_helper.dart' as sync_status;
import 'package:inkroot/services/umeng_analytics_service.dart';
import 'package:inkroot/services/unified_reference_manager.dart';
import 'package:inkroot/services/webdav_service.dart';
import 'package:inkroot/services/webdav_sync_engine.dart';
import 'package:inkroot/utils/error_handler.dart';
// 🚀 大厂标准：监控工具
import 'package:inkroot/utils/logger.dart';
import 'package:inkroot/utils/performance_tracker.dart';
import 'package:inkroot/widgets/cached_avatar.dart';
import 'package:inkroot/widgets/update_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'app_provider_sync.part.dart';

class AppProvider with ChangeNotifier implements NotificationAppProviderBridge {
  User? _user;
  List<Note> _notes = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  // 🚀 大厂标准：分页加载相关
  paging.NotesPaginationState _pagingState =
      paging.initialNotesPaginationState();
  static const int _pageSize = 50;

  // 🚀 大厂标准：并发控制（防止重复加载）
  Completer<void>? _loadMoreCompleter;

  // 🚀 大厂标准：性能监控
  int _totalNotesCount = 0; // 数据库总笔记数
  DateTime? _lastLoadTime; // 上次加载时间
  final Stopwatch _loadStopwatch = Stopwatch(); // 性能计时器
  ApiService? _apiService; // 保留兼容旧服务
  MemosApiServiceFixed? _memosApiService; // 使用修复版API服务
  MemosResourceService? _resourceService; // 图片上传服务
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();
  AppConfig _appConfig = AppConfig();
  bool _mounted = true;
  SortOrder _sortOrder = SortOrder.newest;

  // 🚀 WebDAV 同步相关
  WebDavConfig _webDavConfig = const WebDavConfig();
  WebDavService? _webDavService;
  WebDavSyncEngine? _webDavSyncEngine;
  Timer? _webDavBackupTimer; // WebDAV 定时备份计时器
  bool _hasPerformedStartupBackup = false; // 是否已执行过启动备份

  // 🚀 Notion 同步相关
  final NotionSyncService _notionSyncService = NotionSyncService();
  bool _isNotionSyncing = false;

  // 同步相关变量
  Timer? _syncTimer;
  bool _isSyncing = false;
  String? _syncMessage;

  void _setSyncUi({bool? syncing, String? message, bool notify = true}) {
    if (syncing != null) {
      _isSyncing = syncing;
    }
    _syncMessage = message;
    if (notify) {
      notifyListeners();
    }
  }

  void _setSyncMessage(String? message, {bool notify = true}) {
    _syncMessage = message;
    if (notify) {
      notifyListeners();
    }
  }

  // 🚀 删除队列相关（大厂级批量处理）
  final List<String> _deleteQueue = [];
  bool _isProcessingDelete = false;
  Timer? _deleteDebounceTimer;
  static const Duration deleteUndoWindow = Duration(milliseconds: 3200);
  static const Duration _deleteBatchDelay = Duration(milliseconds: 500);

  // 🚀 撤销删除相关变量
  Note? _lastDeletedNote;
  int? _lastDeletedIndex;
  Timer? _pendingDeleteCommitTimer;

  // 通知相关属性
  final CloudVerificationService _cloudService = CloudVerificationService();
  final NotificationService _notificationService = NotificationService();
  // 🔥 暴露notificationService供main.dart使用
  NotificationService get notificationService => _notificationService;
  final ReminderNotificationService _reminderNotificationService =
      ReminderNotificationService();
  // 🔥 暴露reminderNotificationService供main.dart使用
  ReminderNotificationService get reminderNotificationService =>
      _reminderNotificationService;
  // 🎯 大厂标准：暴露preferencesService供登录/注册页使用
  PreferencesService get preferencesService => _preferencesService;
  IncrementalSyncService? _incrementalSyncService;
  int _unreadAnnouncementsCount = 0;
  final List<Announcement> _announcements = []; // 公告列表
  // 🔄 已移除 _lastReadAnnouncementId，使用SharedPreferences中的列表管理已读状态

  // 云验证相关
  CloudAppConfigData? _cloudAppConfig;
  CloudNoticeData? _cloudNotice;
  DateTime? _lastCloudVerificationTime; // 🚀 上次加载云验证数据的时间
  static const Duration _cloudVerificationCacheDuration =
      Duration(minutes: 5); // 🚀 缓存5分钟

  // 获取排序后的笔记
  List<Note> _getSortedNotes() => sortedNotesCopy(_notes, _sortOrder);

  // 设置排序方式
  void setSortOrder(SortOrder sortOrder) {
    if (_sortOrder != sortOrder) {
      _sortOrder = sortOrder;
      notifyListeners();
    }
  }

  // Getters
  User? get user => _user;
  // 🔥 过滤掉归档笔记，只返回正常笔记
  List<Note> get notes =>
      _getSortedNotes().where((note) => note.isNormal).toList();

  // 🚀 大厂标准：细粒度状态访问
  bool get isLoadingMore => _pagingState.loadMoreState.isLoading;
  bool get hasMoreData =>
      _pagingState.hasMoreData &&
      _pagingState.loadMoreState != LoadMoreState.noMore;
  LoadMoreState get loadMoreState => _pagingState.loadMoreState;

  // 🚀 大厂标准：性能指标访问
  int get totalNotesCount => _totalNotesCount;
  int get loadedNotesCount => _notes.length;
  DateTime? get lastLoadTime => _lastLoadTime;

  // 根据ID获取笔记
  Note? getNoteById(String noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } on Object {
      return null;
    }
  }

  List<Note> get rawNotes => _notes;
  SortOrder get sortOrder => _sortOrder;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn =>
      _user != null && _user!.token != null && _user!.token!.isNotEmpty;
  bool get isLocalMode => _appConfig.isLocalMode;
  AppConfig get appConfig => _appConfig;
  ApiService? get apiService => _apiService;
  MemosApiServiceFixed? get memosApiService => _memosApiService;
  MemosResourceService? get resourceService => _resourceService;
  DatabaseService get databaseService => _databaseService;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;
  bool get mounted => _mounted;

  int get unreadAnnouncementsCount => _unreadAnnouncementsCount;
  List<Announcement> get announcements => _announcements;
  CloudAppConfigData? get cloudAppConfig => _cloudAppConfig;
  CloudNoticeData? get cloudNotice => _cloudNotice;

  Future<List<Note>> searchNotes(String query) async =>
      _databaseService.searchNotes(query);

  Future<List<Note>> getAllNotesForStats() async => _databaseService.getNotes();

  // 🚀 WebDAV getters
  WebDavConfig get webDavConfig => _webDavConfig;
  bool get isWebDavEnabled => _webDavConfig.enabled;

  /// 更新内存中的笔记（用于本地引用服务通知）
  void updateNoteInMemory(Note updatedNote) {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
      // 内存中的笔记已更新
    }
  }

  // 初始化应用
  /// 🔥 单独初始化通知服务（在应用启动时立即调用）
  // 🚀 懒加载：只在需要时初始化
  bool _notificationServiceInitialized = false;

  Future<void> initializeNotificationService() async {
    if (_notificationServiceInitialized) {
      // 已初始化，跳过
      return;
    }

    try {
      // 🔥 清理过期的提醒通知（首次启动时执行）
      await _cleanupOldReminderNotifications();

      await _notificationService.initialize();

      // 设置通知点击回调 - 跳转到笔记详情页并清除提醒
      _notificationService.setNotificationTapCallback((noteIdInt) async {
        // 🔥 关键修复：使用noteIdMapping找到原始的noteId字符串
        final noteIdString = NotificationService.noteIdMapping[noteIdInt];

        if (noteIdString == null) {
          return;
        }

        // 等待一小段时间确保界面完全准备好
        await Future.delayed(const Duration(milliseconds: 300));

        // 🔥 关键修复：使用全局的appRouter，不依赖context
        // 需要从main.dart传入appRouter引用，或者使用其他方式获取
        // 暂时先尝试取消提醒

        // 🔥 自动清除已触发的提醒（市面上常见做法）
        try {
          await cancelNoteReminder(noteIdString);
        } on Object catch (_) {
          // Reminder cleanup is best-effort during notification callbacks.
        }

        // 后续如需点击通知直达详情页，需要由 main.dart 注入 appRouter。
      });

      _notificationServiceInitialized = true;
    } on Object catch (_) {
      // Notifications are optional; app startup must continue without them.
    }
  }

  Future<void> initializeApp() async {
    if (_isInitialized) {
      return;
    }

    // 开始初始化应用

    try {
      // 初始化统一引用管理器
      UnifiedReferenceManager().initialize(
        databaseService: _databaseService,
        onNotesUpdated: (updatedNotes) {
          // 🔧 修复：确保引用关系更新时能实时反映到UI
          // 分页加载时不直接替换整个列表
          if (_pagingState.currentPage == 0 &&
              updatedNotes.length <= _pageSize) {
            _notes = updatedNotes;
          } else {
            // 更新已加载的笔记
            for (final note in updatedNotes) {
              final index = _notes.indexWhere((n) => n.id == note.id);
              if (index != -1) {
                _notes[index] = note;
              } else {
                // 🔧 修复：如果笔记不在当前列表中，添加它
                // 这种情况可能发生在创建新引用时
                _notes.add(note);
              }
            }
          }
          // 🔧 修复：使用双重通知确保UI更新
          notifyListeners();
          // 添加微延迟后再次通知，确保所有监听器都能收到更新
          Future.microtask(() {
            if (mounted) {
              notifyListeners();
            }
          });
        },
        onError: (error) {},
        syncReferenceToServerUnified: _syncReferenceToServerUnified,
      );

      // 🚀 延迟清理过期提醒（不阻塞启动）
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          clearExpiredReminders().catchError((e) {
            if (kDebugMode) {
              debugPrint('AppProvider: 清理过期提醒失败: $e');
            }
          });
        }
      });

      // 加载应用配置
      // 加载应用配置
      _appConfig = await _preferencesService.loadAppConfig();

      // 字体缩放将通过MediaQuery.textScaleFactor全局应用

      // 应用配置加载完成

      // 🔧 加载 WebDAV 配置
      await loadWebDavConfig();

      // 加载用户信息
      // 加载用户信息
      _user = await _preferencesService.getUser();
      // 用户信息加载完成

      // 检查并修复配置状态：如果用户已登录但配置是本地模式，则切换到在线模式
      if (_user != null &&
          _user!.token != null &&
          _appConfig.isLocalMode &&
          _appConfig.memosApiUrl != null) {
        // 检测到已登录用户但配置为本地模式，切换到在线模式
        _appConfig = _appConfig.copyWith(isLocalMode: false);
        await _preferencesService.saveAppConfig(_appConfig);
      }

      // 🔄 本地数据优先加载 - 使用分页加载优化性能
      try {
        // 🚀 使用分页加载，只加载首页数据
        await loadInitialNotes();
        // 本地数据首页加载完成
      } on Object {
        // 加载本地数据失败
        _notes = []; // 确保有默认空列表
      }

      // 设置初始化标志为true，让UI可以立即显示本地数据
      _isInitialized = true;
      notifyListeners(); // 通知UI更新，此时已经有本地数据可以显示

      // 🌐 在后台继续处理网络相关操作，不阻塞UI显示
      unawaited(_initializeNetworkOperationsInBackground());
    } on Object {
      // 初始化应用异常
      // 即使出错也确保初始化标志为true，避免卡在启动页
      _isInitialized = true;
      _notes = []; // 确保有默认空列表
      notifyListeners();
    }
  }

  // 后台网络操作初始化（新增方法）- 🚀 大厂级启动优化
  Future<void> _initializeNetworkOperationsInBackground() async {
    try {
      // 开始后台网络操作初始化

      // 异步初始化API服务
      if (_user != null &&
          (_user!.serverUrl != null || _appConfig.memosApiUrl != null)) {
        // 后台初始化API服务
        await _initializeApiServiceInBackground();
      }

      // 🚀 完全移除启动时的引用关系扫描（按需加载）
      // 用户打开笔记详情页时才扫描该笔记的引用关系

      // 🚀 大厂级优化：延迟3秒后再进行数据同步（让用户先看到界面）
      // 微信/抖音策略：先显示本地数据，后台静默同步
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) {
          return;
        }

        // 如果API服务已初始化，尝试获取服务器数据并同步
        if (_memosApiService != null && !_appConfig.isLocalMode) {
          // 后台从服务器获取最新数据（不扫描引用关系）
          fetchNotesFromServer().catchError((e) {
            if (kDebugMode) {
              debugPrint('AppProvider: 后台获取数据失败: $e');
            }
            // 如果获取失败，至少尝试同步本地数据
            syncLocalDataToServer().catchError((e2) {
              if (kDebugMode) {
                debugPrint('AppProvider: 后台同步失败: $e2');
              }
              return false;
            });
          });
        }
      });

      // 🚀 延迟5秒加载云验证和公告（进一步降低启动负担）
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          if (kDebugMode) {
            debugPrint('AppProvider: 延迟加载通知和云验证');
          }
          refreshAnnouncements()
              .then((_) => refreshUnreadAnnouncementsCount())
              .catchError((e) {
            if (kDebugMode) {
              debugPrint('AppProvider: 加载通知失败: $e');
            }
          });
        }
      });

      if (kDebugMode) {
        debugPrint('AppProvider: 后台网络操作初始化完成（数据同步已延迟）');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 后台网络操作失败: $e');
      }
    }
  }

  // 服务器端引用同步
  Future<void> _syncReferenceToServerUnified(
    String sourceId,
    String targetId,
    String action,
  ) async {
    if (!isLoggedIn || _memosApiService == null || _user?.token == null) {
      if (kDebugMode) {
        // 跳过服务器引用同步（未登录或API服务未初始化）
      }
      return;
    }

    try {
      if (kDebugMode) {
        // 同步引用关系到服务器
      }

      var success = false;

      if (action == 'CREATE') {
        // 创建引用关系
        final relation = {
          'relatedMemoId': targetId,
          'type': 'REFERENCE',
        };
        success = await _syncSingleReferenceToServer(sourceId, relation);
      } else if (action == 'DELETE') {
        // 删除引用关系 - 先删除所有关系，然后重新创建需要保留的关系
        success = await _deleteAllReferenceRelations(sourceId);

        if (success) {
          // 重新创建除了要删除的关系之外的所有引用关系
          final sourceNote = _notes.firstWhere(
            (n) => n.id == sourceId,
            orElse: () => Note(
              id: '',
              content: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          if (sourceNote.id.isNotEmpty) {
            for (final relation in sourceNote.relations) {
              if (relation['type'] == 'REFERENCE' &&
                  relation['memoId']?.toString() == sourceId &&
                  relation['relatedMemoId']?.toString() != targetId) {
                await _syncSingleReferenceToServer(sourceId, relation);
              }
            }
          }
        }
      }

      if (success) {
        // 更新本地关系的同步状态
        await _markRelationAsSynced(sourceId, targetId, action);
      }
    } on Object catch (_) {
      // Reference sync runs in the background and should not block the UI.
    }
  }

  // 标记引用关系为已同步
  Future<void> _markRelationAsSynced(
    String sourceId,
    String targetId,
    String action,
  ) async {
    try {
      // 查找并更新源笔记的关系状态
      final sourceNoteIndex = _notes.indexWhere((n) => n.id == sourceId);
      if (sourceNoteIndex != -1) {
        final sourceNote = _notes[sourceNoteIndex];
        final updatedRelations = sourceNote.relations.map((rel) {
          if (rel['type'] == 'REFERENCE' &&
              rel['memoId']?.toString() == sourceId &&
              rel['relatedMemoId']?.toString() == targetId) {
            return {...rel, 'synced': true};
          }
          return rel;
        }).toList();

        final updatedSourceNote =
            sourceNote.copyWith(relations: updatedRelations);
        await _databaseService.updateNote(updatedSourceNote);
        _notes[sourceNoteIndex] = updatedSourceNote;
      }

      // 查找并更新目标笔记的关系状态
      final targetNoteIndex = _notes.indexWhere((n) => n.id == targetId);
      if (targetNoteIndex != -1) {
        final targetNote = _notes[targetNoteIndex];
        final updatedRelations = targetNote.relations.map((rel) {
          if (rel['type'] == 'REFERENCED_BY' &&
              rel['memoId']?.toString() == sourceId &&
              rel['relatedMemoId']?.toString() == targetId) {
            return {...rel, 'synced': true};
          }
          return rel;
        }).toList();

        final updatedTargetNote =
            targetNote.copyWith(relations: updatedRelations);
        await _databaseService.updateNote(updatedTargetNote);
        _notes[targetNoteIndex] = updatedTargetNote;
      }

      // 刷新UI
      notifyListeners();
    } on Object catch (_) {
      // Local sync markers are best-effort; relations remain usable offline.
    }
  }

  // 在后台加载剩余数据
  // 已废弃的 _loadRemainingData 方法，功能已合并到 initializeApp 和 _initializeNetworkOperationsInBackground 中

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 从本地数据库加载笔记
  Future<void> loadNotesFromLocal({bool reset = false}) async {
    // 🚀 大厂标准：性能监控
    await PerformanceTracker().startTrace(
      'load_notes_from_local',
      attributes: {
        'reset': reset.toString(),
      },
    );
    Log.database.debug('Loading notes from local', data: {'reset': reset});

    try {
      // 🔥 修复：完整加载所有笔记（用于刷新场景，如导入后）
      // 这是刷新操作，需要显示最新的完整数据
      _pagingState = paging.initialNotesPaginationState();
      _notes = await _databaseService.getNotes();

      // 更新总数统计
      _totalNotesCount = _notes.length;

      // 修复失效的图片路径
      await _fixBrokenImagePaths();

      // 重新提取所有笔记的标签
      _refreshAllNoteTags();

      notifyListeners();

      // 🚀 大厂标准：成功监控
      await PerformanceTracker().stopTrace(
        'load_notes_from_local',
        metrics: {'note_count': _notes.length},
      );
      Log.database
          .info('Notes loaded successfully', data: {'count': _notes.length});
    } on Object catch (e, stackTrace) {
      // 🚀 大厂标准：错误监控
      await PerformanceTracker()
          .stopTrace('load_notes_from_local', success: false);
      Log.database.error(
        'Failed to load notes from local',
        error: e,
        stackTrace: stackTrace,
      );
      await ErrorHandler.captureException(
        e,
        stackTrace: stackTrace,
        context: {
          'operation': 'load_notes_from_local',
          'reset': reset,
        },
      );
      rethrow;
    }
  }

  /// 🚀 分页加载初始笔记（性能优化 - 大厂最佳实践）
  /// 三阶段加载：极速首屏 → 预加载 → 后台任务
  Future<void> loadInitialNotes() async {
    try {
      _pagingState = paging.initialNotesPaginationState();

      // 用 COUNT 获取总数，避免全量加载仅用于计数
      _totalNotesCount = await _databaseService.getNotesCount();

      // SQLite 本地读取极快（< 10ms），直接加载完整第一页，无需分步延迟
      final firstPage = await _databaseService.getNotesPaged();

      _notes = firstPage;
      _pagingState = _pagingState.copyWith(
        currentPage: 0,
        hasMoreData: firstPage.length >= _pageSize,
      );

      notifyListeners();
      if (kDebugMode) {
        debugPrint(
          'AppProvider: ✅ 本地数据加载完成，已加载 ${_notes.length}/$_totalNotesCount 条笔记',
        );
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 加载初始笔记失败: $e');
      }
      rethrow;
    }
  }

  /// 🚀 大厂标准：加载更多笔记（滚动到底部时调用）
  /// 特性：并发控制 + 细粒度状态 + 性能监控
  Future<void> loadMoreNotes() async {
    // 1️⃣ 并发控制：如果正在加载，返回现有的 Future
    if (_loadMoreCompleter != null && !_loadMoreCompleter!.isCompleted) {
      debugPrint('AppProvider: ⚠️ 检测到并发加载请求，返回现有Future');
      return _loadMoreCompleter!.future;
    }

    // 2️⃣ 状态检查：使用细粒度状态判断
    if (!paging.canStartLoadMore(_pagingState)) {
      debugPrint(
        'AppProvider: ⏸️ 无法加载更多 - 状态: ${_pagingState.loadMoreState.description}, 有更多数据: ${_pagingState.hasMoreData}',
      );
      return;
    }

    // 3️⃣ 创建新的 Completer
    _loadMoreCompleter = Completer<void>();

    // 4️⃣ 开始性能监控
    _loadStopwatch.reset();
    _loadStopwatch.start();
    try {
      // 5️⃣ 更新状态为加载中
      _pagingState = paging.beginLoadMore(_pagingState);
      notifyListeners();
      debugPrint(
        'AppProvider: 📄 开始加载第 ${_pagingState.currentPage} 页笔记... (状态: ${_pagingState.loadMoreState.description})',
      );

      // 6️⃣ 执行数据加载
      final moreNotes = await _databaseService.getNotesPaged(
        page: _pagingState.currentPage,
      );

      // 7️⃣ 处理加载结果
      if (moreNotes.isNotEmpty) {
        _notes.addAll(moreNotes);
        debugPrint(
          'AppProvider: ✅ 第 ${_pagingState.currentPage} 页加载完成，本页 ${moreNotes.length} 条，总计 ${_notes.length}/$_totalNotesCount 条',
        );
      }
      _pagingState = paging.applyLoadMoreResult(
        state: _pagingState,
        itemCount: moreNotes.length,
      );
      if (moreNotes.isEmpty) {
        debugPrint(
          'AppProvider: ✅ 所有笔记已加载完成，共 ${_notes.length}/$_totalNotesCount 条',
        );
      }

      // 8️⃣ 停止性能监控
      _loadStopwatch.stop();
      _lastLoadTime = DateTime.now();

      // 9️⃣ 性能埋点上报
      _reportLoadPerformance(
        page: _pagingState.currentPage,
        itemCount: moreNotes.length,
        duration: _loadStopwatch.elapsedMilliseconds,
        success: true,
      );

      notifyListeners();

      // 🔟 完成 Completer
      _loadMoreCompleter!.complete();
    } on Object catch (e, stackTrace) {
      // ❌ 错误处理
      _loadStopwatch.stop();
      _pagingState = paging.applyLoadMoreFailure(_pagingState);

      debugPrint(
        'AppProvider: ❌ 加载第 ${_pagingState.currentPage + 1} 页失败: $e',
      );
      if (kDebugMode) {
        debugPrint('AppProvider: 错误堆栈: $stackTrace');
      }

      // 性能埋点上报（失败）
      _reportLoadPerformance(
        page: _pagingState.currentPage + 1,
        itemCount: 0,
        duration: _loadStopwatch.elapsedMilliseconds,
        success: false,
        error: e.toString(),
      );

      notifyListeners();

      // 完成 Completer（带错误）
      _loadMoreCompleter!.completeError(e, stackTrace);

      rethrow;
    } finally {
      // 重置状态（如果不是 noMore）
      _pagingState = paging.endLoadAttempt(_pagingState);
    }
  }

  /// 🚀 大厂标准：性能监控埋点上报
  void _reportLoadPerformance({
    required int page,
    required int itemCount,
    required int duration,
    required bool success,
    String? error,
  }) {
    try {
      // 构建埋点数据（友盟需要 Map<String, String>）
      final eventData = {
        'page': page.toString(),
        'item_count': itemCount.toString(),
        'total_loaded': _notes.length.toString(),
        'total_in_db': _totalNotesCount.toString(),
        'duration_ms': duration.toString(),
        'success': success.toString(),
        'has_more': _pagingState.hasMoreData.toString(),
        'state': _pagingState.loadMoreState.description,
      };

      if (error != null) {
        eventData['error'] = error;
      }

      // 友盟埋点上报
      UmengAnalyticsService.onEventWithMap('list_load_more', eventData);

      // 性能告警（加载超过1秒）
      if (duration > 1000) {
        debugPrint('⚠️ [性能告警] 列表加载耗时过长: ${duration}ms');
        UmengAnalyticsService.onEventWithMap('performance_warning', {
          'type': 'list_load_slow',
          'duration_ms': duration.toString(),
          'page': page.toString(),
        });
      }

      // Debug模式下打印详细信息
      if (kDebugMode) {
        debugPrint('📊 [性能监控] 加载第$page页: ${success ? '成功' : '失败'} | '
            '耗时${duration}ms | 本页$itemCount条 | 总计${_notes.length}条');
      }
    } on Object catch (e) {
      // 埋点失败不应该影响主流程
      if (kDebugMode) {
        debugPrint('⚠️ 性能埋点上报失败: $e');
      }
    }
  }

  // 重新提取所有笔记的标签
  void _refreshAllNoteTags() {
    // 开始重新提取所有笔记的标签
    for (var i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      final tags = extractTags(note.content);
      if (note_tags.tagsChanged(oldTags: note.tags, newTags: tags)) {
        debugPrint(
          'AppProvider: 更新笔记 ${note.id} 的标签: ${note.tags.join(',')} -> ${tags.join(',')}',
        );
        _notes[i] = note.copyWith(tags: tags);
        // 不需要await，批量更新标签只更新内存中的标签，不更新数据库
      }
    }
  }

  // 扫描所有笔记并更新标签（包括数据库更新）
  Future<void> refreshAllNoteTagsWithDatabase() async {
    // 开始扫描所有笔记并更新标签
    _setLoading(true);
    try {
      for (var i = 0; i < _notes.length; i++) {
        final note = _notes[i];
        final tags = extractTags(note.content);
        if (note_tags.tagsChanged(oldTags: note.tags, newTags: tags)) {
          debugPrint(
            'AppProvider: 更新笔记 ${note.id} 的标签: ${note.tags.join(',')} -> ${tags.join(',')}',
          );
          final updatedNote = note.copyWith(tags: tags);
          _notes[i] = updatedNote;
          await _databaseService.updateNote(updatedNote);
        }
      }
      notifyListeners();
    } on Object catch (e) {
      debugPrint('AppProvider: 更新所有笔记标签失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 修复失效的图片路径
  Future<bool> _fixBrokenImagePaths() async {
    var hasUpdates = false;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');

      if (!await imagesDir.exists()) {
        // 图片目录不存在，无需修复
        return false;
      }

      // 获取当前应用目录中的所有图片文件
      final imageFiles = await imagesDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      final imageFileNames =
          imageFiles.map((file) => file.path.split('/').last).toSet();

      // 找到图片文件

      for (var i = 0; i < _notes.length; i++) {
        final note = _notes[i];
        final imageRegex = RegExp(r'!\[图片\]\(file://([^)]+)\)');
        final matches = imageRegex.allMatches(note.content);

        if (matches.isEmpty) {
          continue;
        }

        var updatedContent = note.content;
        var noteUpdated = false;

        for (final match in matches) {
          final fullPath = match.group(1)!;
          final fileName = fullPath.split('/').last;

          // 检查文件是否存在
          final file = File(fullPath);
          if (!await file.exists()) {
            // 文件不存在，尝试在当前应用目录中找到同名文件
            if (imageFileNames.contains(fileName)) {
              final newPath = '${imagesDir.path}/$fileName';
              final newImageMarkdown = '![图片](file://$newPath)';
              updatedContent =
                  updatedContent.replaceAll(match.group(0)!, newImageMarkdown);
              noteUpdated = true;
              // 修复图片路径
            } else {
              // 图片文件不存在
            }
          }
        }

        if (noteUpdated) {
          final updatedNote = note.copyWith(content: updatedContent);
          _notes[i] = updatedNote;
          await _databaseService.updateNote(updatedNote);
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        // 图片路径修复完成，触发UI刷新
        // 立即触发UI刷新，让修复后的图片显示出来
        notifyListeners();

        // 延迟一点时间后再次刷新，确保图片组件重新加载
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
    } on Object {
      // 修复图片路径失败
    }

    return hasUpdates;
  }

  // 计算笔记内容的哈希值
  String _calculateNoteHash(Note note) {
    final content = utf8.encode(note.content);
    final digest = sha256.convert(content);
    return digest.toString();
  }

  Future<Note> _prepareNoteForMemosUpload(Note note) async {
    if (_resourceService == null) {
      return note;
    }

    final imageRegex = RegExp(r'!\[([^\]]*)\]\((file://[^)]+)\)');
    var updatedContent = note.content;
    var changed = false;

    for (final match in imageRegex.allMatches(note.content).toList()) {
      final fullMatch = match.group(0);
      final alt = match.group(1) ?? '图片';
      final localUri = match.group(2);
      if (fullMatch == null || localUri == null) {
        continue;
      }

      final localPath = localUri.replaceFirst('file://', '');
      final imageFile = File(localPath);
      if (!await imageFile.exists()) {
        debugPrint('AppProvider: 本地图片不存在，暂不上传: $localPath');
        continue;
      }

      final uploadResult = await _resourceService!.uploadImage(imageFile);
      final serverMarkdown = MemosResourceService.generateImageMarkdown(
        uploadResult,
        alt: alt.isEmpty ? '图片' : alt,
      );
      updatedContent = updatedContent.replaceAll(fullMatch, serverMarkdown);
      changed = true;
    }

    if (!changed) {
      return note;
    }

    final updatedNote = note.copyWith(
      content: updatedContent,
      isSynced: false,
    );
    await _databaseService.updateNote(updatedNote);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
    return updatedNote;
  }

  bool _isLocalOnlyNoteId(String id) =>
      id.startsWith('local_') || id.contains('-');

  Note _mergeServerNoteWithLocalState(
    Note serverNote,
    Note localNote, {
    bool preserveLocalTimeline = false,
  }) =>
      sync_merge.mergeServerNoteWithLocalState(
        serverNote,
        localNote,
        preserveLocalTimeline: preserveLocalTimeline,
      );

  Future<Note> _syncUnsyncedNoteToMemos(Note note) async {
    if (_memosApiService == null) {
      throw Exception('Memos API 未初始化');
    }

    final uploadableNote = await _prepareNoteForMemosUpload(note);
    final oldId = uploadableNote.id;
    final visibility = uploadableNote.visibility.isNotEmpty
        ? uploadableNote.visibility
        : _appConfig.defaultNoteVisibility;

    final Note serverNote;
    if (_isLocalOnlyNoteId(uploadableNote.id)) {
      serverNote = await _memosApiService!.createMemo(
        content: uploadableNote.content,
        visibility: visibility,
      );
    } else {
      serverNote = await _memosApiService!.updateMemo(
        uploadableNote.id,
        content: uploadableNote.content,
        visibility: visibility,
      );
    }

    final syncedNote = _mergeServerNoteWithLocalState(
      serverNote,
      uploadableNote,
      preserveLocalTimeline: true,
    );
    if (oldId != syncedNote.id) {
      await _updateReferenceIdsAfterSync(oldId, syncedNote.id);
      await _databaseService.deleteNote(oldId);
      _notes.removeWhere((n) => n.id == oldId);
    }

    await _databaseService.saveNote(syncedNote);
    final index = _notes.indexWhere((n) => n.id == syncedNote.id);
    if (index != -1) {
      _notes[index] = syncedNote;
    } else {
      _notes.insert(0, syncedNote);
    }
    return syncedNote;
  }

  // 检测本地是否有数据
  Future<bool> hasLocalData() async {
    final notes = await _databaseService.getNotes();
    return notes.isNotEmpty;
  }

  // 检测云端是否有数据
  Future<bool> hasServerData() async {
    if (!isLoggedIn || _memosApiService == null) {
      return false;
    }

    try {
      final response = await _memosApiService!.getMemos();
      final serverNotes = response['memos'] as List<dynamic>;
      return serverNotes.isNotEmpty;
    } on Object catch (e) {
      debugPrint('检查云端数据失败: $e');
      return false;
    }
  }

  // 更新应用配置
  Future<void> updateConfig(AppConfig newConfig) async {
    // 更新配置

    // 检查API URL是否变化
    final apiUrlChanged = _appConfig.memosApiUrl != newConfig.memosApiUrl;

    // 检查暗黑模式是否变化
    final darkModeChanged = _appConfig.isDarkMode != newConfig.isDarkMode;

    // 保存新配置
    _appConfig = newConfig;
    await _preferencesService.saveAppConfig(newConfig);

    // 字体缩放通过MediaQuery.textScaleFactor全局应用

    // 如果API URL变化，重新创建API服务
    if (apiUrlChanged) {
      // API URL已更改，重新创建API服务
      if (newConfig.memosApiUrl != null && newConfig.lastToken != null) {
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: newConfig.memosApiUrl!,
          token: newConfig.lastToken,
        ) as MemosApiServiceFixed;
      } else {
        _memosApiService = null;
      }
    }

    // 如果暗黑模式变化，需要通知界面刷新主题
    if (darkModeChanged) {
      // 暗黑模式已切换
    }

    // 配置更新成功
    notifyListeners();
  }

  // 获取当前深色模式状态
  bool get isDarkMode {
    // 如果设置了跟随系统，则返回系统深色模式状态
    if (_appConfig.themeSelection == AppConfig.THEME_SYSTEM) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    // 否则根据主题选择返回
    return _appConfig.themeSelection == AppConfig.THEME_DARK;
  }

  // 切换深色模式（兼容旧版本）
  Future<void> toggleDarkMode() async {
    final newTheme = isDarkMode ? AppConfig.THEME_LIGHT : AppConfig.THEME_DARK;
    await setThemeSelection(newTheme);
  }

  // 设置深色模式（兼容旧版本）
  Future<void> setDarkMode(bool value) async {
    final newTheme = value ? AppConfig.THEME_DARK : AppConfig.THEME_LIGHT;
    await setThemeSelection(newTheme);
  }

  // 设置主题选择
  Future<void> setThemeSelection(String themeSelection) async {
    if (themeSelection == _appConfig.themeSelection) {
      return;
    }

    // 同时更新isDarkMode以保持向后兼容
    var isDarkMode = themeSelection == AppConfig.THEME_DARK;
    // 对于跟随系统，需要获取当前系统设置
    if (themeSelection == AppConfig.THEME_SYSTEM) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
    }

    final updatedConfig = _appConfig.copyWith(
      themeSelection: themeSelection,
      isDarkMode: isDarkMode,
    );
    await updateConfig(updatedConfig);
  }

  // 获取当前主题选择
  String get themeSelection => _appConfig.themeSelection;

  // 设置主题模式
  Future<void> setThemeMode(String mode) async {
    if (mode == _appConfig.themeMode) {
      return;
    }

    final updatedConfig = _appConfig.copyWith(themeMode: mode);
    await updateConfig(updatedConfig);
  }

  // 设置语言
  Future<void> setLocale(String? locale) async {
    if (locale == _appConfig.locale) {
      return;
    }

    debugPrint('🌍 [AppProvider.setLocale] 准备更新locale: $locale');
    final updatedConfig = _appConfig.copyWith(
      locale: locale,
      updateLocale: true, // 明确告知copyWith要更新locale字段
    );
    debugPrint(
      '🌍 [AppProvider.setLocale] 更新后的locale: ${updatedConfig.locale}',
    );
    await updateConfig(updatedConfig);
    debugPrint('🌍 [AppProvider.setLocale] locale已保存到数据库');
  }

  // 获取当前语言
  String? get locale => _appConfig.locale;

  // 获取当前主题模式
  String get themeMode => _appConfig.themeMode;

  // 同步本地数据到云端
  Future<bool> syncLocalToServer() async {
    if (!isLoggedIn || _memosApiService == null) {
      return false;
    }

    _setLoading(true);

    try {
      // 获取本地笔记
      final localNotes = await _databaseService.getNotes();
      if (localNotes.isEmpty) {
        return true;
      }

      // 获取服务器笔记以检查重复
      final response = await _memosApiService!.getMemos();
      final serverNotes = (response['memos'] as List<dynamic>)
          .map((m) => Note.fromJson(m as Map<String, dynamic>))
          .toList();

      // 计算所有服务器笔记的哈希值
      final serverHashes = serverNotes.map(_calculateNoteHash).toSet();

      // 同步每个本地笔记到服务器
      var syncedCount = 0;
      for (final note in localNotes) {
        // 如果笔记已经同步，跳过
        if (note.isSynced) {
          continue;
        }

        // 计算本地笔记的哈希值
        final noteHash = _calculateNoteHash(note);

        // 如果服务器上已有相同内容的笔记，跳过
        if (serverHashes.contains(noteHash)) {
          // 标记为已同步
          note.isSynced = true;
          await _databaseService.updateNote(note);
          continue;
        }

        try {
          await _syncUnsyncedNoteToMemos(note);
          syncedCount++;
        } on Object catch (e) {
          debugPrint('同步笔记失败: ${note.id} - $e');
        }
      }

      // 刷新内存中的列表
      await loadNotesFromLocal();

      debugPrint('成功同步 $syncedCount 条笔记到云端');
      return true;
    } on Object catch (e) {
      debugPrint('同步本地数据到云端失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 同步云端数据到本地
  Future<bool> syncServerToLocal() async {
    if (!isLoggedIn || _memosApiService == null) {
      return false;
    }

    _setLoading(true);

    try {
      // 获取服务器笔记
      final response = await _memosApiService!.getMemos();
      final serverNotes = (response['memos'] as List<dynamic>)
          .map((m) => Note.fromJson(m as Map<String, dynamic>))
          .toList();
      if (serverNotes.isEmpty) {
        return true;
      }

      // 获取本地笔记以检查重复
      final localNotes = await _databaseService.getNotes();

      // 计算所有本地笔记的哈希值
      final localHashes = localNotes.map(_calculateNoteHash).toSet();
      final localNotesById = {for (final note in localNotes) note.id: note};

      // 同步每个服务器笔记到本地
      var syncedCount = 0;
      for (final serverNote in serverNotes) {
        // 计算服务器笔记的哈希值
        final noteHash = _calculateNoteHash(serverNote);

        // 如果本地已有相同内容的笔记，跳过
        if (localHashes.contains(noteHash)) {
          continue;
        }

        final localNote = localNotesById[serverNote.id];
        final noteToSave = localNote == null
            ? serverNote
            : _mergeServerNoteWithLocalState(serverNote, localNote);
        await _databaseService.saveNote(noteToSave);
        syncedCount++;
      }

      // 刷新内存中的列表
      await loadNotesFromLocal();

      debugPrint('成功同步 $syncedCount 条笔记到本地');
      return true;
    } on Object catch (e) {
      debugPrint('同步云端数据到本地失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 使用账号密码注册
  Future<(bool, String?)> registerWithPassword(
    String serverUrl,
    String username,
    String password, {
    bool remember = false,
  }) async {
    try {
      debugPrint('AppProvider: 尝试注册账号 - URL: $serverUrl, 用户名: $username');

      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      // 调用注册API
      final response = await http.post(
        Uri.parse('$normalizedUrl/api/v1/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      debugPrint('AppProvider: 注册API响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('AppProvider: 注册成功，尝试自动登录');

        // 注册成功后自动登录
        final loginResult = await loginWithPassword(
          serverUrl,
          username,
          password,
          remember: remember,
        );

        if (loginResult.$1) {
          debugPrint('AppProvider: 注册并登录成功');
          return (true, null);
        } else {
          debugPrint('AppProvider: 注册成功但自动登录失败: ${loginResult.$2}');
          return (false, '注册成功，请手动登录');
        }
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final serverMessage = errorData['message']?.toString() ?? '';
        String userFriendlyMessage;

        // 根据HTTP状态码和服务器消息提供用户友好的错误提示
        switch (response.statusCode) {
          case 400:
            if (serverMessage.toLowerCase().contains('invalid username')) {
              userFriendlyMessage = '用户名格式不正确\n只能包含字母、数字、下划线和连字符';
            } else if (serverMessage.toLowerCase().contains('username') &&
                serverMessage.toLowerCase().contains('exists')) {
              userFriendlyMessage = '用户名已存在，请选择其他用户名';
            } else if (serverMessage.toLowerCase().contains('password')) {
              userFriendlyMessage = '密码不符合要求，请重新设置';
            } else if (serverMessage
                .toLowerCase()
                .contains('failed to create user')) {
              userFriendlyMessage = '创建用户失败，用户名可能已存在';
            } else {
              userFriendlyMessage = '注册信息有误，请检查后重试';
            }
            break;
          case 401:
            if (serverMessage.toLowerCase().contains('signup is disabled') ||
                serverMessage.toLowerCase().contains('disallow')) {
              userFriendlyMessage = '该服务器已禁用用户注册功能\n请联系管理员或使用现有账号登录';
            } else if (serverMessage
                .toLowerCase()
                .contains('password login is deactivated')) {
              userFriendlyMessage = '该服务器已禁用密码登录功能\n请联系管理员';
            } else {
              userFriendlyMessage = '注册功能已被管理员禁用，请联系管理员';
            }
            break;
          case 403:
            userFriendlyMessage = '注册功能已被管理员禁用，请联系管理员';
            break;
          case 409:
            userFriendlyMessage = '用户名已被占用，请选择其他用户名';
            break;
          case 429:
            userFriendlyMessage = '注册请求过于频繁，请稍后再试';
            break;
          case 500:
            if (serverMessage.toLowerCase().contains('failed to create user')) {
              userFriendlyMessage = '创建用户失败，可能是用户名已存在或服务器配置问题';
            } else if (serverMessage
                .toLowerCase()
                .contains('failed to generate password hash')) {
              userFriendlyMessage = '密码处理失败，请重新尝试';
            } else {
              userFriendlyMessage = '服务器内部错误，请稍后重试或联系管理员';
            }
            break;
          case 503:
            userFriendlyMessage = '服务器暂时不可用，请稍后重试';
            break;
          default:
            userFriendlyMessage = '注册失败，请检查网络连接和服务器地址';
        }

        debugPrint('AppProvider: 注册失败: $serverMessage');
        return (false, userFriendlyMessage);
      }
    } on Object catch (e) {
      debugPrint('AppProvider: 注册异常: $e');
      String userFriendlyMessage;

      // 根据异常类型提供用户友好的错误提示
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        userFriendlyMessage = '网络连接失败，请检查网络设置';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyMessage = '连接超时，请检查网络或稍后重试';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Invalid')) {
        userFriendlyMessage = '服务器响应格式错误，请检查服务器地址';
      } else if (e.toString().contains('HandshakeException') ||
          e.toString().contains('TlsException')) {
        userFriendlyMessage = 'SSL连接失败，请检查服务器证书';
      } else {
        userFriendlyMessage = '注册失败，请检查服务器地址和网络连接';
      }

      return (false, userFriendlyMessage);
    }
  }

  // 使用账号密码登录
  Future<(bool, String?)> loginWithPassword(
    String serverUrl,
    String username,
    String password, {
    bool remember = false,
  }) async {
    try {
      debugPrint('AppProvider: 尝试使用账号密码登录 - URL: $serverUrl, 用户名: $username');

      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      final tokenService = MemosApiServiceFixed(baseUrl: normalizedUrl);
      final token = await tokenService.createAccessToken(username, password);
      final serverVersion =
          await MemosApiServiceFixed.getServerVersion(normalizedUrl);
      debugPrint('AppProvider: 服务器版本: 0.$serverVersion.x');

      final userInfoService = MemosApiServiceFixed(
        baseUrl: normalizedUrl,
        token: token,
      );
      final apiUser = await userInfoService.getUserInfo();

      final user = apiUser.copyWith(
        token: token,
        username: apiUser.username.isNotEmpty ? apiUser.username : username,
        serverUrl: normalizedUrl,
      );

      // 保存用户信息到持久化存储和内存
      await _preferencesService.saveUser(user);
      _user = user;

      // 注意：新token登录成功后，服务器端的旧token应该会自动失效
      // 这是大多数现代认证系统的标准行为
      // 如果服务器不支持自动撤销旧token，可以考虑：
      // 1. 在登录前调用logout API撤销旧token（需要旧token仍有效）
      // 2. 设置更短的token过期时间
      // 3. 要求服务器端实现单点登录机制

      // 更新应用配置
      _appConfig = _appConfig.copyWith(
        memosApiUrl: normalizedUrl,
        lastToken: remember ? token : null,
        lastUsername: remember ? username : null,
        lastServerUrl: normalizedUrl,
        rememberLogin: remember,
        autoLogin: true, // 登录成功后自动开启自动登录
        isLocalMode: false, // 登录成功后切换到在线模式
      );

      // 保存配置更新
      await _preferencesService.saveAppConfig(_appConfig);

      // 如果选择记住登录，保存到安全存储
      if (remember) {
        await saveLoginInfo(
          normalizedUrl,
          username,
          token: token,
          password: password,
        );
      }

      // 初始化API服务
      _memosApiService = await ApiServiceFactory.createApiService(
        baseUrl: normalizedUrl,
        token: token,
      ) as MemosApiServiceFixed;

      // 初始化资源服务
      _resourceService = MemosResourceService(
        baseUrl: normalizedUrl,
        token: token,
        serverVersion: serverVersion,
      );

      debugPrint('AppProvider: 账号密码登录成功');
      notifyListeners();

      // 🖼️ 预加载用户头像（提升用户体验）
      _preloadUserAvatarAsync();

      return (true, null);
    } on Object catch (e) {
      debugPrint('AppProvider: 账号密码登录失败: $e');
      String userFriendlyMessage;

      // 根据异常类型给出通俗易懂的错误提示
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        userFriendlyMessage = '网络连接失败，请检查手机网络是否正常，或切换 Wi-Fi / 移动网络后重试';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyMessage = '连接超时，服务器响应太慢了，请检查网络后重试';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Invalid')) {
        userFriendlyMessage = '服务器地址可能不对，请确认地址格式正确，例如：https://demo.memos.app';
      } else if (e.toString().contains('HandshakeException') ||
          e.toString().contains('TlsException')) {
        userFriendlyMessage = '连接服务器时安全验证失败，请检查服务器地址是否使用了 https://';
      } else {
        userFriendlyMessage = '登录时出现问题，请检查网络和服务器地址后重试';
      }

      return (false, userFriendlyMessage);
    }
  }

  // 使用Token登录
  Future<(bool, String?)> loginWithToken(
    String serverUrl,
    String token, {
    bool remember = false,
  }) async {
    try {
      debugPrint('AppProvider: 尝试使用Token登录 - URL: $serverUrl');

      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      // 初始化API服务
      _memosApiService = await ApiServiceFactory.createApiService(
        baseUrl: normalizedUrl,
        token: token,
      ) as MemosApiServiceFixed;

      // 初始化资源服务
      final serverVersion =
          await MemosApiServiceFixed.getServerVersion(normalizedUrl);
      _resourceService = MemosResourceService(
        baseUrl: normalizedUrl,
        token: token,
        serverVersion: serverVersion,
      );

      // 验证Token并获取用户信息（版本感知，由 MemosApiServiceFixed 自动处理）
      try {
        debugPrint('AppProvider: 验证Token并获取用户信息');
        final apiUser = await _memosApiService!.getUserInfo();

        final user = User(
          id: apiUser.id,
          username: apiUser.username,
          nickname: apiUser.nickname,
          email: apiUser.email,
          avatarUrl: apiUser.avatarUrl,
          role: apiUser.role,
          token: token,
          lastSyncTime: DateTime.now(),
        );

        debugPrint('AppProvider: 用户信息解析成功: ${user.username}');

        // 保存用户信息
        await _preferencesService.saveUser(user);
        _user = user;

        // 更新配置
        final updatedConfig = _appConfig.copyWith(
          memosApiUrl: normalizedUrl,
          lastToken: remember ? token : null,
          rememberLogin: remember,
          isLocalMode: false,
        );
        await updateConfig(updatedConfig);

        debugPrint('AppProvider: Token登录成功');

        // 🖼️ 预加载用户头像（提升用户体验）
        _preloadUserAvatarAsync();

        // 检查本地是否有未同步笔记
        final hasLocalNotes = await hasLocalData();
        if (hasLocalNotes) {
          debugPrint('AppProvider: 检测到本地有笔记数据，需要同步');
        }

        return (true, null);
      } on Object catch (e, stackTrace) {
        debugPrint('AppProvider: 验证Token失败: $e');
        debugPrint('AppProvider: 错误堆栈: $stackTrace');
        throw Exception('验证Token失败: $e');
      }
    } on Object catch (e, stackTrace) {
      debugPrint('AppProvider: Token登录失败: $e');
      debugPrint('AppProvider: 错误堆栈: $stackTrace');
      return (false, e.toString());
    }
  }

  // 登录后检查本地数据并提示用户是否需要同步
  Future<void> checkAndSyncOnLogin() async {
    try {
      debugPrint('AppProvider: 登录后检查本地数据');

      // 检查本地是否有数据
      final hasLocalData = await this.hasLocalData();

      if (hasLocalData) {
        debugPrint('AppProvider: 检测到本地有数据');

        // 本地有数据，从服务器获取数据时会自动保留本地未同步的笔记
        // fetchNotesFromServer方法已经被修改，会处理本地未同步笔记
        await fetchNotesFromServer();

        // 这里已经不需要返回状态让UI处理了，因为修改后的同步流程会自动处理
        return;
      } else {
        debugPrint('AppProvider: 本地无数据，直接获取服务器数据');
        // 直接获取服务器数据
        await fetchNotesFromServer();
      }
    } on Object catch (e) {
      debugPrint('AppProvider: 检查同步状态失败: $e');
      // 出错时，至少确保加载了数据
      await loadNotesFromLocal();
    }
  }

  // 同步本地引用关系到服务器
  Future<int> syncLocalReferencesToServer() async {
    if (!isLoggedIn || _memosApiService == null) {
      if (kDebugMode) {
        debugPrint('AppProvider: 未登录或API服务未初始化，无法同步引用关系');
      }
      return 0;
    }

    try {
      final localRefService = LocalReferenceService.instance;
      final unsyncedRefs = await localRefService.getUnsyncedReferences();

      if (unsyncedRefs.isEmpty) {
        if (kDebugMode) {
          debugPrint('AppProvider: 没有未同步的引用关系');
        }
        return 0;
      }

      var syncedCount = 0;
      for (final refData in unsyncedRefs) {
        try {
          final noteId = refData['noteId'] as String;
          final relation = refData['relation'] as Map<String, dynamic>;

          // 调用服务器API同步引用关系
          final success = await _syncSingleReferenceToServer(noteId, relation);

          if (success) {
            // 标记为已同步
            await localRefService.markReferenceAsSynced(noteId, relation);
            syncedCount++;
          }
        } on Object catch (_) {
          // Continue syncing the remaining queued references.
        }
      }

      return syncedCount;
    } on Object {
      return 0;
    }
  }

  // 同步单个引用关系到服务器 (使用v1 API)
  Future<bool> _syncSingleReferenceToServer(
    String noteId,
    Map<String, dynamic> relation,
  ) async {
    try {
      final relatedMemoId = relation['relatedMemoId']?.toString();
      if (relatedMemoId == null || _memosApiService == null) {
        return false;
      }

      return _memosApiService!.addMemoReference(noteId, relatedMemoId);
    } on Object {
      return false;
    }
  }

  // 同步本地数据到服务器
  Future<bool> syncLocalDataToServer() async {
    // 后台静默同步，不显示状态

    if (!isLoggedIn || _memosApiService == null) {
      debugPrint('AppProvider: 未登录或API服务未初始化，无法同步');
      // 后台同步失败，静默处理
      return false;
    }

    try {
      debugPrint('AppProvider: 开始同步本地数据到云端');

      // 获取本地未同步的笔记（后台执行）

      final unsyncedNotes = await _databaseService.getUnsyncedNotes();
      debugPrint('AppProvider: 发现 ${unsyncedNotes.length} 条未同步的笔记');

      if (unsyncedNotes.isEmpty) {
        // 所有笔记已同步（静默处理）

        return true;
      }

      var syncedCount = 0;
      for (var i = 0; i < unsyncedNotes.length; i++) {
        final note = unsyncedNotes[i];
        // 正在后台同步笔记 ${i + 1}/${unsyncedNotes.length}

        try {
          await _syncUnsyncedNoteToMemos(note);
          syncedCount++;
        } on Object catch (e) {
          debugPrint('AppProvider: 同步笔记失败: ${note.id}, 错误: $e');
          continue;
        }
      }

      debugPrint('AppProvider: 成功同步 $syncedCount 条笔记到云端');

      // 同步引用关系
      _syncMessage = '同步引用关系...';
      notifyListeners();

      final refSyncedCount = await syncLocalReferencesToServer();
      if (refSyncedCount > 0) {
        debugPrint('AppProvider: 成功同步 $refSyncedCount 个引用关系到云端');
      }

      // 从服务器获取最新数据
      // 后台刷新最新数据

      await fetchNotesFromServer();

      // 后台同步完成

      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 后台同步失败: $e');
      // 同步失败也静默处理，不影响用户体验
      return false;
    }
  }

  // 从文本内容中提取标签（改进版，排除URL中的#）
  List<String> extractTags(String content) {
    // 使用统一的标签提取逻辑（与Note.extractTagsFromContent一致）
    return note_tags.extractTags(content);
  }

  // 获取所有标签
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  // 排序笔记
  void sortNotes(SortOrder order) {
    _notes.sort(noteComparator(order));
    notifyListeners();
  }

  // 切换笔记的置顶状态
  Future<bool> togglePinStatus(Note note) async {
    try {
      // 切换置顶状态
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );

      // 更新本地数据库
      await _databaseService.updateNote(updatedNote);

      // 先立即更新内存中的列表，让UI快速响应
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }

      // 立即通知UI更新
      notifyListeners();

      // 如果是在线模式且已登录，尝试同步到服务器
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        try {
          // 🔥 使用专门的 memo_organizer API 来更新置顶状态
          final serverNote = await _memosApiService!.updateMemoOrganizer(
            note.id,
            pinned: updatedNote.isPinned,
          );

          final syncedNote = _mergeServerNoteWithLocalState(
            serverNote,
            updatedNote,
            preserveLocalTimeline: true,
          ).copyWith(isPinned: updatedNote.isPinned);
          await _databaseService.updateNote(syncedNote);

          // 更新内存中的列表为服务器返回的数据
          final serverIndex = _notes.indexWhere((n) => n.id == note.id);
          if (serverIndex != -1) {
            _notes[serverIndex] = syncedNote;
          }

          debugPrint('置顶状态已同步到服务器: ${updatedNote.isPinned}');
        } on Object catch (e) {
          // 如果同步失败，本地状态已经更新，不需要额外处理
          debugPrint('同步置顶状态到服务器失败（正常，本地笔记或网络问题）: $e');
        }
      }

      // 重新排序笔记列表
      final currentOrder = _getCurrentSortOrder();
      sortNotes(currentOrder);

      return true;
    } on Object catch (e) {
      debugPrint('切换置顶状态失败: $e');
      return false;
    }
  }

  // 获取当前的排序方式
  SortOrder _getCurrentSortOrder() => inferCurrentSortOrder(_notes);

  // 切换到本地模式
  Future<void> switchToLocalMode() async {
    _appConfig = _appConfig.copyWith(isLocalMode: true);
    await _preferencesService.saveAppConfig(_appConfig);
    notifyListeners();
  }

  // 退出登录
  Future<(bool, String?)> logout({
    bool force = false,
    bool keepLocalData = true,
  }) async {
    if (!force) {
      _setLoading(true);
    } else {
      // 设置同步状态
      _setSyncUi(syncing: true, message: '正在处理退出登录...');
    }

    try {
      // 检查是否有未同步的笔记
      if (!force && !_appConfig.isLocalMode && isLoggedIn) {
        final unsyncedNotes = await _databaseService.getUnsyncedNotes();
        if (unsyncedNotes.isNotEmpty) {
          _setLoading(false);
          return (
            false,
            '有${unsyncedNotes.length}条笔记未同步到云端，退出登录后这些笔记将无法同步。确定要退出吗？'
          );
        }
      }

      // 如果不保留本地数据，则清空数据库
      if (!keepLocalData) {
        _setSyncMessage('清空本地数据库...');

        debugPrint('AppProvider: 清空本地数据库');
        await _databaseService.clearAllNotes();
      } else {
        _setSyncMessage('保存本地数据...');

        debugPrint('AppProvider: 保留本地数据');
      }

      // 取消同步定时器
      _syncTimer?.cancel();
      _syncTimer = null;

      // 🔐 在清除本地信息前，先撤销服务器端的token
      if (_memosApiService != null && !_appConfig.isLocalMode) {
        _setSyncMessage('撤销服务器token...');

        try {
          await _memosApiService!.logout();
          if (kDebugMode) {
            debugPrint('AppProvider: 服务器token撤销成功');
          }
        } on Object catch (e) {
          if (kDebugMode) {
            debugPrint('AppProvider: 服务器token撤销失败: $e');
          }
          // 继续执行，不阻塞登出流程
        }
      }

      // 清除用户信息
      _user = null;
      await _preferencesService.clearUser();

      _setSyncMessage('清除登录信息...');

      // 🔐 总是清除 token（退出登录后不应该自动登录）
      // 但如果之前选择了"记住密码"，保留 username 和 password
      final rememberLogin = _appConfig.rememberLogin;

      if (rememberLogin) {
        // 只清除 token，保留 username 和 password
        await _preferencesService.clearLoginInfo();
        debugPrint('AppProvider: 已清除 token，保留用户名和密码');
      } else {
        // 清除所有登录信息（包括 username、password、token）
        await _preferencesService.clearAllSecureData();
        debugPrint('AppProvider: 已清除所有登录信息');
      }

      _setSyncMessage('更新配置...');

      // 更新配置为本地模式，不保留 token
      _appConfig = _appConfig.copyWith(
        isLocalMode: true,
        rememberLogin: rememberLogin,
        lastServerUrl: rememberLogin ? _appConfig.lastServerUrl : null,
      );
      await _preferencesService.saveAppConfig(_appConfig);

      // 清除API服务
      _apiService = null;
      _memosApiService = null;

      // 重新加载本地笔记
      if (keepLocalData) {
        _setSyncMessage('加载本地笔记...');

        await loadNotesFromLocal();
      } else {
        _notes = [];
      }

      _setSyncMessage('退出登录完成');

      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setSyncUi(syncing: false);
        }
      });

      return (true, null);
    } on Object catch (e) {
      debugPrint('退出登录失败: $e');

      _setSyncMessage('退出登录失败: ${sync_status.shortFirstLine(e)}');

      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _setSyncUi(syncing: false, notify: false);
          _setLoading(false);
          notifyListeners();
        }
      });

      return (false, '退出登录失败: $e');
    } finally {
      if (!force) {
        _setLoading(false);
      }
    }
  }

  // 仅获取服务器数据
  Future<bool> fetchServerDataOnly() async {
    debugPrint('AppProvider: 仅获取服务器数据');
    try {
      // 获取服务器数据
      await fetchNotesFromServer();
      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 获取服务器数据失败: $e');
      return false;
    }
  }

  // 创建笔记（支持自定义时间戳，用于撤销删除）
  Future<Note> createNote(
    String content, {
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    debugPrint('AppProvider: 开始创建笔记');
    try {
      // 提取标签
      final tags = extractTags(content);
      debugPrint('AppProvider: 提取标签: $tags');

      // 时间戳（如果未提供则使用当前时间）
      final now = DateTime.now();
      final noteCreatedAt = createdAt ?? now;
      final noteUpdatedAt = updatedAt ?? now;

      // 创建笔记对象
      final note = Note(
        id: const Uuid().v4(),
        content: content,
        tags: tags,
        createdAt: noteCreatedAt,
        updatedAt: noteUpdatedAt,
      );

      // 本地优先保存。在线发布由后台同步完成，避免弱网阻塞记录动作。
      debugPrint('AppProvider: 本地优先保存');
      await _databaseService.saveNote(note);

      // 添加到内存列表
      _notes.insert(0, note); // 添加到列表顶部而不是末尾

      // 🔧 修复：处理引用关系
      await _processNoteReferences(note);

      // 确保置顶笔记仍在最前面
      _applyCurrentSort();

      notifyListeners();

      // 🚀 自动同步到 Notion（异步执行，不阻塞UI）
      unawaited(_autoSyncToNotion());

      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        unawaited(
          Future.microtask(() async {
            try {
              await syncNotesWithServer();
            } on Object catch (e) {
              debugPrint('AppProvider: 后台同步新笔记失败: $e');
            }
          }),
        );
      }

      return note;
    } on Object catch (e) {
      debugPrint('AppProvider: 创建笔记失败: $e');
      throw Exception('创建笔记失败: $e');
    }
  }

  // 应用当前排序规则
  void _applyCurrentSort() {
    final currentOrder = _getCurrentSortOrder();
    sortNotes(currentOrder);
  }

  // 更新笔记
  Future<bool> updateNote(Note note, String newContent) async {
    debugPrint('AppProvider: 开始更新笔记 ID: ${note.id}');
    try {
      // 更新内容
      debugPrint('AppProvider: 创建更新后的笔记对象');
      final updatedNote = note.copyWith(
        content: newContent,
        updatedAt: DateTime.now(), // 自动更新为当前时间
        isSynced: false,
      );

      debugPrint(
        'AppProvider: updatedAt - 原始: ${note.updatedAt}, 新: ${updatedNote.updatedAt}',
      );

      // 提取标签
      debugPrint('AppProvider: 提取标签');
      final tags = extractTags(newContent);
      debugPrint('AppProvider: 提取到的标签: ${tags.join(', ')}');
      final noteWithTags = updatedNote.copyWith(tags: tags);

      // 更新本地数据库
      debugPrint('AppProvider: 更新本地数据库');
      await _databaseService.updateNote(noteWithTags);

      // ✅ 立即更新内存中的笔记（包含批注）
      final memIndex = _notes.indexWhere((n) => n.id == note.id);
      if (memIndex != -1) {
        _notes[memIndex] = noteWithTags;
      }

      // 如果是在线模式且已登录，尝试同步到服务器
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        try {
          debugPrint('AppProvider: 尝试同步到服务器，笔记ID: ${noteWithTags.id}');
          final uploadableNote = await _prepareNoteForMemosUpload(noteWithTags);

          // 使用Memos API更新笔记
          final serverNote = await _memosApiService!.updateMemo(
            uploadableNote.id,
            content: uploadableNote.content,
            visibility: uploadableNote.visibility,
          );

          // 检查返回的笔记ID是否与原笔记ID不同
          if (serverNote.id != uploadableNote.id) {
            debugPrint(
              'AppProvider: 服务器返回了新的笔记ID: ${serverNote.id}，原ID: ${uploadableNote.id}',
            );
            // 删除本地旧笔记
            await _databaseService.deleteNote(uploadableNote.id);

            // 保存新笔记
            final newSyncedNote =
                _mergeServerNoteWithLocalState(serverNote, uploadableNote);
            await _databaseService.saveNote(newSyncedNote);

            // 更新内存中的列表 - 删除旧笔记
            _notes.removeWhere((n) => n.id == uploadableNote.id);
            // 添加新笔记
            _notes.insert(0, newSyncedNote); // 添加到列表顶部

            _applyCurrentSort();
            notifyListeners();
            debugPrint('AppProvider: 笔记已作为新笔记保存（ID已更改）');
            return true;
          }

          debugPrint('AppProvider: 服务器同步成功，更新同步状态');

          // 🔧 重要修复：保护本地引用关系和批注数据
          // 获取当前内存中的笔记（包含本地引用关系和批注）
          final index = _notes.indexWhere((n) => n.id == note.id);
          var existingRelations = <Map<String, dynamic>>[];
          var existingAnnotations = <Annotation>[]; // ✅ 保护批注

          if (index != -1) {
            existingRelations = _notes[index].relations;
            existingAnnotations = _notes[index].annotations; // ✅ 保护批注
          }

          final syncedNote = _mergeServerNoteWithLocalState(
            serverNote,
            uploadableNote.copyWith(
              tags: tags,
              relations: existingRelations,
              annotations: existingAnnotations,
            ),
          );
          await _databaseService.updateNote(syncedNote);

          // 更新内存中的列表
          if (index != -1) {
            debugPrint('AppProvider: 更新内存中的笔记（保留本地引用关系）');
            _notes[index] = syncedNote;
          }

          // 处理引用关系
          await _processNoteReferences(syncedNote);

          // 应用当前排序并通知UI更新
          _applyCurrentSort();
          notifyListeners();

          debugPrint('AppProvider: 笔记更新完成（已同步到服务器）');
          return true;
        } on Object catch (e) {
          debugPrint('AppProvider: 同步到服务器失败: $e');
          // 如果同步失败，保持本地更新
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = noteWithTags;
          }

          // 即使服务器同步失败，也要处理引用关系
          await _processNoteReferences(noteWithTags);

          _applyCurrentSort();
          notifyListeners();
          debugPrint('AppProvider: 笔记更新完成（仅本地更新）');

          // 🚀 自动同步到 Notion（异步执行，不阻塞UI）
          unawaited(_autoSyncToNotion());

          return true;
        }
      } else {
        // 本地模式直接更新内存中的列表
        debugPrint('AppProvider: 本地模式更新');
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          debugPrint('AppProvider: 找到笔记在列表中的位置: $index');
          debugPrint('AppProvider: 更新前的updatedAt: ${_notes[index].updatedAt}');
          _notes[index] = noteWithTags;
          debugPrint('AppProvider: 更新后的updatedAt: ${_notes[index].updatedAt}');
        } else {
          debugPrint('AppProvider: ⚠️ 在内存列表中找不到笔记！');
        }

        // 本地模式也要处理引用关系
        await _processNoteReferences(noteWithTags);

        _applyCurrentSort();
        debugPrint('AppProvider: 调用notifyListeners()');
        notifyListeners();
        debugPrint('AppProvider: 笔记本地更新完成');

        // 🚀 自动同步到 Notion（异步执行，不阻塞UI）
        unawaited(_autoSyncToNotion());

        return true;
      }
    } on Object catch (e) {
      debugPrint('AppProvider: 更新笔记失败: $e');
      return false;
    }
  }

  // 🕐 仅更新本地笔记（不同步到服务器）
  // 用于修改时间等纯本地操作
  Future<bool> updateNoteLocally(Note note) async {
    try {
      debugPrint('AppProvider: 开始本地更新笔记 ID: ${note.id}');

      // 更新本地数据库
      await _databaseService.updateNote(note);
      debugPrint('AppProvider: 本地数据库更新完成');

      // 更新内存中的笔记
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        debugPrint('AppProvider: 内存更新完成，位置: $index');
      } else {
        debugPrint('AppProvider: ⚠️ 在内存列表中找不到笔记！');
      }

      // 应用排序并通知UI更新
      _applyCurrentSort();
      notifyListeners();
      debugPrint('AppProvider: 本地更新完成');

      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 本地更新笔记失败: $e');
      return false;
    }
  }

  Future<Note?> setNoteVisibility(Note note, String visibility) async {
    final normalizedVisibility = visibility.toUpperCase();
    try {
      final uploadableNote = await _prepareNoteForMemosUpload(note);
      final optimisticNote = uploadableNote.copyWith(
        visibility: normalizedVisibility,
        isSynced: false,
      );
      await _databaseService.updateNote(optimisticNote);

      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = optimisticNote;
        notifyListeners();
      }

      if (_appConfig.isLocalMode || !isLoggedIn || _memosApiService == null) {
        return optimisticNote;
      }

      final serverNote = await _memosApiService!.updateMemoVisibility(
        optimisticNote.id,
        content: optimisticNote.content,
        visibility: normalizedVisibility,
      );
      final syncedNote = _mergeServerNoteWithLocalState(
        serverNote,
        optimisticNote,
      ).copyWith(visibility: normalizedVisibility);

      if (syncedNote.id != optimisticNote.id) {
        await _updateReferenceIdsAfterSync(optimisticNote.id, syncedNote.id);
        await _databaseService.deleteNote(optimisticNote.id);
        await _databaseService.saveNote(syncedNote);
        _notes.removeWhere((n) => n.id == optimisticNote.id);
        _notes.insert(0, syncedNote);
        _applyCurrentSort();
        notifyListeners();
        return syncedNote;
      }

      await _databaseService.updateNote(syncedNote);
      final syncedIndex = _notes.indexWhere((n) => n.id == optimisticNote.id);
      if (syncedIndex != -1) {
        _notes[syncedIndex] = syncedNote;
        notifyListeners();
      }
      return syncedNote;
    } on Object catch (e) {
      debugPrint('AppProvider: 更新笔记可见性失败: $e');
      return null;
    }
  }

  // 🏷️ 更新笔记标签（用于标签管理操作）
  Future<bool> updateNoteTags(String noteId, List<String> newTags) async {
    try {
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index == -1) {
        debugPrint('AppProvider: 笔记不存在: $noteId');
        return false;
      }

      final note = _notes[index];
      final updatedNote = note.copyWith(
        tags: newTags,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // 更新本地数据库
      await _databaseService.updateNote(updatedNote);

      // 更新内存
      _notes[index] = updatedNote;

      // 如果是在线模式且已登录，尝试同步到服务器
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        try {
          await _syncUnsyncedNoteToMemos(updatedNote);
        } on Object catch (e) {
          debugPrint('AppProvider: 同步标签到服务器失败: $e');
        }
      }

      notifyListeners();
      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 更新笔记标签失败: $e');
      return false;
    }
  }

  // 🚀 乐观删除：立即更新UI，后台异步执行删除操作
  // 删除笔记（本地和服务器） - 使用乐观更新策略
  Future<bool> deleteNote(String id, {bool showSnackBar = false}) async {
    try {
      // 1. 🚀 立即从内存中删除并更新UI（乐观更新）
      final deletedNote = _notes.firstWhere((note) => note.id == id);
      final deletedIndex = _notes.indexWhere((note) => note.id == id);

      if (deletedIndex == -1) {
        debugPrint('AppProvider: 笔记不存在: $id');
        return false;
      }

      // 保存删除的笔记和位置，用于撤销
      _lastDeletedNote = deletedNote;
      _lastDeletedIndex = deletedIndex;

      // 立即从列表中移除
      _notes.removeAt(deletedIndex);
      notifyListeners(); // ⚡ UI立即刷新

      debugPrint('AppProvider: ⚡ UI已更新（笔记已从列表移除）');

      // 2. 等撤销窗口结束后再真实删除本地和远端，避免撤销时远端已丢失。
      _pendingDeleteCommitTimer?.cancel();
      _pendingDeleteCommitTimer = Timer(deleteUndoWindow, () {
        _pendingDeleteCommitTimer = null;
        if (_lastDeletedNote?.id == id) {
          _lastDeletedNote = null;
          _lastDeletedIndex = null;
        }
        unawaited(_performBackgroundDelete(id));
      });

      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 删除笔记失败: $e');
      return false;
    }
  }

  // 🔄 后台执行删除操作（大厂级批量处理）
  Future<void> _performBackgroundDelete(String id) async {
    // 添加到删除队列
    _deleteQueue.add(id);

    // 取消之前的定时器
    _deleteDebounceTimer?.cancel();

    // 设置新的定时器：500ms内的删除请求会被合并
    _deleteDebounceTimer = Timer(_deleteBatchDelay, () {
      if (!_isProcessingDelete) {
        _processDeleteQueue();
      }
    });
  }

  // 📦 处理删除队列（大厂级批量删除，智能协调）
  Future<void> _processDeleteQueue() async {
    if (_isProcessingDelete || _deleteQueue.isEmpty) {
      return;
    }

    _isProcessingDelete = true;

    // 1. 🔒 暂停自动同步，避免冲突
    final wasSyncing = _syncTimer?.isActive ?? false;
    _syncTimer?.cancel();

    // 2. 📦 批量处理本地数据库（一次性事务）
    try {
      final idsToDelete = List<String>.from(_deleteQueue);
      _deleteQueue.clear();

      // 批量删除本地数据
      for (final id in idsToDelete) {
        if (_notes.any((note) => note.id == id)) {
          continue;
        }
        try {
          await _databaseService.deleteNote(id);
          await _cleanupReferencesForDeletedNote(id);
        } on Object {
          // 单个失败不影响其他
        }
      }

      // 3. 🌐 批量同步到服务器（并发请求）
      if (!_appConfig.isLocalMode && isLoggedIn && _memosApiService != null) {
        final deleteFutures = idsToDelete.map((id) async {
          try {
            await _memosApiService!.deleteMemo(id);
          } on Object {
            // 服务器删除失败不影响用户体验
          }
        });

        // 并发执行，但有超时保护
        await Future.wait(deleteFutures).timeout(
          const Duration(seconds: 10),
          onTimeout: () => [],
        );
      }
    } on Object {
      // 批量处理失败，记录但不影响UI
    }

    // 4. ✅ 恢复自动同步
    if (wasSyncing) {
      startAutoSync();
    }

    _isProcessingDelete = false;

    // 5. 如果队列中又有新的删除请求，继续处理
    if (_deleteQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      unawaited(_processDeleteQueue());
    }
  }

  // 🔙 撤销删除笔记
  Future<bool> restoreNote() async {
    if (_lastDeletedNote == null || _lastDeletedIndex == null) {
      debugPrint('AppProvider: 没有可撤销的删除操作');
      return false;
    }

    try {
      debugPrint('AppProvider: 🔙 开始撤销删除笔记 ID: ${_lastDeletedNote!.id}');
      _pendingDeleteCommitTimer?.cancel();
      _pendingDeleteCommitTimer = null;
      _deleteQueue.remove(_lastDeletedNote!.id);

      // 1. 恢复到内存列表
      _notes.insert(_lastDeletedIndex!, _lastDeletedNote!);
      notifyListeners(); // ⚡ UI立即刷新

      debugPrint('AppProvider: ⚡ UI已更新（笔记已恢复到列表）');

      // 2. 后台恢复到数据库
      await _databaseService.saveNote(_lastDeletedNote!);

      // 3. 清理临时变量
      _lastDeletedNote = null;
      _lastDeletedIndex = null;

      return true;
    } on Object {
      return false;
    }
  }

  // 仅从本地数据库删除笔记
  Future<bool> deleteNoteLocal(String id) async {
    debugPrint('AppProvider: 从本地数据库删除笔记 ID: $id');
    try {
      // 删除本地数据库中的笔记
      await _databaseService.deleteNote(id);

      // 从内存中的列表删除
      _notes.removeWhere((note) => note.id == id);

      // 🔧 新增：立即清理所有相关的引用关系
      await _cleanupReferencesForDeletedNote(id);

      notifyListeners();

      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 从本地删除笔记失败: $e');
      throw Exception('删除本地笔记失败: $e');
    }
  }

  /// 🔧 新增：清理被删除笔记的所有相关引用关系
  Future<void> _cleanupReferencesForDeletedNote(String deletedNoteId) async {
    try {
      var hasChanges = false;

      // 遍历所有剩余笔记，清理指向被删除笔记的引用关系
      for (var i = 0; i < _notes.length; i++) {
        final note = _notes[i];
        final originalRelationsCount = note.relations.length;

        // 过滤掉所有与被删除笔记相关的引用关系
        final cleanedRelations = note.relations.where((relation) {
          final memoId = relation['memoId']?.toString();
          final relatedMemoId = relation['relatedMemoId']?.toString();

          // 删除所有涉及被删除笔记的关系
          return memoId != deletedNoteId && relatedMemoId != deletedNoteId;
        }).toList();

        if (cleanedRelations.length != originalRelationsCount) {
          final updatedNote = note.copyWith(relations: cleanedRelations);
          await _databaseService.updateNote(updatedNote);
          _notes[i] = updatedNote;
          hasChanges = true;

          if (kDebugMode) {
            debugPrint(
              'AppProvider: 清理 ${originalRelationsCount - cleanedRelations.length} 条失效引用',
            );
          }
        }
      }

      if (hasChanges) {}
    } on Object catch (_) {
      // Invalid relation cleanup is non-critical maintenance.
    }
  }

  // 仅从服务器删除笔记
  Future<bool> deleteNoteFromServer(String id) async {
    debugPrint('AppProvider: 从服务器删除笔记 ID: $id');
    try {
      if (!isLoggedIn || _memosApiService == null) {
        debugPrint('AppProvider: 未登录或API服务不可用');
        return false;
      }

      // 从服务器删除
      await _memosApiService!.deleteMemo(id);
      return true;
    } on Object catch (e) {
      debugPrint('AppProvider: 从服务器删除笔记失败: $e');
      throw Exception('从服务器删除笔记失败: $e');
    }
  }

  // NOTE: `fetchNotesFromServer` moved to `app_provider_sync.part.dart`.

  /// 🚀 快速从服务器刷新（增量同步）
  /// HomeScreen 下拉刷新依赖这个方法。
  Future<void> refreshFromServerFast() async {
    if (!isLoggedIn || _memosApiService == null) {
      return;
    }

    _setSyncUi(syncing: true, message: '正在快速同步...');
    try {
      _incrementalSyncService ??=
          IncrementalSyncService(_databaseService, _memosApiService);

      await _incrementalSyncService!.incrementalSync();

      // 同步后从本地重新加载，保证 UI/内存态一致
      await loadNotesFromLocal(reset: true);
    } on Object catch (e) {
      _setSyncMessage(sync_status.syncFailedMessage(e));
      rethrow;
    } finally {
      _setSyncUi(syncing: false);
    }
  }

  /// 当本地临时ID笔记上传到服务器后，ID 可能发生变化。
  /// 这里负责把所有 relations 中的旧ID替换为新ID，避免引用关系断裂。
  Future<void> _updateReferenceIdsAfterSync(String oldId, String newId) async {
    if (oldId == newId) {
      return;
    }

    Future<List<Map<String, dynamic>>> rewriteRelations(
      List<Map<String, dynamic>> relations,
    ) async {
      var changed = false;
      final updated = relations.map((rel) {
        final memoId = rel['memoId']?.toString();
        final relatedMemoId = rel['relatedMemoId']?.toString();

        final next = <String, dynamic>{...rel};
        if (memoId == oldId) {
          next['memoId'] = newId;
          changed = true;
        }
        if (relatedMemoId == oldId) {
          next['relatedMemoId'] = newId;
          changed = true;
        }
        return next;
      }).toList();
      return changed ? updated : relations;
    }

    var anyChanged = false;
    for (var i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      if (note.relations.isEmpty) {
        continue;
      }

      final nextRelations = await rewriteRelations(note.relations);
      if (!identical(nextRelations, note.relations)) {
        final updatedNote = note.copyWith(relations: nextRelations);
        _notes[i] = updatedNote;
        await _databaseService.updateNote(updatedNote);
        anyChanged = true;
      }
    }

    if (anyChanged) {
      notifyListeners();
    }
  }

  // 同步本地未同步的笔记到服务器
  Future<void> syncNotesWithServer() async {
    if (!isLoggedIn || _memosApiService == null) {
      return;
    }

    // 🚀 大厂标准：性能监控
    await PerformanceTracker().startTrace('sync_notes_to_server');
    Log.sync.info('Starting sync to server');

    try {
      // 获取未同步的笔记
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();

      if (unsyncedNotes.isEmpty) {
        Log.sync.debug('No unsynced notes');
        await PerformanceTracker().stopTrace(
          'sync_notes_to_server',
          metrics: {'note_count': 0},
        );
        return;
      }

      Log.sync.info('Syncing notes', data: {'count': unsyncedNotes.length});

      // 逐一同步到服务器
      var successCount = 0;
      for (final note in unsyncedNotes) {
        try {
          await _syncUnsyncedNoteToMemos(note);
          successCount++;
        } on Object catch (e, stackTrace) {
          Log.sync.error(
            'Failed to sync note',
            error: e,
            stackTrace: stackTrace,
            data: {
              'note_id': note.id,
            },
          );
          await ErrorHandler.captureException(
            e,
            stackTrace: stackTrace,
            context: {
              'operation': 'sync_single_note',
              'note_id': note.id,
            },
          );
        }
      }

      // 刷新内存中的列表
      await loadNotesFromLocal();

      // 🚀 大厂标准：成功监控
      await PerformanceTracker().stopTrace(
        'sync_notes_to_server',
        metrics: {
          'total_count': unsyncedNotes.length,
          'success_count': successCount,
          'failure_count': unsyncedNotes.length - successCount,
        },
      );
      Log.sync.info(
        'Sync completed',
        data: {
          'success': successCount,
          'failed': unsyncedNotes.length - successCount,
        },
      );
    } on Object catch (e, stackTrace) {
      // 🚀 大厂标准：错误监控
      await PerformanceTracker()
          .stopTrace('sync_notes_to_server', success: false);
      Log.sync.error('Sync to server failed', error: e, stackTrace: stackTrace);
      await ErrorHandler.captureException(
        e,
        stackTrace: stackTrace,
        context: {
          'operation': 'sync_notes_to_server',
        },
      );
    }
  }

  // 同步笔记到服务器
  Future<bool> syncNotesToServer() async {
    if (!isLoggedIn || _memosApiService == null) {
      return false;
    }

    try {
      // 获取未同步的笔记
      final unsyncedNotes = await _databaseService.getUnsyncedNotes();

      // 逐一同步到服务器
      for (final note in unsyncedNotes) {
        try {
          await _syncUnsyncedNoteToMemos(note);
        } on Object catch (e) {
          debugPrint('同步笔记失败: ${note.id} - $e');
        }
      }

      // 刷新内存中的列表
      await loadNotesFromLocal();
      return true;
    } on Object catch (e) {
      debugPrint('同步笔记到服务器失败: $e');
      return false;
    }
  }

  // 更新用户信息到服务器
  Future<bool> updateUserInfo({
    String? nickname,
    String? email,
    String? avatarUrl,
    String? description,
  }) async {
    if (!isLoggedIn || _memosApiService == null || _user == null) {
      return false;
    }

    _setLoading(true);

    try {
      // 使用Memos API更新用户信息
      final updatedUser = await _memosApiService!.updateUserInfo(
        nickname: nickname,
        email: email,
        avatarUrl: avatarUrl,
        description: description,
      );

      // 更新本地用户信息
      _user = updatedUser;
      await _preferencesService.saveUser(_user!);

      notifyListeners();
      return true;
    } on Object catch (e) {
      debugPrint('更新用户信息失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isLoggedIn || _memosApiService == null || _user == null) {
      return false;
    }

    _setLoading(true);
    try {
      return await _memosApiService!.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on Object catch (e) {
      debugPrint('更新密码失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 保存登录信息
  Future<void> saveLoginInfo(
    String server,
    String usernameOrToken, {
    String? token,
    String? password,
  }) async {
    debugPrint('AppProvider: 保存登录信息 - 服务器: $server');
    // 规范化URL（确保末尾没有斜杠）
    final normalizedUrl =
        server.endsWith('/') ? server.substring(0, server.length - 1) : server;

    // 生成一个刷新令牌（这里只是为了满足接口要求）
    final refreshToken = const Uuid().v4();

    // 如果提供了token参数，则usernameOrToken是用户名，否则是token（兼容旧版本）
    if (token != null) {
      // 新版本：保存用户名和token
      await _preferencesService.saveLoginInfo(
        token: token,
        refreshToken: refreshToken,
        serverUrl: normalizedUrl,
        username: usernameOrToken, // 这里是用户名
        password: password, // 保存密码（如果提供）
      );

      // 同时更新AppConfig
      final updatedConfig = _appConfig.copyWith(
        memosApiUrl: normalizedUrl,
        lastToken: token,
        lastUsername: usernameOrToken,
        lastServerUrl: normalizedUrl,
        rememberLogin: true,
      );
      await updateConfig(updatedConfig);
    } else {
      // 旧版本：usernameOrToken是token
      await _preferencesService.saveLoginInfo(
        token: usernameOrToken,
        refreshToken: refreshToken,
        serverUrl: normalizedUrl,
      );

      // 同时更新AppConfig
      final updatedConfig = _appConfig.copyWith(
        memosApiUrl: normalizedUrl,
        lastToken: usernameOrToken,
        lastServerUrl: normalizedUrl,
        rememberLogin: true,
      );
      await updateConfig(updatedConfig);
    }
  }

  // 清除登录信息
  Future<void> clearLoginInfo() async {
    await _preferencesService.clearLoginInfo();
  }

  // 获取保存的服务器地址
  Future<String?> getSavedServer() async =>
      _preferencesService.getSavedServer();

  // 获取保存的Token
  Future<String?> getSavedToken() async => _preferencesService.getSavedToken();

  // 获取保存的用户名
  Future<String?> getSavedUsername() async =>
      _preferencesService.getSavedUsername();

  // 获取保存的密码
  Future<String?> getSavedPassword() async =>
      _preferencesService.getSavedPassword();

  // 启动自动同步
  void startAutoSync() {
    stopAutoSync();
    if (!_appConfig.isLocalMode && _memosApiService != null) {
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        syncLocalDataToServer();
      });
      debugPrint('AppProvider: 自动同步已启动');
    } else {
      debugPrint('AppProvider: 本地模式或API服务未初始化，不启动自动同步');
    }
  }

  // 停止自动同步
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('AppProvider: 自动同步已停止');
  }

  // NOTE: `syncWithServer` moved to `app_provider_sync.part.dart`.

  // 刷新未读通知数量
  @override
  Future<void> refreshUnreadAnnouncementsCount() async {
    try {
      // 🚀 不立即刷新云验证数据，而是检查缓存
      // 只有当缓存过期时才刷新（避免启动时网络请求）
      if (_lastCloudVerificationTime == null ||
          DateTime.now().difference(_lastCloudVerificationTime!) >
              _cloudVerificationCacheDuration) {
        await refreshCloudData();
      }

      // 🔄 使用新的状态管理机制更新通知数量
      await _updateUnreadCount();
      notifyListeners();
    } on Object catch (e) {
      debugPrint('刷新未读通知数量异常: $e');
    }
  }

  // 启动时检查更新
  Future<void> checkForUpdatesOnStartup() async {
    try {
      // 使用云验证数据检查更新
      final hasUpdate = await hasCloudUpdate();

      if (hasUpdate && _cloudAppConfig != null) {
        final currentVersion = Config.AppConfig.appVersion;

        // 将云验证数据转换为 VersionInfo 格式
        _pendingVersionInfo = VersionInfo(
          versionName: _cloudAppConfig!.version,
          versionCode: _parseVersionCode(_cloudAppConfig!.version),
          minRequiredVersion: _cloudAppConfig!.version,
          downloadUrls: _cloudAppConfig!.appUpdateUrl.isNotEmpty
              ? {'download': _cloudAppConfig!.appUpdateUrl}
              : {},
          releaseNotes: _cloudAppConfig!.formattedVersionInfo,
          forceUpdate: _cloudAppConfig!.isForceUpdate,
        );
        _pendingCurrentVersion = currentVersion;
      }
    } on Object catch (e) {
      debugPrint('启动时检查更新异常: $e');
    }
  }

  // 解析版本号为版本代码
  int _parseVersionCode(String version) {
    final parts = version.split('.');
    var code = 0;
    for (var i = 0; i < parts.length && i < 3; i++) {
      final part = int.tryParse(parts[i]) ?? 0;
      code += part * (1000 * (3 - i));
    }
    return code;
  }

  // 版本信息暂存
  VersionInfo? _pendingVersionInfo;
  String? _pendingCurrentVersion;

  // 显示更新对话框
  void showUpdateDialogIfNeeded(BuildContext context) {
    if (_pendingVersionInfo != null && _pendingCurrentVersion != null) {
      final versionInfo = _pendingVersionInfo!;
      final currentVersion = _pendingCurrentVersion!;

      // 清除暂存的版本信息
      _pendingVersionInfo = null;
      _pendingCurrentVersion = null;

      // 使用微任务确保对话框在下一帧显示
      Future.microtask(() {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: !versionInfo.forceUpdate,
            builder: (context) => UpdateDialog(
              versionInfo: versionInfo,
              currentVersion: currentVersion,
            ),
          );
        }
      });
    }
  }

  // 通知相关方法
  Future<void> refreshAnnouncements() async {
    await refreshCloudData();

    // 🚀 大厂标准：从云验证公告数据创建 Announcement 对象（不拆分，保持完整）
    _announcements.clear();
    if (_cloudNotice?.appGg.isNotEmpty ?? false) {
      // ✅ 保持应用公告为一条完整通知，不拆分
      final announcement = Announcement(
        id: 'cloud_notice_${DateTime.now().millisecondsSinceEpoch}',
        title: '应用公告',
        content: _cloudNotice!.appGg, // 完整内容，不拆分
        type: 'info', // 使用 info 类型，以便在登录页面显示（update 类型专用于版本更新）
        publishDate: DateTime.now(),
      );
      _announcements.add(announcement);
    }
    notifyListeners();
  }

  Future<void> markAnnouncementAsRead(String id) async {
    try {
      // 🔄 新实现：真正的已读状态管理
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      if (!readNotifications.contains(id)) {
        readNotifications.add(id);
        await prefs.setStringList('read_notifications', readNotifications);
        if (kDebugMode) {
          debugPrint('AppProvider: 通知 $id 已标记为已读');
        }
      }

      // 重新计算未读数量
      await _updateUnreadCount();
      notifyListeners();
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 标记通知已读失败: $e');
      }
    }
  }

  Future<void> markAllAnnouncementsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      // 🔄 新实现：标记当前所有通知为已读
      final currentAnnouncementId = _cloudNotice?.appGg ?? '';
      if (currentAnnouncementId.isNotEmpty &&
          !readNotifications.contains(currentAnnouncementId)) {
        readNotifications.add(currentAnnouncementId);
        await prefs.setStringList('read_notifications', readNotifications);
        if (kDebugMode) {
          debugPrint('AppProvider: 所有通知已标记为已读');
        }
      }

      await _updateUnreadCount();
      notifyListeners();
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 标记所有通知已读失败: $e');
      }
    }
  }

  Future<bool> isAnnouncementRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];
      return readNotifications.contains(id);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 检查通知已读状态失败: $e');
      }
      return false;
    }
  }

  // 🆕 新增：统一的未读数量更新方法（包括系统公告和提醒通知）
  Future<void> _updateUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      final currentAnnouncementId = _cloudNotice?.appGg ?? '';

      // 🔥 计算系统公告未读数量
      var systemUnreadCount = 0;
      if (currentAnnouncementId.isNotEmpty &&
          !readNotifications.contains(currentAnnouncementId)) {
        systemUnreadCount = 1;
      }

      // 🔥 计算提醒通知未读数量
      var reminderUnreadCount = 0;
      try {
        reminderUnreadCount =
            await _reminderNotificationService.getUnreadCount();
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint('AppProvider: 获取提醒通知未读数量失败: $e');
        }
      }

      // 🔥 合并两种通知的未读数量
      _unreadAnnouncementsCount = systemUnreadCount + reminderUnreadCount;
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 更新未读数量失败: $e');
      }
      _unreadAnnouncementsCount = 0;
    }
  }

  // 🗑️ 已移除旧的通知ID管理方法，使用新的列表式状态管理

  // ===== 云验证相关方法 =====

  /// 加载云验证数据（配置和公告）
  Future<void> _loadCloudVerificationData() async {
    try {
      // 🚀 缓存检查：如果5分钟内已加载过，直接跳过
      if (_lastCloudVerificationTime != null) {
        final duration = DateTime.now().difference(_lastCloudVerificationTime!);
        if (duration < _cloudVerificationCacheDuration) {
          return;
        }
      }

      if (kDebugMode) {
        debugPrint('AppProvider: 开始加载云验证数据');
      }

      // 并行加载配置和公告
      final futures = await Future.wait([
        _cloudService.fetchAppConfig(),
        _cloudService.fetchAppNotice(),
      ]);

      final configResponse = futures[0] as CloudAppConfigResponse?;
      final noticeResponse = futures[1] as CloudNoticeResponse?;

      // 处理配置响应
      if (configResponse != null && configResponse.isSuccess) {
        _cloudAppConfig = configResponse.msg;

        // 检查是否需要更新
        await _checkCloudUpdate();
      } else {
        if (kDebugMode) {
          debugPrint('AppProvider: 云配置加载失败');
        }
      }

      // 处理公告响应
      if (noticeResponse != null && noticeResponse.isSuccess) {
        _cloudNotice = noticeResponse.msg;
        // 云公告加载成功
      } else {
        // 云公告加载失败
      }

      // 🚀 更新缓存时间
      _lastCloudVerificationTime = DateTime.now();
    } on Object {
      // 加载云验证数据异常
    }
  }

  /// 检查云端更新
  ///
  /// iOS: 通过iTunes API检查App Store版本（符合Apple规范）
  /// Android: 通过自有服务器检查版本
  Future<void> _checkCloudUpdate() async {
    try {
      // ⚠️ iOS平台使用iTunes API，不使用自有服务器
      if (Platform.isIOS) {
        // iOS通过App Store检查更新（在需要时调用）
        // 这里不自动检查，避免启动时频繁访问App Store API
        return;
      }

      // Android平台继续使用原有逻辑
      if (_cloudAppConfig == null) {
        return;
      }

      // 获取当前应用版本
      final currentVersion = Config.AppConfig.appVersion;

      // 比较版本
      final hasUpdate = _cloudService.isVersionNewer(
        currentVersion,
        _cloudAppConfig!.version,
      );

      if (hasUpdate || _cloudAppConfig!.isForceUpdate) {
        debugPrint(
          'AppProvider: 发现云端更新 - 当前版本: $currentVersion, 最新版本: ${_cloudAppConfig!.version}',
        );
        debugPrint('AppProvider: 强制更新: ${_cloudAppConfig!.isForceUpdate}');
      }
    } on Object catch (e) {
      debugPrint('AppProvider: 检查云端更新异常: $e');
    }
  }

  /// 手动刷新云验证数据
  Future<void> refreshCloudData() async {
    await _loadCloudVerificationData();
    notifyListeners();
  }

  /// 获取云端公告内容列表
  List<String> getCloudNotices() => _cloudNotice?.formattedNotices ?? [];

  /// 获取云端版本信息列表
  List<String> getCloudVersionInfo() =>
      _cloudAppConfig?.formattedVersionInfo ?? [];

  /// 是否有云端更新
  Future<bool> hasCloudUpdate() async {
    try {
      if (_cloudAppConfig == null) {
        return false;
      }

      final currentVersion = Config.AppConfig.appVersion;

      return _cloudService.isVersionNewer(
        currentVersion,
        _cloudAppConfig!.version,
      );
    } on Object catch (e) {
      debugPrint('AppProvider: 检查是否有云端更新异常: $e');
      return false;
    }
  }

  /// 是否强制更新
  bool isForceCloudUpdate() => _cloudAppConfig?.isForceUpdate ?? false;

  // 在销毁时清理
  @override
  void dispose() {
    _mounted = false;
    _syncTimer?.cancel();
    // ✅ dispose 时重置启动备份标志
    _stopWebDavAutoBackup(resetStartupFlag: true);
    super.dispose();
  }

  // 设置本地模式
  Future<void> setLocalMode(bool enabled) async {
    debugPrint('AppProvider: 设置本地模式: $enabled');

    if (enabled) {
      // 启用本地模式
      _user = User(
        id: 'local_user',
        username: '本地用户',
        email: '',
        avatarUrl: '',
      );

      // 清除API服务连接
      _apiService = null;
      _memosApiService = null;
      _resourceService = null;

      // 停止同步定时器
      _syncTimer?.cancel();
      _syncTimer = null;

      // 更新应用配置为本地模式
      _appConfig = _appConfig.copyWith(isLocalMode: true);
      await _preferencesService.saveAppConfig(_appConfig);

      // 初始化数据库
      await _databaseService.database;

      // 加载本地数据
      await loadNotesFromLocal();

      debugPrint('AppProvider: 本地模式已启用');
    } else {
      // 禁用本地模式
      _appConfig = _appConfig.copyWith(isLocalMode: false);
      await _preferencesService.saveAppConfig(_appConfig);
      _user = null;
      debugPrint('AppProvider: 本地模式已禁用');
    }

    notifyListeners();
  }

  // 设置当前用户
  Future<void> setUser(User user) async {
    _user = user;
    await _preferencesService.saveUser(user);
    notifyListeners();
  }

  /// 在后台初始化API服务，不阻塞启动流程
  Future<void> _initializeApiServiceInBackground() async {
    if (_memosApiService != null) {
      return;
    }

    // 检查是否启用自动登录
    if (!_appConfig.autoLogin) {
      if (kDebugMode) {
        debugPrint('AppProvider: 未启用自动登录，跳过自动登录');
      }
      return;
    }

    // 检查是否有保存的token和服务器信息
    final savedServerUrl = _appConfig.lastServerUrl ?? _user?.serverUrl;
    final savedToken = _appConfig.lastToken ?? _user?.token;

    if (savedServerUrl == null || savedToken == null) {
      if (kDebugMode) {
        debugPrint('AppProvider: 缺少保存的服务器信息或token，跳过自动登录');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('AppProvider: 开始验证保存的token并尝试自动登录');
      }

      // 尝试使用保存的token自动登录
      final loginResult = await loginWithToken(savedServerUrl, savedToken);

      if (loginResult.$1) {
        if (kDebugMode) {
          debugPrint('AppProvider: 自动登录成功');
        }

        // 初始化API服务
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: savedServerUrl,
          token: savedToken,
        ) as MemosApiServiceFixed;

        // 🚀 初始化增量同步服务（关键！）
        _incrementalSyncService =
            IncrementalSyncService(_databaseService, _memosApiService);

        _resourceService = MemosResourceService(
          baseUrl: savedServerUrl,
          token: savedToken,
          serverVersion: await MemosApiServiceFixed.getServerVersion(
            savedServerUrl,
          ),
        );

        // 更新应用配置为在线模式
        if (_appConfig.isLocalMode) {
          if (kDebugMode) {
            debugPrint('AppProvider: 切换到在线模式');
          }
          _appConfig = _appConfig.copyWith(isLocalMode: false);
          await _preferencesService.saveAppConfig(_appConfig);
        }

        if (kDebugMode) {
          debugPrint('AppProvider: API服务和资源服务初始化成功');
        }

        // 启动自动同步
        startAutoSync();

        notifyListeners();
      } else {
        if (kDebugMode) {
          debugPrint('AppProvider: 自动登录失败: ${loginResult.$2}，清除保存的登录信息');
        }

        // Token无效，清除保存的登录信息
        await _preferencesService.clearLoginInfo();
        _user = null;
        _appConfig = _appConfig.copyWith();
        await _preferencesService.saveAppConfig(_appConfig);
        notifyListeners();
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 自动登录过程中发生异常: $e');
      }

      // 发生异常时清除保存的登录信息
      try {
        await _preferencesService.clearLoginInfo();
        _user = null;
        _appConfig = _appConfig.copyWith();
        await _preferencesService.saveAppConfig(_appConfig);
        notifyListeners();
      } on Object catch (clearError) {
        if (kDebugMode) {
          debugPrint('AppProvider: 清除登录信息时发生异常: $clearError');
        }
      }
    }
  }

  /// 确保API服务已初始化
  /// 这个方法会快速检查并重新初始化API服务，避免重复的UI更新
  Future<void> _ensureApiServiceInitialized() async {
    if (_memosApiService != null) {
      return;
    }

    // 只在真正需要初始化时才显示消息
    _syncMessage = '初始化API服务...';
    notifyListeners();

    if (kDebugMode) {
      debugPrint('AppProvider: API服务未初始化，尝试重新初始化');
    }

    try {
      // 优先使用当前用户的Token
      if (_appConfig.memosApiUrl != null && _user?.token != null) {
        if (kDebugMode) {
          debugPrint('AppProvider: 使用当前用户Token初始化API服务');
        }
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: _appConfig.memosApiUrl!,
          token: _user!.token,
        ) as MemosApiServiceFixed;

        // 同时初始化资源服务
        _resourceService = MemosResourceService(
          baseUrl: _appConfig.memosApiUrl!,
          token: _user!.token,
          serverVersion: await MemosApiServiceFixed.getServerVersion(
            _appConfig.memosApiUrl!,
          ),
        );
      }
      // 备用：使用上次保存的Token
      else if (_appConfig.memosApiUrl != null && _appConfig.lastToken != null) {
        if (kDebugMode) {
          debugPrint('AppProvider: 使用上次的Token初始化API服务');
        }
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: _appConfig.memosApiUrl!,
          token: _appConfig.lastToken,
        ) as MemosApiServiceFixed;

        // 同时初始化资源服务
        _resourceService = MemosResourceService(
          baseUrl: _appConfig.memosApiUrl!,
          token: _appConfig.lastToken,
          serverVersion: await MemosApiServiceFixed.getServerVersion(
            _appConfig.memosApiUrl!,
          ),
        );
      }

      if (_memosApiService == null) {
        throw Exception('API服务初始化失败：缺少必要的配置信息');
      }

      if (kDebugMode) {
        debugPrint('AppProvider: API服务重新初始化成功');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: API服务初始化失败: $e');
      }
      throw Exception('API服务初始化失败，无法获取数据');
    }
  }

  // 处理笔记中的引用关系
  Future<void> _processNoteReferences(Note note) async {
    try {
      // 🚀 使用统一引用管理器（静默处理）

      // 使用统一引用管理器的智能更新功能
      await UnifiedReferenceManager()
          .updateReferencesFromContent(note.id, note.content);
    } on Object catch (_) {
      // Reference parsing should not block note persistence.
    }
  }

  // 删除服务器上笔记的所有引用关系
  Future<bool> _deleteAllReferenceRelations(String noteId) async {
    try {
      if (_memosApiService == null) {
        return false;
      }
      return _memosApiService!.deleteAllMemoRelations(noteId);
    } on Object {
      return false;
    }
  }

  // 🔧 数据恢复：重新构建所有引用关系
  Future<void> rebuildAllReferences() async {
    try {
      var totalRebuilt = 0;

      // 🔧 首先清理所有现有的引用关系，重新开始
      for (final note in _notes) {
        if (note.relations.isNotEmpty) {
          final cleanNote = note.copyWith(relations: <Map<String, dynamic>>[]);
          await _databaseService.updateNote(cleanNote);
        }
      }

      // 重新加载清理后的笔记
      await loadNotesFromLocal();

      // 🚀 遍历所有笔记，重新解析引用关系（静默处理）
      for (final note in _notes) {
        // 使用UnifiedReferenceManager重新处理每个笔记
        final success = await UnifiedReferenceManager()
            .updateReferencesFromContent(note.id, note.content);
        if (success) {
          totalRebuilt++;
        }

        // 添加小延迟避免处理过快
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 重新加载笔记以获取最新的引用关系
      await loadNotesFromLocal();

      if (kDebugMode) {
        // 🚀 只打印汇总，不打印每条笔记（避免137行日志）
        final totalRelations =
            _notes.fold(0, (sum, n) => sum + n.relations.length);
        debugPrint(
          'AppProvider: 重建引用完成，处理 $totalRebuilt 条笔记，当前 $totalRelations 条引用',
        );
      }
    } on Object catch (_) {
      // Rebuilding references is maintenance and should not interrupt the app.
    }
  }

  // 处理Token过期的情况
  Future<void> _handleTokenExpired() async {
    try {
      if (kDebugMode) {
        debugPrint('AppProvider: 处理Token过期，清除登录状态');
      }

      // 1. 停止自动同步
      stopAutoSync();

      // 2. 尝试撤销过期的token（尽力而为）
      if (_memosApiService != null) {
        try {
          await _memosApiService!.logout();
          if (kDebugMode) {
            debugPrint('AppProvider: 过期token撤销成功');
          }
        } on Object catch (e) {
          if (kDebugMode) {
            debugPrint('AppProvider: 过期token撤销失败: $e');
          }
          // 继续执行，因为token已经过期
        }
      }

      // 3. 清除API服务
      _memosApiService = null;
      _resourceService = null;

      // 4. 清除用户信息和登录状态
      await _preferencesService.clearLoginInfo();
      _user = null;

      // 5. 更新应用配置，切换到本地模式
      _appConfig = _appConfig.copyWith(
        isLocalMode: true,
        autoLogin: false, // 禁用自动登录
      );
      await _preferencesService.saveAppConfig(_appConfig);

      // 6. 设置同步消息提示用户
      _syncMessage = 'Token已过期，请重新登录';
      _isSyncing = false;

      // 7. 通知UI更新
      notifyListeners();

      if (kDebugMode) {
        debugPrint('AppProvider: Token过期处理完成，已切换到本地模式');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 处理Token过期时发生错误: $e');
      }
    }
  }

  // 🖼️ 异步预加载用户头像
  void _preloadUserAvatarAsync() {
    if (_user?.avatarUrl == null || _user!.avatarUrl!.trim().isEmpty) {
      return; // 没有头像URL，无需预加载
    }

    // 在微任务中执行预加载，避免阻塞主线程
    Future.microtask(() async {
      try {
        // 使用NavigatorState获取context，但只在widget树构建完成后
        final context = NavigatorKey.currentContext;
        if (context != null && context.mounted && _user != null) {
          debugPrint('AppProvider: 开始预加载用户头像');
          await AvatarPreloader.preloadUserAvatar(context, _user!);
        }
      } on Object catch (e) {
        // 预加载失败不影响正常功能
        debugPrint('AppProvider: 头像预加载失败（不影响正常使用）: $e');
      }
    });
  }

  // ==================== 提醒管理功能 ====================

  /// 为笔记设置提醒时间
  Future<bool> setNoteReminder(String noteId, DateTime reminderTime) async {
    try {
      // 查找笔记
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex == -1) {
        throw Exception('笔记不存在');
      }

      final note = _notes[noteIndex];

      // 设置通知（传递原始noteId字符串）
      final success = await _notificationService.scheduleNoteReminder(
        noteId: noteId.hashCode,
        noteIdString: noteId, // 🔥 传递原始字符串ID
        title: '📝 笔记提醒',
        body: note.content.length > 50
            ? '${note.content.substring(0, 50)}...'
            : note.content,
        reminderTime: reminderTime,
      );

      if (!success) {
        return false;
      }

      // 通知调度成功后再写入提醒时间，避免失败时 UI 显示假提醒。
      final updatedNote = note.copyWith(reminderTime: reminderTime);
      _notes[noteIndex] = updatedNote;
      await _databaseService.updateNote(updatedNote);

      notifyListeners();

      if (kDebugMode) {
        debugPrint('AppProvider: 成功设置笔记提醒，时间: $reminderTime');
      }

      return success;
    } on Object {
      rethrow;
    }
  }

  /// 🔥 清理过期的提醒通知（保留最近30天的记录）
  Future<void> _cleanupOldReminderNotifications() async {
    try {
      final allReminders =
          await _reminderNotificationService.getAllReminderNotifications();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      var deletedCount = 0;
      for (final reminder in allReminders) {
        // 删除30天前的已读记录
        if (reminder.isRead && reminder.triggeredAt.isBefore(cutoffDate)) {
          await _reminderNotificationService
              .deleteReminderNotification(reminder.id);
          deletedCount++;
        }
      }

      if (kDebugMode && deletedCount > 0) {}
    } on Object catch (_) {
      // Old reminder cleanup is opportunistic.
    }
  }

  /// 🔥 保存提醒通知到数据库（市场主流做法：通知触发时立即保存）
  Future<void> saveReminderNotificationToDatabase({
    required String noteIdString,
    required String title,
    required String body,
    required DateTime triggerTime,
  }) async {
    try {
      final reminderNotification = ReminderNotification(
        id: const Uuid().v4(),
        noteId: noteIdString,
        noteTitle: title,
        noteContent: body,
        reminderTime: triggerTime,
        triggeredAt: DateTime.now(),
      );

      await _reminderNotificationService
          .saveReminderNotification(reminderNotification);

      // 更新未读通知数量
      await _updateUnreadCount();
      notifyListeners();
    } on Object catch (_) {
      // Persisting triggered reminders is best-effort.
    }
  }

  /// 取消笔记提醒
  @override
  Future<void> cancelNoteReminder(String noteId) async {
    try {
      // 查找笔记
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex == -1) {
        throw Exception('笔记不存在');
      }

      final note = _notes[noteIndex];

      // 清除笔记的提醒时间
      final updatedNote = note.copyWith(clearReminderTime: true);
      _notes[noteIndex] = updatedNote;

      // 保存到数据库
      await _databaseService.updateNote(updatedNote);

      // 取消通知（使用hashCode将String ID转为int）
      await _notificationService.cancelNoteReminder(noteId.hashCode);

      notifyListeners();
    } on Object {
      rethrow;
    }
  }

  /// 获取笔记的提醒时间（不自动清理，只返回数据）
  /// 参考大厂应用：UI查询不应触发业务逻辑，过期清理应由定时任务处理
  DateTime? getNoteReminderTime(String noteId) {
    try {
      final note = _notes.firstWhere((note) => note.id == noteId);
      return note.reminderTime;
    } on Object {
      return null;
    }
  }

  /// 清理所有过期的提醒（应用启动时调用）
  /// 参考大厂应用：只清理已经过期超过1分钟的提醒，避免误删刚设置的提醒
  Future<void> clearExpiredReminders() async {
    try {
      final now = DateTime.now();
      // 给1分钟的宽限期，避免时区、时间同步等问题导致的误删
      final threshold = now.subtract(const Duration(minutes: 1));
      var clearedCount = 0;

      for (final note in _notes) {
        // 只清理已经过期超过1分钟的提醒
        if (note.reminderTime != null &&
            note.reminderTime!.isBefore(threshold)) {
          await cancelNoteReminder(note.id);
          clearedCount++;
        }
      }

      if (clearedCount > 0) {
        notifyListeners();
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: 清理过期提醒失败: $e');
      }
    }
  }
  // ========================================
  // 🚀 WebDAV 同步功能
  // ========================================

  /// 加载 WebDAV 配置
  Future<void> loadWebDavConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('webdav_config');

      if (configJson != null && configJson.isNotEmpty) {
        final storedConfig = WebDavConfig.fromJson(jsonDecode(configJson));
        final securePassword = await _preferencesService.getWebDavPassword();
        final legacyPassword = storedConfig.password;
        final resolvedPassword = securePassword?.isNotEmpty ?? false
            ? securePassword!
            : legacyPassword;

        if (legacyPassword.isNotEmpty) {
          await _preferencesService.saveWebDavPassword(resolvedPassword);
          await prefs.setString(
            'webdav_config',
            jsonEncode(storedConfig.copyWith(password: '').toJson()),
          );
        }

        _webDavConfig = storedConfig.copyWith(password: resolvedPassword);

        // 如果启用了 WebDAV，初始化服务
        if (_webDavConfig.enabled && _webDavConfig.isValid) {
          await _initializeWebDavService();
        }
      }
    } on Object catch (_) {
      // WebDAV config is optional; keep the app usable if stored config is bad.
    }
  }

  /// 更新 WebDAV 配置
  Future<void> updateWebDavConfig(
    WebDavConfig config, {
    bool skipInitialize = false,
  }) async {
    try {
      final oldConfig = _webDavConfig;
      _webDavConfig = config;

      // 保存到本地
      final prefs = await SharedPreferences.getInstance();
      if (config.password.isNotEmpty) {
        await _preferencesService.saveWebDavPassword(config.password);
      } else {
        await _preferencesService.deleteWebDavPassword();
      }
      await prefs.setString(
        'webdav_config',
        jsonEncode(config.copyWith(password: '').toJson()),
      );

      // 🔧 改进：保存配置时不立即连接服务器，避免网络问题导致保存失败
      // 只在明确需要时才初始化（如执行备份/恢复操作）
      if (!skipInitialize) {
        // 重新初始化服务（可能抛出网络异常）
        if (config.enabled && config.isValid) {
          await _initializeWebDavService();
        } else {
          _disposeWebDavService();
        }
      } else {
        final connectionChanged = oldConfig.serverUrl != config.serverUrl ||
            oldConfig.username != config.username ||
            oldConfig.password != config.password ||
            oldConfig.syncPath != config.syncPath ||
            oldConfig.enabled != config.enabled ||
            oldConfig.backupImages != config.backupImages;

        if (connectionChanged) {
          _disposeWebDavService();
        }

        if (config.enabled && config.autoSync) {
          _startWebDavAutoBackup();
        } else {
          _stopWebDavAutoBackup();
        }
      }

      notifyListeners();
    } on Object {
      rethrow;
    }
  }

  /// 初始化 WebDAV 服务
  Future<void> _initializeWebDavService() async {
    try {
      // 🔧 释放旧服务（但不重置启动备份标志）
      // 避免频繁初始化导致重复备份
      _disposeWebDavService();

      // 创建新服务
      _webDavService = WebDavService();
      await _webDavService!.initialize(_webDavConfig);

      // 创建同步引擎
      _webDavSyncEngine = WebDavSyncEngine(
        _webDavService!,
        _databaseService,
        memosBaseUrl: _appConfig.memosApiUrl ?? _appConfig.lastServerUrl,
        memosToken: _user?.token ?? _appConfig.lastToken,
      );
      await _webDavSyncEngine!.initialize();

      // 🚀 如果启用了定时备份，启动定时备份
      if (_webDavConfig.autoSync) {
        _startWebDavAutoBackup();
      }
    } on Object {
      rethrow;
    }
  }

  /// 测试 WebDAV 连接
  Future<bool> testWebDavConnection(WebDavConfig config) async {
    try {
      final testService = WebDavService();
      await testService.initialize(config);
      final result = await testService.testConnection();
      testService.dispose();

      return result;
    } on Object {
      return false;
    }
  }

  /// 执行 WebDAV 同步
  Future<SyncStats?> syncWithWebDav() async {
    if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
      return null;
    }

    if (_webDavSyncEngine == null) {
      await _initializeWebDavService();
    }

    try {
      final stats = await _webDavSyncEngine!.sync();

      // 同步完成后重新加载笔记（可能会导致 UI 闪烁）
      // 注意：loadNotesFromLocal 会触发 notifyListeners，可能干扰正在创建笔记的流程
      await loadNotesFromLocal();

      // 更新最后同步时间（跳过初始化，只更新时间戳）
      final updatedConfig = _webDavConfig.copyWith(
        lastSyncTime: DateTime.now(),
      );
      await updateWebDavConfig(updatedConfig, skipInitialize: true);

      return stats;
    } on Object {
      rethrow;
    }
  }

  /// 执行 WebDAV 完整备份（单向上传）
  ///
  /// [onProgress] 进度回调：(progress, message) => void
  Future<SyncStats?> backupWithWebDav({
    void Function(double progress, String message)? onProgress,
  }) async {
    if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
      return null;
    }

    if (_webDavSyncEngine == null) {
      await _initializeWebDavService();
    }

    try {
      final stats = await _webDavSyncEngine!.backup(
        onProgress: onProgress,
      );

      // 更新最后备份时间（跳过初始化，只更新时间戳）
      final updatedConfig = _webDavConfig.copyWith(
        lastSyncTime: DateTime.now(),
      );
      await updateWebDavConfig(updatedConfig, skipInitialize: true);

      return stats;
    } on Object {
      rethrow;
    }
  }

  /// 从 WebDAV 恢复数据（单向下载）
  ///
  /// [onProgress] 进度回调：(progress, message) => void
  Future<SyncStats?> restoreFromWebDav({
    void Function(double progress, String message)? onProgress,
  }) async {
    if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
      return null;
    }

    if (_webDavSyncEngine == null) {
      await _initializeWebDavService();
    }

    try {
      final stats = await _webDavSyncEngine!.restore(
        onProgress: onProgress,
      );

      // 恢复完成后重新加载笔记
      await loadNotesFromLocal();

      // 更新最后同步时间（跳过初始化，只更新时间戳）
      final updatedConfig = _webDavConfig.copyWith(
        lastSyncTime: DateTime.now(),
      );
      await updateWebDavConfig(updatedConfig, skipInitialize: true);

      return stats;
    } on Object {
      rethrow;
    }
  }

  /// 释放 WebDAV 服务
  void _disposeWebDavService({bool resetStartupFlag = false}) {
    // 🔧 符合用户体验：默认不重置启动备份标志
    // "启动备份"应该只在应用真正启动时触发一次，而不是每次重新初始化服务时都触发
    // 避免热重载、页面切换、配置修改时重复备份
    _stopWebDavAutoBackup(resetStartupFlag: resetStartupFlag);
    _webDavService?.dispose();
    _webDavService = null;
    _webDavSyncEngine = null;
  }

  /// 启动 WebDAV 自动备份（参考坚果云、Dropbox等主流软件逻辑）
  void _startWebDavAutoBackup() {
    // 🔧 先停止旧的定时器（不重置启动备份标志）
    // 这样在配置修改、热重载等场景下不会重复触发"启动备份"
    _stopWebDavAutoBackup();

    if (!_webDavConfig.autoSync || !_webDavConfig.enabled) {
      return;
    }

    final interval = _webDavConfig.autoSyncInterval;

    if (interval == 0) {
      // 📱 "启动备份"模式：只在应用真正启动时执行一次
      // ✅ 符合用户预期：启动应用 = 备份一次
      // ❌ 不符合预期：热重载、配置修改、页面切换 = 不应该再次备份
      if (!_hasPerformedStartupBackup) {
        if (kDebugMode) {
          debugPrint('AppProvider: WebDAV 启动备份 - 应用首次启动，立即执行');
        }
        _performWebDavBackup();
        _hasPerformedStartupBackup = true;
      } else {
        if (kDebugMode) {
          debugPrint('AppProvider: WebDAV 启动备份 - 本次会话已执行过，跳过');
        }
      }
    } else {
      // 🚀 大厂标准：定时备份 - 智能判断上次备份时间
      final duration = Duration(minutes: interval);
      final lastBackup = _webDavConfig.lastSyncTime;
      final now = DateTime.now();

      if (kDebugMode) {
        debugPrint('AppProvider: WebDAV 启动定时备份 - 间隔 $interval 分钟');
      }

      // ✅ 智能判断：只有距离上次备份超过间隔时才立即执行
      // 避免频繁修改配置导致频繁备份
      if (lastBackup == null) {
        // 首次启用，立即执行一次
        if (kDebugMode) {
          debugPrint('AppProvider: WebDAV 首次启用定时备份 - 立即执行');
        }
        _performWebDavBackup();
      } else {
        final elapsed = now.difference(lastBackup);
        if (elapsed >= duration) {
          // 距离上次备份已超过间隔，立即执行
          if (kDebugMode) {
            debugPrint(
              'AppProvider: WebDAV 距上次备份已 ${elapsed.inMinutes} 分钟 - 立即执行',
            );
          }
          _performWebDavBackup();
        } else {
          // 距离上次备份未超过间隔，跳过立即执行
          final remaining = duration - elapsed;
          if (kDebugMode) {
            debugPrint(
              'AppProvider: WebDAV 距上次备份仅 ${elapsed.inMinutes} 分钟 - 跳过立即执行，${remaining.inMinutes} 分钟后执行',
            );
          }
        }
      }

      // 启动定时器
      _webDavBackupTimer = Timer.periodic(duration, (_) {
        _performWebDavBackup();
      });
    }
  }

  /// 停止 WebDAV 自动备份
  void _stopWebDavAutoBackup({bool resetStartupFlag = false}) {
    _webDavBackupTimer?.cancel();
    _webDavBackupTimer = null;

    // ✅ 只有在明确需要重置时才重置启动备份标志
    // 避免每次启动定时器都触发一次备份
    if (resetStartupFlag) {
      _hasPerformedStartupBackup = false;
    }

    if (kDebugMode) {
      debugPrint('AppProvider: WebDAV 自动备份已停止');
    }
  }

  /// 执行 WebDAV 备份（内部方法，静默执行）
  Future<void> _performWebDavBackup() async {
    try {
      if (!_webDavConfig.enabled || !_webDavConfig.isValid) {
        return;
      }

      if (kDebugMode) {
        debugPrint('AppProvider: 开始执行 WebDAV 自动备份');
      }

      final stats = await backupWithWebDav();

      if (kDebugMode) {
        debugPrint('AppProvider: WebDAV 自动备份完成 - $stats');
      }

      // 🚀 大厂标准：更新上次备份时间，用于智能判断
      // 注意：backupWithWebDav() 内部已经更新了 lastSyncTime
      // 这里只是确保逻辑清晰
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AppProvider: WebDAV 自动备份失败: $e');
      }
      // 静默失败，不影响用户使用
    }
  }

  // 🚀 Notion 自动同步（内部方法，异步执行，不阻塞UI）
  Future<void> _autoSyncToNotion() async {
    try {
      // 检查是否启用自动同步
      final isEnabled = await _notionSyncService.isEnabled();
      final isAutoSync = await _notionSyncService.isAutoSyncEnabled();

      if (!isEnabled || !isAutoSync) {
        return; // 未启用或未开启自动同步，直接返回
      }

      // 防止重复同步
      if (_isNotionSyncing) {
        debugPrint('Notion: 同步进行中，跳过本次自动同步');
        return;
      }

      debugPrint('Notion: 开始自动同步');
      _isNotionSyncing = true;

      // 获取同步方向
      final direction = await _notionSyncService.getSyncDirection();

      // 执行同步
      if (direction == 'to_notion' || direction == 'both') {
        await _notionSyncService.syncNotesToNotion(_notes);
        debugPrint('Notion: 自动同步完成');
      }
    } on Object catch (e) {
      debugPrint('Notion: 自动同步失败: $e');
      // 静默失败，不影响用户使用
    } finally {
      _isNotionSyncing = false;
    }
  }

  // 🚀 手动同步到 Notion（供下拉刷新等场景使用）
  Future<void> syncToNotion() async {
    try {
      // 检查是否启用
      final isEnabled = await _notionSyncService.isEnabled();
      if (!isEnabled) {
        throw Exception('Notion 同步未启用');
      }

      // 防止重复同步
      if (_isNotionSyncing) {
        debugPrint('Notion: 同步进行中，跳过本次请求');
        return;
      }

      debugPrint('Notion: 开始手动同步');
      _isNotionSyncing = true;
      notifyListeners(); // 通知UI显示加载状态

      // 获取同步方向
      final direction = await _notionSyncService.getSyncDirection();

      // 执行同步
      if (direction == 'to_notion') {
        await _notionSyncService.syncNotesToNotion(_notes);
      } else if (direction == 'from_notion') {
        final result = await _notionSyncService.syncNotesFromNotion();
        debugPrint(
          'Notion: 从 Notion 导入完成 - 成功: ${result['success']}, 失败: ${result['failed']}',
        );
        await loadNotesFromLocal();
      } else if (direction == 'both') {
        // 双向同步
        await _notionSyncService.syncNotesToNotion(_notes);
        final result = await _notionSyncService.syncNotesFromNotion();
        debugPrint(
          'Notion: 从 Notion 导入完成 - 成功: ${result['success']}, 失败: ${result['failed']}',
        );
        await loadNotesFromLocal();
      }

      debugPrint('Notion: 手动同步完成');
    } on Object catch (e) {
      debugPrint('Notion: 手动同步失败: $e');
      rethrow; // 抛出异常供UI处理
    } finally {
      _isNotionSyncing = false;
      notifyListeners();
    }
  }

  // 🚀 获取 Notion 同步状态
  bool get isNotionSyncing => _isNotionSyncing;
}

// 用于获取全局Context的导航键
class NavigatorKey {
  static final GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get key => _key;
  static BuildContext? get currentContext => _key.currentContext;
}
