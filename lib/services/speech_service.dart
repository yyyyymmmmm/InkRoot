import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// 临时禁用 speech_to_text 以兼容 Gradle 8.9
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'baidu_speech_service.dart';
import 'baidu_realtime_speech_service.dart';

/// 语音识别服务
/// 提供本地+云端混合语音转文字功能
///
/// 注意：本地识别功能已临时禁用（speech_to_text 不兼容 Gradle 8.9）
/// 当前仅支持百度云识别
///
/// 策略：
/// 1. 优先使用本地识别（免费，实时）- 已禁用
/// 2. 本地不可用时降级到百度云识别（需配置 API Key）
class SpeechService {
  factory SpeechService() => _instance;
  SpeechService._internal();
  static final SpeechService _instance = SpeechService._internal();

  // 临时禁用本地语音识别
  // late stt.SpeechToText _speech;
  final BaiduSpeechService _baiduSpeech = BaiduSpeechService();
  final BaiduRealtimeSpeechService _baiduRealtime = BaiduRealtimeSpeechService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';
  
  // 用户偏好设置
  static const String _prefKeyUseCloud = 'speech_use_cloud';
  bool _preferCloudRecognition = true; // 默认使用百度云识别

  /// 获取是否正在监听
  bool get isListening => _isListening;

  /// 获取是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取最后识别的文本
  String get lastRecognizedText => _lastRecognizedText;
  
  /// 是否优先使用云端识别
  bool get preferCloudRecognition => _preferCloudRecognition;
  
  /// 百度云识别是否已配置
  bool get isBaiduConfigured => _baiduSpeech.isConfigured();

  /// 初始化语音识别服务
  Future<bool> initialize() async {
    try {
      // 加载用户偏好
      final prefs = await SharedPreferences.getInstance();
      _preferCloudRecognition = prefs.getBool(_prefKeyUseCloud) ?? false;
      
      // 本地语音识别已禁用（speech_to_text 不兼容 Gradle 8.9）
      _isInitialized = false;
      return false;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }
  
  /// 设置是否优先使用云端识别
  Future<void> setPreferCloudRecognition(bool prefer) async {
    _preferCloudRecognition = prefer;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyUseCloud, prefer);
  }

  /// 检查麦克风权限
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// 检查权限（兼容性方法）
  Future<bool> checkPermission() async => checkMicrophonePermission();

  /// 请求麦克风权限
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 请求权限（兼容性方法）
  Future<bool> requestPermission() async => requestMicrophonePermission();

  /// 开始语音识别
  /// 
  /// 本地识别已禁用，始终提示用户本地识别不可用
  Future<bool> startListening({
    Function(String)? onResult,
    Function(String)? onError,
    Function(double)? onSoundLevel,
    Duration? timeout,
    BuildContext? context,
  }) async {
    try {
      // 本地识别已禁用
      debugPrint('SpeechService: 本地识别已禁用（speech_to_text 不兼容 Gradle 8.9）');
      
      if (context != null) {
        _showLocalSpeechFailedDialog(context, onError);
      }
      
      if (onError != null) {
        onError('本地语音识别暂时不可用');
      }
      
      return false;
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
      return false;
    }
  }
  
  /// 识别音频文件（支持云端识别）
  Future<bool> recognizeAudioFile({
    required String audioPath,
    Function(String)? onResult,
    Function(String)? onError,
    BuildContext? context,
  }) async {
    try {
      // 检查百度云识别是否已配置
      if (!_baiduSpeech.isConfigured()) {
        if (context != null) {
          _showBaiduNotConfiguredDialog(context);
        }
        if (onError != null) {
          onError('百度语音识别未配置');
        }
        return false;
      }
      
      // 使用百度云识别
      final result = await _baiduSpeech.recognizeAudioFile(
        audioPath: audioPath,
        format: 'wav',
        rate: 16000,
      );
      
      if (result != null && result.isNotEmpty) {
        _lastRecognizedText = result;
        if (onResult != null) {
          onResult(result);
        }
        return true;
      } else {
        if (onError != null) {
          onError('识别失败，请重试');
        }
        return false;
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
      return false;
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    try {
      _isListening = false;
      
      // 停止百度实时识别
      if (_baiduRealtime.isListening) {
        await _baiduRealtime.stopListening();
      }
      
      // 本地识别已禁用
      // if (_speech.isListening) {
      //   await _speech.cancel();
      //   await Future.delayed(const Duration(milliseconds: 100));
      // }
    } catch (e) {
      debugPrint('停止语音识别失败: $e');
      _isListening = false;
    }
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (_isListening) {
      // await _speech.cancel();
      _isListening = false;
      _lastRecognizedText = '';
    }
  }

  /// 获取支持的语言列表
  Future<List<String>> getSupportedLanguages() async {
    // 本地识别已禁用，返回默认语言
    return ['zh-CN', 'en-US'];
  }

  /// 检查设备是否支持语音识别
  Future<bool> isDeviceSupported() async {
    // 本地识别已禁用
    return false;
  }

  /// 测试语音权限和功能
  Future<Map<String, dynamic>> testSpeechCapabilities() async {
    final result = <String, dynamic>{};

    try {
      result['initialized'] = false;
      result['deviceSupported'] = false;
      result['note'] = '本地语音识别已禁用（speech_to_text 不兼容 Gradle 8.9）';

      // 检查权限状态
      if (Platform.isIOS) {
        final micStatus = await Permission.microphone.status;
        final speechStatus = await Permission.speech.status;
        result['microphonePermission'] = micStatus.toString();
        result['speechPermission'] = speechStatus.toString();
      }

      result['isListening'] = _isListening;
      result['lastText'] = _lastRecognizedText;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      _isListening = false;
      _lastRecognizedText = '';
    } catch (e) {
      debugPrint('释放语音资源失败: $e');
    }
  }

  /// 显示权限被拒绝的对话框
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Text('🎤', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('需要麦克风权限'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('语音识别功能需要麦克风和语音识别权限。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '操作步骤：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. 点击"去设置"按钮\n2. 找到"麦克风"和"语音识别"\n3. 开启权限开关\n4. 返回应用重试',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
  
  /// 显示本地语音识别失败的对话框
  void _showLocalSpeechFailedDialog(
    BuildContext context,
    Function(String)? onError,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('语音识别不可用'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本地语音识别功能暂时不可用（兼容性问题）。'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '原因：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'speech_to_text 插件与当前 Gradle 版本不兼容，\n正在等待官方更新。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_baiduSpeech.isConfigured()) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 建议',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '您可以使用云端语音识别功能（百度语音），识别准确率更高。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
          if (_baiduSpeech.isConfigured())
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 设置优先使用云端识别
                await setPreferCloudRecognition(true);
              },
              child: const Text('使用云端识别'),
            ),
        ],
      ),
    );
  }
  
  /// 显示百度语音未配置的对话框
  void _showBaiduNotConfiguredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Text('🔧', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('云端识别未配置'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('百度语音识别 API 尚未配置。'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  BaiduSpeechService.getSetupInstructions(),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
