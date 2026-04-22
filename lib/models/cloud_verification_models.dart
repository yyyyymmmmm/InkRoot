/// 星河云验证 - 应用配置响应
class CloudAppConfigResponse {
  CloudAppConfigResponse({
    required this.code,
    required this.time,
    required this.check,
    this.msg,
  });

  factory CloudAppConfigResponse.fromJson(Map<String, dynamic> json) =>
      CloudAppConfigResponse(
        code: json['code'] ?? 0,
        msg: json['msg'] != null
            ? CloudAppConfigData.fromJson(json['msg'])
            : null,
        time: json['time'] ?? 0,
        check: json['check'] ?? '',
      );
  final int code;
  final CloudAppConfigData? msg;
  final int time;
  final String check;

  bool get isSuccess => code == 200;
}

/// 星河云验证 - 应用配置数据
class CloudAppConfigData {
  CloudAppConfigData({
    required this.version,
    required this.versionInfo,
    required this.appUpdateShow,
    required this.appUpdateUrl,
    required this.appUpdateMust,
  });

  factory CloudAppConfigData.fromJson(Map<String, dynamic> json) =>
      CloudAppConfigData(
        version: json['version'] ?? '',
        versionInfo: json['version_info'] ?? '',
        appUpdateShow: json['app_update_show'] ?? '',
        appUpdateUrl: json['app_update_url'] ?? '',
        appUpdateMust: json['app_update_must'] ?? 'n',
      );
  final String version;
  final String versionInfo;
  final String appUpdateShow;
  final String appUpdateUrl;
  final String appUpdateMust;

  /// 是否强制更新
  bool get isForceUpdate => appUpdateMust.toLowerCase() == 'y';

  /// 获取格式化的版本信息列表
  List<String> get formattedVersionInfo =>
      versionInfo.split('\n').where((line) => line.trim().isNotEmpty).toList();
}

/// 星河云验证 - 应用公告响应
class CloudNoticeResponse {
  CloudNoticeResponse({
    required this.code,
    required this.time,
    required this.check,
    this.msg,
  });

  factory CloudNoticeResponse.fromJson(Map<String, dynamic> json) =>
      CloudNoticeResponse(
        code: json['code'] ?? 0,
        msg: json['msg'] != null ? CloudNoticeData.fromJson(json['msg']) : null,
        time: json['time'] ?? 0,
        check: json['check'] ?? '',
      );
  final int code;
  final CloudNoticeData? msg;
  final int time;
  final String check;

  bool get isSuccess => code == 200;
}

/// 星河云验证 - 应用公告数据
class CloudNoticeData {
  CloudNoticeData({
    required this.appGg,
  });

  factory CloudNoticeData.fromJson(Map<String, dynamic> json) =>
      CloudNoticeData(
        appGg: json['app_gg'] ?? '',
      );
  final String appGg;

  /// 获取格式化的公告内容列表
  List<String> get formattedNotices =>
      appGg.split('\n').where((line) => line.trim().isNotEmpty).toList();
}
