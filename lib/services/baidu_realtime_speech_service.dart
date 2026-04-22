import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../config/app_config.dart';
import 'baidu_speech_service.dart';

/// 百度实时语音识别服务（WebSocket 流式识别）
/// 文档: https://ai.baidu.com/ai-doc/SPEECH/glzh8g8uc
class BaiduRealtimeSpeechService {
  factory BaiduRealtimeSpeechService() => _instance;
  BaiduRealtimeSpeechService._internal();
  static final BaiduRealtimeSpeechService _instance = 
      BaiduRealtimeSpeechService._internal();

  // WebSocket 连接
  WebSocket? _webSocket;
  final AudioRecorder _recorder = AudioRecorder();
  
  // 状态
  bool _isListening = false;
  bool _isConnected = false;
  
  // 回调
  StreamController<String>? _resultController;
  StreamController<double>? _soundLevelController;
  
  // 配置
  static const String _wsUrl = 'wss://vop.baidu.com/realtime_asr';
  static const int _sampleRate = 16000; // 采样率
  static const int _sendIntervalMs = 160; // 发送间隔（毫秒）
  
  /// 获取是否正在监听
  bool get isListening => _isListening;
  
  /// 开始实时语音识别
  /// 
  /// [onResult] 实时识别结果回调
  /// [onError] 错误回调
  /// [onSoundLevel] 音量回调（0.0 - 1.0）
  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onError,
    Function(double)? onSoundLevel,
  }) async {
    try {
      if (_isListening) {
        debugPrint('百度实时识别: 已在监听中');
        return false;
      }
      
      // 1. 获取 Access Token
      final baiduSpeech = BaiduSpeechService();
      final token = await baiduSpeech.getAccessToken();
      if (token == null) {
        debugPrint('百度实时识别: 获取 token 失败');
        onError?.call('获取访问令牌失败');
        return false;
      }
      
      // 2. 创建结果流
      _resultController = StreamController<String>.broadcast();
      _soundLevelController = StreamController<double>.broadcast();
      
      // 监听结果
      _resultController!.stream.listen(onResult);
      if (onSoundLevel != null) {
        _soundLevelController!.stream.listen(onSoundLevel);
      }
      
      // 3. 连接 WebSocket
      final wsUrlWithToken = '$_wsUrl?sn=${DateTime.now().millisecondsSinceEpoch}'
          '&dev_pid=1537' // 1537=普通话
          '&cuid=${_getDeviceId()}'
          '&token=$token';
      
      debugPrint('百度实时识别: 连接 WebSocket...');
      _webSocket = await WebSocket.connect(wsUrlWithToken);
      _isConnected = true;
      debugPrint('百度实时识别: WebSocket 已连接');
      
      // 4. 监听 WebSocket 消息
      _webSocket!.listen(
        _handleWebSocketMessage,
        onError: (error) {
          debugPrint('百度实时识别: WebSocket 错误: $error');
          onError?.call(error.toString());
          stopListening();
        },
        onDone: () {
          debugPrint('百度实时识别: WebSocket 连接关闭');
          _isConnected = false;
        },
      );
      
      // 5. 开始录音并获取音频流
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('百度实时识别: 没有麦克风权限');
        onError?.call('没有麦克风权限');
        await stopListening();
        return false;
      }
      
      debugPrint('百度实时识别: 开始录音...');
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );
      
      // 6. 监听音频流并发送到 WebSocket
      _isListening = true;
      stream.listen(
        (audioData) {
          if (_isConnected && _webSocket != null) {
            // 发送音频数据到 WebSocket
            _webSocket!.add(audioData);
            
            // 计算音量（简化版）
            final level = _calculateSoundLevel(audioData);
            _soundLevelController?.add(level);
          }
        },
        onError: (error) {
          debugPrint('百度实时识别: 音频流错误: $error');
          onError?.call(error.toString());
        },
        onDone: () {
          debugPrint('百度实时识别: 音频流结束');
        },
      );
      
      debugPrint('百度实时识别: 开始监听');
      return true;
    } catch (e) {
      debugPrint('百度实时识别: 启动失败: $e');
      onError?.call(e.toString());
      await stopListening();
      return false;
    }
  }
  
  /// 停止实时语音识别
  Future<void> stopListening() async {
    try {
      _isListening = false;
      
      // 停止录音
      if (await _recorder.isRecording()) {
        await _recorder.stop();
        debugPrint('百度实时识别: 录音已停止');
      }
      
      // 发送结束标记
      if (_isConnected && _webSocket != null) {
        _webSocket!.add(json.encode({'type': 'finish'}));
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // 关闭 WebSocket
      await _webSocket?.close();
      _webSocket = null;
      _isConnected = false;
      
      // 关闭流
      await _resultController?.close();
      await _soundLevelController?.close();
      _resultController = null;
      _soundLevelController = null;
      
      debugPrint('百度实时识别: 已停止');
    } catch (e) {
      debugPrint('百度实时识别: 停止失败: $e');
    }
  }
  
  /// 计算音量级别（0.0 - 1.0）
  double _calculateSoundLevel(Uint8List audioData) {
    if (audioData.isEmpty) return 0.0;
    
    // 计算 RMS (Root Mean Square)
    double sum = 0;
    for (int i = 0; i < audioData.length; i += 2) {
      if (i + 1 < audioData.length) {
        // 将两个字节转换为 16 位整数
        final sample = (audioData[i + 1] << 8) | audioData[i];
        sum += sample * sample;
      }
    }
    
    final rms = sqrt(sum / (audioData.length / 2));
    // 归一化到 0.0 - 1.0
    final normalized = (rms / 32768.0).clamp(0.0, 1.0);
    
    return normalized;
  }
  
  /// 处理 WebSocket 消息
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      
      // 检查错误
      if (data['err_no'] != null && data['err_no'] != 0) {
        debugPrint('百度实时识别: 错误 ${data['err_no']}: ${data['err_msg']}');
        return;
      }
      
      // 获取识别结果
      if (data['result'] != null) {
        final result = data['result'] as String;
        if (result.isNotEmpty) {
          debugPrint('百度实时识别: $result');
          _resultController?.add(result);
        }
      }
    } catch (e) {
      debugPrint('百度实时识别: 解析消息失败: $e');
    }
  }
  
  /// 获取设备ID
  String _getDeviceId() {
    return 'flutter_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// 释放资源
  Future<void> dispose() async {
    await stopListening();
    await _recorder.dispose();
  }
}
