import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// 隐私政策弹窗 - 大厂标准设计
/// 参考：微信、抖音、支付宝等一线App的设计规范
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({
    required this.onAgree,
    required this.onDisagree,
    super.key,
  });
  final VoidCallback onAgree;
  final VoidCallback onDisagree;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false, // 禁止通过返回键关闭
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                const Text(
                  '用户协议与隐私政策',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // 协议内容
                _buildContent(context),

                const SizedBox(height: 20),

                // 按钮
                Row(
                  children: [
                    // 不同意按钮
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          onDisagree();
                          // 退出应用
                          SystemNavigator.pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Color(0xFFE5E5E5),
                            ),
                          ),
                        ),
                        child: const Text(
                          '不同意并退出',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 同意按钮
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAgree,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '同意并继续',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildContent(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我们会以本地优先方式保存笔记。只有你主动配置同步、登录服务器或使用保存图片、通知等功能时，才会使用必要权限和账号信息。',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                '继续使用前，请阅读并同意',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF666666),
                ),
              ),
              _buildProtocolLink('《用户协议》', AppConfig.userAgreementUri),
              const Text(
                '和',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF666666),
                ),
              ),
              _buildProtocolLink('《隐私政策》', AppConfig.privacyPolicyUri),
            ],
          ),
        ],
      );

  Widget _buildProtocolLink(String label, Uri uri) => TextButton(
        onPressed: () => _openUrl(uri),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Future<void> _openUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
