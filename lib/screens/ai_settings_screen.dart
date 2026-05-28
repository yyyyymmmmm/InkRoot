import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
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
  final _customInsightPromptController = TextEditingController();
  final _customReviewPromptController = TextEditingController();
  final _customContinuationPromptController = TextEditingController();
  final _customTagInsightPromptController = TextEditingController();
  final _customTagRecommendationPromptController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final appConfig = appProvider.appConfig;

    // 初始化输入框
    _apiUrlController.text = appConfig.aiApiUrl ?? AppConfig.DEEPSEEK_API_URL;
    _apiKeyController.text = appConfig.aiApiKey ?? '';
    _customInsightPromptController.text = appConfig.customInsightPrompt ?? '';
    _customReviewPromptController.text = appConfig.customReviewPrompt ?? '';
    _customContinuationPromptController.text = appConfig.customContinuationPrompt ?? '';
    _customTagInsightPromptController.text = appConfig.customTagInsightPrompt ?? '';
    _customTagRecommendationPromptController.text = appConfig.customTagRecommendationPrompt ?? '';
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _customInsightPromptController.dispose();
    _customReviewPromptController.dispose();
    _customContinuationPromptController.dispose();
    _customTagInsightPromptController.dispose();
    _customTagRecommendationPromptController.dispose();
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
        leading: isDesktop ? null : IconButton(
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
                          const Color(0xFF6366F1).withOpacity(0.15),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFF6366F1).withOpacity(0.08),
                          const Color(0xFFF59E0B).withOpacity(0.06),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.5),
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
                    child: const Icon(Icons.insights, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalization',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View AI learning preferences',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: secondaryTextColor),
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
            _buildModelSelectorCard(context, appProvider, appConfig),

            const SizedBox(height: 24),

            // 🎯 自定义Prompt
            _buildSectionHeader(context, AppLocalizationsSimple.of(context)?.customPrompts ?? '自定义提示词'),
            _buildCustomPromptCard(context, appProvider, appConfig),

            const SizedBox(height: 24),

            // 测试连接
            if (appConfig.aiApiKey != null &&
                appConfig.aiApiKey!.isNotEmpty) ...[
              _buildTestConnectionButton(context, appConfig),
              const SizedBox(height: 24),
            ],

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
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
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
              color: iconColor.withOpacity(0.1),
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
            activeColor: iconColor,
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
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
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
                  color: iconColor.withOpacity(0.1),
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
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: textColor.withOpacity(0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
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
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  // iOS风格的模型选择器卡片
  Widget _buildModelSelectorCard(
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

    // 获取当前模型的名称和描述（仅显示兼容OpenAI格式的模型）
    String getModelName(String model) {
      switch (model) {
        // DeepSeek V3系列
        case AppConfig.AI_MODEL_DEEPSEEK:
          return 'DeepSeek V3';
        case AppConfig.AI_MODEL_DEEPSEEK_REASONER:
          return 'DeepSeek Reasoner';
        
        // OpenAI 2025系列
        case AppConfig.AI_MODEL_O3_MINI:
          return 'o3-mini';
        case AppConfig.AI_MODEL_O1:
          return 'o1';
        case AppConfig.AI_MODEL_O1_MINI:
          return 'o1-mini';
        case AppConfig.AI_MODEL_GPT4O:
          return 'GPT-4o';
        case AppConfig.AI_MODEL_GPT4O_MINI:
          return 'GPT-4o Mini';
        
        // 通义千问系列
        case AppConfig.AI_MODEL_QWEN_MAX:
          return 'Qwen Max';
        case AppConfig.AI_MODEL_QWEN_PLUS:
          return 'Qwen Plus';
        case AppConfig.AI_MODEL_QWEN_TURBO:
          return 'Qwen Turbo';
        
        // 智谱GLM系列
        case AppConfig.AI_MODEL_GLM_4_FLASH:
          return 'GLM-4-Flash';
        case AppConfig.AI_MODEL_GLM_4_PLUS:
          return 'GLM-4-Plus';
        case AppConfig.AI_MODEL_GLM_4_AIR:
          return 'GLM-4-Air';
        
        // Moonshot
        case AppConfig.AI_MODEL_MOONSHOT:
          return 'Kimi (128K)';
        
        default:
          // 🎯 大厂标准：自定义模型显示实际名称，而不是"未知"
          return '$model (自定义)';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: appConfig.aiEnabled
              ? () => _showModelSelectorSheet(context, appProvider, appConfig)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.model_training_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizationsSimple.of(context)?.modelSelection ??
                            '模型选择',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getModelName(appConfig.aiModel),
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: subTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示iOS风格的模型选择器底部对话框
  void _showModelSelectorSheet(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
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
                  color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
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
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      AppLocalizationsSimple.of(context)?.selectModel ??
                          '选择AI模型',
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
                          // 🔥 DeepSeek V3 系列（2025最新）
                          _buildModelCategoryHeader(context, 'DeepSeek V3 性价比之选'),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.flash_on,
                            title: 'DeepSeek V3',
                            subtitle: '最新V3版本，超强性价比',
                            model: AppConfig.AI_MODEL_DEEPSEEK,
                            apiUrl: AppConfig.DEEPSEEK_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.psychology,
                            title: 'DeepSeek Reasoner',
                            subtitle: '深度推理，复杂任务首选',
                            model: AppConfig.AI_MODEL_DEEPSEEK_REASONER,
                            apiUrl: AppConfig.DEEPSEEK_API_URL,
                          ),

                          const SizedBox(height: 16),

                          // 🌟 OpenAI 2025系列
                          _buildModelCategoryHeader(context, 'OpenAI 2025 全新推理模型'),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.stars,
                            title: 'o3-mini',
                            subtitle: '2025最新推理，快速高效',
                            model: AppConfig.AI_MODEL_O3_MINI,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.wb_incandescent,
                            title: 'o1',
                            subtitle: '强大推理能力，适合复杂分析',
                            model: AppConfig.AI_MODEL_O1,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.bolt,
                            title: 'o1-mini',
                            subtitle: '轻量推理，性价比高',
                            model: AppConfig.AI_MODEL_O1_MINI,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.auto_awesome,
                            title: 'GPT-4o',
                            subtitle: '多模态旗舰，强大全能',
                            model: AppConfig.AI_MODEL_GPT4O,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.speed,
                            title: 'GPT-4o Mini',
                            subtitle: '轻量快速，日常使用',
                            model: AppConfig.AI_MODEL_GPT4O_MINI,
                            apiUrl: AppConfig.OPENAI_API_URL,
                          ),

                          const SizedBox(height: 16),

                          // 📚 通义千问官方系列
                          _buildModelCategoryHeader(context, '通义千问 阿里旗舰'),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.workspace_premium,
                            title: 'Qwen Max',
                            subtitle: '旗舰版本，最强性能',
                            model: AppConfig.AI_MODEL_QWEN_MAX,
                            apiUrl: AppConfig.QWEN_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.auto_awesome,
                            title: 'Qwen Plus',
                            subtitle: '强大性能，均衡之选',
                            model: AppConfig.AI_MODEL_QWEN_PLUS,
                            apiUrl: AppConfig.QWEN_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.flash_on,
                            title: 'Qwen Turbo',
                            subtitle: '极速响应，高性价比',
                            model: AppConfig.AI_MODEL_QWEN_TURBO,
                            apiUrl: AppConfig.QWEN_API_URL,
                          ),

                          const SizedBox(height: 16),

                          // 🎯 智谱 GLM 系列
                          _buildModelCategoryHeader(context, '智谱 AI 国产旗舰'),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.flash_on,
                            title: 'GLM-4-Flash',
                            subtitle: '闪电响应，完全免费 ✨',
                            model: AppConfig.AI_MODEL_GLM_4_FLASH,
                            apiUrl: AppConfig.ZHIPU_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.stars,
                            title: 'GLM-4-Plus',
                            subtitle: '旗舰版本，智能强大',
                            model: AppConfig.AI_MODEL_GLM_4_PLUS,
                            apiUrl: AppConfig.ZHIPU_API_URL,
                          ),
                          Divider(height: 1, color: dividerColor),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.cloud,
                            title: 'GLM-4-Air',
                            subtitle: '轻量高效，快速部署',
                            model: AppConfig.AI_MODEL_GLM_4_AIR,
                            apiUrl: AppConfig.ZHIPU_API_URL,
                          ),

                          const SizedBox(height: 16),

                          // 🌙 Moonshot（Kimi）
                          _buildModelCategoryHeader(context, 'Moonshot AI'),
                          _buildModelSheetOption(
                            context,
                            appProvider,
                            appConfig,
                            icon: Icons.nightlight,
                            title: 'Kimi (128K)',
                            subtitle: '超长上下文，长文本专家',
                            model: AppConfig.AI_MODEL_MOONSHOT,
                            apiUrl: AppConfig.MOONSHOT_API_URL,
                          ),

                          const SizedBox(height: 16),

                          // 🎯 大厂标准：高级选项 - 自定义模型
                          _buildModelCategoryHeader(
                            context,
                            '高级选项 Advanced',
                          ),
                          _buildCustomModelOption(
                            context,
                            appProvider,
                            appConfig,
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
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig, {
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
    final isSelected = appConfig.aiModel == model;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _apiUrlController.text = apiUrl;
          });
          final updatedConfig = appConfig.copyWith(
            aiModel: model,
            aiApiUrl: apiUrl,
          );
          appProvider.updateConfig(updatedConfig);
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
                      ? primaryColor.withOpacity(0.15)
                      : (isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
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

  // 构建快捷操作卡片
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: subTextColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建测试连接按钮
  Widget _buildTestConnectionButton(BuildContext context, AppConfig appConfig) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _testConnection(appConfig),
        icon: const Icon(Icons.wifi_tethering, size: 20),
        label: const Text('测试API连接', style: TextStyle(fontSize: 15)),
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
  }

  // 构建底部提醒卡片
  Widget _buildHelpCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '温馨提示',
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
            '• 选择模型后会自动填充 API 地址\n'
            '• API 密钥仅存储在本地，不会上传\n'
            '• 支持所有兼容 OpenAI 格式的 AI 服务',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // 测试API连接
  Future<void> _testConnection(AppConfig appConfig) async {
    // 🔧 改进：使用当前输入框的值进行测试，而不是已保存的配置
    // 这样用户可以在保存前测试新配置，符合大厂最佳实践
    final currentApiUrl = _apiUrlController.text.trim();
    final currentApiKey = _apiKeyController.text.trim();

    if (currentApiUrl.isEmpty) {
      SnackBarUtils.showWarning(context, '请先输入API地址');
      return;
    }

    if (currentApiKey.isEmpty) {
      SnackBarUtils.showWarning(context, '请先输入API密钥');
      return;
    }

    // 显示加载提示
    if (mounted) {
      SnackBarUtils.showInfo(context, '正在测试连接...');
    }

    try {
      // 🎯 使用当前输入框的值创建临时配置进行测试
      final apiService = DeepSeekApiService(
        apiUrl: currentApiUrl,
        apiKey: currentApiKey,
        model: appConfig.aiModel, // 模型使用当前已选择的
      );

      final (success, error) = await apiService.testConnection();

      if (mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, 'API连接测试成功！请点击右上角保存配置');
        } else {
          SnackBarUtils.showError(context, error ?? '连接失败');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '测试失败: $e');
      }
    }
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
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
                        '快速上手',
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
                        question: '🔑 获取 API 密钥',
                        answer:
                            '推荐服务商（均兼容 OpenAI API 格式）：\n\n'
                            '• DeepSeek V3：platform.deepseek.com\n'
                            '  2025最新版本，性价比之王\n\n'
                            '• 智谱 GLM：open.bigmodel.cn\n'
                            '  GLM-4-Flash 完全免费 ✨\n\n'
                            '• 通义千问：dashscope.aliyun.com\n'
                            '  阿里旗舰，Qwen Max 性能强大\n\n'
                            '• Moonshot (Kimi)：platform.moonshot.cn\n'
                            '  支持 128K 超长上下文\n\n'
                            '• OpenAI：platform.openai.com\n'
                            '  o3-mini/o1 最新推理模型',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🎯 推荐配置（2025版）',
                        answer:
                            '免费首选：GLM-4-Flash\n'
                            '极致性价比：DeepSeek V3\n'
                            '最强推理：o3-mini / o1\n'
                            '国产旗舰：Qwen Max / GLM-4-Plus\n'
                            '长文本：Kimi (128K)',
                      ),
                      _buildFAQItem(
                        context,
                        question: '❌ 连接失败？',
                        answer:
                            '1. 检查 API 地址格式（需 https://）\n'
                            '2. 确认 API 密钥完整复制无误\n'
                            '3. 确保账户有余额（部分需充值）\n'
                            '4. OpenAI 需科学上网\n\n'
                            '使用"测试 API 连接"按钮快速诊断',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔧 高级功能',
                        answer:
                            '• 自定义模型：支持任意兼容 OpenAI 格式的模型\n'
                            '• 聚合服务：可配置 OpenRouter 等中转服务\n'
                            '• 自定义提示词：个性化 AI 输出风格\n'
                            '• API 地址可自定义（代理/自建服务）',
                      ),
                      _buildFAQItem(
                        context,
                        question: '🔒 安全说明',
                        answer:
                            'API 密钥仅存储在本地设备，不会上传到任何服务器。\n'
                            'AI 功能仅在你主动点击时调用，不会自动运行。',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.rocket_launch_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '新手推荐',
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
                              '1. GLM-4-Flash（免费）\n'
                              '2. DeepSeek V3（性价比）\n'
                              '3. 推理任务用 o3-mini / DeepSeek Reasoner',
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
                        AppLocalizationsSimple.of(context)?.enableCustomPrompts ?? '启用自定义提示词',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizationsSimple.of(context)?.customPrompts ?? '自定义AI洞察和点评的提示词',
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
                activeColor: AppTheme.primaryColor,
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
                    AppLocalizationsSimple.of(context)?.insightPrompt ?? '洞察提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.insightPromptHint ?? '自定义AI洞察的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
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
                      hintText: localizations?.insightPromptHint ?? '自定义AI洞察的提示词，留空使用默认提示词',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.reviewPromptHint ?? '自定义AI点评的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
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
                      hintText: localizations?.reviewPromptHint ?? '自定义AI点评的提示词，留空使用默认提示词',
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
                    AppLocalizationsSimple.of(context)?.continuationPrompt ?? '续写提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.continuationPromptHint ?? '自定义AI续写的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
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
                      hintText: localizations?.continuationPromptHint ?? '自定义AI续写的提示词，留空使用默认提示词',
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
                    AppLocalizationsSimple.of(context)?.tagInsightPrompt ?? '标签洞察提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.tagInsightPromptHint ?? '自定义标签洞察的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
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
                      hintText: localizations?.tagInsightPromptHint ?? '自定义标签洞察的提示词，留空使用默认提示词',
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
                    AppLocalizationsSimple.of(context)?.tagRecommendationPrompt ?? '标签推荐提示词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 🎯 大厂标准：明确说明作用范围
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            localizations?.tagRecommendationPromptHint ?? '自定义标签推荐的提示词，留空使用默认提示词',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withOpacity(0.7),
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
                      hintText: localizations?.tagRecommendationPromptHint ?? '自定义标签推荐的提示词，留空使用默认提示词',
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
    if (apiKey.isEmpty) return null;
    
    // 移除所有不可见字符（空格、换行、制表符等）
    var cleaned = apiKey.replaceAll(RegExp(r'\s'), '');
    
    // 检查是否包含非 ASCII 字符
    if (cleaned.runes.any((rune) => rune > 127)) {
      throw FormatException('API Key 包含非法字符，请重新复制粘贴');
    }
    
    // 检查是否为空
    if (cleaned.isEmpty) {
      throw FormatException('API Key 不能为空');
    }
    
    return cleaned;
  }

  // 保存设置
  Future<void> _saveSettings(AppProvider appProvider) async {
    final apiUrl = _apiUrlController.text.trim();
    var apiKey = _apiKeyController.text.trim();

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
      
      // 🔧 清理和验证 API Key
      try {
        apiKey = _cleanAndValidateApiKey(apiKey) ?? '';
      } catch (e) {
        SnackBarUtils.showError(context, e.toString());
        return;
      }
    }

    // 保存配置
    final customInsightPrompt = _customInsightPromptController.text.trim();
    final customReviewPrompt = _customReviewPromptController.text.trim();
    final customContinuationPrompt = _customContinuationPromptController.text.trim();
    final customTagInsightPrompt = _customTagInsightPromptController.text.trim();
    final customTagRecommendationPrompt = _customTagRecommendationPromptController.text.trim();

    final updatedConfig = appProvider.appConfig.copyWith(
      aiApiUrl: apiUrl.isEmpty ? null : apiUrl,
      aiApiKey: apiKey.isEmpty ? null : apiKey,
      customInsightPrompt:
          customInsightPrompt.isEmpty ? null : customInsightPrompt,
      customReviewPrompt:
          customReviewPrompt.isEmpty ? null : customReviewPrompt,
      customContinuationPrompt:
          customContinuationPrompt.isEmpty ? null : customContinuationPrompt,
      customTagInsightPrompt:
          customTagInsightPrompt.isEmpty ? null : customTagInsightPrompt,
      customTagRecommendationPrompt:
          customTagRecommendationPrompt.isEmpty ? null : customTagRecommendationPrompt,
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

  // 🎯 大厂标准：判断是否为预设模型（2025最新版本）
  bool _isPresetModel(String model) {
    const presetModels = [
      // DeepSeek V3系列
      AppConfig.AI_MODEL_DEEPSEEK,
      AppConfig.AI_MODEL_DEEPSEEK_REASONER,
      // OpenAI 2025系列
      AppConfig.AI_MODEL_O3_MINI,
      AppConfig.AI_MODEL_O1,
      AppConfig.AI_MODEL_O1_MINI,
      AppConfig.AI_MODEL_GPT4O,
      AppConfig.AI_MODEL_GPT4O_MINI,
      // 通义千问系列
      AppConfig.AI_MODEL_QWEN_MAX,
      AppConfig.AI_MODEL_QWEN_PLUS,
      AppConfig.AI_MODEL_QWEN_TURBO,
      // 智谱GLM系列
      AppConfig.AI_MODEL_GLM_4_FLASH,
      AppConfig.AI_MODEL_GLM_4_PLUS,
      AppConfig.AI_MODEL_GLM_4_AIR,
      // Moonshot
      AppConfig.AI_MODEL_MOONSHOT,
    ];
    return presetModels.contains(model);
  }

  // 🎯 大厂标准：自定义模型选项（渐进式披露）
  Widget _buildCustomModelOption(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    // 🔍 判断当前是否使用自定义模型
    final isCustomModel = !_isPresetModel(appConfig.aiModel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomModelDialog(context, appProvider, appConfig),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // 图标容器
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCustomModel
                      ? primaryColor.withOpacity(0.15)
                      : (isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: isCustomModel ? primaryColor : secondaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // 文本内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自定义模型',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isCustomModel ? FontWeight.w600 : FontWeight.normal,
                        color: isCustomModel ? primaryColor : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCustomModel
                          ? '当前：${appConfig.aiModel}'
                          : '输入任意兼容 OpenAI API 的模型',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 箭头或选中图标
              Icon(
                isCustomModel ? Icons.check_circle : Icons.chevron_right,
                color: isCustomModel ? primaryColor : secondaryColor,
                size: isCustomModel ? 24 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 大厂标准：自定义模型输入对话框
  void _showCustomModelDialog(
    BuildContext context,
    AppProvider appProvider,
    AppConfig appConfig,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    // 初始化输入框：如果当前是自定义模型则显示，否则为空
    final customModelController = TextEditingController(
      text: _isPresetModel(appConfig.aiModel) ? '' : appConfig.aiModel,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '自定义模型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文字
            Text(
              '输入任意兼容 OpenAI API 格式的模型名称',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // 输入框
            TextField(
              controller: customModelController,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'gpt-4o-2024-08-06',
                hintStyle: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  Icons.code,
                  color: textColor.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 提示信息卡片
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '提示',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '请确保你的 API 服务商支持该模型，并已正确配置 API 地址',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 示例
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: textColor.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  '示例',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'claude-3-5-sonnet, o1-mini',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.4),
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: textColor.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              AppLocalizationsSimple.of(context)?.cancel ?? '取消',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          // 确定按钮
          ElevatedButton(
            onPressed: () {
              final customModel = customModelController.text.trim();
              if (customModel.isEmpty) {
                SnackBarUtils.showWarning(
                  context,
                  '请输入模型名称',
                );
                return;
              }

              // 更新配置
              setState(() {
                // 自定义模型不自动改变 API URL，让用户自己配置
              });

              final updatedConfig = appConfig.copyWith(
                aiModel: customModel,
              );
              appProvider.updateConfig(updatedConfig);

              Navigator.of(dialogContext).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 关闭模型选择器

              SnackBarUtils.showSuccess(
                context,
                '已设置自定义模型：$customModel',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              AppLocalizationsSimple.of(context)?.confirm ?? '确定',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
    );
  }
}
