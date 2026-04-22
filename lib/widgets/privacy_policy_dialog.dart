import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

                const SizedBox(height: 20),

                // 协议内容
                _buildContent(context),

                const SizedBox(height: 24),

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
                          '不同意',
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
                          '同意',
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

  Widget _buildContent(BuildContext context) => RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF666666),
          ),
          children: [
            const TextSpan(
              text: '欢迎使用InkRoot！\n\n我们非常重视您的隐私保护和个人信息安全。在使用我们的服务前，请您仔细阅读并充分理解',
            ),
            TextSpan(
              text: '《用户协议》',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://inkroot.cn/agreement.html'),
            ),
            const TextSpan(text: '和'),
            TextSpan(
              text: '《隐私政策》',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl('https://inkroot.cn/privacy.html'),
            ),
            const TextSpan(
              text: '。\n\n点击"同意"即表示您已阅读并同意上述协议的全部内容。',
            ),
          ],
        ),
      );

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
