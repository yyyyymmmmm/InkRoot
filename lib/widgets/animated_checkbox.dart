// 🎯 优雅的动画复选框（参考 Things 3 / Todoist / Microsoft To Do）
import 'package:flutter/material.dart';
import 'package:inkroot/themes/app_theme.dart';

class AnimatedCheckbox extends StatefulWidget {
  const AnimatedCheckbox({
    required this.value,
    required this.onChanged,
    this.size = 22.0,
    this.borderRadius = 6.0,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final double size;
  final double borderRadius;

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInteractive = widget.onChanged != null;

    // 🎨 主流待办软件的配色方案
    final Color borderColor = widget.value
        ? AppTheme.primaryColor
        : (isDark ? Colors.grey[600]! : Colors.grey[400]!);

    final Color fillColor = widget.value
        ? AppTheme.primaryColor
        : Colors.transparent;

    final Color checkColor = Colors.white;

    return GestureDetector(
      onTap: isInteractive
          ? () {
              widget.onChanged?.call(!widget.value);
            }
          : null,
      child: Container(
        width: widget.size + 8, // 减少水平触摸区域
        height: widget.size + 2, // 最小化垂直触摸区域，确保与文本对齐
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: 2.0,
              ),
              // 🎯 已完成时添加微妙的阴影（Things 3 风格）
              boxShadow: widget.value
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: widget.value
                ? ScaleTransition(
                    scale: _checkAnimation,
                    child: Icon(
                      Icons.check,
                      size: widget.size * 0.7,
                      color: checkColor,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

