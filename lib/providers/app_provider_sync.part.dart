part of 'app_provider.dart';

extension AppProviderSyncPart on AppProvider {
  // 从服务器获取笔记
  Future<void> fetchNotesFromServer() async {
    // 设置同步状态
    _setSyncUi(syncing: true, message: '正在从服务器获取数据...');

    try {
      // 检查并快速重新初始化API服务
      if (_memosApiService == null) {
        await _ensureApiServiceInitialized();
      }

      // 首先获取本地所有笔记（包括已同步和未同步的）
      _setSyncMessage('备份本地笔记...');

      debugPrint('AppProvider: 获取所有本地笔记');
      final localNotes =
          _excludePendingDeletedNotes(await _databaseService.getNotes());
      final unsyncedNotes = _excludePendingDeletedNotes(
        await _databaseService.getUnsyncedNotes(),
      );
      debugPrint(
        'AppProvider: 本地共有 ${localNotes.length} 条笔记，其中 ${unsyncedNotes.length} 条未同步',
      );

      _setSyncMessage('获取远程笔记...');

      debugPrint('AppProvider: 从服务器获取笔记');
      final response = await _memosApiService!.getMemos();
      final isRemoteComplete = response['isComplete'] as bool? ?? true;

      _setSyncMessage('处理笔记数据...');

      final memosList = response['memos'] as List<dynamic>;
      final serverNotes = memosList
          .map((memo) => Note.fromJson(memo as Map<String, dynamic>))
          .where(_isVisibleNote) // 🔥 过滤掉归档和待删除笔记
          .toList();

      // 🚀 性能优化：批量处理标签提取，不阻塞UI
      // Note.fromJson已经包含relationList，无需单独请求引用关系
      for (var i = 0; i < serverNotes.length; i++) {
        final note = serverNotes[i];
        final tags = Note.extractTagsFromContent(note.content);

        // 确保服务器笔记都标记为已同步，relations已在fromJson中处理
        serverNotes[i] = note.copyWith(
          tags: tags,
          isSynced: true,
        );
      }

      _setSyncMessage('智能合并数据...');

      // 智能合并策略：优先保留服务器数据，但不丢失本地未同步的数据
      final mergedNotes = <Note>[];
      final serverNoteIds = serverNotes.map((note) => note.id).toSet();
      final serverNoteHashes = serverNotes.map(_calculateNoteHash).toSet();
      final localNotesById = {for (final note in localNotes) note.id: note};

      // 1. 添加所有服务器笔记，但保留本地的引用关系和置顶状态
      for (final serverNote in serverNotes) {
        final localNote = localNotesById[serverNote.id];

        if (localNote != null) {
          mergedNotes
              .add(_mergeServerNoteWithLocalState(serverNote, localNote));
        } else {
          mergedNotes.add(serverNote);
        }
      }
      debugPrint('AppProvider: 添加 ${serverNotes.length} 条服务器笔记');

      // 2. 添加本地未同步的笔记（避免重复）
      var addedUnsyncedCount = 0;
      for (var note in unsyncedNotes) {
        final noteHash = _calculateNoteHash(note);

        // 检查是否与服务器数据重复
        final isDuplicate = serverNoteHashes.contains(noteHash);
        final hasIdConflict =
            serverNoteIds.contains(note.id) && !note.id.startsWith('local_');

        if (!isDuplicate) {
          // 如果ID冲突但内容不重复，生成新的本地ID
          if (hasIdConflict) {
            note = note.copyWith(
              id: 'local_${DateTime.now().millisecondsSinceEpoch}_$addedUnsyncedCount',
              isSynced: false,
            );
          }
          mergedNotes.add(note);
          addedUnsyncedCount++;
        } else {
          debugPrint('AppProvider: 跳过重复笔记: ${note.id}');
        }
      }

      debugPrint('AppProvider: 添加 $addedUnsyncedCount 条本地未同步笔记');

      // 3. 更新本地数据库（upsert 策略：不清空，避免写入中断时丢失数据）
      debugPrint('AppProvider: 更新本地数据库');
      await _databaseService.saveNotes(mergedNotes);
      // 删除服务器已不存在的本地已同步笔记，未同步笔记保留
      if (isRemoteComplete) {
        await _databaseService.deleteSyncedNotesNotIn(serverNoteIds.toList());
      } else {
        debugPrint('AppProvider: 远程分页未完整，跳过本地删除清理');
      }

      // 4. 🚀 同步完成后重新完整加载笔记
      // 大厂标准：同步完成后应该从数据库重新加载全部数据，确保数据一致性
      _totalNotesCount = mergedNotes.length;

      // 🔥 关键修复：从数据库重新加载全部笔记（确保数据新鲜且正确排序）
      final dbNotes = _excludePendingDeletedNotes(
        await _databaseService.getNotes(),
      ); // 加载全部数据

      // ✅ 保护内存中的批注数据（批注是本地增强功能，不同步到服务器）
      final memoryNotesMap = {for (final note in _notes) note.id: note};

      _notes = dbNotes.map((dbNote) {
        // 如果内存中有这个笔记且有批注，保留其批注
        final memoryNote = memoryNotesMap[dbNote.id];
        if (memoryNote != null && memoryNote.annotations.isNotEmpty) {
          return dbNote.copyWith(annotations: memoryNote.annotations);
        }
        return dbNote;
      }).toList();

      // 重置分页状态
      _pagingState = paging.NotesPaginationState(
        currentPage:
            (_notes.length / AppProvider._pageSize).floor(), // 根据实际加载的数量计算页码
        hasMoreData: false, // 已经全部加载
        loadMoreState: LoadMoreState.idle,
      );

      _setSyncMessage('同步完成');

      debugPrint(
        'AppProvider: ✅ 笔记同步完成！数据库总计 $_totalNotesCount 条，已全部加载 ${_notes.length} 条到内存',
      );
    } on Object catch (e, stackTrace) {
      debugPrint('AppProvider: 从服务器获取数据失败: $e');
      debugPrint('AppProvider: 错误堆栈: $stackTrace');

      // 🔥 过滤 Firebase 错误（项目未使用 Firebase，忽略相关错误）
      final errorString = e.toString();
      if (errorString.contains('Firebase') ||
          errorString.contains('[core/no-app]') ||
          errorString.contains('FirebaseApp')) {
        debugPrint('⚠️ 检测到 Firebase 相关错误，已忽略（项目未使用 Firebase）');
        _setSyncUi(syncing: false);
        // 继续加载本地数据
        await loadNotesFromLocal();
        return;
      }

      // 检查是否为Token过期异常
      if (e is TokenExpiredException || sync_status.isTokenExpiredError(e)) {
        debugPrint('AppProvider: 检测到Token过期，强制用户重新登录');
        _setSyncMessage('登录已过期，请重新登录');
        await _handleTokenExpired();
        return;
      }

      _setSyncMessage(sync_status.syncFailedMessage(e));

      // 如果是API服务初始化失败，尝试清除登录状态
      if (e.toString().contains('API服务初始化失败')) {
        await logout(force: true);
      }

      debugPrint('AppProvider: 保留本地数据');
      // 加载本地数据作为后备
      await loadNotesFromLocal();

      rethrow;
    } finally {
      // 延迟一点时间再清除同步状态，让用户有时间看到"同步完成"
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setSyncUi(syncing: false);
        }
      });
    }
  }

  // 从云端同步数据
  Future<void> syncWithServer() async {
    if (!isLoggedIn || _memosApiService == null) {
      throw Exception('请先登录您的账号');
    }

    // 设置同步状态
    _setSyncUi(syncing: true, message: '准备同步...');

    try {
      // 1. 先将本地未同步的笔记上传到服务器
      _setSyncMessage('上传本地笔记...');

      final unsyncedNotes = _excludePendingDeletedNotes(
        await _databaseService.getUnsyncedNotes(),
      );
      debugPrint('AppProvider: 发现 ${unsyncedNotes.length} 条未同步笔记');

      for (final note in unsyncedNotes) {
        try {
          await _syncUnsyncedNotesSnapshot([note]);
        } on Object catch (e) {
          debugPrint('同步笔记到服务器失败: ${note.id} - $e');
        }
      }

      // 2. 从服务器获取最新数据
      _setSyncMessage('获取服务器数据...');

      final response = await _memosApiService!.getMemos();
      final isRemoteComplete = response['isComplete'] as bool? ?? true;

      final memosList = response['memos'] as List<dynamic>;
      final serverNotes = memosList
          .map((memo) => Note.fromJson(memo as Map<String, dynamic>))
          .where(_isVisibleNote) // 🔥 过滤掉归档和待删除笔记
          .toList();
      final localNotes =
          _excludePendingDeletedNotes(await _databaseService.getNotes());
      final localNotesById = {for (final note in localNotes) note.id: note};

      // 3. 为所有服务器笔记重新提取标签
      _setSyncMessage('处理笔记数据...');

      for (var i = 0; i < serverNotes.length; i++) {
        final note = serverNotes[i];
        final tags = Note.extractTagsFromContent(note.content);
        if (tags.isNotEmpty) {
          serverNotes[i] = note.copyWith(tags: tags);
        }
      }

      // 4. 更新本地数据库（upsert 策略）
      _setSyncMessage('更新本地数据...');

      final mergedServerNotes = serverNotes.map((serverNote) {
        final localNote = localNotesById[serverNote.id];
        return localNote == null
            ? serverNote
            : _mergeServerNoteWithLocalState(serverNote, localNote);
      }).toList();
      await _databaseService.saveNotes(mergedServerNotes);
      final syncedServerIds = mergedServerNotes.map((n) => n.id).toList();
      if (isRemoteComplete) {
        await _databaseService.deleteSyncedNotesNotIn(syncedServerIds);
      } else {
        debugPrint('AppProvider: 远程分页未完整，跳过本地删除清理');
      }

      // 5. 更新内存中的列表
      _notes = _excludePendingDeletedNotes(await _databaseService.getNotes());

      _setSyncMessage('同步完成');

      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setSyncUi(syncing: false);
        }
      });
    } on Object catch (e) {
      debugPrint('同步失败: $e');
      _setSyncMessage(sync_status.syncFailedMessage(e));

      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _setSyncUi(syncing: false);
        }
      });

      rethrow;
    }
  }
}
