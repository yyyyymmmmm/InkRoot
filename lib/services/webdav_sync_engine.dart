import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/webdav_service.dart';
import 'package:path_provider/path_provider.dart';

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
    this.resourceUploaded = 0,
    this.downloaded = 0,
    this.deleted = 0,
    this.conflicts = 0,
    this.errors = 0,
  });
  final int uploaded; // 上传数量
  final int resourceUploaded; // 图片等资源上传数量
  final int downloaded; // 下载数量
  final int deleted; // 删除数量
  final int conflicts; // 冲突数量
  final int errors;

  SyncStats copyWith({
    int? uploaded,
    int? resourceUploaded,
    int? downloaded,
    int? deleted,
    int? conflicts,
    int? errors,
  }) =>
      SyncStats(
        uploaded: uploaded ?? this.uploaded,
        resourceUploaded: resourceUploaded ?? this.resourceUploaded,
        downloaded: downloaded ?? this.downloaded,
        deleted: deleted ?? this.deleted,
        conflicts: conflicts ?? this.conflicts,
        errors: errors ?? this.errors,
      );

  @override
  String toString() =>
      'SyncStats(上传: $uploaded, 资源上传: $resourceUploaded, 下载: $downloaded, 删除: $deleted, 冲突: $conflicts, 错误: $errors)';
}

class _WebDavResourceRecord {
  const _WebDavResourceRecord({
    required this.originalPath,
    required this.webdavPath,
    required this.filename,
    required this.source,
  });

  factory _WebDavResourceRecord.fromJson(Map<String, dynamic> json) =>
      _WebDavResourceRecord(
        originalPath: json['originalPath']?.toString() ?? '',
        webdavPath: json['webdavPath']?.toString() ?? '',
        filename: json['filename']?.toString() ?? '',
        source: json['source']?.toString() ?? 'unknown',
      );

  final String originalPath;
  final String webdavPath;
  final String filename;
  final String source;

  Map<String, dynamic> toJson() => {
        'originalPath': originalPath,
        'webdavPath': webdavPath,
        'filename': filename,
        'source': source,
      };

  bool get isValid => originalPath.isNotEmpty && webdavPath.isNotEmpty;
}

/// WebDAV 同步引擎
///
/// 使用单个 notes.json 文件同步所有笔记（类似导入导出格式）
class WebDavSyncEngine {
  WebDavSyncEngine(
    this._webdavService,
    this._databaseService, {
    String? memosBaseUrl,
    String? memosToken,
  })  : _memosBaseUrl = memosBaseUrl,
        _memosToken = memosToken;
  final WebDavService _webdavService;
  final DatabaseService _databaseService;
  final String? _memosBaseUrl;
  final String? _memosToken;

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
    } on Object {
      rethrow;
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

      try {
        final remoteContent = await _webdavService.downloadFile(notesPath);
        final remoteData = jsonDecode(remoteContent) as Map<String, dynamic>;
        if (remoteData['notes'] is List) {
          remoteNotes = (remoteData['notes'] as List<dynamic>)
              .map((json) => Note.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } on Object {
        // 远程文件不存在，首次同步
      }

      // 3. 🚀 增量同步：只处理有变化的笔记
      _syncMessage = '增量合并笔记...';
      final mergedNotes = await _mergeNotesIncremental(
        localNotes,
        remoteNotes,
      );

      // 4. 同步图片资源
      _syncMessage = '同步图片资源...';
      final resourceManifest = await _syncResources(mergedNotes);

      // 5. 上传合并后的笔记（全量，但标记了同步时间）
      _syncMessage = '上传到云端...';
      final backupData = {
        'version': '2.0', // 增量同步版本
        'lastSync': now.toIso8601String(),
        'noteCount': mergedNotes.length,
        'notes': mergedNotes.map((note) => note.toJson()).toList(),
        'resourceManifest':
            resourceManifest.map((record) => record.toJson()).toList(),
      };

      await _webdavService.uploadFile(notesPath, jsonEncode(backupData));

      _status = SyncStatus.success;
      _syncMessage = '同步完成';

      return _stats;
    } on Object catch (e) {
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
  ) async {
    final mergedMap = <String, Note>{};
    var uploaded = 0;
    var downloaded = 0;
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
        final syncedNote = remoteNote.copyWith(lastSyncTime: now);
        mergedMap[remoteNote.id] = syncedNote;
        await _databaseService.saveNote(syncedNote);
        downloaded++;
      }
    }

    _stats = SyncStats(
      uploaded: uploaded,
      downloaded: downloaded,
    );

    return mergedMap.values.toList();
  }

  /// 同步图片资源并返回可恢复的资源清单。
  Future<List<_WebDavResourceRecord>> _syncResources(List<Note> notes) async {
    final config = _webdavService.config;
    if (config == null) {
      return const [];
    }
    if (!config.backupImages) {
      return const [];
    }

    var resourceCount = 0;
    var errorCount = 0;
    final manifest = <String, _WebDavResourceRecord>{};

    for (final note in notes) {
      if (note.resourceList.isEmpty) {
        continue;
      }

      for (final resource in note.resourceList) {
        try {
          final resourcePath = _resourcePathFromResource(resource);
          final filename = resource['filename']?.toString();
          if (resourcePath == null || resourcePath.isEmpty) {
            continue;
          }

          final remoteName = _backupFileNameForResource(resource, resourcePath);
          final remotePath = '${config.fullSyncPath}resources/$remoteName';
          final record = _WebDavResourceRecord(
            originalPath: resourcePath,
            webdavPath: remotePath,
            filename: filename?.isNotEmpty ?? false ? filename! : remoteName,
            source: 'resourceList',
          );

          // 检查 WebDAV 上是否已存在
          if (await _webdavService.exists(remotePath)) {
            manifest[resourcePath] = record;
            continue;
          }

          final bytes = await _readImageBytes(resourcePath);
          if (bytes != null) {
            // 上传到 WebDAV
            await _webdavService.uploadBinaryFile(
              remotePath,
              bytes,
            );
            manifest[resourcePath] = record;
            resourceCount++;
          } else {
            errorCount++;
          }
        } on Object {
          errorCount++;
        }
      }
    }

    for (final note in notes) {
      for (final imagePath in _extractMarkdownImagePaths(note.content)) {
        try {
          final remoteName = _resourceFileName(imagePath);
          final remotePath = '${config.fullSyncPath}resources/$remoteName';
          final record = _WebDavResourceRecord(
            originalPath: imagePath,
            webdavPath: remotePath,
            filename: remoteName,
            source: 'markdown',
          );

          if (await _webdavService.exists(remotePath)) {
            manifest.putIfAbsent(imagePath, () => record);
            continue;
          }

          final bytes = await _readImageBytes(imagePath);
          if (bytes == null) {
            continue;
          }

          await _webdavService.uploadBinaryFile(remotePath, bytes);
          manifest.putIfAbsent(imagePath, () => record);
          resourceCount++;
        } on Object {
          errorCount++;
        }
      }
    }

    // 更新统计
    _stats = _stats.copyWith(
      resourceUploaded: _stats.resourceUploaded + resourceCount,
      errors: _stats.errors + errorCount,
    );

    return manifest.values.where((record) => record.isValid).toList();
  }

  List<String> _extractMarkdownImagePaths(String content) {
    final regex = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
    return regex
        .allMatches(content)
        .map((match) => match.group(1)?.trim() ?? '')
        .where((path) => path.isNotEmpty)
        .toList();
  }

  Future<List<int>?> _readImageBytes(String imagePath) async {
    if (imagePath.startsWith('file://')) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (!await file.exists()) {
        return null;
      }
      return file.readAsBytes();
    }

    if (_isAppRelativeImagePath(imagePath)) {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$imagePath');
      if (!await file.exists()) {
        return null;
      }
      return file.readAsBytes();
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      final response = await _downloadImage(imagePath);
      return response;
    }

    if (_isMemosResourcePath(imagePath)) {
      final fullUrl = _memosResourceUrl(imagePath);
      if (fullUrl == null) {
        return null;
      }
      return _downloadImage(fullUrl, authorized: true);
    }

    return null;
  }

  Future<List<int>?> _downloadImage(
    String url, {
    bool authorized = false,
  }) async {
    final headers = <String, String>{};
    final token = _memosToken;
    if (authorized && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(Uri.parse(url), headers: headers);
    return response.statusCode == 200 ? response.bodyBytes : null;
  }

  bool _isMemosResourcePath(String path) =>
      path.startsWith('/o/r/') ||
      path.startsWith('/file/') ||
      path.startsWith('attachments/') ||
      path.startsWith('/resource/') ||
      path.startsWith('/api/v1/attachments/') ||
      path.startsWith('/api/v1/resource/');

  String? _memosResourceUrl(String path) {
    final baseUrl = _memosBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    if (path.startsWith('attachments/')) {
      return '$baseUrl/file/$path';
    }
    return '$baseUrl$path';
  }

  bool _isAppRelativeImagePath(String path) =>
      path.startsWith('images/') || path.startsWith('webdav_images/');

  String _resourceFileName(String imagePath) {
    final source = imagePath.startsWith('file://')
        ? imagePath.replaceFirst('file://', '')
        : imagePath;
    final uri = Uri.tryParse(source);
    final name = uri?.pathSegments.isNotEmpty ?? false
        ? uri!.pathSegments.last
        : source.split('/').last;
    final safeName = name.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');
    final fallback = safeName.isEmpty
        ? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : safeName;
    final digest = sha1.convert(utf8.encode(imagePath)).toString();
    return _fileNameWithDigest(fallback, digest.substring(0, 10));
  }

  String _backupFileNameForResource(
    Map<String, dynamic> resource,
    String resourcePath,
  ) {
    final filename = resource['filename']?.toString();
    final extension = _extensionFromPath(filename ?? resourcePath);
    final id = resource['id']?.toString() ??
        resource['uid']?.toString() ??
        resource['name']?.toString().split('/').last;
    final base = id != null && id.isNotEmpty
        ? id
        : sha1.convert(utf8.encode(resourcePath)).toString().substring(0, 16);
    return '${_sanitizeFileComponent(base)}.$extension';
  }

  String _fileNameWithDigest(String filename, String digest) {
    final dot = filename.lastIndexOf('.');
    if (dot <= 0 || dot == filename.length - 1) {
      return '${_sanitizeFileComponent(filename)}_$digest';
    }
    final base = filename.substring(0, dot);
    final ext = filename.substring(dot + 1);
    return '${_sanitizeFileComponent(base)}_$digest.${_sanitizeFileComponent(ext)}';
  }

  String _extensionFromPath(String path) {
    final cleanPath = path.split('?').first.split('#').first;
    final name = cleanPath.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return _sanitizeFileComponent(name.substring(dot + 1)).toLowerCase();
    }
    return 'jpg';
  }

  String _sanitizeFileComponent(String value) {
    final safe = value.replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_');
    return safe.isEmpty ? 'image' : safe;
  }

  String? _resourcePathFromResource(Map<String, dynamic> resource) {
    if (_isVideoResource(resource)) {
      return null;
    }

    final externalLink = resource['externalLink']?.toString();
    if (externalLink != null && externalLink.isNotEmpty) {
      return externalLink;
    }

    final name = resource['name']?.toString();
    final filename = resource['filename']?.toString();
    if (name != null &&
        name.startsWith('attachments/') &&
        filename != null &&
        filename.isNotEmpty) {
      return '/file/$name/$filename';
    }

    final uid = resource['uid']?.toString() ?? name?.split('/').last;
    if (uid != null && uid.isNotEmpty) {
      return '/o/r/$uid';
    }

    final id = resource['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return '/o/r/$id';
    }

    return null;
  }

  List<String> _resourcePathCandidates(Map<String, dynamic> resource) {
    final candidates = <String>[];
    void add(String? value) {
      if (value != null && value.isNotEmpty && !candidates.contains(value)) {
        candidates.add(value);
      }
    }

    add(resource['externalLink']?.toString());
    final name = resource['name']?.toString();
    final filename = resource['filename']?.toString();
    if (name != null &&
        name.startsWith('attachments/') &&
        filename != null &&
        filename.isNotEmpty) {
      add('/file/$name/$filename');
      add(name);
    }

    final uid = resource['uid']?.toString() ?? name?.split('/').last;
    if (uid != null && uid.isNotEmpty) {
      add('/o/r/$uid');
    }

    final id = resource['id']?.toString();
    if (id != null && id.isNotEmpty) {
      add('/o/r/$id');
    }

    return candidates;
  }

  bool _isVideoResource(Map<String, dynamic> resource) {
    final type = resource['type']?.toString().toLowerCase();
    final filename = resource['filename']?.toString().toLowerCase();
    if (type != null && type.startsWith('video')) {
      return true;
    }
    if (filename == null) {
      return false;
    }
    return filename.endsWith('.mov') ||
        filename.endsWith('.mp4') ||
        filename.endsWith('.avi') ||
        filename.endsWith('.mkv') ||
        filename.endsWith('.webm') ||
        filename.endsWith('.flv');
  }

  List<_WebDavResourceRecord> _parseResourceManifest(rawManifest) {
    if (rawManifest is! List) {
      return const [];
    }

    return rawManifest
        .whereType<Map>()
        .map(
          (item) => _WebDavResourceRecord.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((record) => record.isValid)
        .toList();
  }

  Future<Map<String, String>> _restoreResources(
    List<_WebDavResourceRecord> manifest, {
    void Function(double progress, String message)? onProgress,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final restoredPathMap = <String, String>{};
    var errorCount = 0;

    for (var i = 0; i < manifest.length; i++) {
      final record = manifest[i];
      try {
        final bytes =
            await _webdavService.downloadBinaryFile(record.webdavPath);
        final localName = _restoredLocalFileName(record, i);
        final localFile = File('${imagesDir.path}/$localName');
        await localFile.writeAsBytes(bytes, flush: true);
        restoredPathMap[record.originalPath] = 'file://${localFile.path}';
      } on Object {
        errorCount++;
      }

      onProgress?.call(
        manifest.isEmpty ? 1 : (i + 1) / manifest.length,
        '恢复图片 ${i + 1}/${manifest.length}',
      );
    }

    if (errorCount > 0) {
      _stats = _stats.copyWith(errors: _stats.errors + errorCount);
    }
    return restoredPathMap;
  }

  String _restoredLocalFileName(_WebDavResourceRecord record, int index) {
    final sourceName =
        record.filename.isNotEmpty ? record.filename : record.webdavPath;
    final ext = _extensionFromPath(sourceName);
    final digest = sha1
        .convert(utf8.encode('${record.originalPath}:${record.webdavPath}'))
        .toString()
        .substring(0, 12);
    final base = _sanitizeFileComponent(
      sourceName.split('/').last.split('.').first,
    );
    return 'webdav_${base}_${digest}_$index.$ext';
  }

  Note _rewriteNoteImagePaths(Note note, Map<String, String> restoredPathMap) {
    var content = note.content;
    restoredPathMap.forEach((originalPath, localPath) {
      content = content.replaceAll(']($originalPath)', ']($localPath)');
    });

    var resourceChanged = false;
    final resourceList = note.resourceList.map((resource) {
      final updated = Map<String, dynamic>.from(resource);
      for (final candidate in _resourcePathCandidates(resource)) {
        final localPath = restoredPathMap[candidate];
        if (localPath == null) {
          continue;
        }
        updated['externalLink'] = localPath;
        resourceChanged = true;
        break;
      }
      return updated;
    }).toList();

    if (content == note.content && !resourceChanged) {
      return note;
    }

    return note.copyWith(
      content: content,
      resourceList: resourceChanged ? resourceList : note.resourceList,
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
    onProgress?.call(0, '准备恢复...');

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
      var resourceManifest = <_WebDavResourceRecord>[];
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
          resourceManifest = _parseResourceManifest(
            remoteData['resourceManifest'],
          );
          onProgress?.call(0.5, '备份数据解析完成，共 ${remoteNotes.length} 条笔记');
        } on Object catch (e) {
          throw Exception('解析备份文件失败: $e');
        }
      } on Object {
        rethrow;
      }

      if (remoteNotes.isEmpty) {
        throw Exception('远程备份为空，已取消恢复，避免覆盖本地数据');
      }

      // 2. 恢复图片资源并重写路径（兼容旧备份：没有 manifest 时跳过）
      if (config.backupImages && resourceManifest.isNotEmpty) {
        _syncMessage = '恢复图片资源...';
        onProgress?.call(0.55, '恢复图片资源...');
        final restoredPathMap = await _restoreResources(
          resourceManifest,
          onProgress: (progress, message) {
            onProgress?.call(0.55 + progress * 0.2, message);
          },
        );
        if (restoredPathMap.isNotEmpty) {
          remoteNotes = remoteNotes
              .map((note) => _rewriteNoteImagePaths(note, restoredPathMap))
              .toList();
        }
      }

      // 3. 覆盖前保存本地应急备份，避免误操作造成不可恢复的数据损失。
      onProgress?.call(0.73, '保存本地应急备份...');
      await _uploadRestoreSafetyBackup();

      // 4. 保存所有远程笔记到本地（覆盖）(75% ~ 100%)
      _syncMessage = '恢复笔记到本地...';
      final totalNotes = remoteNotes.length;
      onProgress?.call(0.75, '写入本地数据库...');
      await _databaseService.replaceAllNotes(remoteNotes);
      onProgress?.call(1, '恢复完成，共 $totalNotes 条笔记');

      _stats = _stats.copyWith(downloaded: remoteNotes.length);

      _status = SyncStatus.success;
      _syncMessage = '恢复完成';
      onProgress?.call(1, '恢复完成');

      return _stats;
    } on Object catch (e) {
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

  Future<void> _uploadRestoreSafetyBackup() async {
    final config = _webdavService.config;
    if (config == null) {
      return;
    }

    final localNotes = await _databaseService.getNotes();
    if (localNotes.isEmpty) {
      return;
    }

    final emergencyPath = '${config.fullSyncPath}emergency/';
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final backupPath = '${emergencyPath}local-before-restore-$timestamp.json';
    final payload = {
      'version': '2.0',
      'type': 'local-before-webdav-restore',
      'createdAt': DateTime.now().toIso8601String(),
      'noteCount': localNotes.length,
      'notes': localNotes.map((note) => note.toJson()).toList(),
    };

    try {
      await _webdavService.createFolder(emergencyPath);
      await _webdavService.uploadFile(backupPath, jsonEncode(payload));
    } on Object {
      throw Exception('恢复前本地应急备份失败，已取消恢复以保护本地数据');
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
    onProgress?.call(0, '准备备份...');

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
      final resourceManifest = await _syncResources(localNotes);
      onProgress?.call(0.6, '图片资源备份完成');

      // 3. 上传笔记数据 (60% ~ 100%)
      _syncMessage = '上传笔记数据...';
      onProgress?.call(0.7, '打包笔记数据...');
      final backupData = {
        'version': '2.0',
        'lastBackup': DateTime.now().toIso8601String(),
        'noteCount': localNotes.length,
        'notes': localNotes.map((note) => note.toJson()).toList(),
        'resourceManifest':
            resourceManifest.map((record) => record.toJson()).toList(),
      };

      onProgress?.call(0.8, '上传备份文件...');
      await _webdavService.uploadFile(notesPath, jsonEncode(backupData));

      _stats = _stats.copyWith(uploaded: _stats.uploaded + localNotes.length);

      _status = SyncStatus.success;
      _syncMessage = '备份完成';
      onProgress?.call(1, '备份完成');

      return _stats;
    } on Object catch (e) {
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
