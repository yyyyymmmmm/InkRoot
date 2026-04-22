import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/services/umeng_analytics_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// 隐私政策页面（大厂标准：首次安装时全屏显示）
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final textPrimary = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final textSecondary = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏（大厂标准：简洁优雅）
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryLightColor,
                          AppTheme.primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 标题
                  Text(
                    '欢迎使用 InkRoot',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // 副标题
                  Text(
                    '请仔细阅读并同意以下协议',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 隐私政策内容（可滚动）
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Center(
                        child: Text(
                          '用户协议与隐私政策',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 开场白
                      _buildContentText(
                        '欢迎使用 InkRoot（墨鸣笔记）！\n\n'
                        '我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。我们致力于维持您对我们的信任，恪守以下原则，保护您的个人信息：权责一致原则、目的明确原则、选择同意原则、最少够用原则、确保安全原则、主体参与原则、公开透明原则等。同时，我们承诺将按业界成熟的安全标准，采取相应的安全保护措施来保护您的个人信息。\n\n'
                        '请在使用我们的产品或服务前，仔细阅读并充分理解本《用户协议》和《隐私政策》。',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('一、我们如何收集和使用您的信息', textPrimary),
                      const SizedBox(height: 12),
                      
                      _buildSubsectionTitle('1.1 笔记数据', textPrimary),
                      const SizedBox(height: 8),
                      _buildContentText(
                        '• 您创建的所有笔记内容仅存储在您的设备本地数据库中\n'
                        '• 如果您配置了 Memos 服务器或 WebDAV，笔记会同步到您自己的服务器\n'
                        '• 我们不会收集、上传或存储您的任何笔记内容\n'
                        '• 您对笔记数据拥有完全的控制权',
                        textSecondary,
                      ),
                      const SizedBox(height: 16),

                      _buildSubsectionTitle('1.2 账号信息', textPrimary),
                      const SizedBox(height: 8),
                      _buildContentText(
                        '• 服务器地址、用户名：用于连接您配置的 Memos 服务器\n'
                        '• 登录凭证：使用系统级加密存储（iOS Keychain / Android Keystore）\n'
                        '• 所有账号信息仅存储在您的设备本地，不会上传到我们的服务器',
                        textSecondary,
                      ),
                      const SizedBox(height: 16),

                      _buildSubsectionTitle('1.3 使用统计信息', textPrimary),
                      const SizedBox(height: 8),
                      _buildContentText(
                        Platform.isIOS
                            ? '• iOS版本：我们不收集任何使用统计信息\n'
                              '• 所有数据仅存储在您的设备本地\n'
                              '• 如需崩溃诊断，请通过"设置-帮助与反馈"主动发送日志'
                            : '为了提升产品体验和稳定性，我们会通过第三方统计工具收集以下匿名化信息：\n\n'
                              '• 设备信息：操作系统版本、设备型号、应用版本\n'
                              '• 使用统计：应用启动次数、功能使用频率、页面访问情况\n'
                              '• 崩溃日志：应用崩溃时的技术信息，不包含您的笔记内容\n\n'
                              '这些信息均经过匿名化处理，无法识别您的个人身份。',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('二、我们如何保护您的信息', textPrimary),
                      const SizedBox(height: 12),
                      _buildContentText(
                        '• 本地优先：采用"本地优先"架构，所有数据默认存储在本地\n'
                        '• 加密存储：敏感信息使用系统级加密存储技术\n'
                        '• 最小权限：仅申请必要的系统权限（存储、通知等）\n'
                        '• 开源透明：核心功能代码开源，接受社区监督\n'
                        '• 数据控制：您可以随时导出、删除所有数据',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('三、第三方服务说明', textPrimary),
                      const SizedBox(height: 12),
                      _buildContentText(
                        Platform.isIOS
                            ? 'iOS版本不集成任何第三方统计SDK，确保您的隐私安全。\n\n'
                              '• 不使用友盟统计\n'
                              '• 不使用Firebase性能监控\n'
                              '• 不使用Sentry错误追踪\n'
                              '• 仅使用Apple官方提供的基础框架'
                            : '为了提供更好的服务，Android版本集成了以下第三方SDK：\n\n'
                              '• 友盟统计（UMeng）：应用使用统计和崩溃分析\n'
                              '  - 收集信息：设备信息、应用使用统计\n'
                              '  - 隐私政策：https://www.umeng.com/page/policy\n\n'
                              '• Sentry：错误追踪和性能监控\n'
                              '  - 收集信息：崩溃日志、性能数据\n'
                              '  - 隐私政策：https://sentry.io/privacy/',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('四、您的权利', textPrimary),
                      const SizedBox(height: 12),
                      _buildContentText(
                        '• 访问权：查看您存储在应用中的所有数据\n'
                        '• 导出权：随时导出您的所有笔记数据\n'
                        '• 删除权：删除部分或全部笔记数据\n'
                        '• 撤回权：在设置中关闭统计功能\n'
                        '• 注销权：卸载应用即可清除所有本地数据',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('五、未成年人保护', textPrimary),
                      const SizedBox(height: 12),
                      _buildContentText(
                        '我们非常重视未成年人的个人信息保护。若您是未满18周岁的未成年人，请在监护人的陪同下阅读本政策，并在征得监护人同意后使用我们的服务。',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('六、本政策的更新', textPrimary),
                      const SizedBox(height: 12),
                      _buildContentText(
                        '我们可能会适时修订本政策内容。如该等变更会导致您在本政策项下权利的实质减损，我们将在变更生效前，通过应用内通知等显著方式告知您。',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('七、联系我们', textPrimary),
                      const SizedBox(height: 12),
                      _buildContentText(
                        '如果您对本政策有任何疑问、意见或建议，请通过以下方式联系我们：\n\n'
                        '邮箱：${AppConfig.supportEmail}\n'
                        '官方网站：${AppConfig.officialWebsite}\n'
                        '反馈入口：应用内"设置 - 帮助与反馈"\n\n'
                        '我们将在15个工作日内回复您的请求。',
                        textSecondary,
                      ),
                      const SizedBox(height: 24),

                      // 生效日期
                      Center(
                        child: Text(
                          '本政策自2025年1月1日起生效',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 完整协议链接
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _openPrivacyPolicyUrl(),
                          icon: Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          label: Text(
                            '查看完整版《用户协议》和《隐私政策》',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 底部按钮（大厂标准：现代渐变设计）
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 同意按钮
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _handleAgree(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryLightColor,
                              AppTheme.primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            '同意并继续',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 提示文字（大厂标准：温馨提示）
                  Text(
                    '如不同意，请关闭应用',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildSubsectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildContentText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: color,
      ),
    );
  }

  Future<void> _handleAgree(BuildContext context) async {
    final preferencesService = PreferencesService();
    
    // 保存同意状态
    await preferencesService.setPrivacyPolicyAgreed(true);
    
    // 初始化友盟统计（仅在同意后初始化）
    await UmengAnalyticsService.init();
    await UmengAnalyticsService.onAppStart();
    
    debugPrint('✅ 用户已同意隐私政策');
    
    // 检查是否首次启动
    final isFirstLaunch = await preferencesService.isFirstLaunch();
    
    if (context.mounted) {
      if (isFirstLaunch) {
        // 首次启动 → 引导页
        context.go('/onboarding');
      } else {
        // 后续启动 → 主界面
        context.go('/');
      }
    }
  }

  /// 打开完整版隐私政策和用户协议网页
  Future<void> _openPrivacyPolicyUrl() async {
    final Uri privacyUrl = Uri.parse(AppConfig.privacyPolicyUrl);
    final Uri agreementUrl = Uri.parse(AppConfig.userAgreementUrl);
    
    // 先尝试打开隐私政策
    if (await canLaunchUrl(privacyUrl)) {
      await launchUrl(
        privacyUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('⚠️  无法打开隐私政策链接: ${AppConfig.privacyPolicyUrl}');
    }
  }

}
