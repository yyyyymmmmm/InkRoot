import 'package:flutter/material.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/text_style_helper.dart';

/// 用于显示全屏加载状态的覆盖层组件
class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({
    required this.isVisible,
    super.key,
    this.message,
    this.color = AppTheme.primaryColor,
  });
  final bool isVisible;
  final String? message;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isVisible
            ? ColoredBox(
                key: const ValueKey<bool>(true),
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: color,
                            strokeWidth: 3,
                          ),
                          if (message != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                message!,
                                style: AppTextStyles.bodyMedium(
                                  context,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey<bool>(false)),
      );
}
