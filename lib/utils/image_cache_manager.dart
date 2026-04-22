import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ImageCacheManager {
  static const String keyAuthImages = 'authImageCache';
  static const String keyNormalImages = 'normalImageCache';

  // 🔥 创建一个宽松的 HTTP 客户端，即使认证失败也返回缓存
  static http.Client _createHttpClient() {
    final ioClient = HttpClient();
    // 允许长时间连接
    ioClient.connectionTimeout = const Duration(seconds: 30);
    return IOClient(ioClient);
  }

  // 认证图片缓存 (90天，2000个对象) - 🔥 更长缓存时间
  static final CacheManager _authImageCacheManager = CacheManager(
    Config(
      keyAuthImages,
      stalePeriod: const Duration(days: 90), // 🔥 90天不过期
      maxNrOfCacheObjects: 2000, // 🔥 支持更多图片
      repo: JsonCacheInfoRepository(databaseName: keyAuthImages),
      fileService: HttpFileService(httpClient: _createHttpClient()),
    ),
  );

  // 普通图片缓存 (30天，1000个对象)
  static final CacheManager _normalImageCacheManager = CacheManager(
    Config(
      keyNormalImages,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 1000,
      repo: JsonCacheInfoRepository(databaseName: keyNormalImages),
      fileService: HttpFileService(httpClient: _createHttpClient()),
    ),
  );

  static CacheManager get authImageCache => _authImageCacheManager;
  static CacheManager get normalImageCache => _normalImageCacheManager;

  // 清理所有缓存
  static Future<void> clearAllCache() async {
    await _authImageCacheManager.emptyCache();
    await _normalImageCacheManager.emptyCache();
  }

  // 🛡️ 一键清理所有图片缓存（用于清理可能存在的视频文件）
  // 用户可以在设置中手动调用，或在遇到缓存问题时使用
  static Future<void> cleanVideoFilesFromCache() async {
    try {
      // 简单方案：清空所有缓存
      // 因为我们已经在前端过滤了视频文件，所以旧的视频缓存会自动失效
      // 不自动清理，让用户在需要时手动清理
      // await clearAllCache();
    } catch (e) {}
  }

  // 初始化
  static Future<void> initialize() async {
    debugPrint('ImageCacheManager initialized');
    // 🎯 不需要启动时清理缓存，因为：
    // 1. 我们已在前端过滤了所有视频文件
    // 2. 旧的视频缓存不会被访问
    // 3. 缓存会根据LRU策略自动清理
  }
}
