import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';

class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.grey.shade50;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final accentColor = isDarkMode ? AppTheme.primaryLightColor : Colors.teal;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizationsSimple.of(context)?.userAgreement ?? '用户协议',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Center(
                child: Text(
                  '${AppConfig.appName} 用户协议',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLocalizationsSimple.of(context)?.lastUpdated(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ) ??
                      '最后更新日期：${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 协议接受
              _buildSection(
                AppLocalizationsSimple.of(context)?.agreementAcceptance ??
                    '协议接受',
                '${AppLocalizationsSimple.of(context)?.welcomeMessage(AppConfig.appName) ?? '欢迎使用${AppConfig.appName}！通过下载、安装或使用${AppConfig.appName}应用程序（以下简称"应用"或"服务"），您同意受本用户协议（以下简称"协议"）的约束。如果您不同意本协议的任何条款，请不要使用我们的服务。'}\n\n'
                '${AppLocalizationsSimple.of(context)?.importantReminder ?? '重要提醒：'}\n'
                '• 请仔细阅读本协议的所有条款\n'
                '• 本协议与隐私政策共同构成完整的法律文件\n'
                '• 继续使用应用即表示您完全同意本协议\n'
                '• 如有疑问，请在使用前咨询法律专业人士',
                textColor,
                accentColor,
                isHighlight: true,
              ),

              // 服务描述
              _buildSection(
                AppLocalizationsSimple.of(context)?.serviceDescription ??
                    '服务描述',
                '${AppConfig.appName}是一个专为Memos笔记服务设计的跨平台客户端应用。我们提供以下功能：\n\n'
                '📝 核心功能：\n'
                '• 连接到用户自托管的Memos服务器\n'
                '• 创建、编辑、删除和管理笔记\n'
                '• 支持Markdown格式编辑和实时预览\n'
                '• 图片上传、压缩和管理\n'
                '• 标签分类和全文搜索功能\n'
                '• 数据同步和离线访问\n\n'
                '🔧 扩展功能：\n'
                '• 笔记导入导出（JSON、Markdown、HTML）\n'
                '• 图片分享和美化\n'
                '• 多种主题模式\n'
                '• Telegram Bot集成（可选）\n'
                '• 应用内反馈和问题报告\n\n'
                '📖 开源特性：\n'
                '${AppConfig.appName}是一个开源项目，代码完全透明，用户可以自由查看、修改和分发。项目遵循MIT开源协议。',
                textColor,
                accentColor,
              ),

              // 用户责任
              _buildSection(
                AppLocalizationsSimple.of(context)?.userResponsibilities ??
                    '用户责任与义务',
                '${AppLocalizationsSimple.of(context)?.userResponsibilitiesContent(AppConfig.appName) ?? '使用${AppConfig.appName}时，您同意并承诺：'}\n\n'
                '🔐 账户安全：\n'
                '• 提供准确的服务器连接信息\n'
                '• 对您的账户安全负责，包括访问令牌的保密\n'
                '• 定期更新密码和访问凭证\n'
                '• 发现安全问题时及时报告\n\n'
                '⚖️ 合规使用：\n'
                '• 遵守适用的法律法规和社会道德规范\n'
                '• 不使用应用进行任何非法或有害活动\n'
                '• 尊重他人的知识产权和隐私权\n'
                '• 不传播违法有害信息\n\n'
                '🛡️ 负责任使用：\n'
                '• 不滥用应用功能或试图破坏服务\n'
                '• 不进行逆向工程、反编译或破解\n'
                '• 不利用应用进行网络攻击或有害行为\n'
                '• 配合我们处理违规行为\n\n'
                '${AppLocalizationsSimple.of(context)?.userContentResponsibility ?? '您对通过应用创建、存储或传输的所有内容承担完全责任。'}',
                textColor,
                accentColor,
              ),

              // 数据所有权
              _buildSection(
                AppLocalizationsSimple.of(context)?.dataOwnership ?? '数据所有权',
                '${AppLocalizationsSimple.of(context)?.dataOwnershipDeclaration ?? '重要声明：'}\n\n'
                '• 您的所有笔记数据完全归您所有\n'
                '• 数据存储在您自己的Memos服务器上\n'
                '• InkRoot不会声明对您的内容拥有任何权利\n'
                '• 您可以随时导出、删除或迁移您的数据\n'
                '• 我们不会访问、备份或分析您的个人数据\n\n'
                '${AppLocalizationsSimple.of(context)?.userContentControl ?? '您保留对自己创建的所有内容的完整控制权。'}',
                textColor,
                accentColor,
                isHighlight: true,
              ),

              // 免责声明
              _buildSection(
                AppLocalizationsSimple.of(context)?.disclaimer ?? '免责声明',
                '${AppConfig.appName}按"现状"提供服务，我们努力提供稳定可靠的服务，但不提供任何明示或暗示的保证：\n\n'
                '🚫 服务限制：\n'
                '• 不保证服务的持续可用性（可能因维护、更新等中断）\n'
                '• 不保证服务完全无错误或故障\n'
                '• 不保证服务满足您的所有特定需求\n'
                '• 不保证第三方Memos服务器的稳定性和安全性\n'
                '• 不保证网络连接的稳定性\n\n'
                '🔒 数据责任：\n'
                '• 用户应自行备份重要数据\n'
                '• 我们不对数据丢失承担责任\n'
                '• 第三方服务器的数据安全由服务器运营方负责\n'
                '• 建议用户定期导出重要笔记\n\n'
                '⚠️ 风险提示：\n'
                '${AppLocalizationsSimple.of(context)?.disclaimerContent(AppConfig.appName) ?? '您理解并同意，使用${AppConfig.appName}的风险完全由您自己承担。在适用法律允许的最大范围内，我们不承担任何直接、间接、偶然、特殊或后果性损害的责任，包括但不限于数据丢失、业务中断、利润损失等。'}',
                textColor,
                accentColor,
              ),

              // 知识产权
              _buildSection(
                AppLocalizationsSimple.of(context)?.intellectualProperty ??
                    '知识产权',
                '📜 软件版权：\n'
                '${AppConfig.appName}应用及其原创内容、功能和特性归${AppConfig.companyName}所有，受国际版权、商标和其他知识产权法律保护。\n\n'
                '🔓 开源许可：\n'
                '${AppLocalizationsSimple.of(context)?.openSourceRights(AppConfig.appName) ?? '作为开源软件，${AppConfig.appName}在MIT许可证下发布，您享有以下权利：'}\n'
                '• 自由使用、修改和分发软件\n'
                '• 用于商业或非商业目的\n'
                '• 创建基于${AppConfig.appName}的衍生作品\n'
                '• 私用、学习和研究\n\n'
                '📋 使用条件：\n'
                '${AppLocalizationsSimple.of(context)?.openSourceObligations ?? '使用本软件时，您必须：'}\n'
                '• 保留原始版权声明和许可证声明\n'
                '• 在衍生作品中包含MIT许可证\n'
                '• 不将商标用作推广衍生作品的名称\n\n'
                '🎨 用户内容：\n'
                '${AppLocalizationsSimple.of(context)?.userContentOwnership ?? '您对自己创建的笔记内容拥有完整的知识产权，我们不声明对您的内容拥有任何权利。'}',
                textColor,
                accentColor,
              ),

              // 服务变更
              _buildSection(
                AppLocalizationsSimple.of(context)?.serviceChangesTermination ??
                    '服务变更与终止',
                '📱 服务更新：\n'
                '${AppLocalizationsSimple.of(context)?.serviceModificationRights ?? '我们保留随时修改、更新或改进服务的权利，可能包括：'}\n'
                '• 更新应用功能和用户界面\n'
                '• 修复漏洞和改进性能\n'
                '• 添加新的功能特性\n'
                '• 调整技术要求和系统兼容性\n'
                '• 优化用户体验\n\n'
                '📢 变更通知：\n'
                '${AppLocalizationsSimple.of(context)?.majorChangeNotifications ?? '重大变更将通过以下方式通知用户：'}\n'
                '• 应用内公告和弹窗提醒\n'
                '• 应用商店更新说明\n'
                '• 官方网站和社交媒体\n'
                '• 直接邮件通知（如适用）\n\n'
                '🚪 服务终止：\n'
                '${AppLocalizationsSimple.of(context)?.serviceSuspensionConditions ?? '在以下情况下，我们可能暂停或终止服务：'}\n'
                '• 用户严重违反本协议\n'
                '• 法律法规要求\n'
                '• 技术或商业原因\n'
                '• 不可抗力因素\n\n'
                '${AppLocalizationsSimple.of(context)?.terminationNotice ?? '终止前我们将尽合理努力提前通知用户。'}',
                textColor,
                accentColor,
              ),

              // 协议修改
              _buildSection(
                AppLocalizationsSimple.of(context)?.agreementModifications ??
                    '协议修改',
                AppLocalizationsSimple.of(context)?.agreementUpdatePolicy ??
                    '我们可能会不时更新本用户协议。重大变更会在应用中显著展示，并要求您重新同意。\n\n继续使用应用即表示您接受修改后的协议。如果您不同意修改后的条款，应停止使用应用并可卸载软件。',
                textColor,
                accentColor,
              ),

              // 终止
              _buildSection(
                AppLocalizationsSimple.of(context)?.termination ?? '终止',
                '${AppLocalizationsSimple.of(context)?.userTerminationRights ?? '您可以随时停止使用InkRoot并删除应用。\n\n我们也可能在以下情况下终止您的访问权限：'}\n'
                '• 违反本协议的条款\n'
                '• 滥用服务或进行有害活动\n'
                '• 法律要求\n\n'
                '${AppLocalizationsSimple.of(context)?.postTerminationObligations ?? '终止后，您应停止使用应用并删除所有副本。'}',
                textColor,
                accentColor,
              ),

              // 添加争议解决条款
              _buildSection(
                AppLocalizationsSimple.of(context)?.disputeResolution ?? '争议解决',
                '🤝 友好协商：\n'
                '${AppLocalizationsSimple.of(context)?.disputeNegotiation(AppConfig.supportEmail) ?? '因本协议产生的任何争议，双方应首先通过友好协商解决。协商时应本着诚实守信、互相尊重的原则。\n\n如协商无法解决争议，任何一方可向有管辖权的人民法院提起诉讼。诉讼过程中，本协议的其他条款仍应继续履行。\n\n争议协商请联系：${AppConfig.supportEmail}'}',
                textColor,
                accentColor,
              ),

              // 其他条款
              _buildSection(
                AppLocalizationsSimple.of(context)?.otherTerms ?? '其他条款',
                '📄 协议完整性：\n'
                '${AppLocalizationsSimple.of(context)?.entireAgreement ?? '本协议构成双方就本服务达成的完整协议，取代之前的所有口头或书面协议。\n\n如本协议的任何条款被认定为无效或不可执行，其余条款仍然有效。\n\n本协议自您接受之日起生效，对之前的使用行为具有追溯效力。\n\n本协议以中文为准。如有其他语言版本，仅供参考，以中文版本为准。'}',
                textColor,
                accentColor,
              ),

              // 适用法律
              _buildSection(
                AppLocalizationsSimple.of(context)?.governingLaw ?? '适用法律与管辖',
                '⚖️ 适用法律：\n'
                '${AppLocalizationsSimple.of(context)?.lawJurisdiction(AppConfig.companyAddress) ?? '本协议的签订、效力、解释、履行和争议解决均适用中华人民共和国法律法规，不考虑法律冲突原则。\n\n因本协议引起的争议，由${AppConfig.companyAddress}所在地有管辖权的人民法院管辖。\n\n本协议在法律允许的范围内对双方具有约束力。如本协议与法律法规相冲突，以法律法规为准。'}',
                textColor,
                accentColor,
              ),

              // 联系信息
              _buildSection(
                AppLocalizationsSimple.of(context)?.contactUsAgreement ??
                    '联系我们',
                AppLocalizationsSimple.of(context)
                        ?.contactInfoMessage(AppConfig.supportEmail) ??
                    '如果您对本用户协议有任何疑问，请通过以下方式联系我们：\n\n反馈建议：设置 → 反馈建议（推荐）\n邮箱：${AppConfig.supportEmail}\n应用内反馈：设置 → 意见反馈',
                textColor,
                accentColor,
              ),

              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    AppLocalizationsSimple.of(context)
                            ?.closingMessage(AppConfig.appName) ??
                        '感谢您选择${AppConfig.appName}！我们致力于为您提供最佳的笔记体验。\n\n如您对本协议有任何疑问，请随时联系我们。',
                    style: TextStyle(
                      fontSize: 14,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    Color textColor,
    Color accentColor, {
    bool isHighlight = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: isHighlight ? const EdgeInsets.all(12) : EdgeInsets.zero,
            decoration: isHighlight
                ? BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.3)),
                  )
                : null,
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
}
