import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/text_style_helper.dart';
import 'package:intl/intl.dart' show DateFormat;

class Heatmap extends StatefulWidget {
  const Heatmap({
    required this.notes,
    super.key,
    this.cellColor,
    this.activeColor = AppTheme.primaryColor,
  });
  final List<Note> notes;
  final Color? cellColor;
  final Color activeColor;

  @override
  State<Heatmap> createState() => _HeatmapState();
}

// 统计信息卡片 - 简化版
class _StatCardWidget extends StatelessWidget {
  const _StatCardWidget({
    required this.label,
    required this.value,
    required this.isDarkMode,
    required this.primaryColor,
  });
  final String label;
  final String value;
  final bool isDarkMode;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyMedium(
                  context,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppTheme.darkTextPrimaryColor
                      : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.custom(
                  context,
                  10,
                  color: isDarkMode
                      ? AppTheme.darkTextSecondaryColor.withOpacity(0.8)
                      : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
}

class _HeatmapState extends State<Heatmap> {
  // 月份偏移量（0表示当前月，-1表示上个月，1表示下个月）
  int _monthOffset = 0;

  final DateFormat _keyDateFormat = DateFormat('yyyy-MM-dd');

  // 获取本地化的日期格式
  DateFormat _getDateFormat(BuildContext context) {
    final isZh =
        AppLocalizationsSimple.of(context)?.locale.languageCode == 'zh';
    return isZh ? DateFormat('yyyy年M月') : DateFormat('MMMM yyyy', 'en_US');
  }

  DateFormat _getFullDateFormat(BuildContext context) {
    final isZh =
        AppLocalizationsSimple.of(context)?.locale.languageCode == 'zh';
    return isZh
        ? DateFormat('yyyy年MM月dd日')
        : DateFormat('MMM dd, yyyy', 'en_US');
  }

  // 热力图颜色定义 - 从浅到深
  static const List<Color> lightModeColors = [
    Color(0xFFEBEDF0), // 灰色 - 无活动
    Color(0xFFE3F5E8), // 非常浅的绿色 - 级别1
    Color(0xFFCCECD4), // 浅绿色 - 级别2
    Color(0xFFA8DFBA), // 中浅绿色 - 级别3
    Color(0xFF7ECDA0), // 中绿色 - 级别4
  ];

  // 深色模式下的热力图颜色
  static const List<Color> darkModeColors = [
    Color(0xFF2C2C2C), // 深灰色 - 无活动
    Color(0xFF1A3B2D), // 非常深的绿色 - 级别1
    Color(0xFF204836), // 深绿色 - 级别2
    Color(0xFF275C42), // 中深绿色 - 级别3
    Color(0xFF306E4F), // 中绿色 - 级别4
  ];

  // 获取当前显示的月份
  DateTime get _displayMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  // 判断是否可以查看下个月（不能查看未来）
  bool get _canGoNext => _monthOffset < 0;

  // 切换到上个月
  void _previousMonth() {
    setState(() {
      _monthOffset--;
    });
  }

  // 切换到下个月
  void _nextMonth() {
    if (_canGoNext) {
      setState(() {
        _monthOffset++;
      });
    }
  }

  // 计算总字数
  int _getTotalWordCount() =>
      widget.notes.fold(0, (sum, note) => sum + note.content.length);

  // 计算记录总天数（去重）
  int _getTotalDays() {
    final uniqueDates = <String>{};
    for (final note in widget.notes) {
      uniqueDates.add(_keyDateFormat.format(note.createdAt));
      if (note.updatedAt != note.createdAt) {
        uniqueDates.add(_keyDateFormat.format(note.updatedAt));
      }
    }
    return uniqueDates.length;
  }

  // 计算今日记录字数（大厂标准：只统计纯文字）
  int _getTodayWordCount() {
    final today = DateTime.now();
    final todayStr = _keyDateFormat.format(today);
    var count = 0;
    for (final note in widget.notes) {
      final createDateStr = _keyDateFormat.format(note.createdAt);
      final updateDateStr = _keyDateFormat.format(note.updatedAt);
      if (createDateStr == todayStr || updateDateStr == todayStr) {
        count += _getActualWordCount(note.content);
      }
    }
    return count;
  }

  // 🎯 大厂标准：只统计实际文字（去除Markdown语法、标点、空格）
  int _getActualWordCount(String content) {
    if (content.isEmpty) return 0;

    var cleaned = content;

    // 移除Markdown语法
    cleaned = cleaned.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), ''); // 图片
    cleaned =
        cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1'); // 链接，保留文字
    cleaned = cleaned.replaceAll(RegExp(r'`{3}[\s\S]*?`{3}'), ''); // 代码块
    cleaned = cleaned.replaceAll(RegExp('`[^`]+`'), ''); // 行内代码
    cleaned = cleaned.replaceAll(RegExp(r'[*_~#>\-\[\]\(\)]'), ''); // 符号

    // 移除标点符号和空格
    cleaned = cleaned.replaceAll(RegExp('[，。！？；：、""' '《》【】（）,.!?;:"\'s]'), '');

    // 返回纯文字字符数
    return cleaned.length;
  }

  // 🔥 计算今日活跃笔记数量（大厂标准：今天创建或修改的）
  // 这样导入数据后也能正确显示统计
  int _getTodayNewNoteCount() {
    final today = DateTime.now();
    final todayStr = _keyDateFormat.format(today);
    return widget.notes.where((note) {
      final createDateStr = _keyDateFormat.format(note.createdAt);
      final updateDateStr = _keyDateFormat.format(note.updatedAt);
      // 今天创建或今天更新的都算活跃笔记
      return createDateStr == todayStr || updateDateStr == todayStr;
    }).length;
  }

  // 🔥 计算今日活跃标签数量（大厂标准：活跃笔记中的标签）
  int _getTodayNewTagCount() {
    final today = DateTime.now();
    final todayStr = _keyDateFormat.format(today);
    final todayTags = <String>{};
    for (final note in widget.notes) {
      final createDateStr = _keyDateFormat.format(note.createdAt);
      final updateDateStr = _keyDateFormat.format(note.updatedAt);
      // 今天创建或今天更新的笔记中的标签
      if (createDateStr == todayStr || updateDateStr == todayStr) {
        todayTags.addAll(note.tags);
      }
    }
    return todayTags.length;
  }

  // 格式化数字（大于1000时显示为k）
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前主题模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    // 生成一个更可靠的key，同时考虑笔记数量和最近的更新时间以及月份偏移
    final latestUpdateTime = widget.notes.isEmpty
        ? DateTime.now().millisecondsSinceEpoch
        : widget.notes
            .map((note) => note.updatedAt.millisecondsSinceEpoch)
            .reduce((max, time) => time > max ? time : max);

    final uniqueKey = ValueKey(
      'heatmap-${widget.notes.length}-$latestUpdateTime-$_monthOffset',
    );

    final dailyCounts = _calculateDailyCounts();
    final maxCount =
        dailyCounts.values.fold(0, (max, count) => count > max ? count : max);
    final dates = _generateMonthDates();

    // 计算单个格子的大小和间距
    const cellSize = 18.0;
    const spacing = 2.0;

    return Column(
      key: uniqueKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 总体统计卡片 - 清晰版
        Row(
          children: [
            _StatCardWidget(
              label: AppLocalizationsSimple.of(context)?.totalWords ?? '总字数',
              value: _formatNumber(_getTotalWordCount()),
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),
            const SizedBox(width: 4),
            _StatCardWidget(
              label: AppLocalizationsSimple.of(context)?.totalNotes ?? '笔记数',
              value: _formatNumber(widget.notes.length),
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),
            const SizedBox(width: 4),
            _StatCardWidget(
              label: AppLocalizationsSimple.of(context)?.totalDays ?? '记录天数',
              value: _formatNumber(_getTotalDays()),
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 月份标题和切换按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左箭头按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _previousMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
              ),
            ),

            // 月份标题
            Text(
              _getDateFormat(context).format(_displayMonth),
              style: AppTextStyles.labelSmall(
                context,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),

            // 右箭头按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _canGoNext ? _nextMonth : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _canGoNext
                        ? (isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03))
                        : (isDarkMode
                            ? Colors.white.withOpacity(0.02)
                            : Colors.black.withOpacity(0.01)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: _canGoNext
                        ? primaryColor
                        : (isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 热力图网格 - 使用固定尺寸
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cellSize, // 固定格子高度
          ),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final dateKey = _keyDateFormat.format(date);
            final count = dailyCounts[dateKey] ?? 0;
            final isDisplayMonth = date.month == _displayMonth.month &&
                date.year == _displayMonth.year;

            return Tooltip(
              message:
                  '${_getFullDateFormat(context).format(date)}: ${AppLocalizationsSimple.of(context)?.notesCountFormatted(count) ?? '$count 条笔记'}',
              child: Center(
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: isDisplayMonth
                        ? _getHeatmapColor(count, maxCount, isDarkMode)
                        : (widget.cellColor ??
                                (isDarkMode
                                    ? darkModeColors[0]
                                    : lightModeColors[0]))
                            .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3.5), // 圆角方块
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 5),

        // 星期标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['一', '二', '三', '四', '五', '六', '日']
              .map(
                (day) => SizedBox(
                  width: cellSize,
                  child: Text(
                    day,
                    style: AppTextStyles.custom(
                      context,
                      8,
                      color: secondaryTextColor.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),

        // 添加颜色说明
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${AppLocalizationsSimple.of(context)?.activityLevel ?? '活跃度'}: ',
              style: AppTextStyles.custom(
                context,
                8,
                color: secondaryTextColor.withOpacity(0.6),
              ),
            ),
            ...List.generate(4, (index) {
              final colors = isDarkMode ? darkModeColors : lightModeColors;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  color: colors[index + 1],
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ],
        ),

        // 今日统计卡片 - 清晰版
        const SizedBox(height: 8),
        Row(
          children: [
            _StatCardWidget(
              label: AppLocalizationsSimple.of(context)?.todayWords ?? '今日字数',
              value: _formatNumber(_getTodayWordCount()),
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),
            const SizedBox(width: 4),
            _StatCardWidget(
              label:
                  AppLocalizationsSimple.of(context)?.todayNewNotes ?? '活跃笔记',
              value: _formatNumber(_getTodayNewNoteCount()),
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),
            const SizedBox(width: 4),
            _StatCardWidget(
              label: AppLocalizationsSimple.of(context)?.todayNewTags ?? '活跃标签',
              value: _formatNumber(_getTodayNewTagCount()),
              isDarkMode: isDarkMode,
              primaryColor: primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  Map<String, int> _calculateDailyCounts() {
    final result = <String, int>{};

    // 预先填充显示月份的所有日期，确保它们至少有0的值
    final displayMonth = _displayMonth;
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;

    for (var i = 1; i <= daysInMonth; i++) {
      final date = DateTime(displayMonth.year, displayMonth.month, i);
      final dateStr = _keyDateFormat.format(date);
      result[dateStr] = 0;
    }

    // 同时考虑创建日期和更新日期来计算每天的笔记活动
    for (final note in widget.notes) {
      // 记录创建日期的笔记
      final createDateStr = _keyDateFormat.format(note.createdAt);
      if (note.createdAt.month == displayMonth.month &&
          note.createdAt.year == displayMonth.year) {
        result[createDateStr] = (result[createDateStr] ?? 0) + 1;
      }

      // 如果更新日期与创建日期不同，且在显示月份，也计入活动
      final updateDateStr = _keyDateFormat.format(note.updatedAt);
      if (note.updatedAt != note.createdAt &&
          note.updatedAt.month == displayMonth.month &&
          note.updatedAt.year == displayMonth.year) {
        result[updateDateStr] = (result[updateDateStr] ?? 0) + 1;
      }
    }

    return result;
  }

  List<DateTime> _generateMonthDates() {
    final displayMonth = _displayMonth;
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month);
    final lastDayOfMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0);

    // 计算第一天之前需要填充的天数（从周一开始）
    final firstWeekday = firstDayOfMonth.weekday;
    final firstDate =
        firstDayOfMonth.subtract(Duration(days: firstWeekday - 1));

    // 计算最后一天之后需要填充的天数（到周日结束）
    final lastWeekday = lastDayOfMonth.weekday;
    final daysToAdd = 7 - lastWeekday;
    final lastDate = lastDayOfMonth.add(Duration(days: daysToAdd));

    final dates = <DateTime>[];
    var currentDate = firstDate;

    // 生成包含完整周的日期列表
    while (!currentDate.isAfter(lastDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  Color _getHeatmapColor(int count, int maxCount, bool isDarkMode) {
    final colors = isDarkMode ? darkModeColors : lightModeColors;

    // 无活动返回灰色
    if (count == 0) {
      return widget.cellColor ?? colors[0];
    }

    // 计算颜色级别
    int level;
    if (maxCount <= 1) {
      // 如果最大值是1，则直接使用第一个颜色
      level = 1;
    } else if (count == maxCount) {
      // 如果是最大值，使用最深的颜色
      level = colors.length - 1;
    } else {
      // 使用线性比例计算颜色级别
      final ratio = count / maxCount;
      level = (ratio * (colors.length - 2)).round() + 1;
    }

    // 确保级别在有效范围内
    level = level.clamp(1, colors.length - 1);
    return colors[level];
  }
}
