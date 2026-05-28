import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/user_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:provider/provider.dart';

/// 统一的缓存头像组件
///
/// 特性：
/// - 智能缓存：内存+磁盘双重缓存
/// - 渐进式加载：占位符 → 加载中 → 真实头像
/// - 多格式支持：网络URL、Base64、相对路径
/// - 错误处理：自动回退到默认头像
/// - 性能优化：避免重复网络请求
class CachedAvatar extends StatelessWidget {
  // 可选的认证token

  const CachedAvatar({
    super.key,
    this.avatarUrl,
    this.fallbackText,
    this.size = 40,
    this.isCircle = true,
    this.backgroundColor,
    this.textColor,
    this.authToken,
  });

  /// 从User对象创建头像
  factory CachedAvatar.fromUser(
    User? user, {
    double size = 40,
    bool isCircle = true,
  }) =>
      CachedAvatar(
        avatarUrl: user?.avatarUrl,
        fallbackText: user?.username.isNotEmpty ?? false
            ? user!.username[0].toUpperCase()
            : user?.nickname?.isNotEmpty ?? false
                ? user!.nickname![0].toUpperCase()
                : 'U',
        size: size,
        isCircle: isCircle,
      );
  final String? avatarUrl;
  final String? fallbackText; // 默认头像显示的文字
  final double size;
  final bool isCircle;
  final Color? backgroundColor;
  final Color? textColor;
  final String? authToken;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = backgroundColor ??
        (isDarkMode
            ? AppTheme.darkCardColor
            : AppTheme.primaryColor.withOpacity(0.1));
    final defaultTextColor = textColor ??
        (isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.primaryColor);

    // 如果没有头像URL，直接显示默认头像
    if (avatarUrl == null || avatarUrl!.trim().isEmpty) {
      return _buildDefaultAvatar(defaultBgColor, defaultTextColor);
    }

    final cleanUrl = avatarUrl!.trim();

    // 处理Base64格式头像
    if (cleanUrl.startsWith('data:image')) {
      return _buildBase64Avatar(cleanUrl, defaultBgColor, defaultTextColor);
    }

    // 处理网络头像
    if (cleanUrl.startsWith('http://') ||
        cleanUrl.startsWith('https://') ||
        cleanUrl.startsWith('/')) {
      return _buildNetworkAvatar(
        context,
        cleanUrl,
        defaultBgColor,
        defaultTextColor,
      );
    }

    // 其他情况显示默认头像
    return _buildDefaultAvatar(defaultBgColor, defaultTextColor);
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar(Color bgColor, Color textColor) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(size * 0.2),
        ),
        child: Center(
          child: Text(
            fallbackText ?? 'U',
            style: TextStyle(
              color: textColor,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  /// 构建Base64头像
  Widget _buildBase64Avatar(String base64Url, Color bgColor, Color textColor) {
    try {
      final dataStart = base64Url.indexOf('base64,') + 'base64,'.length;
      final base64Data = base64Url.substring(dataStart);
      final decodedBytes = base64Decode(base64Data);

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(size * 0.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          decodedBytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildDefaultAvatar(bgColor, textColor),
        ),
      );
    } catch (e) {
      return _buildDefaultAvatar(bgColor, textColor);
    }
  }

  /// 构建网络头像（核心优化部分）
  Widget _buildNetworkAvatar(
    BuildContext context,
    String url,
    Color bgColor,
    Color textColor,
  ) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 处理相对路径
    final fullUrl =
        url.startsWith('/') ? '${appProvider.appConfig.memosApiUrl}$url' : url;

    // 创建自定义缓存管理器，支持认证
    final cacheManager = _getCustomCacheManager(appProvider);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        cacheManager: cacheManager,
        width: size,
        height: size,
        fit: BoxFit.cover,

        // 占位符：加载时显示
        placeholder: (context, url) => ColoredBox(
          color: bgColor,
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
                backgroundColor: textColor.withOpacity(0.1),
              ),
            ),
          ),
        ),

        // 错误处理：加载失败时显示默认头像
        errorWidget: (context, url, error) =>
            _buildDefaultAvatar(bgColor, textColor),

        // 渐变效果
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),

        // 缓存配置
        memCacheWidth: (size * 2).round(), // 内存缓存尺寸优化
        memCacheHeight: (size * 2).round(),
      ),
    );
  }

  /// 获取自定义缓存管理器
  CacheManager _getCustomCacheManager(AppProvider appProvider) => CacheManager(
        Config(
          'avatar_cache',
          stalePeriod: const Duration(days: 7), // 缓存有效期7天
          maxNrOfCacheObjects: 100, // 最多缓存100个头像
          repo: JsonCacheInfoRepository(databaseName: 'avatar_cache'),
          fileSystem: IOFileSystem('avatar_cache'),
          fileService: HttpFileService(
            httpClient: _CustomHttpClient(appProvider),
          ),
        ),
      );
}

/// 自定义HTTP客户端，支持认证
class _CustomHttpClient extends http.BaseClient {
  _CustomHttpClient(this._appProvider);
  final AppProvider _appProvider;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 添加认证头（如果需要）
    if (_appProvider.user?.token != null) {
      request.headers['Authorization'] = 'Bearer ${_appProvider.user!.token}';
    }

    // 移除no-cache，允许缓存
    request.headers.remove('Cache-Control');

    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

/// 头像预加载工具类
class AvatarPreloader {
  static final Map<String, bool> _preloadedUrls = {};

  /// 预加载用户头像
  static Future<void> preloadUserAvatar(BuildContext context, User user) async {
    if (user.avatarUrl == null || user.avatarUrl!.trim().isEmpty) return;

    final url = user.avatarUrl!.trim();
    if (_preloadedUrls[url] ?? false) return;

    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/')) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final fullUrl = url.startsWith('/')
          ? '${appProvider.appConfig.memosApiUrl}$url'
          : url;

      try {
        await precacheImage(CachedNetworkImageProvider(fullUrl), context);
        _preloadedUrls[url] = true;
      } catch (e) {
        // 预加载失败不影响正常使用
        debugPrint('头像预加载失败: $e');
      }
    }
  }

  /// 清除预加载缓存
  static void clearPreloadCache() {
    _preloadedUrls.clear();
  }
}
