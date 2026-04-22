import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/models/announcement_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.showBackButton = false,
  });
  final bool showBackButton;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberLogin = true;
  bool _obscurePassword = true;
  bool _useCustomServer = false;

  // 🔔 云通知相关
  List<Announcement> _announcements = [];
  bool _isLoadingAnnouncements = true;
  final ScrollController _announcementScrollController = ScrollController();
  Timer? _autoScrollTimer;

  // 🚀 默认静态公告（跑马灯）
  final List<String> _staticAnnouncements = [
    '仅支持 Memos 0.21.0 - API版本差异较大',
    '建议使用 0.21.0 版本以获得最佳体验',
    '不同版本的 API 接口存在较大差异',
    '0.21.0 版本经过充分测试，功能稳定',
  ];

  // 🎬 动画控制器
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('LoginScreen: initState');
    _loadSavedLoginInfo();
    _loadAnnouncements(); // 加载云通知
    _rememberLogin = true;

    // 🎨 初始化动画系统
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 🎬 启动动画序列
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _floatingController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _announcementScrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  /// 加载云通知（使用 AppProvider 的公告数据）
  Future<void> _loadAnnouncements() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // 从 AppProvider 获取公告
      await appProvider.refreshAnnouncements();
      
      if (mounted) {
        setState(() {
          // 获取 AppProvider 的公告列表，只显示非更新类型的通知
          _announcements = appProvider.announcements
              .where((a) => a.type != 'update')
              .toList();
          _isLoadingAnnouncements = false;
        });

        // 🚀 总是启动跑马灯滚动（云通知或默认静态公告都需要）
        _startAutoScroll();
      }
    } catch (e) {
      debugPrint('LoginScreen: 加载云通知失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
        
        // 🚀 即使加载失败，也启动跑马灯显示默认公告
        _startAutoScroll();
      }
    }
  }

  /// 启动自动滚动（跑马灯效果）
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    
    // 等待布局完成后再开始滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_announcementScrollController.hasClients) return;
      
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted || !_announcementScrollController.hasClients) {
          timer.cancel();
          return;
        }

        final maxScroll = _announcementScrollController.position.maxScrollExtent;
        final currentScroll = _announcementScrollController.offset;

        // 如果滚动到末尾，重置到开头
        if (currentScroll >= maxScroll) {
          _announcementScrollController.jumpTo(0);
        } else {
          // 每次滚动 1 像素
          _announcementScrollController.jumpTo(currentScroll + 1);
        }
      });
    });
  }

  Future<void> _loadSavedLoginInfo() async {
    debugPrint('LoginScreen: 加载保存的登录信息');
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // 🎯 大厂标准：加载服务器选择偏好（跨页面共享）
    final prefsService = appProvider.preferencesService;
    final useCustomServer = await prefsService.getUseCustomServer();
    final customServerUrl = await prefsService.getCustomServerUrl();
    
    final savedServer = await appProvider.getSavedServer();
    final savedUsername = await appProvider.getSavedUsername();
    final savedPassword = await appProvider.getSavedPassword();
    final savedToken = await appProvider.getSavedToken(); // 获取保存的token
    
    debugPrint('LoginScreen: 使用自定义服务器: $useCustomServer');
    debugPrint('LoginScreen: 自定义服务器地址: $customServerUrl');

    setState(() {
      _useCustomServer = useCustomServer;
      _serverController.text = useCustomServer && customServerUrl != null
          ? customServerUrl
          : AppConfig.officialMemosServer;
    });

    if (savedUsername != null) {
      debugPrint('LoginScreen: 发现保存的用户名');
      setState(() {
        _usernameController.text = savedUsername;
      });
    }

    if (savedPassword != null) {
      debugPrint('LoginScreen: 发现保存的密码');
      setState(() {
        _passwordController.text = savedPassword;
      });
    }

    // 🔑 检查是否有有效的token可以快速登录
    if (savedToken != null && savedServer != null && savedUsername != null) {
      _attemptQuickLogin(savedServer, savedToken);
    }
  }

  // 🎯 大厂标准：处理服务器选择变化（实时同步到SharedPreferences）
  Future<void> _onServerTypeChanged(bool useCustom) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final prefsService = appProvider.preferencesService;
    
    if (useCustom) {
      // 切换到自定义：显示之前保存的自定义地址，如果没有则清空
      final savedCustomUrl = await prefsService.getCustomServerUrl();
      setState(() {
        _useCustomServer = true;
        _serverController.text = (savedCustomUrl != null && 
                savedCustomUrl != AppConfig.officialMemosServer) 
            ? savedCustomUrl 
            : ''; // 清空输入框，让用户输入
      });
    } else {
      // 切换到官方：显示官方地址
      setState(() {
        _useCustomServer = false;
        _serverController.text = AppConfig.officialMemosServer;
      });
      await prefsService.saveCustomServerUrl(AppConfig.officialMemosServer);
    }
    
    // 保存选择到SharedPreferences，实现跨页面同步
    await prefsService.saveUseCustomServer(useCustom);
    
    debugPrint('LoginScreen: 服务器选择已更改: ${useCustom ? "自定义" : "官方"}');
  }
  
  // 🎯 大厂标准：处理自定义服务器地址变化
  Future<void> _onCustomServerUrlChanged(String url) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final prefsService = appProvider.preferencesService;
    
    // 保存到SharedPreferences，实现跨页面同步
    await prefsService.saveCustomServerUrl(url);
    
    debugPrint('LoginScreen: 自定义服务器地址已更新: $url');
  }

  // 🚀 尝试使用保存的token快速登录
  Future<void> _attemptQuickLogin(String serverUrl, String token) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // 尝试使用token登录
      final result =
          await appProvider.loginWithToken(serverUrl, token, remember: true);

      if (result.$1 && mounted) {
        // 成功则直接跳转到主页
        context.go('/');

        // 后台同步数据
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            debugPrint('LoginScreen: 开始后台数据同步');
            await appProvider.fetchNotesFromServer();
          } catch (e) {
            debugPrint('LoginScreen: 后台同步失败: $e');
          }
        });
      } else {
        // Token失效，清除保存的登录信息，让用户手动登录
        await appProvider.clearLoginInfo();
      }
    } catch (e) {
      // 异常情况下清除保存的登录信息
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.clearLoginInfo();
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final serverUrl = _useCustomServer
          ? _serverController.text.trim()
          : AppConfig.officialMemosServer;
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      debugPrint('LoginScreen: 尝试登录，记住密码: $_rememberLogin');

      final result = await appProvider.loginWithPassword(
        serverUrl,
        username,
        password,
        remember: _rememberLogin,
      );

      if (result.$1 && mounted) {
        debugPrint('LoginScreen: 登录成功，立即进入主界面');

        // 🎉 显示成功提示
        await _showSuccessLoginDialog();

        // 🎉 成功动画
        await _scaleController.reverse();

        context.go('/');

        // 后台执行数据同步
        Future.microtask(() async {
          try {
            debugPrint('LoginScreen: 开始后台数据同步');
            await appProvider.fetchNotesFromServer();
            final hasLocalData = await appProvider.hasLocalData();
            if (hasLocalData) {
              await appProvider.syncLocalDataToServer();
            }
          } catch (e) {
            debugPrint('LoginScreen: 后台同步失败: $e');
          }
        });
      } else if (mounted) {
        debugPrint('LoginScreen: 登录失败: ${result.$2}');
        final l10n = AppLocalizationsSimple.of(context);
        SnackBarUtils.showError(
          context,
          result.$2 ??
              (AppLocalizationsSimple.of(context)
                      ?.loginFailedCheckCredentials ??
                  '登录失败，请检查账号密码和服务器地址'),
          onRetry: _login,
        );
      }
    } catch (e) {
      debugPrint('LoginScreen: 登录异常: $e');
      if (mounted) {
        SnackBarUtils.showNetworkError(
          context,
          e,
          onRetry: _login,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🎉 显示登录成功对话框
  Future<void> _showSuccessLoginDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: ResponsiveUtils.responsivePadding(context, all: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 成功动画图标
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Container(
                  width: ResponsiveUtils.responsiveIconSize(context, 80),
                  height: ResponsiveUtils.responsiveIconSize(context, 80),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: ResponsiveUtils.responsiveIconSize(context, 50),
                    color: Colors.green,
                  ),
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 20)),

            Text(
              AppLocalizationsSimple.of(context)?.loginSuccessful ?? '登录成功！',
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),

            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),

            Text(
              AppLocalizationsSimple.of(context)?.welcomeBackPreparingSpace ??
                  '欢迎回来！正在为您准备个人笔记空间...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 14),
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 20)),

            // 加载进度指示器
            SizedBox(
              width: ResponsiveUtils.responsive<double>(
                context,
                mobile: 200,
                tablet: 220,
                desktop: 250,
              ),
              child: LinearProgressIndicator(
                backgroundColor:
                    isDarkMode ? Colors.grey[700] : Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );

    // 1.5秒后自动关闭对话框
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizationsSimple.of(context);

    // 🎨 现代化配色方案 - 绿色主题
    const primaryColor = AppTheme.primaryColor;
    const primaryLight = AppTheme.primaryLightColor;
    const primaryDark = AppTheme.primaryDarkColor;

    final surfaceColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    final cardColor =
        isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor;

    final textPrimary =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    final textSecondary = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    return Scaffold(
      backgroundColor: surfaceColor,
      extendBodyBehindAppBar: true,
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _buildNavButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => context.go('/'),
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                textPrimary: textPrimary,
              ),
              actions: [
                _buildNavButton(
                  icon: Icons.help_outline,
                  onTap: _showHelpDialog,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textPrimary: textPrimary,
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                _buildNavButton(
                  icon: Icons.help_outline,
                  onTap: _showHelpDialog,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  textPrimary: textPrimary,
                ),
              ],
            ),
      body: Stack(
        children: [
          // 🌟 背景装饰层
          _buildBackgroundDecoration(isDarkMode, primaryColor, screenHeight),

          // 🎭 主要内容层
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: ResponsiveLayout(
                mobile: _buildMobileLayout(
                  textPrimary,
                  textSecondary,
                  primaryColor,
                  primaryLight,
                  cardColor,
                  isDarkMode,
                ),
                tablet: _buildTabletLayout(
                  textPrimary,
                  textSecondary,
                  primaryColor,
                  primaryLight,
                  cardColor,
                  isDarkMode,
                ),
                desktop: _buildDesktopLayout(
                  textPrimary,
                  textSecondary,
                  primaryColor,
                  primaryLight,
                  cardColor,
                  isDarkMode,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局
  Widget _buildMobileLayout(
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color primaryLight,
    Color cardColor,
    bool isDarkMode,
  ) =>
      CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🚀 英雄区域
          SliverToBoxAdapter(
            child: _buildHeroSection(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              isDarkMode: isDarkMode,
            ),
          ),

          // 📝 登录表单
          SliverToBoxAdapter(
            child: _buildLoginForm(
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              primaryLight: primaryLight,
              isDarkMode: isDarkMode,
            ),
          ),

          // 🔗 快速操作
          SliverToBoxAdapter(
            child: _buildQuickActions(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
          ),

          // 📱 底部空间
          SliverToBoxAdapter(
            child: SizedBox(
              height: ResponsiveUtils.responsiveSpacing(context, 40),
            ),
          ),
        ],
      );

  // 平板布局
  Widget _buildTabletLayout(
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color primaryLight,
    Color cardColor,
    bool isDarkMode,
  ) =>
      // 平板使用左右分栏布局，类似桌面但比例调整
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧装饰区域
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizationsSimple.of(context)
                              ?.intelligentNoteManagement ??
                          '智能笔记管理，\n让思考更有条理',
                      style: TextStyle(
                        fontSize: 20,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),

              // 右侧登录区域
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoginForm(
                        cardColor: cardColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryColor: primaryColor,
                        primaryLight: primaryLight,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 24),
                      _buildQuickActions(
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // 桌面布局
  Widget _buildDesktopLayout(
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color primaryLight,
    Color cardColor,
    bool isDarkMode,
  ) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧装饰区域
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConfig.appName,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizationsSimple.of(context)
                                ?.intelligentNoteManagement ??
                            '智能笔记管理，\n让思考更有条理',
                        style: TextStyle(
                          fontSize: 24,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),

                // 右侧登录区域
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLoginForm(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                          primaryLight: primaryLight,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 32),
                        _buildQuickActions(
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // 🌟 背景装饰层
  Widget _buildBackgroundDecoration(
    bool isDarkMode,
    Color primaryColor,
    double screenHeight,
  ) =>
      AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) => Stack(
          children: [
            // 渐变背景
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          AppTheme.darkBackgroundColor,
                          AppTheme.darkSurfaceColor,
                          AppTheme.darkCardColor,
                        ]
                      : [
                          AppTheme.backgroundColor,
                          AppTheme.surfaceColor,
                          Colors.white,
                        ],
                ),
              ),
            ),

            // 浮动装饰圆圈
            Positioned(
              top: screenHeight * 0.15 + _floatingAnimation.value * 30,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.15),
                      primaryColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 左侧装饰
            Positioned(
              bottom: screenHeight * 0.3 - _floatingAnimation.value * 20,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // 🎯 导航按钮
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color cardColor,
    required Color textPrimary,
  }) =>
      Container(
        margin: const EdgeInsets.all(12),
        child: Material(
          color: cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Icon(
                icon,
                color: textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      );

  // 🚀 英雄区域
  Widget _buildHeroSection({
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required bool isDarkMode,
  }) {
    // 根据屏幕类型判断是否显示英雄区域
    if (ResponsiveUtils.isDesktop(context)) {
      return const SizedBox.shrink(); // 桌面版本不显示英雄区域
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(_fadeAnimation),
        child: Container(
          padding: ResponsiveUtils.responsivePadding(
            context,
            horizontal: 32,
            vertical: 60,
          ),
          child: Column(
            children: [
              // Logo区域
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: ResponsiveUtils.responsive<double>(
                    context,
                    mobile: 80,
                    tablet: 100,
                  ),
                  height: ResponsiveUtils.responsive<double>(
                    context,
                    mobile: 80,
                    tablet: 100,
                  ),
                  margin: ResponsiveUtils.responsivePadding(
                    context,
                    bottom: 32,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        AppTheme.primaryLightColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/images/black2logo.png'
                          : 'assets/images/logo.png',
                      width: ResponsiveUtils.responsiveIconSize(context, 40),
                      height: ResponsiveUtils.responsiveIconSize(context, 40),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // 主标题
              Text(
                AppLocalizationsSimple.of(context)?.welcomeBack ?? '欢迎回来',
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 36),
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 12)),

              // 副标题
              Text(
                AppLocalizationsSimple.of(context)?.continueCreativeJourney ??
                    '继续您的创作之旅',
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, 16),
                  color: textSecondary,
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),

              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, 24)),

              // 🔔 云通知展示区域
              _buildAnnouncementsSection(
                primaryColor: primaryColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔔 构建云通知展示区域
  Widget _buildAnnouncementsSection({
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    // 如果正在加载，显示加载指示器
    if (_isLoadingAnnouncements) {
      return Container(
        padding: ResponsiveUtils.responsivePadding(
          context,
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 12)),
            Text(
              '正在获取通知...',
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, 12),
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 🚀 统一使用跑马灯效果展示公告（无论是否有云通知）
    // 如果有云通知，显示云通知；否则显示默认的静态公告
    String announcementText;
    if (_announcements.isEmpty) {
      // 使用静态公告（默认内容）
      announcementText = _staticAnnouncements.join('  •  ');
    } else {
      // 使用云通知内容
      announcementText = _announcements.map((a) => a.content).join('  •  ');
    }
    
    return Container(
      height: ResponsiveUtils.responsive<double>(
        context,
        mobile: 48,
        tablet: 52,
      ),
      padding: ResponsiveUtils.responsivePadding(
        context,
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(isDarkMode ? 0.12 : 0.08),
            primaryColor.withOpacity(isDarkMode ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(isDarkMode ? 0.25 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 图标
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(isDarkMode ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: ResponsiveUtils.responsiveIconSize(context, 16),
              color: primaryColor,
            ),
          ),
          SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 10)),
          // 滚动文本区域
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                controller: _announcementScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // 禁止手动滚动
                child: Row(
                  children: [
                    Text(
                      announcementText,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          13,
                        ),
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                        height: 1.3,
                      ),
                    ),
                    // 为了实现无缝循环，添加一段空白后再重复一次文本
                    SizedBox(width: ResponsiveUtils.responsiveSpacing(context, 40)),
                    Text(
                      announcementText,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(
                          context,
                          13,
                        ),
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔔 构建单个通知卡片
  Widget _buildAnnouncementCard({
    required Announcement announcement,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDarkMode,
  }) {
    // 根据通知类型选择图标和颜色
    IconData icon;
    Color accentColor;

    switch (announcement.type) {
      case 'warning':
        icon = Icons.warning_amber_rounded;
        accentColor = Colors.orange;
        break;
      case 'event':
        icon = Icons.celebration_outlined;
        accentColor = Colors.purple;
        break;
      case 'info':
      default:
        icon = Icons.info_outline;
        accentColor = primaryColor;
        break;
    }

    return Container(
      padding: ResponsiveUtils.responsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(isDarkMode ? 0.12 : 0.08),
            accentColor.withOpacity(isDarkMode ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(isDarkMode ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(isDarkMode ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: ResponsiveUtils.responsiveIconSize(context, 18),
              color: accentColor,
            ),
          ),
          SizedBox(
            width: ResponsiveUtils.responsiveSpacing(context, 14),
          ),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      13.5,
                    ),
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.3,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (announcement.content.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveUtils.responsiveSpacing(
                      context,
                      4,
                    ),
                  ),
                  Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.responsiveFontSize(
                        context,
                        11.5,
                      ),
                      color: textSecondary,
                      height: 1.4,
                      letterSpacing: 0.05,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📝 登录表单
  Widget _buildLoginForm({
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required Color primaryLight,
    required bool isDarkMode,
  }) {
    final l10n = AppLocalizationsSimple.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: ResponsiveUtils.responsivePadding(context, horizontal: 24),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsive<double>(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 32,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 服务器选择
                      _buildServerSection(
                        textPrimary,
                        textSecondary,
                        primaryColor,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),

                      // 用户名
                      _buildTextField(
                        controller: _usernameController,
                        label: AppLocalizationsSimple.of(context)?.username ??
                            '用户名',
                        hint: AppLocalizationsSimple.of(context)?.username ??
                            '请输入您的用户名',
                        icon: Icons.person_outline,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryColor: primaryColor,
                        isDarkMode: isDarkMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizationsSimple.of(context)
                                    ?.pleaseEnterUsername ??
                                '请输入用户名';
                          }
                          if (value.length < 2) {
                            return AppLocalizationsSimple.of(context)
                                    ?.usernameMinLength ??
                                '用户名至少需要2个字符';
                          }
                          if (value.contains(' ')) {
                            return AppLocalizationsSimple.of(context)
                                    ?.usernameNoSpaces ??
                                '用户名不能包含空格';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 密码
                      _buildTextField(
                        controller: _passwordController,
                        label: AppLocalizationsSimple.of(context)?.password ??
                            '密码',
                        hint: AppLocalizationsSimple.of(context)
                                ?.pleaseEnterPassword ??
                            '请输入您的密码',
                        icon: Icons.lock_outline,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryColor: primaryColor,
                        isDarkMode: isDarkMode,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizationsSimple.of(context)
                                    ?.pleaseEnterPassword ??
                                '请输入密码';
                          }
                          if (value.length < 6) {
                            return AppLocalizationsSimple.of(context)
                                    ?.passwordMinLength ??
                                '密码至少需要6个字符';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 记住密码开关
                      _buildRememberSwitch(
                        textPrimary,
                        textSecondary,
                        primaryColor,
                      ),

                      const SizedBox(height: 32),

                      // 登录按钮
                      _buildLoginButton(primaryColor, primaryLight, isDarkMode),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 大厂标准：服务器选择器（下拉框 + 条件显示输入框）
  Widget _buildServerSection(
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 服务器类型选择标题
        Text(
          AppLocalizationsSimple.of(context)?.server ?? '服务器',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        
        // 下拉选择框（官方/自定义）
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: _useCustomServer,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: primaryColor,
              ),
              dropdownColor: isDarkMode
                  ? AppTheme.darkCardColor
                  : AppTheme.surfaceColor,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              items: [
                DropdownMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 20,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizationsSimple.of(context)?.officialServer ?? '官方服务器',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            AppLocalizationsSimple.of(context)?.recommended ?? '推荐使用',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 20,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizationsSimple.of(context)?.customServer ?? '自定义服务器',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _onServerTypeChanged(value);
                }
              },
            ),
          ),
        ),
        
        // 🎯 自定义服务器地址输入框（仅在选择自定义时显示）
        if (_useCustomServer) ...[
          const SizedBox(height: 20),
          Text(
            AppLocalizationsSimple.of(context)?.serverAddress ?? '服务器地址',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _serverController,
            style: TextStyle(
              fontSize: 16,
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              // 实时保存到SharedPreferences
              _onCustomServerUrlChanged(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizationsSimple.of(context)?.enterServerAddress ?? '请输入服务器地址';
              }
              if (!value.startsWith('http://') && !value.startsWith('https://')) {
                return AppLocalizationsSimple.of(context)?.serverAddressMustStartWithHttp ?? '服务器地址必须以 http:// 或 https:// 开头';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'https://your-memos-server.com',
              hintStyle: TextStyle(
                color: textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 📝 输入框组件
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required bool isDarkMode,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            style: TextStyle(
              fontSize: 16,
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 16,
                ),
              ),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ],
      );

  // 💡 记住密码开关
  Widget _buildRememberSwitch(
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
  ) =>
      Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.save_alt,
              color: primaryColor,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizationsSimple.of(context)?.rememberPassword ??
                      '记住密码',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizationsSimple.of(context)?.saveAccountLocally ??
                      '保存账号和密码到本地',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _rememberLogin,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                _rememberLogin = value;
              });
            },
          ),
        ],
      );

  // 🎯 登录按钮
  Widget _buildLoginButton(
    Color primaryColor,
    Color primaryLight,
    bool isDarkMode,
  ) {
    final l10n = AppLocalizationsSimple.of(context);
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : LinearGradient(
                colors: [
                  primaryColor,
                  primaryLight,
                ],
              ),
        color: _isLoading
            ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _login,
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppLocalizationsSimple.of(context)?.login ?? '登录',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 🔗 快速操作
  Widget _buildQuickActions({
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text(
              AppLocalizationsSimple.of(context)?.noAccount ?? '还没有账号？',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/register'),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      AppLocalizationsSimple.of(context)?.registerNow ?? '立即注册',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 版本兼容性详细说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.support,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizationsSimple.of(context)
                                ?.versionCompatibility ??
                            '版本兼容性说明',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 本应用专为 Memos 0.21.0 版本优化\n• 不同版本的 API 接口存在较大差异\n• 0.21.0 版本经过充分测试，功能稳定\n• 建议使用指定版本以获得最佳体验',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizationsSimple.of(context)?.contactSupport ??
                        '如有疑问，请查看官方文档或联系技术支持',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // 🔧 自定义服务器对话框
  void _showCustomServerDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor =
        isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    const primaryColor = AppTheme.primaryColor;

    final customServerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: dialogColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dns_outlined,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizationsSimple.of(context)?.customServer ??
                          '自定义服务器',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizationsSimple.of(context)
                                  ?.customServerWarning ??
                              '使用自定义服务器可能会影响使用体验',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: customServerController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizationsSimple.of(context)?.serverAddress ??
                            '服务器地址',
                    hintText: 'https://your-server.com',
                    prefixIcon: const Icon(Icons.language, color: primaryColor),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  style: TextStyle(fontSize: 16, color: textColor),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🎯 大厂标准：提供快捷返回官方服务器的选项
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _useCustomServer = false;
                          _serverController.text = AppConfig.officialMemosServer;
                        });
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text(
                        '使用官方',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizationsSimple.of(context)?.cancel ?? '取消',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            final customServer = customServerController.text.trim();
                            if (customServer.isNotEmpty) {
                              setState(() {
                                _useCustomServer = true;
                                _serverController.text =
                                    customServer.startsWith('http')
                                        ? customServer
                                        : 'https://$customServer';
                              });
                            }
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            AppLocalizationsSimple.of(context)?.confirm ?? '确定',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆘 帮助对话框 - 常见问题
  void _showHelpDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogColor =
        isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor;
    final textPrimary =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final textSecondary = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    const primaryColor = AppTheme.primaryColor;
    const accentColor = AppTheme.accentColor;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth:
                  ResponsiveUtils.isMobile(context) ? double.infinity : 600,
            ),
            decoration: BoxDecoration(
              color: dialogColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎨 对话框头部
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        accentColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizationsSimple.of(context)?.faq ?? '常见问题',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizationsSimple.of(context)
                                      ?.answerYourQuestions ??
                                  '为您解答使用中的疑问',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: textSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 📋 问题列表
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildFAQItem(
                          icon: Icons.login_outlined,
                          iconColor: primaryColor,
                          question:
                              AppLocalizationsSimple.of(context)?.howToLogin ??
                                  '如何登录账号？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.howToLoginAnswer ??
                              '输入您注册时使用的用户名和密码，即可登录。如果开启"记住密码"，下次将自动登录。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.dns_outlined,
                          iconColor: accentColor,
                          question: AppLocalizationsSimple.of(context)
                                  ?.whatIsServer ??
                              '什么是服务器？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.whatIsServerAnswer ??
                              '服务器用于存储和同步您的笔记数据。推荐使用官方服务器，也可以使用自己部署的 Memos 服务器。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.cloud_sync_outlined,
                          iconColor: primaryColor,
                          question: AppLocalizationsSimple.of(context)
                                  ?.howToSyncData ??
                              '如何同步数据？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.howToSyncDataAnswer ??
                              '登录后，您的笔记将自动同步到服务器。支持多端同步，在任何设备登录都能查看您的笔记。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.edit_note_outlined,
                          iconColor: accentColor,
                          question: '笔记支持哪些功能？',
                          answer:
                              '支持 Markdown 格式、图片上传、标签分类、提醒功能、知识图谱等。还能使用 AI 助手帮助您创作和整理笔记。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.security_outlined,
                          iconColor: primaryColor,
                          question: '数据安全吗？',
                          answer: '我们使用加密传输保护您的数据安全。本地数据也经过安全存储。建议定期备份重要笔记。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.lock_reset_outlined,
                          iconColor: accentColor,
                          question: AppLocalizationsSimple.of(context)?.whatIfForgotPassword ?? '忘记密码怎么办？',
                          answer: AppLocalizationsSimple.of(context)?.whatIfForgotPasswordAnswer ?? '如使用官方服务器，请联系管理员重置密码。如使用自定义服务器，请联系您的服务器管理员。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🎯 底部操作区
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '还有其他问题？',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // 可以跳转到帮助中心或联系客服
                          context.push('/help');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          '查看帮助中心',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 FAQ 条目组件
  Widget _buildFAQItem({
    required IconData icon,
    required Color iconColor,
    required String question,
    required String answer,
    required bool isDarkMode,
    required Color textPrimary,
    required Color textSecondary,
  }) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            title: Text(
              question,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            iconColor: iconColor,
            collapsedIconColor: textSecondary,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
