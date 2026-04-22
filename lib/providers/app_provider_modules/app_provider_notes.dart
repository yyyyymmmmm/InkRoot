import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkroot/models/annotation_model.dart';
import 'package:inkroot/models/load_more_state.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/sort_order.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:inkroot/services/unified_reference_manager.dart';
import 'package:inkroot/utils/error_handler.dart';
import 'package:inkroot/utils/logger.dart';
import 'package:inkroot/utils/performance_tracker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

/// AppProviderNotes Mixin
///
/// 包含所有笔记相关的操作：
/// - 笔记CRUD：创建、读取、更新、删除
/// - 笔记加载：分页加载、刷新、加载更多
/// - 笔记查询：根据ID查询、获取归档笔记
/// - 笔记同步：与服务器同步
/// - 笔记操作：置顶、归档、排序
/// - 笔记标签：提取和管理标签
/// - 笔记引用：处理笔记间的引用关系
mixin AppProviderNotes on ChangeNotifier {
  // ========== 需要从 AppProvider 访问的状态和服务 ==========

  // 笔记相关状态变量
  List<Note> _notes = [];
  bool _isLoading = false;

  // 分页加载相关
  LoadMoreState _loadMoreState = LoadMoreState.idle;
  bool _hasMoreData = true;
  int _currentPage = 0;
  static const int _pageSize = 50;
  Completer<void>? _loadMoreCompleter;

  // 性能监控
  int _totalNotesCount = 0;
  DateTime? _lastLoadTime;
  final Stopwatch _loadStopwatch = Stopwatch();

  // 删除队列相关（批量处理）
  final List<String> _deleteQueue = [];
  bool _isProcessingDelete = false;
  Timer? _deleteDebounceTimer;
  static const Duration _deleteBatchDelay = Duration(milliseconds: 500);

  // 撤销删除相关
  Note? _lastDeletedNote;
  int? _lastDeletedIndex;

  // 排序
  SortOrder _sortOrder = SortOrder.newest;

  // 需要从 AppProvider 获取的服务和配置
  // 这些需要在具体实现类中提供
  DatabaseService get databaseService;
  MemosApiServiceFixed? get memosApiService;
  bool get isLoggedIn;
  bool get isLocalMode;
  String get defaultNoteVisibility;
  bool get mounted;
  Timer? get syncTimer;

  // ========== Getters ==========

  /// 获取所有正常笔记（过滤掉归档笔记）
  List<Note> get notes => _getSortedNotes().where((note) => note.isNormal).toList();

  /// 获取原始笔记列表（包括归档笔记）
  List<Note> get rawNotes => _notes;

  /// 当前排序方式
  SortOrder get sortOrder => _sortOrder;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 是否正在加载更多
  bool get isLoadingMore => _loadMoreState.isLoading;

  /// 是否还有更多数据
  bool get hasMoreData => _hasMoreData && _loadMoreState != LoadMoreState.noMore;

  /// 加载更多状态
  LoadMoreState get loadMoreState => _loadMoreState;

  /// 数据库总笔记数
  int get totalNotesCount => _totalNotesCount;

  /// 已加载笔记数
  int get loadedNotesCount => _notes.length;

  /// 上次加载时间
  DateTime? get lastLoadTime => _lastLoadTime;

  // ========== 笔记查询方法 ==========

  /// 根据ID获取笔记
  Note? getNoteById(String noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  /// 更新内存中的笔记（用于本地引用服务通知）
  void updateNoteInMemory(Note updatedNote) {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  // ========== 笔记加载方法 ==========

  /// 从本地数据库加载笔记
  Future<void> loadNotesFromLocal({bool reset = false}) async {
    await PerformanceTracker().startTrace('load_notes_from_local', attributes: {
      'reset': reset.toString(),
    });
    Log.database.debug('Loading notes from local', data: {'reset': reset});

    try {
      // 完整加载所有笔记（用于刷新场景，如导入后）
      _currentPage = 0;
      _hasMoreData = true;
      _notes = await databaseService.getNotes();

      // 更新总数统计
      _totalNotesCount = _notes.length;

      // 修复失效的图片路径
      final hasUpdates = await _fixBrokenImagePaths();

      // 重新提取所有笔记的标签
      _refreshAllNoteTags();

      notifyListeners();

      await PerformanceTracker().stopTrace('load_notes_from_local',
        success: true,
        metrics: {'note_count': _notes.length},
      );
      Log.database.info('Notes loaded successfully', data: {'count': _notes.length});
    } catch (e, stackTrace) {
      await PerformanceTracker().stopTrace('load_notes_from_local', success: false);
      Log.database.error('Failed to load notes from local', error: e, stackTrace: stackTrace);
      await ErrorHandler.captureException(e, stackTrace: stackTrace, context: {
        'operation': 'load_notes_from_local',
        'reset': reset,
      });
      rethrow;
    }
  }

  /// 分页加载初始笔记（性能优化 - 大厂最佳实践）
  /// 三阶段加载：极速首屏 → 预加载 → 后台任务
  Future<void> loadInitialNotes() async {
    try {
      _currentPage = 0;
      _hasMoreData = true;
      _loadMoreState = LoadMoreState.idle;

      // 获取数据库总笔记数（用于性能监控）
      final allNotes = await databaseService.getNotes();
      _totalNotesCount = allNotes.length;

      // 极速启动：只加载5条笔记，够首屏显示
      final firstPage = await databaseService.getNotesPaged(
        pageSize: 5,
      );

      _notes = firstPage;
      _hasMoreData = firstPage.length >= 5;

      notifyListeners();
      if (kDebugMode) {
        debugPrint('AppProvider: ✅ 首页极速加载完成，已加载 ${_notes.length}/$_totalNotesCount 条笔记（首屏显示）');
      }

      // 延迟加载更多（用户打开应用2秒后，不阻塞启动）
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted && _hasMoreData) {
          try {
            // 加载接下来的30条
            final morePage = await databaseService.getNotesPaged(
              page: 1,
              pageSize: 30,
            );
            if (mounted) {
              _notes.addAll(morePage);
              _currentPage = 1;
              _hasMoreData = morePage.length >= 30;
              notifyListeners();
              if (kDebugMode) {
                debugPrint('AppProvider: 📦 预加载完成，已加载 ${morePage.length} 条，总计 ${_notes.length}/$_totalNotesCount 条笔记');
              }
            }
          } catch (e) {
            if (kDebugMode) debugPrint('AppProvider: ❌ 预加载失败: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 加载初始笔记失败: $e');
      rethrow;
    }
  }

  /// 加载更多笔记（滚动到底部时调用）
  /// 特性：并发控制 + 细粒度状态 + 性能监控
  Future<void> loadMoreNotes() async {
    // 1️⃣ 并发控制：如果正在加载，返回现有的 Future
    if (_loadMoreCompleter != null && !_loadMoreCompleter!.isCompleted) {
      debugPrint('AppProvider: ⚠️ 检测到并发加载请求，返回现有Future');
      return _loadMoreCompleter!.future;
    }

    // 2️⃣ 状态检查：使用细粒度状态判断
    if (!_loadMoreState.canLoadMore || !_hasMoreData) {
      debugPrint('AppProvider: ⏸️ 无法加载更多 - 状态: ${_loadMoreState.description}, 有更多数据: $_hasMoreData');
      return;
    }

    // 3️⃣ 创建新的 Completer
    _loadMoreCompleter = Completer<void>();

    // 4️⃣ 开始性能监控
    _loadStopwatch.reset();
    _loadStopwatch.start();
    final loadStartTime = DateTime.now();

    try {
      // 5️⃣ 更新状态为加载中
      _loadMoreState = LoadMoreState.loadingMore;
      notifyListeners();

      _currentPage++;
      debugPrint('AppProvider: 📄 开始加载第 $_currentPage 页笔记... (状态: ${_loadMoreState.description})');

      // 6️⃣ 执行数据加载
      final moreNotes = await databaseService.getNotesPaged(
        page: _currentPage,
        pageSize: _pageSize,
      );

      // 7️⃣ 处理加载结果
      if (moreNotes.isEmpty) {
        _hasMoreData = false;
        _loadMoreState = LoadMoreState.noMore;
        debugPrint('AppProvider: ✅ 所有笔记已加载完成，共 ${_notes.length}/$_totalNotesCount 条');
      } else {
        _notes.addAll(moreNotes);
        _loadMoreState = LoadMoreState.success;
        debugPrint('AppProvider: ✅ 第 $_currentPage 页加载完成，本页 ${moreNotes.length} 条，总计 ${_notes.length}/$_totalNotesCount 条');
      }

      // 8️⃣ 停止性能监控
      _loadStopwatch.stop();
      _lastLoadTime = DateTime.now();

      // 9️⃣ 性能埋点上报
      _reportLoadPerformance(
        page: _currentPage,
        itemCount: moreNotes.length,
        duration: _loadStopwatch.elapsedMilliseconds,
        success: true,
      );

      notifyListeners();

      // 🔟 完成 Completer
      _loadMoreCompleter!.complete();
    } catch (e, stackTrace) {
      // ❌ 错误处理
      _loadStopwatch.stop();
      _loadMoreState = LoadMoreState.failed;
      _currentPage--; // 回退页码

      debugPrint('AppProvider: ❌ 加载第 ${_currentPage + 1} 页失败: $e');
      if (kDebugMode) {
        debugPrint('AppProvider: 错误堆栈: $stackTrace');
      }

      // 性能埋点上报（失败）
      _reportLoadPerformance(
        page: _currentPage + 1,
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
      if (_loadMoreState != LoadMoreState.noMore) {
        _loadMoreState = LoadMoreState.idle;
      }
    }
  }

  /// 性能监控埋点上报
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
        'has_more': _hasMoreData.toString(),
        'state': _loadMoreState.description,
      };

      if (error != null) {
        eventData['error'] = error;
      }

      // 友盟埋点上报（需要在主 AppProvider 中实现）
      // UmengAnalyticsService.onEventWithMap('list_load_more', eventData);

      // 性能告警（加载超过1秒）
      if (duration > 1000) {
        debugPrint('⚠️ [性能告警] 列表加载耗时过长: ${duration}ms');
      }

      // Debug模式下打印详细信息
      if (kDebugMode) {
        debugPrint('📊 [性能监控] 加载第$page页: ${success ? '成功' : '失败'} | '
            '耗时${duration}ms | 本页${itemCount}条 | 总计${_notes.length}条');
      }
    } catch (e) {
      // 埋点失败不应该影响主流程
      if (kDebugMode) {
        debugPrint('⚠️ 性能埋点上报失败: $e');
      }
    }
  }

  // ========== 笔记创建方法 ==========

  /// 创建笔记（支持自定义时间戳，用于撤销删除）
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

      // 如果是在线模式且已登录，先尝试保存到服务器
      if (!isLocalMode && isLoggedIn && memosApiService != null) {
        debugPrint('AppProvider: 尝试保存到服务器');
        try {
          final serverNote = await memosApiService!.createMemo(
            content: content,
            visibility: defaultNoteVisibility,
          );

          // 确保服务器返回的笔记标记为已同步
          final syncedServerNote = serverNote.copyWith(isSynced: true);

          // 保存到本地
          await databaseService.saveNote(syncedServerNote);

          // 添加到内存列表
          _notes.insert(0, syncedServerNote);

          debugPrint('AppProvider: 笔记已保存到服务器和本地');

          // 处理引用关系
          await _processNoteReferences(syncedServerNote);

          // 应用当前排序
          _applyCurrentSort();
          notifyListeners();

          return syncedServerNote;
        } catch (e) {
          debugPrint('AppProvider: 保存到服务器失败: $e');

          // 检查是否为Token过期异常
          if (e.toString().contains('Token无效或已过期')) {
            debugPrint('AppProvider: 检测到Token过期，强制用户重新登录');
            // 需要在主 AppProvider 中处理
            throw Exception('登录已过期，请重新登录');
          }

          // 继续本地保存流程
        }
      }

      // 本地模式或服务器保存失败，保存到本地
      debugPrint('AppProvider: 本地保存');
      await databaseService.saveNote(note);

      // 添加到内存列表
      _notes.insert(0, note);

      // 处理引用关系
      await _processNoteReferences(note);

      // 确保置顶笔记仍在最前面
      _applyCurrentSort();

      notifyListeners();

      return note;
    } catch (e) {
      debugPrint('AppProvider: 创建笔记失败: $e');
      throw Exception('创建笔记失败: $e');
    }
  }

  // ========== 笔记更新方法 ==========

  /// 更新笔记
  Future<bool> updateNote(Note note, String newContent) async {
    debugPrint('AppProvider: 开始更新笔记 ID: ${note.id}');
    try {
      // 更新内容
      debugPrint('AppProvider: 创建更新后的笔记对象');
      final updatedNote = note.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      debugPrint('AppProvider: updatedAt - 原始: ${note.updatedAt}, 新: ${updatedNote.updatedAt}');

      // 提取标签
      debugPrint('AppProvider: 提取标签');
      final tags = extractTags(newContent);
      debugPrint('AppProvider: 提取到的标签: ${tags.join(', ')}');
      final noteWithTags = updatedNote.copyWith(tags: tags);

      // 更新本地数据库
      debugPrint('AppProvider: 更新本地数据库');
      await databaseService.updateNote(noteWithTags);

      // ✅ 立即更新内存中的笔记（包含批注）
      final memIndex = _notes.indexWhere((n) => n.id == note.id);
      if (memIndex != -1) {
        _notes[memIndex] = noteWithTags;
      }

      // 如果是在线模式且已登录，尝试同步到服务器
      if (!isLocalMode && isLoggedIn && memosApiService != null) {
        try {
          debugPrint('AppProvider: 尝试同步到服务器，笔记ID: ${noteWithTags.id}');

          final serverNote = await memosApiService!.updateMemo(
            noteWithTags.id,
            content: newContent,
          );

          // 检查返回的笔记ID是否与原笔记ID不同
          if (serverNote.id != noteWithTags.id) {
            debugPrint(
              'AppProvider: 服务器返回了新的笔记ID: ${serverNote.id}，原ID: ${noteWithTags.id}',
            );
            // 删除本地旧笔记
            await databaseService.deleteNote(noteWithTags.id);

            // 保存新笔记
            final newSyncedNote = serverNote.copyWith(isSynced: true, tags: tags);
            await databaseService.saveNote(newSyncedNote);

            // 更新内存中的列表 - 删除旧笔记
            _notes.removeWhere((n) => n.id == noteWithTags.id);
            // 添加新笔记
            _notes.insert(0, newSyncedNote);

            _applyCurrentSort();
            notifyListeners();
            debugPrint('AppProvider: 笔记已作为新笔记保存（ID已更改）');
            return true;
          }

          debugPrint('AppProvider: 服务器同步成功，更新同步状态');

          // 重要修复：保护本地引用关系和批注数据
          final index = _notes.indexWhere((n) => n.id == note.id);
          var existingRelations = <Map<String, dynamic>>[];
          var existingAnnotations = <Annotation>[];

          if (index != -1) {
            existingRelations = _notes[index].relations;
            existingAnnotations = _notes[index].annotations;
          }

          // 创建同步后的笔记，保留本地引用关系和批注
          final syncedNote = serverNote.copyWith(
            isSynced: true,
            tags: tags,
            relations: existingRelations,
            annotations: existingAnnotations,
          );
          await databaseService.updateNote(syncedNote);

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
        } catch (e) {
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

        return true;
      }
    } catch (e) {
      debugPrint('AppProvider: 更新笔记失败: $e');
      return false;
    }
  }

  /// 仅更新本地笔记（不同步到服务器）
  /// 用于修改时间等纯本地操作
  Future<bool> updateNoteLocally(Note note) async {
    try {
      debugPrint('AppProvider: 开始本地更新笔记 ID: ${note.id}');

      // 更新本地数据库
      await databaseService.updateNote(note);
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
    } catch (e) {
      debugPrint('AppProvider: 本地更新笔记失败: $e');
      return false;
    }
  }

  /// 更新笔记标签（用于标签管理操作）
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
      await databaseService.updateNote(updatedNote);

      // 更新内存
      _notes[index] = updatedNote;

      // 如果是在线模式且已登录，尝试同步到服务器
      if (!isLocalMode && isLoggedIn && memosApiService != null) {
        try {
          await memosApiService!.updateMemo(
            updatedNote.id,
            content: updatedNote.content,
          );
        } catch (e) {
          debugPrint('AppProvider: 同步标签到服务器失败: $e');
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AppProvider: 更新笔记标签失败: $e');
      return false;
    }
  }

  // ========== 笔记删除方法 ==========

  /// 删除笔记（本地和服务器） - 使用乐观更新策略
  Future<bool> deleteNote(String id, {bool showSnackBar = false}) async {
    try {
      // 1. 立即从内存中删除并更新UI（乐观更新）
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

      // 2. 后台异步执行实际删除操作（不阻塞UI）
      _performBackgroundDelete(id);

      return true;
    } catch (e) {
      debugPrint('AppProvider: 删除笔记失败: $e');
      return false;
    }
  }

  /// 后台执行删除操作（大厂级批量处理）
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

  /// 处理删除队列（大厂级批量删除，智能协调）
  Future<void> _processDeleteQueue() async {
    if (_isProcessingDelete || _deleteQueue.isEmpty) return;

    _isProcessingDelete = true;

    // 1. 暂停自动同步，避免冲突
    final wasSyncing = syncTimer?.isActive ?? false;
    syncTimer?.cancel();

    // 2. 批量处理本地数据库（一次性事务）
    try {
      final idsToDelete = List<String>.from(_deleteQueue);
      _deleteQueue.clear();

      // 批量删除本地数据
      for (final id in idsToDelete) {
        try {
          await databaseService.deleteNote(id);
          await _cleanupReferencesForDeletedNote(id);
        } catch (e) {
          // 单个失败不影响其他
        }
      }

      // 3. 批量同步到服务器（并发请求）
      if (!isLocalMode && isLoggedIn && memosApiService != null) {
        final deleteFutures = idsToDelete.map((id) async {
          try {
            await memosApiService!.deleteMemo(id);
          } catch (e) {
            // 服务器删除失败不影响用户体验
          }
        });

        // 并发执行，但有超时保护
        await Future.wait(deleteFutures).timeout(
          const Duration(seconds: 10),
          onTimeout: () => [],
        );
      }
    } catch (e) {
      // 批量处理失败，记录但不影响UI
    }

    // 4. 恢复自动同步（需要在主 AppProvider 中实现）
    // if (wasSyncing) {
    //   startAutoSync();
    // }

    _isProcessingDelete = false;

    // 5. 如果队列中又有新的删除请求，继续处理
    if (_deleteQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      _processDeleteQueue();
    }
  }

  /// 撤销删除笔记
  Future<bool> restoreNote() async {
    if (_lastDeletedNote == null || _lastDeletedIndex == null) {
      debugPrint('AppProvider: 没有可撤销的删除操作');
      return false;
    }

    try {
      debugPrint('AppProvider: 🔙 开始撤销删除笔记 ID: ${_lastDeletedNote!.id}');

      // 1. 恢复到内存列表
      _notes.insert(_lastDeletedIndex!, _lastDeletedNote!);
      notifyListeners(); // ⚡ UI立即刷新

      debugPrint('AppProvider: ⚡ UI已更新（笔记已恢复到列表）');

      // 2. 后台恢复到数据库
      await databaseService.saveNote(_lastDeletedNote!);

      // 3. 清理临时变量
      _lastDeletedNote = null;
      _lastDeletedIndex = null;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 仅从本地数据库删除笔记
  Future<bool> deleteNoteLocal(String id) async {
    debugPrint('AppProvider: 从本地数据库删除笔记 ID: $id');
    try {
      // 删除本地数据库中的笔记
      await databaseService.deleteNote(id);

      // 从内存中的列表删除
      _notes.removeWhere((note) => note.id == id);

      // 立即清理所有相关的引用关系
      await _cleanupReferencesForDeletedNote(id);

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('AppProvider: 从本地删除笔记失败: $e');
      throw Exception('删除本地笔记失败: $e');
    }
  }

  /// 仅从服务器删除笔记
  Future<bool> deleteNoteFromServer(String id) async {
    debugPrint('AppProvider: 从服务器删除笔记 ID: $id');
    try {
      if (!isLoggedIn || memosApiService == null) {
        debugPrint('AppProvider: 未登录或API服务不可用');
        return false;
      }

      // 从服务器删除
      await memosApiService!.deleteMemo(id);
      return true;
    } catch (e) {
      debugPrint('AppProvider: 从服务器删除笔记失败: $e');
      throw Exception('从服务器删除笔记失败: $e');
    }
  }

  // ========== 笔记操作方法 ==========

  /// 切换笔记的置顶状态
  Future<bool> togglePinStatus(Note note) async {
    try {
      // 切换置顶状态
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );

      // 更新本地数据库
      await databaseService.updateNote(updatedNote);

      // 先立即更新内存中的列表，让UI快速响应
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }

      // 立即通知UI更新
      notifyListeners();

      // 如果是在线模式且已登录，尝试同步到服务器
      if (!isLocalMode && isLoggedIn && memosApiService != null) {
        try {
          // 使用专门的 memo_organizer API 来更新置顶状态
          final serverNote = await memosApiService!.updateMemoOrganizer(
            note.id,
            pinned: updatedNote.isPinned,
          );

          // 更新本地数据库（服务器返回的数据已包含正确的 isPinned 状态）
          final syncedNote = serverNote.copyWith(
            isSynced: true,
          );
          await databaseService.updateNote(syncedNote);

          // 更新内存中的列表为服务器返回的数据
          final serverIndex = _notes.indexWhere((n) => n.id == note.id);
          if (serverIndex != -1) {
            _notes[serverIndex] = syncedNote;
          }

          debugPrint('置顶状态已同步到服务器: ${updatedNote.isPinned}');
        } catch (e) {
          // 如果同步失败，本地状态已经更新，不需要额外处理
          debugPrint('同步置顶状态到服务器失败（正常，本地笔记或网络问题）: $e');
        }
      }

      // 重新排序笔记列表
      final currentOrder = _getCurrentSortOrder();
      sortNotes(currentOrder);

      return true;
    } catch (e) {
      debugPrint('切换置顶状态失败: $e');
      return false;
    }
  }

  // ========== 笔记排序方法 ==========

  /// 排序笔记
  void sortNotes(SortOrder order) {
    switch (order) {
      case SortOrder.newest:
        _notes.sort((a, b) {
          // 先按是否置顶排序，置顶的在前面
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // 再按创建时间排序
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case SortOrder.oldest:
        _notes.sort((a, b) {
          // 先按是否置顶排序，置顶的在前面
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // 再按创建时间排序
          return a.createdAt.compareTo(b.createdAt);
        });
        break;
      case SortOrder.updated:
        _notes.sort((a, b) {
          // 先按是否置顶排序，置顶的在前面
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          // 再按更新时间排序
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }
    notifyListeners();
  }

  /// 设置排序方式
  void setSortOrder(SortOrder sortOrder) {
    if (_sortOrder != sortOrder) {
      _sortOrder = sortOrder;
      notifyListeners();
    }
  }

  /// 获取排序后的笔记
  List<Note> _getSortedNotes() {
    final sortedNotes = List<Note>.from(_notes);

    // 首先按置顶状态排序，然后按照选择的排序方式排序
    sortedNotes.sort((a, b) {
      // 置顶的笔记始终排在前面
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // 如果两个笔记的置顶状态相同，则按照选择的排序方式排序
      switch (_sortOrder) {
        case SortOrder.newest:
          return b.createdAt.compareTo(a.createdAt);
        case SortOrder.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case SortOrder.updated:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return sortedNotes;
  }

  /// 获取当前的排序方式
  SortOrder _getCurrentSortOrder() {
    if (_notes.length < 2) return SortOrder.newest;

    // 忽略置顶状态，仅根据时间判断排序方式
    final unpinnedNotes = _notes.where((note) => !note.isPinned).toList();
    if (unpinnedNotes.length < 2) return SortOrder.newest;

    if (unpinnedNotes[0].createdAt.isAfter(unpinnedNotes[1].createdAt)) {
      return SortOrder.newest;
    } else if (unpinnedNotes[0]
        .createdAt
        .isBefore(unpinnedNotes[1].createdAt)) {
      return SortOrder.oldest;
    } else if (unpinnedNotes[0].updatedAt.isAfter(unpinnedNotes[1].updatedAt)) {
      return SortOrder.updated;
    }

    return SortOrder.newest; // 默认返回最新排序
  }

  /// 应用当前排序规则
  void _applyCurrentSort() {
    final currentOrder = _getCurrentSortOrder();
    sortNotes(currentOrder);
  }

  // ========== 笔记标签方法 ==========

  /// 从文本内容中提取标签（改进版，排除URL中的#）
  List<String> extractTags(String content) {
    // 使用统一的标签提取逻辑（与Note.extractTagsFromContent一致）
    return Note.extractTagsFromContent(content);
  }

  /// 获取所有标签
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  /// 重新提取所有笔记的标签
  void _refreshAllNoteTags() {
    for (var i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      final tags = extractTags(note.content);
      if (tags.length != note.tags.length ||
          !note.tags.toSet().containsAll(tags)) {
        debugPrint(
          'AppProvider: 更新笔记 ${note.id} 的标签: ${note.tags.join(',')} -> ${tags.join(',')}',
        );
        _notes[i] = note.copyWith(tags: tags);
      }
    }
  }

  /// 扫描所有笔记并更新标签（包括数据库更新）
  Future<void> refreshAllNoteTagsWithDatabase() async {
    _setLoading(true);
    try {
      for (var i = 0; i < _notes.length; i++) {
        final note = _notes[i];
        final tags = extractTags(note.content);
        if (tags.length != note.tags.length ||
            !note.tags.toSet().containsAll(tags)) {
          debugPrint(
            'AppProvider: 更新笔记 ${note.id} 的标签: ${note.tags.join(',')} -> ${tags.join(',')}',
          );
          final updatedNote = note.copyWith(tags: tags);
          _notes[i] = updatedNote;
          await databaseService.updateNote(updatedNote);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: 更新所有笔记标签失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ========== 笔记引用处理方法 ==========

  /// 处理笔记引用关系（需要在主 AppProvider 中实现具体逻辑）
  Future<void> _processNoteReferences(Note note) async {
    // 使用统一引用管理器处理引用关系
    try {
      await UnifiedReferenceManager().processNoteReferences(note);
    } catch (e) {
      debugPrint('AppProvider: 处理笔记引用关系失败: $e');
    }
  }

  /// 清理被删除笔记的所有相关引用关系
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
          await databaseService.updateNote(updatedNote);
          _notes[i] = updatedNote;
          hasChanges = true;

          final removedCount = originalRelationsCount - cleanedRelations.length;
          debugPrint('AppProvider: 清理了 $removedCount 个引用关系');
        }
      }

      if (hasChanges) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppProvider: 清理引用关系失败: $e');
    }
  }

  /// 在笔记ID变化后更新所有引用关系
  Future<void> _updateReferenceIdsAfterSync(String oldId, String newId) async {
    try {
      final allNotes = await databaseService.getNotes();
      var hasUpdates = false;

      for (final note in allNotes) {
        var noteUpdated = false;
        final updatedRelations = <Map<String, dynamic>>[];

        for (final relation in note.relations) {
          final relationMap = Map<String, dynamic>.from(relation);

          // 更新 memoId
          if (relationMap['memoId'] == oldId) {
            relationMap['memoId'] = newId;
            noteUpdated = true;
          }

          // 更新 relatedMemoId
          if (relationMap['relatedMemoId'] == oldId) {
            relationMap['relatedMemoId'] = newId;
            noteUpdated = true;
          }

          updatedRelations.add(relationMap);
        }

        if (noteUpdated) {
          final updatedNote = note.copyWith(relations: updatedRelations);
          await databaseService.updateNote(updatedNote);

          // 更新内存中的笔记
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = updatedNote;
          }

          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        notifyListeners();
        debugPrint('AppProvider: 引用关系ID更新完成 ($oldId -> $newId)');
      }
    } catch (e) {
      debugPrint('AppProvider: 更新引用关系ID失败: $e');
    }
  }

  // ========== 辅助方法 ==========

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 修复失效的图片路径
  Future<bool> _fixBrokenImagePaths() async {
    var hasUpdates = false;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');

      if (!await imagesDir.exists()) {
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

      for (var i = 0; i < _notes.length; i++) {
        final note = _notes[i];
        final imageRegex = RegExp(r'!\[图片\]\(file://([^)]+)\)');
        final matches = imageRegex.allMatches(note.content);

        if (matches.isEmpty) continue;

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
            }
          }
        }

        if (noteUpdated) {
          final updatedNote = note.copyWith(content: updatedContent);
          _notes[i] = updatedNote;
          await databaseService.updateNote(updatedNote);
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        notifyListeners();

        // 延迟一点时间后再次刷新，确保图片组件重新加载
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('AppProvider: 修复图片路径失败: $e');
    }

    return hasUpdates;
  }

  /// 同步笔记到服务器（需要在主 AppProvider 中实现）
  Future<void> syncNotesWithServer() async {
    if (!isLoggedIn || memosApiService == null) return;

    await PerformanceTracker().startTrace('sync_notes_to_server');
    Log.sync.info('Starting sync to server');

    try {
      // 获取未同步的笔记
      final unsyncedNotes = await databaseService.getUnsyncedNotes();

      if (unsyncedNotes.isEmpty) {
        Log.sync.debug('No unsynced notes');
        await PerformanceTracker().stopTrace('sync_notes_to_server',
          success: true,
          metrics: {'note_count': 0},
        );
        return;
      }

      Log.sync.info('Syncing notes', data: {'count': unsyncedNotes.length});

      // 逐一同步到服务器
      int successCount = 0;
      for (final note in unsyncedNotes) {
        try {
          final oldId = note.id;

          // 创建服务器笔记
          final serverNote = await memosApiService!.createMemo(
            content: note.content,
            visibility: note.visibility.isNotEmpty
                ? note.visibility
                : defaultNoteVisibility,
          );

          final newId = serverNote.id;

          // 如果ID发生变化，更新所有引用关系
          if (oldId != newId) {
            await _updateReferenceIdsAfterSync(oldId, newId);
          }

          // 删除本地笔记（使用临时ID）
          await databaseService.deleteNote(note.id);

          // 保存服务器返回的笔记（带有服务器ID）
          await databaseService.saveNote(serverNote);

          // 更新内存中的列表
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = serverNote;
          }

          successCount++;
        } catch (e, stackTrace) {
          Log.sync.error('Failed to sync note', error: e, stackTrace: stackTrace, data: {
            'note_id': note.id,
          });
          await ErrorHandler.captureException(e, stackTrace: stackTrace, context: {
            'operation': 'sync_single_note',
            'note_id': note.id,
          });
        }
      }

      // 刷新内存中的列表
      await loadNotesFromLocal();

      await PerformanceTracker().stopTrace('sync_notes_to_server',
        success: true,
        metrics: {
          'total_count': unsyncedNotes.length,
          'success_count': successCount,
          'failure_count': unsyncedNotes.length - successCount,
        },
      );
      Log.sync.info('Sync completed', data: {
        'success': successCount,
        'failed': unsyncedNotes.length - successCount,
      });
    } catch (e, stackTrace) {
      await PerformanceTracker().stopTrace('sync_notes_to_server', success: false);
      Log.sync.error('Sync to server failed', error: e, stackTrace: stackTrace);
      await ErrorHandler.captureException(e, stackTrace: stackTrace, context: {
        'operation': 'sync_notes_to_server',
      });
    }
  }

  /// 同步笔记到服务器（简化版）
  Future<bool> syncNotesToServer() async {
    if (!isLoggedIn || memosApiService == null) return false;

    try {
      // 获取未同步的笔记
      final unsyncedNotes = await databaseService.getUnsyncedNotes();

      // 逐一同步到服务器
      for (final note in unsyncedNotes) {
        try {
          final oldId = note.id;

          // 创建服务器笔记
          final serverNote = await memosApiService!.createMemo(
            content: note.content,
            visibility: note.visibility.isNotEmpty
                ? note.visibility
                : defaultNoteVisibility,
          );

          final newId = serverNote.id;

          // 如果ID发生变化，更新所有引用关系
          if (oldId != newId) {
            await _updateReferenceIdsAfterSync(oldId, newId);
          }

          // 删除本地笔记（使用临时ID）
          await databaseService.deleteNote(note.id);

          // 保存服务器返回的笔记（带有服务器ID）
          await databaseService.saveNote(serverNote);

          // 更新内存中的列表
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = serverNote;
          }
        } catch (e) {
          debugPrint('同步笔记失败: ${note.id} - $e');
        }
      }

      // 刷新内存中的列表
      await loadNotesFromLocal();
      return true;
    } catch (e) {
      debugPrint('同步笔记到服务器失败: $e');
      return false;
    }
  }
}
