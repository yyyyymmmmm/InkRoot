import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberLogin = true;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _useCustomServer = false;

  late AnimationController _heroController;
  late AnimationController _formController;
  late AnimationController _floatingController;
  late Animation<double> _heroAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedServerInfo();

    // 精心设计的动画系统
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _formController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutExpo,
    );

    _formAnimation = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_formAnimation);

    // 启动动画序列
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _heroController.dispose();
    _formController.dispose();
    _floatingController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedServerInfo() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 🎯 大厂标准：加载服务器选择偏好（跨页面共享）
    final prefsService = appProvider.preferencesService;
    final useCustomServer = await prefsService.getUseCustomServer();
    final customServerUrl = await prefsService.getCustomServerUrl();

    debugPrint('RegisterScreen: 使用自定义服务器: $useCustomServer');
    debugPrint('RegisterScreen: 自定义服务器地址: $customServerUrl');

    setState(() {
      _useCustomServer = useCustomServer;
      _serverController.text = useCustomServer && customServerUrl != null
          ? customServerUrl
          : AppConfig.officialMemosServer;
    });
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

    debugPrint('RegisterScreen: 服务器选择已更改: ${useCustom ? "自定义" : "官方"}');
  }

  // 🎯 大厂标准：处理自定义服务器地址变化
  Future<void> _onCustomServerUrlChanged(String url) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final prefsService = appProvider.preferencesService;

    // 保存到SharedPreferences，实现跨页面同步
    await prefsService.saveCustomServerUrl(url);

    debugPrint('RegisterScreen: 自定义服务器地址已更新: $url');
  }

  void _openPrivacyPolicy() {
    context.push('/privacy-policy-detail');
  }

  void _openUserAgreement() {
    context.push('/user-agreement');
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      SnackBarUtils.showWarning(
        context,
        AppLocalizationsSimple.of(context)?.pleaseAgreeToPolicy ??
            '请阅读并同意隐私政策及用户协议',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final serverUrl = _useCustomServer
          ? _serverController.text.trim()
          : AppConfig.officialMemosServer;
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final result = await appProvider.registerWithPassword(
        serverUrl,
        username,
        password,
        remember: _rememberLogin,
      );

      if (result.$1 && mounted) {
        SnackBarUtils.showSuccess(
          context,
          AppLocalizationsSimple.of(context)?.registrationSuccessful ??
              '注册成功！正在为您登录...',
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/');
        }
      } else if (mounted) {
        SnackBarUtils.showError(
          context,
          result.$2 ??
              (AppLocalizationsSimple.of(context)?.registrationFailed ??
                  '注册失败，请检查信息后重试'),
          onRetry: _register,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        SnackBarUtils.showNetworkError(
          context,
          e,
          onRetry: _register,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 🎨 符合现有主题的配色方案
    const primaryColor = AppTheme.primaryColor;

    final surfaceColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    final cardColor =
        isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor;

    final textPrimary =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;

    final textSecondary = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;

    final accentGlow = primaryColor.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: surfaceColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 🌟 背景装饰层 - 现代极简风格
          _buildBackgroundDecoration(isDarkMode, primaryColor),

          // 🎭 主要内容层
          SafeArea(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(
                isDarkMode,
                cardColor,
                textPrimary,
                textSecondary,
                primaryColor,
                accentGlow,
              ),
              tablet: _buildTabletLayout(
                isDarkMode,
                cardColor,
                textPrimary,
                textSecondary,
                primaryColor,
                accentGlow,
              ),
              desktop: _buildDesktopLayout(
                isDarkMode,
                cardColor,
                textPrimary,
                textSecondary,
                primaryColor,
                accentGlow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局
  Widget _buildMobileLayout(
    bool isDarkMode,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color accentGlow,
  ) =>
      CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎯 顶部导航栏
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _buildNavButton(
              icon: Icons.arrow_back_ios_new,
              // 🎯 大厂标准：智能返回，如果能pop就pop，否则跳转到登录页
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/login');
                }
              },
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
          ),

          // 🚀 英雄标题区域
          SliverToBoxAdapter(
            child: _buildHeroSection(
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
          ),

          // 📝 表单区域
          SliverToBoxAdapter(
            child: _buildFormSection(
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              accentGlow: accentGlow,
              isDarkMode: isDarkMode,
            ),
          ),

          // 🔧 设置区域
          SliverToBoxAdapter(
            child: _buildSettingsSection(
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              isDarkMode: isDarkMode,
            ),
          ),

          // 📄 条款区域
          SliverToBoxAdapter(
            child: _buildTermsSection(
              cardColor: cardColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
          ),

          // 🎯 操作区域
          SliverToBoxAdapter(
            child: _buildActionSection(
              primaryColor: primaryColor,
              textPrimary: textPrimary,
              cardColor: cardColor,
              isDarkMode: isDarkMode,
            ),
          ),

          // 📱 底部区域
          SliverToBoxAdapter(
            child: SizedBox(
              height: ResponsiveUtils.responsiveSpacing(context, 40),
            ),
          ),
        ],
      );

  // 平板布局
  Widget _buildTabletLayout(
    bool isDarkMode,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color accentGlow,
  ) =>
      // 平板使用左右分栏布局
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _buildNavButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
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
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
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
                        AppLocalizationsSimple.of(context)?.createAccount ??
                            '创建账户',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizationsSimple.of(context)
                                ?.startYourCreativeJourney ??
                            '开启您的创作之旅',
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

                // 右侧注册表单区域
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFormSection(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                          accentGlow: accentGlow,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsSection(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildTermsSection(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 24),
                        _buildActionSection(
                          primaryColor: primaryColor,
                          textPrimary: textPrimary,
                          cardColor: cardColor,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // 桌面布局
  Widget _buildDesktopLayout(
    bool isDarkMode,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color accentGlow,
  ) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Row(
              children: [
                // 左侧信息区域
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizationsSimple.of(context)?.joinInkRoot ??
                            '加入 InkRoot',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizationsSimple.of(context)
                                ?.startIntelligentNoteJourney ??
                            '开启您的智能笔记之旅',
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

                // 右侧注册表单区域
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormSection(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                          accentGlow: accentGlow,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsSection(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        _buildTermsSection(
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 24),
                        _buildActionSection(
                          primaryColor: primaryColor,
                          textPrimary: textPrimary,
                          cardColor: cardColor,
                          isDarkMode: isDarkMode,
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
  Widget _buildBackgroundDecoration(bool isDarkMode, Color primaryColor) =>
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
              top: 100 + _floatingAnimation.value * 20,
              right: 50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      primaryColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 左侧装饰
            Positioned(
              bottom: 200 - _floatingAnimation.value * 30,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.08),
                      primaryColor.withValues(alpha: 0.03),
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
          color: cardColor.withValues(alpha: 0.8),
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
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
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

  // 🚀 英雄标题区域
  Widget _buildHeroSection({
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) =>
      FadeTransition(
        opacity: _heroAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(_heroAnimation),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo区域
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        AppTheme.primaryLightColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/images/black2logo.png'
                          : 'assets/images/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 主标题
                Text(
                  AppLocalizationsSimple.of(context)?.startCreativeJourney ??
                      '开启您的\n创作之旅',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // 副标题
                Text(
                  AppLocalizationsSimple.of(context)?.recordEachMoment ??
                      '加入 InkRoot，记录每一个值得珍藏的时刻',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // 📝 表单区域
  Widget _buildFormSection({
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required Color accentGlow,
    required bool isDarkMode,
  }) =>
      SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _formAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                      label:
                          AppLocalizationsSimple.of(context)?.username ?? '用户名',
                      hint: AppLocalizationsSimple.of(context)
                              ?.pleaseEnterUsername ??
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
                        if (value.length < 3) {
                          return AppLocalizationsSimple.of(context)
                                  ?.usernameMinLength3 ??
                              '用户名至少需要3个字符';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_\u4e00-\u9fa5]+$')
                            .hasMatch(value)) {
                          return AppLocalizationsSimple.of(context)
                                  ?.usernameInvalidChars ??
                              '用户名只能包含字母、数字、下划线和中文';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // 密码
                    _buildTextField(
                      controller: _passwordController,
                      label:
                          AppLocalizationsSimple.of(context)?.password ?? '密码',
                      hint: AppLocalizationsSimple.of(context)?.passwordHint ??
                          '至少8位，包含字母或数字',
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
                        if (value.length < 8) {
                          return AppLocalizationsSimple.of(context)
                                  ?.passwordMinLength ??
                              '密码至少需要8个字符';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // 确认密码
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label:
                          AppLocalizationsSimple.of(context)?.confirmPassword ??
                              '确认密码',
                      hint: AppLocalizationsSimple.of(context)
                              ?.pleaseConfirmPassword ??
                          '请再次输入密码',
                      icon: Icons.lock_outline,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      primaryColor: primaryColor,
                      isDarkMode: isDarkMode,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizationsSimple.of(context)
                                  ?.pleaseConfirmPassword ??
                              '请再次输入密码';
                        }
                        if (value != _passwordController.text) {
                          return AppLocalizationsSimple.of(context)
                                  ?.passwordMismatch ??
                              '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  // 🔧 设置区域
  Widget _buildSettingsSection({
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required bool isDarkMode,
  }) =>
      Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizationsSimple.of(context)
                              ?.autoLoginAfterRegistration ??
                          '注册后自动登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizationsSimple.of(context)?.betterExperience ??
                          '为您提供更便捷的使用体验',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _rememberLogin,
                activeThumbColor: primaryColor,
                onChanged: (value) {
                  setState(() {
                    _rememberLogin = value;
                  });
                },
              ),
            ],
          ),
        ),
      );

  // 📄 条款区域
  Widget _buildTermsSection({
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _agreedToTerms = !_agreedToTerms;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _agreedToTerms ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: _agreedToTerms ? primaryColor : textSecondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _agreedToTerms
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: AppLocalizationsSimple.of(context)?.agreeToTerms ??
                          '我已阅读并同意 ',
                    ),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _openPrivacyPolicy,
                        child: Text(
                          AppLocalizationsSimple.of(context)?.privacyPolicy ??
                              '隐私政策',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' 和 '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _openUserAgreement,
                        child: Text(
                          AppLocalizationsSimple.of(context)?.userAgreement ??
                              '用户协议',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // 🎯 操作区域
  Widget _buildActionSection({
    required Color primaryColor,
    required Color textPrimary,
    required Color cardColor,
    required bool isDarkMode,
  }) =>
      Container(
        margin: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 注册按钮
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _isLoading || !_agreedToTerms
                    ? null
                    : LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                color: _isLoading || !_agreedToTerms
                    ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isLoading || !_agreedToTerms
                    ? []
                    : [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading || !_agreedToTerms ? null : _register,
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
                            AppLocalizationsSimple.of(context)?.startCreating ??
                                '开始创作',
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
            ),

            const SizedBox(height: 24),

            // 登录链接
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  // 🎯 大厂标准：明确跳转到登录页面，而不是pop
                  // 因为用户可能直接访问注册页面（不是从登录页面来的）
                  onTap: () {
                    // 如果能pop就pop（从登录页面来的），否则go到登录页面
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizationsSimple.of(context)
                                  ?.alreadyHaveAccount ??
                              '已有账号？立即登录',
                          style: TextStyle(
                            fontSize: 15,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
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

  // 🎯 大厂标准：服务器选择器（下拉框 + 条件显示输入框）
  Widget _buildServerSection(
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    bool isDarkMode,
  ) =>
      Column(
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
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
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
                dropdownColor:
                    isDarkMode ? AppTheme.darkCardColor : AppTheme.surfaceColor,
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
                              AppLocalizationsSimple.of(context)
                                      ?.officialServer ??
                                  '官方服务器',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              AppLocalizationsSimple.of(context)?.recommended ??
                                  '推荐使用',
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
                          AppLocalizationsSimple.of(context)?.customServer ??
                              '自定义服务器',
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
              onChanged: _onCustomServerUrlChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入服务器地址';
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return '服务器地址必须以 http:// 或 https:// 开头';
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
                    color: primaryColor.withValues(alpha: 0.1),
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
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
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
                  color: primaryColor.withValues(alpha: 0.1),
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
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
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
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.1),
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
                        primaryColor.withValues(alpha: 0.1),
                        accentColor.withValues(alpha: 0.05),
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
                          color: primaryColor.withValues(alpha: 0.15),
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
                          icon: Icons.person_add_outlined,
                          iconColor: primaryColor,
                          question: AppLocalizationsSimple.of(context)
                                  ?.howToRegister ??
                              '如何注册账号？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.howToRegisterAnswer ??
                              '填写用户名和密码（至少8位），勾选同意协议后点击"开始创作"即可注册。注册成功后将自动登录。',
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
                          question: AppLocalizationsSimple.of(context)
                                  ?.whatFeaturesSupported ??
                              '笔记支持哪些功能？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.whatFeaturesAnswer ??
                              '支持 Markdown 格式、图片上传、标签分类、提醒功能、知识图谱等。还能使用 AI 助手帮助您创作和整理笔记。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.security_outlined,
                          iconColor: primaryColor,
                          question:
                              AppLocalizationsSimple.of(context)?.isDataSafe ??
                                  '数据安全吗？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.isDataSafeAnswer ??
                              '我们使用加密传输保护您的数据安全。本地数据也经过安全存储。建议定期备份重要笔记。',
                          isDarkMode: isDarkMode,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        _buildFAQItem(
                          icon: Icons.lock_reset_outlined,
                          iconColor: accentColor,
                          question: AppLocalizationsSimple.of(context)
                                  ?.whatIfForgotPassword ??
                              '忘记密码怎么办？',
                          answer: AppLocalizationsSimple.of(context)
                                  ?.whatIfForgotPasswordAnswer ??
                              '如使用官方服务器，请联系管理员重置密码。如使用自定义服务器，请联系您的服务器管理员。',
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
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
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
                          AppLocalizationsSimple.of(context)
                                  ?.anyOtherQuestions ??
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
                        child: Text(
                          AppLocalizationsSimple.of(context)?.viewHelpCenter ??
                              '查看帮助中心',
                          style: const TextStyle(
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
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
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
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
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
