import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/services/iflytek_speech_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _apiUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _customInsightPromptController = TextEditingController();
  final _customReviewPromptController = TextEditingController();
  final _customContinuationPromptController = TextEditingController();
  final _customTagInsightPromptController = TextEditingController();
  final _customTagRecommendationPromptController = TextEditingController();
  final _iflytekAppIdController = TextEditingController();
  final _iflytekApiKeyController = TextEditingController();
  final _iflytekApiSecretController = TextEditingController();
  bool _obscureApiKey = true;
  bool _obscureIflytekApiKey = true;
  bool _obscureIflytekApiSecret = true;
  bool _useIflytekSpeech = false;

  String _text(String zh, String en) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final appConfig = appProvider.appConfig;

    // 初始化输入框
    _apiUrlController.text = appConfig.aiApiUrl ?? AppConfig.DEEPSEEK_API_URL;
    _apiKeyController.text = appConfig.aiApiKey ?? '';
    _modelController.text = appConfig.aiModel;
    _customInsightPromptController.text = appConfig.customInsightPrompt ?? '';
    _customReviewPromptController.text = appConfig.customReviewPrompt ?? '';
    _customContinuationPromptController.text =
        appConfig.customContinuationPrompt ?? '';
    _customTagInsightPromptController.text =
        appConfig.customTagInsightPrompt ?? '';
    _customTagRecommendationPromptController.text =
        appConfig.customTagRecommendationPrompt ?? '';
    _iflytekAppIdController.text = appConfig.iflytekAppId ?? '';
    _iflytekApiKeyController.text = appConfig.iflytekApiKey ?? '';
    _iflytekApiSecretController.text = appConfig.iflytekApiSecret ?? '';
    _useIflytekSpeech =
        appConfig.speechRecognitionMode == AppConfig.SPEECH_MODE_IFLYTEK &&
            appConfig.iflytekSpeechEnabled;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _customInsightPromptController.dispose();
    _customReviewPromptController.dispose();
    _customContinuationPromptController.dispose();
    _customTagInsightPromptController.dispose();
    _customTagRecommendationPromptController.dispose();
    _iflytekAppIdController.dispose();
    _iflytekApiKeyController.dispose();
    _iflytekApiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final appConfig = appProvider.appConfig;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkSurfaceColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Text(
          AppLocalizationsSimple.of(context)?.aiSettings ?? 'AI 设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        actions: [
          // 帮助按钮
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
            onPressed: _showFAQDialog,
          ),
          // 保存按钮
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
            onPressed: () => _saveSettings(appProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 个性化统计入口
          InkWell(
            onTap: () => context.push('/user-preferences'),
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          const Color(0xFF6366F1).withValues(alpha: 0.15),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        ]
                      : [
                          const Color(0xFF6366F1).withValues(alpha: 0.08),
                          const Color(0xFFF59E0B).withValues(alpha: 0.06),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text('个性化', 'Personalization'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text('查看 AI 学习偏好', 'View AI learning preferences'),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),

          // AI功能开关
          _buildSectionHeader(
            context,
            AppLocalizationsSimple.of(context)?.aiFeatures ?? 'AI功能',
          ),
          _buildSwitchCard(
            context,
            icon: Icons.psychology,
            title: AppLocalizationsSimple.of(context)?.enableAIAssistant ??
                '启用AI助手',
            subtitle:
                AppLocalizationsSimple.of(context)?.aiAssistantDescription ??
                    '开启后可使用AI辅助功能',
            value: appConfig.aiEnabled,
            onChanged: (value) {
              final updatedConfig = appConfig.copyWith(aiEnabled: value);
              appProvider.updateConfig(updatedConfig);
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, _text('语音输入', 'Voice Input')),
          _buildSpeechSettingsCard(context, appProvider, appConfig),

          // 只有启用AI后才显示配置项
          if (appConfig.aiEnabled) ...[
            const SizedBox(height: 24),

            // API配置
            _buildSectionHeader(
              context,
              AppLocalizationsSimple.of(context)?.apiConfiguration ?? 'API配置',
            ),

            // API地址
            _buildInputCard(
              context,
              icon: Icons.cloud,
              title: AppLocalizationsSimple.of(context)?.apiAddressLabel ??
                  'API 地址',
              controller: _apiUrlController,
              hintText: 'https://api.deepseek.com/v1',
            ),

            const SizedBox(height: 12),

            // API密钥
            _buildInputCard(
              context,
              icon: Icons.key,
              title:
                  AppLocalizationsSimple.of(context)?.apiKeyLabel ?? 'API 密钥',
              controller: _apiKeyController,
              hintText: AppLocalizationsSimple.of(context)?.enterAPIKey ??
                  '请输入API Key',
              obscureText: _obscureApiKey,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  color: secondaryTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // AI模型选择
            _buildSectionHeader(
              context,
              AppLocalizationsSimple.of(context)?.aiModel ?? 'AI模型',
            ),
            _buildModelInputCard(context, appProvider, appConfig),

            const SizedBox(height: 24),

            // 🎯 自定义Prompt
            _buildSectionHeader(
              context,
              AppLocalizationsSimple.of(context)?.customPrompts ?? '自定义提示词',
            ),
            _buildCustomPromptCard(context, appProvider, appConfig),

            const SizedBox(height: 24),

            // 测试连接
            _buildTestConnectionButton(context),
            const SizedBox(height: 24),

            // 帮助信息
            _buildHelpCard(context),
          ],
        ],
      ),
    );
  }

  // 构建分区标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // 构建开关卡片
  Widget _buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
          ),
        ],
      ),
    );
  }

  // 构建输入卡片
  Widget _buildInputCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: textColor.withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechSettingsCard(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final useIflytek = _useIflytekSpeech;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.mic_none_rounded, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text('语音转文字', 'Speech to Text'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _text(
                        '点击编辑器麦克风，或长按首页 + 号直接语音新建。',
                        'Use the editor mic button, or long-press + on Home to start a voice note.',
                      ),
                      style: TextStyle(fontSize: 13, color: subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: AppConfig.SPEECH_MODE_SYSTEM,
                icon: const Icon(Icons.phone_iphone_rounded),
                label: Text(_text('系统识别', 'System')),
              ),
              const ButtonSegment<String>(
                value: AppConfig.SPEECH_MODE_IFLYTEK,
                icon: Icon(Icons.cloud_outlined),
                label: Text('讯飞'),
              ),
            ],
            selected: {
              if (useIflytek)
                AppConfig.SPEECH_MODE_IFLYTEK
              else
                AppConfig.SPEECH_MODE_SYSTEM,
            },
            onSelectionChanged: (selection) {
              final mode = selection.first;
              setState(() {
                _useIflytekSpeech = mode == AppConfig.SPEECH_MODE_IFLYTEK;
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            useIflytek
                ? _text(
                    '开启后语音会发送到讯飞接口转写，调用费用由你的讯飞账号承担。',
                    'When enabled, audio is sent to iFlytek for transcription. Usage costs belong to your iFlytek account.',
                  )
                : _text(
                    '默认使用系统语音识别，免费、低门槛，能力受系统和设备环境影响。',
                    'System recognition is free and simple, but quality depends on the OS and device environment.',
                  ),
            style: TextStyle(fontSize: 12, height: 1.5, color: subTextColor),
          ),
          if (useIflytek) ...[
            const SizedBox(height: 16),
            _buildInputCard(
              context,
              icon: Icons.badge_outlined,
              title: 'APPID',
              controller: _iflytekAppIdController,
              hintText: _text('讯飞控制台的 APPID', 'APPID from iFlytek console'),
            ),
            const SizedBox(height: 12),
            _buildInputCard(
              context,
              icon: Icons.key_outlined,
              title: 'APIKey',
              controller: _iflytekApiKeyController,
              hintText: 'APIKey',
              obscureText: _obscureIflytekApiKey,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureIflytekApiKey
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: subTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureIflytekApiKey = !_obscureIflytekApiKey;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildInputCard(
              context,
              icon: Icons.lock_outline,
              title: 'APISecret',
              controller: _iflytekApiSecretController,
              hintText: 'APISecret',
              obscureText: _obscureIflytekApiSecret,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureIflytekApiSecret
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: subTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscureIflytekApiSecret = !_obscureIflytekApiSecret;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testIflytekConnection,
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: Text(_text('测试讯飞连接', 'Test iFlytek')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showIflytekSetupGuide,
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: Text(_text('对接教程', 'Setup Guide')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelInputCard(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.model_training_rounded,
                    color: iconColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizationsSimple.of(context)?.modelSelection ?? '模型名称',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: appConfig.aiEnabled
                      ? () => _showModelSelectorSheet(
                            context,
                          )
                      : null,
                  child: Text(_text('示例', 'Examples')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              enabled: appConfig.aiEnabled,
              style: TextStyle(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: 'deepseek-chat / gpt-4o / qwen-plus',
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _text(
                '直接填写服务商文档里的模型名。AI 模型更新很快，这里不再强制限制固定列表。',
                'Enter the model name from your provider documentation. Models change quickly, so this field is not locked to a fixed list.',
              ),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示常用模型示例底部对话框
  void _showModelSelectorSheet(
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final dividerColor =
        isDarkMode ? AppTheme.darkDividerColor : AppTheme.dividerColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.5 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      AppLocalizationsSimple.of(context)?.selectModel ??
                          '常用模型示例',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModelCategoryHeader(
                            context,
                            'DeepSeek',
                          ),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.flash_on,
                            title: 'DeepSeek V3',
                            subtitle: '通用对话模型示例',
                            model: AppConfig.AI_MODEL_DEEPSEEK,
                            apiUrl: AppConfig.DEEPSEEK_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.psychology,
                            title: 'DeepSeek Reasoner',
                            subtitle: '推理模型示例',
                            model: AppConfig.AI_MODEL_DEEPSEEK_REASONER,
                            apiUrl: AppConfig.DEEPSEEK_API_URL,
                          ),

                          const SizedBox(height: 16),

                          _buildModelCategoryHeader(
                            context,
                            'OpenAI',
                          ),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.stars,
                            title: 'o3-mini',
                            subtitle: '推理模型示例',
                            model: AppConfig.AI_MODEL_O3_MINI,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.wb_incandescent,
                            title: 'o1',
                            subtitle: '推理模型示例',
                            model: AppConfig.AI_MODEL_O1,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.bolt,
                            title: 'o1-mini',
                            subtitle: '轻量推理模型示例',
                            model: AppConfig.AI_MODEL_O1_MINI,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.auto_awesome,
                            title: 'GPT-4o',
                            subtitle: '多模态模型示例',
                            model: AppConfig.AI_MODEL_GPT4O,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.speed,
                            title: 'GPT-4o Mini',
                            subtitle: '轻量模型示例',
                            model: AppConfig.AI_MODEL_GPT4O_MINI,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),

                          const SizedBox(height: 16),

                          _buildModelCategoryHeader(context, '通义千问'),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.workspace_premium,
                            title: 'Qwen Max',
                            subtitle: '通义千问模型示例',
                            model: AppConfig.AI_MODEL_QWEN_MAX,
                            apiUrl: AppConfig.QWEN_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.auto_awesome,
                            title: 'Qwen Plus',
                            subtitle: '通义千问模型示例',
                            model: AppConfig.AI_MODEL_QWEN_PLUS,
                            apiUrl: AppConfig.QWEN_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.flash_on,
                            title: 'Qwen Turbo',
                            subtitle: '通义千问模型示例',
                            model: AppConfig.AI_MODEL_QWEN_TURBO,
                            apiUrl: AppConfig.QWEN_API_URL,
                          ),

                          const SizedBox(height: 16),

                          _buildModelCategoryHeader(context, '智谱 GLM'),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.flash_on,
                            title: 'GLM-4-Flash',
                            subtitle: 'GLM 模型示例',
                            model: AppConfig.AI_MODEL_GLM_4_FLASH,
                            apiUrl: AppConfig.ZHIPU_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.stars,
                            title: 'GLM-4-Plus',
                            subtitle: 'GLM 模型示例',
                            model: AppConfig.AI_MODEL_GLM_4_PLUS,
                            apiUrl: AppConfig.ZHIPU_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.cloud,
                            title: 'GLM-4-Air',
                            subtitle: 'GLM 模型示例',
                            model: AppConfig.AI_MODEL_GLM_4_AIR,
                            apiUrl: AppConfig.ZHIPU_API_URL,
                          ),

                          const SizedBox(height: 16),

                          // 🌙 Moonshot（Kimi）
                          _buildModelCategoryHeader(context, 'Moonshot AI'),
                          _buildModelSheetOption(
                            context,
                            icon: Icons.nightlight,
                            title: 'Kimi (128K)',
                            subtitle: '长上下文模型示例',
                            model: AppConfig.AI_MODEL_MOONSHOT,
                            apiUrl: AppConfig.MOONSHOT_API_URL,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建模型分类标题
  Widget _buildModelCategoryHeader(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // 构建模型选项（底部对话框中）
  Widget _buildModelSheetOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String model,
    required String apiUrl,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final isSelected = _modelController.text.trim() == model;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _apiUrlController.text = apiUrl;
            _modelController.text = model;
          });
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.15)
                      : (isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : secondaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? primaryColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建测试连接按钮
  Widget _buildTestConnectionButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _testConnection,
          icon: const Icon(Icons.wifi_tethering, size: 20),
          label: Text(
            AppLocalizationsSimple.of(context)?.testingAPIConnection ??
                '测试API连接',
            style: const TextStyle(fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      );

  // 构建底部提醒卡片
  Widget _buildHelpCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _text('温馨提示', 'Tips'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _text(
              '• 示例模型只会填入输入框，最终以右上角保存为准\n'
                  '• 可以直接输入服务商提供的任意模型名\n'
                  '• API 密钥仅存储在本地，不会上传\n'
                  '• 支持所有兼容 OpenAI 格式的 AI 服务',
              '• Example models only fill the fields; use the top-right save button to apply\n'
                  '• You can enter any model name provided by your AI service\n'
                  '• API keys are stored locally and are not uploaded\n'
                  '• OpenAI-compatible AI services are supported',
            ),
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // 测试API连接
  Future<void> _testConnection() async {
    // 🔧 改进：使用当前输入框的值进行测试，而不是已保存的配置
    // 这样用户可以在保存前测试新配置，符合大厂最佳实践
    final currentApiUrl = _apiUrlController.text.trim();
    final currentApiKey = _apiKeyController.text.trim();
    final currentModel = _modelController.text.trim();

    if (currentApiUrl.isEmpty) {
      SnackBarUtils.showWarning(
        context,
        _text('请先输入 API 地址', 'Enter API URL first'),
      );
      return;
    }

    if (currentApiKey.isEmpty) {
      SnackBarUtils.showWarning(
        context,
        _text('请先输入 API 密钥', 'Enter API key first'),
      );
      return;
    }

    if (currentModel.isEmpty) {
      SnackBarUtils.showWarning(
        context,
        _text('请先输入模型名称', 'Enter model name first'),
      );
      return;
    }

    // 显示加载提示
    if (mounted) {
      SnackBarUtils.showInfo(
        context,
        _text('正在测试连接...', 'Testing connection...'),
      );
    }

    try {
      // 🎯 使用当前输入框的值创建临时配置进行测试
      final apiService = DeepSeekApiService(
        apiUrl: currentApiUrl,
        apiKey: currentApiKey,
        model: currentModel,
      );

      final (success, error) = await apiService.testConnection();

      if (mounted) {
        if (success) {
          SnackBarUtils.showSuccess(
            context,
            _text(
              'API 连接测试成功，请点击右上角保存配置',
              'API connection succeeded. Save the settings to apply.',
            ),
          );
        } else {
          SnackBarUtils.showError(
            context,
            error ?? _text('连接失败', 'Connection failed'),
          );
        }
      }
    } on Object catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '${_text('测试失败', 'Test failed')}: $e',
        );
      }
    }
  }

  Future<void> _testIflytekConnection() async {
    final config = _speechConfigFromInputs(
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).appConfig,
    );

    if (!IflytekSpeechService(config).isConfigured) {
      SnackBarUtils.showWarning(
        context,
        _text(
          '请先填写完整的 APPID、APIKey 和 APISecret',
          'Enter APPID, APIKey, and APISecret first',
        ),
      );
      return;
    }

    SnackBarUtils.showInfo(
      context,
      _text('正在测试讯飞连接...', 'Testing iFlytek connection...'),
    );
    final ok = await IflytekSpeechService(config).testConnection();
    if (!mounted) {
      return;
    }
    if (ok) {
      SnackBarUtils.showSuccess(
        context,
        _text('讯飞连接成功，请点击右上角保存', 'iFlytek connected. Save to apply.'),
      );
    } else {
      SnackBarUtils.showError(
        context,
        _text(
          '讯飞连接失败，请检查密钥、额度和网络',
          'iFlytek connection failed. Check keys, quota, and network.',
        ),
      );
    }
  }

  AppConfig _speechConfigFromInputs(AppConfig base) {
    final appId = _iflytekAppIdController.text.trim();
    final apiKey = _iflytekApiKeyController.text.trim();
    final apiSecret = _iflytekApiSecretController.text.trim();
    return base.copyWith(
      speechRecognitionMode: _useIflytekSpeech
          ? AppConfig.SPEECH_MODE_IFLYTEK
          : AppConfig.SPEECH_MODE_SYSTEM,
      iflytekSpeechEnabled: _useIflytekSpeech,
      iflytekAppId: appId.isEmpty ? null : appId,
      iflytekApiKey: apiKey.isEmpty ? null : apiKey,
      iflytekApiSecret: apiSecret.isEmpty ? null : apiSecret,
      updateIflytekAppId: true,
      updateIflytekApiKey: true,
      updateIflytekApiSecret: true,
    );
  }

  void _showIflytekSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_text('讯飞语音识别对接教程', 'iFlytek Setup Guide')),
        content: SingleChildScrollView(
          child: Text(
            _text(
              '1. 打开讯飞开放平台，进入控制台\n'
                  '2. 创建应用，开通“语音听写/实时语音转写”能力\n'
                  '3. 在应用详情复制 APPID、APIKey、APISecret\n'
                  '4. 回到 InkRoot 填入上方三个字段并测试连接\n'
                  '5. 首页长按 + 号即可语音新建，编辑器里也可点麦克风补充\n\n'
                  '注意：开启后语音会发送到讯飞接口识别，调用额度和费用由你的讯飞账号承担。',
              '1. Open iFlytek Open Platform and enter the console\n'
                  '2. Create an app and enable speech dictation / real-time ASR\n'
                  '3. Copy APPID, APIKey, and APISecret from the app detail page\n'
                  '4. Enter them in InkRoot and test the connection\n'
                  '5. Long-press + on Home to create a voice note; use the editor mic to add more\n\n'
                  'Note: when enabled, audio is sent to iFlytek for recognition. Quota and costs belong to your iFlytek account.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizationsSimple.of(context)?.confirm ?? '确定'),
          ),
        ],
      ),
    );
  }

  // 显示常见问题对话框
  void _showFAQDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI 配置说明',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: secondaryColor, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 内容
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFAQItem(
                        context,
                        question: '🔑 API 密钥从哪里来？',
                        answer: '请到对应 AI 服务商控制台创建 API Key。\n\n'
                            '常见兼容 OpenAI 格式的服务商包括：\n'
                            '• DeepSeek：platform.deepseek.com\n'
                            '• 智谱 GLM：open.bigmodel.cn\n'
                            '• 通义千问：dashscope.aliyun.com\n'
                            '• Moonshot：platform.moonshot.cn\n'
                            '• OpenAI：platform.openai.com\n\n'
                            '具体模型名和可用 API 地址以服务商当前文档为准。',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🧩 模型名称怎么填？',
                        answer:
                            '模型名称直接填写服务商文档中的 model 字段，例如 deepseek-chat、gpt-4o、qwen-plus。\n\n'
                            '“示例”按钮只负责快速填入常见模型和 API 地址，不限制你输入新模型。',
                      ),
                      _buildFAQItem(
                        context,
                        question: '❌ 连接失败？',
                        answer: '1. 检查 API 地址格式（需 https://）\n'
                            '2. 确认 API 密钥完整复制无误\n'
                            '3. 确认模型名和服务商当前文档一致\n'
                            '4. 检查账户额度、网络和服务商可用状态\n\n'
                            '可以先用“测试 API 连接”验证当前输入框内容。',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔧 高级功能',
                        answer: '• 模型输入框：支持任意兼容 OpenAI 格式的模型名\n'
                            '• 聚合服务：可配置兼容 OpenAI 格式的中转服务\n'
                            '• 自定义提示词：个性化 AI 输出风格\n'
                            '• API 地址可自定义（代理/自建服务）',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔒 安全说明',
                        answer: 'API 密钥仅存储在本地设备，不会上传到任何服务器。\n'
                            'AI 功能仅在你主动点击时调用，不会自动运行。',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.rocket_launch_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '配置原则',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '1. 优先按服务商官方文档填写 API 地址和模型名\n'
                              '2. 保存前先测试连接，避免保存不可用配置\n'
                              '3. 模型更新很快，应用不强制维护固定列表',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建FAQ项目
  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 构建自定义Prompt卡片
  Widget _buildCustomPromptCard(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final localizations = AppLocalizationsSimple.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 开关行
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizationsSimple.of(context)
                                ?.enableCustomPrompts ??
                            '启用自定义提示词',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '按功能分别定义 AI 输出规则。关闭开关会暂时停用，清空输入框并保存才会删除。',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: appConfig.useCustomPrompt,
                  onChanged: (value) {
                    appProvider.updateConfig(
                      appConfig.copyWith(useCustomPrompt: value),
                    );
                  },
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          // 自定义Prompt输入区域（仅在启用时显示）
          if (appConfig.useCustomPrompt) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: 16),

            // 洞察Prompt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizationsSimple.of(context)?.insightPrompt ??
                        '洞察提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.insightPromptHint ??
                                '自定义AI洞察的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customInsightPromptController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: localizations?.insightPromptHint ??
                          '自定义AI洞察的提示词，留空使用默认提示词',
                      hintStyle: TextStyle(color: secondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 点评Prompt
                  Text(
                    AppLocalizationsSimple.of(context)?.reviewPrompt ?? '点评提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.reviewPromptHint ??
                                '自定义AI点评的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customReviewPromptController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: localizations?.reviewPromptHint ??
                          '自定义AI点评的提示词，留空使用默认提示词',
                      hintStyle: TextStyle(color: secondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 续写Prompt
                  Text(
                    AppLocalizationsSimple.of(context)?.continuationPrompt ??
                        '续写提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.continuationPromptHint ??
                                '自定义AI续写的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customContinuationPromptController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: localizations?.continuationPromptHint ??
                          '自定义AI续写的提示词，留空使用默认提示词',
                      hintStyle: TextStyle(color: secondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标签洞察Prompt
                  Text(
                    AppLocalizationsSimple.of(context)?.tagInsightPrompt ??
                        '标签洞察提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.tagInsightPromptHint ??
                                '自定义标签洞察的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customTagInsightPromptController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: localizations?.tagInsightPromptHint ??
                          '自定义标签洞察的提示词，留空使用默认提示词',
                      hintStyle: TextStyle(color: secondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标签推荐Prompt
                  Text(
                    AppLocalizationsSimple.of(context)
                            ?.tagRecommendationPrompt ??
                        '标签推荐提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.tagRecommendationPromptHint ??
                                '自定义标签推荐的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customTagRecommendationPromptController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: localizations?.tagRecommendationPromptHint ??
                          '自定义标签推荐的提示词，留空使用默认提示词',
                      hintStyle: TextStyle(color: secondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🔧 清理和验证 API Key（防止编码问题）
  String? _cleanAndValidateApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      return null;
    }

    // 移除所有不可见字符（空格、换行、制表符等）
    final cleaned = apiKey.replaceAll(RegExp(r'\s'), '');

    // 检查是否包含非 ASCII 字符
    if (cleaned.runes.any((rune) => rune > 127)) {
      throw const FormatException('API Key 包含非法字符，请重新复制粘贴');
    }

    // 检查是否为空
    if (cleaned.isEmpty) {
      throw const FormatException('API Key 不能为空');
    }

    return cleaned;
  }

  // 保存设置
  Future<void> _saveSettings(AppProvider appProvider) async {
    final apiUrl = _apiUrlController.text.trim();
    var apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();

    // 验证输入
    if (appProvider.appConfig.aiEnabled) {
      if (apiUrl.isEmpty) {
        SnackBarUtils.showWarning(context, '请输入API地址');
        return;
      }
      if (apiKey.isEmpty) {
        SnackBarUtils.showWarning(context, '请输入API密钥');
        return;
      }
      if (model.isEmpty) {
        SnackBarUtils.showWarning(context, '请输入模型名称');
        return;
      }

      // 🔧 清理和验证 API Key
      try {
        apiKey = _cleanAndValidateApiKey(apiKey) ?? '';
      } on Object catch (e) {
        SnackBarUtils.showError(context, e.toString());
        return;
      }
    }

    // 保存配置
    final customInsightPrompt = _customInsightPromptController.text.trim();
    final customReviewPrompt = _customReviewPromptController.text.trim();
    final customContinuationPrompt =
        _customContinuationPromptController.text.trim();
    final customTagInsightPrompt =
        _customTagInsightPromptController.text.trim();
    final customTagRecommendationPrompt =
        _customTagRecommendationPromptController.text.trim();
    final hasCustomPrompt = appProvider.appConfig.useCustomPrompt &&
        (customInsightPrompt.isNotEmpty ||
            customReviewPrompt.isNotEmpty ||
            customContinuationPrompt.isNotEmpty ||
            customTagInsightPrompt.isNotEmpty ||
            customTagRecommendationPrompt.isNotEmpty);
    final iflytekAppId = _iflytekAppIdController.text.trim();
    final iflytekApiKey = _iflytekApiKeyController.text.trim();
    final iflytekApiSecret = _iflytekApiSecretController.text.trim();

    if (_useIflytekSpeech &&
        (iflytekAppId.isEmpty ||
            iflytekApiKey.isEmpty ||
            iflytekApiSecret.isEmpty)) {
      SnackBarUtils.showWarning(
        context,
        _text(
          '开启讯飞语音识别需要填写 APPID、APIKey 和 APISecret',
          'APPID, APIKey, and APISecret are required for iFlytek speech.',
        ),
      );
      return;
    }

    final updatedConfig = appProvider.appConfig.copyWith(
      aiApiUrl: apiUrl.isEmpty ? null : apiUrl,
      aiApiKey: apiKey.isEmpty ? null : apiKey,
      aiModel: model.isEmpty ? appProvider.appConfig.aiModel : model,
      updateAiApiUrl: true,
      updateAiApiKey: true,
      speechRecognitionMode: _useIflytekSpeech
          ? AppConfig.SPEECH_MODE_IFLYTEK
          : AppConfig.SPEECH_MODE_SYSTEM,
      iflytekSpeechEnabled: _useIflytekSpeech,
      iflytekAppId: iflytekAppId.isEmpty ? null : iflytekAppId,
      iflytekApiKey: iflytekApiKey.isEmpty ? null : iflytekApiKey,
      iflytekApiSecret: iflytekApiSecret.isEmpty ? null : iflytekApiSecret,
      updateIflytekAppId: true,
      updateIflytekApiKey: true,
      updateIflytekApiSecret: true,
      useCustomPrompt: hasCustomPrompt,
      customInsightPrompt:
          customInsightPrompt.isEmpty ? null : customInsightPrompt,
      customReviewPrompt:
          customReviewPrompt.isEmpty ? null : customReviewPrompt,
      customContinuationPrompt:
          customContinuationPrompt.isEmpty ? null : customContinuationPrompt,
      customTagInsightPrompt:
          customTagInsightPrompt.isEmpty ? null : customTagInsightPrompt,
      customTagRecommendationPrompt: customTagRecommendationPrompt.isEmpty
          ? null
          : customTagRecommendationPrompt,
      updateCustomInsightPrompt: true,
      updateCustomReviewPrompt: true,
      updateCustomContinuationPrompt: true,
      updateCustomTagInsightPrompt: true,
      updateCustomTagRecommendationPrompt: true,
    );

    await appProvider.updateConfig(updatedConfig);

    if (mounted) {
      SnackBarUtils.showSuccess(
        context,
        AppLocalizationsSimple.of(context)?.saveConfiguration ?? 'AI配置已保存',
      );
      Navigator.of(context).pop();
    }
  }
}
