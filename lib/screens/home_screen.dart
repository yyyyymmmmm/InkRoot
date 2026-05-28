import 'dart:async'; // 🚀 用于搜索防抖

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
// import '../utils/share_helper.dart'; // 🔥 分享接收助手（暂时禁用）
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/app_config_model.dart' as models;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/sort_order.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/deepseek_api_service.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/services/umeng_analytics_service.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:inkroot/widgets/note_card.dart';
import 'package:inkroot/widgets/note_editor.dart';
import 'package:inkroot/widgets/privacy_policy_dialog.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:inkroot/widgets/desktop_layout.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  // 🔥 接收分享的内容

  const HomeScreen({super.key, this.sharedContent});
  final String? sharedContent;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // 🏢 大厂方案：会话标记 - 标记本次应用会话是否已自动弹出编辑框
  // 参考微信、Notion等应用，只在应用冷启动时弹出一次，而不是每次进入页面
  static bool _hasShownEditorInThisSession = false;
  
  // 🔧 恢复 _scaffoldKey 以修复侧边栏按钮
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  List<Note> _searchResults = [];
  bool _isRefreshing = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  SortOrder _currentSortOrder = SortOrder.newest;

  // 🚀 分页加载相关
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  

  // 🚀 搜索防抖
  Timer? _searchDebounce;

  // 🚀 分帧渲染优化
  int _visibleItemsCount = 0; // 初始显示0个NoteCard，首帧只渲染骨架

  // 🔥 分享接收助手（暂时禁用）
  // final ShareHelper _shareHelper = ShareHelper();
  
  // 🎨 侧边栏宽度（可拖动调整）
  double _sidebarWidth = 280;

  @override
  void initState() {
    super.initState();
    
    // 🚀 大厂做法：先渲染 UI，再异步初始化（不阻塞 UI）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp(); // 异步执行，不阻塞首帧
      _startProgressiveRendering();
    });
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // 🚀 添加滚动监听，实现分页加载
    _scrollController.addListener(_onScroll);

    // 在页面加载完成后异步检查更新和通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🚀 最优延迟策略：与后台云验证协调（启动后8-10秒）
      // 此时后台已开始云验证，直接使用缓存数据
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _checkForUpdates();
          _refreshNotifications();
        }
      });

      // 🔥 如果有分享的内容，打开编辑器（延迟确保页面完全加载）
      if (widget.sharedContent != null && widget.sharedContent!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showAddNoteFormWithContent(widget.sharedContent!);
          }
        });
      } else {
        // 🔥 大厂标准：等待 AppProvider 初始化完成后再检查自动弹出设置
        // 解决部分用户配置未生效的问题
        _checkAndShowEditorOnLaunch();
      }
    });
  }

  // 🚀 分帧渲染：逐步增加可见NoteCard数量
  void _startProgressiveRendering() {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final totalNotes = appProvider.notes.length;

    if (totalNotes == 0) {
      setState(() => _visibleItemsCount = 0);
      return;
    }

    // 🎯 首帧显示0个，后续每帧增加3个（微信/抖音标准做法）
    const itemsPerFrame = 3;
    var currentCount = 0;

    void renderNextBatch() {
      if (!mounted) return;

      currentCount = (currentCount + itemsPerFrame).clamp(0, totalNotes);

      setState(() {
        _visibleItemsCount = currentCount;
      });

      // 如果还没渲染完，继续下一帧
      if (currentCount < totalNotes) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          renderNextBatch();
        });
      }
    }

    // 开始渲染
    renderNextBatch();
  }

  // 🎯 退出搜索状态
  void _exitSearch() {
    if (!_isSearchActive) return;

    setState(() {
      _isSearchActive = false;
      _searchController.clear();
      _searchResults.clear();
    });
    FocusScope.of(context).unfocus(); // 收起键盘
  }

  // 🚀 滚动监听 - 检测底部并加载更多
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // 距离底部300px时开始加载
      _loadMoreNotes();
    }
  }

  // 🚀 加载更多笔记
  Future<void> _loadMoreNotes() async {
    if (_isLoadingMore) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (!appProvider.hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await appProvider.loadMoreNotes();
    } catch (e) {
      if (kDebugMode) debugPrint('HomeScreen: 加载更多失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // 🔥 检查并处理待分享的内容（暂时禁用）
  /*
  void _checkPendingShared() {
    if (_shareHelper.hasPendingShared()) {
      if (kDebugMode) debugPrint('HomeScreen: 检测到待处理的分享内容');
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      _shareHelper.checkAndHandleShared(
        context,
        (content) async {
          try {
            if (kDebugMode) debugPrint('HomeScreen: 从分享创建笔记，内容长度: ${content.length}');
            await appProvider.createNote(content);
            if (kDebugMode) debugPrint('HomeScreen: 分享笔记创建成功');
          } catch (e) {
            if (kDebugMode) debugPrint('HomeScreen: 创建分享笔记失败: $e');
            if (mounted) {
              SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.createNoteFailed ?? '创建笔记失败'}: $e');
            }
          }
        },
      );
    }
  }
  */

  // 异步检查更新
  Future<void> _checkForUpdates() async {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // 异步检查更新，不阻塞UI
    appProvider.checkForUpdatesOnStartup().then((_) {
      if (mounted) {
        appProvider.showUpdateDialogIfNeeded(context);
      }
    });
  }

  // 刷新通知数据
  Future<void> _refreshNotifications() async {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // 异步刷新通知数量，不阻塞UI
    appProvider.refreshUnreadAnnouncementsCount();
  }

  // 🏢 大厂方案：等待配置加载完成后检查并自动弹出编辑框
  // 参考微信、Notion等应用，只在应用冷启动时弹出一次
  Future<void> _checkAndShowEditorOnLaunch() async {
    if (!mounted) return;
    
    // 🎯 核心优化：检查本次会话是否已弹出过
    // 避免每次页面切换都弹出（如从设置页返回主页）
    if (_hasShownEditorInThisSession) {
      if (kDebugMode) {
        debugPrint('HomeScreen: 本次会话已弹出过编辑框，跳过自动弹出');
      }
      return;
    }
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // 🎯 等待 AppProvider 初始化完成
    // 最多等待5秒，避免无限等待
    int attempts = 0;
    while (!appProvider.isInitialized && attempts < 50 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    // 检查配置是否启用了自动弹出
    if (mounted && appProvider.appConfig.autoShowEditorOnLaunch) {
      // 再延迟一小段时间，确保UI完全准备好
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        // 🏢 标记本次会话已弹出，避免重复弹出
        _hasShownEditorInThisSession = true;
        
        if (kDebugMode) {
          debugPrint('HomeScreen: 应用启动时自动弹出编辑框');
        }
        
        _showAddNoteForm();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose(); // 🚀 释放滚动控制器
    _searchDebounce?.cancel(); // 🚀 取消防抖定时器
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final preferencesService = PreferencesService();

    // 🔒 大厂标准：隐私政策检查已在路由层完成，这里只需要初始化友盟
    // 能进入这个页面，说明用户已经同意隐私政策
    await UmengAnalyticsService.init();
    await UmengAnalyticsService.onAppStart();

    // 🎯 检查是否首次启动（路由已处理，这里做二次防御）
    final isFirstLaunch = await preferencesService.isFirstLaunch();
    if (isFirstLaunch) {
      // 🔒 首次启动时清理所有旧数据（防止卸载后重装时残留 Keychain 数据）
      await preferencesService.clearAllSecureData();
      
      if (mounted) {
        // 跳转到引导页（路由应该已经处理了，这里是兜底）
        context.go('/onboarding');
        return;
      }
    }

    // 初始化应用
    if (!appProvider.isInitialized) {
      await appProvider.initializeApp();
    }

    // 后台数据同步现在已经在AppProvider.initializeApp中自动处理
    // 无需在UI层再次触发
  }

  // 刷新笔记数据
  Future<void> _refreshNotes() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 🚀 使用增量同步：速度快10倍以上！
      if (appProvider.isLoggedIn && !appProvider.isLocalMode) {
        if (kDebugMode) {
          // 🚀 执行增量同步（静默）
        }
        await appProvider.refreshFromServerFast();

        // 显示同步成功提示
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            AppLocalizationsSimple.of(context)?.syncSuccess ?? '同步成功',
          );
        }
      }

      // 🔧 移除自动 WebDAV 同步，避免干扰 UI
      // WebDAV 同步改为在设置页面手动触发或定时自动执行
      if (!appProvider.isWebDavEnabled) {
        // 本地模式下重新加载本地数据
        if (kDebugMode) {
          // 🚀 加载本地数据（静默）
        }
        await appProvider.loadNotesFromLocal();

        // 显示刷新成功提示
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            AppLocalizationsSimple.of(context)?.refreshSuccess ?? '刷新成功',
          );
        }
      }

      // 🚀 下拉刷新时同步到 Notion（异步执行，不阻塞UI）
      try {
        await appProvider.syncToNotion();
        if (kDebugMode) {
          debugPrint('HomeScreen: Notion 同步成功');
        }
      } catch (e) {
        // Notion 同步失败不影响主流程
        if (kDebugMode) {
          debugPrint('HomeScreen: Notion 同步失败: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('HomeScreen: 刷新失败: $e');
      // 显示刷新失败提示
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '${AppLocalizationsSimple.of(context)?.refreshFailed ?? '刷新失败'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // 打开侧边栏
  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // 显示排序选项（iOS风格）
  void _showSortOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : Colors.black87;
    final primaryColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示器
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  AppLocalizationsSimple.of(context)?.sortBy ?? '排序方式',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 排序选项
              _buildSortOption(
                AppLocalizationsSimple.of(context)?.newestFirst ?? '最新优先',
                SortOrder.newest,
                primaryColor,
                textColor,
              ),
              _buildSortOption(
                AppLocalizationsSimple.of(context)?.oldestFirst ?? '最旧优先',
                SortOrder.oldest,
                primaryColor,
                textColor,
              ),
              _buildSortOption(
                AppLocalizationsSimple.of(context)?.updatedTime ?? '更新时间',
                SortOrder.updated,
                primaryColor,
                textColor,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 构建排序选项
  Widget _buildSortOption(
    String title,
    SortOrder sortOrder,
    Color primaryColor,
    Color textColor,
  ) {
    final isSelected = _currentSortOrder == sortOrder;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? primaryColor : textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: primaryColor,
              size: 20,
            )
          : null,
      onTap: () {
        setState(() {
          _currentSortOrder = sortOrder;
        });
        Navigator.pop(context);
        _applySorting();
      },
    );
  }

  // 应用排序
  void _applySorting() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setSortOrder(_currentSortOrder);
  }

  // 显示添加笔记表单
  void _showAddNoteForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              final note = await appProvider.createNote(content);
              // 🚀 笔记创建成功（静默）

              // 🔧 修复：退出搜索模式，确保新笔记显示
              if (_isSearchActive) {
                _exitSearch();
              }

              // 🐛 修复：确保新笔记可见
              if (mounted) {
                setState(() {
                  // 增加可见笔记数量，至少显示 10 条（如果有的话）
                  final newCount = _visibleItemsCount + 1;
                  final minCount = appProvider.notes.length >= 10
                      ? 10
                      : appProvider.notes.length;
                  _visibleItemsCount = newCount < minCount
                      ? minCount
                      : newCount.clamp(0, appProvider.notes.length);
                });

                // 🚀 滚动到顶部，确保用户看到新笔记
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              }

              // 如果用户已登录但笔记未同步，尝试再次同步
              if (appProvider.isLoggedIn && !note.isSynced) {
                appProvider.syncNotesWithServer();
              }
            } catch (e) {
              if (kDebugMode) debugPrint('HomeScreen: 创建笔记失败: $e');
              if (mounted) {
                SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.createNoteFailed ?? '创建笔记失败'}: $e');
              }
            }
          }
        },
      ),
    ).then((_) {
      // 🚀 表单关闭（静默）
    });
  }

  // 🔥 显示添加笔记表单（带初始内容）- 用于分享接收
  void _showAddNoteFormWithContent(String initialContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: initialContent, // 🔥 预填充分享的内容
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              final note = await appProvider.createNote(content);
              // 🚀 笔记创建成功（静默）

              // 🔧 修复：退出搜索模式，确保新笔记显示
              if (_isSearchActive) {
                _exitSearch();
              }

              // 🐛 修复：确保新笔记可见
              if (mounted) {
                setState(() {
                  // 增加可见笔记数量，至少显示 10 条（如果有的话）
                  final newCount = _visibleItemsCount + 1;
                  final minCount = appProvider.notes.length >= 10
                      ? 10
                      : appProvider.notes.length;
                  _visibleItemsCount = newCount < minCount
                      ? minCount
                      : newCount.clamp(0, appProvider.notes.length);
                });

                // 🚀 滚动到顶部，确保用户看到新笔记
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              }

              // 如果用户已登录但笔记未同步，尝试再次同步
              if (appProvider.isLoggedIn && !note.isSynced) {
                appProvider.syncNotesWithServer();
              }

              // 显示成功提示
              if (mounted) {
                SnackBarUtils.showSuccess(
                  context,
                  AppLocalizationsSimple.of(context)?.addedFromShare ??
                      '已添加来自分享的笔记',
                );
              }
            } catch (e) {
              if (kDebugMode) debugPrint('HomeScreen: 创建笔记失败: $e');
              if (mounted) {
                SnackBarUtils.showError(context, '${AppLocalizationsSimple.of(context)?.createNoteFailed ?? '创建笔记失败'}: $e');
              }
            }
          }
        },
      ),
    ).then((_) {
      // 🚀 表单关闭（静默）
    });
  }

  // 显示编辑笔记表单
  void _showEditNoteForm(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditor(
        initialContent: note.content,
        currentNoteId: note.id,
        onSave: (content) async {
          if (content.trim().isNotEmpty) {
            try {
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              await appProvider.updateNote(note, content);
              // 🚀 笔记更新成功（静默）

              // 确保标签更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.notifyListeners(); // 通知所有监听者，确保标签页更新
              });
            } catch (e) {
              if (kDebugMode) debugPrint('HomeScreen: 更新笔记失败: $e');
              if (mounted) {
                SnackBarUtils.showError(
                  context,
                  '${AppLocalizationsSimple.of(context)?.updateFailed ?? '更新失败'}: $e',
                );
              }
            }
          }
        },
      ),
    ).then((_) {
      // 🚀 表单关闭（静默）
    });
  }

  // 构建通知提示框
  // 构建通知提示框
  Widget _buildNotificationBanner() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context);

    // 如果没有未读通知，则不显示通知栏
    if (appProvider.unreadAnnouncementsCount <= 0) {
      return const SizedBox.shrink();
    }

    // 设置颜色 - 使用卡片背景色和蓝色主题
    final backgroundColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = Colors.blue.shade600;
    final iconColor = Colors.blue.shade600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // 减少下边距
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // 🎯 点击跳转到通知页面（不自动标记已读）
            if (context.mounted) {
              context.pushNamed('notifications');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.black)
                      .withOpacity(isDarkMode ? 0.3 : 0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ), // 减少内边距，降低高度
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: iconColor,
                    size: 16, // 减小图标尺寸
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizationsSimple.of(context)
                            ?.unreadNotificationsCount(
                                appProvider.unreadAnnouncementsCount) ??
                        '${appProvider.unreadAnnouncementsCount}条未读信息',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w400, // 减轻字重
                      fontSize: 12, // 减小字体
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final cardShadow = AppTheme.neuCardShadow(isDark: isDarkMode);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(60),
              boxShadow: cardShadow,
            ),
            child: Center(
              child: Icon(
                Icons.note_add_rounded,
                size: 48,
                color: iconColor.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizationsSimple.of(context)?.noNotesYet ?? '还没有笔记',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizationsSimple.of(context)?.clickToCreate ?? '点击右下角的按钮开始创建',
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOrderOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final headerBgColor = isDarkMode
        ? AppTheme.primaryColor.withOpacity(0.15)
        : AppTheme.primaryColor.withOpacity(0.05);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // 获取当前排序方式
    var currentSortOrder = SortOrder.newest;

    // 检查当前排序方式
    if (appProvider.notes.length > 1) {
      if (appProvider.notes[0].createdAt
          .isAfter(appProvider.notes[1].createdAt)) {
        currentSortOrder = SortOrder.newest;
      } else if (appProvider.notes[0].createdAt
          .isBefore(appProvider.notes[1].createdAt)) {
        currentSortOrder = SortOrder.oldest;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    AppLocalizationsSimple.of(context)?.sortBy ?? '排序方式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              RadioListTile<SortOrder>(
                title: Text(
                  AppLocalizationsSimple.of(context)?.newestFirst ?? '从新到旧',
                  style: TextStyle(color: textColor),
                ),
                value: SortOrder.newest,
                groupValue: currentSortOrder,
                activeColor: iconColor,
                onChanged: (SortOrder? value) {
                  if (value != null) {
                    appProvider.sortNotes(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<SortOrder>(
                title: Text(
                  AppLocalizationsSimple.of(context)?.oldestFirst ?? '从旧到新',
                  style: TextStyle(color: textColor),
                ),
                value: SortOrder.oldest,
                groupValue: currentSortOrder,
                activeColor: iconColor,
                onChanged: (SortOrder? value) {
                  if (value != null) {
                    appProvider.sortNotes(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey[400];

    // 🎯 允许直接返回（最小化应用）
    // 桌面端侧边栏由DesktopLayout处理，这里只需要内容区域
    final content = _buildMobileLayout(
      backgroundColor,
      cardColor,
      textColor,
      secondaryTextColor,
      iconColor,
      hintColor ?? Colors.grey,
      isDarkMode,
    );
    
    return ResponsiveLayout(
      mobile: content,
      tablet: content, // 平板端也使用相同布局
      desktop: content, // 桌面端使用相同布局，侧边栏由DesktopLayout处理
    );
  }

  // 移动端布局
  Widget _buildMobileLayout(
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color iconColor,
    Color hintColor,
    bool isDarkMode,
  ) {
    final bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: isDesktop ? null : const Sidebar(),
      drawerEdgeDragWidth: isDesktop ? null : MediaQuery.of(context).size.width * 0.25,
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
          title: _isSearchActive
              ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true, // 自动聚焦，提供更好的用户体验
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizationsSimple.of(context)?.searchNotes ??
                              '搜索笔记...',
                      hintStyle: TextStyle(
                        color: hintColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: iconColor,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(
                      color: textColor,
                    ),
                    onChanged: (query) {
                      final appProvider =
                          Provider.of<AppProvider>(context, listen: false);

                      if (query.isEmpty) {
                        // 搜索框为空时，清空搜索结果，这样会显示所有笔记
                        setState(() {
                          _searchResults.clear();
                        });
                        return;
                      }

                      // 执行搜索过滤
                      final results = appProvider.notes
                          .where(
                            (note) =>
                                note.content
                                    .toLowerCase()
                                    .contains(query.toLowerCase()) ||
                                note.tags.any(
                                  (tag) => tag
                                      .toLowerCase()
                                      .contains(query.toLowerCase()),
                                ),
                          )
                          .toList();

                      setState(() {
                        _searchResults = results;
                      });
                    },
                  ),
                )
              : GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConfig.appName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: textColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
          centerTitle: true,
          actions: [
            // AI洞察按钮
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.fontScaledSpacing(context, 8),
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.fontScaledBorderRadius(context, 8),
                  ),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  size: ResponsiveUtils.fontScaledIconSize(context, 20),
                  color: AppTheme.primaryColor,
                ),
              ),
              tooltip: 'AI洞察',
              onPressed: _showAiInsightDialog,
            ),
            SizedBox(
              width: ResponsiveUtils.fontScaledSpacing(context, 5),
            ), // 紧凑间距
            // 搜索按钮
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.fontScaledSpacing(context, 8),
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.fontScaledBorderRadius(context, 8),
                  ),
                ),
                child: Icon(
                  _isSearchActive ? Icons.close : Icons.search,
                  size: ResponsiveUtils.fontScaledIconSize(context, 20),
                  color: iconColor,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    _searchController.clear();
                    _searchResults.clear();
                  }
                });
              },
            ),
            SizedBox(width: ResponsiveUtils.fontScaledSpacing(context, 8)),
          ],
        ),
        body: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            // 🚀 极速启动：不等loading，立即显示界面
            // 如果没有数据会显示空白状态，数据加载完立即刷新

            final notes = _isSearchActive
                ? (_searchController.text.isEmpty
                    ? appProvider.notes
                    : _searchResults)
                : appProvider.notes;

            // 🔧 修复：确保至少显示一些笔记，避免创建后不显示
            if (!_isSearchActive &&
                notes.isNotEmpty &&
                _visibleItemsCount == 0) {
              // 使用 post frame callback 避免在 build 中调用 setState
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    // 至少显示 10 条笔记（如果有的话）
                    _visibleItemsCount = notes.length >= 10 ? 10 : notes.length;
                  });
                }
              });
            }
            
            // 🔥 大厂标准：动态更新可见数量（同步完成后自动显示全部）
            if (!_isSearchActive && notes.length > _visibleItemsCount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    // 如果笔记数量增加了（比如同步完成），立即显示全部
                    _visibleItemsCount = notes.length;
                  });
                }
              });
            }

            // 🚀 分帧渲染：限制可见笔记数量（搜索时不限制）
            final visibleNotes = _isSearchActive
                ? notes.length
                : _visibleItemsCount.clamp(0, notes.length);

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _exitSearch, // 🎯 点击空白处退出搜索
                        behavior: HitTestBehavior.translucent, // 确保空白区域也能响应点击
                        child: RefreshIndicator(
                          onRefresh: _refreshNotes,
                          color: AppTheme.primaryColor,
                          child: SlidableAutoCloseBehavior(
                            // 🔥 类似微信：同时只能打开一个侧滑项
                            child: notes.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      // 添加通知提示框到ListView内部
                                      _buildNotificationBanner(),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height -
                                                200,
                                        child: _buildEmptyState(),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    controller: _scrollController, // 🚀 添加滚动控制器
                                    physics:
                                        const AlwaysScrollableScrollPhysics(), // 🎯 确保下拉刷新可用
                                    itemCount: visibleNotes +
                                        3, // 🚀 使用可见数量 +1通知栏 +1加载指示器 +1底部间距
                                    padding: EdgeInsets.zero,
                                    cacheExtent: 1000, // 🚀 增加缓存区域，减少重建
                                    itemBuilder: (context, index) {
                                      // 第一个item是通知栏
                                      if (index == 0) {
                                        return _buildNotificationBanner();
                                      }

                                      // 倒数第二个item是加载更多指示器
                                      if (index == visibleNotes + 1) {
                                        return _buildLoadMoreIndicator(
                                          appProvider,
                                        );
                                      }

                                      // 最后一个item是底部间距
                                      if (index == visibleNotes + 2) {
                                        return const SizedBox(height: 120);
                                      }

                                      final noteIndex =
                                          index - 1; // 调整索引，因为第一个是通知栏

                                      // 🚀 显示骨架屏占位符（分帧渲染未到达的item）
                                      if (noteIndex >= visibleNotes) {
                                        return _buildSkeletonCard();
                                      }

                                      final note = notes[noteIndex];
                                      return RepaintBoundary(
                                        key: ValueKey(
                                          note.id,
                                        ), // 🚀 添加key避免不必要的重建
                                        child: NoteCard(
                                          key: ValueKey(
                                            'card_${note.id}',
                                          ), // 🚀 为NoteCard添加key
                                          note: note, // 🚀 直接传递Note对象，避免内部查找
                                          onEdit: () {
                                            // 🚀 编辑笔记（静默）
                                            _showEditNoteForm(note);
                                          },
                                          onDelete: () async {
                                            // 🚀 乐观删除笔记（立即更新UI）
                                            try {
                                              final appProvider =
                                                  Provider.of<AppProvider>(
                                                context,
                                                listen: false,
                                              );
                                              await appProvider
                                                  .deleteNote(note.id);

                                              if (context.mounted) {
                                                // 🎯 清除之前的通知，避免累积
                                                ScaffoldMessenger.of(context).clearSnackBars();
                                                // 🔇 已禁用删除成功通知
                                                /* 显示带撤销按钮的美化提示
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            AppLocalizationsSimple
                                                                    .of(
                                                                  context,
                                                                )?.noteDeleted ??
                                                                '笔记已删除',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.successColor,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 50,
                                                      vertical: 20,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        25,
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 3,
                                                    ),
                                                    action: SnackBarAction(
                                                      label:
                                                          AppLocalizationsSimple
                                                                      .of(context)
                                                                  ?.undo ??
                                                              '撤销',
                                                      textColor: Colors.white,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      disabledTextColor:
                                                          Colors.white70,
                                                      onPressed: () async {
                                                        // 撤销删除
                                                        await appProvider
                                                            .restoreNote();
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .restore,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 20,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      AppLocalizationsSimple.of(context)
                                                                              ?.noteRestored ??
                                                                          '笔记已恢复',
                                                                      style:
                                                                          const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor:
                                                                  Colors.blue
                                                                      .shade600,
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 50,
                                                                vertical: 20,
                                                              ),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  25,
                                                                ),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8,
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                seconds: 2,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ); */
                                              }
                                            } catch (e) {
                                              if (kDebugMode) {
                                                debugPrint(
                                                  'HomeScreen: 删除笔记失败: $e',
                                                );
                                              }
                                              if (context.mounted) {
                                                SnackBarUtils.showError(
                                                  context,
                                                  '删除失败: $e',
                                                );
                                              }
                                            }
                                          },
                                          onPin: () async {
                                            final appProvider =
                                                Provider.of<AppProvider>(
                                              context,
                                              listen: false,
                                            );
                                            // 🔥 保存切换前的状态
                                            final willPin = !note.isPinned;
                                            await appProvider
                                                .togglePinStatus(note);
                                            if (context.mounted) {
                                              SnackBarUtils.showSuccess(
                                                context,
                                                // 🔥 显示切换后的状态
                                                willPin 
                                                    ? (AppLocalizationsSimple.of(context)?.pinned ?? '已置顶')
                                                    : (AppLocalizationsSimple.of(context)?.unpinned ?? '已取消置顶'),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ), // ListView.builder 结束
                          ), // SlidableAutoCloseBehavior 结束
                        ), // RefreshIndicator 结束
                      ), // GestureDetector 结束 - 点击空白处退出搜索

                      // 移除全屏同步覆盖层，改为后台静默同步
                    ],
                  ), // Stack 结束
                ), // Expanded 结束
              ],
            ); // Column 结束
          }, // Consumer builder 结束
        ), // Consumer 结束
        floatingActionButton: GestureDetector(
          onTapDown: (_) => _fabAnimationController.forward(),
          onTapUp: (_) => _fabAnimationController.reverse(),
          onTapCancel: () => _fabAnimationController.reverse(),
          child: ScaleTransition(
            scale: _fabScaleAnimation,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLightColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddNoteForm,
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.white.withOpacity(0.2),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  // 平板布局
  Widget _buildTabletLayout(
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color iconColor,
    Color hintColor,
    bool isDarkMode,
  ) =>
      Scaffold(
        // 🔧 修复GlobalKey冲突：tablet布局不需要key
        drawer: const Sidebar(),
        // 🎯 大厂标准：侧滑区域设为屏幕20%（参考微信/支付宝）
        // 80-100px 在大多数设备上约等于 15-20% 屏幕宽度
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
        backgroundColor: backgroundColor,
        appBar: _buildResponsiveAppBar(
          backgroundColor,
          cardColor,
          textColor,
          iconColor,
          hintColor,
          isDarkMode,
        ),
        body: ResponsiveContainer(
          maxWidth: 800,
          child: _buildMainContent(
            backgroundColor,
            cardColor,
            textColor,
            secondaryTextColor,
            iconColor,
            hintColor,
            isDarkMode,
          ),
        ),
        floatingActionButton: _buildResponsiveFAB(isDarkMode),
      );
  }

  // 桌面布局
  Widget _buildDesktopLayout(
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color iconColor,
    Color hintColor,
    bool isDarkMode,
  ) =>
      Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // 左侧可调整宽度的侧边栏
            Container(
              width: _sidebarWidth,
              decoration: BoxDecoration(
                color:
                    isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor,
              ),
              child: const Sidebar(isDrawer: false), // 桌面端侧边栏固定显示
            ),
            // 可拖动的分隔条
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(200.0, 400.0);
                  });
                },
                child: Container(
                  width: 1,
                  color: isDarkMode
                      ? AppTheme.darkDividerColor
                      : AppTheme.dividerColor,
                ),
              ),
            ),
            // 右侧主内容区域
            Expanded(
              child: Scaffold(
                backgroundColor: backgroundColor,
                appBar: _buildResponsiveAppBar(
                  backgroundColor,
                  cardColor,
                  textColor,
                  iconColor,
                  hintColor,
                  isDarkMode,
                  showDrawerButton: false,
                ),
                body: ResponsiveContainer(
                  maxWidth: 1000,
                  child: _buildMainContent(
                    backgroundColor,
                    cardColor,
                    textColor,
                    secondaryTextColor,
                    iconColor,
                    hintColor,
                    isDarkMode,
                  ),
                ),
                floatingActionButton: _buildResponsiveFAB(isDarkMode),
              ),
            ),
          ],
        ),
      );

  // 响应式AppBar
  PreferredSizeWidget _buildResponsiveAppBar(
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color iconColor,
    Color hintColor,
    bool isDarkMode, {
    bool showDrawerButton = true,
  }) =>
      AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: showDrawerButton
            ? IconButton(
                icon: Container(
                  padding: ResponsiveUtils.responsivePadding(context, all: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: ResponsiveUtils.responsive<double>(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        height: 2,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveUtils.responsiveSpacing(context, 4),
                      ),
                      Container(
                        width: ResponsiveUtils.responsive<double>(
                          context,
                          mobile: 10,
                          tablet: 12,
                          desktop: 14,
                        ),
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
              )
            : null,
        title: _isSearchActive
            ? Container(
                height: ResponsiveUtils.responsive<double>(
                  context,
                  mobile: 40,
                  tablet: 44,
                  desktop: 48,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsive<double>(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _performSearch,
                  style: TextStyle(
                    color: textColor,
                    fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizationsSimple.of(context)?.searchNotes ??
                        '搜索笔记...',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                    ),
                    border: InputBorder.none,
                    contentPadding: ResponsiveUtils.responsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: hintColor,
                      size: ResponsiveUtils.responsiveIconSize(context, 20),
                    ),
                  ),
                ),
              )
            : GestureDetector(
                onTap: _showAppSelector,
                child: Container(
                  padding: ResponsiveUtils.responsivePadding(
                    context,
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConfig.appName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize:
                              ResponsiveUtils.responsiveFontSize(context, 18),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveUtils.responsiveSpacing(context, 4),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textColor,
                        size: ResponsiveUtils.responsiveIconSize(context, 20),
                      ),
                    ],
                  ),
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: ResponsiveUtils.responsivePadding(context, all: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isSearchActive ? Icons.close : Icons.search,
                size: ResponsiveUtils.responsiveIconSize(context, 20),
                color: iconColor,
              ),
            ),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _searchResults.clear();
                }
              });
            },
          ),
          SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 8)),
        ],
      );

  // 响应式悬浮操作按钮
  Widget _buildResponsiveFAB(bool isDarkMode) {
    final fabSize = ResponsiveUtils.responsive<double>(
      context,
      mobile: 60,
      tablet: 68,
      desktop: 72,
    );

    return GestureDetector(
      onTapDown: (_) => _fabAnimationController.forward(),
      onTapUp: (_) => _fabAnimationController.reverse(),
      onTapCancel: () => _fabAnimationController.reverse(),
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Container(
          width: fabSize,
          height: fabSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryLightColor,
              ],
            ),
            borderRadius: BorderRadius.circular(fabSize / 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: ResponsiveUtils.responsive<double>(
                  context,
                  mobile: 16,
                  tablet: 20,
                  desktop: 24,
                ),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAddNoteForm,
              borderRadius: BorderRadius.circular(fabSize / 2),
              splashColor: Colors.white.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: ResponsiveUtils.responsiveIconSize(context, 32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 主内容区域
  Widget _buildMainContent(
    Color backgroundColor,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color iconColor,
    Color hintColor,
    bool isDarkMode,
  ) =>
      GestureDetector(
        onTap: _exitSearch, // 🎯 点击空白处退出搜索（统一使用_exitSearch方法）
        child: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            if (appProvider.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: ResponsiveUtils.responsive<double>(
                        context,
                        mobile: 50,
                        tablet: 60,
                        desktop: 70,
                      ),
                      height: ResponsiveUtils.responsive<double>(
                        context,
                        mobile: 50,
                        tablet: 60,
                        desktop: 70,
                      ),
                      child: CircularProgressIndicator(
                        color: iconColor,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveUtils.responsiveSpacing(context, 16),
                    ),
                    Text(
                      AppLocalizationsSimple.of(context)?.loading ?? '加载中...',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize:
                            ResponsiveUtils.responsiveFontSize(context, 16),
                      ),
                    ),
                  ],
                ),
              );
            }

            final notes = _isSearchActive
                ? (_searchController.text.isEmpty
                    ? appProvider.notes
                    : _searchResults)
                : appProvider.notes;

            // 🔧 修复：确保至少显示一些笔记，避免创建后不显示
            if (!_isSearchActive &&
                notes.isNotEmpty &&
                _visibleItemsCount == 0) {
              // 使用 post frame callback 避免在 build 中调用 setState
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    // 至少显示 10 条笔记（如果有的话）
                    _visibleItemsCount = notes.length >= 10 ? 10 : notes.length;
                  });
                }
              });
            }
            
            // 🔥 大厂标准：动态更新可见数量（同步完成后自动显示全部）
            if (!_isSearchActive && notes.length > _visibleItemsCount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    // 如果笔记数量增加了（比如同步完成），立即显示全部
                    _visibleItemsCount = notes.length;
                  });
                }
              });
            }

            // 🚀 分帧渲染：限制可见笔记数量（搜索时不限制）
            final visibleNotes = _isSearchActive
                ? notes.length
                : _visibleItemsCount.clamp(0, notes.length);

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _exitSearch, // 🎯 点击空白处退出搜索
                        behavior: HitTestBehavior.translucent, // 确保空白区域也能响应点击
                        child: RefreshIndicator(
                          onRefresh: _refreshNotes,
                          color: AppTheme.primaryColor,
                          child: SlidableAutoCloseBehavior(
                            // 🔥 类似微信：同时只能打开一个侧滑项
                            child: notes.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      _buildNotificationBanner(),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height -
                                                200,
                                        child: _buildEmptyState(),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    controller: _scrollController, // 🚀 添加滚动控制器
                                    physics:
                                        const AlwaysScrollableScrollPhysics(), // 🎯 确保下拉刷新可用
                                    itemCount: visibleNotes +
                                        3, // 🚀 使用可见数量 +1通知栏 +1加载指示器 +1底部间距
                                    padding: EdgeInsets.zero,
                                    cacheExtent: 1000, // 🚀 增加缓存区域，减少重建
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return _buildNotificationBanner();
                                      }

                                      // 倒数第二个item是加载更多指示器
                                      if (index == visibleNotes + 1) {
                                        return _buildLoadMoreIndicator(
                                          appProvider,
                                        );
                                      }

                                      // 最后一个item是底部间距
                                      if (index == visibleNotes + 2) {
                                        return SizedBox(
                                          height:
                                              ResponsiveUtils.responsiveSpacing(
                                            context,
                                            120,
                                          ),
                                        );
                                      }

                                      final noteIndex =
                                          index - 1; // 调整索引，因为第一个是通知栏

                                      // 🚀 显示骨架屏占位符（分帧渲染未到达的item）
                                      if (noteIndex >= visibleNotes) {
                                        return _buildSkeletonCard();
                                      }

                                      final note = notes[noteIndex];
                                      return RepaintBoundary(
                                        key: ValueKey(
                                          note.id,
                                        ), // 🚀 添加key避免不必要的重建
                                        child: NoteCard(
                                          key: ValueKey(
                                            'card_${note.id}',
                                          ), // 🚀 为NoteCard添加key
                                          note: note, // 🚀 直接传递Note对象，避免内部查找
                                          onEdit: () {
                                            // 🚀 编辑笔记（静默）
                                            _showEditNoteForm(note);
                                          },
                                          onDelete: () async {
                                            // 🚀 乐观删除笔记（立即更新UI）
                                            try {
                                              final appProvider =
                                                  Provider.of<AppProvider>(
                                                context,
                                                listen: false,
                                              );
                                              await appProvider
                                                  .deleteNote(note.id);

                                              if (context.mounted) {
                                                // 🎯 清除之前的通知，避免累积
                                                ScaffoldMessenger.of(context).clearSnackBars();
                                                // 🔇 已禁用删除成功通知
                                                /* 显示带撤销按钮的美化提示
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            AppLocalizationsSimple
                                                                    .of(
                                                                  context,
                                                                )?.noteDeleted ??
                                                                '笔记已删除',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.successColor,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 50,
                                                      vertical: 20,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        25,
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 3,
                                                    ),
                                                    action: SnackBarAction(
                                                      label:
                                                          AppLocalizationsSimple
                                                                      .of(context)
                                                                  ?.undo ??
                                                              '撤销',
                                                      textColor: Colors.white,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      disabledTextColor:
                                                          Colors.white70,
                                                      onPressed: () async {
                                                        // 撤销删除
                                                        await appProvider
                                                            .restoreNote();
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .restore,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 20,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      AppLocalizationsSimple.of(context)
                                                                              ?.noteRestored ??
                                                                          '笔记已恢复',
                                                                      style:
                                                                          const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              backgroundColor:
                                                                  Colors.blue
                                                                      .shade600,
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 50,
                                                                vertical: 20,
                                                              ),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  25,
                                                                ),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8,
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                seconds: 2,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ); */
                                              }
                                            } catch (e) {
                                              if (kDebugMode) {
                                                debugPrint(
                                                  'HomeScreen: 删除笔记失败: $e',
                                                );
                                              }
                                              if (context.mounted) {
                                                SnackBarUtils.showError(
                                                  context,
                                                  '删除失败: $e',
                                                );
                                              }
                                            }
                                          },
                                          onPin: () async {
                                            final appProvider =
                                                Provider.of<AppProvider>(
                                              context,
                                              listen: false,
                                            );
                                            // 🔥 保存切换前的状态
                                            final willPin = !note.isPinned;
                                            await appProvider
                                                .togglePinStatus(note);
                                            if (context.mounted) {
                                              SnackBarUtils.showSuccess(
                                                context,
                                                // 🔥 显示切换后的状态
                                                willPin 
                                                    ? (AppLocalizationsSimple.of(context)?.pinned ?? '已置顶')
                                                    : (AppLocalizationsSimple.of(context)?.unpinned ?? '已取消置顶'),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ), // ListView.builder 结束
                          ), // SlidableAutoCloseBehavior 结束
                        ), // RefreshIndicator 结束
                      ), // GestureDetector 结束 - 点击空白处退出搜索
                    ],
                  ), // Stack 结束
                ), // Expanded 结束
              ],
            ); // Column 结束
          }, // Consumer builder 结束
        ), // Consumer 结束
      );

  // 执行搜索（带防抖优化）
  void _performSearch(String query) {
    // 🚀 防抖：取消之前的搜索请求
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      // 搜索框为空时，清空搜索结果，这样会显示所有笔记
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    // 🚀 延迟300ms执行搜索，避免每次输入都查询
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
  }

  // 实际执行搜索
  Future<void> _executeSearch(String query) async {
    // 🚀 改用数据库搜索，确保搜索全部笔记
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final results = await appProvider.databaseService.searchNotes(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('HomeScreen: 搜索失败: $e');
      // 如果数据库搜索失败，回退到内存搜索
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final results = appProvider.notes
          .where(
            (note) =>
                note.content.toLowerCase().contains(query.toLowerCase()) ||
                note.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    }
  }

  // 显示应用选择器（占位方法）
  void _showAppSelector() {
    // 这是一个占位方法，可以根据需要实现应用选择功能
    // 暂时不做任何操作
  }

  // 🚀 构建骨架屏占位符（分帧渲染）
  Widget _buildSkeletonCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题骨架
          Container(
            height: 16,
            width: double.infinity * 0.7,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // 内容骨架
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: double.infinity * 0.85,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 构建加载更多指示器
  Widget _buildLoadMoreIndicator(AppProvider appProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    // 如果还有更多数据，显示加载中
    if (appProvider.hasMoreData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode
                      ? AppTheme.primaryLightColor
                      : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizationsSimple.of(context)?.loading ?? '加载中...',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    // 没有更多数据，显示已加载全部
    if (appProvider.notes.length > 10) {
      // 只有笔记数量大于10才显示
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          (AppLocalizationsSimple.of(context)?.loadedAll ?? '已加载全部 {count} 条笔记').replaceAll('{count}', '${appProvider.notes.length}'),
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.6),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // AI洞察对话框
  void _showAiInsightDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final appConfig = appProvider.appConfig;

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
        builder: (context) => _AiInsightScreen(
          notes: appProvider.notes,
          appConfig: appConfig,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

// AI洞察页面
class _AiInsightScreen extends StatefulWidget {
  const _AiInsightScreen({
    required this.notes,
    required this.appConfig,
  });
  final List<Note> notes;
  final models.AppConfig appConfig;

  @override
  State<_AiInsightScreen> createState() => _AiInsightScreenState();
}

class _AiInsightScreenState extends State<_AiInsightScreen> {
  final _keywordController = TextEditingController();
  final _scrollController = ScrollController(); // 🔥 添加滚动控制器
  final Set<String> _selectedTags = {};
  final Set<String> _excludedTags = {};
  String _timeRange = 'all'; // all, week, month, year
  bool _isAnalyzing = false;
  String? _insightResult;
  bool _isIncludeTagsExpanded = false; // 包含标签是否展开
  bool _isExcludeTagsExpanded = false; // 排除标签是否展开
  String? _errorMessage;
  final GlobalKey _insightResultKey = GlobalKey(); // 🔥 结果区域的key，用于定位

  @override
  void dispose() {
    _keywordController.dispose();
    _scrollController.dispose(); // 🔥 释放滚动控制器
    super.dispose();
  }

  // 获取所有可用标签
  List<String> get _availableTags {
    final tags = <String>{};
    for (final note in widget.notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  // 根据筛选条件过滤笔记
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
              controller: _scrollController, // 🔥 添加滚动控制器
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
                      key: _insightResultKey, // 🔥 添加key用于定位
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

          // 底部操作栏
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(
                  color: (isDarkMode ? Colors.white : Colors.black)
                      .withOpacity(0.1),
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
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
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('AI正在分析中...'),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 20),
                            const SizedBox(width: 8),
                            Text('开始洞察 (${_filteredNotes.length} 条笔记)'),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: subTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTimeRangeOption(
            AppLocalizationsSimple.of(context)?.allTime ?? '全部',
            'all',
          ),
          _buildTimeRangeOption(
            AppLocalizationsSimple.of(context)?.last7Days ?? '近7天',
            'week',
          ),
          _buildTimeRangeOption(
            AppLocalizationsSimple.of(context)?.last30Days ?? '近30天',
            'month',
          ),
          _buildTimeRangeOption(
            AppLocalizationsSimple.of(context)?.last1Year ?? '近1年',
            'year',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeOption(String label, String value) {
    final isSelected = _timeRange == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _timeRange = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSelector({
    required bool isInclude,
    required bool isExpanded,
  }) {
    final tags = _availableTags;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;

    if (tags.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppLocalizationsSimple.of(context)?.noAvailableTags ?? '暂无可用标签',
          style: const TextStyle(
            color: AppTheme.darkTextSecondaryColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 🔥 标签折叠：默认只显示前10个，点击展开查看全部
    final tagList = tags.toList()..sort();
    final displayTags = isExpanded ? tagList : tagList.take(10).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayTags.map((tag) {
        final isSelected = isInclude
            ? _selectedTags.contains(tag)
            : _excludedTags.contains(tag);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isInclude) {
                if (isSelected) {
                  _selectedTags.remove(tag);
                } else {
                  _selectedTags.add(tag);
                  _excludedTags.remove(tag); // 从排除列表移除
                }
              } else {
                if (isSelected) {
                  _excludedTags.remove(tag);
                } else {
                  _excludedTags.add(tag);
                  _selectedTags.remove(tag); // 从包含列表移除
                }
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isInclude ? AppTheme.primaryColor : Colors.red)
                  : surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isInclude ? AppTheme.primaryColor : Colors.red)
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isInclude ? Icons.check : Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 构建展开/收起按钮
  Widget _buildExpandButton({required bool isInclude}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExpanded =
        isInclude ? _isIncludeTagsExpanded : _isExcludeTagsExpanded;
    final tagCount = _availableTags.length;

    return Center(
      child: TextButton.icon(
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
          size: 18,
          color: AppTheme.primaryColor,
        ),
        label: Text(
          isExpanded
              ? (AppLocalizationsSimple.of(context)?.collapse ?? '收起')
              : (AppLocalizationsSimple.of(context)
                      ?.expandAllTagsWithCount(tagCount) ??
                  '展开全部 ($tagCount个标签)'),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDarkMode ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final subTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    final totalNotes = widget.notes.length;
    final filteredCount = _filteredNotes.length;
    final totalWords = _filteredNotes.fold<int>(
      0,
      (sum, note) => sum + _getActualWordCount(note.content),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.description_outlined,
            label: AppLocalizationsSimple.of(context)?.filterNotes ?? '筛选笔记',
            value: '$filteredCount / $totalNotes',
            color: AppTheme.primaryColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          _buildStatItem(
            icon: Icons.text_fields,
            label: AppLocalizationsSimple.of(context)?.totalWordCount ?? '总字数',
            value: totalWords.toString(),
            color: Colors.orange,
          ),
          Container(
            width: 1,
            height: 40,
            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          _buildStatItem(
            icon: Icons.label_outlined,
            label: AppLocalizationsSimple.of(context)?.tagCount ?? '标签数',
            value: _availableTags.length.toString(),
            color: Colors.green,
          ),
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: subTextColor,
          ),
        ),
      ],
    );
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

  Widget _buildInsightResult() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    // 🔥 flomo风格：简洁的卡片展示，强调内容而非装饰 + 淡入动画
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.95 + (0.05 * value), // 从0.95缩放到1.0
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 简洁的标题
            Row(
              children: [
                const Text(
                  '💌',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '专属洞察报告',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 洞察内容 - flomo风格：简洁清晰的文本（可复制）
            SelectableText(
              _insightResult!,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 自动滚动到结果区域
  void _scrollToResult() {
    // 延迟一下，确保Widget已经渲染完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      try {
        // 获取结果区域的RenderBox
        final resultBox =
            _insightResultKey.currentContext?.findRenderObject() as RenderBox?;
        if (resultBox == null) return;

        // 计算需要滚动的位置（结果区域顶部 - 一些padding）
        final position = resultBox.localToGlobal(Offset.zero).dy;
        final scrollPosition =
            _scrollController.offset + position - 100; // 减去100px，留出一些空间

        // 平滑滚动到结果区域
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      } catch (e) {
        // 如果出错，直接滚动到底部
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  // 清理Markdown符号，转换为纯文本
  String _cleanMarkdown(String text) {
    var cleaned = text;

    // 移除Markdown标题符号 (# ## ###)
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

    // 移除加粗符号 (** __ )
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp('__(.*?)__'), r'$1');

    // 移除斜体符号 (* _)
    cleaned = cleaned.replaceAll(
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
      r'$1',
    );
    cleaned =
        cleaned.replaceAll(RegExp('(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'), r'$1');

    // 移除删除线 (~~)
    cleaned = cleaned.replaceAll(RegExp('~~(.*?)~~'), r'$1');

    // 移除代码块符号 (```)
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp('`(.*?)`'), r'$1');

    // 移除链接格式 [text](url)
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

    // 移除图片格式 ![alt](url)
    cleaned = cleaned.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), r'$1');

    // 移除引用符号 (>)
    cleaned = cleaned.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

    // 移除水平线 (--- ***)
    cleaned =
        cleaned.replaceAll(RegExp(r'^[\-\*]{3,}\s*$', multiLine: true), '');

    // 移除列表符号 (- * 1.)
    cleaned = cleaned.replaceAll(RegExp(r'^[\-\*\+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');

    // 清理多余的空行（保留段落间的单个空行）
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  Future<void> _startAnalysis() async {
    if (_filteredNotes.isEmpty) {
      SnackBarUtils.showWarning(
        context,
        AppLocalizationsSimple.of(context)?.noNotesMatchingCriteria ??
            '没有符合条件的笔记',
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _insightResult = null;
    });

    try {
      final apiService = DeepSeekApiService(
        apiUrl: widget.appConfig.aiApiUrl!,
        apiKey: widget.appConfig.aiApiKey!,
        model: widget.appConfig.aiModel,
      );

      // 构建笔记内容摘要
      final notesSummary = _filteredNotes
          .take(50)
          .map(
            (note) =>
                '【${note.tags.join(', ')}】${note.content.length > 200 ? '${note.content.substring(0, 200)}...' : note.content}',
          )
          .join('\n\n');

      // 🎯 使用自定义Prompt或系统默认Prompt
      final systemPrompt = widget.appConfig.useCustomPrompt &&
              widget.appConfig.customInsightPrompt != null &&
              widget.appConfig.customInsightPrompt!.isNotEmpty
          ? widget.appConfig.customInsightPrompt!
          : '''
你是一位善于洞察的笔记分析师，用自然的对话方式提供完整的分析闭环。

输出格式要求（重要！）：
- 纯文本，绝对不要用 # * ** 等Markdown符号
- 不要用emoji
- 用"你"称呼用户
- 自然地直接进入内容，不要固定开头
- 分4段，每段2-3句话，段落间空一行

内容结构（完整闭环）：

第1段 - 整体观察：
用一个直接、有洞察力的句子开场，概括你看到的核心模式或特点。

第2段 - 值得肯定：
指出笔记中闪光的思考、有价值的探索方向，或值得保持的习惯。用"我注意到"、"这里有个亮点"等自然表述。

第3段 - 可改进之处：
坦诚地指出可以优化的地方，比如思考的盲区、缺失的连接，或值得深入的方向。用"或许可以"、"有个地方值得注意"等温和表述。

第4段 - 具体建议：
给出1-2条清晰、可操作的建议，帮助用户形成行动闭环。

写作风格：
- 像Notion AI那样：直接、专业、有温度
- 坦诚但不批评，建设性而非说教
- 每个部分自然过渡，不要生硬分段
- 保持对话感，避免报告感
''';

      var userPrompt = '请分析这${_filteredNotes.length}条笔记';
      if (_selectedTags.isNotEmpty) {
        userPrompt += '（标签：${_selectedTags.join(', ')}）';
      }
      if (_excludedTags.isNotEmpty) {
        userPrompt += '（排除：${_excludedTags.join(', ')}）';
      }
      if (_keywordController.text.isNotEmpty) {
        userPrompt += '（关键词：${_keywordController.text}）';
      }
      userPrompt +=
          '，按4段结构提供完整分析：整体观察、值得肯定、可改进之处、具体建议。\n\n笔记内容：\n\n$notesSummary';

      final messages = [
        DeepSeekApiService.buildSystemMessage(systemPrompt),
        DeepSeekApiService.buildUserMessage(userPrompt),
      ];

      final (result, error) = await apiService.chat(messages: messages);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (error != null) {
            _errorMessage = error;
          } else {
            // 🔥 清理Markdown符号，得到纯文本结果
            _insightResult = result != null ? _cleanMarkdown(result) : null;
            // 🔥 分析完成后显示提示
            SnackBarUtils.showSuccess(context, '✨ AI洞察分析完成！');
            // 🔥 自动滚动到结果区域
            _scrollToResult();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'AI分析失败: $e';
        });
      }
    }
  }
}
