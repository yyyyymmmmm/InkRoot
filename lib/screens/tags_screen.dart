import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/themes/app_typography.dart';
import 'package:inkroot/utils/logger.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/utils/tag_path_utils.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:inkroot/widgets/tag_tree_item.dart';
import 'package:provider/provider.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController =
      TextEditingController(); // 搜索控制器
  String _searchQuery = ''; // 搜索关键词
  late AnimationController _animationController;
  bool _expandAll = false; // 🌳 是否展开所有子分类
  bool _isSearching = false; // 🔍 是否正在搜索
  bool _didRequestTagRefresh = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // 🚀 初始化（静默）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotes();

      // 只在首次进入时触发一次标签刷新，避免每次切换到标签页都做全量扫描导致卡顿
      if (!_didRequestTagRefresh) {
        _didRequestTagRefresh = true;
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.refreshAllNoteTagsWithDatabase().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 不要在这里跟随 AppProvider 全量变化去 setState；会导致路由切换/同步时频繁重建，体感卡顿
  }

  void _refreshNotes() {
    // 🚀 刷新（静默）
    setState(() {});
  }

  // 导航到标签详情页（使用 pushNamed 避免URL特殊字符问题）
  void _navigateToTagNotes(String tag) {
    Log.ui.debug(
      'Navigate to tag notes',
      data: {'tag': tag, 'tagLength': tag.length},
    );

    // 🛡️ 确保标签不为空
    if (tag.isEmpty || tag.trim().isEmpty) {
      Log.ui.warning('Ignored empty tag navigation');
      return;
    }

    // 🎯 使用 pushNamed + queryParameters，GoRouter 会自动处理参数编码
    try {
      context.pushNamed(
        'tag-notes',
        queryParameters: {'tag': tag}, // GoRouter 会自动编码
      );
    } on Object catch (e, stackTrace) {
      Log.ui.error(
        'Failed to navigate to tag notes',
        error: e,
        stackTrace: stackTrace,
        data: {'tag': tag},
      );
      // 显示错误提示
      if (mounted) {
        SnackBarUtils.showError(context, '无法打开标签页面: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 构建UI（静默）
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final tags = _visibleNormalizedTags(appProvider);
        // 🚀 标签统计（静默）

        return ResponsiveLayout(
          mobile: _buildMobileLayout(
            context,
            appProvider,
            backgroundColor,
            cardColor,
            textColor,
            secondaryTextColor,
            iconColor,
            tags,
          ),
          tablet: _buildTabletLayout(
            context,
            appProvider,
            backgroundColor,
            cardColor,
            textColor,
            secondaryTextColor,
            iconColor,
            tags,
          ),
          desktop: _buildDesktopLayout(
            context,
            appProvider,
            backgroundColor,
            cardColor,
            textColor,
            secondaryTextColor,
            iconColor,
            tags,
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppProvider appProvider,
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color? secondaryTextColor,
    Color iconColor,
    List<String> tags,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: _buildResponsiveAppBar(
        context,
        backgroundColor,
        textColor,
        iconColor,
      ),
      drawer: const Sidebar(),
      // 🎯 大厂标准：侧滑区域设为屏幕20%（参考微信/支付宝）
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
      body: Column(
        children: [
          // 🔍 搜索框（参考Apple iOS设计）
          if (_isSearching) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 搜索框
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizationsSimple.of(context)?.searchTags ??
                                  '搜索标签',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: isDarkMode
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF8E8E93),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 取消按钮（iOS风格）
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      AppLocalizationsSimple.of(context)?.cancel ?? '取消',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 标签内容（点击空白处仅收起键盘，不清空搜索）
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSearching) {
                  FocusScope.of(context).unfocus();
                }
              },
              behavior: HitTestBehavior.translucent,
              child: _buildTagsContent(
                context,
                cardColor,
                textColor,
                secondaryTextColor,
                iconColor,
                tags,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    AppProvider appProvider,
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color? secondaryTextColor,
    Color iconColor,
    List<String> tags,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: _buildResponsiveAppBar(
        context,
        backgroundColor,
        textColor,
        iconColor,
      ),
      drawer: const Sidebar(),
      // 🎯 大厂标准：侧滑区域设为屏幕20%（参考微信/支付宝）
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
      body: Column(
        children: [
          // 🔍 搜索框（参考Apple iOS设计）
          if (_isSearching) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 搜索框
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizationsSimple.of(context)?.searchTags ??
                                  '搜索标签',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: isDarkMode
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF8E8E93),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 取消按钮（iOS风格）
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      AppLocalizationsSimple.of(context)?.cancel ?? '取消',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 标签内容（点击空白处仅收起键盘，不清空搜索）
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSearching) {
                  FocusScope.of(context).unfocus();
                }
              },
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                  ),
                  child: _buildTagsContent(
                    context,
                    cardColor,
                    textColor,
                    secondaryTextColor,
                    iconColor,
                    tags,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppProvider appProvider,
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color? secondaryTextColor,
    Color iconColor,
    List<String> tags,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isDesktop ? null : const Sidebar(),
      drawerEdgeDragWidth:
          isDesktop ? null : MediaQuery.of(context).size.width * 0.2,
      appBar: _buildResponsiveAppBar(
        context,
        backgroundColor,
        textColor,
        iconColor,
        showDrawerButton: !isDesktop,
      ),
      body: Column(
        children: [
          // 🔍 搜索框（参考Apple iOS设计）
          if (_isSearching) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 搜索框
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '搜索标签',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: isDarkMode
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF8E8E93),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 取消按钮（iOS风格）
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 标签内容（点击空白处关闭搜索）
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSearching) {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                }
              },
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtils.getMaxContentWidth(context),
                  ),
                  child: _buildTagsContent(
                    context,
                    cardColor,
                    textColor,
                    secondaryTextColor,
                    iconColor,
                    tags,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(
    BuildContext context,
    Color backgroundColor,
    Color textColor,
    Color iconColor, {
    bool showDrawerButton = true,
  }) =>
      AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: showDrawerButton
            ? IconButton(
                icon: Container(
                  padding: ResponsiveUtils.responsivePadding(context, all: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveSpacing(context, 8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: ResponsiveUtils.responsiveSpacing(context, 16),
                        height: ResponsiveUtils.responsiveSpacing(context, 2),
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context, 4),
                      ),
                      Container(
                        width: ResponsiveUtils.responsiveSpacing(context, 10),
                        height: ResponsiveUtils.responsiveSpacing(context, 2),
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Text(
          AppLocalizationsSimple.of(context)?.allTags ?? '全部标签',
          style: AppTypography.getTitleStyle(
            context,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          // 🌳 展开/收起所有子分类
          PopupMenuButton<String>(
            icon: Container(
              padding: ResponsiveUtils.responsivePadding(context, all: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveSpacing(context, 8),
                ),
              ),
              child: Icon(
                _expandAll ? Icons.unfold_less : Icons.unfold_more,
                size: ResponsiveUtils.responsiveIconSize(context, 20),
                color: iconColor,
              ),
            ),
            tooltip: '展开选项',
            onSelected: (value) {
              setState(() {
                _expandAll = value == 'expand';
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'expand',
                child: Row(
                  children: [
                    Icon(
                      Icons.unfold_more,
                      size: 20,
                      color: _expandAll ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizationsSimple.of(context)?.expandAll ?? '展开所有',
                      style: TextStyle(
                        color: _expandAll ? AppTheme.primaryColor : textColor,
                        fontWeight:
                            _expandAll ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (_expandAll) ...[
                      const Spacer(),
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'collapse',
                child: Row(
                  children: [
                    Icon(
                      Icons.unfold_less,
                      size: 20,
                      color: !_expandAll ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizationsSimple.of(context)?.collapseAll ?? '收起所有',
                      style: TextStyle(
                        color: !_expandAll ? AppTheme.primaryColor : textColor,
                        fontWeight:
                            !_expandAll ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (!_expandAll) ...[
                      const Spacer(),
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // 🔍 搜索按钮
          IconButton(
            icon: Container(
              padding: ResponsiveUtils.responsivePadding(context, all: 8),
              decoration: BoxDecoration(
                color: _isSearching
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : backgroundColor,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveSpacing(context, 8),
                ),
              ),
              child: Icon(
                Icons.search,
                size: ResponsiveUtils.responsiveIconSize(context, 20),
                color: _isSearching ? AppTheme.primaryColor : iconColor,
              ),
            ),
            tooltip: AppLocalizationsSimple.of(context)?.searchTags ?? '搜索标签',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  // 再次点击搜索按钮：关闭搜索
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  // 展开搜索框
                  _isSearching = true;
                }
              });
            },
          ),
          SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 8)),
        ],
      );

  Widget _buildTagsContent(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color? secondaryTextColor,
    Color iconColor,
    List<String> tags,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredTags = query.isEmpty
        ? tags
        : tags
            .where(
              (tag) => tag.toLowerCase().contains(query),
            )
            .toList();

    return Column(
      children: [
        // 🏷️ 标签列表区域（占据全部剩余空间）
        Expanded(
          child: filteredTags.isEmpty
              ? _buildEmptyState(
                  context,
                  secondaryTextColor,
                  _searchQuery.isNotEmpty ? '未找到匹配的标签' : '暂无标签',
                  Icons.label_outline,
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  child: _buildTreeView(filteredTags),
                ),
        ),
      ],
    );
  }

  List<String> _visibleNormalizedTags(AppProvider appProvider) {
    final tags = <String>{};
    for (final note in appProvider.notes) {
      for (final tag in note.tags) {
        final normalized = normalizeTagPath(tag);
        if (normalized != null) {
          tags.add(normalized);
        }
      }
    }
    return tags.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color? secondaryTextColor,
    String message,
    IconData icon,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 精美插图
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
            Text(
              _searchQuery.isEmpty
                  ? (AppLocalizationsSimple.of(context)?.noTagsYet ?? '还没有任何标签')
                  : (AppLocalizationsSimple.of(context)?.noMatchingTags ??
                      '未找到匹配的标签'),
              style: AppTypography.getBodyStyle(
                context,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 16)),
            Text(
              _searchQuery.isEmpty
                  ? (AppLocalizationsSimple.of(context)?.tagsHelp ??
                      '标签可以帮助你更好地组织和查找笔记')
                  : (AppLocalizationsSimple.of(context)?.tryOtherKeywords ??
                      '尝试使用其他关键词搜索'),
              style: AppTypography.getCaptionStyle(
                context,
                color: secondaryTextColor,
              ).copyWith(fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 48)),
              // 使用教程卡片（优化设计）
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            const Color(0xFF1E1E1E),
                            const Color(0xFF2A2A2A),
                          ]
                        : [
                            Colors.white,
                            Colors.grey[50]!,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 26,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          AppLocalizationsSimple.of(context)?.howToUseTags ??
                              '如何使用标签',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[900],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTipItem(
                      isDarkMode,
                      Icons.tag_rounded,
                      AppLocalizationsSimple.of(context)?.createTagByTyping ??
                          '在笔记中输入 #标签名 创建标签',
                    ),
                    const SizedBox(height: 14),
                    _buildTipItem(
                      isDarkMode,
                      Icons.account_tree_rounded,
                      AppLocalizationsSimple.of(context)?.hierarchicalTags ??
                          '使用 / 创建层级标签，如 #工作/项目A',
                    ),
                    const SizedBox(height: 14),
                    _buildTipItem(
                      isDarkMode,
                      Icons.touch_app_rounded,
                      AppLocalizationsSimple.of(context)?.clickTagToView ??
                          '点击标签查看所有相关笔记',
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
              // CTA 按钮（优化设计）
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.edit_rounded, size: 22),
                  label: Text(
                    AppLocalizationsSimple.of(context)?.startWriting ?? '开始写笔记',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(bool isDarkMode, IconData icon, String text) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[800]!.withValues(alpha: 0.3)
              : Colors.grey[100]!.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.grey[700]!.withValues(alpha: 0.3)
                : Colors.grey[200]!,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.5,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTreeView(List<String> tags) {
    // 🛡️ 过滤掉空标签
    final validTags =
        tags.where((tag) => tag.isNotEmpty && tag.trim().isNotEmpty).toList();

    if (validTags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '暂无标签',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final validTagSet = validTags.toSet();
    final tagNodes = _searchQuery.trim().isEmpty
        ? TagNode.buildTreeFromNoteTags(
            appProvider.notes.map((note) => note.tags),
          )
        : TagNode.buildTreeFromNoteTags(
            appProvider.notes.map(
              (note) => note.tags.where((tag) {
                final normalized = normalizeTagPath(tag);
                return normalized != null && validTagSet.contains(normalized);
              }),
            ),
          );

    if (tagNodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '暂无标签',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 💡 紧凑提示（仅在有层级标签时显示）
        if (tags.any((tag) => tag.contains('/')))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.hierarchicalTagsShort ??
                        '使用 / 创建层级标签（如 #工作/项目A）',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // 标签树
        ...tagNodes.map(
          (node) => TagTreeItem(
            key: ValueKey('${node.fullPath}_$_expandAll'), // 🔑 强制重建以应用展开状态
            node: node,
            onTagSelect: (tag) {
              // 用于其他场景（保留但不使用）
              if (kDebugMode) {
                debugPrint('🏷️ [标签页] onTagSelect: $tag');
              }
            },
            onTagTap: (tag) {
              // 🎯 大厂标准：单击标签名 → 跳转到标签笔记页
              if (kDebugMode) {
                debugPrint('🏷️ [标签页] 单击标签: $tag（跳转）');
              }
              _navigateToTagNotes(tag);
            },
            expandAll: _expandAll, // 🌳 传递展开状态
          ),
        ),
      ],
    );
  }
}
