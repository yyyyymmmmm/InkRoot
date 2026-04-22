import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/webdav_service.dart';

/// 同步状态
enum SyncStatus {
  idle, // 空闲
  syncing, // 同步中
  success, // 成功
  failed, // 失败
}

/// 同步统计信息
class SyncStats {
  // 错误数量

  const SyncStats({
    this.uploaded = 0,
    this.downloaded = 0,
    this.deleted = 0,
    this.conflicts = 0,
    this.errors = 0,
  });
  final int uploaded; // 上传数量
  final int downloaded; // 下载数量
  final int deleted; // 删除数量
  final int conflicts; // 冲突数量
  final int errors;

  SyncStats copyWith({
    int? uploaded,
    int? downloaded,
    int? deleted,
    int? conflicts,
    int? errors,
  }) =>
      SyncStats(
        uploaded: uploaded ?? this.uploaded,
        downloaded: downloaded ?? this.downloaded,
        deleted: deleted ?? this.deleted,
        conflicts: conflicts ?? this.conflicts,
        errors: errors ?? this.errors,
      );

  @override
  String toString() =>
      'SyncStats(上传: $uploaded, 下载: $downloaded, 删除: $deleted, 冲突: $conflicts, 错误: $errors)';
}

/// WebDAV 同步引擎
///
/// 使用单个 notes.json 文件同步所有笔记（类似导入导出格式）
class WebDavSyncEngine {
  WebDavSyncEngine(this._webdavService, this._databaseService);
  final WebDavService _webdavService;
  final DatabaseService _databaseService;

  SyncStatus _status = SyncStatus.idle;
  SyncStats _stats = const SyncStats();
  String _syncMessage = '';

  /// 当前同步状态
  SyncStatus get status => _status;

  /// 当前同步统计
  SyncStats get stats => _stats;

  /// 同步消息
  String get syncMessage => _syncMessage;

  /// 初始化同步环境
  Future<void> initialize() async {
    try {
      final config = _webdavService.config;
      if (config == null) {
        throw Exception('WebDAV 配置未设置');
      }

      // 创建必要的文件夹结构
      final basePath = config.fullSyncPath;
      await _webdavService.createFolder(basePath);

      // 创建 resources 文件夹用于存储图片
      await _webdavService.createFolder('${basePath}resources/');

      // 初始化备份文件
      await _initializeBackupFile(basePath);
    } catch (e) {
      rethrow;
    }
  }

  /// 初始化备份文件
  Future<void> _initializeBackupFile(String basePath) async {
    // 使用单个 notes.json 文件存储所有笔记
    final notesPath = '${basePath}notes.json';

    try {
      // 尝试读取现有文件
      await _webdavService.downloadFile(notesPath);
    } catch (e) {
      // 文件不存在，创建新的空备份文件

      final backupData = {
        'version': '1.0',
        'lastSync': DateTime.now().toIso8601String(),
        'noteCount': 0,
        'notes': [],
      };

      await _webdavService.uploadFile(notesPath, jsonEncode(backupData));
    }
  }

  /// 执行增量同步
  Future<SyncStats> sync() async {
    // 🔧 改进：检查并自动重置异常状态
    if (_status == SyncStatus.syncing) {
      throw Exception('同步正在进行中，请稍后再试');
    }

    _status = SyncStatus.syncing;
    _stats = const SyncStats();
    _syncMessage = '准备同步...';

    try {
      final config = _webdavService.config;
      if (config == null) {
        throw Exception('WebDAV 配置未设置');
      }

      final notesPath = '${config.fullSyncPath}notes.json';
      final now = DateTime.now();

      // 1. 获取本地所有笔记
      _syncMessage = '读取本地笔记...';
      final localNotes = await _databaseService.getNotes();

      // 2. 下载远程笔记数据
      _syncMessage = '下载远程备份...';
      var remoteNotes = <Note>[];
      var lastRemoteSync = DateTime(2000); // 默认很早的时间
      
      try {
        final remoteContent = await _webdavService.downloadFile(notesPath);
        final remoteData = jsonDecode(remoteContent);
        if (remoteData['lastSync'] != null) {
          lastRemoteSync = DateTime.parse(remoteData['lastSync']);
        }
        if (remoteData['notes'] is List) {
          remoteNotes = (remoteData['notes'] as List)
              .map((json) => Note.fromJson(json))
              .toList();
        }
      } catch (e) {
        // 远程文件不存在，首次同步
      }

      // 3. 🚀 增量同步：只处理有变化的笔记
      _syncMessage = '增量合并笔记...';
      final mergedNotes = await _mergeNotesIncremental(
        localNotes,
        remoteNotes,
        lastRemoteSync,
      );

      // 4. 同步图片资源（只同步变化的笔记的图片）
      _syncMessage = '同步图片资源...';
      final changedNotes = mergedNotes.where((note) {
        return note.lastSyncTime == null ||
            note.updatedAt.isAfter(note.lastSyncTime!);
      }).toList();
      await _syncResources(changedNotes);

      // 5. 上传合并后的笔记（全量，但标记了同步时间）
      _syncMessage = '上传到云端...';
      final backupData = {
        'version': '2.0', // 增量同步版本
        'lastSync': now.toIso8601String(),
        'noteCount': mergedNotes.length,
        'notes': mergedNotes.map((note) => note.toJson()).toList(),
      };

      await _webdavService.uploadFile(notesPath, jsonEncode(backupData));

      _status = SyncStatus.success;
      _syncMessage = '同步完成';

      return _stats;
    } catch (e) {
      _status = SyncStatus.failed;
      _syncMessage = '同步失败: $e';

      rethrow;
    } finally {
      // 🔧 大厂标准：无论成功失败，确保状态最终回到稳定态
      // 防止异常中断导致状态卡住
      if (_status == SyncStatus.syncing) {
        _status = SyncStatus.failed;
      }
    }
  }

  /// 🚀 增量合并本地和远程笔记
  Future<List<Note>> _mergeNotesIncremental(
    List<Note> localNotes,
    List<Note> remoteNotes,
    DateTime lastRemoteSync,
  ) async {
    final mergedMap = <String, Note>{};
    var uploaded = 0;
    var downloaded = 0;
    var deleted = 0;
    final now = DateTime.now();

    // 创建远程笔记映射（用于快速查找）
    final remoteNoteMap = <String, Note>{};
    for (final note in remoteNotes) {
      remoteNoteMap[note.id] = note;
    }

    // 处理本地笔记
    for (final localNote in localNotes) {
      final remoteNote = remoteNoteMap[localNote.id];

      if (remoteNote == null) {
        // 本地独有的笔记
        // 检查是否需要上传（本地修改时间 > 上次同步时间）
        if (localNote.lastSyncTime == null ||
            localNote.updatedAt.isAfter(localNote.lastSyncTime!)) {
          // 需要上传
          final syncedNote = localNote.copyWith(lastSyncTime: now);
          mergedMap[localNote.id] = syncedNote;
          await _databaseService.saveNote(syncedNote);
          uploaded++;
        } else {
          // 已同步过，保持不变
          mergedMap[localNote.id] = localNote;
        }
      } else {
        // 本地和远程都有的笔记，比较更新时间
        if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          // 远程更新，使用远程版本
          final syncedNote = remoteNote.copyWith(lastSyncTime: now);
          mergedMap[remoteNote.id] = syncedNote;
          await _databaseService.saveNote(syncedNote);
          downloaded++;
        } else if (localNote.updatedAt.isAfter(remoteNote.updatedAt)) {
          // 本地更新，上传本地版本
          final syncedNote = localNote.copyWith(lastSyncTime: now);
          mergedMap[localNote.id] = syncedNote;
          await _databaseService.saveNote(syncedNote);
          uploaded++;
        } else {
          // 时间相同，标记为已同步
          final syncedNote = localNote.copyWith(lastSyncTime: now);
          mergedMap[localNote.id] = syncedNote;
          await _databaseService.saveNote(syncedNote);
        }
      }
    }

    // 处理远程独有的笔记（可能是其他设备新增的）
    for (final remoteNote in remoteNotes) {
      if (!mergedMap.containsKey(remoteNote.id)) {
        // 检查是否是新笔记（在上次同步之后创建的）
        if (remoteNote.createdAt.isAfter(lastRemoteSync)) {
          // 是新笔记，下载
          final syncedNote = remoteNote.copyWith(lastSyncTime: now);
          mergedMap[remoteNote.id] = syncedNote;
          await _databaseService.saveNote(syncedNote);
          downloaded++;
        } else {
          // 是旧笔记但本地没有，可能已被删除，不下载
          deleted++;
        }
      }
    }

    _stats = SyncStats(
      uploaded: uploaded,
      downloaded: downloaded,
      deleted: deleted,
      conflicts: 0,
      errors: 0,
    );

    return mergedMap.values.toList();
  }

  /// 合并本地和远程笔记（保留最新版本，同步删除操作）
  Future<List<Note>> _mergeNotes(
    List<Note> localNotes,
    List<Note> remoteNotes,
  ) async {
    final mergedMap = <String, Note>{};
    var uploaded = 0;
    var downloaded = 0;
    var deleted = 0;
    const conflicts = 0;

    // 创建本地笔记ID集合（用于快速查找）
    final localNoteIds = localNotes.map((note) => note.id).toSet();
    final remoteNoteIds = remoteNotes.map((note) => note.id).toSet();

    // 先添加所有本地笔记
    for (final note in localNotes) {
      mergedMap[note.id] = note;
    }

    // 合并远程笔记
    for (final remoteNote in remoteNotes) {
      final localNote = mergedMap[remoteNote.id];

      if (localNote == null) {
        // 远程独有的笔记
        // 🔧 改进：检查是否是删除操作
        // 如果本地完全没有这个笔记，可能是：
        // 1. 新设备首次同步（应该下载）
        // 2. 本地已删除（不应该下载）
        //
        // 策略：以本地为准，远程多出的笔记不下载（视为已删除）
        // 如果用户需要恢复，可以使用"从 WebDAV 恢复"功能
        deleted++;
        // 不添加到 mergedMap，这样最终上传时就不会包含这个笔记
      } else {
        // 本地和远程都有的笔记，比较更新时间
        if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          // 远程更新，使用远程版本
          mergedMap[remoteNote.id] = remoteNote;
          await _databaseService.saveNote(remoteNote);
          downloaded++;
        } else if (localNote.updatedAt.isAfter(remoteNote.updatedAt)) {
          // 本地更新，保留本地版本
          uploaded++;
        }
        // 如果时间相同，保留本地版本（不计数）
      }
    }

    // 统计本地独有的笔记（需要上传）
    for (final localNote in localNotes) {
      if (!remoteNoteIds.contains(localNote.id)) {
        uploaded++;
      }
    }

    _stats = SyncStats(
      uploaded: uploaded,
      downloaded: downloaded,
      deleted: deleted,
    );

    return mergedMap.values.toList();
  }

  /// 同步图片资源
  Future<void> _syncResources(List<Note> notes) async {
    final config = _webdavService.config;
    if (config == null) return;

    var resourceCount = 0;
    var errorCount = 0;

    for (final note in notes) {
      if (note.resourceList.isEmpty) continue;

      for (final resource in note.resourceList) {
        try {
          final resourceId = resource['id']?.toString();
          final externalLink = resource['externalLink']?.toString();
          final filename = resource['filename']?.toString();

          if (resourceId == null ||
              externalLink == null ||
              externalLink.isEmpty) {
            continue;
          }

          // 获取文件扩展名
          var extension = 'jpg';
          if (filename != null && filename.contains('.')) {
            extension = filename.split('.').last;
          }

          final remotePath =
              '${config.fullSyncPath}resources/$resourceId.$extension';

          // 检查 WebDAV 上是否已存在
          if (await _webdavService.exists(remotePath)) {
            continue;
          }

          // 下载图片

          final response = await http.get(Uri.parse(externalLink));
          if (response.statusCode == 200) {
            // 上传到 WebDAV
            await _webdavService.uploadBinaryFile(
              remotePath,
              response.bodyBytes,
            );
            resourceCount++;
          } else {
            errorCount++;
          }
        } catch (e) {
          errorCount++;
        }
      }
    }

    // 更新统计
    _stats = _stats.copyWith(
      uploaded: _stats.uploaded + resourceCount,
      errors: _stats.errors + errorCount,
    );
  }

  /// 从 WebDAV 恢复（单向下载，完全覆盖本地）
  /// 
  /// [onProgress] 进度回调：(progress, message) => void
  /// - progress: 0.0 ~ 1.0 的进度值
  /// - message: 当前操作描述
  Future<SyncStats> restore({
    void Function(double progress, String message)? onProgress,
  }) async {
    // 🔧 改进：检查并自动重置异常状态
    if (_status == SyncStatus.syncing) {
      throw Exception('恢复正在进行中，请稍后再试');
    }

    _status = SyncStatus.syncing;
    _stats = const SyncStats();
    _syncMessage = '准备恢复...';
    onProgress?.call(0.0, '准备恢复...');

    try {
      final config = _webdavService.config;
      if (config == null) {
        throw Exception('WebDAV 配置未设置');
      }

      final notesPath = '${config.fullSyncPath}notes.json';

      // 1. 下载远程笔记 (0% ~ 50%)
      _syncMessage = '下载远程备份...';
      onProgress?.call(0.1, '检查远程备份...');
      var remoteNotes = <Note>[];
      try {
        // 先检查文件是否存在
        final exists = await _webdavService.exists(notesPath);
        if (!exists) {
          throw Exception('远程备份文件不存在，请先执行"立即备份"创建备份');
        }

        onProgress?.call(0.2, '下载备份文件...');
        final remoteContent = await _webdavService.downloadFile(notesPath);
        if (remoteContent.isEmpty) {
          throw Exception('远程备份文件为空');
        }

        try {
          onProgress?.call(0.3, '解析备份数据...');
          final remoteData = jsonDecode(remoteContent);
          if (remoteData is! Map) {
            throw Exception('备份文件格式错误：不是有效的JSON对象');
          }
          
          if (remoteData['notes'] is List) {
            remoteNotes = (remoteData['notes'] as List)
                .map((json) => Note.fromJson(json))
                .toList();
          } else {
            throw Exception('备份文件格式错误：缺少notes字段或格式不正确');
          }
          onProgress?.call(0.5, '备份数据解析完成，共 ${remoteNotes.length} 条笔记');
        } catch (e) {
          throw Exception('解析备份文件失败: $e');
        }
      } catch (e) {
        rethrow;
      }

      // 2. 保存所有远程笔记到本地（覆盖）(50% ~ 100%)
      _syncMessage = '恢复笔记到本地...';
      final totalNotes = remoteNotes.length;
      for (var i = 0; i < totalNotes; i++) {
        await _databaseService.saveNote(remoteNotes[i]);
        
        // 更新进度：50% ~ 100%
        final progress = 0.5 + (0.5 * (i + 1) / totalNotes);
        onProgress?.call(progress, '恢复笔记中 ${i + 1}/$totalNotes');
      }

      _stats = _stats.copyWith(downloaded: remoteNotes.length);

      _status = SyncStatus.success;
      _syncMessage = '恢复完成';
      onProgress?.call(1.0, '恢复完成');

      return _stats;
    } catch (e) {
      _status = SyncStatus.failed;
      _syncMessage = '恢复失败: $e';

      rethrow;
    } finally {
      // 🔧 大厂标准：无论成功失败，确保状态最终回到稳定态
      // 防止异常中断导致状态卡住
      if (_status == SyncStatus.syncing) {
        _status = SyncStatus.failed;
      }
    }
  }

  /// 执行完整备份（单向上传）
  /// 
  /// [onProgress] 进度回调：(progress, message) => void
  /// - progress: 0.0 ~ 1.0 的进度值
  /// - message: 当前操作描述
  Future<SyncStats> backup({
    void Function(double progress, String message)? onProgress,
  }) async {
    // 🔧 改进：检查并自动重置异常状态
    if (_status == SyncStatus.syncing) {
      throw Exception('备份正在进行中，请稍后再试');
    }

    _status = SyncStatus.syncing;
    _stats = const SyncStats();
    _syncMessage = '准备备份...';
    onProgress?.call(0.0, '准备备份...');

    try {
      final config = _webdavService.config;
      if (config == null) {
        throw Exception('WebDAV 配置未设置');
      }

      final notesPath = '${config.fullSyncPath}notes.json';

      // 1. 获取本地所有笔记 (0% ~ 20%)
      _syncMessage = '读取本地笔记...';
      onProgress?.call(0.1, '读取本地笔记...');
      final localNotes = await _databaseService.getNotes();
      onProgress?.call(0.2, '读取完成，共 ${localNotes.length} 条笔记');

      // 2. 备份图片资源 (20% ~ 60%)
      _syncMessage = '备份图片资源...';
      onProgress?.call(0.3, '开始备份图片资源...');
      await _syncResources(localNotes);
      onProgress?.call(0.6, '图片资源备份完成');

      // 3. 上传笔记数据 (60% ~ 100%)
      _syncMessage = '上传笔记数据...';
      onProgress?.call(0.7, '打包笔记数据...');
      final backupData = {
        'version': '1.0',
        'lastBackup': DateTime.now().toIso8601String(),
        'noteCount': localNotes.length,
        'notes': localNotes.map((note) => note.toJson()).toList(),
      };

      onProgress?.call(0.8, '上传备份文件...');
      await _webdavService.uploadFile(notesPath, jsonEncode(backupData));

      _stats = _stats.copyWith(uploaded: _stats.uploaded + localNotes.length);

      _status = SyncStatus.success;
      _syncMessage = '备份完成';
      onProgress?.call(1.0, '备份完成');

      return _stats;
    } catch (e) {
      _status = SyncStatus.failed;
      _syncMessage = '备份失败: $e';

      rethrow;
    } finally {
      // 🔧 大厂标准：无论成功失败，确保状态最终回到稳定态
      // 防止异常中断导致状态卡住
      if (_status == SyncStatus.syncing) {
        _status = SyncStatus.failed;
      }
    }
  }

  /// 重置同步状态
  void reset() {
    _status = SyncStatus.idle;
    _stats = const SyncStats();
    _syncMessage = '';
  }
}
