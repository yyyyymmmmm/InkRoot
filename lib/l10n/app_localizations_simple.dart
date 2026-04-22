import 'package:flutter/material.dart';
import 'package:inkroot/l10n/translations.dart';

/// 简单的应用国际化类 - 支持23种语言
class AppLocalizationsSimple {
  AppLocalizationsSimple(this.locale);
  final Locale locale;

  static AppLocalizationsSimple? of(BuildContext context) =>
      Localizations.of<AppLocalizationsSimple>(
        context,
        AppLocalizationsSimple,
      );

  static const LocalizationsDelegate<AppLocalizationsSimple> delegate =
      _AppLocalizationsDelegate();

  /// 统一的翻译获取方法
  String _t(String key, {String? fallback}) =>
      Translations.get(key, locale.languageCode, fallback: fallback);

  // ===== 应用基础 =====
  String get appTitle => _t('appTitle', fallback: '墨鸣笔记');
  String get preferences => _t('preferences', fallback: '偏好设置');
  String get appearance => _t('appearance', fallback: '外观');
  String get themeSelection => _t('theme', fallback: '主题选择');
  String get fontSize => _t('fontSize', fallback: '字体大小');
  String get selectFontSize => _t('selectFontSize', fallback: '选择字体大小');
  String get fontFamily => locale.languageCode == 'zh' ? '字体选择' : 'Font';
  String get language => _t('language', fallback: '语言选择');
  String get sync => _t('sync', fallback: '同步');
  String get privacy => _t('privacy', fallback: '隐私');
  String get help => _t('help', fallback: '帮助');
  String get about => _t('about', fallback: '关于');
  String get forgotPassword => _t('forgotPassword', fallback: '忘记密码');
  String get serverUrl => _t('serverUrl', fallback: '服务器地址');
  String get login => _t('login', fallback: '登录');
  String get username => _t('username', fallback: '用户名');
  String get password => _t('password', fallback: '密码');
  String get settings => _t('settings', fallback: '设置');
  String get accountInfo => _t('accountInfo', fallback: '账户信息');
  String get importExport => _t('importExport', fallback: '导入导出');
  String get dataCleanup => _t('dataCleanup', fallback: '数据清理');
  String get laboratory => _t('laboratory', fallback: '实验室');
  String get randomReview => _t('randomReview', fallback: '随机回顾');
  String get faq => _t('faq', fallback: '常见问题');
  String get fontSelection => _t('fontSelection', fallback: '字体选择');
  String get noteVisibility => _t('noteVisibility', fallback: '笔记状态');
  String get private => _t('private', fallback: '私有');
  String get public => _t('public', fallback: '公开');
  String get register => _t('register', fallback: '注册');
  String get confirmPassword => _t('confirmPassword', fallback: '确认密码');
  String get email => _t('email', fallback: '邮箱');
  String get save => _t('save', fallback: '保存');
  String get cancel => _t('cancel', fallback: '取消');
  String get delete => _t('delete', fallback: '删除');
  String get edit => _t('edit', fallback: '编辑');
  String get confirm => _t('confirm', fallback: '确认');
  String get submit => _t('submit', fallback: '提交');
  String get logout => _t('logout', fallback: '退出登录');
  String get export => _t('export', fallback: '导出');
  String get import => _t('import', fallback: '导入');
  String get nickname => _t('nickname', fallback: '昵称');
  String get bio => _t('bio', fallback: '简介');
  String get changePassword => _t('changePassword', fallback: '修改密码');
  String get oldPassword => _t('oldPassword', fallback: '旧密码');
  String get newPassword => _t('newPassword', fallback: '新密码');
  String get notLoggedIn => _t('notLoggedIn', fallback: '未登录');
  String get serverConnection => _t('serverConnection', fallback: '服务器连接');
  String get connectionStatus => _t('connectionStatus', fallback: '连接状态');
  String get connected => _t('connected', fallback: '已连接');
  String get disconnected => _t('disconnected', fallback: '未连接');
  String get diagnosing => _t('diagnosing', fallback: '诊断中...');
  String get connectionDiagnosis => _t('connectionDiagnosis', fallback: '连接诊断');
  String get connectionSettings => _t('connectionSettings', fallback: '连接设置');
  String get connectionLog => _t('connectionLog', fallback: '连接日志');
  String get saveChanges => _t('saveChanges', fallback: '保存更改');
  String get success => _t('success', fallback: '成功');
  String get failed => _t('failed', fallback: '失败');
  String get updateSuccess => _t('updateSuccess', fallback: '更新成功');
  String get updateFailed => _t('updateFailed', fallback: '更新失败');
  String get syncSuccess => _t('syncSuccess', fallback: '同步成功');

  String get themeSystem => locale.languageCode == 'zh' ? '跟随系统' : 'System';
  String get themeLight => locale.languageCode == 'zh' ? '纸白' : 'Light';
  String get themeDark => locale.languageCode == 'zh' ? '幽谷' : 'Dark';
  String get themeSystemDesc =>
      locale.languageCode == 'zh' ? '跟随系统设置' : 'Follow system settings';
  String get themeLightDesc =>
      locale.languageCode == 'zh' ? '浅色主题' : 'Light theme';
  String get themeDarkDesc =>
      locale.languageCode == 'zh' ? '深色主题' : 'Dark theme';

  String get fontSizeMini => locale.languageCode == 'zh' ? '极小' : 'Mini';
  String get fontSizeSmall => locale.languageCode == 'zh' ? '小' : 'Small';
  String get fontSizeNormal => locale.languageCode == 'zh' ? '标准' : 'Normal';
  String get fontSizeLarge => locale.languageCode == 'zh' ? '大' : 'Large';
  String get fontSizeXLarge =>
      locale.languageCode == 'zh' ? '特大' : 'Extra Large';
  String get fontSizeMiniDesc => locale.languageCode == 'zh'
      ? '最小字体，节省空间'
      : 'Minimum font size, space-saving';
  String get fontSizeSmallDesc => locale.languageCode == 'zh'
      ? '适合阅读大量文字'
      : 'Suitable for reading large amounts of text';
  String get fontSizeNormalDesc =>
      locale.languageCode == 'zh' ? '默认字体大小' : 'Default font size';
  String get fontSizeLargeDesc =>
      locale.languageCode == 'zh' ? '更易于阅读' : 'Easier to read';
  String get fontSizeXLargeDesc =>
      locale.languageCode == 'zh' ? '最大字体' : 'Maximum font size';

  String get autoSync => locale.languageCode == 'zh' ? '自动同步' : 'Auto Sync';
  String get autoSyncDesc => locale.languageCode == 'zh'
      ? '定期自动同步笔记'
      : 'Automatically sync notes periodically';
  String get syncInterval =>
      locale.languageCode == 'zh' ? '同步间隔' : 'Sync Interval';

  String get defaultNoteVisibility =>
      locale.languageCode == 'zh' ? '默认笔记状态' : 'Default Note Visibility';
  String get visibilityPrivate =>
      locale.languageCode == 'zh' ? '私有' : 'Private';
  String get visibilityPublic => locale.languageCode == 'zh' ? '公开' : 'Public';
  String get visibilityPrivateDesc =>
      locale.languageCode == 'zh' ? '仅自己可见' : 'Only visible to you';
  String get visibilityPublicDesc =>
      locale.languageCode == 'zh' ? '所有人可见' : 'Visible to everyone';

  String get rememberPassword =>
      locale.languageCode == 'zh' ? '记住密码' : 'Remember Password';
  String get rememberPasswordDesc => locale.languageCode == 'zh'
      ? '保存账号和密码到本地'
      : 'Save account and password locally';
  String get autoLogin => locale.languageCode == 'zh' ? '自动登录' : 'Auto Login';
  String get autoLoginDesc => locale.languageCode == 'zh'
      ? '启动应用时跳过登录页面直接进入'
      : 'Skip login page when starting the app';

  String get autoShowEditor =>
      locale.languageCode == 'zh' ? '启动自动弹出编辑框' : 'Auto Show Editor on Launch';
  String get autoShowEditorDesc => locale.languageCode == 'zh'
      ? '打开应用时自动弹出笔记编辑框，快速记录灵感'
      : 'Automatically open note editor when app starts, quickly capture inspiration';
  String get autoShowEditorEnabled => locale.languageCode == 'zh'
      ? '已开启启动自动弹出编辑框'
      : 'Auto show editor on launch enabled';
  String get autoShowEditorDisabled => locale.languageCode == 'zh'
      ? '已关闭启动自动弹出编辑框'
      : 'Auto show editor on launch disabled';

  String get selectDefaultNoteVisibility => locale.languageCode == 'zh'
      ? '选择默认笔记状态'
      : 'Select Default Note Visibility';

  String minutesFormat(int minutes) =>
      locale.languageCode == 'zh' ? '$minutes分钟' : '$minutes minutes';

  // ===== 语言名称 (23种语言) =====
  String get languageSystem => _t('languageSystem', fallback: '跟随系统');
  String get languageChineseSimplified =>
      _t('languageChineseSimplified', fallback: '简体中文');
  String get languageChineseTraditionalTW =>
      _t('languageChineseTraditionalTW', fallback: '繁体中文（台湾）');
  String get languageChineseTraditionalHK =>
      _t('languageChineseTraditionalHK', fallback: '繁体中文（香港）');
  String get languageEnglish => _t('languageEnglish', fallback: 'English');
  String get languageJapanese => _t('languageJapanese', fallback: '日本語');
  String get languageKorean => _t('languageKorean', fallback: '한국어');
  String get languageFrench => _t('languageFrench', fallback: 'Français');
  String get languageGerman => _t('languageGerman', fallback: 'Deutsch');
  String get languageSpanish => _t('languageSpanish', fallback: 'Español');
  String get languagePortuguesePT =>
      _t('languagePortuguesePT', fallback: 'Português (PT)');
  String get languagePortugueseBR =>
      _t('languagePortugueseBR', fallback: 'Português (BR)');
  String get languageItalian => _t('languageItalian', fallback: 'Italiano');
  String get languageRussian => _t('languageRussian', fallback: 'Русский');
  String get languageArabic => _t('languageArabic', fallback: 'العربية');
  String get languageThai => _t('languageThai', fallback: 'ไทย');
  String get languageVietnamese =>
      _t('languageVietnamese', fallback: 'Tiếng Việt');
  String get languageIndonesian =>
      _t('languageIndonesian', fallback: 'Bahasa Indonesia');
  String get languageMalay => _t('languageMalay', fallback: 'Bahasa Melayu');
  String get languageTurkish => _t('languageTurkish', fallback: 'Türkçe');
  String get languagePolish => _t('languagePolish', fallback: 'Polski');
  String get languageDutch => _t('languageDutch', fallback: 'Nederlands');
  String get languageHindi => _t('languageHindi', fallback: 'हिन्दी');

  String get selectTheme => _t('selectTheme', fallback: '选择主题');
  String get selectFont => _t('selectFont', fallback: '选择字体');
  String get selectNoteVisibility =>
      _t('selectNoteVisibility', fallback: '选择笔记状态');
  String get selectLanguage =>
      locale.languageCode == 'zh' ? '选择语言' : 'Select Language';

  String get privateDesc => _t('privateDesc', fallback: '仅自己可见');
  String get publicDesc => _t('publicDesc', fallback: '所有人可见');

  String get fontFamilyDefault =>
      _t('fontFamilyDefault', fallback: 'SF Pro Display');
  String get fontFamilyNotoSans => _t('fontFamilyNotoSans', fallback: '思源黑体');
  String get fontFamilyNotoSerif => _t('fontFamilyNotoSerif', fallback: '思源宋体');
  String get fontFamilyMaShanZheng =>
      _t('fontFamilyMaShanZheng', fallback: '楷体风格');
  String get fontFamilyZcoolXiaowei =>
      _t('fontFamilyZcoolXiaowei', fallback: '站酷小薇');
  String get fontFamilyZcoolQingke =>
      _t('fontFamilyZcoolQingke', fallback: '站酷庆科');

  String get fontFamilyDefaultDesc =>
      _t('fontFamilyDefaultDesc', fallback: '系统默认，清晰现代');
  String get fontFamilyNotoSansDesc =>
      _t('fontFamilyNotoSansDesc', fallback: 'Noto Sans SC，现代简洁');
  String get fontFamilyNotoSerifDesc =>
      _t('fontFamilyNotoSerifDesc', fallback: 'Noto Serif SC，优雅复古');
  String get fontFamilyMaShanZhengDesc =>
      _t('fontFamilyMaShanZhengDesc', fallback: 'Ma Shan Zheng，手写风格');
  String get fontFamilyZcoolXiaoweiDesc =>
      _t('fontFamilyZcoolXiaoweiDesc', fallback: 'Zcool XiaoWei，圆润可爱');
  String get fontFamilyZcoolQingkeDesc =>
      _t('fontFamilyZcoolQingkeDesc', fallback: 'Zcool QingKe HuangYou，活泼俏皮');

  String languageChanged(String language) => locale.languageCode == 'zh'
      ? '语言已切换为$language'
      : 'Language changed to $language';
  
  String fontChanged(String fontName) => locale.languageCode == 'zh'
      ? '字体已切换为$fontName'
      : 'Font changed to $fontName';

  // ===== 主页和通用 =====
  String get home => locale.languageCode == 'zh' ? '首页' : 'Home';
  String get notes => locale.languageCode == 'zh' ? '笔记' : 'Notes';
  String get search => locale.languageCode == 'zh' ? '搜索' : 'Search';
  String get add => locale.languageCode == 'zh' ? '添加' : 'Add';
  String get back => locale.languageCode == 'zh' ? '返回' : 'Back';
  String get done => locale.languageCode == 'zh' ? '完成' : 'Done';
  String get close => locale.languageCode == 'zh' ? '关闭' : 'Close';

  // ===== 侧边栏 =====
  String get allNotes => _t('allNotes', fallback: '全部笔记');
  String get allTags => _t('allTags', fallback: '全部标签');
  String get account => _t('account', fallback: '账号');
  String get tags => _t('tags', fallback: '标签');
  String get notifications =>
      locale.languageCode == 'zh' ? '通知' : 'Notifications';
  String get knowledgeGraph =>
      locale.languageCode == 'zh' ? '知识图谱' : 'Knowledge Graph';

  // ===== 笔记相关 =====
  String get createNote => locale.languageCode == 'zh' ? '新建笔记' : 'Create Note';
  String get editNote => locale.languageCode == 'zh' ? '编辑笔记' : 'Edit Note';
  String get deleteNote => locale.languageCode == 'zh' ? '删除笔记' : 'Delete Note';
  String get pinNote => locale.languageCode == 'zh' ? '置顶笔记' : 'Pin Note';
  String get unpinNote => locale.languageCode == 'zh' ? '取消置顶' : 'Unpin Note';
  String get pinned => _t('pinned', fallback: '已置顶');
  String get unpinned => _t('unpinned', fallback: '已取消置顶');
  String get shareNote => locale.languageCode == 'zh' ? '分享笔记' : 'Share Note';
  String get copyNote => locale.languageCode == 'zh' ? '复制笔记' : 'Copy Note';
  String get noteContent =>
      locale.languageCode == 'zh' ? '笔记内容' : 'Note Content';
  String get emptyNote => locale.languageCode == 'zh' ? '暂无笔记' : 'No notes yet';
  String get searchNotes =>
      locale.languageCode == 'zh' ? '搜索笔记' : 'Search notes';

  // ===== 排序 =====
  String get sortBy => locale.languageCode == 'zh' ? '排序方式' : 'Sort By';
  String get sortNewest => locale.languageCode == 'zh' ? '最新创建' : 'Newest';
  String get sortOldest => locale.languageCode == 'zh' ? '最早创建' : 'Oldest';
  String get sortUpdated =>
      locale.languageCode == 'zh' ? '最近更新' : 'Recently Updated';

  // ===== 设置 =====
  String get generalSettings =>
      locale.languageCode == 'zh' ? '通用设置' : 'General Settings';
  String get accountSettings =>
      locale.languageCode == 'zh' ? '账号设置' : 'Account Settings';
  String get privacySettings =>
      locale.languageCode == 'zh' ? '隐私设置' : 'Privacy Settings';
  String get advancedSettings =>
      locale.languageCode == 'zh' ? '高级设置' : 'Advanced Settings';
  String get feedback => locale.languageCode == 'zh' ? '意见反馈' : 'Feedback';

  // ===== 同步 =====
  String get syncing => locale.languageCode == 'zh' ? '同步中...' : 'Syncing...';
  String get syncFailed => locale.languageCode == 'zh' ? '同步失败' : 'Sync failed';
  String get lastSync => locale.languageCode == 'zh' ? '上次同步' : 'Last sync';
  String get syncNow => locale.languageCode == 'zh' ? '立即同步' : 'Sync now';

  // ===== 时间 =====
  String get today => locale.languageCode == 'zh' ? '今天' : 'Today';
  String get yesterday => locale.languageCode == 'zh' ? '昨天' : 'Yesterday';
  String get thisWeek => locale.languageCode == 'zh' ? '本周' : 'This week';
  String get thisMonth => locale.languageCode == 'zh' ? '本月' : 'This month';

  // ===== 提示消息 =====
  String get loading => locale.languageCode == 'zh' ? '加载中...' : 'Loading...';
  String get noData => locale.languageCode == 'zh' ? '暂无数据' : 'No data';
  String get networkError =>
      locale.languageCode == 'zh' ? '网络错误' : 'Network error';
  String get operationSuccess =>
      locale.languageCode == 'zh' ? '操作成功' : 'Operation successful';
  String get operationFailed =>
      locale.languageCode == 'zh' ? '操作失败' : 'Operation failed';

  // ===== 删除确认 =====
  String get deleteConfirmTitle =>
      locale.languageCode == 'zh' ? '确认删除' : 'Confirm Delete';
  String get deleteConfirmMessage => locale.languageCode == 'zh'
      ? '确定要删除这条笔记吗？'
      : 'Are you sure you want to delete this note?';
  String get deleteSuccess =>
      locale.languageCode == 'zh' ? '删除成功' : 'Deleted successfully';

  // ===== 导入导出 =====
  String get exportBackup => _t('exportBackup', fallback: '导出备份');
  String get importRestore => _t('importRestore', fallback: '导入恢复');
  String get backupInfo => _t('backupInfo', fallback: '备份信息');
  String get lastBackup => _t('lastBackup', fallback: '上次备份');
  String get neverBackedUp => _t('neverBackedUp', fallback: '从未备份');
  String get backupSize => _t('backupSize', fallback: '备份大小');
  String get exportOptions => _t('exportOptions', fallback: '导出选项');
  String get exportFormat => _t('exportFormat', fallback: '导出格式');
  String get includeImages => _t('includeImages', fallback: '包含图片');
  String get includeImagesSubtitle =>
      _t('includeImagesSubtitle', fallback: '将笔记中的图片一同导出');
  String get includeTags => _t('includeTags', fallback: '包含标签');
  String get encryptBackup => _t('encryptBackup', fallback: '加密备份');
  String get encryptionOptions => _t('encryptionOptions', fallback: '加密选项');
  String get encryptionPassword => _t('encryptionPassword', fallback: '加密密码');
  String get importHistory => _t('importHistory', fallback: '导入历史');
  String get startExport => _t('startExport', fallback: '开始导出');
  String get startImport => _t('startImport', fallback: '开始导入');

  // ===== 实验室 =====
  String get releasedFeatures => _t('releasedFeatures', fallback: '已发布功能');
  String get developingFeatures => _t('developingFeatures', fallback: '开发中功能');
  String get inDevelopment => _t('inDevelopment', fallback: '开发中');
  String get experimentalNotice => _t(
        'experimentalNotice',
        fallback: '实验室功能可能不稳定，使用前请备份重要数据。我们会根据用户反馈不断改进这些功能。',
      );
  String get featureDetails => _t('featureDetails', fallback: '功能特性');
  String get exploring => _t('exploring', fallback: '探索前沿功能，体验创新特性');

  // ===== 反馈 =====
  String get feedbackType => _t('feedbackType', fallback: '反馈类型');
  String get featureSuggestion => _t('featureSuggestion', fallback: '功能建议');
  String get bugReport => _t('bugReport', fallback: '问题反馈');
  String get uiOptimization => _t('uiOptimization', fallback: '界面优化');
  String get performanceIssue => _t('performanceIssue', fallback: '性能问题');
  String get other => _t('other', fallback: '其他');
  String get contactInfo => _t('contactInfo', fallback: '联系方式');
  String get feedbackContent => _t('feedbackContent', fallback: '反馈内容');
  String get submitFeedback => _t('submitFeedback', fallback: '提交反馈');
  String get feedbackSuccess => _t('feedbackSuccess', fallback: '反馈发送成功！');

  // ===== 侧边栏扩展 =====
  String get loginButton => _t('loginButton', fallback: '登录');
  String get logoutButton => _t('logoutButton', fallback: '退出登录');
  String get logoutConfirm => _t('logoutConfirm', fallback: '确认退出');
  String get logoutMessage => _t('logoutMessage', fallback: '退出登录时如何处理本地数据？');
  String get keepLocal => _t('keepLocal', fallback: '保留本地');
  String get syncBeforeLogout => _t('syncBeforeLogout', fallback: '同步后退出');
  String get confirmLogout => _t('confirmLogout', fallback: '确定退出');
  String get logoutFailed => _t('logoutFailed', fallback: '退出登录失败');

  // ===== 随机回顾 & 知识图谱 =====
  String get updatingFailed => _t('updatingFailed', fallback: '更新失败');
  String get cannotOpenLink => _t('cannotOpenLink', fallback: '无法打开链接');
  String get linkError => _t('linkError', fallback: '链接错误');
  String get copiedToClipboard => _t('copiedToClipboard', fallback: '已复制到剪贴板');
  String get deletingNote => _t('deletingNote', fallback: '正在删除笔记...');
  String get noteDeleted => _t('noteDeleted', fallback: '笔记已删除');
  String get noteRestored => _t('noteRestored', fallback: '笔记已恢复');
  String get undo => _t('undo', fallback: '撤销');
  String get deleteFailed => _t('deleteFailed', fallback: '删除失败');
  String get showAll => _t('showAll', fallback: '显示全部');
  String get unknown => _t('unknown', fallback: '未知');

  // ===== AI设置 =====
  String get aiSettings => _t('aiSettings', fallback: 'AI 设置');
  String get aiFeatures => _t('aiFeatures', fallback: 'AI功能');
  String get apiConfiguration => _t('apiConfiguration', fallback: 'API配置');
  String get aiModel => _t('aiModel', fallback: 'AI模型');
  String get modelSelection => _t('modelSelection', fallback: '模型选择');
  String get selectModel => _t('selectModel', fallback: '选择AI模型');
  String get domesticModels => _t('domesticModels', fallback: '国产大模型');
  String get apiAddress => _t('apiAddress', fallback: 'API地址');
  String get apiKey => _t('apiKey', fallback: 'API密钥');
  String get saveConfiguration => _t('saveConfiguration', fallback: 'AI配置已保存');

  // ===== 关于 & 帮助 =====
  String get aboutUs => _t('aboutUs', fallback: '关于我们');
  String get version => _t('version', fallback: '版本');
  String get team => _t('team', fallback: '团队');
  String get contactUs => _t('contactUs', fallback: '联系我们');
  String get helpCenter => _t('helpCenter', fallback: '帮助中心');
  String get gettingStarted => _t('gettingStarted', fallback: '开始使用');
  String get quickGuide => _t('quickGuide', fallback: '快速入门指南');
  String get quickStartDescription =>
      _t('quickStartDescription', fallback: '快速了解InkRoot-墨鸣笔记的基本功能和使用方式');
  String get noteFeaturesDescription =>
      _t('noteFeaturesDescription', fallback: '全面了解InkRoot-墨鸣笔记的核心功能');
  String get noteFeatures => _t('noteFeatures', fallback: '笔记功能');
  String get tagFeatures => _t('tagFeatures', fallback: '标签功能');
  String get dataSync => _t('dataSync', fallback: '数据同步');
  String get commonQuestions => _t('commonQuestions', fallback: '常见问题');
  String get markdownSyntax => _t('markdownSyntax', fallback: 'Markdown语法');

  // ===== 标签页 =====
  String get searchTags => _t('searchTags', fallback: '搜索标签...');
  String get tagScanComplete => _t('tagScanComplete', fallback: '标签扫描完成');
  String get tagScanFailed => _t('tagScanFailed', fallback: '标签扫描失败');

  // ===== 数据清理 =====
  String get cleanupConfirm => _t('cleanupConfirm', fallback: '确认清理');
  String get cleanupAllDataMessage =>
      _t('cleanupAllDataMessage', fallback: '此操作将删除所有本地笔记数据，且不可恢复。是否继续？');
  String get cleanupImagesMessage =>
      _t('cleanupImagesMessage', fallback: '此操作将删除所有未使用的图片文件。是否继续？');
  String get cleanupHistoryMessage =>
      _t('cleanupHistoryMessage', fallback: '此操作将删除所有导入导出历史记录。是否继续？');
  String get cleanupFailed => _t('cleanupFailed', fallback: '清理失败');
  String get deleteAllHistorySubtitle =>
      _t('deleteAllHistorySubtitle', fallback: '删除所有导入导出的历史记录');
  String get dangerOperationSubtitle =>
      _t('dangerOperationSubtitle', fallback: '危险操作：删除所有本地笔记数据，此操作不可恢复');
  String get notesItem => _t('notesItem', fallback: '条笔记');
  String get imagesItem => _t('imagesItem', fallback: '张图片');
  String get notesCount => _t('notesCount', fallback: '笔记数量');
  String get databaseSize => _t('databaseSize', fallback: '数据库大小');
  String get cacheSize => _t('cacheSize', fallback: '缓存大小');
  String get imagesCount => _t('imagesCount', fallback: '图片数量');
  String get dataStatistics => _t('dataStatistics', fallback: '数据统计');
  String get refreshData => _t('refreshData', fallback: '刷新数据');
  String get cleanupOperations => _t('cleanupOperations', fallback: '清理操作');
  String get cleanCache => _t('cleanCache', fallback: '清理缓存');
  String get allNotesCleanedSuccess =>
      _t('allNotesCleanedSuccess', fallback: '所有笔记已清理');

  // ===== 主页空状态 =====
  String get noNotesYet => _t('noNotesYet', fallback: '还没有笔记');
  String get clickToCreate => _t('clickToCreate', fallback: '点击右下角的按钮开始创建');
  String get noRelationships => _t('noRelationships', fallback: '笔记之间还没有建立关联');

  // ===== 引导页 =====
  String get onboardingTitle1 => _t('onboardingTitle1', fallback: '智能笔记管理');
  String get onboardingDesc1 =>
      _t('onboardingDesc1', fallback: '轻松记录生活中的每一个灵感时刻\n让思考更有条理，让创意永不丢失');
  String get onboardingTitle2 => _t('onboardingTitle2', fallback: '标签分类系统');
  String get onboardingDesc2 =>
      _t('onboardingDesc2', fallback: '智能标签让你的笔记井然有序\n快速找到需要的内容，提升工作效率');
  String get onboardingTitle3 => _t('onboardingTitle3', fallback: '随时随地同步');
  String get onboardingDesc3 =>
      _t('onboardingDesc3', fallback: '云端同步确保数据安全\n无论在哪里都能访问你的重要笔记');
  String get onboardingTitle4 => _t('onboardingTitle4', fallback: '多平台支持');
  String get onboardingDesc4 =>
      _t('onboardingDesc4', fallback: '支持手机、平板、电脑多端协作\n让你的创作思路在任何设备上延续');
  String get getStarted => _t('getStarted', fallback: '开始使用');
  String get skip => _t('skip', fallback: '跳过');
  String get next => _t('next', fallback: '下一步');

  // ===== 侧边栏其他 =====
  String get activityLog => _t('activityLog', fallback: '活动记录');
  String get notificationCenter => _t('notificationCenter', fallback: '通知中心');
  String get activityLevel => _t('activityLevel', fallback: '活跃度');
  String get unreadNotifications => _t('unreadNotifications', fallback: '条未读');
  String unreadNotificationsCount(int count) {
    final template = _t('unreadNotificationsCount', fallback: '{count}条未读信息');
    return template.replaceAll('{count}', count.toString());
  }

  // ===== 登录注册 =====
  String get registerNow => _t('registerNow', fallback: '立即注册');
  String get localMode => _t('localMode', fallback: '本地运行');

  // ===== 通用对话框 =====
  String get featureInDevelopment =>
      _t('featureInDevelopment', fallback: '该功能正在开发中，敬请期待！\n我们会尽快为您带来更多精彩功能。');
  String get ok => _t('ok', fallback: '好的');

  // ===== 账户信息 =====
  String get localUser => _t('localUser', fallback: '本地用户');
  String get createdTime => _t('createdTime', fallback: '创建时间');
  String get createdTimeLabel => _t('createdTimeLabel', fallback: '创建时间：');
  String get nicknameNotSet => _t('nicknameNotSet', fallback: '未设置昵称');
  String get emailNotSet => _t('emailNotSet', fallback: '未设置邮箱');
  String get basicInfo => _t('basicInfo', fallback: '基本信息');
  String get modifyNickname => _t('modifyNickname', fallback: '修改昵称');
  String get modifyEmail => _t('modifyEmail', fallback: '修改邮箱');
  String get modifyPassword => _t('modifyPassword', fallback: '修改密码');
  String get syncPersonalInfo => _t('syncPersonalInfo', fallback: '立即同步');
  String get syncPersonalInfoDesc => _t('syncPersonalInfoDesc', fallback: '从服务器同步最新的个人资料');
  String get logoutDesc => _t('logoutDesc', fallback: '退出当前账号并返回登录页');
  String get notLoggedInOrAPINotInitialized =>
      _t('notLoggedInOrAPINotInitialized', fallback: '未登录或API服务未初始化');
  String get welcomeToInkRootShort => _t('welcomeToInkRootShort', fallback: '欢迎使用 InkRoot');
  String get loginToUnlockFeatures => _t('loginToUnlockFeatures', fallback: '登录后解锁更多精彩功能');
  String get cloudSyncFeature => _t('cloudSyncFeature', fallback: '云端同步');
  String get cloudSyncDesc => _t('cloudSyncDesc', fallback: '笔记实时同步，随时随地访问');
  String get aiAssistantFeature => _t('aiAssistantFeature', fallback: 'AI 助手');
  String get aiAssistantDesc => _t('aiAssistantDesc', fallback: '智能总结、扩展、改进笔记内容');
  String get remindersFeature => _t('remindersFeature', fallback: '定时提醒');
  String get remindersDesc => _t('remindersDesc', fallback: '重要事项不错过，高效管理时间');
  String get agreeToTermsAndPrivacy => _t('agreeToTermsAndPrivacy', fallback: '注册即表示同意用户协议和隐私政策');

  // ===== 服务器连接 =====
  String get connectionNormal =>
      _t('connectionNormal', fallback: '服务器连接正常，数据同步正常');
  String get notConnected => _t('notConnected', fallback: '未连接');
  String get pleaseCheckServerSettings =>
      _t('pleaseCheckServerSettings', fallback: '请检查服务器设置');
  String get host => _t('host', fallback: '主机地址');
  String get port => _t('port', fallback: '端口');
  String get latency => _t('latency', fallback: '延迟');
  String get lastSyncTime => _t('lastSyncTime', fallback: '上次同步');
  String get syncNowButton => _t('syncNowButton', fallback: '立即同步');
  String get enterServerAddress =>
      _t('enterServerAddress', fallback: '请输入服务器地址');
  String get serverAddress => _t('serverAddress', fallback: '服务器地址');
  String get portNumber => _t('portNumber', fallback: '端口号');
  String get enterPortNumber => _t('enterPortNumber', fallback: '请输入端口号');
  String get useHTTPS => _t('useHTTPS', fallback: '使用HTTPS安全连接');
  String get enterAPIKey => _t('enterAPIKey', fallback: '请输入API密钥');
  String get apiKeyPlaceholder =>
      _t('apiKeyPlaceholder', fallback: '在此粘贴您从服务器获取的API密钥');

  // ===== 意见反馈 =====
  String get yourOpinionMatters =>
      _t('yourOpinionMatters', fallback: '您的意见很重要');
  String get feedbackEncouragement =>
      _t('feedbackEncouragement', fallback: '我们致力于不断提升产品体验，您的每一个建议都会让产品更好！感谢！');
  String get quickFeedback => _t('quickFeedback', fallback: '快速反馈');
  String get nodAndImprove => _t('nodAndImprove', fallback: '轻点选择，快速吐槽');
  String get uiBeautiful => _t('uiBeautiful', fallback: '界面很漂亮，体验很棒！');
  String get moreTemplates => _t('moreTemplates', fallback: '希望增加更多笔记模板');
  String get fasterSync => _t('fasterSync', fallback: '同步速度可以更快一些');
  String get moreFormats => _t('moreFormats', fallback: '希望支持更多文件格式');
  String get problemReport => _t('problemReport', fallback: '问题反馈');
  String get feedbackTypeRequired =>
      _t('feedbackTypeRequired', fallback: '反馈类型');
  String get pleaseSelectFeedbackType =>
      _t('pleaseSelectFeedbackType', fallback: '请选择建议类型');
  String get contactMethod => _t('contactMethod', fallback: '联系方式');
  String get contactPlaceholder =>
      _t('contactPlaceholder', fallback: '请输入邮箱或其他联系方式（选填）');
  String get feedbackContentRequired =>
      _t('feedbackContentRequired', fallback: '反馈内容');
  String get feedbackContentPlaceholder => _t(
        'feedbackContentPlaceholder',
        fallback: '请详细描述您遇到的问题或建议...\n\n我们会认真对待每一条反馈，并尽快回复您。',
      );
  String get deleteAllFeedback => _t('deleteAllFeedback', fallback: '清除所有反馈记录');
  String get copyEmail => _t('copyEmail', fallback: '复制邮箱');
  String get feedbackSuccessMessage =>
      _t('feedbackSuccessMessage', fallback: '感谢您的反馈！我们会认真阅读并尽快回复您。');
  String get feedbackFailed =>
      _t('feedbackFailed', fallback: '发送失败，已为您复制反馈内容到剪贴板');
  String get feedbackCopied =>
      _t('feedbackCopied', fallback: '反馈内容已复制到剪贴板\n您可以直接发送到：');
  String get sendFeedback => _t('sendFeedback', fallback: '发送反馈');

  // ===== 导入导出 =====
  String get exportTab => _t('exportTab', fallback: '导出备份');
  String get importTab => _t('importTab', fallback: '导入历史');
  String get backupInfoTitle => _t('backupInfoTitle', fallback: '备份信息');
  String get lastBackupTime => _t('lastBackupTime', fallback: '上次备份');
  String get backupedNotes => _t('backupedNotes', fallback: '备份笔记');
  String get backupSizeLabel => _t('backupSizeLabel', fallback: '备份大小');
  String get exportOptionsTitle => _t('exportOptionsTitle', fallback: '导出选项');
  String get exportFormatLabel => _t('exportFormatLabel', fallback: '导出格式');
  String get includeImagesLabel => _t('includeImagesLabel', fallback: '包含图片');
  String get includeImagesDescription =>
      _t('includeImagesDescription', fallback: '将笔记中的图片一同导出');
  String get includeTagsLabel => _t('includeTagsLabel', fallback: '包含标签');
  String get includeTagsDescription =>
      _t('includeTagsDescription', fallback: '保留笔记的标签信息');
  String get encryptionOptionsTitle =>
      _t('encryptionOptionsTitle', fallback: '加密选项');
  String get encryptBackupLabel => _t('encryptBackupLabel', fallback: '加密备份');
  String get encryptBackupDescription =>
      _t('encryptBackupDescription', fallback: '使用密码加密您的备份文件');
  String get startExportButton => _t('startExportButton', fallback: '导出备份');
  String get startImportButton => _t('startImportButton', fallback: '导入备份');

  // ===== 服务器信息页面 =====
  String get serverInfoReadOnlyNotice => _t('serverInfoReadOnlyNotice', 
      fallback: '此页面仅用于查看服务器连接状态和同步日志\n服务器设置请在登录页面配置');
  String get connectionInfoReadOnly => _t('connectionInfoReadOnly', fallback: '连接信息（只读）');
  String get notConfigured => _t('notConfigured', fallback: '未配置');
  String get enabled => _t('enabled', fallback: '已启用');
  String get disabled => _t('disabled', fallback: '未启用');
  String get modifyServerSettingsHint => _t('modifyServerSettingsHint', 
      fallback: '要修改服务器设置，请退出登录后在登录页面配置');
  String get noLogRecords => _t('noLogRecords', fallback: '暂无日志记录');

  // ===== AI设置 =====
  String get enableAIAssistant => _t('enableAIAssistant', fallback: '启用AI助手');
  String get aiAssistantDescription =>
      _t('aiAssistantDescription', fallback: '开启后可使用AI辅助功能');
  String get apiAddressLabel => _t('apiAddressLabel', fallback: 'API地址');
  String get apiKeyLabel => _t('apiKeyLabel', fallback: 'API密钥');
  String get getAPIKey => _t('getAPIKey', fallback: '获取API密钥');
  String get modelSelectionTitle => _t('modelSelectionTitle', fallback: '模型选择');

  // ===== 数据清理补充 =====
  String get cleanCacheDescription =>
      _t('cleanCacheDescription', fallback: '缓存片段文档数据，不会影响笔记');
  String get cleanUnusedImagesDescription =>
      _t('cleanUnusedImagesDescription', fallback: '删除未关联到笔记的图片文件');
  String get resetAppSettingsDescription =>
      _t('resetAppSettingsDescription', fallback: '恢复所有设置为默认状态，不会删除笔记数据');

  // ===== 计数格式化 =====
  String notesCountFormatted(int count) => locale.languageCode == 'zh'
      ? '$count 条笔记'
      : '$count note${count == 1 ? '' : 's'}';

  String tagsCountFormatted(int count) => locale.languageCode == 'zh'
      ? '$count 个标签'
      : '$count tag${count == 1 ? '' : 's'}';

  // ===== 随机回顾 =====
  String get randomReviewTitle => _t('randomReviewTitle', fallback: '随机回顾');
  String get noNotesToReview => _t('noNotesToReview', fallback: '没有可回顾的笔记');
  String get reviewSettings => _t('reviewSettings', fallback: '回顾设置');
  String get reviewTimeRange => _t('reviewTimeRange', fallback: '回顾时间范围：');
  String get reviewNotesCount => _t('reviewNotesCount', fallback: '回顾笔记数量：');
  String get all => _t('all', fallback: '全部');
  String get days => _t('days', fallback: '天');
  String get items => _t('items', fallback: '条');
  String get characterCount => _t('characterCount', fallback: '字数统计');
  String get lastEdited => _t('lastEdited', fallback: '最后编辑');
  String get copyContent => _t('copyContent', fallback: '复制内容');
  String get itemsNote => _t('itemsNote', fallback: '条笔记');

  // ===== 反馈页面补充 =====
  String get feedbackTitle => _t('feedbackTitle', fallback: '意见反馈');
  String get feedbackWelcome =>
      _t('feedbackWelcome', fallback: '我们致力于为您提供最好的体验。您的每一个建议和反馈，都是我们前进的动力！');
  String get enterEmailOrWechat =>
      _t('enterEmailOrWechat', fallback: '请输入您的邮箱或微信号（选填）');
  String get enterFeedbackContent =>
      _t('enterFeedbackContent', fallback: '请输入您的反馈内容');
  String get sending => _t('sending', fallback: '发送中...');
  String get developerEmail => _t('developerEmail', fallback: '开发团队邮箱：');
  String get feedbackResponseTime =>
      _t('feedbackResponseTime', fallback: '我们会在 1-3 个工作日内回复您的反馈');
  String get complete => _t('complete', fallback: '完成');

  // ===== 通用计量单位 =====
  String get dayUnit => _t('dayUnit', fallback: '天');
  String get noteUnit => _t('noteUnit', fallback: '条');

  // ===== 时间相对表达 =====
  String get weeksAgo => _t('weeksAgo', fallback: '周前');
  String get monthsAgo => _t('monthsAgo', fallback: '个月前');

  // ===== 导出导入补充 =====
  String get exportSuccess => _t('exportSuccess', fallback: '导出成功');
  String get importSuccess => _t('importSuccess', fallback: '导入成功');
  String get exporting => _t('exporting', fallback: '导出中...');
  String get importing => _t('importing', fallback: '导入中...');
  String get exportComplete => _t('exportComplete', fallback: '导出完成');
  String get importComplete => _t('importComplete', fallback: '导入完成');
  String get backupFileExported =>
      _t('backupFileExported', fallback: '备份文件已成功导出');
  String get dataImported => _t('dataImported', fallback: '数据已成功导入');

  // ===== 通知页面 =====
  String get clear => _t('clear', fallback: '清除');
  String get markAllRead => _t('markAllRead', fallback: '全部已读');
  String get noNotifications => _t('noNotifications', fallback: '暂无通知');
  String get noNotificationsMessage =>
      _t('noNotificationsMessage', fallback: '您目前没有新的通知消息');
  String get earlier => _t('earlier', fallback: '更早');
  String get notificationDeleted =>
      _t('notificationDeleted', fallback: '已删除通知');
  String get refreshNotificationsFailed =>
      _t('refreshNotificationsFailed', fallback: '刷新通知失败，请检查网络连接');
  String get markedAllAsRead => _t('markedAllAsRead', fallback: '已全部标记为已读');
  String get noReadNotificationsToDelete =>
      _t('noReadNotificationsToDelete', fallback: '没有已读通知可清除');
  String get clearReadNotifications =>
      _t('clearReadNotifications', fallback: '清除已读通知');
  String get clearFailed => _t('clearFailed', fallback: '清除失败');
  String get updateNow => _t('updateNow', fallback: '立即更新');
  String get viewDetails => _t('viewDetails', fallback: '查看详情');

  // ===== 服务器连接页面 =====
  String get notSynced => _t('notSynced', fallback: '未同步');
  String get connectionAbnormal => _t('connectionAbnormal', fallback: '连接异常');
  String get timeout => _t('timeout', fallback: '超时');
  String get serverResponseError =>
      _t('serverResponseError', fallback: '服务器响应错误');
  String get notLoggedInPleaseLogin =>
      _t('notLoggedInPleaseLogin', fallback: '当前未登录，请配置服务器并登录');
  String get startingSyncData => _t('startingSyncData', fallback: '开始同步数据...');
  String get syncFailedNotLoggedIn =>
      _t('syncFailedNotLoggedIn', fallback: '同步失败: 未登录');
  String get syncFailedPleaseLogin =>
      _t('syncFailedPleaseLogin', fallback: '同步失败: 请先登录');
  String get syncingLocalDataToServer =>
      _t('syncingLocalDataToServer', fallback: '正在同步本地数据到服务器...');
  String get gettingLatestDataFromServer =>
      _t('gettingLatestDataFromServer', fallback: '正在从服务器获取最新数据...');
  String get syncSuccessMessage => _t('syncSuccessMessage', fallback: '同步成功');
  String get syncFailedMessage => _t('syncFailedMessage', fallback: '同步失败');
  String get startingConnectionDiagnosis =>
      _t('startingConnectionDiagnosis', fallback: '开始连接诊断...');
  String get serverAddressNotConfigured =>
      _t('serverAddressNotConfigured', fallback: '未配置服务器地址');
  String get diagnosisFailedNoServerAddress =>
      _t('diagnosisFailedNoServerAddress', fallback: '诊断失败: 未配置服务器地址');
  String get parsingServerAddress =>
      _t('parsingServerAddress', fallback: '解析服务器地址...');
  String get protocol => _t('protocol', fallback: '协议');
  String get parseServerAddressFailed =>
      _t('parseServerAddressFailed', fallback: '解析服务器地址失败');
  String get diagnosisFailedInvalidAddress =>
      _t('diagnosisFailedInvalidAddress', fallback: '诊断失败: 服务器地址无效');
  String get checkingDNSResolution =>
      _t('checkingDNSResolution', fallback: '检查DNS解析...');
  String get dnsResolutionFailed =>
      _t('dnsResolutionFailed', fallback: 'DNS解析失败');
  String get testingAPIConnection =>
      _t('testingAPIConnection', fallback: '测试API连接...');

  // ===== 导入导出页面补充 =====
  String get fileName => _t('fileName', fallback: '文件名');
  String get youCan => _t('youCan', fallback: '您可以：');
  String get shareBackupFile => _t('shareBackupFile', fallback: '分享备份文件');
  String get saveToDevice => _t('saveToDevice', fallback: '保存到设备');
  String get share => _t('share', fallback: '分享');
  String get shareFailed => _t('shareFailed', fallback: '分享失败: 文件不存在');
  String get successfullyImported =>
      _t('successfullyImported', fallback: '成功导入');
  String get selectExportMethod => _t('selectExportMethod', fallback: '选择导出方式');
  String get selectHowToSaveExportedFile =>
      _t('selectHowToSaveExportedFile', fallback: '请选择要如何保存导出的文件：');

  // 格式化方法
  String confirmClearReadNotifications(int count) {
    final template = _t(
      'confirmClearReadNotifications',
      fallback: '确定要清除 {count} 条已读通知吗？此操作不可恢复。',
    );
    return template.replaceAll('{count}', count.toString());
  }

  String notificationsCleared(int count) {
    final template = _t('notificationsCleared', fallback: '已清除 {count} 条通知');
    return template.replaceAll('{count}', count.toString());
  }

  String syncWarning(int hours) {
    final template = _t('syncWarning', fallback: '同步警告: 距离上次同步已超过{hours}小时');
    return template.replaceAll('{hours}', hours.toString());
  }

  String dnsResolutionSuccess(int ms) {
    final template = _t('dnsResolutionSuccess', fallback: 'DNS解析成功，耗时: {ms}ms');
    return template.replaceAll('{ms}', ms.toString());
  }

  String apiConnectionSuccess(int ms) {
    final template =
        _t('apiConnectionSuccess', fallback: 'API连接成功，响应时间: {ms}ms');
    return template.replaceAll('{ms}', ms.toString());
  }

  // ===== 帮助中心 =====
  String get quickStartGuide => _t('quickStartGuide', fallback: '快速入门指南');
  String get welcomeToInkRoot =>
      _t('welcomeToInkRoot', fallback: '欢迎使用InkRoot-墨鸣笔记');
  String get coreFeatures => _t('coreFeatures', fallback: '核心特色');
  String get minimalistDesign => _t('minimalistDesign', fallback: '极简设计');
  String get crossPlatform => _t('crossPlatform', fallback: '跨平台支持');
  String get perfectCompatibility =>
      _t('perfectCompatibility', fallback: '完美兼容');
  String get dataSecurity => _t('dataSecurity', fallback: '数据安全');
  String get markdownSupport => _t('markdownSupport', fallback: 'Markdown支持');
  String get smartTags => _t('smartTags', fallback: '智能标签');
  String get fullTextSearch => _t('fullTextSearch', fallback: '全文搜索');
  String get appArchitecture => _t('appArchitecture', fallback: '应用架构');
  String get platformSupport => _t('platformSupport', fallback: '平台支持');
  String get firstTimeUse => _t('firstTimeUse', fallback: '初次使用');
  String get downloadInstall => _t('downloadInstall', fallback: '下载安装');
  String get memosServerSetup => _t('memosServerSetup', fallback: 'Memos服务器准备');
  String get accountLogin => _t('accountLogin', fallback: '账户登录');
  String get createFirstNote => _t('createFirstNote', fallback: '创建首条笔记');

  // ===== 关于页面 =====
  String get aboutInkRoot => _t('aboutInkRoot', fallback: '关于InkRoot');
  String get appTagline =>
      _t('appTagline', fallback: '静待沉淀，蓄势鸣响。\n你的每一次落笔，都是未来生长的根源。');
  String get appIntroduction =>
      _t('appIntroduction', fallback: 'InkRoot-墨鸣笔记是一款基于Memos系统打造的极简跨平台笔记应用。');
  String get appTechDescription => _t(
        'appTechDescription',
        fallback: 'InkRoot-墨鸣笔记基于Flutter 3.32.5和Dart 3.0+构建，采用现代化的架构设计。',
      );
  String get technicalDetails =>
      _t('technicalDetails', fallback: '基于Flutter 3.32.5打造的跨平台架构。');
  String get securityCommitment =>
      _t('securityCommitment', fallback: '数据安全是我们的核心承诺。');
  String get coreFeaturesTitle => _t('coreFeaturesTitle', fallback: '核心功能');
  String get contactMessage =>
      _t('contactMessage', fallback: '我们非常重视用户的反馈和建议。');
  String get feedbackSuggestions => _t('feedbackSuggestions', fallback: '反馈建议');
  String get clickToSubmitFeedback =>
      _t('clickToSubmitFeedback', fallback: '点击提交反馈建议');
  String get officialWebsite => _t('officialWebsite', fallback: '官方网站');
  String get communicationAddress =>
      _t('communicationAddress', fallback: '交流地址');
  String get copyrightInfo => _t('copyrightInfo', fallback: '版权信息');
  String get opening => _t('opening', fallback: '正在打开');

  // ===== 功能标签 =====
  String get memosExclusiveVersion =>
      _t('memosExclusiveVersion', fallback: 'Memos 0.21.0专版');
  String get intelligentTagSystem =>
      _t('intelligentTagSystem', fallback: '智能标签系统');
  String get randomReviewFeature => _t('randomReviewFeature', fallback: '随机回顾');
  String get realtimeSync => _t('realtimeSync', fallback: '实时同步');
  String get localEncryption => _t('localEncryption', fallback: '本地加密');
  String get multiTheme => _t('multiTheme', fallback: '多主题切换');
  String get offlineUse => _t('offlineUse', fallback: '离线使用');
  String get dataExport => _t('dataExport', fallback: '数据导出');
  String get imageManagement => _t('imageManagement', fallback: '图片管理');
  String get privateDeployment => _t('privateDeployment', fallback: '私有化部署');

  // ===== 用户协议页面 =====
  String get userAgreement => _t('userAgreement', fallback: '用户协议');
  String lastUpdated(int year, int month, int day) {
    final template =
        _t('lastUpdated', fallback: '最后更新日期：{year}年{month}月{day}日');
    return template
        .replaceAll('{year}', year.toString())
        .replaceAll('{month}', month.toString())
        .replaceAll('{day}', day.toString());
  }

  String get agreementAcceptance => _t('agreementAcceptance', fallback: '协议接受');
  String welcomeMessage(String appName) {
    final template = _t(
      'welcomeMessage',
      fallback:
          '欢迎使用{appName}！通过下载、安装或使用{appName}应用程序（以下简称"应用"或"服务"），您同意受本用户协议（以下简称"协议"）的约束。如果您不同意本协议的任何条款，请不要使用我们的服务。',
    );
    return template.replaceAll('{appName}', appName);
  }

  String get importantReminder => _t('importantReminder', fallback: '重要提醒：');
  String get serviceDescription => _t('serviceDescription', fallback: '服务描述');
  String get userResponsibilities =>
      _t('userResponsibilities', fallback: '用户责任与义务');
  String userResponsibilitiesContent(String appName) {
    final template =
        _t('userResponsibilitiesContent', fallback: '使用{appName}时，您同意并承诺：');
    return template.replaceAll('{appName}', appName);
  }

  String get userContentResponsibility =>
      _t('userContentResponsibility', fallback: '您对通过应用创建、存储或传输的所有内容承担完全责任。');
  String get dataOwnership => _t('dataOwnership', fallback: '数据所有权');
  String get dataOwnershipDeclaration =>
      _t('dataOwnershipDeclaration', fallback: '重要声明：');
  String get userContentControl =>
      _t('userContentControl', fallback: '您保留对自己创建的所有内容的完整控制权。');
  String get disclaimer => _t('disclaimer', fallback: '免责声明');
  String disclaimerContent(String appName) {
    final template = _t(
      'disclaimerContent',
      fallback:
          '您理解并同意，使用{appName}的风险完全由您自己承担。在适用法律允许的最大范围内，我们不承担任何直接、间接、偶然、特殊或后果性损害的责任，包括但不限于数据丢失、业务中断、利润损失等。',
    );
    return template.replaceAll('{appName}', appName);
  }

  String get intellectualProperty =>
      _t('intellectualProperty', fallback: '知识产权');
  String openSourceRights(String appName) {
    final template =
        _t('openSourceRights', fallback: '作为开源软件，{appName}在MIT许可证下发布，您享有以下权利：');
    return template.replaceAll('{appName}', appName);
  }

  String get openSourceObligations =>
      _t('openSourceObligations', fallback: '使用本软件时，您必须：');
  String get userContentOwnership => _t(
        'userContentOwnership',
        fallback: '您对自己创建的笔记内容拥有完整的知识产权，我们不声明对您的内容拥有任何权利。',
      );
  String get serviceChangesTermination =>
      _t('serviceChangesTermination', fallback: '服务变更与终止');
  String get serviceModificationRights =>
      _t('serviceModificationRights', fallback: '我们保留随时修改、更新或改进服务的权利，可能包括：');
  String get majorChangeNotifications =>
      _t('majorChangeNotifications', fallback: '重大变更将通过以下方式通知用户：');
  String get serviceSuspensionConditions =>
      _t('serviceSuspensionConditions', fallback: '在以下情况下，我们可能暂停或终止服务：');
  String get terminationNotice =>
      _t('terminationNotice', fallback: '终止前我们将尽合理努力提前通知用户。');
  String get agreementModifications =>
      _t('agreementModifications', fallback: '协议修改');
  String get agreementUpdatePolicy => _t(
        'agreementUpdatePolicy',
        fallback:
            '我们可能会不时更新本用户协议。重大变更会在应用中显著展示，并要求您重新同意。\n\n继续使用应用即表示您接受修改后的协议。如果您不同意修改后的条款，应停止使用应用并可卸载软件。',
      );
  String get termination => _t('termination', fallback: '终止');
  String get userTerminationRights => _t(
        'userTerminationRights',
        fallback: '您可以随时停止使用InkRoot并删除应用。\n\n我们也可能在以下情况下终止您的访问权限：',
      );
  String get postTerminationObligations =>
      _t('postTerminationObligations', fallback: '终止后，您应停止使用应用并删除所有副本。');
  String get disputeResolution => _t('disputeResolution', fallback: '争议解决');
  String disputeNegotiation(String email) {
    final template = _t(
      'disputeNegotiation',
      fallback:
          '因本协议产生的任何争议，双方应首先通过友好协商解决。协商时应本着诚实守信、互相尊重的原则。\n\n如协商无法解决争议，任何一方可向有管辖权的人民法院提起诉讼。诉讼过程中，本协议的其他条款仍应继续履行。\n\n争议协商请联系：{email}',
    );
    return template.replaceAll('{email}', email);
  }

  String get otherTerms => _t('otherTerms', fallback: '其他条款');
  String get entireAgreement => _t(
        'entireAgreement',
        fallback:
            '本协议构成双方就本服务达成的完整协议，取代之前的所有口头或书面协议。\n\n如本协议的任何条款被认定为无效或不可执行，其余条款仍然有效。\n\n本协议自您接受之日起生效，对之前的使用行为具有追溯效力。\n\n本协议以中文为准。如有其他语言版本，仅供参考，以中文版本为准。',
      );
  String get governingLaw => _t('governingLaw', fallback: '适用法律与管辖');
  String lawJurisdiction(String address) {
    final template = _t(
      'lawJurisdiction',
      fallback:
          '本协议的签订、效力、解释、履行和争议解决均适用中华人民共和国法律法规，不考虑法律冲突原则。\n\n因本协议引起的争议，由{address}所在地有管辖权的人民法院管辖。\n\n本协议在法律允许的范围内对双方具有约束力。如本协议与法律法规相冲突，以法律法规为准。',
    );
    return template.replaceAll('{address}', address);
  }

  String get contactUsAgreement => _t('contactUsAgreement', fallback: '联系我们');
  String contactInfoMessage(String email) {
    final template = _t(
      'contactInfo',
      fallback:
          '如果您对本用户协议有任何疑问，请通过以下方式联系我们：\n\n反馈建议：设置 → 反馈建议（推荐）\n邮箱：{email}\n应用内反馈：设置 → 意见反馈',
    );
    return template.replaceAll('{email}', email);
  }

  String closingMessage(String appName) {
    final template = _t(
      'closingMessage',
      fallback: '感谢您选择{appName}！我们致力于为您提供最佳的笔记体验。\n\n如您对本协议有任何疑问，请随时联系我们。',
    );
    return template.replaceAll('{appName}', appName);
  }

  // ===== 忘记密码页面 =====
  String get functionDescription => _t('functionDescription', fallback: '功能说明');
  String get forgotPasswordHelp => _t(
        'forgotPasswordHelp',
        fallback:
            'Memos服务器暂不支持在线密码重置功能。\n\n如果忘记密码，请：\n\n1. 联系服务器管理员重置密码\n2. 或通过服务器后台管理界面重置\n3. 如果是自建服务器，可通过数据库直接修改',
      );
  String get backToLogin => _t('backToLogin', fallback: '返回登录');
  String get learnMore => _t('learnMore', fallback: '了解详情');

  // ===== 服务器信息页面 =====
  String get initializingServerConnection =>
      _t('initializingServerConnection', fallback: '初始化服务器连接页面...');

  // ===== 登录页面 =====
  String get loginFailedCheckCredentials =>
      _t('loginFailedCheckCredentials', fallback: '登录失败，请检查账号密码和服务器地址');
  String get loginSuccessful => _t('loginSuccessful', fallback: '登录成功！');
  String get welcomeBackPreparingSpace =>
      _t('welcomeBackPreparingSpace', fallback: '欢迎回来！正在为您准备个人笔记空间...');
  String get intelligentNoteManagement =>
      _t('intelligentNoteManagement', fallback: '智能笔记管理，\n让思考更有条理');
  String get welcomeBack => _t('welcomeBack', fallback: '欢迎回来');
  String get continueCreativeJourney =>
      _t('continueCreativeJourney', fallback: '继续您的创作之旅');
  String get createAccount => _t('createAccount', fallback: '创建账户');
  String get startYourCreativeJourney =>
      _t('startYourCreativeJourney', fallback: '开启您的创作之旅');
  String get onlySupportsMemosVersion =>
      _t('onlySupportsMemosVersion', fallback: '仅支持 Memos 0.21.0');
  String get pleaseEnterUsername =>
      _t('pleaseEnterUsername', fallback: '请输入用户名');
  String get usernameMinLength =>
      _t('usernameMinLength', fallback: '用户名至少需要2个字符');
  String get usernameNoSpaces => _t('usernameNoSpaces', fallback: '用户名不能包含空格');
  String get pleaseEnterPassword =>
      _t('pleaseEnterPassword', fallback: '请输入密码');
  String get passwordMinLength =>
      _t('passwordMinLength', fallback: '密码至少需要6个字符');
  String get server => _t('server', fallback: '服务器');
  String get customServer => _t('customServer', fallback: '自定义服务器');
  String get officialServer => _t('officialServer', fallback: '官方服务器');
  String get recommended => _t('recommended', fallback: '推荐使用');
  String get serverAddressMustStartWithHttp =>
      _t('serverAddressMustStartWithHttp', fallback: '服务器地址必须以 http:// 或 https:// 开头');
  String get change => _t('change', fallback: '更改');
  String get customize => _t('customize', fallback: '自定义');
  String get custom => _t('custom', fallback: '自定义');
  String get saveAccountLocally =>
      _t('saveAccountLocally', fallback: '保存账号和密码到本地');
  String get noAccount => _t('noAccount', fallback: '还没有账号？');
  String get versionCompatibility =>
      _t('versionCompatibility', fallback: '版本兼容性说明');
  String get contactSupport =>
      _t('contactSupport', fallback: '如有疑问，请查看官方文档或联系技术支持');
  String get customServerWarning =>
      _t('customServerWarning', fallback: '使用自定义服务器可能会影响使用体验');
  String get answerYourQuestions =>
      _t('answerYourQuestions', fallback: '为您解答使用中的疑问');
  String get howToLogin => _t('howToLogin', fallback: '如何登录账号？');
  String get howToLoginAnswer => _t(
        'howToLoginAnswer',
        fallback: '输入您注册时使用的用户名和密码，即可登录。如果开启"记住密码"，下次将自动登录。',
      );
  String get whatIsServer => _t('whatIsServer', fallback: '什么是服务器？');
  String get whatIsServerAnswer => _t(
        'whatIsServerAnswer',
        fallback: '服务器用于存储和同步您的笔记数据。推荐使用官方服务器，也可以使用自己部署的 Memos 服务器。',
      );
  String get howToSyncData => _t('howToSyncData', fallback: '如何同步数据？');
  String get howToSyncDataAnswer => _t(
        'howToSyncDataAnswer',
        fallback: '登录后，您的笔记将自动同步到服务器。支持多端同步，在任何设备登录都能查看您的笔记。',
      );

  // ===== 注册页面 =====
  String get pleaseAgreeToPolicy =>
      _t('pleaseAgreeToPolicy', fallback: '请阅读并同意隐私政策及用户协议');
  String get registrationSuccessful =>
      _t('registrationSuccessful', fallback: '注册成功！正在为您登录...');
  String get registrationFailed =>
      _t('registrationFailed', fallback: '注册失败，请检查信息后重试');
  String get joinInkRoot => _t('joinInkRoot', fallback: '加入 InkRoot');
  String get startIntelligentNoteJourney =>
      _t('startIntelligentNoteJourney', fallback: '开启您的智能笔记之旅');
  String get startCreativeJourney =>
      _t('startCreativeJourney', fallback: '开启您的\n创作之旅');
  String get recordEachMoment =>
      _t('recordEachMoment', fallback: '加入 InkRoot，记录每一个值得珍藏的时刻');
  String get usernameMinLength3 =>
      _t('usernameMinLength3', fallback: '用户名至少需要3个字符');
  String get usernameInvalidChars =>
      _t('usernameInvalidChars', fallback: '用户名只能包含字母、数字、下划线和中文');
  String get passwordHint => _t('passwordHint', fallback: '至少8位，包含字母或数字');
  String get pleaseConfirmPassword =>
      _t('pleaseConfirmPassword', fallback: '请再次输入密码');
  String get passwordMismatch => _t('passwordMismatch', fallback: '两次输入的密码不一致');
  String get autoLoginAfterRegistration =>
      _t('autoLoginAfterRegistration', fallback: '注册后自动登录');
  String get betterExperience =>
      _t('betterExperience', fallback: '为您提供更便捷的使用体验');
  String get agreeToTerms => _t('agreeToTerms', fallback: '我已阅读并同意 ');
  String get privacyPolicy => _t('privacyPolicy', fallback: '隐私政策');
  String get startCreating => _t('startCreating', fallback: '开始创作');
  String get alreadyHaveAccount =>
      _t('alreadyHaveAccount', fallback: '已有账号？立即登录');
  String get howToRegister => _t('howToRegister', fallback: '如何注册账号？');
  String get howToRegisterAnswer => _t(
        'howToRegisterAnswer',
        fallback: '填写用户名和密码（至少8位），勾选同意协议后点击"开始创作"即可注册。注册成功后将自动登录。',
      );
  String get whatFeaturesSupported =>
      _t('whatFeaturesSupported', fallback: '笔记支持哪些功能？');
  String get whatFeaturesAnswer => _t(
        'whatFeaturesAnswer',
        fallback: '支持 Markdown 格式、图片上传、标签分类、提醒功能、知识图谱等。还能使用 AI 助手帮助您创作和整理笔记。',
      );
  String get isDataSafe => _t('isDataSafe', fallback: '数据安全吗？');
  String get isDataSafeAnswer => _t(
        'isDataSafeAnswer',
        fallback: '我们使用加密传输保护您的数据安全。本地数据也经过安全存储。建议定期备份重要笔记。',
      );
  String get whatIfForgotPassword =>
      _t('whatIfForgotPassword', fallback: '忘记密码怎么办？');
  String get whatIfForgotPasswordAnswer => _t(
        'whatIfForgotPasswordAnswer',
        fallback: '如使用官方服务器，请联系管理员重置密码。如使用自定义服务器，请联系您的服务器管理员。',
      );
  String get anyOtherQuestions => _t('anyOtherQuestions', fallback: '还有其他问题？');
  String get viewHelpCenter => _t('viewHelpCenter', fallback: '查看帮助中心');

  // ===== Home页面 =====
  String get createNoteFailed => _t('createNoteFailed', fallback: '创建笔记失败');
  // syncSuccess已在前面定义(line 81)
  String get refreshSuccess => _t('refreshSuccess', fallback: '刷新成功');
  String get refreshFailed => _t('refreshFailed', fallback: '刷新失败');
  // sortBy已在前面定义(line 186)
  String get newestFirst => _t('newestFirst', fallback: '最新优先');
  String get oldestFirst => _t('oldestFirst', fallback: '最旧优先');
  String get updatedTime => _t('updatedTime', fallback: '更新时间');
  String get createFailed => _t('createFailed', fallback: '创建失败');
  String get addedFromShare => _t('addedFromShare', fallback: '已添加来自分享的笔记');
  // updateFailed已在前面定义(line 80)
  // noteDeleted已在前面定义(line 277)
  // deleteFailed已在前面定义(line 278)
  String get notePinned => _t('notePinned', fallback: '笔记已置顶');
  String get noteUnpinned => _t('noteUnpinned', fallback: '笔记已取消置顶');
  // searchNotes已在前面定义(line 183)
  // loading已在前面定义(line 211)
  String loadedAllNotes(int count) {
    final template = _t('loadedAllNotes', fallback: '已加载全部 {count} 条笔记');
    return template.replaceAll('{count}', count.toString());
  }

  String get enableAIFirst => _t('enableAIFirst', fallback: '请先在设置中启用AI功能');
  String get configureAIFirst =>
      _t('configureAIFirst', fallback: '请先在设置中配置AI API');

  // ===== 笔记详情页面 =====
  String get unableToOpenLink => _t('unableToOpenLink', fallback: '无法打开链接');
  // linkError已在前面定义(line 274)
  String get reviewCopied => _t('reviewCopied', fallback: '点评内容已复制');
  String get copyReview => _t('copyReview', fallback: '复制点评');
  // close已在前面定义(line 163)
  String get noteUpdated => _t('noteUpdated', fallback: '笔记已更新');
  String get noteActions => _t('noteActions', fallback: '笔记操作');
  String get selectAction => _t('selectAction', fallback: '选择您要执行的操作');
  // share已在前面定义(line 551)
  // edit已在前面定义(line 56)
  // pinNote已在前面定义(line 177)
  // unpinNote已在前面定义(line 178)
  String get archiveNote => _t('archiveNote', fallback: '归档');
  String get unarchiveNote => _t('unarchiveNote', fallback: '取消归档');
  // deleteNote已在前面定义(line 176)
  // copyContent已在前面定义(line 472)
  String get viewHistory => _t('viewHistory', fallback: '查看历史');
  String get setReminder => _t('setReminder', fallback: '设置提醒');
  String get aiReview => _t('aiReview', fallback: 'AI点评');
  String get aiReviewSubtitle => _t('aiReviewSubtitle', fallback: 'AI Review');
  String get exportAsImage => _t('exportAsImage', fallback: '导出图片');
  String get contentCopied => _t('contentCopied', fallback: '内容已复制');
  String get copyFailed => _t('copyFailed', fallback: '复制失败');
  String get confirmDelete => _t('confirmDelete', fallback: '确认删除');
  String get deleteNoteMessage =>
      _t('deleteNoteMessage', fallback: '确定要删除这条笔记吗？此操作不可恢复。');

  // ===== 账户信息页面 =====
  // unknown已在前面定义(line 280)
  // notLoggedInOrAPINotInitialized已在前面定义(line 378)
  String get currentUserInfoEmpty =>
      _t('currentUserInfoEmpty', fallback: '当前用户信息为空');
  String get userInfoSyncSuccess =>
      _t('userInfoSyncSuccess', fallback: '用户信息同步成功');
  String get allAPIVersionsFailed =>
      _t('allAPIVersionsFailed', fallback: '所有API版本都无法获取用户信息');
  String allAPIVersionsUpdateFailed(String v1Error, String v2Error) {
    final template = _t(
      'allAPIVersionsUpdateFailed',
      fallback: '所有API版本更新失败: v1({v1}), v2({v2})',
    );
    return template.replaceAll('{v1}', v1Error).replaceAll('{v2}', v2Error);
  }

  String get userInfoEmpty => _t('userInfoEmpty', fallback: '用户信息为空');
  String get cannotGetUsername => _t('cannotGetUsername', fallback: '无法获取用户名');
  String allPasswordUpdateFailed(String v1Error, String v2Error) {
    final template = _t(
      'allPasswordUpdateFailed',
      fallback: '所有API版本密码更新失败: v1({v1}), v2({v2})',
    );
    return template.replaceAll('{v1}', v1Error).replaceAll('{v2}', v2Error);
  }

  // ===== 实验室页面 =====
  String get telegramBot => _t('telegramBot', fallback: 'Telegram 助手');
  String get telegramBotDesc =>
      _t('telegramBotDesc', fallback: '连接 InkRoot_Bot，实现跨平台笔记同步');
  String get stableRunning => _t('stableRunning', fallback: '稳定运行');
  String get voiceToText => _t('voiceToText', fallback: '语音转文字');
  String get voiceToTextDesc =>
      _t('voiceToTextDesc', fallback: '语音录制自动转换为文字笔记');
  String get aiNoteAssistant => _t('aiNoteAssistant', fallback: 'AI 笔记助手');
  String get aiNoteAssistantDesc =>
      _t('aiNoteAssistantDesc', fallback: '智能分析和优化您的笔记内容');
  String get expectedNextRelease =>
      _t('expectedNextRelease', fallback: '预计下个版本发布');
  String get connectInkRootBot =>
      _t('connectInkRootBot', fallback: '连接 InkRoot_Bot');
  String get telegramBotDialogContent => _t('telegramBotDialogContent',
      fallback: '在 Telegram 中搜索 @InkRoot_Bot，连接机器人后即可发送消息自动创建笔记。支持 Markdown 格式，实时同步到 InkRoot 应用。');
  String get voiceToTextDialogContent => _t('voiceToTextDialogContent',
      fallback: '在笔记编辑器中点击麦克风按钮即可开始语音识别。支持离线识别，无需联网。识别过程中可随时暂停和继续，文字将自动插入到编辑器中。');
  
  // AI 智能助手
  String get aiSmartAssistant => _t('aiSmartAssistant', fallback: 'AI 智能助手');
  String get aiSmartAssistantDesc =>
      _t('aiSmartAssistantDesc', fallback: '相关笔记推荐、智能续写、标签生成、内容摘要');
  String get aiAssistantFeatures =>
      _t('aiAssistantFeatures', fallback: 'AI 智能助手包含以下功能：');
  String get relatedNotesRecommend =>
      _t('relatedNotesRecommend', fallback: '📌 相关笔记推荐');
  String get relatedNotesDesc =>
      _t('relatedNotesDesc', fallback: '基于笔记内容智能推荐相关笔记');
  String get smartContinueWriting =>
      _t('smartContinueWriting', fallback: '✍️ 智能续写');
  String get smartContinueWritingDesc =>
      _t('smartContinueWritingDesc', fallback: '根据上下文智能续写笔记内容');
  String get tagGeneration => _t('tagGeneration', fallback: '🏷️ 标签生成');
  String get tagGenerationDesc =>
      _t('tagGenerationDesc', fallback: '自动分析笔记内容生成相关标签');
  String get contentSummary => _t('contentSummary', fallback: '📝 内容摘要');
  String get contentSummaryDesc =>
      _t('contentSummaryDesc', fallback: '快速生成笔记内容摘要');
  String get aiAssistantTip =>
      _t('aiAssistantTip', fallback: '💡 提示：在笔记详情页点击右下角魔法棒图标即可使用');
  
  // 笔记批注
  String get noteAnnotation => _t('noteAnnotation', fallback: '笔记批注');
  String get noteAnnotationDesc =>
      _t('noteAnnotationDesc', fallback: '为笔记添加评论、问题、想法等批注信息');
  String get testing => _t('testing', fallback: '测试中');
  String get annotationIntro =>
      _t('annotationIntro', fallback: '为笔记添加批注，记录你的想法、问题和评论：');
  String get annotationComment => _t('annotationComment', fallback: '💬 评论');
  String get annotationCommentDesc =>
      _t('annotationCommentDesc', fallback: '添加对笔记内容的评论和反思');
  String get annotationQuestion => _t('annotationQuestion', fallback: '❓ 问题');
  String get annotationQuestionDesc =>
      _t('annotationQuestionDesc', fallback: '记录阅读时产生的疑问');
  String get annotationIdea => _t('annotationIdea', fallback: '💡 想法');
  String get annotationIdeaDesc =>
      _t('annotationIdeaDesc', fallback: '记录灵感和新想法');
  String get annotationImportant => _t('annotationImportant', fallback: '⚠️ 重要');
  String get annotationImportantDesc =>
      _t('annotationImportantDesc', fallback: '标记重要信息和关键点');
  String get annotationWarning => _t('annotationWarning',
      fallback: '⚠️ 功能暂时不稳定，请自行斟酌使用。批注数据仅保存在本地，不会同步到服务器。');
  String get annotationUsageTip => _t('annotationUsageTip',
      fallback: '💡 使用方法：在笔记列表或详情页点击批注图标 🟠 即可查看和管理批注');
  String get iKnow => _t('iKnow', fallback: '我知道了');

  // ===== AI设置页面 =====
  String get doubaoModel => _t('doubaoModel', fallback: '豆包 Pro');
  String get zhipuModel => _t('zhipuModel', fallback: '智谱 GLM-4');
  String get baichuanModel => _t('baichuanModel', fallback: '百川智能');
  String get unknownModel => _t('unknownModel', fallback: '未知模型');
  String get deepseekchat => _t('deepseekchat', fallback: 'DeepSeek Chat');
  String get deepseekchatDesc =>
      _t('deepseekchatDesc', fallback: '快速响应，适合日常对话');
  String get deepseekReasoner =>
      _t('deepseekReasoner', fallback: 'DeepSeek Reasoner');
  String get deepseekReasonerDesc =>
      _t('deepseekReasonerDesc', fallback: '深度思考，适合复杂推理');
  String get gpt4o => _t('gpt4o', fallback: 'GPT-4o');
  String get gpt4oDesc => _t('gpt4oDesc', fallback: '最新旗舰，强大全能');
  String get gpt4oMini => _t('gpt4oMini', fallback: 'GPT-4o Mini');
  String get gpt4oMiniDesc => _t('gpt4oMiniDesc', fallback: '轻量快速，性价比高');
  String get gpt4Turbo => _t('gpt4Turbo', fallback: 'GPT-4 Turbo');
  String get gpt4TurboDesc => _t('gpt4TurboDesc', fallback: '强大推理');
  String get gpt35Turbo => _t('gpt35Turbo', fallback: 'GPT-3.5 Turbo');

  // ===== 设置页面 =====
  String get waitPatiently => _t('waitPatiently', fallback: '静待沉淀');
  String get poiseToResound => _t('poiseToResound', fallback: '蓄势鸣响');
  String get focusAndAccumulate =>
      _t('focusAndAccumulate', fallback: '你的每一次落笔，都是未来成长的根源！');

  // ===== 隐私政策页面 =====
  String get privacyPolicyTitle => _t('privacyPolicyTitle', fallback: '隐私政策');
  String get importantStatement => _t('importantStatement', fallback: '重要声明');
  String get informationCollection =>
      _t('informationCollection', fallback: '信息收集与处理');
  String get dataTransmissionSecurity =>
      _t('dataTransmissionSecurity', fallback: '数据传输与安全');
  String get privacyPolicyContent1 =>
      _t('privacyPolicyContent1', fallback: '我们不收集以下信息：');
  String get privacyPolicyContent2 =>
      _t('privacyPolicyContent2', fallback: '本地存储的信息：');
  String get privacyPolicyContent3 =>
      _t('privacyPolicyContent3', fallback: '技术实现：');
  String get privacyPolicyContent4 =>
      _t('privacyPolicyContent4', fallback: '这些信息仅存储在您的设备上，不会传输给我们或任何第三方。');
  String get privacyPolicyContent5 =>
      _t('privacyPolicyContent5', fallback: '主要数据流向：');
  String get privacyPolicyContent6 =>
      _t('privacyPolicyContent6', fallback: '数据安全保障：');

  // ===== NoteEditor Widget =====
  String get thinkingNow => _t('thinkingNow', fallback: '现在的想法是...');
  String get listening => _t('listening', fallback: '正在聆听...');
  String get recognizing => _t('recognizing', fallback: '识别中');
  String get tapToStop => _t('tapToStop', fallback: '点击停止');
  String get saveFailed => _t('saveFailed', fallback: '保存失败');
  String get loadFailed => _t('loadFailed', fallback: '加载失败');
  String get selectImageFailed => _t('selectImageFailed', fallback: '选择图片失败');
  String get noteNotFound => _t('noteNotFound', fallback: '找不到要引用的笔记');
  String get referenceInserted =>
      _t('referenceInserted', fallback: '引用内容已插入，保存笔记后将自动建立引用关系');
  String get referenceCreatedSuccess =>
      _t('referenceCreatedSuccess', fallback: '引用关系已创建');
  String get createReferenceFailed =>
      _t('createReferenceFailed', fallback: '创建引用关系失败');
  String get referenceFailed => _t('referenceFailed', fallback: '引用失败');
  String get needMicPermission =>
      _t('needMicPermission', fallback: '需要麦克风权限才能使用语音识别');

  // ===== NoteCard Widget =====
  String get cannotDisplayImage => _t('cannotDisplayImage', fallback: '无法显示图片');
  String get pinnedStatus => _t('pinned', fallback: '置顶');
  String get unpinnedStatus => _t('unpinned', fallback: '取消置顶');
  String get referenceDetails => _t('referenceDetails', fallback: '引用详情');
  String get viewReferenceRelations =>
      _t('viewReferenceRelations', fallback: '查看笔记引用关系');

  // ===== Widget通用文本 =====
  String get pleaseEnableNotificationFirst =>
      _t('pleaseEnableNotificationFirst', fallback: '请先开启通知权限才能设置提醒');
  String get setReminderFailed =>
      _t('setReminderFailed', fallback: '设置提醒失败，请稍后重试');
  String get needNotificationPermission =>
      _t('needNotificationPermission', fallback: '需要开启通知权限');
  String get later => _t('later', fallback: '稍后');
  String get batteryOptimization => _t('batteryOptimization', fallback: '电池优化');

  // ===== 权限引导对话框 =====
  String get permissionsReady => _t('permissionsReady', fallback: '✅ 权限已就绪');
  String get permissionsRequired => _t('permissionsRequired', fallback: '需要权限');
  String get allPermissionsGrantedMessage =>
      _t('allPermissionsGrantedMessage', fallback: '所有权限已开启，可以正常使用提醒功能');
  String get pleaseEnablePermissionsMessage =>
      _t('pleaseEnablePermissionsMessage', fallback: '为了准时收到笔记提醒，请开启以下权限');
  String get notificationPermission =>
      _t('notificationPermission', fallback: '通知权限');
  String get allowAppNotifications =>
      _t('allowAppNotifications', fallback: '允许应用显示通知');
  String get exactAlarm => _t('exactAlarm', fallback: '精确闹钟');
  String get allowExactAlarmDescription =>
      _t('allowExactAlarmDescription', fallback: '允许在特定时间触发提醒');
  String get backgroundRunning => _t('backgroundRunning', fallback: '后台运行');
  String get allowBackgroundDescription =>
      _t('allowBackgroundDescription', fallback: '允许应用在后台保持活跃');
  String get openSettingsInstructions => _t(
        'openSettingsInstructions',
        fallback: '点击下方"打开设置"按钮，在应用设置中开启权限后，点击"重新检查"',
      );
  String get openSettings => _t('openSettings', fallback: '打开设置');
  String get recheck => _t('recheck', fallback: '重新检查');
  String get postponeSettings => _t('postponeSettings', fallback: '稍后设置');

  // ===== NoteCard侧滑按钮 =====
  String get pinAction => _t('pinAction', fallback: '置顶');
  String get unpinAction => _t('unpinAction', fallback: '取消置顶');
  String get deleteAction => _t('deleteAction', fallback: '删除');

  // ===== 分享功能 =====
  String get shareLink => _t('shareLink', fallback: '分享链接');
  String get generateShareLink => _t('generateShareLink', fallback: '生成分享链接');
  String get shareImage => _t('shareImage', fallback: '分享图片');
  String get generateImageShare => _t('generateImageShare', fallback: '生成图片分享');
  String get quickActions => _t('quickActions', fallback: '快捷操作');
  String get copyNoteContent => _t('copyNoteContent', fallback: '复制笔记内容到剪贴板');
  String get systemShare => _t('systemShare', fallback: '系统分享');
  String get useSystemShare => _t('useSystemShare', fallback: '使用系统分享功能');
  String get noteSummary => _t('noteSummary', fallback: '笔记摘要');
  String get sharePermissionConfirmation =>
      _t('sharePermissionConfirmation', fallback: '分享权限确认');
  String get sharePermissionMessage => _t(
        'sharePermissionMessage',
        fallback: '要分享此笔记，需要将其设置为公开状态。\n任何拥有链接的人都可以查看该笔记的内容。',
      );
  String get confirmAndShare => _t('confirmAndShare', fallback: '确定并分享');
  String get pleaseLoginToShare =>
      _t('pleaseLoginToShare', fallback: '请先登录后再使用分享链接功能');
  String get generatingHighQualityImage =>
      _t('generatingHighQualityImage', fallback: '生成高质量分享图片需要一些时间');
  String get analyzingImages => _t('analyzingImages', fallback: '正在分析图片...');
  String get loadingImages => _t('loadingImages', fallback: '正在加载图片...');
  String get generatingShareImage =>
      _t('generatingShareImage', fallback: '正在生成分享图片...');
  String get savingImage => _t('savingImage', fallback: '正在保存图片...');
  String get shareFailedRetry =>
      _t('shareFailedRetry', fallback: '生成分享链接失败，请稍后再试');
  String get loginRequired => _t('loginRequired', fallback: '需要登录');
  String get shareUnknownError =>
      _t('shareUnknownError', fallback: '生成分享链接时发生未知错误，请稍后重试');
  String get setReminderTime => _t('setReminderTime', fallback: '设置提醒时间');
  String get setNoteReminderTime =>
      _t('setNoteReminderTime', fallback: '设定笔记提醒时间');
  String get shareSettings => _t('shareSettings', fallback: '分享设置');
  String get customizeShareContent =>
      _t('customizeShareContent', fallback: '自定义分享内容和选项');
  String get changeTime => _t('changeTime', fallback: '修改时间');
  String get selectDate => _t('selectDate', fallback: '选择日期');
  String get selectTime => _t('selectTime', fallback: '选择时间');
  String get timeUpdated => _t('timeUpdated', fallback: '时间已更新');
  String get viewOriginalImage => _t('viewOriginalImage', fallback: '查看原图');
  String get saveImage => _t('saveImage', fallback: '保存图片');
  String get fitScreen => _t('fitScreen', fallback: '适应屏幕');
  String get fillScreen => _t('fillScreen', fallback: '填满屏幕');
  String get loadingHDImage => _t('loadingHDImage', fallback: '正在加载高清原图...');
  String get imageLoadError => _t('imageLoadError', fallback: '无法加载图片');
  String get networkFailedNoCache => _t('networkFailedNoCache', fallback: '网络连接失败且无缓存');
  String get authFailedNoCache => _t('authFailedNoCache', fallback: '认证失败且无缓存');
  String get unsupportedImageFormat => _t('unsupportedImageFormat', fallback: '不支持的图片格式');
  String get allImagesCount => _t('allImagesCount', fallback: '全部图片 ({count})');
  String get timeUpdateFailed => _t('timeUpdateFailed', fallback: '时间更新失败');
  String get detailedInfo => _t('detailedInfo', fallback: '详细信息');
  String get viewCreationTime => _t('viewCreationTime', fallback: '查看创建时间详细信息');
  String get appSettings => _t('appSettings', fallback: '应用设置');
  String get modifyReminderTime => _t('modifyReminderTime', fallback: '修改提醒时间');
  String get cancelReminder => _t('cancelReminder', fallback: '取消提醒');
  String get referenceCreated => _t('referenceCreated', fallback: '引用关系已创建');
  String get linkCopied => _t('linkCopied', fallback: '链接已复制到剪贴板');
  String get copyLink => _t('copyLink', fallback: '复制链接');
  // Note: cancel and share are already defined above
  String get saveAndShare => _t('saveAndShare', fallback: '保存并分享');
  String get generatingShareLink =>
      _t('generatingShareLink', fallback: '正在生成分享链接...');
  // copyReview已在前面定义(line 796)
  // Note: close is already defined above
  // loadFailed已在前面定义(line 886)

  // ===== 导入导出页面补充 =====
  String get importDescription => _t('importDescription', fallback: '导入说明');
  String get supportedFormatsDescription =>
      _t('supportedFormatsDescription', fallback: '支持导入以下格式的备份文件：');
  String get markdownBatchImport =>
      _t('markdownBatchImport', fallback: '支持批量导入Markdown文件');
  String get txtImportDescription =>
      _t('txtImportDescription', fallback: '纯文本文件将作为单独笔记导入');
  String get htmlImportDescription =>
      _t('htmlImportDescription', fallback: '支持从其他笔记软件导出的HTML');
  String get importWarning =>
      _t('importWarning', fallback: '导入操作可能会影响现有数据，建议先备份当前数据');
  String get importOptions => _t('importOptions', fallback: '导入选项');
  String get overwriteExistingNotes =>
      _t('overwriteExistingNotes', fallback: '覆盖现有笔记');
  String get overwriteDescription =>
      _t('overwriteDescription', fallback: '如果导入的笔记与现有笔记ID相同，则覆盖现有笔记');
  String get importAsNewNotes => _t('importAsNewNotes', fallback: '作为新笔记导入');
  String get importAsNewDescription =>
      _t('importAsNewDescription', fallback: '所有导入的笔记将作为新笔记添加，不会影响现有笔记');
  String get refreshImportHistory =>
      _t('refreshImportHistory', fallback: '刷新导入历史');
  String get noImportHistory => _t('noImportHistory', fallback: '暂无导入历史记录');
  String get setPassword => _t('setPassword', fallback: '设置密码');
  String get rememberPasswordWarning =>
      _t('rememberPasswordWarning', fallback: '请记住您的密码，如果忘记将无法恢复备份数据');

  // ===== 数据清理页面补充 =====
  String get cleanCacheConfirm =>
      _t('cleanCacheConfirm', fallback: '此操作将清除应用缓存，可能会影响短期使用体验。是否继续？');
  String get cacheCleanedSuccess =>
      _t('cacheCleanedSuccess', fallback: '缓存已清理');
  String get cleanCacheFailed => _t('cleanCacheFailed', fallback: '清理缓存失败');
  String get imagesCleanedSuccess =>
      _t('imagesCleanedSuccess', fallback: '图片已清理');
  String get cleanImagesFailed => _t('cleanImagesFailed', fallback: '清理图片失败');
  String get confirmReset => _t('confirmReset', fallback: '确认重置');
  String get resetSettingsConfirm =>
      _t('resetSettingsConfirm', fallback: '此操作将重置所有应用设置到默认状态，但不会删除笔记数据。是否继续？');
  String get settingsResetSuccess =>
      _t('settingsResetSuccess', fallback: '应用设置已重置');
  String get resetSettingsFailed =>
      _t('resetSettingsFailed', fallback: '重置设置失败');
  String get historyCleanedSuccess =>
      _t('historyCleanedSuccess', fallback: '导入导出历史已清理');
  String get cleanHistoryFailed => _t('cleanHistoryFailed', fallback: '清理历史失败');
  String get advancedOperations => _t('advancedOperations', fallback: '高级操作');
  String get cleanUnusedImages => _t('cleanUnusedImages', fallback: '清理未使用图片');
  String get cleanImportExportHistory =>
      _t('cleanImportExportHistory', fallback: '清理导入导出历史');
  String get cleanImportExportDescription =>
      _t('cleanImportExportDescription', fallback: '删除所有导入/export历史记录');
  String get resetAppSettings => _t('resetAppSettings', fallback: '重置应用设置');
  String get resetAppDescription =>
      _t('resetAppDescription', fallback: '恢复所有设置到默认状态，不会删除笔记数据');
  String get deleteAllNotes => _t('deleteAllNotes', fallback: '清理所有笔记');
  String get deleteAllNotesWarning => _t(
        'deleteAllNotesWarning',
        fallback: 'Danger: Delete all local data, cannot be undone',
      );
  String get selectTagToView =>
      _t('selectTagToView', fallback: '选择一个标签以查看相关笔记');

  // ===== 版本更新 =====
  String get newVersionAvailable =>
      _t('newVersionAvailable', fallback: '发现新版本');
  String get updateAvailableMessage =>
      _t('updateAvailableMessage', fallback: '墨鸣笔记有新版本可用，建议立即更新以体验新功能！');
  String get updateNotes => _t('updateNotes', fallback: '更新内容：');
  String get remindMeLater => _t('remindMeLater', fallback: '稍后再说');
  // updateNow已在line 519定义

  // ===== 分享相关 =====
  String get sharedText => _t('sharedText', fallback: '收到分享的文本');
  String get sharedImage => _t('sharedImage', fallback: '收到分享的图片');
  String get sharedImages => _t('sharedImages', fallback: '收到分享的图片');
  String get sharedFile => _t('sharedFile', fallback: '收到分享的文件');
  String get sharedFromOther => _t('sharedFromOther', fallback: '来自分享的');
  String sharedImagesCount(int count) {
    final template = _t('sharedImagesCount', fallback: '来自分享的图片 ({count}张)');
    return template.replaceAll('{count}', count.toString());
  }

  String get sharedFiles => _t('sharedFiles', fallback: '分享的文件：');

  // ===== 排序和筛选 =====
  String get fromNewToOld => _t('fromNewToOld', fallback: '从新到旧');
  String get fromOldToNew => _t('fromOldToNew', fallback: '从旧到新');
  String get filterNotes => _t('filterNotes', fallback: '筛选笔记');
  String get totalWordCount => _t('totalWordCount', fallback: '总字数');
  String get tagCount => _t('tagCount', fallback: '标签数');

  // ===== 登录状态 =====
  String get online => _t('online', fallback: '在线');
  String get offline => _t('offline', fallback: '离线');
  String get clearLocalData => _t('clearLocalData', fallback: '清空本地数据');
  String get keepLocalData => _t('keepLocalData', fallback: '保留本地数据');

  // ===== 功能菜单 =====
  String get featureMenu => _t('featureMenu', fallback: '功能菜单');
  String get noAvailableTags => _t('noAvailableTags', fallback: '暂无可用标签');

  // ===== AI洞察相关 =====
  String get keywords => _t('keywords', fallback: '关键词');
  String get inputKeywords => _t('inputKeywords', fallback: '输入想要洞察的关键词');
  String get timeRange => _t('timeRange', fallback: '时间范围');
  String get selectAnalysisTimeRange =>
      _t('selectAnalysisTimeRange', fallback: '选择要分析的时间段');
  // includeTags已在line 233定义
  String get selectIncludeTags => _t('selectIncludeTags', fallback: '选择要包含的标签');
  String get excludeTags => _t('excludeTags', fallback: '排除标签');
  String get selectExcludeTags => _t('selectExcludeTags', fallback: '选择要排除的标签');
  String get insightResults => _t('insightResults', fallback: '洞察结果');
  String get aiGeneratedAnalysis =>
      _t('aiGeneratedAnalysis', fallback: 'AI为您生成的深度分析');
  String get allTime => _t('allTime', fallback: '全部');

  // ===== 权限和设置提示 =====
  String get permissionRequired => _t('permissionRequired', fallback: '需要通知权限');
  String get permissionInstructions => _t(
        'permissionInstructions',
        fallback:
            '为了准时提醒您，InkRoot需要发送通知。请在iPhone设置中找到InkRoot，开启"允许通知"，并启用"时间敏感通知"。',
      );
  String get operationSteps => _t('operationSteps', fallback: '操作步骤：');
  String get permissionStepGuide => _t(
        'permissionStepGuide',
        fallback: '1. 点击"去设置"按钮\n2. 找到"通知"权限\n3. 开启权限开关\n4. 返回应用重试',
      );
  String get goToSettings => _t('goToSettings', fallback: '去设置');
  String get rateLimitExceeded =>
      _t('rateLimitExceeded', fallback: '请求过于频繁，请稍后再试');
  String get streamResponseNotImplemented =>
      _t('streamResponseNotImplemented', fallback: '流式响应功能待实现');
  String get noTitle => _t('noTitle', fallback: '无标题');
  String get view => _t('view', fallback: '查看');

  // ===== 通知相关 =====
  String get noteReminder => _t('noteReminder', fallback: '笔记提醒');
  String get noteReminderDescription =>
      _t('noteReminderDescription', fallback: '笔记定时提醒通知');
  String get dismiss => _t('dismiss', fallback: '关闭');

  // ===== 时间相关 =====
  String get last7Days => _t('last7Days', fallback: '近7天');
  String get last30Days => _t('last30Days', fallback: '近30天');
  String get last1Year => _t('last1Year', fallback: '近1年');

  // ===== 笔记详情页 =====
  String get noteDetail => _t('noteDetail', fallback: '笔记详情');
  String get linkNote => _t('linkNote', fallback: '链接');
  String get deleteNoteConfirmTitle =>
      _t('deleteNoteConfirmTitle', fallback: '删除笔记');
  String get deleteNoteConfirmMessage =>
      _t('deleteNoteConfirmMessage', fallback: '确定要删除这条笔记吗？删除后无法恢复。');
  // referenceDetails已在line 900定义
  // viewReferenceRelations已在line 901定义
  // detailedInfo已在line 957定义
  String get viewCreationTimeInfo =>
      _t('viewCreationTimeInfo', fallback: '查看创建时间等信息');
  String get reminderSet => _t('reminderSet', fallback: '提醒已设置');
  String get clickToModifyReminder =>
      _t('clickToModifyReminder', fallback: '点击修改或取消提醒');
  // setNoteReminderTime已在line 954定义
  // shareSettings已在line 955定义
  String get manageNoteVisibility =>
      _t('manageNoteVisibility', fallback: '管理笔记可见性');
  // createdTime已在line 369定义
  // characterCount已在line 470定义
  String get characters => _t('characters', fallback: '字符');
  // tagCount已在line 1044定义
  String get tagsCount => _t('tagsCount', fallback: '个标签');
  // shareNote已在line 874定义
  // shareLink已在line 875定义
  // generateShareLink已在line 876定义
  // shareImage已在line 877定义
  // generateImageShare已在line 935定义

  // ===== AI提示词 =====
  String get aiSystemPrompt =>
      _t('aiSystemPrompt', fallback: '你是一个专业的内容分析助手...');

  // ===== 笔记编辑器 =====
  String get image => _t('image', fallback: '图片');
  String get addNoteReference => _t('addNoteReference', fallback: '添加笔记引用');
  String get selectNoteToReference =>
      _t('selectNoteToReference', fallback: '选择要引用的笔记，建立笔记间的关联关系');
  String get noNotesToReference =>
      _t('noNotesToReference', fallback: '暂无笔记可引用');
  String get noMatchingNotes => _t('noMatchingNotes', fallback: '没有找到相关笔记');
  String get createNotesFirst =>
      _t('createNotesFirst', fallback: '先创建一些笔记再来建立引用关系');
  String get tryOtherKeywords => _t('tryOtherKeywords', fallback: '试试其他关键词');

  // ===== NoteCard相关 =====
  String get expand => _t('expand', fallback: '展开');
  String get collapse => _t('collapse', fallback: '收起');
  String get reminderCancelled => _t('reminderCancelled', fallback: '已取消提醒');
  String get cancelFailed => _t('cancelFailed', fallback: '取消失败');
  // pleaseEnableNotificationFirst已在line 904定义
  // setReminderFailed已在line 905定义
  // needNotificationPermission已在line 906定义
  String get notificationSteps =>
      _t('notificationSteps', fallback: '为了准时收到笔记提醒，请按以下步骤操作：');
  String get tapAppSettingsButton =>
      _t('tapAppSettingsButton', fallback: '🔥 点击下方"应用设置"按钮，然后：');
  String get returnToSettings =>
      _t('returnToSettings', fallback: '6️⃣ 返回手机"设置"主页');
  String get enableAutoStart =>
      _t('enableAutoStart', fallback: '7️⃣ 搜索"自启动" → 找到InkRoot → 开启✅');
  String get disableBatteryOptimization => _t(
        'disableBatteryOptimization',
        fallback: '8️⃣ 搜索"电池优化" → InkRoot → 不限制✅',
      );
  String get autoStartWarning =>
      _t('autoStartWarning', fallback: '不开启自启动和电池优化，应用关闭后就收不到提醒！');
  // batteryOptimization已在line 908定义
  // appSettings已在line 959定义

  // ===== Preferences相关 =====
  // unknown已在line 768定义
  // syncInterval已在line 101定义
  String get rememberPasswordEnabled =>
      _t('rememberPasswordEnabled', fallback: '已同时开启记住密码功能');

  // ===== AccountInfo相关 =====
  // userInfoEmpty已在line 829定义
  String get currentPasswordVerificationFailed =>
      _t('currentPasswordVerificationFailed', fallback: '当前密码验证失败');
  String get currentPasswordIncorrect =>
      _t('currentPasswordIncorrect', fallback: '当前密码不正确');
  String get avatarUpdated => _t('avatarUpdated', fallback: '头像已更新');
  // modifyNickname已在line 374定义
  String get pleaseEnterNewNickname =>
      _t('pleaseEnterNewNickname', fallback: '请输入新的昵称');
  String get nicknameUpdateSuccess =>
      _t('nicknameUpdateSuccess', fallback: '昵称更新成功');
  String get nicknameUpdateFailed =>
      _t('nicknameUpdateFailed', fallback: '昵称更新失败');
  String get modifyBio => _t('modifyBio', fallback: '修改简介');
  // bio已在line 63定义
  String get pleaseEnterNewBio => _t('pleaseEnterNewBio', fallback: '请输入新的简介');
  String get bioUpdateSuccess => _t('bioUpdateSuccess', fallback: '简介更新成功');
  String get bioUpdateFailed => _t('bioUpdateFailed', fallback: '简介更新失败');
  // modifyEmail已在line 375定义
  String get pleaseEnterNewEmail =>
      _t('pleaseEnterNewEmail', fallback: '请输入新的邮箱地址');

  // ===== SnackBarUtils相关 =====
  String get networkConnectionFailed =>
      _t('networkConnectionFailed', fallback: '网络连接失败，请检查网络设置');
  String get connectionTimeout =>
      _t('connectionTimeout', fallback: '连接超时，请检查网络或稍后重试');
  String get serverResponseFormatError =>
      _t('serverResponseFormatError', fallback: '服务器响应格式错误，请检查服务器地址');
  String get loginInfoExpired =>
      _t('loginInfoExpired', fallback: '登录信息已过期，请重新登录');
  String get noAccessPermission =>
      _t('noAccessPermission', fallback: '没有访问权限，请联系管理员');
  String get resourceNotFound =>
      _t('resourceNotFound', fallback: '请求的资源不存在，请检查服务器地址');
  String get serverInternalError =>
      _t('serverInternalError', fallback: '服务器内部错误，请稍后重试');
  String get serverTemporarilyUnavailable =>
      _t('serverTemporarilyUnavailable', fallback: '服务器暂时不可用，请稍后重试');
  String get retry => _t('retry', fallback: '重试');

  // ===== DatabaseService相关 =====
  String get invalidBackupFileFormat =>
      _t('invalidBackupFileFormat', fallback: '无效的备份文件格式');
  String get fileNameContentMismatch =>
      _t('fileNameContentMismatch', fallback: '文件名和内容数量不匹配');

  // ===== 引用关系相关 =====
  String get referenceRelations => _t('referenceRelations', fallback: '引用关系');
  String get viewAllReferences =>
      _t('viewAllReferences', fallback: '查看此笔记的所有引用关系');
  String get noReferences => _t('noReferences', fallback: '暂无引用关系');
  String get canAddReferencesWhenEditing =>
      _t('canAddReferencesWhenEditing', fallback: '在编辑笔记时可以添加引用关系');
  // referenceCreated已在line 962定义
  // referenceFailed已在line 893定义
  // createReferenceFailed已在line 892定义
  String get errorCreatingReference =>
      _t('errorCreatingReference', fallback: '创建引用关系时发生错误');
  String get references => _t('references', fallback: '引用关系');

  // ===== 侧滑操作 =====
  String get reminder => _t('reminder', fallback: '提醒');

  // ===== 关于我们 =====
  String get emailAddress => _t('emailAddress', fallback: '电子邮件');
  String get wechat => _t('wechat', fallback: '微信');

  // ===== 导入导出 =====
  String get selectImportMethod => _t('selectImportMethod', fallback: '选择导入方式');
  String get storagePermissionRequired =>
      _t('storagePermissionRequired', fallback: '需要存储权限');
  String get storagePermissionMessage => _t(
        'storagePermissionMessage',
        fallback:
            '为了能够导出备份文件，需要授予"所有文件访问权限"。\n\n请按照以下步骤操作：\n1. 点击"允许访问所有文件"\n2. 找到并允许"InkRoot-墨鸣笔记"的权限',
      );
  String get allFilesAccessRequired =>
      _t('allFilesAccessRequired', fallback: '需要"所有文件访问权限"才能导出文件');
  String get storagePermissionRequiredForExport =>
      _t('storagePermissionRequiredForExport', fallback: '需要存储权限才能导出文件');
  String get unsupportedExportFormat =>
      _t('unsupportedExportFormat', fallback: '不支持的导出格式');

  // ===== 笔记详情页-提醒相关(新增不重复的) =====
  // reminderSet已在line 1099定义
  // setReminder已在line 811定义
  String get clickToModifyOrCancel =>
      _t('clickToModifyOrCancel', fallback: '点击修改或取消提醒');
  // setNoteReminderTime已在line 954定义
  String get currentReminderTime =>
      _t('currentReminderTime', fallback: '当前提醒时间');
  // modifyReminderTime已在line 960定义
  // cancelReminder已在line 961定义
  // reminderCancelled已在line 1130定义
  String get enableNotificationFirst =>
      _t('enableNotificationFirst', fallback: '请先开启通知权限才能设置提醒');
  String get reminderTimeMustBeFuture =>
      _t('reminderTimeMustBeFuture', fallback: '提醒时间必须在未来');
  // setReminderFailed已在line 905定义
  String get setReminderFailedRetry =>
      _t('setReminderFailedRetry', fallback: '设置提醒失败，请稍后重试');

  // ===== 笔记详情页-详细信息 =====
  String get creationTime => _t('creationTime', fallback: '创建时间');
  String get characterCountLabel => _t('characterCountLabel', fallback: '字符数量');
  String get charactersUnit => _t('charactersUnit', fallback: '字符');
  String get tagsCountLabel => _t('tagsCountLabel', fallback: '标签数量');
  String get tagsUnit => _t('tagsUnit', fallback: '个标签');

  // ===== 笔记详情页-分享相关 =====
  String get shareLinkTitle => _t('shareLinkTitle', fallback: '分享链接');
  String get noteMadePublic =>
      _t('noteMadePublic', fallback: '您的笔记已设置为公开，任何人都可以通过链接访问');
  // linkCopied已在line 963定义
  String get linkCopiedToClipboard =>
      _t('linkCopiedToClipboard', fallback: '链接已复制到剪贴板');
  // copyLink已在line 964定义
  String get shareAction => _t('shareAction', fallback: '分享');
  String get generateShareLinkFailed =>
      _t('generateShareLinkFailed', fallback: '生成分享链接失败，请稍后再试');
  String get copyLinkFailed => _t('copyLinkFailed', fallback: '复制链接失败，请稍后再试');
  String get serverUrlEmpty => _t('serverUrlEmpty', fallback: '服务器地址为空');
  String get cannotMakeNotePublic =>
      _t('cannotMakeNotePublic', fallback: '无法将笔记设置为公开');

  // ===== 数据清理页面 =====
  String get resetSettingsDescription =>
      _t('resetSettingsDescription', fallback: '将所有应用设置恢复到默认状态，不会删除笔记数据');

  // ===== AI设置页面 =====
  String get getApiKey => _t('getApiKey', fallback: '获取API密钥');

  // ===== 首页其他 =====
  String get noNotesMatchingCriteria =>
      _t('noNotesMatchingCriteria', fallback: '没有符合条件的笔记');
  String get contentCopiedToClipboard =>
      _t('contentCopiedToClipboard', fallback: '内容已复制到剪贴板');

  // ===== 热力图统计 =====
  String get totalWords => _t('totalWords', fallback: '总字数');
  String get totalNotes => _t('totalNotes', fallback: '笔记数');
  String get totalDays => _t('totalDays', fallback: '记录天数');
  String get todayWords => _t('todayWords', fallback: '今日字数');
  String get todayNewNotes => _t('todayNewNotes', fallback: '新增笔记');
  String get todayNewTags => _t('todayNewTags', fallback: '新增标签');

  // ===== AI 功能 =====
  String get aiAssistant =>
      locale.languageCode == 'zh' ? 'AI 智能助手' : 'AI Assistant';
  String get aiContinueWriting =>
      locale.languageCode == 'zh' ? 'AI 续写' : 'AI Continue';
  String get aiContinueWritingDesc => locale.languageCode == 'zh'
      ? '基于已有内容智能续写'
      : 'Intelligently continue based on existing content';
  String get aiSmartTags => locale.languageCode == 'zh' ? '智能标签' : 'Smart Tags';
  String get aiSmartTagsDesc => locale.languageCode == 'zh'
      ? '自动生成精准标签'
      : 'Automatically generate precise tags';
  String get aiRelatedNotes =>
      locale.languageCode == 'zh' ? '相关笔记' : 'Related Notes';
  String get aiSummary =>
      locale.languageCode == 'zh' ? '智能摘要' : 'Smart Summary';
  String get aiProcessing =>
      locale.languageCode == 'zh' ? 'AI 处理中...' : 'AI processing...';
  String get aiContinueWritingProcessing =>
      locale.languageCode == 'zh' ? '✨ AI 正在续写中...' : '✨ AI is continuing...';
  String get aiContinueWritingSuccess =>
      locale.languageCode == 'zh' ? '✅ AI 续写完成！' : '✅ AI continue completed!';
  String get aiTagsProcessing => locale.languageCode == 'zh'
      ? '🏷️ AI 正在生成标签...'
      : '🏷️ AI is generating tags...';
  String aiTagsSuccess(int count) {
    final template = locale.languageCode == 'zh'
        ? '✅ 生成了 {count} 个标签！'
        : '✅ Generated {count} tags!';
    return template.replaceAll('{count}', count.toString());
  }

  String get aiSummaryProcessing => locale.languageCode == 'zh'
      ? '🤖 AI 正在生成摘要...'
      : '🤖 AI is generating summary...';
  String get aiSummarySuccess => locale.languageCode == 'zh'
      ? '✅ 摘要生成成功！'
      : '✅ Summary generated successfully!';
  String get aiRelatedNotesProcessing => locale.languageCode == 'zh'
      ? '🔍 AI 正在查找相关笔记...'
      : '🔍 AI is finding related notes...';
  String get aiRelatedNotesEmpty =>
      locale.languageCode == 'zh' ? '暂无相关笔记' : 'No related notes found';
  String get aiConfigRequired => locale.languageCode == 'zh'
      ? '请先在设置中配置 AI'
      : 'Please configure AI in settings first';
  String get aiApiConfigRequired => locale.languageCode == 'zh'
      ? '请先在 AI 设置中配置 API'
      : 'Please configure AI API in settings first';
  String get aiContentRequired => locale.languageCode == 'zh'
      ? '请先输入一些内容'
      : 'Please enter some content first';
  String get aiGenerateSummaryFailed => locale.languageCode == 'zh'
      ? '生成摘要失败，请稍后重试'
      : 'Failed to generate summary, please try again later';
  String get aiRelatedNotesTitle =>
      locale.languageCode == 'zh' ? '相关笔记' : 'Related Notes';

  // 实验室功能
  String get aiRelatedNotesFeature =>
      locale.languageCode == 'zh' ? 'AI 相关笔记' : 'AI Related Notes';
  String get aiRelatedNotesFeatureDesc => locale.languageCode == 'zh'
      ? '智能推荐与当前笔记相关的其他笔记'
      : 'Intelligently recommend notes related to the current note';
  String get aiContinueWritingFeature =>
      locale.languageCode == 'zh' ? 'AI 续写' : 'AI Continue Writing';
  String get aiContinueWritingFeatureDesc => locale.languageCode == 'zh'
      ? '基于已有内容智能续写笔记'
      : 'Intelligently continue writing based on existing content';
  String get aiSmartTagsAndSummary =>
      locale.languageCode == 'zh' ? 'AI 智能标签 & 摘要' : 'AI Smart Tags & Summary';
  String get aiSmartTagsAndSummaryDesc => locale.languageCode == 'zh'
      ? '自动生成精准标签和智能摘要'
      : 'Automatically generate precise tags and smart summaries';
  String get wechatAssistant =>
      locale.languageCode == 'zh' ? '微信小助手' : 'WeChat Assistant';
  String get wechatAssistantDesc => locale.languageCode == 'zh'
      ? '通过微信直接输入快速记录笔记，支持文字、图片'
      : 'Quickly record notes via WeChat, supports text and images';
  String get featureCompleted =>
      locale.languageCode == 'zh' ? '已完成' : 'Completed';
  String get aiRelatedNotesUsage => locale.languageCode == 'zh'
      ? '在笔记详情页点击右下角的 AI 按钮即可查看相关笔记'
      : 'Click the AI button in the bottom right corner of the note details page to view related notes';
  String get aiContinueWritingUsage => locale.languageCode == 'zh'
      ? '在编辑笔记时点击工具栏的 AI 按钮，选择续写功能'
      : 'Click the AI button in the toolbar when editing notes and select the continue writing feature';
  String get aiSmartTagsAndSummaryUsage => locale.languageCode == 'zh'
      ? '编辑笔记时使用 AI 按钮生成标签，详情页使用智能摘要功能'
      : 'Use the AI button to generate tags when editing notes, and use the smart summary feature on the details page';
  String get understood => locale.languageCode == 'zh' ? '知道了' : 'Got it';

  // WebDAV 同步（部分key已存在，只添加新的）
  String get webdavSync =>
      locale.languageCode == 'zh' ? 'WebDAV 同步' : 'WebDAV Sync';
  String get enableWebdavSync =>
      locale.languageCode == 'zh' ? '启用 WebDAV 同步' : 'Enable WebDAV Sync';
  String get syncFolder =>
      locale.languageCode == 'zh' ? '同步文件夹' : 'Sync Folder';
  String get testNow => locale.languageCode == 'zh' ? '立即测试' : 'Test Now';
  String get backupNow => locale.languageCode == 'zh' ? '立即备份' : 'Backup Now';
  String get restoreFromWebdav =>
      locale.languageCode == 'zh' ? '从 WebDAV 恢复' : 'Restore from WebDAV';
  String get enableTimedBackup =>
      locale.languageCode == 'zh' ? '启用定时备份' : 'Enable Timed Backup';
  String get autoBackupToWebdav => locale.languageCode == 'zh'
      ? '自动备份笔记到 WebDAV'
      : 'Auto backup notes to WebDAV';
  String get backupTiming =>
      locale.languageCode == 'zh' ? '备份时机' : 'Backup Timing';
  String get everyStartup =>
      locale.languageCode == 'zh' ? '每次启动' : 'Every Startup';
  String get every15Minutes =>
      locale.languageCode == 'zh' ? '15分钟' : '15 Minutes';
  String get every30Minutes =>
      locale.languageCode == 'zh' ? '30分钟' : '30 Minutes';
  String get every1Hour => locale.languageCode == 'zh' ? '1小时' : '1 Hour';
  String get backingUp =>
      locale.languageCode == 'zh' ? '备份中...' : 'Backing up...';
  String get restoring =>
      locale.languageCode == 'zh' ? '恢复中...' : 'Restoring...';
  String get pleaseEnterServerAddress =>
      locale.languageCode == 'zh' ? '请输入服务器地址' : 'Please enter server address';
  String get addressMustStartWithHttp => locale.languageCode == 'zh'
      ? '地址必须以 http:// 或 https:// 开头'
      : 'Address must start with http:// or https://';
  String get pleaseEnterSyncFolderPath => locale.languageCode == 'zh'
      ? '请输入同步文件夹路径'
      : 'Please enter sync folder path';
  String get webdavConfigSaved =>
      locale.languageCode == 'zh' ? 'WebDAV 配置已保存' : 'WebDAV config saved';
  String get pleaseEnableWebdavFirst => locale.languageCode == 'zh'
      ? '请先启用 WebDAV 同步'
      : 'Please enable WebDAV sync first';
  String get webdavHelpText => locale.languageCode == 'zh'
      ? '• 推荐使用坚果云等专业 WebDAV 服务\n• 坚果云需要使用"应用专用密码"而不是登录密码\n• 立即测试：测试 WebDAV 服务器连接\n• 立即备份：单向上传，完整备份所有数据到云端\n• 从 WebDAV 恢复：下载云端数据到本地（覆盖本地）\n• 定时备份：可选择每次启动或定时自动备份'
      : '• Recommend using professional WebDAV services like Nutstore\n• Nutstore requires using "App-specific password" instead of login password\n• Test Now: Test WebDAV server connection\n• Backup Now: One-way upload, full backup of all data to cloud\n• Restore from WebDAV: Download cloud data to local (overwrite local)\n• Timed Backup: Choose to auto backup on every startup or timed intervals';
  String get webdavGuide =>
      locale.languageCode == 'zh' ? 'WebDAV 使用指南' : 'WebDAV Usage Guide';
  String get whatIsWebdav =>
      locale.languageCode == 'zh' ? '🤔 什么是 WebDAV？' : '🤔 What is WebDAV?';
  String get webdavDescription => locale.languageCode == 'zh'
      ? 'WebDAV 是一种网络协议，可以让你将笔记备份到云端服务器。本应用支持使用 WebDAV 进行笔记备份和恢复。'
      : 'WebDAV is a network protocol that allows you to backup notes to a cloud server. This app supports using WebDAV for note backup and recovery.';

  // ===== 新增缺失的国际化字符串 =====
  String get undoDelete => _t('undoDelete', fallback: '已撤销删除');
  String get undoFailed => _t('undoFailed', fallback: '撤销失败');
  String get currentStatus => _t('currentStatus', fallback: '当前：{status}');
  String get alreadyPrivate => _t('alreadyPrivate', fallback: '当前已是私有');
  String get alreadyPublic => _t('alreadyPublic', fallback: '当前已是公开');
  String get setToPrivate => _t('setToPrivate', fallback: '已设为私有');
  String get setToPublic => _t('setToPublic', fallback: '已设为公开');
  String get setFailed => _t('setFailed', fallback: '设置失败');
  String get fullText => _t('fullText', fallback: '全文');
  String get referencedNoteNotFound => _t('referencedNoteNotFound', fallback: '引用的笔记不存在或已被删除 (ID: {id})');
  String get cancelSuccess => _t('cancelSuccess', fallback: '取消成功');
  String get setSuccess => _t('setSuccess', fallback: '设置成功');
  String get editorPlaceholder => _t('editorPlaceholder', fallback: '现在的想法是...');
  String get voiceListening => _t('voiceListening', fallback: '正在聆听...');
  String get voiceRecognizing => _t('voiceRecognizing', fallback: '识别中');
  String get clickToStop => _t('clickToStop', fallback: '点击停止');
  String get microphonePermissionRequired => _t('microphonePermissionRequired', fallback: '需要麦克风权限才能使用语音识别');
  String get referenceCreationFailed => _t('referenceCreationFailed', fallback: '创建引用关系失败');
  String get searchNoteContent => _t('searchNoteContent', fallback: '搜索笔记内容...');
  String get createNotesFirstToReference => _t('createNotesFirstToReference', fallback: '先创建一些笔记再来建立引用关系');
  String get foundNotesCount => _t('foundNotesCount', fallback: '找到 {count} 个笔记');
  String get logoutDataPrompt => _t('logoutDataPrompt', fallback: '退出登录前，请选择如何处理本地数据：');
  String get functionMenu => _t('functionMenu', fallback: '功能菜单');
  String get loadedAll => _t('loadedAll', fallback: '已加载全部 {count} 条笔记');
  String get serverError => _t('serverError', fallback: '服务器错误');
  String get unknownError => _t('unknownError', fallback: '未知错误');
  String get copySuccess => _t('copySuccess', fallback: '已复制');
  
  // 隐私政策相关
  String get userAgreementAndPrivacy => _t('userAgreementAndPrivacy', fallback: '用户协议与隐私政策');
  String get disagree => _t('disagree', fallback: '不同意');
  String get agree => _t('agree', fallback: '同意');
  String get welcomeToApp => _t('welcomeToApp', fallback: '欢迎使用InkRoot！\n\n我们非常重视您的隐私保护和个人信息安全。在使用我们的服务前，请您仔细阅读并充分理解');
  String get and => locale.languageCode == 'zh' ? '和' : 'and';
  String get agreeText => _t('agreeText', fallback: '。\n\n点击"同意"即表示您已阅读并同意上述协议的全部内容。');
  
  // 更新对话框相关
  String get mustUpdateMessage => _t('mustUpdateMessage', fallback: '此为重要更新，必须更新后才能继续使用');
  String get downloading => _t('downloading', fallback: '正在下载...');
  String get laterUpdate => _t('laterUpdate', fallback: '稍后更新');
  String get downloadComplete => _t('downloadComplete', fallback: '下载完成！请安装更新包');
  
  // 标签相关
  String get relatedTags => _t('relatedTags', fallback: '相关标签');
  String get statistics => _t('statistics', fallback: '统计图表');
  String get rename => _t('rename', fallback: '重命名');
  String get relatedTagsRecommendation => _t('relatedTagsRecommendation', fallback: '相关标签推荐');
  String get noRelatedTags => _t('noRelatedTags', fallback: '暂无相关标签');
  String get addMoreNotesForAI => _t('addMoreNotesForAI', fallback: '添加更多包含该标签的笔记，\nAI将为您推荐相关标签');
  String get tagStatistics => _t('tagStatistics', fallback: '标签统计');
  String get noteCount => _t('noteCount', fallback: '笔记数');
  String get creationMonths => _t('creationMonths', fallback: '创建月数');
  String get recentSixMonthsTrend => _t('recentSixMonthsTrend', fallback: '最近6个月趋势');
  String get noStatisticsData => _t('noStatisticsData', fallback: '暂无统计数据');
  String get renameTag => _t('renameTag', fallback: '重命名标签');
  String get enterNewTagName => _t('enterNewTagName', fallback: '输入新标签名');
  String get deleteTag => _t('deleteTag', fallback: '删除标签');
  String get deleteTagConfirm => _t('deleteTagConfirm', fallback: '确定要删除此标签吗？删除后，该标签下的所有笔记将失去此标签。');
  String get deleteTagSimpleConfirm => _t('deleteTagSimpleConfirm', fallback: '确定要删除此标签吗？');
  
  // 导入导出相关
  String get localBackupRestore => _t('localBackupRestore', fallback: '本地备份与恢复');
  String get localBackupDescription => _t('localBackupDescription', fallback: '将笔记数据导出为本地文件，支持从备份文件恢复数据');
  String get flomoImport => _t('flomoImport', fallback: 'Flomo 笔记导入');
  String get flomoImportDescription => _t('flomoImportDescription', fallback: '支持从 Flomo 导出的 HTML 文件批量导入笔记内容');
  String get backupTip => _t('backupTip', fallback: '💡 数据安全提示：建议定期备份笔记数据。导入前请确认文件格式正确，避免数据丢失。');
  String get browserExtension => _t('browserExtension', fallback: 'Memos 浏览器扩展');
  String get browserExtensionDescription => _t('browserExtensionDescription', fallback: '第三方浏览器扩展程序，支持 Chrome/Edge，可快速收集网页内容至 Memos');
  
  // 标签页面相关
  String get noTagsYet => _t('noTagsYet', fallback: '还没有任何标签');
  String get tagsHelp => _t('tagsHelp', fallback: '标签可以帮助你更好地组织和查找笔记');
  String get howToUseTags => _t('howToUseTags', fallback: '如何使用标签');
  String get expandAll => _t('expandAll', fallback: '展开所有');
  String get collapseAll => _t('collapseAll', fallback: '收起所有');
  String get expandAllTags => _t('expandAllTags', fallback: '展开全部');
  String expandAllTagsWithCount(int count) {
    final template = _t('expandAllTagsWithCount', fallback: '展开全部 ({count}个标签)');
    return template.replaceAll('{count}', count.toString());
  }
  String get startWriting => _t('startWriting', fallback: '开始写笔记');
  String get noMatchingTags => _t('noMatchingTags', fallback: '未找到匹配的标签');
  
  // Flomo导入页面相关
  String get flomoNoteImport => _t('flomoNoteImport', fallback: 'Flomo 笔记导入');
  String get importInstructions => _t('importInstructions', fallback: '导入说明');
  String get flomoImportStep1 => _t('flomoImportStep1', fallback: '1. 在 Flomo 应用中，进入"设置 > 账号详情 > 导出所有数据"');
  String get flomoImportStep2 => _t('flomoImportStep2', fallback: '2. 导出后会得到一个包含 HTML 文件和 file 目录的文件夹');
  String get flomoImportStep3 => _t('flomoImportStep3', fallback: '3. 📁 将整个导出文件夹保存到"文件"App中（iCloud Drive或本地）');
  String get flomoImportStep4 => _t('flomoImportStep4', fallback: '4. 点击下方"选择Flomo导出文件夹"按钮');
  String get flomoImportStep5 => _t('flomoImportStep5', fallback: '5. 标签会自动识别（以 # 开头的文本）');
  String get flomoExportWarning => _t('flomoExportWarning', fallback: 'Flomo 每 7 天只能导出一次，请妥善保管导出的文件');
  String get selectFile => _t('selectFile', fallback: '选择文件');
  String get selectFlomoExportFolder => _t('selectFlomoExportFolder', fallback: '选择 Flomo 导出文件夹');
  String get selectFlomoHtmlFile => _t('selectFlomoHtmlFile', fallback: '选择 Flomo HTML 文件');
  String get alreadyInTagPage => _t('alreadyInTagPage', fallback: '已在标签页中');
  String get imageFileMissing => _t('imageFileMissing', fallback: '图片文件缺失');
  String get possibleReasons => _t('possibleReasons', fallback: '可能原因：');
  String get htmlAndFileSeparated => _t('htmlAndFileSeparated', fallback: '• HTML文件和file目录不在同一位置');
  String get fileFolderMoved => _t('fileFolderMoved', fallback: '• file目录被移动或删除');
  String get exportDataIncomplete => _t('exportDataIncomplete', fallback: '• 导出数据不完整');
  String get solutionTip => _t('solutionTip', fallback: '💡 解决方法：');
  String get ensureHtmlAndFile => _t('ensureHtmlAndFile', fallback: '1. 确保Flomo导出的HTML文件和file目录在同一文件夹中');
  String get reselectFolder => _t('reselectFolder', fallback: '2. 重新点击"选择Flomo导出文件夹"，选择包含HTML和file目录的整个文件夹');
  String get doNotMoveFiles => _t('doNotMoveFiles', fallback: '3. 不要单独移动HTML文件或file目录');
  String get preserveTags => _t('preserveTags', fallback: '保留标签');
  String get preserveTagsDesc => _t('preserveTagsDesc', fallback: '将 Flomo 中的 # 标签导入为笔记标签');
  String get preserveTime => _t('preserveTime', fallback: '保留时间');
  String get preserveTimeDesc => _t('preserveTimeDesc', fallback: '尽可能保留笔记的创建时间');
  String get importAsNew => _t('importAsNew', fallback: '作为新笔记导入');
  String get importAsNewDesc => _t('importAsNewDesc', fallback: '所有导入的笔记将作为新笔记添加');
  String get importImages => _t('importImages', fallback: '导入图片');
  String get importImagesDesc => _t('importImagesDesc', fallback: '导入笔记中的图片附件（图片会被复制到本地存储）');
  String get smartDeduplication => _t('smartDeduplication', fallback: '智能去重');
  String get detectDuplicates => _t('detectDuplicates', fallback: '检测重复笔记');
  String get detectDuplicatesDesc => _t('detectDuplicatesDesc', fallback: '基于内容和时间智能识别重复笔记');
  String get whenDuplicatesFound => _t('whenDuplicatesFound', fallback: '发现重复笔记时：');
  String get autoSkip => _t('autoSkip', fallback: '自动跳过');
  String get autoSkipDesc => _t('autoSkipDesc', fallback: '静默跳过所有重复笔记');
  String get askMe => _t('askMe', fallback: '询问我');
  String get askMeDesc => _t('askMeDesc', fallback: '让我选择要导入哪些重复笔记（推荐）');
  String get importAll => _t('importAll', fallback: '全部导入');
  String get importAllDesc => _t('importAllDesc', fallback: '忽略重复检测，全部作为新笔记导入');
  String get notePreview => _t('notePreview', fallback: '笔记预览（前5条）');
  String get dirNotExist => _t('dirNotExist', fallback: '目录不存在');
  String get noHtmlFileInFolder => _t('noHtmlFileInFolder', fallback: '该文件夹中没有找到HTML文件');
  String get selectFolderFailed => _t('selectFolderFailed', fallback: '选择文件夹失败');
  String get fileNotExist => _t('fileNotExist', fallback: '文件不存在');
  String get selectFileFailed => _t('selectFileFailed', fallback: '选择文件失败');
  String get previewFileFailed => _t('previewFileFailed', fallback: '预览文件失败');
  String get noValidNotesInFile => _t('noValidNotesInFile', fallback: '文件中没有找到有效的笔记内容');
  String get pleaseSelectFileFirst => _t('pleaseSelectFileFirst', fallback: '请先选择文件');
  String get userCancelledImport => _t('userCancelledImport', fallback: '用户取消导入');
  String get importFailed => _t('importFailed', fallback: '导入失败');
  String get importSuccessful => _t('importSuccessful', fallback: '导入成功');
  String get importedFromFlomo => _t('importedFromFlomo', fallback: '成功从 Flomo 导入：');
  String get exactMatch => _t('exactMatch', fallback: '精确匹配');
  String get contentOnly => _t('contentOnly', fallback: '内容相同');
  String get time => _t('time', fallback: '时间');
  String get duplicatesFoundTitle => _t('duplicatesFoundTitle', fallback: '发现重复笔记');
  String get selectedToImportHint => _t('selectedToImportHint', fallback: '选中的笔记将被导入，未选中的将跳过');
  String get selectAll => _t('selectAll', fallback: '全选');
  String get deselectAll => _t('deselectAll', fallback: '取消全选');
  String get skipAll => _t('skipAll', fallback: '全部跳过');
  String get toImport => _t('toImport', fallback: '待导入');
  String get existing => _t('existing', fallback: '已存在');
  String get viewSkippedDuplicates => _t('viewSkippedDuplicates', fallback: '查看跳过的重复笔记');
  String get skippedDuplicates => _t('skippedDuplicates', fallback: '跳过的重复笔记');
  
  // 标签页面使用提示
  String get createTagByTyping => _t('createTagByTyping', fallback: '在笔记中输入 #标签名 创建标签');
  String get hierarchicalTags => _t('hierarchicalTags', fallback: '使用 / 创建层级标签，如 #工作/项目A');
  String get hierarchicalTagsShort => _t('hierarchicalTagsShort', fallback: '使用 / 创建层级标签（如 #工作/项目A）');
  String get clickTagToView => _t('clickTagToView', fallback: '点击标签查看所有相关笔记');
  
  // WebDAV设置页面
  String get passwordAppSpecific => _t('passwordAppSpecific', fallback: '密码（应用专用密码）');
  String get notLoginPassword => _t('notLoginPassword', fallback: '⚠️ 不是登录密码！需在服务商处生成');
  String get clickHelpIcon => _t('clickHelpIcon', fallback: '💡 点击右上角 ? 查看如何获取');
  
  // 偏好设置页面
  String get sidebarCustomization => _t('sidebarCustomization', fallback: '侧边栏');
  String get adjustMenuDisplay => _t('adjustMenuDisplay', fallback: '调整菜单显示与排序');
  
  // 侧边栏自定义页面
  String get customizeSidebar => _t('customizeSidebar', fallback: '自定义侧边栏');
  String get headerComponents => _t('headerComponents', fallback: '头部组件');
  String get showProfileCenter => _t('showProfileCenter', fallback: '显示个人中心');
  String get avatarUsernameLogin => _t('avatarUsernameLogin', fallback: '头像、用户名和登录按钮');
  String get showActivityLog => _t('showActivityLog', fallback: '显示活动记录');
  String get showNoteCreationCalendar => _t('showNoteCreationCalendar', fallback: '展示笔记创建活动日历');
  String get menuItems => _t('menuItems', fallback: '菜单项');
  String get longPressDragToReorder => _t('longPressDragToReorder', fallback: '长按拖动可调整顺序');
  String get confirmResetSidebar => _t('confirmResetSidebar', fallback: '确定要恢复侧边栏的默认设置吗？\n\n这将重置所有菜单项的显示状态和排序。');
  String get defaultHome => _t('defaultHome', fallback: '默认首页');
  String get allNotesIsDefaultHome => _t('allNotesIsDefaultHome', fallback: '💡 "全部笔记"是默认首页，无法隐藏或移动');
  String get restoreDefaultSettings => _t('restoreDefaultSettings', fallback: '恢复默认设置');
  String get profileOrSettingsRequired => _t('profileOrSettingsRequired', fallback: '个人中心和设置至少保留一个');
  String get defaultSettingsRestored => _t('defaultSettingsRestored', fallback: '已恢复默认设置');
  String get sidebarConfigSaved => _t('sidebarConfigSaved', fallback: '侧边栏配置已保存');

  // ===== 批注功能 =====
  String get annotations => locale.languageCode == 'zh' ? '批注' : 'Annotations';
  String get viewAnnotations => locale.languageCode == 'zh' ? '查看批注' : 'View Annotations';
  String get addAnnotation => locale.languageCode == 'zh' ? '添加批注' : 'Add Annotation';
  String get editAnnotation => locale.languageCode == 'zh' ? '编辑批注' : 'Edit Annotation';
  String get deleteAnnotation => locale.languageCode == 'zh' ? '删除批注' : 'Delete Annotation';
  String get annotationType => locale.languageCode == 'zh' ? '批注类型' : 'Annotation Type';
  String get annotationContent => locale.languageCode == 'zh' ? '批注内容' : 'Annotation Content';
  String get annotationPlaceholder => locale.languageCode == 'zh' 
      ? '在这里写下你的批注...' 
      : 'Write your annotation here...';
  String get annotationEditPlaceholder => locale.languageCode == 'zh' 
      ? '修改批注内容...' 
      : 'Edit annotation content...';
  String get noAnnotations => locale.languageCode == 'zh' ? '还没有批注' : 'No annotations yet';
  String get noAnnotationsHint => locale.languageCode == 'zh' 
      ? '点击上方按钮添加批注，记录你的思考' 
      : 'Click the button above to add annotations';
  String get annotationAdded => locale.languageCode == 'zh' ? '批注已添加' : 'Annotation added';
  String get annotationUpdated => locale.languageCode == 'zh' ? '批注已更新' : 'Annotation updated';
  String get annotationDeleted => locale.languageCode == 'zh' ? '批注已删除' : 'Annotation deleted';
  String get confirmDeleteAnnotation => locale.languageCode == 'zh' 
      ? '确定要删除这条批注吗？' 
      : 'Are you sure you want to delete this annotation?';
  String get annotationCount => locale.languageCode == 'zh' ? '条批注' : 'annotations';
  String get showResolved => locale.languageCode == 'zh' ? '显示已解决' : 'Show resolved';
  String get markAsResolved => locale.languageCode == 'zh' ? '标记为已解决' : 'Mark as resolved';
  String get resolved => locale.languageCode == 'zh' ? '已解决' : 'Resolved';
  String get markedAsResolved => locale.languageCode == 'zh' ? '已标记为已解决' : 'Marked as resolved';
  String get locatedToAnnotation => locale.languageCode == 'zh' ? '已定位到批注' : 'Located to annotation';
  String get replies => locale.languageCode == 'zh' ? '条回复' : 'replies';
  String get justNow => locale.languageCode == 'zh' ? '刚刚' : 'Just now';
  String minutesAgo(int minutes) => locale.languageCode == 'zh' 
      ? '$minutes 分钟前' 
      : '$minutes minutes ago';
  String hoursAgo(int hours) => locale.languageCode == 'zh' 
      ? '$hours 小时前' 
      : '$hours hours ago';
  String daysAgo(int days) => locale.languageCode == 'zh' 
      ? '$days 天前' 
      : '$days days ago';
  
  // 批注类型
  String get annotationTypeComment => locale.languageCode == 'zh' ? '评论' : 'Comment';
  String get annotationTypeQuestion => locale.languageCode == 'zh' ? '问题' : 'Question';
  String get annotationTypeIdea => locale.languageCode == 'zh' ? '想法' : 'Idea';
  String get annotationTypeImportant => locale.languageCode == 'zh' ? '重要' : 'Important';
  String get annotationTypeTodo => locale.languageCode == 'zh' ? '待办' : 'To-do';
  
  // 筛选
  String get filterByType => locale.languageCode == 'zh' ? '按类型筛选' : 'Filter by type';
  String get noAnnotationsOfType => locale.languageCode == 'zh' 
      ? '没有此类型的批注' 
      : 'No annotations of this type';
  
  // AI设置 - 自定义提示词
  String get customPrompts => locale.languageCode == 'zh' ? '自定义提示词' : 'Custom Prompts';
  String get enableCustomPrompts => locale.languageCode == 'zh' ? '启用自定义提示词' : 'Enable Custom Prompts';
  String get insightPrompt => locale.languageCode == 'zh' ? '洞察提示词' : 'Insight Prompt';
  String get reviewPrompt => locale.languageCode == 'zh' ? '点评提示词' : 'Review Prompt';
  String get continuationPrompt => locale.languageCode == 'zh' ? '续写提示词' : 'Continuation Prompt';
  String get tagInsightPrompt => locale.languageCode == 'zh' ? '标签洞察提示词' : 'Tag Insight Prompt';
  String get tagRecommendationPrompt => locale.languageCode == 'zh' ? '标签推荐提示词' : 'Tag Recommendation Prompt';
  String get insightPromptHint => locale.languageCode == 'zh' 
      ? '自定义AI洞察的提示词，留空使用默认提示词' 
      : 'Customize AI insight prompt, leave empty to use default';
  String get reviewPromptHint => locale.languageCode == 'zh' 
      ? '自定义AI点评的提示词，留空使用默认提示词' 
      : 'Customize AI review prompt, leave empty to use default';
  String get continuationPromptHint => locale.languageCode == 'zh' 
      ? '自定义AI续写的提示词，留空使用默认提示词' 
      : 'Customize AI continuation prompt, leave empty to use default';
  String get tagInsightPromptHint => locale.languageCode == 'zh' 
      ? '自定义标签洞察的提示词，留空使用默认提示词' 
      : 'Customize tag insight prompt, leave empty to use default';
  String get tagRecommendationPromptHint => locale.languageCode == 'zh' 
      ? '自定义标签推荐的提示词，留空使用默认提示词' 
      : 'Customize tag recommendation prompt, leave empty to use default';
  
  // 引用关系侧边栏
  String get referencesCount => locale.languageCode == 'zh' ? '个引用' : 'references';
  String get referencedNotes => locale.languageCode == 'zh' ? '引用的笔记' : 'Referenced Notes';
  String get referencedByNotes => locale.languageCode == 'zh' ? '被引用' : 'Referenced By';
  String get referenced => locale.languageCode == 'zh' ? '引用' : 'Referenced';
  String get referencedBy => locale.languageCode == 'zh' ? '被引用' : 'Referenced By';
  String get noReferencesYet => locale.languageCode == 'zh' ? '还没有引用关系' : 'No references yet';
  String get noOutgoingReferences => locale.languageCode == 'zh' ? '没有引用其他笔记' : 'No outgoing references';
  String get noIncomingReferences => locale.languageCode == 'zh' ? '没有被其他笔记引用' : 'No incoming references';
  
  // Notion 同步
  String get notionSync => locale.languageCode == 'zh' ? 'Notion 数据同步' : 'Notion Sync';
  String get notionSyncDescription => locale.languageCode == 'zh' ? '与 Notion 工作区实时同步笔记数据，支持双向同步与自动同步功能' : 'Real-time sync with Notion workspace, supports bidirectional and auto-sync';
  String get notionAccessTokenHint => locale.languageCode == 'zh' 
      ? '输入 Notion Integration Token' 
      : 'Enter Notion Integration Token';
  String get notionTestConnection => locale.languageCode == 'zh' ? '测试' : 'Test';
  String get notionSelectDatabase => locale.languageCode == 'zh' ? '选择数据库' : 'Select Database';
  String get notionSelectDatabaseHint => locale.languageCode == 'zh' 
      ? '选择一个 Notion 数据库' 
      : 'Select a Notion database';
  String get notionSyncDirection => locale.languageCode == 'zh' ? '同步方向' : 'Sync Direction';
  String get notionSyncToNotion => locale.languageCode == 'zh' ? '仅同步到 Notion' : 'To Notion Only';
  String get notionSyncToNotionDesc => locale.languageCode == 'zh' 
      ? '本地笔记 → Notion' 
      : 'Local → Notion';
  String get notionSyncFromNotion => locale.languageCode == 'zh' ? '仅从 Notion 同步' : 'From Notion Only';
  String get notionSyncFromNotionDesc => locale.languageCode == 'zh' 
      ? 'Notion → 本地笔记' 
      : 'Notion → Local';
  String get notionSyncBoth => locale.languageCode == 'zh' ? '双向同步' : 'Bidirectional';
  String get notionSyncBothDesc => locale.languageCode == 'zh' 
      ? '本地笔记 ↔ Notion' 
      : 'Local ↔ Notion';
  String get notionAutoSync => locale.languageCode == 'zh' ? '自动同步' : 'Auto Sync';
  String get notionAutoSyncDesc => locale.languageCode == 'zh' 
      ? '笔记创建或编辑时自动同步至 Notion' 
      : 'Auto sync when creating or modifying notes';
  String get notionSyncNow => locale.languageCode == 'zh' ? '立即同步' : 'Sync Now';
  String get notionLastSync => locale.languageCode == 'zh' ? '最后同步' : 'Last Sync';
  String get notionEnableSync => locale.languageCode == 'zh' ? '启用 Notion 同步' : 'Enable Notion Sync';
  String get notionEnableSyncDesc => locale.languageCode == 'zh' 
      ? '自动同步笔记到 Notion' 
      : 'Auto sync notes to Notion';
  String get notionConnectionSuccess => locale.languageCode == 'zh' ? '✅ 连接成功！' : '✅ Connection successful!';
  String get notionConnectionFailed => locale.languageCode == 'zh' 
      ? '❌ 连接失败，请检查令牌是否正确' 
      : '❌ Connection failed, please check your token';
  String get notionSyncFailed => locale.languageCode == 'zh' ? '同步失败' : 'Sync failed';
  String get notionHowToGetToken => locale.languageCode == 'zh' 
      ? '如何获取 Notion 访问令牌？' 
      : 'How to get Notion access token?';
  String get notionTokenInstructions => locale.languageCode == 'zh'
      ? '1. 访问 https://www.notion.so/my-integrations\n'
        '2. 点击"New integration"创建集成\n'
        '3. 复制"Internal Integration Token"\n'
        '4. 在 Notion 中分享数据库给该集成'
      : '1. Visit https://www.notion.so/my-integrations\n'
        '2. Click "New integration" to create integration\n'
        '3. Copy "Internal Integration Token"\n'
        '4. Share database with the integration in Notion';
  
  // Notion 属性映射
  String get notionFieldMapping => locale.languageCode == 'zh' ? '字段映射' : 'Field Mapping';
  String get notionFieldMappingDescription => locale.languageCode == 'zh' 
      ? '配置笔记字段如何映射到 Notion 属性' 
      : 'Configure how note fields map to Notion properties';
  String get notionNoteTitle => locale.languageCode == 'zh' ? '笔记标题' : 'Note Title';
  String get notionNoteTags => locale.languageCode == 'zh' ? '笔记标签' : 'Note Tags';
  String get notionNoteCreated => locale.languageCode == 'zh' ? '创建时间' : 'Created Time';
  String get notionNoteUpdated => locale.languageCode == 'zh' ? '更新时间' : 'Updated Time';
  String get notionNoteContent => locale.languageCode == 'zh' ? '笔记内容' : 'Note Content';
  String get notionMapsTo => locale.languageCode == 'zh' ? '映射到' : 'Maps to';
  String get notionPropertyType => locale.languageCode == 'zh' ? '属性类型' : 'Property Type';
  String get notionNoProperty => locale.languageCode == 'zh' ? '不映射' : 'No Mapping';
  String get notionAutoDetected => locale.languageCode == 'zh' ? '自动检测' : 'Auto Detected';
  String get notionConfigureMapping => locale.languageCode == 'zh' ? '配置映射' : 'Configure Mapping';
  String get notionUseDefaultMapping => locale.languageCode == 'zh' ? '使用默认映射' : 'Use Default Mapping';
  String get notionMappingRequired => locale.languageCode == 'zh' ? '必需' : 'Required';
  String get notionMappingOptional => locale.languageCode == 'zh' ? '可选' : 'Optional';
  String get notionDatabaseProperties => locale.languageCode == 'zh' ? '数据库属性' : 'Database Properties';
  String get notionPropertyName => locale.languageCode == 'zh' ? '属性名称' : 'Property Name';
  String get notionContentMappingHint => locale.languageCode == 'zh' ? '不映射则写入页面正文' : 'If not mapped, write to page body';
  
  // 帮助对话框
  String get notionHelpTitle => locale.languageCode == 'zh' ? '常见问题' : 'FAQ';
  String get notionHelpKnowIt => locale.languageCode == 'zh' ? '知道了' : 'Got it';
  
  String get notionFaqSyncFailTitle => locale.languageCode == 'zh' ? '❓ 同步失败怎么办？' : '❓ What if sync fails?';
  String get notionFaqSyncFailContent => locale.languageCode == 'zh' 
      ? '1. 检查字段映射是否完整（标题必须映射）\n2. 确认已在 Notion 中分享数据库给集成\n3. 查看控制台日志了解具体错误\n4. 尝试完全重启应用'
      : '1. Check if field mapping is complete (title is required)\n2. Confirm database is shared with integration in Notion\n3. Check console logs for specific errors\n4. Try completely restarting the app';
  
  String get notionFaqSelectTagTitle => locale.languageCode == 'zh' ? '❓ 标签属性是单选怎么办？' : '❓ What if tag property is single-select?';
  String get notionFaqSelectTagContent => locale.languageCode == 'zh'
      ? '如果你的 Notion 数据库中标签属性是"单选"类型：\n• 只会同步第一个标签\n• 建议在 Notion 中改为"多选"类型'
      : 'If your Notion database tag property is "single-select":\n• Only the first tag will be synced\n• Recommend changing to "multi-select" in Notion';
  
  String get notionFaqSystemTimeTitle => locale.languageCode == 'zh' ? '❓ 创建时间/更新时间无法写入？' : '❓ Cannot write created/updated time?';
  String get notionFaqSystemTimeContent => locale.languageCode == 'zh'
      ? '如果映射到系统属性（created_time、last_edited_time）：\n• 这些是只读属性，由 Notion 自动管理\n• 建议映射到普通的"日期"类型属性'
      : 'If mapped to system properties (created_time, last_edited_time):\n• These are read-only, managed by Notion\n• Recommend mapping to regular "date" type properties';
  
  String get notionFaqGlobalKeyTitle => locale.languageCode == 'zh' ? '❓ GlobalKey 错误怎么办？' : '❓ What about GlobalKey error?';
  String get notionFaqGlobalKeyContent => locale.languageCode == 'zh'
      ? '这是 Flutter 热重载的已知问题：\n• 完全停止应用（按 q）\n• 重新运行 flutter run -d macos'
      : 'This is a known Flutter hot reload issue:\n• Stop the app completely (press q)\n• Re-run flutter run -d macos';
  
  String get notionFaqViewLogsTitle => locale.languageCode == 'zh' ? '❓ 如何查看详细日志？' : '❓ How to view detailed logs?';
  String get notionFaqViewLogsContent => locale.languageCode == 'zh'
      ? '在终端中查看以下标记的日志：\n• 📊 数据库信息\n• 🔍 字段映射\n• 📤 同步过程\n• ✅/❌ 成功/失败'
      : 'Check terminal for logs with these markers:\n• 📊 Database info\n• 🔍 Field mapping\n• 📤 Sync process\n• ✅/❌ Success/Failure';
  
  // 新增的国际化字符串
  String get notionSave => locale.languageCode == 'zh' ? '保存' : 'Save';
  String get notionTest => locale.languageCode == 'zh' ? '测试' : 'Test';
  String get notionAccessToken => locale.languageCode == 'zh' ? '访问令牌' : 'Access Token';
  String get notionAutoSyncWhen => locale.languageCode == 'zh' ? '笔记创建或编辑时自动同步至 Notion' : 'Auto sync when creating or modifying notes';
  String get notionSyncNowButton => locale.languageCode == 'zh' ? '立即同步' : 'Sync Now';
  String notionLastSyncTime(String time) => locale.languageCode == 'zh' ? '最后同步于: $time' : 'Last synced: $time';
  String get notionSyncingToNotion => locale.languageCode == 'zh' ? '同步到 Notion' : 'Syncing to Notion';
  String get notionSyncingFromNotion => locale.languageCode == 'zh' ? '从 Notion 同步' : 'Syncing from Notion';
  String get notionSyncingProgress => locale.languageCode == 'zh' ? '正在同步' : 'Syncing';
  String get notionPleaseEnableSync => locale.languageCode == 'zh' ? '请先启用 Notion 同步' : 'Please enable Notion sync first';
  String get notionPleaseSelectDatabase => locale.languageCode == 'zh' ? '请选择数据库' : 'Please select a database';
  String get notionPleaseEnterToken => locale.languageCode == 'zh' ? '请输入访问令牌' : 'Please enter access token';
  String get notionSettingsSaved => locale.languageCode == 'zh' ? '✅ 设置已保存' : '✅ Settings saved';
  String get notionSaveSettingsFailed => locale.languageCode == 'zh' ? '保存设置失败' : 'Failed to save settings';
  String notionSyncComplete(int success, int failed) => locale.languageCode == 'zh' 
      ? '同步完成: 成功 $success 条，失败 $failed 条' 
      : 'Sync complete: $success succeeded, $failed failed';
  String notionSyncSuccess(int count) => locale.languageCode == 'zh' 
      ? '同步成功！已同步 $count 条笔记' 
      : 'Sync successful! $count notes synced';
  String get notionTestConnectionFailed => locale.languageCode == 'zh' ? '连接测试失败' : 'Connection test failed';
  String get notionNoDatabaseFound => locale.languageCode == 'zh' ? '未找到任何数据库，请确保已在 Notion 中分享数据库给集成' : 'No databases found. Please share a database with the integration in Notion';
  String get notionLoadDatabasesFailed => locale.languageCode == 'zh' ? '加载数据库列表失败' : 'Failed to load databases';
  
  // 微信读书笔记导入
  String get wereadImportTitle => locale.languageCode == 'zh' ? '微信读书笔记导入' : 'WeRead Notes Import';
  String get wereadImportDescription => locale.languageCode == 'zh' ? '支持从微信读书导出的笔记文本批量导入，自动识别书籍信息和标注内容' : 'Import notes from WeRead with automatic book info and highlight recognition';
  
  // Obsidian 同步
  String get obsidianSync => locale.languageCode == 'zh' ? 'Obsidian 数据同步' : 'Obsidian Sync';
  String get obsidianSyncDescription => locale.languageCode == 'zh' ? '通过第三方插件实现与 Obsidian 笔记应用的双向同步，支持每日笔记自动集成' : 'Bidirectional sync with Obsidian via third-party plugin, supports daily notes integration';
  String get wereadUsageInstructions => locale.languageCode == 'zh' ? '使用说明' : 'Usage Instructions';
  String get wereadInstructions => locale.languageCode == 'zh'
      ? '1. 在微信读书 App 中打开一本书\n2. 点击右上角"..."→"笔记"\n3. 点击"分享"→"复制为文本"\n4. 粘贴到下方输入框\n5. 点击"检查"验证格式\n6. 可选：展开"高级选项"自定义设置\n7. 点击右上角"导入"完成导入'
      : '1. Open a book in WeRead App\n2. Tap "..." → "Notes" in top right\n3. Tap "Share" → "Copy as Text"\n4. Paste into the input box below\n5. Tap "Check" to verify format\n6. Optional: Expand "Advanced Options" to customize\n7. Tap "Import" in top right to complete';
  String get wereadPasteHint => locale.languageCode == 'zh'
      ? '粘贴微信读书笔记...\n\n例如：\n《书名》\n\n35个笔记\n点评\n\n第一章 标题\n\n笔记内容...'
      : 'Paste WeRead notes here...\n\nExample:\n《Book Title》\n\n35 notes\nReview\n\nChapter 1 Title\n\nNote content...';
  String get wereadCheckResult => locale.languageCode == 'zh' ? '检查结果' : 'Check Result';
  String wereadBookInfo(String title, int noteCount, int chapterCount) => locale.languageCode == 'zh'
      ? '书名: $title\n笔记数: $noteCount 条\n章节数: $chapterCount 个'
      : 'Book: $title\nNotes: $noteCount\nChapters: $chapterCount';
  String get wereadAdvancedOptions => locale.languageCode == 'zh' ? '高级选项' : 'Advanced Options';
  String get wereadShowBookTitle => locale.languageCode == 'zh' ? '显示书名来源' : 'Show Book Source';
  String get wereadShowBookTitleDesc => locale.languageCode == 'zh' ? '在笔记末尾显示"来自《书名》"' : 'Show "From 《Book》" at note end';
  String get wereadShowChapter => locale.languageCode == 'zh' ? '显示章节信息' : 'Show Chapter Info';
  String get wereadShowChapterDesc => locale.languageCode == 'zh' ? '显示笔记所在章节' : 'Show note chapter';
  String get wereadShowReview => locale.languageCode == 'zh' ? '显示点评内容' : 'Show Review';
  String get wereadShowReviewDesc => locale.languageCode == 'zh' ? '显示笔记的点评部分' : 'Show note review section';
  String get wereadCustomTags => locale.languageCode == 'zh' ? '自定义标签' : 'Custom Tags';
  String get wereadCustomTagsDesc => locale.languageCode == 'zh' ? '点击上方添加按钮添加标签，默认使用"微信读书"和书名作为标签' : 'Tap add button above to add tags. Default: "WeRead" and book title';
  String get wereadClear => locale.languageCode == 'zh' ? '清空' : 'Clear';
  String get wereadCheck => locale.languageCode == 'zh' ? '检查' : 'Check';
  String get wereadImport => locale.languageCode == 'zh' ? '导入' : 'Import';
  String get wereadPleasePasteContent => locale.languageCode == 'zh' ? '请粘贴微信读书笔记内容' : 'Please paste WeRead notes content';
  String wereadCheckSuccess(int count) => locale.languageCode == 'zh' ? '✅ 检查通过！共 $count 条笔记' : '✅ Check passed! $count notes found';
  String get wereadParseFailed => locale.languageCode == 'zh' ? '解析失败' : 'Parse failed';
  String get wereadPleaseCheckFirst => locale.languageCode == 'zh' ? '请先预览笔记' : 'Please check notes first';
  String wereadImportSuccess(int count) => locale.languageCode == 'zh' ? '成功导入 $count 条笔记！' : 'Successfully imported $count notes!';
  String get wereadImportFailed => locale.languageCode == 'zh' ? '导入失败' : 'Import failed';
}



class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizationsSimple> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizationsSimple> load(Locale locale) async =>
      AppLocalizationsSimple(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
