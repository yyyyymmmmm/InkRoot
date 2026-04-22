import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/text_style_helper.dart';

class LaboratoryScreen extends StatefulWidget {
  const LaboratoryScreen({super.key});

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor =
        isDarkMode ? AppTheme.darkTextSecondaryColor : Colors.grey[600];
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isDesktop ? null : IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : null,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizationsSimple.of(context)?.laboratory ?? '实验室',
          style: AppTextStyles.custom(
            context,
            17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部介绍卡片
            _buildHeaderCard(isDarkMode, textColor, secondaryTextColor),

            const SizedBox(height: 24),

            // 已发布功能
            _buildSectionHeader(
              AppLocalizationsSimple.of(context)?.releasedFeatures ?? '已发布功能',
              Icons.check_circle,
              Colors.green,
              textColor,
            ),
            const SizedBox(height: 12),
            _buildReleasedFeatures(isDarkMode, textColor, secondaryTextColor),

            const SizedBox(height: 32),

            // 开发中功能
            _buildSectionHeader(
              AppLocalizationsSimple.of(context)?.developingFeatures ?? '开发中功能',
              Icons.build,
              Colors.orange,
              textColor,
            ),
            const SizedBox(height: 12),
            _buildDevelopingFeatures(isDarkMode, textColor, secondaryTextColor),

            const SizedBox(height: 32),

            // 底部提示
            _buildFooterTip(isDarkMode, secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    bool isDarkMode,
    Color textColor,
    Color? secondaryTextColor,
  ) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.indigo[800]!.withOpacity(0.4),
                    Colors.purple[800]!.withOpacity(0.4),
                  ]
                : [Colors.indigo[50]!, Colors.purple[50]!],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.indigo[700]!.withOpacity(0.3)
                : Colors.indigo[100]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.indigo[700]!.withOpacity(0.5)
                    : Colors.indigo[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.science_outlined,
                color: isDarkMode ? Colors.indigo[200] : Colors.indigo[700],
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizationsSimple.of(context)?.laboratory ?? '实验室',
              style: AppTextStyles.headlineSmall(
                context,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppLocalizationsSimple.of(context)?.exploring ??
                    '探索前沿功能，体验创新特性',
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(
                  context,
                  14,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    Color textColor,
  ) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.titleLarge(
              context,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      );

  Widget _buildReleasedFeatures(
    bool isDarkMode,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.grey[50]!;

    return Column(
      children: [
        // Telegram 助手
        _buildModernFeatureCard(
          context: context,
          icon: Icons.telegram,
          iconColor: Colors.blue,
          title:
              AppLocalizationsSimple.of(context)?.telegramBot ?? 'Telegram 助手',
          subtitle: AppLocalizationsSimple.of(context)?.telegramBotDesc ??
              '连接 InkRoot_Bot，实现跨平台笔记同步',
          status: AppLocalizationsSimple.of(context)?.stableRunning ?? '稳定运行',
          statusColor: Colors.green,
          cardColor: cardColor,
          onTap: () => _showTelegramBotDialog(context),
          isDarkMode: isDarkMode,
        ),

        const SizedBox(height: 12),

        // 语音转文字
        _buildModernFeatureCard(
          context: context,
          icon: Icons.mic_outlined,
          iconColor: Colors.purple,
          title: AppLocalizationsSimple.of(context)?.voiceToText ?? '语音转文字',
          subtitle: AppLocalizationsSimple.of(context)?.voiceToTextDesc ??
              '语音录制自动转换为文字笔记',
          status: AppLocalizationsSimple.of(context)?.stableRunning ?? '稳定运行',
          statusColor: Colors.green,
          cardColor: cardColor,
          onTap: () => _showSpeechToTextTutorial(context),
          isDarkMode: isDarkMode,
        ),

        const SizedBox(height: 12),

        // AI 智能助手（合并3个功能）
        _buildModernFeatureCard(
          context: context,
          icon: Icons.auto_awesome,
          iconColor: isDarkMode ? Colors.purple[300]! : Colors.purple[600]!,
          title: AppLocalizationsSimple.of(context)?.aiSmartAssistant ??
              'AI 智能助手',
          subtitle: AppLocalizationsSimple.of(context)?.aiSmartAssistantDesc ??
              '相关笔记推荐、智能续写、标签生成、内容摘要',
          status: AppLocalizationsSimple.of(context)?.featureCompleted ??
              'Completed',
          statusColor: Colors.green,
          cardColor: cardColor,
          onTap: () => _showAIFeaturesDialog(context),
          isDarkMode: isDarkMode,
          isNew: true,
        ),

        const SizedBox(height: 12),

        // 批注功能（新增）
        _buildModernFeatureCard(
          context: context,
          icon: Icons.comment_outlined,
          iconColor: isDarkMode ? Colors.orange[300]! : Colors.orange[600]!,
          title: AppLocalizationsSimple.of(context)?.noteAnnotation ??
              '笔记批注',
          subtitle: AppLocalizationsSimple.of(context)?.noteAnnotationDesc ??
              '为笔记添加评论、问题、想法等批注信息',
          status: AppLocalizationsSimple.of(context)?.testing ?? '测试中',
          statusColor: Colors.orange,
          cardColor: cardColor,
          onTap: () => _showAnnotationFeatureDialog(context),
          isDarkMode: isDarkMode,
          isNew: true,
        ),
      ],
    );
  }

  Widget _buildDevelopingFeatures(
    bool isDarkMode,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.grey[50]!;

    return Column(
      children: [
        // 微信小助手
        _buildModernFeatureCard(
          context: context,
          icon: Icons.wechat,
          iconColor: isDarkMode ? Colors.green[300]! : Colors.green[600]!,
          title: AppLocalizationsSimple.of(context)?.wechatAssistant ??
              'WeChat Assistant',
          subtitle: AppLocalizationsSimple.of(context)?.wechatAssistantDesc ??
              'Record notes via WeChat',
          status: AppLocalizationsSimple.of(context)?.inDevelopment ??
              'In Development',
          statusColor: Colors.orange,
          cardColor: cardColor,
          onTap: () => _showComingSoonDialog(
            context,
            AppLocalizationsSimple.of(context)?.wechatAssistant ??
                'WeChat Assistant',
          ),
          isDarkMode: isDarkMode,
          isNew: true,
          isDeveloping: true,
        ),
      ],
    );
  }

  Widget _buildModernFeatureCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required Color cardColor,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isNew = false,
    bool isDeveloping = false,
  }) {
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor =
        isDarkMode ? AppTheme.darkTextSecondaryColor : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 图标容器
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // 内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.custom(
                                context,
                                16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          // 状态标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              status,
                              style: AppTextStyles.labelMedium(
                                context,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          // 新功能标签
                          if (isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red[400]!, Colors.pink[400]!],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NEW',
                                style: AppTextStyles.labelSmall(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.custom(
                          context,
                          14,
                          color: secondaryTextColor,
                          height: 1.3,
                        ),
                      ),
                      // 开发进度指示器
                      if (isDeveloping) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizationsSimple.of(context)
                                      ?.expectedNextRelease ??
                                  '预计下个版本发布',
                              style: AppTextStyles.labelMedium(
                                context,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 箭头
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: secondaryTextColor?.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterTip(bool isDarkMode, Color? secondaryTextColor) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.amber[900]?.withOpacity(0.2)
              : Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.amber[800]!.withOpacity(0.3)
                : Colors.amber[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.amber[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizationsSimple.of(context)?.laboratory ?? '实验室',
                    style: AppTextStyles.bodyMedium(
                      context,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizationsSimple.of(context)?.experimentalNotice ??
                        '实验室功能可能不稳定，使用前请备份重要数据。我们会根据用户反馈不断改进这些功能。',
                    style: AppTextStyles.caption(
                      context,
                      color: secondaryTextColor,
                    ).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _showTelegramBotDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.telegram,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizationsSimple.of(context)?.telegramBot ??
                    'Telegram 助手',
                style: AppTextStyles.custom(
                  context,
                  18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizationsSimple.of(context)?.telegramBotDialogContent ??
              '在 Telegram 中搜索 @InkRoot_Bot，连接机器人后即可发送消息自动创建笔记。支持 Markdown 格式，实时同步到 InkRoot 应用。',
          style: AppTextStyles.custom(
            context,
            14,
            color: textColor.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizationsSimple.of(context)?.understood ?? 'Got it',
              style: AppTextStyles.custom(
                context,
                14,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureDetailDialog(
    BuildContext context,
    String featureName,
    String description,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                featureName,
                style: AppTextStyles.custom(
                  context,
                  18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: AppTextStyles.custom(
            context,
            14,
            color: textColor.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizationsSimple.of(context)?.understood ?? 'Got it',
              style: AppTextStyles.custom(
                context,
                14,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.schedule,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                featureName,
                style: AppTextStyles.custom(
                  context,
                  18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizationsSimple.of(context)?.featureInDevelopment ??
              '功能正在开发中，敬请期待！',
          style: AppTextStyles.custom(
            context,
            14,
            color: textColor.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizationsSimple.of(context)?.understood ?? 'Got it',
              style: AppTextStyles.custom(
                context,
                14,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示语音转文字教程
  void _showSpeechToTextTutorial(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.mic_outlined,
              color: Colors.purple,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizationsSimple.of(context)?.voiceToText ??
                    '语音转文字',
                style: AppTextStyles.custom(
                  context,
                  18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizationsSimple.of(context)?.voiceToTextDialogContent ??
              '在笔记编辑器中点击麦克风按钮即可开始语音识别。支持离线识别，无需联网。识别过程中可随时暂停和继续，文字将自动插入到编辑器中。',
          style: AppTextStyles.custom(
            context,
            14,
            color: textColor.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizationsSimple.of(context)?.understood ?? 'Got it',
              style: AppTextStyles.custom(
                context,
                14,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示AI功能详情对话框
  void _showAIFeaturesDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: isDarkMode ? Colors.purple[300] : Colors.purple[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizationsSimple.of(context)?.aiSmartAssistant ??
                    'AI 智能助手',
                style: AppTextStyles.custom(
                  context,
                  18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.aiAssistantFeatures ??
                    'AI 智能助手包含以下功能：',
                style: AppTextStyles.custom(
                  context,
                  14,
                  color: textColor.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.relatedNotesRecommend ??
                    '📌 相关笔记推荐',
                AppLocalizationsSimple.of(context)?.relatedNotesDesc ??
                    '基于笔记内容智能推荐相关笔记',
                textColor,
              ),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.smartContinueWriting ??
                    '✍️ 智能续写',
                AppLocalizationsSimple.of(context)?.smartContinueWritingDesc ??
                    '根据上下文智能续写笔记内容',
                textColor,
              ),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.tagGeneration ??
                    '🏷️ 标签生成',
                AppLocalizationsSimple.of(context)?.tagGenerationDesc ??
                    '自动分析笔记内容生成相关标签',
                textColor,
              ),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.contentSummary ??
                    '📝 内容摘要',
                AppLocalizationsSimple.of(context)?.contentSummaryDesc ??
                    '快速生成笔记内容摘要',
                textColor,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizationsSimple.of(context)?.aiAssistantTip ??
                    '💡 提示：在笔记详情页点击右下角魔法棒图标即可使用',
                style: AppTextStyles.custom(
                  context,
                  13,
                  color: isDarkMode ? Colors.purple[300] : Colors.purple[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizationsSimple.of(context)?.understood ?? 'Got it',
              style: AppTextStyles.custom(
                context,
                14,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示批注功能详情对话框
  void _showAnnotationFeatureDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.comment_outlined,
              color: isDarkMode ? Colors.orange[300] : Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizationsSimple.of(context)?.noteAnnotation ??
                    '笔记批注',
                style: AppTextStyles.custom(
                  context,
                  18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 功能介绍
              Text(
                AppLocalizationsSimple.of(context)?.annotationIntro ??
                    '为笔记添加批注，记录你的想法、问题和评论：',
                style: AppTextStyles.custom(
                  context,
                  14,
                  color: textColor.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.annotationComment ??
                    '💬 评论',
                AppLocalizationsSimple.of(context)?.annotationCommentDesc ??
                    '添加对笔记内容的评论和反思',
                textColor,
              ),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.annotationQuestion ??
                    '❓ 问题',
                AppLocalizationsSimple.of(context)?.annotationQuestionDesc ??
                    '记录阅读时产生的疑问',
                textColor,
              ),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.annotationIdea ??
                    '💡 想法',
                AppLocalizationsSimple.of(context)?.annotationIdeaDesc ??
                    '记录灵感和新想法',
                textColor,
              ),
              _buildAIFeatureItem(
                context,
                AppLocalizationsSimple.of(context)?.annotationImportant ??
                    '⚠️ 重要',
                AppLocalizationsSimple.of(context)?.annotationImportantDesc ??
                    '标记重要信息和关键点',
                textColor,
              ),
              const SizedBox(height: 16),
              // 警告提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizationsSimple.of(context)?.annotationWarning ??
                            '⚠️ 功能暂时不稳定，请自行斟酌使用。批注数据仅保存在本地，不会同步到服务器。',
                        style: AppTextStyles.custom(
                          context,
                          13,
                          color: Colors.orange,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizationsSimple.of(context)?.annotationUsageTip ??
                    '💡 使用方法：在笔记列表或详情页点击批注图标 🟠 即可查看和管理批注',
                style: AppTextStyles.custom(
                  context,
                  13,
                  color: textColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizationsSimple.of(context)?.iKnow ?? '我知道了',
              style: AppTextStyles.custom(
                context,
                14,
                color: isDarkMode
                    ? AppTheme.primaryLightColor
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建AI功能项
  Widget _buildAIFeatureItem(
    BuildContext context,
    String title,
    String description,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.custom(
              context,
              14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.custom(
                context,
                13,
                color: textColor.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
