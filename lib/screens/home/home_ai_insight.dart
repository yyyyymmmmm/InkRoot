import 'package:flutter/material.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/app_config_model.dart' as models;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/ai_enhanced_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import 'package:inkroot/providers/app_provider.dart';

/// AI 洞察功能模块（从 home_screen.dart 拆分）
///
/// 功能：
/// - AI 驱动的笔记洞察分析
/// - 支持关键词、时间范围、标签筛选
/// - 生成深度分析报告

/// 显示 AI 洞察对话框
void showAiInsightDialog(BuildContext context) {
  final appProvider = Provider.of<AppProvider>(context, listen: false);
  final appConfig = appProvider.appConfig.appConfig;

  // 检查AI功能
  if (!appConfig.aiEnabled) {
    SnackBarUtils.showWarning(context, '请先在设置中启用AI功能');
    return;
  }

  if (appConfig.aiApiUrl == null || appConfig.aiApiKey == null) {
    SnackBarUtils.showWarning(context, '请先在设置中配置AI API');
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AiInsightScreen(
        notes: appProvider.notes,
        appConfig: appConfig,
      ),
      fullscreenDialog: true,
    ),
  );
}

/// AI 洞察页面
class AiInsightScreen extends StatefulWidget {
  const AiInsightScreen({
    required this.notes,
    required this.appConfig,
    super.key,
  });

  final List<Note> notes;
  final models.AppConfig appConfig;

  @override
  State<AiInsightScreen> createState() => _AiInsightScreenState();
}

class _AiInsightScreenState extends State<AiInsightScreen> {
  final _keywordController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _selectedTags = {};
  final Set<String> _excludedTags = {};
  String _timeRange = 'all'; // all, week, month, year
  bool _isAnalyzing = false;
  String? _insightResult;
  bool _isIncludeTagsExpanded = false;
  bool _isExcludeTagsExpanded = false;
  String? _errorMessage;
  final GlobalKey _insightResultKey = GlobalKey();

  @override
  void dispose() {
    _keywordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 获取所有可用标签
  List<String> get _availableTags {
    final tags = <String>{};
    for (final note in widget.notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  /// 根据筛选条件过滤笔记
  List<Note> get _filteredNotes => widget.notes.where((note) {
        // 时间范围筛选
        if (_timeRange != 'all') {
          final now = DateTime.now();
          final noteDate = note.createdAt;
          switch (_timeRange) {
            case 'week':
              if (now.difference(noteDate).inDays > 7) return false;
              break;
            case 'month':
              if (now.difference(noteDate).inDays > 30) return false;
              break;
            case 'year':
              if (now.difference(noteDate).inDays > 365) return false;
              break;
          }
        }

        // 标签筛选
        if (_selectedTags.isNotEmpty) {
          if (!_selectedTags.any((tag) => note.tags.contains(tag))) {
            return false;
          }
        }

        // 排除标签
        if (_excludedTags.isNotEmpty) {
          if (_excludedTags.any((tag) => note.tags.contains(tag))) return false;
        }

        // 关键词筛选
        if (_keywordController.text.isNotEmpty) {
          if (!note.content
              .toLowerCase()
              .contains(_keywordController.text.toLowerCase())) {
            return false;
          }
        }

        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.psychology_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'AI 洞察',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 筛选区域
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 关键词输入
                  _buildSectionTitle(
                    context,
                    AppLocalizationsSimple.of(context)?.keywords ?? '关键词',
                    AppLocalizationsSimple.of(context)?.inputKeywords ??
                        '输入想要洞察的关键词',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keywordController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: '例如：工作、学习、思考...',
                      hintStyle:
                          TextStyle(color: subTextColor.withOpacity(0.5)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 时间范围
                  _buildSectionTitle(
                    context,
                    AppLocalizationsSimple.of(context)?.timeRange ?? '时间范围',
                    AppLocalizationsSimple.of(context)
                            ?.selectAnalysisTimeRange ??
                        '选择要分析的时间段',
                  ),
                  const SizedBox(height: 12),
                  _buildTimeRangeSelector(),

                  const SizedBox(height: 24),

                  // 包含标签
                  _buildSectionTitle(
                    context,
                    AppLocalizationsSimple.of(context)?.includeTags ?? '包含标签',
                    AppLocalizationsSimple.of(context)?.selectIncludeTags ??
                        '选择要包含的标签',
                  ),
                  const SizedBox(height: 12),
                  _buildTagSelector(
                    isInclude: true,
                    isExpanded: _isIncludeTagsExpanded,
                  ),
                  if (_availableTags.length > 10)
                    _buildExpandButton(isInclude: true),

                  const SizedBox(height: 24),

                  // 排除标签
                  _buildSectionTitle(
                    context,
                    AppLocalizationsSimple.of(context)?.excludeTags ?? '排除标签',
                    AppLocalizationsSimple.of(context)?.selectExcludeTags ??
                        '选择要排除的标签',
                  ),
                  const SizedBox(height: 12),
                  _buildTagSelector(
                    isInclude: false,
                    isExpanded: _isExcludeTagsExpanded,
                  ),
                  if (_availableTags.length > 10)
                    _buildExpandButton(isInclude: false),

                  const SizedBox(height: 24),

                  // 统计信息
                  _buildStatistics(),

                  const SizedBox(height: 24),

                  // 洞察结果
                  if (_insightResult != null) ...[
                    Container(
                      key: _insightResultKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            context,
                            AppLocalizationsSimple.of(context)
                                    ?.insightResults ??
                                '洞察结果',
                            AppLocalizationsSimple.of(context)
                                    ?.aiGeneratedAnalysis ??
                                'AI为您生成的深度分析',
                          ),
                          const SizedBox(height: 12),
                          _buildInsightResult(),
                        ],
                      ),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 底部操作按钮
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _startAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizationsSimple.of(context)?.analyzing ??
                                  '分析中...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizationsSimple.of(context)
                                      ?.startAnalysis ??
                                  '开始分析',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: subTextColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildTimeRangeOption('全部', 'all'),
        _buildTimeRangeOption('最近一周', 'week'),
        _buildTimeRangeOption('最近一月', 'month'),
        _buildTimeRangeOption('最近一年', 'year'),
      ],
    );
  }

  Widget _buildTimeRangeOption(String label, String value) {
    final isSelected = _timeRange == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _timeRange = value;
        });
      },
      backgroundColor: isDarkMode
          ? AppTheme.darkSurfaceColor
          : AppTheme.surfaceColor,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.primaryColor
            : (isDarkMode
                ? AppTheme.darkTextSecondaryColor
                : AppTheme.textSecondaryColor),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryColor
            : (isDarkMode ? Colors.white12 : Colors.black12),
      ),
    );
  }

  Widget _buildTagSelector({
    required bool isInclude,
    required bool isExpanded,
  }) {
    final tagsToShow = isExpanded ? _availableTags : _availableTags.take(10).toList();
    final selectedTags = isInclude ? _selectedTags : _excludedTags;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tagsToShow.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text('#$tag'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedTags.add(tag);
              } else {
                selectedTags.remove(tag);
              }
            });
          },
          backgroundColor: isDarkMode
              ? AppTheme.darkSurfaceColor
              : AppTheme.surfaceColor,
          selectedColor: isInclude
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? (isInclude ? AppTheme.primaryColor : Colors.red)
                : (isDarkMode
                    ? AppTheme.darkTextSecondaryColor
                    : AppTheme.textSecondaryColor),
          ),
          side: BorderSide(
            color: isSelected
                ? (isInclude ? AppTheme.primaryColor : Colors.red)
                : (isDarkMode ? Colors.white12 : Colors.black12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandButton({required bool isInclude}) {
    final isExpanded =
        isInclude ? _isIncludeTagsExpanded : _isExcludeTagsExpanded;

    return TextButton.icon(
      onPressed: () {
        setState(() {
          if (isInclude) {
            _isIncludeTagsExpanded = !_isIncludeTagsExpanded;
          } else {
            _isExcludeTagsExpanded = !_isExcludeTagsExpanded;
          }
        });
      },
      icon: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        size: 16,
      ),
      label: Text(isExpanded ? '收起' : '展开更多'),
    );
  }

  Widget _buildStatistics() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.description_outlined,
                  label: '符合条件',
                  value: '${_filteredNotes.length}',
                  color: AppTheme.primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDarkMode ? Colors.white12 : Colors.black12,
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.library_books_outlined,
                  label: '总笔记数',
                  value: '${widget.notes.length}',
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (_filteredNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDarkMode ? Colors.white12 : Colors.black12,
              height: 1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.label_outline,
                    label: '标签数',
                    value: '${_availableTags.length}',
                    color: Colors.blue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.text_fields,
                    label: '总字数',
                    value: _getTotalWordCount(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getTotalWordCount() {
    int totalCount = 0;
    for (final note in _filteredNotes) {
      totalCount += note.content.length;
    }
    if (totalCount > 10000) {
      return '${(totalCount / 10000).toStringAsFixed(1)}万';
    }
    return totalCount.toString();
  }

  Widget _buildInsightResult() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 分析结果',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _insightResult ?? '',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_insightResultKey.currentContext != null) {
        Scrollable.ensureVisible(
          _insightResultKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _startAnalysis() async {
    if (_filteredNotes.isEmpty) {
      setState(() {
        _errorMessage = '没有符合条件的笔记，请调整筛选条件';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _insightResult = null;
    });

    try {
      final aiService = AIEnhancedService();

      // 构建分析提示词
      final prompt = _buildAnalysisPrompt();

      // 调用 AI 分析
      final result = await aiService.analyzeNotes(
        prompt: prompt,
        notes: _filteredNotes,
        apiUrl: widget.appConfig.aiApiUrl!,
        apiKey: widget.appConfig.aiApiKey!,
      );

      if (!mounted) return;

      setState(() {
        _insightResult = result;
        _isAnalyzing = false;
      });

      // 滚动到结果
      _scrollToResult();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '分析失败：${e.toString()}';
        _isAnalyzing = false;
      });
    }
  }

  String _buildAnalysisPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('请对以下笔记进行深度分析：');
    buffer.writeln();

    if (_keywordController.text.isNotEmpty) {
      buffer.writeln('关键词：${_keywordController.text}');
    }

    if (_selectedTags.isNotEmpty) {
      buffer.writeln('包含标签：${_selectedTags.join(', ')}');
    }

    if (_excludedTags.isNotEmpty) {
      buffer.writeln('排除标签：${_excludedTags.join(', ')}');
    }

    buffer.writeln('时间范围：$_timeRange');
    buffer.writeln('共 ${_filteredNotes.length} 篇笔记');
    buffer.writeln();
    buffer.writeln('请从以下角度进行分析：');
    buffer.writeln('1. 主题分析：识别主要话题和思考方向');
    buffer.writeln('2. 趋势洞察：发现思维模式和变化趋势');
    buffer.writeln('3. 深度思考：提炼核心观点和价值');
    buffer.writeln('4. 建议：给出可行的改进建议');

    return buffer.toString();
  }
}
