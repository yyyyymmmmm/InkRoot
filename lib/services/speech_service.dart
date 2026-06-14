import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/services/baidu_realtime_speech_service.dart';
import 'package:inkroot/services/baidu_speech_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 语音识别服务
/// 提供本地+云端混合语音转文字功能
///
/// 策略：
/// 1. 优先使用本地识别（免费，实时）
/// 2. 本地不可用时降级到百度云识别（需配置 API Key）
class SpeechService {
  factory SpeechService() => _instance;
  SpeechService._internal();
  static final SpeechService _instance = SpeechService._internal();

  late stt.SpeechToText _speech;
  final BaiduSpeechService _baiduSpeech = BaiduSpeechService();
  final BaiduRealtimeSpeechService _baiduRealtime =
      BaiduRealtimeSpeechService();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';

  // 用户偏好设置
  static const String _prefKeyUseCloud = 'speech_use_cloud';
  bool _preferCloudRecognition = false; // 商业化上架默认仅本地识别

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

      // 初始化本地语音识别
      _speech = stt.SpeechToText();
      _isInitialized = await _speech.initialize(
        onError: (error) {},
        onStatus: (status) {
          _isListening = status == 'listening';
        },
      );

      return _isInitialized;
    } on Object {
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
  /// 使用本地 speech_to_text 实时识别
  Future<bool> startListening({
    Function(String)? onResult,
    Function(String)? onError,
    Function(double)? onSoundLevel, // 🎤 音量变化回调
    Duration? timeout,
    BuildContext? context,
  }) async {
    try {
      // 🎯 使用本地识别（已优化，体验很好）
      debugPrint('SpeechService: 使用本地实时识别');
      // iOS: speech_to_text的initialize()方法会自动触发权限请求
      // 所以不需要提前请求权限，直接初始化即可
      if (!_isInitialized) {
        // 在iOS上，这个调用会触发麦克风和语音识别权限请求
        final success = await initialize();

        if (!success) {
          // 如果初始化失败，提示用户
          if (context != null && context.mounted) {
            _showLocalSpeechFailedDialog(context, onError);
          }
          return false;
        }
      }

      if (!_isInitialized) {
        // 本地识别不可用，提示用户
        if (context != null && context.mounted) {
          _showLocalSpeechFailedDialog(context, onError);
        }
        return false;
      }

      // 检查权限状态
      final available = await _speech.hasPermission;
      if (!available) {
        if (context != null && context.mounted) {
          _showPermissionDeniedDialog(context);
        }
        return false;
      }

      await _speech.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          // 🎯 实时回调：不仅在 finalResult 时回调，中间结果也回调
          if (onResult != null) {
            onResult(_lastRecognizedText);
          }
        },
        // 🎤 监听音量变化，用于动画效果
        onSoundLevelChange: (level) {
          // 🎯 只在有声音时回调（过滤静音）
          if (onSoundLevel != null && level > 0.1) {
            onSoundLevel(level);
          } else if (onSoundLevel != null) {
            onSoundLevel(0); // 静音时返回 0
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: timeout ?? const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'zh_CN',
          cancelOnError: true,
        ),
      );

      _isListening = true;
      return true;
    } on Object catch (e) {
      if (onError != null) {
        onError(e.toString());
      }

      // 本地识别失败，提示用户
      if (context != null && context.mounted) {
        _showLocalSpeechFailedDialog(context, onError);
      }
      return false;
    }
  }

  /// 识别音频文件（支持云端识别）
  ///
  /// [audioPath] 音频文件路径
  /// [onResult] 识别成功回调
  /// [onError] 识别失败回调
  /// [context] 用于显示对话框
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
    } on Object catch (e) {
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

      // 停止本地识别
      if (_speech.isListening) {
        await _speech.stop();

        // 等待系统完全释放麦克风权限
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } on Object catch (e) {
      debugPrint('停止语音识别失败: $e');
      _isListening = false;
    }
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      _lastRecognizedText = '';
    }
  }

  /// 获取支持的语言列表
  Future<List<String>> getSupportedLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized) {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    }
    return ['zh-CN', 'en-US'];
  }

  /// 检查设备是否支持语音识别
  Future<bool> isDeviceSupported() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  /// 测试语音权限和功能
  Future<Map<String, dynamic>> testSpeechCapabilities() async {
    final result = <String, dynamic>{};

    try {
      // 1. 检查初始化状态
      if (!_isInitialized) {
        await initialize();
      }
      result['initialized'] = _isInitialized;

      // 2. 检查设备支持
      final deviceSupported = await _speech.hasPermission;
      result['deviceSupported'] = deviceSupported;

      // 3. 检查权限状态
      if (Platform.isIOS) {
        final micStatus = await Permission.microphone.status;
        final speechStatus = await Permission.speech.status;
        result['microphonePermission'] = micStatus.toString();
        result['speechPermission'] = speechStatus.toString();
      }

      // 4. 获取可用语言
      final locales = await _speech.locales();
      result['availableLocales'] = locales.map((l) => l.localeId).toList();
      result['hasChineseSupport'] =
          locales.any((l) => l.localeId.startsWith('zh'));

      // 5. 检查当前状态
      result['isListening'] = _isListening;
      result['lastText'] = _lastRecognizedText;
    } on Object catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      if (_isListening || _speech.isListening) {
        // 🔥 确保完全释放麦克风资源
        await _speech.cancel();
      }
      _isListening = false;
      _lastRecognizedText = '';
    } on Object catch (e) {
      debugPrint('Failed to release speech resources: $e');
    }
  }

  /// 显示权限被拒绝的对话框
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            const Text('🎤', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              AppLocalizationsSimple.of(context)
                      ?.speechPermissionRequiredTitle ??
                  '需要麦克风权限',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizationsSimple.of(context)
                      ?.speechPermissionRequiredMessage ??
                  '语音识别功能需要麦克风和语音识别权限。',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizationsSimple.of(context)?.permissionStepTitle ??
                        '操作步骤：',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizationsSimple.of(context)?.permissionStepSpeech ??
                        '1. 点击"去设置"按钮\n2. 找到"麦克风"和"语音识别"\n3. 开启权限开关\n4. 返回应用重试',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child:
                Text(AppLocalizationsSimple.of(context)?.goToSettings ?? '去设置'),
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
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              AppLocalizationsSimple.of(context)
                      ?.speechRecognitionUnavailable ??
                  '语音识别不可用',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizationsSimple.of(context)?.localSpeechUnavailable ??
                  '本地语音识别功能暂时不可用。',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizationsSimple.of(context)?.possibleReasons ??
                        '可能的原因：',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizationsSimple.of(context)
                            ?.speechUnavailableReasons ??
                        '• Android: 缺少 Google 服务\n'
                            '• iOS: 系统版本过低\n'
                            '• 网络连接问题',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_baiduSpeech.isConfigured()) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizationsSimple.of(context)?.suggestion ?? '💡 建议',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizationsSimple.of(context)
                              ?.cloudSpeechSuggestion ??
                          '您可以使用云端语音识别功能（百度语音），识别准确率更高。',
                      style: const TextStyle(fontSize: 12),
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
            child: Text(AppLocalizationsSimple.of(context)?.iKnow ?? '知道了'),
          ),
          if (_baiduSpeech.isConfigured())
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 设置优先使用云端识别
                await setPreferCloudRecognition(true);
              },
              child: Text(
                AppLocalizationsSimple.of(context)?.useCloudRecognition ??
                    '使用云端识别',
              ),
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
        title: Row(
          children: [
            const Text('🔧', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              AppLocalizationsSimple.of(context)
                      ?.cloudRecognitionNotConfigured ??
                  '云端识别未配置',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.baiduSpeechNotConfigured ??
                    '百度语音识别 API 尚未配置。',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
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
            child: Text(AppLocalizationsSimple.of(context)?.iKnow ?? '知道了'),
          ),
        ],
      ),
    );
  }
}
