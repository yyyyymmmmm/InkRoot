import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/themes/app_typography.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
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
  String _sortMode = 'name'; // 排序模式: 'name'(名称), 'count'(笔记数), 'time'(最近使用)
  late AnimationController _animationController;
  bool _expandAll = false; // 🌳 是否展开所有子分类
  bool _isSearching = false; // 🔍 是否正在搜索

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

      // 🎯 每次进入标签页都自动刷新标签列表（静默，无加载提示）
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.refreshAllNoteTagsWithDatabase().then((_) {
        if (mounted) {
          setState(() {}); // 刷新UI
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🎨 根据标签名生成渐变色
  List<Color> _generateGradientColors(String tag) {
    final hash = tag.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final color1 = HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
    final color2 = HSLColor.fromAHSL(1, (hue + 30) % 360, 0.7, 0.5).toColor();
    return [color1, color2];
  }

  // 🎨 根据标签名生成单一主色
  Color _generateTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.65, 0.55).toColor();
  }

  // 📊 获取标签对应的笔记数量
  int _getTagNoteCount(String tag, AppProvider appProvider) =>
      appProvider.notes.where((note) => note.tags.contains(tag)).length;

  // 📊 根据笔记数量获取热度等级 (1-5)
  int _getTagHeatLevel(int noteCount, int maxCount) {
    if (maxCount == 0) return 1;
    final ratio = noteCount / maxCount;
    if (ratio >= 0.8) return 5;
    if (ratio >= 0.6) return 4;
    if (ratio >= 0.4) return 3;
    if (ratio >= 0.2) return 2;
    return 1;
  }

  // 🔄 标签列表（树状视图保持层级结构）
  List<String> _sortTags(List<String> tags, AppProvider appProvider) {
    // 🎯 树状视图始终保持层级结构，不进行排序
    return tags;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听AppProvider的变化
    final appProvider = Provider.of<AppProvider>(context);
    // 笔记和标签数据更新

    // 每次AppProvider变化时都重新加载标签
    _refreshNotes();
  }

  void _refreshNotes() {
    // 🚀 刷新（静默）
    setState(() {});
  }

  // 扫描笔记并更新所有标签
  Future<void> _scanAllNoteTags() async {
    // 🚀 扫描标签（静默）
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 显示加载中对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveSpacing(context, 16),
          ),
        ),
        content: Container(
          padding: ResponsiveUtils.responsivePadding(context, all: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: ResponsiveUtils.responsiveIconSize(context, 24),
                height: ResponsiveUtils.responsiveIconSize(context, 24),
                child: const CircularProgressIndicator(),
              ),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 16)),
              Text(
                '正在扫描所有笔记中的标签...',
                style: AppTypography.getBodyStyle(context),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 调用AppProvider的方法扫描所有笔记的标签
      await appProvider.refreshAllNoteTagsWithDatabase();

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框

        // 重新加载标签
        _refreshNotes();

        // 显示成功提示
        SnackBarUtils.showSuccess(
          context,
          AppLocalizationsSimple.of(context)?.tagScanComplete ?? '标签扫描完成',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框

        // 显示错误提示
        SnackBarUtils.showError(
          context,
          '${AppLocalizationsSimple.of(context)?.tagScanFailed ?? '标签扫描失败'}: $e',
        );
      }
    }
  }

  // 导航到标签详情页（使用 pushNamed 避免URL特殊字符问题）
  void _navigateToTagNotes(String tag) {
    print('🏷️ [导航] 准备跳转到标签笔记页面');
    print('🏷️ [导航] 标签名称: "$tag"');
    print('🏷️ [导航] 标签名长度: ${tag.length}');
    
    // 🛡️ 确保标签不为空
    if (tag.isEmpty || tag.trim().isEmpty) {
      print('⚠️ [导航] 标签为空，取消导航');
      return;
    }

    // 🎯 使用 pushNamed + queryParameters，GoRouter 会自动处理参数编码
    try {
      print('🏷️ [导航] 使用 context.pushNamed 方式导航');
      context.pushNamed(
        'tag-notes',
        queryParameters: {'tag': tag}, // GoRouter 会自动编码
      );
      print('✅ [导航] 导航命令已发送');
    } catch (e, stackTrace) {
      print('❌ [导航] 导航失败: $e');
      print('❌ [导航] 堆栈跟踪: $stackTrace');
      print('❌ [导航] 标签名: "$tag"');
      // 显示错误提示
      if (mounted) {
        SnackBarUtils.showError(context, '无法打开标签页面: ${e.toString()}');
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
    final tagSelectedBgColor =
        isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFEDF3FF);
    final tagSelectedTextColor =
        isDarkMode ? const Color(0xFF82B1FF) : Colors.blue;
    final tagBorderColor =
        isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.grey.shade300;
    final tagUnselectedBgColor =
        isDarkMode ? AppTheme.darkCardColor : Colors.white;

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final tags = appProvider.getAllTags().toList(); // 🔄 不在这里排序，由 _sortTags 统一处理
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
                          hintText: AppLocalizationsSimple.of(context)?.searchTags ?? '搜索标签',
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
                          hintText: AppLocalizationsSimple.of(context)?.searchTags ?? '搜索标签',
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
      
      final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);
      
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        drawer: isDesktop ? null : const Sidebar(),
        drawerEdgeDragWidth: isDesktop ? null : MediaQuery.of(context).size.width * 0.2,
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
                      child: Text(
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
        centerTitle: ResponsiveUtils.isMobile(context) ? true : true,
        leading: showDrawerButton ? IconButton(
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
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 4)),
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
        ) : null,
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
                        fontWeight: _expandAll ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (_expandAll) ...[
                      const Spacer(),
                    Icon(
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
                        fontWeight: !_expandAll ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (!_expandAll) ...[
                      const Spacer(),
                      Icon(
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
          // 🔄 排序按钮已删除（树状图不需要排序）
          if (false)
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
                  Icons.sort,
                size: ResponsiveUtils.responsiveIconSize(context, 20),
                color: iconColor,
              ),
            ),
              tooltip: '排序标签',
            onSelected: (value) {
              print('🔄 排序模式切换: $_sortMode -> $value');
                setState(() {
                _sortMode = value;
              });
              print('🔄 排序模式已更新为: $_sortMode');
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 20,
                      color: _sortMode == 'name' ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(
                            '按名称',
                      style: TextStyle(
                              color: _sortMode == 'name' ? AppTheme.primaryColor : textColor,
                              fontWeight: _sortMode == 'name' ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          Text(
                            'A → Z',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_sortMode == 'name')
                      Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'count',
                              child: Row(
                                children: [
                    Icon(
                      Icons.numbers,
                      size: 20,
                      color: _sortMode == 'count' ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                  Text(
                            '按笔记数',
                                    style: TextStyle(
                              color: _sortMode == 'count' ? AppTheme.primaryColor : textColor,
                              fontWeight: _sortMode == 'count' ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                                  Text(
                            '多 → 少',
                                    style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    if (_sortMode == 'count')
                      Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'time',
                            child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: _sortMode == 'time' ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                            '按最近使用',
                                  style: TextStyle(
                              color: _sortMode == 'time' ? AppTheme.primaryColor : textColor,
                              fontWeight: _sortMode == 'time' ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          Text(
                            '新 → 旧',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                      ),
                                ),
                              ],
                            ),
                          ),
                    if (_sortMode == 'time')
                      Icon(
                        Icons.check,
                        size: 18,
                        color: AppTheme.primaryColor,
              ),
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
                color: _isSearching ? AppTheme.primaryColor.withOpacity(0.15) : backgroundColor,
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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 根据搜索关键词过滤标签
    print('🏷️ 开始过滤标签 - 搜索关键词: "$_searchQuery", 总标签数: ${tags.length}');
    var filteredTags = _searchQuery.isEmpty
        ? tags
        : tags
            .where(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
    print('🏷️ 过滤后的标签数: ${filteredTags.length}');
    if (filteredTags.length <= 5) {
      print('🏷️ 过滤结果: $filteredTags');
    }

    // 🔄 应用排序
    filteredTags = _sortTags(filteredTags, appProvider);

    // 📊 计算最大笔记数量（用于热度可视化）
    final maxNoteCount = filteredTags.isEmpty
        ? 1
        : filteredTags
            .map((tag) => _getTagNoteCount(tag, appProvider))
            .reduce((a, b) => a > b ? a : b);

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
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
              icon,
                size: 80,
                color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
            Text(
              _searchQuery.isEmpty ? (AppLocalizationsSimple.of(context)?.noTagsYet ?? '还没有任何标签') : (AppLocalizationsSimple.of(context)?.noMatchingTags ?? '未找到匹配的标签'),
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
                  ? (AppLocalizationsSimple.of(context)?.tagsHelp ?? '标签可以帮助你更好地组织和查找笔记')
                  : (AppLocalizationsSimple.of(context)?.tryOtherKeywords ?? '尝试使用其他关键词搜索'),
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
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
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
                                AppTheme.primaryColor.withOpacity(0.15),
                                AppTheme.primaryColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 26,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          AppLocalizationsSimple.of(context)?.howToUseTags ?? '如何使用标签',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTipItem(
                      isDarkMode,
                      Icons.tag_rounded,
                      AppLocalizationsSimple.of(context)?.createTagByTyping ?? '在笔记中输入 #标签名 创建标签',
                    ),
                    const SizedBox(height: 14),
                    _buildTipItem(
                      isDarkMode,
                      Icons.account_tree_rounded,
                      AppLocalizationsSimple.of(context)?.hierarchicalTags ?? '使用 / 创建层级标签，如 #工作/项目A',
                    ),
                    const SizedBox(height: 14),
                    _buildTipItem(
                      isDarkMode,
                      Icons.touch_app_rounded,
                      AppLocalizationsSimple.of(context)?.clickTagToView ?? '点击标签查看所有相关笔记',
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 32)),
              // CTA 按钮（优化设计）
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
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
  
  Widget _buildTipItem(bool isDarkMode, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey[800]!.withOpacity(0.3)
            : Colors.grey[100]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.grey[700]!.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
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
  }

  Widget _buildTreeView(List<String> tags) {
    // 🛡️ 过滤掉空标签
    final validTags = tags.where((tag) => tag.isNotEmpty && tag.trim().isNotEmpty).toList();
    
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
    
    final tagNodes = TagNode.buildTree(validTags);
    
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
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.hierarchicalTagsShort ?? '使用 / 创建层级标签（如 #工作/项目A）',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // 标签树
        ...tagNodes.map((node) => TagTreeItem(
          key: ValueKey('${node.fullPath}_$_expandAll'), // 🔑 强制重建以应用展开状态
          node: node,
          selectedTag: null, // 不需要选中状态
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
        )),
      ],
    );
  }

}
