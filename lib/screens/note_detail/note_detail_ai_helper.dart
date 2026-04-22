// AI 功能助手（从 note_detail_screen.dart 拆分）
// 职责：处理笔记的 AI 摘要和 AI 点评功能

import 'package:flutter/material.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/ai_enhanced_service.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';

/// AI 功能助手类
///
/// 提供以下功能：
/// 1. AI 摘要生成
/// 2. AI 点评（flomo 风格）
/// 3. Markdown 符号清理
class NoteDetailAIHelper {
  final AIEnhancedService _aiEnhancedService = AIEnhancedService();

  /// 生成 AI 摘要
  Future<String?> generateSummary(Note note, AppConfigModel appConfig) async {
    try {
      return await _aiEnhancedService.generateSummary(
        note.content,
        appConfig,
      );
    } catch (e) {
      return null;
    }
  }

  /// 显示 AI 点评对话框（flomo 风格底部 Sheet）
  Future<void> showAiReviewDialog(
    BuildContext context,
    Note note,
    AppConfigModel appConfig,
  ) async {
    // 检查 AI 功能是否启用
    if (!appConfig.aiEnabled) {
      SnackBarUtils.showWarning(context, '请先在设置中启用AI功能');
      return;
    }

    // 检查 API 配置
    if (appConfig.aiApiUrl == null || appConfig.aiApiKey == null) {
      SnackBarUtils.showWarning(context, '请先在设置中配置AI API');
      return;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? reviewResult;
    String? errorMessage;
    bool isLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // 开始 AI 点评（仅执行一次）
          if (isLoading && reviewResult == null && errorMessage == null) {
            _getAiReview(note, appConfig).then((result) {
              if (context.mounted) {
                setState(() {
                  reviewResult = result.$1;
                  errorMessage = result.$2;
                  isLoading = false;
                });
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // 拖动指示器
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI 点评',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (!isLoading)
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          onPressed: () => Navigator.pop(context),
                        ),
                    ],
                  ),
                ),
                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: isDarkMode ? Colors.white38 : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDarkMode ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : isLoading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 60),
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDarkMode
                                              ? AppTheme.primaryLightColor
                                              : AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'AI 正在思考...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDarkMode ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildReviewContent(reviewResult!, isDarkMode),
                  ),
                ),
                // 底部按钮
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode ? Colors.white12 : Colors.black12,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 复制按钮
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: reviewResult != null
                                ? () {
                                    // 复制内容（移除 Markdown 符号）
                                    final plainText = _cleanMarkdown(reviewResult!);
                                    SnackBarUtils.showSuccess(context, '已复制到剪贴板');
                                  }
                                : null,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('复制'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 完成按钮
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '完成',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建点评内容（flomo 风格）
  Widget _buildReviewContent(String review, bool isDarkMode) {
    return Text(
      review,
      style: TextStyle(
        fontSize: 16,
        height: 1.8,
        color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
        letterSpacing: 0.3,
      ),
    );
  }

  /// 清理 Markdown 符号，转换为纯文本
  String _cleanMarkdown(String markdown) {
    String result = markdown;

    // 移除 Markdown 标题符号
    result = result.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

    // 移除加粗符号
    result = result.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    result = result.replaceAll(RegExp(r'__(.*?)__'), r'$1');

    // 移除斜体符号
    result = result.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    result = result.replaceAll(RegExp(r'_(.*?)_'), r'$1');

    // 移除删除线
    result = result.replaceAll(RegExp(r'~~(.*?)~~'), r'$1');

    // 移除代码块符号
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    result = result.replaceAll(RegExp(r'`(.*?)`'), r'$1');

    // 移除链接格式
    result = result.replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1');

    // 移除图片格式
    result = result.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');

    // 移除引用符号
    result = result.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

    // 移除水平线
    result = result.replaceAll(RegExp(r'^-{3,}$', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\*{3,}$', multiLine: true), '');

    // 移除列表符号
    result = result.replaceAll(RegExp(r'^[\*\-\+]\s+', multiLine: true), '');
    result = result.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    // 清理多余的空行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }

  /// 调用 AI 进行点评（flomo 风格 Prompt）
  Future<(String?, String?)> _getAiReview(
    Note note,
    AppConfigModel appConfig,
  ) async {
    try {
      final prompt = appConfig.aiReviewPrompt ??
          '''请以轻松、有见地的语气点评这篇笔记，就像一个聪明的朋友在和你聊天。
不要使用列表、标题或过于正式的结构。

笔记内容：
${note.content}

请从以下角度给出你的看法：
1. 这篇笔记让你想到了什么？有什么有趣的联系或启发？
2. 内容中有什么值得深入思考的点？
3. 如果要改进，你会建议什么？

记住：像朋友聊天一样自然、真诚，不要太正式。''';

      final response = await DeepSeekApiService.generateText(
        prompt: prompt,
        apiUrl: appConfig.aiApiUrl!,
        apiKey: appConfig.aiApiKey!,
        model: appConfig.aiModel ?? 'deepseek-chat',
      );

      return (response, null);
    } catch (e) {
      return (null, 'AI 点评失败: $e');
    }
  }
}
