import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _feedbackController = TextEditingController();

  int _selectedTypeIndex = 0;
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _getFeedbackTypes(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    return [
      l10n?.featureSuggestion ?? '功能建议',
      l10n?.problemReport ?? '问题反馈',
      l10n?.uiOptimization ?? '界面优化',
      l10n?.performanceIssue ?? '性能问题',
      l10n?.other ?? '其他',
    ];
  }

  List<Map<String, dynamic>> _getQuickFeedbacks(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    return [
      {
        'text': l10n?.uiBeautiful ?? '界面很漂亮，体验很棒！',
        'icon': Icons.thumb_up_rounded,
        'color': Colors.green,
      },
      {
        'text': l10n?.moreTemplates ?? '希望增加更多笔记模板',
        'icon': Icons.extension_rounded,
        'color': Colors.blue,
      },
      {
        'text': l10n?.fasterSync ?? '同步速度可以更快一些',
        'icon': Icons.speed_rounded,
        'color': Colors.orange,
      },
      {
        'text': l10n?.moreFormats ?? '希望支持更多文件格式',
        'icon': Icons.file_present_rounded,
        'color': Colors.purple,
      },
    ];
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _contactController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 构建邮件内容
      final feedbackTypes = _getFeedbackTypes(context);
      final subject = Uri.encodeComponent(
        'InkRoot 用户反馈 - ${feedbackTypes[_selectedTypeIndex]}',
      );
      final body = Uri.encodeComponent('''
亲爱的开发团队，

反馈类型：${feedbackTypes[_selectedTypeIndex]}
联系方式：${_contactController.text}

反馈内容：
${_feedbackController.text}

---
来自 InkRoot 应用的用户反馈
发送时间：${DateTime.now().toString().split('.')[0]}
''');

      final emailUrl =
          'mailto:${AppConfig.supportEmail}?subject=$subject&body=$body';

      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));

        // 显示成功提示
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        // 如果无法打开邮件客户端，复制到剪贴板
        _copyToClipboard();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizationsSimple.of(context)?.feedbackFailed ??
              '发送失败，已为您复制反馈内容到剪贴板',
        );
        _copyToClipboard();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    final feedbackTypes = _getFeedbackTypes(context);
    final content = '''
反馈类型：${feedbackTypes[_selectedTypeIndex]}
联系方式：${_contactController.text}
反馈内容：${_feedbackController.text}

开发团队邮箱：${AppConfig.supportEmail}
''';

    Clipboard.setData(ClipboardData(text: content));
    SnackBarUtils.showSuccess(
      context,
      '${AppLocalizationsSimple.of(context)?.feedbackCopied ?? '反馈内容已复制到剪贴板\n您可以直接发送到：'}${AppConfig.supportEmail}',
    );
  }

  void _showSuccessDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: ResponsiveUtils.responsivePadding(context, all: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成功图标
            Container(
              width: ResponsiveUtils.responsiveIconSize(context, 80),
              height: ResponsiveUtils.responsiveIconSize(context, 80),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: ResponsiveUtils.responsiveIconSize(context, 50),
                color: Colors.green,
              ),
            ),

            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 20)),

            Text(
              AppLocalizationsSimple.of(context)?.feedbackSuccess ?? '反馈发送成功！',
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),

            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),

            Text(
              AppLocalizationsSimple.of(context)?.feedbackSuccessMessage ??
                  '感谢您的宝贵意见！\n我们会认真考虑您的建议，\n并在后续版本中进行优化。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 24)),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      ResponsiveUtils.responsivePadding(context, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizationsSimple.of(context)?.complete ?? '完成',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(isDarkMode),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);
    
    return AppBar(
        title: Text(
          AppLocalizationsSimple.of(context)?.feedbackTitle ?? '意见反馈',
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
          ),
        ),
        backgroundColor:
            isDarkMode ? AppTheme.darkBackgroundColor : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isDesktop ? null : IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            size: ResponsiveUtils.responsiveIconSize(context, 20),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _copyToClipboard,
            child: Text(
              AppLocalizationsSimple.of(context)?.copyEmail ?? '复制邮箱',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildBody(bool isDarkMode) => SingleChildScrollView(
        padding: ResponsiveUtils.responsivePadding(context, all: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(isDarkMode),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 24)),
              _buildQuickFeedbacks(isDarkMode),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 24)),
              _buildFeedbackTypeSelector(isDarkMode),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 20)),
              _buildContactField(isDarkMode),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 20)),
              _buildFeedbackField(isDarkMode),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
              _buildSubmitButton(isDarkMode),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 16)),
              _buildFooterInfo(isDarkMode),
            ],
          ),
        ),
      );

  Widget _buildWelcomeCard(bool isDarkMode) => Container(
        width: double.infinity,
        padding: ResponsiveUtils.responsivePadding(context, all: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryLightColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: ResponsiveUtils.responsivePadding(context, all: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.primaryColor,
                    size: ResponsiveUtils.responsiveIconSize(context, 20),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 12)),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.yourOpinionMatters ??
                        '您的意见很重要',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.responsiveFontSize(context, 18),
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),
            Text(
              AppLocalizationsSimple.of(context)?.feedbackWelcome ??
                  '我们致力于为您提供最好的体验。您的每一个建议和反馈，都是我们前进的动力！',
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickFeedbacks(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizationsSimple.of(context)?.quickFeedback ?? '快速反馈',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),
          Wrap(
            spacing: ResponsiveUtils.responsiveSpacing(context, 8),
            runSpacing: ResponsiveUtils.responsiveSpacing(context, 8),
            children: _getQuickFeedbacks(context)
                .map(
                  (feedback) => _buildQuickFeedbackChip(
                    feedback['text'],
                    feedback['icon'],
                    feedback['color'],
                    isDarkMode,
                  ),
                )
                .toList(),
          ),
        ],
      );

  Widget _buildQuickFeedbackChip(
    String text,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) =>
      InkWell(
        onTap: () {
          _feedbackController.text = text;
          _selectedTypeIndex = 0;
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: ResponsiveUtils.responsivePadding(
            context,
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.responsiveIconSize(context, 16),
                color: color,
              ),
              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 6)),
              Text(
                text,
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 12),
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFeedbackTypeSelector(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizationsSimple.of(context)?.feedbackTypeRequired ?? '反馈类型',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkCardColor : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: DropdownButton<int>(
              value: _selectedTypeIndex,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(
                Icons.expand_more_rounded,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              padding: ResponsiveUtils.responsivePadding(
                context,
                horizontal: 16,
                vertical: 4,
              ),
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
                color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
              dropdownColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
              items: _getFeedbackTypes(context)
                  .asMap()
                  .entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTypeIndex = value;
                  });
                }
              },
            ),
          ),
        ],
      );

  Widget _buildContactField(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizationsSimple.of(context)?.contactMethod ?? '联系方式',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 8)),
          TextFormField(
            controller: _contactController,
            decoration: InputDecoration(
              hintText:
                  AppLocalizationsSimple.of(context)?.enterEmailOrWechat ??
                      '请输入您的邮箱或微信号（选填）',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
              ),
              filled: true,
              fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: ResponsiveUtils.responsivePadding(
                context,
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.contact_mail_rounded,
                color: isDarkMode ? Colors.white54 : Colors.black54,
                size: ResponsiveUtils.responsiveIconSize(context, 20),
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
            ),
          ),
        ],
      );

  Widget _buildFeedbackField(bool isDarkMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizationsSimple.of(context)?.feedbackContentRequired ??
                    '反馈内容',
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 8)),
          TextFormField(
            controller: _feedbackController,
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizationsSimple.of(context)
                        ?.enterFeedbackContent ??
                    '请输入您的反馈内容';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: AppLocalizationsSimple.of(context)
                      ?.feedbackContentPlaceholder ??
                  '请详细描述您遇到的问题或建议...\n\n我们会认真阅读每一条反馈，并尽快回复您。',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
              ),
              filled: true,
              fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
              contentPadding:
                  ResponsiveUtils.responsivePadding(context, all: 16),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
              height: 1.5,
            ),
          ),
        ],
      );

  Widget _buildSubmitButton(bool isDarkMode) => SizedBox(
        width: double.infinity,
        height: ResponsiveUtils.responsive<double>(
          context,
          mobile: 52,
          tablet: 56,
          desktop: 60,
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: ResponsiveUtils.responsiveIconSize(context, 20),
                      height: ResponsiveUtils.responsiveIconSize(context, 20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.responsiveSpacing(context, 12),
                    ),
                    Text(
                      AppLocalizationsSimple.of(context)?.sending ?? '发送中...',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.responsiveFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      size: ResponsiveUtils.responsiveIconSize(context, 20),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.responsiveSpacing(context, 8),
                    ),
                    Text(
                      AppLocalizationsSimple.of(context)?.sendFeedback ??
                          '发送反馈',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.responsiveFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      );

  Widget _buildFooterInfo(bool isDarkMode) => Container(
        padding: ResponsiveUtils.responsivePadding(context, all: 16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppTheme.darkCardColor.withOpacity(0.5)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.email_rounded,
                  size: ResponsiveUtils.responsiveIconSize(context, 16),
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 8)),
                Text(
                  '${AppLocalizationsSimple.of(context)?.developerEmail ?? '开发团队邮箱：'}${AppConfig.supportEmail}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, 12),
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 8)),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: ResponsiveUtils.responsiveIconSize(context, 16),
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 8)),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.feedbackResponseTime ??
                        '我们会在 1-3 个工作日内回复您的反馈',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.responsiveFontSize(context, 12),
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
