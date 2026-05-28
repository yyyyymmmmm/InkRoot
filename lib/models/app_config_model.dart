import 'sidebar_config.dart';

class AppConfig {
  AppConfig({
    this.isLocalMode = false,
    this.memosApiUrl,
    this.lastToken,
    this.lastUsername,
    this.lastServerUrl,
    this.rememberLogin = false,
    this.autoLogin = false,
    this.autoSyncEnabled = false,
    this.syncInterval = 300,
    this.isDarkMode = false,
    this.themeMode = 'default',
    this.themeSelection = THEME_SYSTEM, // 默认跟随系统
    this.defaultNoteVisibility = VISIBILITY_PRIVATE, // 默认私有
    this.fontScale = FONT_SCALE_NORMAL, // 默认标准字体
    this.fontFamily = FONT_FAMILY_DEFAULT, // 默认字体家族
    this.locale = LOCALE_SYSTEM, // 默认跟随系统
    this.aiApiUrl,
    this.aiApiKey,
    this.aiModel = AI_MODEL_DEEPSEEK, // 默认使用DeepSeek
    this.aiEnabled = false, // 默认不启用AI
    this.autoShowEditorOnLaunch = false, // 默认不自动弹出编辑框
    this.useCustomPrompt = false, // 默认不使用自定义Prompt
    this.customInsightPrompt, // 自定义笔记洞察Prompt（首页AI洞察）
    this.customReviewPrompt, // 自定义点评Prompt
    this.customContinuationPrompt, // 自定义续写Prompt
    this.customTagInsightPrompt, // 自定义标签洞察Prompt（标签详情页洞察）
    this.customTagRecommendationPrompt, // 自定义标签推荐Prompt
    SidebarConfig? sidebarConfig,
  }) : sidebarConfig = sidebarConfig ?? SidebarConfig();

  // 🔧 修复 API Key 编码问题（UTF-16BE -> ASCII）
  static String? _fixApiKeyEncoding(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return apiKey;
    
    // 检查是否包含非 ASCII 字符（可能是编码错误）
    if (apiKey.runes.any((rune) => rune > 127)) {
      try {
        // 尝试修复 UTF-16BE 编码错误
        // 如果字符的 Unicode 码点在 0xXX00 范围内，提取高字节
        final fixed = apiKey.runes
            .map((r) => (r & 0xFF00) != 0 && (r & 0xFF) == 0
                ? String.fromCharCode((r >> 8) & 0xFF)
                : String.fromCharCode(r))
            .join();
        
        // 验证修复后的结果是否为纯 ASCII
        if (fixed.runes.every((r) => r <= 127) && fixed.isNotEmpty) {
          print('🔧 自动修复 API Key 编码问题: ${apiKey.substring(0, 10)}... -> ${fixed.substring(0, 10)}...');
          return fixed;
        }
      } catch (e) {
        print('⚠️ API Key 编码修复失败: $e');
      }
    }
    
    return apiKey;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        isLocalMode: json['isLocalMode'] ?? false,
        memosApiUrl: json['memosApiUrl'],
        lastToken: json['lastToken'],
        lastUsername: json['lastUsername'],
        lastServerUrl: json['lastServerUrl'],
        rememberLogin: json['rememberLogin'] ?? false,
        autoLogin: json['autoLogin'] ?? false,
        autoSyncEnabled: json['autoSyncEnabled'] ?? false,
        syncInterval: json['syncInterval'] ?? 300,
        isDarkMode: json['isDarkMode'] ?? false,
        themeMode: json['themeMode'] ?? 'default',
        themeSelection: json['themeSelection'] ?? THEME_SYSTEM,
        defaultNoteVisibility:
            json['defaultNoteVisibility'] ?? VISIBILITY_PRIVATE,
        fontScale: json['fontScale'] ?? FONT_SCALE_NORMAL,
        fontFamily: json['fontFamily'] ?? FONT_FAMILY_DEFAULT,
        locale: json['locale'], // null表示跟随系统
        aiApiUrl: json['aiApiUrl'],
        aiApiKey: _fixApiKeyEncoding(json['aiApiKey']), // 🔧 自动修复编码
        aiModel: json['aiModel'] ?? AI_MODEL_DEEPSEEK,
        aiEnabled: json['aiEnabled'] ?? false,
        autoShowEditorOnLaunch: json['autoShowEditorOnLaunch'] ?? false,
        useCustomPrompt: json['useCustomPrompt'] ?? false,
        customInsightPrompt: json['customInsightPrompt'],
        customReviewPrompt: json['customReviewPrompt'],
        customContinuationPrompt: json['customContinuationPrompt'],
        customTagInsightPrompt: json['customTagInsightPrompt'],
        customTagRecommendationPrompt: json['customTagRecommendationPrompt'],
        sidebarConfig: json['sidebarConfig'] != null
            ? SidebarConfig.fromJson(json['sidebarConfig'])
            : null,
      );
  final bool isLocalMode;
  final String? memosApiUrl;
  final String? lastToken;
  final String? lastUsername;
  final String? lastServerUrl;
  final bool rememberLogin;
  final bool autoLogin;
  final bool autoSyncEnabled;
  final int syncInterval;
  final bool isDarkMode; // 保留此字段以兼容旧版本
  final String themeMode; // 主题模式：default(默认), fenglan(凤蓝)
  final String themeSelection; // 主题选择：system(跟随系统)、light(纸白)、dark(幽谷)
  final String defaultNoteVisibility; // 新建笔记的默认可见性
  final double fontScale; // 字体缩放倍数：0.85(小), 1.0(标准), 1.15(大), 1.3(特大)
  final String
      fontFamily; // 字体家族：default(默认), noto-sans(思源黑体), noto-serif(思源宋体), ma-shan-zheng(楷体风格), zcool-xiaowei(站酷小薇)
  final String? locale; // 语言选择：null(跟随系统), zh_CN(简体中文), en_US(English)
  final bool autoShowEditorOnLaunch; // 启动时自动弹出编辑框

  // AI配置
  final String? aiApiUrl; // AI API地址
  final String? aiApiKey; // AI API密钥
  final String aiModel; // AI模型：deepseek-chat, gpt-3.5-turbo等
  final bool aiEnabled; // 是否启用AI功能

  // AI自定义Prompt配置
  final bool useCustomPrompt; // 是否使用自定义Prompt
  final String? customInsightPrompt; // 自定义笔记洞察Prompt（用于：首页AI洞察）
  final String? customReviewPrompt; // 自定义点评Prompt（用于：笔记详情页AI智能点评）
  final String? customContinuationPrompt; // 自定义续写Prompt（用于：笔记编辑器AI续写）
  final String? customTagInsightPrompt; // 自定义标签洞察Prompt（用于：标签详情页洞察分析）
  final String? customTagRecommendationPrompt; // 自定义标签推荐Prompt（用于：标签智能推荐）

  // 侧边栏配置
  final SidebarConfig sidebarConfig; // 侧边栏自定义配置

  static const String THEME_SYSTEM = 'system';
  static const String THEME_LIGHT = 'light';
  static const String THEME_DARK = 'dark';

  // 笔记可见性选项
  static const String VISIBILITY_PRIVATE = 'PRIVATE';
  static const String VISIBILITY_PUBLIC = 'PUBLIC';

  // 字体大小选项（参考微信/支付宝标准）
  static const double FONT_SCALE_MINI = 0.8; // 极小：15*0.8=12pt
  static const double FONT_SCALE_SMALL = 0.9; // 小：15*0.9=13.5pt（调整为更接近微信）
  static const double FONT_SCALE_NORMAL = 1; // 标准：15pt
  static const double FONT_SCALE_LARGE = 1.15; // 大：15*1.15=17.25pt
  static const double FONT_SCALE_XLARGE = 1.3; // 特大：15*1.3=19.5pt

  // 字体家族选项
  static const String FONT_FAMILY_DEFAULT = 'default';
  static const String FONT_FAMILY_NOTO_SANS = 'noto-sans'; // 思源黑体
  static const String FONT_FAMILY_NOTO_SERIF = 'noto-serif'; // 思源宋体
  static const String FONT_FAMILY_MA_SHAN_ZHENG = 'ma-shan-zheng'; // 楷体风格
  static const String FONT_FAMILY_ZCOOL_XIAOWEI = 'zcool-xiaowei'; // 站酷小薇
  static const String FONT_FAMILY_ZCOOL_QINGKE = 'zcool-qingke'; // 站酷庆科黄油体

  // 语言选项 (23种语言，覆盖全球主要市场)
  static const String? LOCALE_SYSTEM = null; // 跟随系统
  static const String LOCALE_ZH_CN = 'zh_CN'; // 简体中文
  static const String LOCALE_ZH_TW = 'zh_TW'; // 繁体中文（台湾）
  static const String LOCALE_ZH_HK = 'zh_HK'; // 繁体中文（香港）
  static const String LOCALE_EN_US = 'en_US'; // English (US)
  static const String LOCALE_EN_GB = 'en_GB'; // English (UK)
  static const String LOCALE_JA_JP = 'ja_JP'; // 日本語
  static const String LOCALE_KO_KR = 'ko_KR'; // 한국어
  static const String LOCALE_FR_FR = 'fr_FR'; // Français
  static const String LOCALE_DE_DE = 'de_DE'; // Deutsch
  static const String LOCALE_ES_ES = 'es_ES'; // Español
  static const String LOCALE_PT_PT = 'pt_PT'; // Português (PT)
  static const String LOCALE_PT_BR = 'pt_BR'; // Português (BR)
  static const String LOCALE_IT_IT = 'it_IT'; // Italiano
  static const String LOCALE_RU_RU = 'ru_RU'; // Русский
  static const String LOCALE_AR_SA = 'ar_SA'; // العربية
  static const String LOCALE_TH_TH = 'th_TH'; // ไทย
  static const String LOCALE_VI_VN = 'vi_VN'; // Tiếng Việt
  static const String LOCALE_ID_ID = 'id_ID'; // Bahasa Indonesia
  static const String LOCALE_MS_MY = 'ms_MY'; // Bahasa Melayu
  static const String LOCALE_TR_TR = 'tr_TR'; // Türkçe
  static const String LOCALE_PL_PL = 'pl_PL'; // Polski
  static const String LOCALE_NL_NL = 'nl_NL'; // Nederlands
  static const String LOCALE_HI_IN = 'hi_IN'; // हिन्दी

  // AI模型选项（2025年最新版本，仅保留兼容OpenAI格式的模型）
  // DeepSeek 系列（2025）
  static const String AI_MODEL_DEEPSEEK = 'deepseek-chat'; // V3版本
  static const String AI_MODEL_DEEPSEEK_REASONER = 'deepseek-reasoner';
  
  // OpenAI 系列（2025）
  static const String AI_MODEL_O1 = 'o1'; // 推理模型
  static const String AI_MODEL_O1_MINI = 'o1-mini'; // 轻量推理
  static const String AI_MODEL_O3_MINI = 'o3-mini'; // 最新推理
  static const String AI_MODEL_GPT4O = 'gpt-4o'; // 多模态旗舰
  static const String AI_MODEL_GPT4O_MINI = 'gpt-4o-mini';
  
  // 通义千问系列（2025）
  static const String AI_MODEL_QWEN_MAX = 'qwen-max'; // 旗舰版
  static const String AI_MODEL_QWEN_PLUS = 'qwen-plus';
  static const String AI_MODEL_QWEN_TURBO = 'qwen-turbo';
  
  // 智谱 GLM 系列（2025）
  static const String AI_MODEL_GLM_4_FLASH = 'glm-4-flash';
  static const String AI_MODEL_GLM_4_PLUS = 'glm-4-plus';
  static const String AI_MODEL_GLM_4_AIR = 'glm-4-air';
  
  // Moonshot（Kimi）系列
  static const String AI_MODEL_MOONSHOT = 'moonshot-v1-128k'; // 升级到128k

  // 官方API地址（兼容OpenAI格式）
  static const String DEEPSEEK_API_URL = 'https://api.deepseek.com/v1';
  static const String OPENAI_API_URL = 'https://api.openai.com/v1';
  static const String QWEN_API_URL = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
  static const String MOONSHOT_API_URL = 'https://api.moonshot.cn/v1';
  static const String ZHIPU_API_URL = 'https://open.bigmodel.cn/api/paas/v4/';

  AppConfig copyWith({
    bool? isLocalMode,
    String? memosApiUrl,
    String? lastToken,
    String? lastUsername,
    String? lastServerUrl,
    bool? rememberLogin,
    bool? autoLogin,
    bool? autoSyncEnabled,
    int? syncInterval,
    bool? isDarkMode,
    String? themeMode,
    String? themeSelection,
    String? defaultNoteVisibility,
    double? fontScale,
    String? fontFamily,
    String? locale,
    bool updateLocale = false, // 标记是否要更新locale（因为locale可能是null）
    String? aiApiUrl,
    String? aiApiKey,
    String? aiModel,
    bool? aiEnabled,
    bool? autoShowEditorOnLaunch,
    bool? useCustomPrompt,
    String? customInsightPrompt,
    String? customReviewPrompt,
    String? customContinuationPrompt,
    String? customTagInsightPrompt,
    String? customTagRecommendationPrompt,
    SidebarConfig? sidebarConfig,
  }) =>
      AppConfig(
        isLocalMode: isLocalMode ?? this.isLocalMode,
        memosApiUrl: memosApiUrl ?? this.memosApiUrl,
        lastToken: lastToken ?? this.lastToken,
        lastUsername: lastUsername ?? this.lastUsername,
        lastServerUrl: lastServerUrl ?? this.lastServerUrl,
        rememberLogin: rememberLogin ?? this.rememberLogin,
        autoLogin: autoLogin ?? this.autoLogin,
        autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
        syncInterval: syncInterval ?? this.syncInterval,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        themeMode: themeMode ?? this.themeMode,
        themeSelection: themeSelection ?? this.themeSelection,
        defaultNoteVisibility:
            defaultNoteVisibility ?? this.defaultNoteVisibility,
        fontScale: fontScale ?? this.fontScale,
        fontFamily: fontFamily ?? this.fontFamily,
        locale: updateLocale
            ? locale
            : (locale ??
                this.locale), // 如果updateLocale为true，则使用传入的locale（可能是null）
        aiApiUrl: aiApiUrl ?? this.aiApiUrl,
        aiApiKey: aiApiKey ?? this.aiApiKey,
        aiModel: aiModel ?? this.aiModel,
        aiEnabled: aiEnabled ?? this.aiEnabled,
        autoShowEditorOnLaunch:
            autoShowEditorOnLaunch ?? this.autoShowEditorOnLaunch,
        useCustomPrompt: useCustomPrompt ?? this.useCustomPrompt,
        customInsightPrompt: customInsightPrompt ?? this.customInsightPrompt,
        customReviewPrompt: customReviewPrompt ?? this.customReviewPrompt,
        customContinuationPrompt: customContinuationPrompt ?? this.customContinuationPrompt,
        customTagInsightPrompt: customTagInsightPrompt ?? this.customTagInsightPrompt,
        customTagRecommendationPrompt: customTagRecommendationPrompt ?? this.customTagRecommendationPrompt,
        sidebarConfig: sidebarConfig ?? this.sidebarConfig,
      );

  Map<String, dynamic> toJson() => {
        'isLocalMode': isLocalMode,
        'memosApiUrl': memosApiUrl,
        'lastToken': lastToken,
        'lastUsername': lastUsername,
        'lastServerUrl': lastServerUrl,
        'rememberLogin': rememberLogin,
        'autoLogin': autoLogin,
        'autoSyncEnabled': autoSyncEnabled,
        'syncInterval': syncInterval,
        'isDarkMode': isDarkMode,
        'themeMode': themeMode,
        'themeSelection': themeSelection,
        'defaultNoteVisibility': defaultNoteVisibility,
        'fontScale': fontScale,
        'fontFamily': fontFamily,
        'locale': locale,
        'aiApiUrl': aiApiUrl,
        'aiApiKey': aiApiKey,
        'aiModel': aiModel,
        'aiEnabled': aiEnabled,
        'autoShowEditorOnLaunch': autoShowEditorOnLaunch,
        'useCustomPrompt': useCustomPrompt,
        'customInsightPrompt': customInsightPrompt,
        'customReviewPrompt': customReviewPrompt,
        'customContinuationPrompt': customContinuationPrompt,
        'customTagInsightPrompt': customTagInsightPrompt,
        'customTagRecommendationPrompt': customTagRecommendationPrompt,
        'sidebarConfig': sidebarConfig.toJson(),
      };
}
