import 'package:inkroot/config/app_config.dart';

/// WebDAV 配置模型
///
/// 用于存储和管理 WebDAV 服务器连接配置
class WebDavConfig {
  // 最后同步时间

  const WebDavConfig({
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.syncPath = AppConfig.defaultWebDavPath,
    this.enabled = false,
    this.autoSyncInterval = 15,
    this.autoSync = false,
    this.backupImages = true,
    this.lastSyncTime,
  });

  /// 从 JSON 创建配置
  factory WebDavConfig.fromJson(Map<String, dynamic> json) => WebDavConfig(
        serverUrl: json['serverUrl'] as String? ?? '',
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        syncPath: json['syncPath'] as String? ?? AppConfig.defaultWebDavPath,
        enabled: json['enabled'] as bool? ?? false,
        autoSyncInterval: json['autoSyncInterval'] as int? ?? 15,
        autoSync: json['autoSync'] as bool? ?? false,
        backupImages: json['backupImages'] as bool? ?? true,
        lastSyncTime: json['lastSyncTime'] != null
            ? DateTime.parse(json['lastSyncTime'] as String)
            : null,
      );
  final String serverUrl; // WebDAV 服务器地址
  final String username; // 用户名
  final String password; // 密码
  final String syncPath; // 同步文件夹路径
  final bool enabled; // 是否启用 WebDAV 同步
  final int autoSyncInterval; // 自动同步间隔（分钟）
  final bool autoSync; // 是否自动同步
  final bool backupImages; // 是否备份笔记内图片资源
  final DateTime? lastSyncTime;

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'syncPath': syncPath,
        'enabled': enabled,
        'autoSyncInterval': autoSyncInterval,
        'autoSync': autoSync,
        'backupImages': backupImages,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
      };

  /// 复制并修改
  WebDavConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? syncPath,
    bool? enabled,
    int? autoSyncInterval,
    bool? autoSync,
    bool? backupImages,
    DateTime? lastSyncTime,
  }) =>
      WebDavConfig(
        serverUrl: serverUrl ?? this.serverUrl,
        username: username ?? this.username,
        password: password ?? this.password,
        syncPath: syncPath ?? this.syncPath,
        enabled: enabled ?? this.enabled,
        autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
        autoSync: autoSync ?? this.autoSync,
        backupImages: backupImages ?? this.backupImages,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      );

  /// 验证配置是否有效
  bool get isValid =>
      serverUrl.isNotEmpty &&
      username.isNotEmpty &&
      password.isNotEmpty &&
      syncPath.isNotEmpty;

  bool get usesSecureTransport {
    final uri = Uri.tryParse(serverUrl.trim());
    if (uri == null) {
      return false;
    }
    if (uri.scheme == 'https') {
      return true;
    }
    if (uri.scheme != 'http') {
      return false;
    }
    final host = uri.host.toLowerCase();
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(host);
  }

  /// 获取完整的同步路径（确保以 / 开头和结尾）
  String get fullSyncPath {
    var path = syncPath.trim();
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    return path;
  }

  @override
  String toString() =>
      'WebDavConfig(serverUrl: $serverUrl, username: $username, syncPath: $syncPath, enabled: $enabled)';
}

/// WebDAV 服务器预设配置
class WebDavPresets {
  static const String jianguoyun = 'https://dav.jianguoyun.com/dav/';
  static const String infinicloud = 'https://dav.infini-cloud.net/dav/';
  static const String teracloud = 'https://nanao.teracloud.jp/dav/';
  static const String koofr = 'https://app.koofr.net/dav/Koofr';

  static const Map<String, String> presets = {
    '坚果云': jianguoyun,
    'InfiniCloud': infinicloud,
    'TeraCloud': teracloud,
    'Koofr': koofr,
    '自定义': '',
  };

  static const Map<String, String> presetsEn = {
    'Nutstore': jianguoyun,
    'InfiniCloud': infinicloud,
    'TeraCloud': teracloud,
    'Koofr': koofr,
    'Custom': '',
  };
}
