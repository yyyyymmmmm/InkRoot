import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class IflytekSpeechService {
  IflytekSpeechService(this.config);

  static const String _host = 'iat-api.xfyun.cn';
  static const String _path = '/v2/iat';
  static const String _baseUrl = 'wss://$_host$_path';

  final AppConfig config;
  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<List<int>>? _audioSubscription;
  StreamSubscription<dynamic>? _socketSubscription;
  bool _isListening = false;
  String _lastText = '';

  bool get isListening => _isListening;
  String get lastText => _lastText;

  bool get isConfigured =>
      config.iflytekSpeechEnabled &&
      config.speechRecognitionMode == AppConfig.SPEECH_MODE_IFLYTEK &&
      (config.iflytekAppId?.trim().isNotEmpty ?? false) &&
      (config.iflytekApiKey?.trim().isNotEmpty ?? false) &&
      (config.iflytekApiSecret?.trim().isNotEmpty ?? false);

  Future<bool> startListening({
    required ValueChanged<String> onResult,
    ValueChanged<String>? onError,
    ValueChanged<double>? onSoundLevel,
  }) async {
    if (_isListening) {
      return false;
    }
    if (!isConfigured) {
      onError?.call('讯飞语音识别未配置完整');
      return false;
    }

    try {
      if (!await _recorder.hasPermission()) {
        onError?.call('没有麦克风权限');
        return false;
      }

      _lastText = '';
      _channel = IOWebSocketChannel.connect(_authenticatedUrl());
      _socketSubscription = _channel!.stream.listen(
        (message) => _handleMessage(message, onResult, onError),
        onError: (Object error) {
          onError?.call(error.toString());
          unawaited(stopListening());
        },
        onDone: () {
          _isListening = false;
        },
      );

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      var isFirstFrame = true;
      _isListening = true;
      _audioSubscription = stream.listen(
        (audioData) {
          if (!_isListening || _channel == null) {
            return;
          }
          final frame = <String, dynamic>{
            'data': {
              'status': isFirstFrame ? 0 : 1,
              'format': 'audio/L16;rate=16000',
              'encoding': 'raw',
              'audio': base64Encode(audioData),
            },
          };
          if (isFirstFrame) {
            frame['common'] = {'app_id': config.iflytekAppId};
            frame['business'] = {
              'language': 'zh_cn',
              'domain': 'iat',
              'accent': 'mandarin',
              'vad_eos': 3000,
              'dwa': 'wpgs',
            };
          }
          _channel!.sink.add(jsonEncode(frame));
          isFirstFrame = false;
          onSoundLevel?.call(_soundLevel(audioData));
        },
        onError: (Object error) {
          onError?.call(error.toString());
        },
      );
      return true;
    } on Object catch (e) {
      onError?.call(e.toString());
      await stopListening();
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening && _channel == null) {
      return;
    }
    _isListening = false;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      _channel?.sink.add(
        jsonEncode({
          'data': {
            'status': 2,
            'format': 'audio/L16;rate=16000',
            'encoding': 'raw',
            'audio': '',
          },
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _socketSubscription?.cancel();
      _socketSubscription = null;
      await _channel?.sink.close();
      _channel = null;
    } on Object catch (e) {
      debugPrint('讯飞语音识别停止失败: $e');
    }
  }

  Future<bool> testConnection() async {
    if (!isConfigured) {
      return false;
    }
    WebSocketChannel? channel;
    try {
      channel = IOWebSocketChannel.connect(_authenticatedUrl());
      await channel.ready.timeout(const Duration(seconds: 8));
      await channel.sink.close();
      return true;
    } on Object catch (e) {
      debugPrint('讯飞语音识别连接测试失败: $e');
      await channel?.sink.close();
      return false;
    }
  }

  Uri _authenticatedUrl() {
    final date = HttpDate.format(DateTime.now().toUtc());
    final signatureOrigin = 'host: $_host\ndate: $date\nGET $_path HTTP/1.1';
    final hmacSha256 = Hmac(
      sha256,
      utf8.encode(config.iflytekApiSecret!.trim()),
    );
    final signature = base64Encode(
      hmacSha256.convert(utf8.encode(signatureOrigin)).bytes,
    );
    final authorizationOrigin =
        'api_key="${config.iflytekApiKey!.trim()}", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';

    return Uri.parse(_baseUrl).replace(
      queryParameters: {
        'authorization': base64Encode(utf8.encode(authorizationOrigin)),
        'date': date,
        'host': _host,
      },
    );
  }

  void _handleMessage(
    Object? message,
    ValueChanged<String> onResult,
    ValueChanged<String>? onError,
  ) {
    if (message is! String) {
      return;
    }
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final code = data['code'] as int? ?? 0;
      if (code != 0) {
        onError?.call(data['message']?.toString() ?? '讯飞语音识别失败');
        unawaited(stopListening());
        return;
      }

      final text = _parseText(data);
      if (text.isNotEmpty) {
        _lastText = text;
        onResult(_lastText);
      }

      final status = (data['data'] as Map?)?['status'];
      if (status == 2) {
        unawaited(stopListening());
      }
    } on Object catch (e) {
      onError?.call('讯飞语音结果解析失败: $e');
    }
  }

  String _parseText(Map<String, dynamic> data) {
    final result = data['data'];
    if (result is! Map) {
      return '';
    }
    final inner = result['result'];
    if (inner is! Map) {
      return '';
    }
    final words = inner['ws'];
    if (words is! List) {
      return '';
    }

    final buffer = StringBuffer();
    for (final wordGroup in words) {
      if (wordGroup is! Map) {
        continue;
      }
      final candidates = wordGroup['cw'];
      if (candidates is! List || candidates.isEmpty) {
        continue;
      }
      final first = candidates.first;
      if (first is Map) {
        buffer.write(first['w']?.toString() ?? '');
      }
    }
    return buffer.toString().trim();
  }

  double _soundLevel(List<int> audioData) {
    if (audioData.isEmpty) {
      return 0;
    }
    var sum = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < audioData.length; i += 2) {
      final sample = audioData[i] | (audioData[i + 1] << 8);
      final signed = sample > 32767 ? sample - 65536 : sample;
      sum += signed * signed;
      count += 1;
    }
    if (count == 0) {
      return 0;
    }
    return (sum / count / (32768 * 32768)).clamp(0, 1).toDouble();
  }

  Future<void> dispose() async {
    await stopListening();
    await _recorder.dispose();
  }
}
