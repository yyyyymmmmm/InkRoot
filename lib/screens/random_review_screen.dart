import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/image_cache_manager.dart'; // 🔥 添加长期缓存
import 'package:inkroot/utils/tag_utils.dart' as tag_utils;
import 'package:inkroot/utils/todo_parser.dart';
import 'package:inkroot/services/intelligent_related_notes_service.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/widgets/animated_checkbox.dart';
import 'package:inkroot/widgets/intelligent_related_notes_sheet.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:inkroot/widgets/note_more_options_menu.dart';
import 'package:inkroot/widgets/saveable_image.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:inkroot/widgets/simple_memo_content.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RandomReviewScreen extends StatefulWidget {
  const RandomReviewScreen({super.key});

  @override
  State<RandomReviewScreen> createState() => _RandomReviewScreenState();
}

class _RandomReviewScreenState extends State<RandomReviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final Random _random = Random();

  List<Note> _reviewNotes = [];
  int _currentIndex = 0;

  // 回顾设置
  int _reviewDays = 30; // 默认回顾最近30天的笔记
  int _reviewCount = 10; // 默认回顾10条笔记
  Set<String> _selectedTags = {}; // 选中的标签集合

  // 🧠 智能相关笔记
  bool _isLoadingRelatedNotes = false;
  final IntelligentRelatedNotesService _intelligentRelatedNotesService = 
      IntelligentRelatedNotesService();

  @override
  void initState() {
    super.initState();

    // 初始化时获取笔记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviewNotes();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 加载回顾笔记
  void _loadReviewNotes() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allNotes = appProvider.notes;

    if (allNotes.isEmpty) {
      setState(() {
        _reviewNotes = [];
        _currentIndex = 0;
      });
      return;
    }

    // 根据时间范围筛选笔记
    final cutoffDate = DateTime.now().subtract(Duration(days: _reviewDays));
    var filteredNotes =
        allNotes.where((note) => note.createdAt.isAfter(cutoffDate)).toList();

    // 🔥 根据选中的标签筛选笔记（AND关系 - 必须包含所有选中的标签）
    if (_selectedTags.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        // 提取笔记中的标签（使用改进的标签识别规则）
        final noteTags = tag_utils.extractTagsFromContent(note.content).toSet();
        // 检查笔记是否包含所有选中的标签（AND关系）
        return _selectedTags.every(noteTags.contains);
      }).toList();
    }

    // 如果筛选后的笔记不足，则使用全部笔记
    final availableNotes = filteredNotes.isEmpty ? allNotes : filteredNotes;

    // 随机选择指定数量的笔记
    var selectedNotes = <Note>[];
    if (availableNotes.length <= _reviewCount) {
      // 如果可用笔记少于请求的数量，全部使用
      selectedNotes = List.from(availableNotes);
    } else {
      // 随机选择笔记
      availableNotes.shuffle(_random);
      selectedNotes = availableNotes.take(_reviewCount).toList();
    }

    // 保持当前笔记的位置
    final currentNoteId = _currentIndex < _reviewNotes.length
        ? _reviewNotes[_currentIndex].id
        : '';
    final newIndex =
        selectedNotes.indexWhere((note) => note.id == currentNoteId);

    setState(() {
      _reviewNotes = selectedNotes;
      _currentIndex = newIndex != -1 ? newIndex : 0;
    });
  }

  // 🎯 切换笔记中指定索引的待办事项
  void _toggleTodoInNote(Note note, int todoIndex) {
    final todos = TodoParser.parseTodos(note.content);
    if (todoIndex < 0 || todoIndex >= todos.length) {
      if (kDebugMode) {
        debugPrint('RandomReviewScreen: 待办事项索引越界 $todoIndex/${todos.length}');
      }
      return;
    }

    final todo = todos[todoIndex];
    final newContent = TodoParser.toggleTodoAtLine(note.content, todo.lineNumber);
    if (kDebugMode) {
      debugPrint('RandomReviewScreen: 切换待办事项 #$todoIndex 行${todo.lineNumber}: "${todo.text}"');
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateNote(note, newContent).then((_) {
      if (kDebugMode) {
        debugPrint('RandomReviewScreen: 待办事项状态已更新');
      }
      _loadReviewNotes(); // 刷新笔记列表
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('RandomReviewScreen: 更新待办事项失败: $error');
      }
      SnackBarUtils.showError(context, '更新失败');
    });
  }

  // 🔥 获取所有可用的标签
  Set<String> _getAllTags() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final allNotes = appProvider.notes;
    final allTags = <String>{};

    // 使用改进的标签识别规则（排除URL中的#）
    for (final note in allNotes) {
      final tags = tag_utils.extractTagsFromContent(note.content);
      allTags.addAll(tags);
    }

    return allTags;
  }

  // 显示编辑笔记表单
  void _showEditNoteForm(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: note.content,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);
              _loadReviewNotes(); // 重新加载笔记
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${AppLocalizationsSimple.of(context)?.updatingFailed ?? '更新失败'}: $e',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  // 🔥 显示iOS风格的设置页面
  void _showSettingsDialog() {
    var tempDays = _reviewDays;
    var tempCount = _reviewCount;
    var tempSelectedTags = Set<String>.from(_selectedTags);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkCardColor : const Color(0xFFF2F2F7);
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final allTags = _getAllTags().toList()..sort();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 🔥 顶部拖动条和标题
                Container(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 拖动条
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: secondaryTextColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 标题栏
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizationsSimple.of(context)
                                      ?.reviewSettings ??
                                  '回顾设置',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _reviewDays = tempDays;
                                  _reviewCount = tempCount;
                                  _selectedTags = tempSelectedTags;
                                });
                                Navigator.pop(context);
                                _loadReviewNotes();
                              },
                              child: Text(
                                AppLocalizationsSimple.of(context)?.confirm ??
                                    '完成',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔥 设置内容（可滚动）
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📅 时间范围设置
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildSettingItem(
                                title: AppLocalizationsSimple.of(context)
                                        ?.reviewTimeRange ??
                                    '时间范围',
                                trailing: _buildOptionButton(
                                  tempDays == 999999
                                      ? (AppLocalizationsSimple.of(context)
                                              ?.all ??
                                          '全部')
                                      : '$tempDays ${AppLocalizationsSimple.of(context)?.dayUnit ?? '天'}',
                                  () => _showTimeRangePicker(context, tempDays,
                                      (value) {
                                    setModalState(() {
                                      tempDays = value;
                                    });
                                  }),
                                  isDarkMode,
                                ),
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 📊 回顾数量设置
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildSettingItem(
                                title: AppLocalizationsSimple.of(context)
                                        ?.reviewNotesCount ??
                                    '笔记数量',
                                trailing: _buildOptionButton(
                                  '$tempCount ${AppLocalizationsSimple.of(context)?.noteUnit ?? '条'}',
                                  () => _showCountPicker(context, tempCount,
                                      (value) {
                                    setModalState(() {
                                      tempCount = value;
                                    });
                                  }),
                                  isDarkMode,
                                ),
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🏷️ 标签筛选
                        if (allTags.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                            child: Text(
                              '🏷️ 标签筛选',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 全选/取消全选按钮
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tempSelectedTags.isEmpty
                                            ? '选择标签（全部）'
                                            : '已选 ${tempSelectedTags.length} 个标签',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setModalState(() {
                                          if (tempSelectedTags.isEmpty) {
                                            tempSelectedTags =
                                                Set.from(allTags);
                                          } else {
                                            tempSelectedTags.clear();
                                          }
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        tempSelectedTags.isEmpty ? '全选' : '清空',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 🔥 标签网格（限制最大高度，可滚动）
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 300, // 最大高度限制，避免溢出
                                  ),
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: allTags.map((tag) {
                                        final isSelected =
                                            tempSelectedTags.contains(tag);
                                        return GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              if (isSelected) {
                                                tempSelectedTags.remove(tag);
                                              } else {
                                                tempSelectedTags.add(tag);
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : (isDarkMode
                                                      ? Colors.grey[800]
                                                      : Colors.grey[200]),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppTheme.primaryColor
                                                    : Colors.transparent,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isSelected)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 4,
                                                    ),
                                                    child: Icon(
                                                      Icons.check,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                Text(
                                                  '#$tag',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : textColor,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
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
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 构建设置项
  Widget _buildSettingItem({
    required String title,
    required Widget trailing,
    required bool isDarkMode,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  // 🔥 构建选项按钮
  Widget _buildOptionButton(String text, VoidCallback onTap, bool isDarkMode) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      );

  // 🔥 显示时间范围选择器
  void _showTimeRangePicker(
    BuildContext context,
    int currentValue,
    Function(int) onSelect,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final options = [7, 14, 30, 60, 90, 180, 365, 999999];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizationsSimple.of(context)?.reviewTimeRange ?? '选择时间范围',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ...options.map((days) {
              final isSelected = days == currentValue;
              return ListTile(
                title: Text(
                  days == 999999
                      ? (AppLocalizationsSimple.of(context)?.all ?? '全部')
                      : '$days ${AppLocalizationsSimple.of(context)?.dayUnit ?? '天'}',
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  onSelect(days);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 🔥 显示数量选择器
  void _showCountPicker(
    BuildContext context,
    int currentValue,
    Function(int) onSelect,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final options = [5, 10, 20, 30, 50, 100];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizationsSimple.of(context)?.reviewNotesCount ??
                    '选择笔记数量',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ...options.map((count) {
              final isSelected = count == currentValue;
              return ListTile(
                title: Text(
                  '$count ${AppLocalizationsSimple.of(context)?.noteUnit ?? '条'}',
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : null,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  onSelect(count);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 处理页面变化
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 打开侧边栏
  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // 🔥 处理链接点击
  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) return;

    try {
      // 处理笔记内部引用 [[noteId]]
      if (href.startsWith('[[') && href.endsWith(']]')) {
        final noteId = href.substring(2, href.length - 2);
        if (mounted) {
          Navigator.of(context).pushNamed('/note/$noteId');
        }
        return;
      }

      // 处理外部链接
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${AppLocalizationsSimple.of(context)?.cannotOpenLink ?? '无法打开链接'}: $href',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizationsSimple.of(context)?.linkError ?? '链接错误'}: $e',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // 🔥 复制笔记内容
  Future<void> _copyNoteContent(Note note) async {
    await Clipboard.setData(ClipboardData(text: note.content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                AppLocalizationsSimple.of(context)?.copiedToClipboard ??
                    '已复制到剪贴板',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // 处理标签和Markdown内容
  Widget _buildContent(Note note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : const Color(0xFF333333);
    final secondaryTextColor =
        isDarkMode ? Colors.grey[400] : const Color(0xFF666666);
    final codeBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

    final content = note.content;

    // 🔥 从resourceList中提取图片
    final imagePaths = <String>[];
    for (final resource in note.resourceList) {
      final uid = resource['uid'] as String?;
      if (uid != null) {
        imagePaths.add('/o/r/$uid');
      }
    }

    // 从content中提取Markdown格式的图片
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final imageMatches = imageRegex.allMatches(content);
    for (final match in imageMatches) {
      final path = match.group(1) ?? '';
      if (path.isNotEmpty && !imagePaths.contains(path)) {
        imagePaths.add(path);
      }
    }

    // 将图片从内容中移除
    var contentWithoutImages = content;
    for (final match in imageMatches) {
      contentWithoutImages =
          contentWithoutImages.replaceAll(match.group(0) ?? '', '');
    }
    contentWithoutImages = contentWithoutImages.trim();

    // 首先处理标签
    // 🎯 改进的标签识别规则（参考Obsidian/Notion/Logseq，排除URL中的#）
    final tagRegex = tag_utils.getTagRegex();
    final parts = contentWithoutImages.split(tagRegex);
    final matches = tagRegex.allMatches(contentWithoutImages);

    final contentWidgets = <Widget>[];
    var matchIndex = 0;

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        // 非标签部分用Markdown渲染
        contentWidgets.add(
          MarkdownBody(
            data: parts[i],
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubFlavored, // 🎯 启用GitHub风格Markdown（支持待办事项）
            checkboxBuilder: (value) {
              // 🎯 优雅的动画复选框（只读模式）
              return AnimatedCheckbox(
                value: value ?? false,
                onChanged: null, // 只读模式
                size: 20,
                borderRadius: 6,
              );
            },
            onTapLink: (text, href, title) => _handleLinkTap(href),
            imageBuilder: (uri, title, alt) {
              // 处理图片URL
              final imagePath = uri.toString();
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(imagePath),
                ),
              );
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
              ),
              h1: TextStyle(
                fontSize: 20,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              h2: TextStyle(
                fontSize: 18,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              h3: TextStyle(
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              code: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2,
                color: textColor,
                backgroundColor: codeBgColor,
                fontFamily: 'monospace',
              ),
              blockquote: TextStyle(
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.2,
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }

      // 添加标签 - 更新为与主页一致的样式
      if (matchIndex < matches.length && i < parts.length - 1) {
        final tag = matches.elementAt(matchIndex).group(1)!;
        contentWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#$tag',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        matchIndex++;
      }
    }

    // 构建最终内容，包括文本和图片
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contentWidgets.isNotEmpty)
          Wrap(
            spacing: 2,
            runSpacing: 4,
            children: contentWidgets,
          ),
        // 🔥 显示图片网格
        if (imagePaths.isNotEmpty) ...[
          if (contentWidgets.isNotEmpty) const SizedBox(height: 12),
          _buildImageGrid(imagePaths),
        ],
      ],
    );
  }

  // 🔥 构建图片网格
  Widget _buildImageGrid(List<String> imagePaths) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 4.0;
          final imageWidth = (constraints.maxWidth - spacing * 2) / 3;
          final imageCount = imagePaths.length > 9 ? 9 : imagePaths.length;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(imageCount, (index) {
              final imagePath = imagePaths[index];
              return _buildImageItem(imagePath, imageWidth);
            }),
          );
        },
      );

  // 🔥 构建单个图片项
  Widget _buildImageItem(String imagePath, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _buildImageWidget(imagePath),
        ),
      );


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final bottomInfoBgColor =
        isDarkMode ? Colors.grey[850] : Colors.grey.shade100;

    // 侧边栏由DesktopLayout处理
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isDesktop ? null : const Sidebar(),
      drawerEdgeDragWidth: isDesktop ? null : MediaQuery.of(context).size.width * 0.2,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: isDesktop ? null : IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 2,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          onPressed: _openDrawer,
        ),
        centerTitle: true,
        title: Text(
          AppLocalizationsSimple.of(context)?.randomReviewTitle ?? '随机回顾',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.settings,
                size: 20,
                color: iconColor,
              ),
            ),
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_reviewNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 80,
                    color: isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizationsSimple.of(context)?.noNotesToReview ??
                        '没有可回顾的笔记',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            itemCount: _reviewNotes.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final note = _reviewNotes[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 时间显示
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm:ss')
                                  .format(note.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                            Builder(
                              builder: (btnContext) => InkWell(
                                onTap: () {
                                  NoteMoreOptionsMenu.show(
                                    context: btnContext,
                                    note: note,
                                    onNoteUpdated: _loadReviewNotes,
                                  );
                                },
                                child: Icon(
                                  Icons.more_horiz,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 笔记内容（双击编辑）
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: () => _showEditNoteForm(note),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Builder(
                                builder: (context) {
                                  final serverUrl = Provider.of<AppProvider>(
                                    context,
                                    listen: false,
                                  ).appConfig.memosApiUrl;

                                  // 从resourceList提取图片并添加到content
                                  var contentWithImages = note.content;
                                  final hasImagesInContent =
                                      RegExp(r'!\[.*?\]\((.*?)\)')
                                          .hasMatch(contentWithImages);

                                  if (!hasImagesInContent &&
                                      note.resourceList.isNotEmpty) {
                                    final imagePaths = <String>[];
                                    for (final resource in note.resourceList) {
                                      final uid = resource['uid'] as String?;
                                      if (uid != null) {
                                        imagePaths.add('/o/r/$uid');
                                      }
                                    }

                                    if (imagePaths.isNotEmpty) {
                                      contentWithImages += '\n\n';
                                      for (final path in imagePaths) {
                                        contentWithImages += '![]($path)\n';
                                      }
                                    }
                                  }

                                  return SimpleMemoContent(
                                    content: contentWithImages,
                                    serverUrl: serverUrl,
                                    note: note, // 🎯 传入note对象
                                    onCheckboxTap: (index) => _toggleTodoInNote(note, index), // 🎯 复选框点击回调（传递索引）
                                    onLinkTap: _handleLinkTap,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 底部导航 - 只显示笔记计数
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 当前笔记索引/总数
                            Text(
                              '${index + 1}/${_reviewNotes.length}${AppLocalizationsSimple.of(context)?.itemsNote ?? '条笔记'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // 🧠 智能相关笔记按钮（与详情页样式一致）
      floatingActionButton: _reviewNotes.isNotEmpty
          ? _buildAIRelatedNotesFAB(isDarkMode)
          : null,
    );
  }

  // 构建图片组件，支持不同类型的图片源
  Widget _buildImageWidget(String imagePath) {
    try {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        // 🚀 网络图片 - 90天缓存，支持长按保存
        return SaveableImage(
          imageUrl: imagePath,
          child: CachedNetworkImage(
            imageUrl: imagePath,
            cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const SizedBox(),
            ),
            errorWidget: (context, url, error) {
              // 🔥 离线模式：尝试从缓存加载
              return FutureBuilder<File?>(
                future: ImageCacheManager.authImageCache
                    .getFileFromCache(url)
                    .then((info) => info?.file),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.file(snapshot.data!, fit: BoxFit.cover);
                  }
                  return Center(
                    child: Icon(Icons.broken_image, color: Colors.grey[600]),
                  );
                },
              );
            },
          ),
        );
      } else if (imagePath.startsWith('/o/r/') ||
          imagePath.startsWith('/file/') ||
          imagePath.startsWith('/resource/')) {
        // Memos服务器资源路径
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        if (appProvider.resourceService != null) {
          final fullUrl = appProvider.resourceService!.buildImageUrl(imagePath);
          final token = appProvider.user?.token;
          if (kDebugMode) {
            debugPrint(
              'RandomReview: 构建图片 - 原路径: $imagePath, URL: $fullUrl, 有Token: ${token != null}',
            );
          }

          final headers = <String, String>{};
          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }

          // 🚀 使用90天缓存，支持长按保存
          return SaveableImage(
            imageUrl: fullUrl,
            headers: headers,
            child: SizedBox(
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
                httpHeaders: headers,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const SizedBox(),
                ),
                errorWidget: (context, url, error) {
                  if (kDebugMode) {
                    debugPrint(
                      'RandomReview: 图片加载失败 - URL: $fullUrl, 错误: $error',
                    );
                  }
                  // 🔥 离线模式：尝试从缓存加载
                  return FutureBuilder<File?>(
                    future: ImageCacheManager.authImageCache
                        .getFileFromCache(fullUrl)
                        .then((info) => info?.file),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.file(snapshot.data!, fit: BoxFit.cover);
                      }
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        } else {
          // 如果没有资源服务，尝试使用基础URL（🔥 即使退出登录也能加载缓存）
          final baseUrl = appProvider.user?.serverUrl ??
              appProvider.appConfig.lastServerUrl ??
              appProvider.appConfig.memosApiUrl ??
              '';
          if (baseUrl.isNotEmpty) {
            final token = appProvider.user?.token;
            final fullUrl = '$baseUrl$imagePath';
            if (kDebugMode) {
              debugPrint(
                'RandomReview: 加载图片(fallback) - URL: $fullUrl, 有Token: ${token != null}',
              );
            }
            final headers = <String, String>{};
            if (token != null) {
              headers['Authorization'] = 'Bearer $token';
            }
            return SaveableImage(
              imageUrl: fullUrl,
              headers: headers,
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                cacheManager: ImageCacheManager.authImageCache, // 🔥 90天缓存
                httpHeaders: headers,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) {
                  // 🔥 离线模式
                  return FutureBuilder<File?>(
                    future: ImageCacheManager.authImageCache
                        .getFileFromCache(fullUrl)
                        .then((info) => info?.file),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.file(snapshot.data!, fit: BoxFit.cover);
                      }
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
        }
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      } else if (imagePath.startsWith('file://')) {
        // 本地文件
        final filePath = imagePath.replaceFirst('file://', '');
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      } else {
        // 其他情况，尝试作为资源或本地文件处理
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'RandomReview Error in _buildImageWidget: $e for $imagePath',
        );
      }
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  /// 🧠 构建智能相关笔记FAB（与详情页样式一致 - 炫酷脉冲动画）
  Widget _buildAIRelatedNotesFAB(bool isDark) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 1.1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [AppTheme.primaryLightColor, AppTheme.accentColor]
                    : [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                        AppTheme.primaryLightColor,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? AppTheme.primaryLightColor
                          : AppTheme.primaryColor)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _isLoadingRelatedNotes ? null : _findRelatedNotes,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: _isLoadingRelatedNotes
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
        onEnd: () {
          // 反向动画
          if (mounted) {
            setState(() {});
          }
        },
      );

  /// 🧠 查找并显示当前笔记的智能相关笔记
  Future<void> _findRelatedNotes() async {
    if (_reviewNotes.isEmpty || _currentIndex >= _reviewNotes.length) return;
    
    final currentNote = _reviewNotes[_currentIndex];

    setState(() {
      _isLoadingRelatedNotes = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 🧠 使用智能相关笔记服务进行分析
      final result = await _intelligentRelatedNotesService.findIntelligentRelatedNotes(
        currentNote: currentNote,
        allNotes: appProvider.notes,
        apiKey: appProvider.appConfig.aiApiKey,
        apiUrl: appProvider.appConfig.aiApiUrl,
        model: appProvider.appConfig.aiModel,
      );

      setState(() {
        _isLoadingRelatedNotes = false;
      });

      // 显示智能相关笔记结果
      if (!mounted) return;
      
      if (result.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          AppLocalizationsSimple.of(context)?.aiRelatedNotesEmpty ??
              '未找到相关笔记',
        );
      } else {
        // 🎨 显示现代化的智能相关笔记抽屉
        await IntelligentRelatedNotesSheet.show(context, result);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ 查找相关笔记失败: $e');
      setState(() {
        _isLoadingRelatedNotes = false;
      });
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '查找相关笔记失败：${e.toString()}',
        );
      }
    }
  }
}
