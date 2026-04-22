import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inkroot/config/app_config.dart' as Config;
import 'package:inkroot/models/app_config_model.dart';

/// DeepSeek API服务
/// 负责与DeepSeek API进行通信
class DeepSeekApiService {
  DeepSeekApiService({
    required this.apiUrl,
    required this.apiKey,
    this.model = AppConfig.AI_MODEL_DEEPSEEK,
  });
  final String apiUrl;
  final String apiKey;
  final String model;

  /// 发送聊天消息
  ///
  /// [messages] - 对话消息列表，格式：[{'role': 'user', 'content': '消息内容'}]
  /// [temperature] - 温度参数，控制回复的随机性 (0.0-2.0)
  /// [maxTokens] - 最大token数
  Future<(String?, String?)> chat({
    required List<Map<String, String>> messages,
    double temperature = 1.0,
    int? maxTokens,
  }) async {
    try {
      final url = Uri.parse('$apiUrl/chat/completions');

      final requestBody = {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
        'stream': false,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            data['choices']?[0]?['message']?['content'] as String?;

        if (content != null) {
          return (content, null);
        } else {
          return (null, 'AI响应格式错误');
        }
      } else if (response.statusCode == 401) {
        return (null, 'API密钥无效，请检查配置');
      } else if (response.statusCode == 429) {
        return (null, '请求过于频繁，请稍后再试');
      } else {
        final errorMessage = _parseErrorMessage(response.body);
        return (null, errorMessage ?? 'AI服务错误: ${response.statusCode}');
      }
    } catch (e) {
      return (null, '网络请求失败: $e');
    }
  }

  /// 流式聊天（暂未实现）
  ///
  /// 用于实时显示AI回复内容
  Stream<String> chatStream({
    required List<Map<String, String>> messages,
    double temperature = 1.0,
    int? maxTokens,
  }) async* {
    // TODO: 实现流式响应
    yield '流式响应功能待实现';
  }

  /// 解析错误消息
  String? _parseErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']?['message'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 测试API连接
  ///
  /// 返回 (是否成功, 错误消息)
  Future<(bool, String?)> testConnection() async {
    try {
      final (response, error) = await chat(
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        maxTokens: 10,
      );

      if (error != null) {
        return (false, error);
      }

      if (response != null) {
        return (true, null);
      }

      return (false, 'API响应为空');
    } catch (e) {
      return (false, '连接测试失败: $e');
    }
  }

  /// 获取模型信息（如果API支持）
  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final url = Uri.parse('$apiUrl/models/$model');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 构建系统提示词
  ///
  /// 用于为AI设置角色和行为规范
  static Map<String, String> buildSystemMessage(String systemPrompt) => {
        'role': 'system',
        'content': systemPrompt,
      };

  /// 构建用户消息
  static Map<String, String> buildUserMessage(String content) => {
        'role': 'user',
        'content': content,
      };

  /// 构建助手消息
  static Map<String, String> buildAssistantMessage(String content) => {
        'role': 'assistant',
        'content': content,
      };

  /// 🚀 使用统一配置管理的提示词模板
  static String get defaultSystemPrompt => Config.AppConfig.aiDefaultPrompt;
  static String get summarySystemPrompt => Config.AppConfig.aiSummaryPrompt;
  static String get expandSystemPrompt => Config.AppConfig.aiExpandPrompt;
  static String get improveSystemPrompt => Config.AppConfig.aiImprovePrompt;
}

/// AI对话历史管理器
class AiConversationManager {
  AiConversationManager({this.maxHistoryLength = 20});
  final List<Map<String, String>> _messages = [];
  final int maxHistoryLength;

  /// 添加系统消息
  void addSystemMessage(String content) {
    _messages.add(DeepSeekApiService.buildSystemMessage(content));
  }

  /// 添加用户消息
  void addUserMessage(String content) {
    _messages.add(DeepSeekApiService.buildUserMessage(content));
  }

  /// 添加助手消息
  void addAssistantMessage(String content) {
    _messages.add(DeepSeekApiService.buildAssistantMessage(content));
  }

  /// 获取所有消息
  List<Map<String, String>> getMessages() {
    // 保留系统消息 + 最近的N条对话
    final systemMessages =
        _messages.where((m) => m['role'] == 'system').toList();
    final conversationMessages =
        _messages.where((m) => m['role'] != 'system').toList();

    if (conversationMessages.length > maxHistoryLength) {
      return [
        ...systemMessages,
        ...conversationMessages
            .sublist(conversationMessages.length - maxHistoryLength),
      ];
    }

    return _messages;
  }

  /// 清空历史
  void clear() {
    _messages.clear();
  }

  /// 获取消息数量
  int get length => _messages.length;
}
