import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:inkroot/models/webdav_config.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// WebDAV 客户端服务
///
/// 提供与 WebDAV 服务器通信的基础功能
class WebDavService {
  webdav.Client? _client;
  WebDavConfig? _config;

  /// 初始化客户端
  Future<void> initialize(WebDavConfig config) async {
    if (!config.isValid) {
      throw Exception('WebDAV 配置无效');
    }

    _config = config;
    _client = webdav.newClient(
      config.serverUrl,
      user: config.username,
      password: config.password,
    );

    // 设置超时
    _client!.setConnectTimeout(30000);
    _client!.setSendTimeout(30000);
    _client!.setReceiveTimeout(30000);
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }
      final config = _config;
      if (config == null) {
        throw Exception('WebDAV 配置缺失');
      }

      // 尝试列出根目录
      await _client!.readDir('/');
      final probePath =
          '${config.fullSyncPath}.inkroot-connection-${DateTime.now().millisecondsSinceEpoch}.txt';
      await uploadFile(probePath, 'InkRoot WebDAV connection test');
      try {
        await deleteFile(probePath);
      } on Object {
        // 删除探测文件是清理动作；连接测试只要求目录可写。
      }

      return true;
    } on Object {
      return false;
    }
  }

  /// 创建文件夹
  Future<void> createFolder(String path) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      await _ensureDirectoryExists(path);
    } on Object catch (e) {
      // 如果文件夹已存在，不抛出异常
      if (!e.toString().contains('405') &&
          !e.toString().contains('already exists')) {
        rethrow;
      }
    }
  }

  /// 检查文件/文件夹是否存在
  Future<bool> exists(String path) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      // 🔧 大厂标准：使用 ping 方法检查文件是否存在（适用于文件和目录）
      // ping 方法会发送 HEAD 请求，比 readDir 更轻量且适用于文件
      await _client!.ping();

      // 尝试获取文件/目录的属性信息
      try {
        // 如果是目录（以 / 结尾），使用 readDir
        if (path.endsWith('/')) {
          await _client!.readDir(path);
        } else {
          // 如果是文件，尝试读取文件列表中是否包含该文件
          final parentPath = path.substring(0, path.lastIndexOf('/') + 1);
          final fileName = path.substring(path.lastIndexOf('/') + 1);
          final files = await _client!.readDir(parentPath);

          // 检查文件是否在列表中
          return files.any((file) => file.name == fileName);
        }
        return true;
      } on Object {
        return false;
      }
    } on Object {
      return false;
    }
  }

  /// 递归创建文件夹路径
  Future<void> _ensureDirectoryExists(String path) async {
    if (path.isEmpty || path == '/') {
      return;
    }

    // 移除末尾的斜杠
    final cleanPath =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;

    // 检查路径是否已存在
    if (await exists('$cleanPath/')) {
      return;
    }

    // 分割路径
    final parts = cleanPath.split('/').where((p) => p.isNotEmpty).toList();
    var currentPath = '/';

    // 递归创建每一级目录
    for (final part in parts) {
      currentPath += '$part/';
      try {
        // 检查目录是否存在
        if (!await exists(currentPath)) {
          await _client!.mkdir(currentPath);
        }
      } on Object catch (e) {
        // 如果是405错误（目录已存在），忽略
        if (e.toString().contains('405') ||
            e.toString().contains('already exists')) {
        } else {
          rethrow;
        }
      }
    }
  }

  /// 上传文件（文本）
  Future<void> uploadFile(String remotePath, String content) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      final bytes = utf8.encode(content);

      // 自动创建所有必需的父目录
      final parentDir = remotePath.substring(0, remotePath.lastIndexOf('/'));
      if (parentDir.isNotEmpty && parentDir != '/') {
        await _ensureDirectoryExists('$parentDir/');
      }

      await _client!.write(remotePath, bytes);
    } on Object {
      rethrow;
    }
  }

  /// 上传二进制文件（图片等）
  Future<void> uploadBinaryFile(String remotePath, List<int> bytes) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      // 自动创建所有必需的父目录
      final parentDir = remotePath.substring(0, remotePath.lastIndexOf('/'));
      if (parentDir.isNotEmpty && parentDir != '/') {
        await _ensureDirectoryExists('$parentDir/');
      }

      // 转换为 Uint8List
      final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      await _client!.write(remotePath, uint8List);
    } on Object {
      rethrow;
    }
  }

  /// 下载文件（文本）
  Future<String> downloadFile(String remotePath) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      final bytes = await _client!.read(remotePath);
      final content = utf8.decode(bytes);

      return content;
    } on Object {
      rethrow;
    }
  }

  /// 下载二进制文件（图片等）
  Future<List<int>> downloadBinaryFile(String remotePath) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      final bytes = await _client!.read(remotePath);

      return bytes;
    } on Object {
      rethrow;
    }
  }

  /// 删除文件
  Future<void> deleteFile(String remotePath) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      await _client!.remove(remotePath);
    } on Object {
      rethrow;
    }
  }

  /// 列出文件夹内容
  Future<List<webdav.File>> listFiles(String path) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      final list = await _client!.readDir(path);

      return list;
    } on Object {
      rethrow;
    }
  }

  /// 获取文件信息
  Future<webdav.File?> getFileInfo(String path) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      final list = await _client!.readDir(path);
      if (list.isNotEmpty) {
        return list.first;
      }
      return null;
    } on Object {
      return null;
    }
  }

  /// 移动/重命名文件
  Future<void> moveFile(String fromPath, String toPath) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      await _client!.copy(fromPath, toPath, true);
      await _client!.remove(fromPath);
    } on Object {
      rethrow;
    }
  }

  /// 复制文件
  Future<void> copyFile(
    String fromPath,
    String toPath, {
    bool overwrite = false,
  }) async {
    try {
      if (_client == null) {
        throw Exception('客户端未初始化');
      }

      await _client!.copy(fromPath, toPath, overwrite);
    } on Object {
      rethrow;
    }
  }

  /// 获取当前配置
  WebDavConfig? get config => _config;

  /// 释放资源
  void dispose() {
    _client = null;
    _config = null;
  }
}
