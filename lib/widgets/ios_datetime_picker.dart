import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:intl/intl.dart';

/// iOS风格的日期时间选择器
/// 符合中国人使用习惯和应用主题风格
class IOSDateTimePicker {
  /// 显示iOS风格的日期时间选择器
  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDateTime,
    DateTime? minimumDateTime,
    DateTime? maximumDateTime,
    bool showQuickOptions = true, // 是否显示快捷选择
  }) async {
    // 🎯 默认为当前时间（如果没有指定初始时间）
    final initialDate = initialDateTime ?? DateTime.now();
    var selectedDateTime = initialDate;
    // 用于强制重建 DatePicker 的 key
    var pickerKey = 0;

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor =
            isDarkMode ? AppTheme.darkCardColor : Colors.white;
        final textColor = isDarkMode
            ? AppTheme.darkTextPrimaryColor
            : AppTheme.textPrimaryColor;
        final secondaryColor = isDarkMode
            ? AppTheme.darkTextSecondaryColor
            : AppTheme.textSecondaryColor;
        final primaryColor =
            isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
        final dividerColor =
            isDarkMode ? AppTheme.darkDividerColor : AppTheme.dividerColor;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => DecoratedBox(
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
                  // 🎯 顶部拖动指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 头部标题栏
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '取消',
                            style: AppTextStyles.custom(
                              context,
                              17,
                              color: secondaryColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          '设置提醒时间',
                          style: AppTextStyles.custom(
                            context,
                            17,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              Navigator.of(context).pop(selectedDateTime),
                          child: Text(
                            '确定',
                            style: AppTextStyles.custom(
                              context,
                              17,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 快捷选项（可选）
                  if (showQuickOptions)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '快捷选择',
                            style: AppTextStyles.custom(
                              context,
                              13,
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildQuickOptions(
                              context,
                              (DateTime newTime) {
                                setState(() {
                                  selectedDateTime = newTime;
                                  pickerKey++; // 改变 key 以触发滚轮动画
                                });
                              },
                              isDarkMode,
                              primaryColor,
                              selectedDateTime,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // iOS风格的滚轮选择器（中文）
                  SizedBox(
                    height: 216,
                    child: Localizations.override(
                      context: context,
                      locale: const Locale('zh', 'CN'),
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness:
                              isDarkMode ? Brightness.dark : Brightness.light,
                          primaryColor: primaryColor,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: AppTextStyles.custom(
                              context,
                              21,
                              color: textColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          key: ValueKey(pickerKey), // 🎯 添加 key 以触发重建和动画
                          use24hFormat: true,
                          minimumDate: minimumDateTime ?? DateTime.now(),
                          maximumDate: maximumDateTime ??
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateTime: selectedDateTime,
                          onDateTimeChanged: (DateTime newDateTime) {
                            setState(() {
                              selectedDateTime = newDateTime;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建快捷选项按钮
  static List<Widget> _buildQuickOptions(
    BuildContext context,
    Function(DateTime) onSelect,
    bool isDarkMode,
    Color primaryColor,
    DateTime selectedDateTime,
  ) {
    final now = DateTime.now();
    final options = [
      {
        'label': '1小时后',
        'time': now.add(const Duration(hours: 1)),
        'icon': CupertinoIcons.time,
      },
      {
        'label': '今晚8点',
        'time': DateTime(now.year, now.month, now.day, 20),
        'icon': CupertinoIcons.moon_stars,
      },
      {
        'label': '明早9点',
        'time': DateTime(now.year, now.month, now.day + 1, 9),
        'icon': CupertinoIcons.sunrise,
      },
      {
        'label': '明晚8点',
        'time': DateTime(now.year, now.month, now.day + 1, 20),
        'icon': CupertinoIcons.moon,
      },
      {
        'label': '下周一9点',
        'time': _getNextWeekday(now, DateTime.monday, 9),
        'icon': CupertinoIcons.calendar,
      },
    ];

    return options.where((option) {
      // 过滤掉已经过去的时间
      return (option['time']! as DateTime).isAfter(now);
    }).map((option) {
      final optionTime = option['time']! as DateTime;
      final isSelected = _isSameDateTime(optionTime, selectedDateTime);

      return _QuickOptionChip(
        label: option['label']! as String,
        icon: option['icon']! as IconData,
        onTap: () => onSelect(optionTime),
        isDarkMode: isDarkMode,
        primaryColor: primaryColor,
        isSelected: isSelected,
      );
    }).toList();
  }

  /// 判断两个时间是否相同（精确到分钟）
  static bool _isSameDateTime(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  /// 获取下周的某一天
  static DateTime _getNextWeekday(DateTime from, int weekday, int hour) {
    final daysUntilWeekday = (weekday - from.weekday + 7) % 7;
    final nextWeekday =
        from.add(Duration(days: daysUntilWeekday == 0 ? 7 : daysUntilWeekday));
    return DateTime(
      nextWeekday.year,
      nextWeekday.month,
      nextWeekday.day,
      hour,
    );
  }

  /// 格式化日期时间（中文显示）
  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (dateToCheck == today) {
      dateStr = '今天';
    } else if (dateToCheck == tomorrow) {
      dateStr = '明天';
    } else {
      // 使用中文星期
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekday = weekdays[dateTime.weekday - 1];
      dateStr = '${DateFormat('MM月dd日', 'zh_CN').format(dateTime)} $weekday';
    }

    final timeStr = DateFormat('HH:mm').format(dateTime);
    return '$dateStr $timeStr';
  }
}

/// 快捷选项芯片组件
class _QuickOptionChip extends StatefulWidget {
  const _QuickOptionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDarkMode,
    required this.primaryColor,
    required this.isSelected,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color primaryColor;
  final bool isSelected;

  @override
  State<_QuickOptionChip> createState() => _QuickOptionChipState();
}

class _QuickOptionChipState extends State<_QuickOptionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSelected
        ? widget.primaryColor
        : (widget.isDarkMode
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7));

    final textColor = widget.isSelected
        ? Colors.white
        : (widget.isDarkMode ? Colors.white : Colors.black87);

    final iconColor = widget.isSelected ? Colors.white : widget.primaryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isSelected
                  ? widget.primaryColor
                  : (widget.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.06)),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTextStyles.bodyMedium(
                  context,
                  color: textColor,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
