import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

/// 百度语音识别服务
/// 文档: https://ai.baidu.com/ai-doc/SPEECH/Vk38lxily
class BaiduSpeechService {
  factory BaiduSpeechService() => _instance;
  BaiduSpeechService._internal();
  static final BaiduSpeechService _instance = BaiduSpeechService._internal();

  // 🔑 百度语音识别 API 配置（从 AppConfig 读取）
  static String get _apiKey => AppConfig.baiduSpeechApiKey;
  static String get _secretKey => AppConfig.baiduSpeechSecretKey;
  
  // API 端点
  static const String _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const String _asrUrl = 'https://vop.baidu.com/server_api';
  
  String? _accessToken;
  DateTime? _tokenExpireTime;

  /// 获取 Access Token
  Future<String?> _getAccessToken() async {
    try {
      // 检查 token 是否有效
      if (_accessToken != null && 
          _tokenExpireTime != null && 
          DateTime.now().isBefore(_tokenExpireTime!)) {
        return _accessToken;
      }

      // 请求新的 token
      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'grant_type': 'client_credentials',
          'client_id': _apiKey,
          'client_secret': _secretKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        
        // token 有效期 30 天，提前 1 天刷新
        final expiresIn = data['expires_in'] as int;
        _tokenExpireTime = DateTime.now().add(
          Duration(seconds: expiresIn - 86400),
        );
        
        return _accessToken;
      } else {
        debugPrint('获取百度 Access Token 失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('获取百度 Access Token 异常: $e');
      return null;
    }
  }

  /// 语音识别（录音文件）
  /// 
  /// [audioPath] 音频文件路径，支持 pcm/wav/amr/m4a 格式
  /// [format] 音频格式，默认 wav
  /// [rate] 采样率，支持 8000 或 16000，默认 16000
  Future<String?> recognizeAudioFile({
    required String audioPath,
    String format = 'wav',
    int rate = 16000,
  }) async {
    try {
      // 1. 获取 Access Token
      final token = await _getAccessToken();
      if (token == null) {
        debugPrint('百度语音识别: 获取 token 失败');
        return null;
      }

      // 2. 读取音频文件
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        debugPrint('百度语音识别: 音频文件不存在');
        return null;
      }

      final audioBytes = await audioFile.readAsBytes();
      final audioBase64 = base64Encode(audioBytes);

      // 3. 构建请求参数
      final requestBody = {
        'format': format,
        'rate': rate,
        'channel': 1,
        'cuid': _getDeviceId(),
        'token': token,
        'speech': audioBase64,
        'len': audioBytes.length,
        'dev_pid': 1537, // 1537=普通话(纯中文识别)，1737=英语，1837=粤语
      };

      // 4. 发送识别请求
      final response = await http.post(
        Uri.parse(_asrUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        
        // 检查错误码
        final errNo = result['err_no'];
        if (errNo == 0) {
          // 识别成功
          final resultList = result['result'] as List;
          if (resultList.isNotEmpty) {
            return resultList[0] as String;
          }
        } else {
          debugPrint('百度语音识别错误: $errNo - ${result['err_msg']}');
          return null;
        }
      } else {
        debugPrint('百度语音识别请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('百度语音识别异常: $e');
      return null;
    }
    
    return null;
  }

  /// 实时语音识别（流式）
  /// 注意: 百度实时语音识别需要 WebSocket，这里暂不实现
  /// 如需实时识别，建议使用本地 speech_to_text
  Future<String?> recognizeStream() async {
    // TODO: 实现 WebSocket 流式识别
    throw UnimplementedError('实时识别请使用本地 speech_to_text');
  }

  /// 获取设备唯一标识
  String _getDeviceId() {
    // 使用简单的设备标识
    // 生产环境建议使用 device_info_plus 获取真实设备 ID
    return 'flutter_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 检查 API 配置是否有效
  bool isConfigured() {
    return _apiKey.isNotEmpty && 
           _secretKey.isNotEmpty && 
           AppConfig.enableBaiduSpeech;
  }

  /// 测试 API 连接
  Future<bool> testConnection() async {
    try {
      final token = await _getAccessToken();
      return token != null;
    } catch (e) {
      debugPrint('百度语音 API 连接测试失败: $e');
      return false;
    }
  }
  
  /// 公开获取 Access Token 方法（供实时识别使用）
  Future<String?> getAccessToken() async {
    return _getAccessToken();
  }

  /// 获取使用说明
  static String getSetupInstructions() {
    return '''
百度语音识别配置步骤：

1. 访问百度 AI 开放平台
   https://console.bce.baidu.com/ai/#/ai/speech/overview/index

2. 创建应用
   - 点击"创建应用"
   - 填写应用名称和描述
   - 选择"语音识别"服务

3. 获取 API Key 和 Secret Key
   - 在应用列表中找到你的应用
   - 复制 API Key 和 Secret Key

4. 配置到代码中
   - 打开 lib/services/baidu_speech_service.dart
   - 替换 _apiKey 和 _secretKey

免费额度：
- 每日 50,000 次调用
- 每月 100 万次调用
- 超出后按量计费

注意事项：
- 音频格式支持: pcm, wav, amr, m4a
- 采样率: 8000 或 16000
- 音频时长: 不超过 60 秒
- 文件大小: 不超过 10MB
''';
  }
}
