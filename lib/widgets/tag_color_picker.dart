import 'package:flutter/material.dart';
import 'package:inkroot/models/tag_color_model.dart';
import 'package:inkroot/themes/app_theme.dart';

/// 标签颜色选择器 - 简洁优雅设计
class TagColorPicker extends StatefulWidget {
  final String tagName;
  final TagColor? currentColor;
  final Function(TagColor) onColorSelected;

  const TagColorPicker({
    required this.tagName,
    this.currentColor,
    required this.onColorSelected,
    super.key,
  });

  @override
  State<TagColorPicker> createState() => _TagColorPickerState();
}

class _TagColorPickerState extends State<TagColorPicker> {
  int _selectedPresetIndex = 0;
  Color? _customBackgroundColor;
  Color? _customTextColor;
  bool _isCustomMode = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // 初始化自定义颜色（不依赖 Theme）
    if (widget.currentColor != null) {
      _customBackgroundColor = widget.currentColor!.backgroundColor;
      _customTextColor = widget.currentColor!.textColor;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🎯 在这里访问 Theme.of(context) 是安全的
    if (!_initialized && widget.currentColor != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final index = TagColor.presetColors.indexWhere((preset) {
        final bgColor = isDark ? preset['darkBg'] as Color : preset['bg'] as Color;
        return bgColor.value == widget.currentColor!.backgroundColor.value;
      });
      if (index != -1) {
        _selectedPresetIndex = index;
      } else {
        _isCustomMode = true;
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPreset = TagColor.presetColors[_selectedPresetIndex];
    final previewBg = _isCustomMode
        ? (_customBackgroundColor ?? TagColor.defaultBackgroundColor(context))
        : (isDark ? selectedPreset['darkBg'] as Color : selectedPreset['bg'] as Color);
    final previewText = _isCustomMode
        ? (_customTextColor ?? TagColor.defaultTextColor(context))
        : (isDark ? selectedPreset['darkText'] as Color : selectedPreset['text'] as Color);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.tagColorScheme ?? '标签配色',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 实时预览
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.previewEffect ?? '预览效果',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: previewBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${widget.tagName}',
                    style: TextStyle(
                      color: previewText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 配色方案选择
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.presetColors ?? '预设配色',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCustomMode = !_isCustomMode;
                    });
                  },
                  icon: Icon(
                    _isCustomMode ? Icons.grid_view : Icons.tune,
                    size: 16,
                  ),
                  label: Text(
                    _isCustomMode
                        ? (AppLocalizationsSimple.of(context)?.selectPreset ?? '选择预设')
                        : (AppLocalizationsSimple.of(context)?.customColor ?? '自定义'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (!_isCustomMode) ...[
            // 预设配色网格
            Container(
              height: 240,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: TagColor.presetColors.length,
                itemBuilder: (context, index) {
                  final preset = TagColor.presetColors[index];
                  final bgColor = isDark
                      ? preset['darkBg'] as Color
                      : preset['bg'] as Color;
                  final textColor = isDark
                      ? preset['darkText'] as Color
                      : preset['text'] as Color;
                  final isSelected = _selectedPresetIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPresetIndex = index;
                        _isCustomMode = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // 自定义颜色选择（简化版）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildColorRow(
                    AppLocalizationsSimple.of(context)?.backgroundColor ?? '背景色',
                    _customBackgroundColor ?? TagColor.defaultBackgroundColor(context),
                    (color) {
                      setState(() {
                        _customBackgroundColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorRow(
                    AppLocalizationsSimple.of(context)?.textColor ?? '文字色',
                    _customTextColor ?? TagColor.defaultTextColor(context),
                    (color) {
                      setState(() {
                        _customTextColor = color;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 底部按钮
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (widget.currentColor != null)
                  TextButton(
                    onPressed: () async {
                      await TagColorService.removeTagColor(widget.tagName);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(AppLocalizationsSimple.of(context)?.reset ?? '重置'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizationsSimple.of(context)?.cancel ?? '取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final bgColor = _isCustomMode
                        ? (_customBackgroundColor ??
                            TagColor.defaultBackgroundColor(context))
                        : (isDark
                            ? selectedPreset['darkBg'] as Color
                            : selectedPreset['bg'] as Color);
                    final textColor = _isCustomMode
                        ? (_customTextColor ??
                            TagColor.defaultTextColor(context))
                        : (isDark
                            ? selectedPreset['darkText'] as Color
                            : selectedPreset['text'] as Color);

                    final tagColor = TagColor(
                      tagName: widget.tagName,
                      backgroundColor: bgColor,
                      textColor: textColor,
                      updatedAt: DateTime.now(),
                    );

                    widget.onColorSelected(tagColor);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizationsSimple.of(context)?.confirm ?? '确定'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, Color color, Function(Color) onColorChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 简化的颜色选择器：提供6个常用颜色
    final basicColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.grey,
    ];

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: basicColors.map((c) {
              final isSelected = c.value == color.value;
              return GestureDetector(
                onTap: () => onColorChanged(c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

