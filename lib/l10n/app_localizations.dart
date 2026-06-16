import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'墨鸣笔记'**
  String get appTitle;

  /// 偏好设置标题
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get preferences;

  /// 外观设置分类
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// 主题选择
  ///
  /// In zh, this message translates to:
  /// **'主题选择'**
  String get themeSelection;

  /// 跟随系统主题
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// 浅色主题
  ///
  /// In zh, this message translates to:
  /// **'纸白'**
  String get themeLight;

  /// 深色主题
  ///
  /// In zh, this message translates to:
  /// **'幽谷'**
  String get themeDark;

  /// 跟随系统描述
  ///
  /// In zh, this message translates to:
  /// **'跟随系统设置'**
  String get themeSystemDesc;

  /// 浅色主题描述
  ///
  /// In zh, this message translates to:
  /// **'浅色主题'**
  String get themeLightDesc;

  /// 深色主题描述
  ///
  /// In zh, this message translates to:
  /// **'深色主题'**
  String get themeDarkDesc;

  /// 字体大小
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get fontSize;

  /// 极小字体
  ///
  /// In zh, this message translates to:
  /// **'极小'**
  String get fontSizeMini;

  /// 小字体
  ///
  /// In zh, this message translates to:
  /// **'小'**
  String get fontSizeSmall;

  /// 标准字体
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get fontSizeNormal;

  /// 大字体
  ///
  /// In zh, this message translates to:
  /// **'大'**
  String get fontSizeLarge;

  /// 特大字体
  ///
  /// In zh, this message translates to:
  /// **'特大'**
  String get fontSizeXLarge;

  /// 极小字体描述
  ///
  /// In zh, this message translates to:
  /// **'最小字体，节省空间'**
  String get fontSizeMiniDesc;

  /// 小字体描述
  ///
  /// In zh, this message translates to:
  /// **'适合阅读大量文字'**
  String get fontSizeSmallDesc;

  /// 标准字体描述
  ///
  /// In zh, this message translates to:
  /// **'默认字体大小'**
  String get fontSizeNormalDesc;

  /// 大字体描述
  ///
  /// In zh, this message translates to:
  /// **'更易于阅读'**
  String get fontSizeLargeDesc;

  /// 特大字体描述
  ///
  /// In zh, this message translates to:
  /// **'最大字体'**
  String get fontSizeXLargeDesc;

  /// 字体选择
  ///
  /// In zh, this message translates to:
  /// **'字体选择'**
  String get fontFamily;

  /// 同步设置分类
  ///
  /// In zh, this message translates to:
  /// **'同步'**
  String get sync;

  /// 自动同步
  ///
  /// In zh, this message translates to:
  /// **'自动同步'**
  String get autoSync;

  /// 自动同步描述
  ///
  /// In zh, this message translates to:
  /// **'定期自动同步笔记'**
  String get autoSyncDesc;

  /// 同步间隔
  ///
  /// In zh, this message translates to:
  /// **'同步间隔'**
  String get syncInterval;

  /// 隐私设置分类
  ///
  /// In zh, this message translates to:
  /// **'隐私'**
  String get privacy;

  /// 默认笔记状态
  ///
  /// In zh, this message translates to:
  /// **'默认笔记状态'**
  String get defaultNoteVisibility;

  /// 私有
  ///
  /// In zh, this message translates to:
  /// **'私有'**
  String get visibilityPrivate;

  /// 公开
  ///
  /// In zh, this message translates to:
  /// **'公开'**
  String get visibilityPublic;

  /// 私有描述
  ///
  /// In zh, this message translates to:
  /// **'仅自己可见'**
  String get visibilityPrivateDesc;

  /// 公开描述
  ///
  /// In zh, this message translates to:
  /// **'所有人可见'**
  String get visibilityPublicDesc;

  /// 其他设置分类
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get other;

  /// 记住密码
  ///
  /// In zh, this message translates to:
  /// **'记住密码'**
  String get rememberPassword;

  /// 记住密码描述
  ///
  /// In zh, this message translates to:
  /// **'保存账号和密码到本地'**
  String get rememberPasswordDesc;

  /// 自动登录
  ///
  /// In zh, this message translates to:
  /// **'自动登录'**
  String get autoLogin;

  /// 自动登录描述
  ///
  /// In zh, this message translates to:
  /// **'启动应用时跳过登录页面直接进入'**
  String get autoLoginDesc;

  /// 启动自动弹出编辑框
  ///
  /// In zh, this message translates to:
  /// **'启动自动弹出编辑框'**
  String get autoShowEditor;

  /// 启动自动弹出编辑框描述
  ///
  /// In zh, this message translates to:
  /// **'打开应用时自动弹出笔记编辑框，快速记录灵感'**
  String get autoShowEditorDesc;

  /// 启动自动弹出编辑框已启用消息
  ///
  /// In zh, this message translates to:
  /// **'已开启启动自动弹出编辑框'**
  String get autoShowEditorEnabled;

  /// 启动自动弹出编辑框已禁用消息
  ///
  /// In zh, this message translates to:
  /// **'已关闭启动自动弹出编辑框'**
  String get autoShowEditorDisabled;

  /// 语言选择
  ///
  /// In zh, this message translates to:
  /// **'语言选择'**
  String get language;

  /// 简体中文
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// 英文
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// 选择主题
  ///
  /// In zh, this message translates to:
  /// **'选择主题'**
  String get selectTheme;

  /// 选择字体大小
  ///
  /// In zh, this message translates to:
  /// **'选择字体大小'**
  String get selectFontSize;

  /// 选择字体
  ///
  /// In zh, this message translates to:
  /// **'选择字体'**
  String get selectFont;

  /// 选择默认笔记状态
  ///
  /// In zh, this message translates to:
  /// **'选择默认笔记状态'**
  String get selectDefaultNoteVisibility;

  /// 选择语言
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get selectLanguage;

  /// 主题切换成功消息
  ///
  /// In zh, this message translates to:
  /// **'主题已切换为{themeName}'**
  String themeChanged(String themeName);

  /// 字体大小切换成功消息
  ///
  /// In zh, this message translates to:
  /// **'字体大小已设置为{sizeName}'**
  String fontSizeChanged(String sizeName);

  /// 字体切换成功消息
  ///
  /// In zh, this message translates to:
  /// **'字体已切换为{fontName}'**
  String fontChanged(String fontName);

  /// 笔记可见性切换成功消息
  ///
  /// In zh, this message translates to:
  /// **'默认笔记状态已设置为{visibility}'**
  String defaultNoteVisibilityChanged(String visibility);

  /// 记住密码已启用消息
  ///
  /// In zh, this message translates to:
  /// **'已同时开启记住密码功能'**
  String get rememberPasswordEnabled;

  /// 语言切换成功消息
  ///
  /// In zh, this message translates to:
  /// **'语言已切换为{language}'**
  String languageChanged(String language);

  /// 分享图预览页面标题
  ///
  /// In zh, this message translates to:
  /// **'生成分享图'**
  String get shareImageTitle;

  /// 生成分享图消息
  ///
  /// In zh, this message translates to:
  /// **'生成中...'**
  String get shareImageGenerating;

  /// 生成预览和图片消息
  ///
  /// In zh, this message translates to:
  /// **'正在生成预览（加载图片中...）'**
  String get shareImageGeneratingPreview;

  /// 加载图片消息
  ///
  /// In zh, this message translates to:
  /// **'图片加载中，请稍候...'**
  String get shareImageLoadingImages;

  /// 预览生成失败消息
  ///
  /// In zh, this message translates to:
  /// **'预览生成失败'**
  String get shareImageGenerationFailed;

  /// 更换模板按钮
  ///
  /// In zh, this message translates to:
  /// **'更换模板'**
  String get shareImageChangeTemplate;

  /// 保存图片按钮
  ///
  /// In zh, this message translates to:
  /// **'保存图片'**
  String get shareImageSave;

  /// 分享按钮
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get shareImageShare;

  /// 保存图片消息
  ///
  /// In zh, this message translates to:
  /// **'正在保存图片...'**
  String get shareImageSaving;

  /// 保存到相册消息
  ///
  /// In zh, this message translates to:
  /// **'正在保存图片，请稍候'**
  String get shareImageSavingToAlbum;

  /// 图片保存成功消息
  ///
  /// In zh, this message translates to:
  /// **'图片已保存'**
  String get shareImageSaveSuccess;

  /// 保存失败消息
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请检查权限或保存位置'**
  String get shareImageSaveFailed;

  /// 分享失败消息
  ///
  /// In zh, this message translates to:
  /// **'分享失败'**
  String get shareImageShareFailed;

  /// 等待预览消息
  ///
  /// In zh, this message translates to:
  /// **'请等待预览生成完成'**
  String get shareImageWaitForPreview;

  /// 字体大小设置标题
  ///
  /// In zh, this message translates to:
  /// **'字体大小'**
  String get shareImageFontSizeTitle;

  /// 字体大小设置描述
  ///
  /// In zh, this message translates to:
  /// **'拖动滑块实时预览效果'**
  String get shareImageFontSizeDesc;

  /// 重置字体大小按钮
  ///
  /// In zh, this message translates to:
  /// **'重置 (17px)'**
  String get shareImageFontSizeReset;

  /// 完成按钮
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get shareImageFontSizeDone;

  /// 简约模板
  ///
  /// In zh, this message translates to:
  /// **'简约风格'**
  String get shareTemplateSimple;

  /// 卡片模板
  ///
  /// In zh, this message translates to:
  /// **'卡片风格'**
  String get shareTemplateCard;

  /// 渐变模板
  ///
  /// In zh, this message translates to:
  /// **'渐变风格'**
  String get shareTemplateGradient;

  /// 极简模板
  ///
  /// In zh, this message translates to:
  /// **'极简风格'**
  String get shareTemplateMinimal;

  /// 杂志模板
  ///
  /// In zh, this message translates to:
  /// **'杂志风格'**
  String get shareTemplateMagazine;

  /// 字体设置工具提示
  ///
  /// In zh, this message translates to:
  /// **'字体设置'**
  String get shareImageFontSettings;

  /// AI 助手标题
  ///
  /// In zh, this message translates to:
  /// **'AI 智能助手'**
  String get aiAssistant;

  /// AI 续写功能
  ///
  /// In zh, this message translates to:
  /// **'AI 续写'**
  String get aiContinueWriting;

  /// AI 续写功能描述
  ///
  /// In zh, this message translates to:
  /// **'基于已有内容智能续写'**
  String get aiContinueWritingDesc;

  /// AI 智能标签功能
  ///
  /// In zh, this message translates to:
  /// **'智能标签'**
  String get aiSmartTags;

  /// AI 智能标签功能描述
  ///
  /// In zh, this message translates to:
  /// **'根据内容生成标签建议'**
  String get aiSmartTagsDesc;

  /// AI 相关笔记功能
  ///
  /// In zh, this message translates to:
  /// **'相关笔记'**
  String get aiRelatedNotes;

  /// AI 摘要功能
  ///
  /// In zh, this message translates to:
  /// **'智能摘要'**
  String get aiSummary;

  /// AI 处理中提示
  ///
  /// In zh, this message translates to:
  /// **'AI 处理中...'**
  String get aiProcessing;

  /// AI 续写处理中
  ///
  /// In zh, this message translates to:
  /// **'✨ AI 正在续写中...'**
  String get aiContinueWritingProcessing;

  /// AI 续写成功
  ///
  /// In zh, this message translates to:
  /// **'✅ AI 续写完成！'**
  String get aiContinueWritingSuccess;

  /// AI 标签生成中
  ///
  /// In zh, this message translates to:
  /// **'🏷️ AI 正在生成标签...'**
  String get aiTagsProcessing;

  /// AI 标签生成成功
  ///
  /// In zh, this message translates to:
  /// **'✅ 生成了 {count} 个标签！'**
  String aiTagsSuccess(int count);

  /// AI 摘要生成中
  ///
  /// In zh, this message translates to:
  /// **'🤖 AI 正在生成摘要...'**
  String get aiSummaryProcessing;

  /// AI 摘要生成成功
  ///
  /// In zh, this message translates to:
  /// **'✅ 摘要生成成功！'**
  String get aiSummarySuccess;

  /// AI 查找相关笔记中
  ///
  /// In zh, this message translates to:
  /// **'🔍 AI 正在查找相关笔记...'**
  String get aiRelatedNotesProcessing;

  /// 没有找到相关笔记
  ///
  /// In zh, this message translates to:
  /// **'暂无相关笔记'**
  String get aiRelatedNotesEmpty;

  /// 需要配置 AI
  ///
  /// In zh, this message translates to:
  /// **'请先在设置中配置 AI'**
  String get aiConfigRequired;

  /// 需要配置 AI API
  ///
  /// In zh, this message translates to:
  /// **'请先在 AI 设置中配置 API'**
  String get aiApiConfigRequired;

  /// 需要输入内容
  ///
  /// In zh, this message translates to:
  /// **'请先输入一些内容'**
  String get aiContentRequired;

  /// 生成摘要失败
  ///
  /// In zh, this message translates to:
  /// **'生成摘要失败，请稍后重试'**
  String get aiGenerateSummaryFailed;

  /// 相关笔记标题
  ///
  /// In zh, this message translates to:
  /// **'相关笔记'**
  String get aiRelatedNotesTitle;

  /// AI 相关笔记功能
  ///
  /// In zh, this message translates to:
  /// **'AI 相关笔记'**
  String get aiRelatedNotesFeature;

  /// AI 相关笔记功能描述
  ///
  /// In zh, this message translates to:
  /// **'查找与当前笔记可能相关的内容'**
  String get aiRelatedNotesFeatureDesc;

  /// AI 续写功能
  ///
  /// In zh, this message translates to:
  /// **'AI 续写'**
  String get aiContinueWritingFeature;

  /// AI 续写功能描述
  ///
  /// In zh, this message translates to:
  /// **'基于已有内容智能续写笔记'**
  String get aiContinueWritingFeatureDesc;

  /// AI 智能标签和摘要
  ///
  /// In zh, this message translates to:
  /// **'AI 智能标签 & 摘要'**
  String get aiSmartTagsAndSummary;

  /// AI 智能标签和摘要描述
  ///
  /// In zh, this message translates to:
  /// **'根据内容生成标签建议和摘要'**
  String get aiSmartTagsAndSummaryDesc;

  /// 微信小助手
  ///
  /// In zh, this message translates to:
  /// **'微信小助手'**
  String get wechatAssistant;

  /// 微信小助手描述
  ///
  /// In zh, this message translates to:
  /// **'通过微信直接输入快速记录笔记，支持文字、图片'**
  String get wechatAssistantDesc;

  /// 功能已完成状态
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get featureCompleted;

  /// AI 相关笔记使用说明
  ///
  /// In zh, this message translates to:
  /// **'在笔记详情页点击右下角的 AI 按钮即可查看相关笔记'**
  String get aiRelatedNotesUsage;

  /// AI 续写使用说明
  ///
  /// In zh, this message translates to:
  /// **'在编辑笔记时点击工具栏的 AI 按钮，选择续写功能'**
  String get aiContinueWritingUsage;

  /// AI 智能标签和摘要使用说明
  ///
  /// In zh, this message translates to:
  /// **'编辑笔记时使用 AI 按钮生成标签，详情页使用智能摘要功能'**
  String get aiSmartTagsAndSummaryUsage;

  /// 知道了按钮
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get understood;

  /// WebDAV 同步
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 同步'**
  String get webdavSync;

  /// 启用 WebDAV 同步
  ///
  /// In zh, this message translates to:
  /// **'启用 WebDAV 同步'**
  String get enableWebdavSync;

  /// 服务器地址
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get serverAddress;

  /// 用户名
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get username;

  /// 密码
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// 同步文件夹
  ///
  /// In zh, this message translates to:
  /// **'同步文件夹'**
  String get syncFolder;

  /// 立即测试
  ///
  /// In zh, this message translates to:
  /// **'立即测试'**
  String get testNow;

  /// 立即备份
  ///
  /// In zh, this message translates to:
  /// **'立即备份'**
  String get backupNow;

  /// 从 WebDAV 恢复
  ///
  /// In zh, this message translates to:
  /// **'从 WebDAV 恢复'**
  String get restoreFromWebdav;

  /// 启用定时备份
  ///
  /// In zh, this message translates to:
  /// **'启用定时备份'**
  String get enableTimedBackup;

  /// 自动备份笔记到 WebDAV
  ///
  /// In zh, this message translates to:
  /// **'自动备份笔记到 WebDAV'**
  String get autoBackupToWebdav;

  /// 备份时机
  ///
  /// In zh, this message translates to:
  /// **'备份时机'**
  String get backupTiming;

  /// 每次启动
  ///
  /// In zh, this message translates to:
  /// **'每次启动'**
  String get everyStartup;

  /// 15分钟
  ///
  /// In zh, this message translates to:
  /// **'15分钟'**
  String get every15Minutes;

  /// 30分钟
  ///
  /// In zh, this message translates to:
  /// **'30分钟'**
  String get every30Minutes;

  /// 1小时
  ///
  /// In zh, this message translates to:
  /// **'1小时'**
  String get every1Hour;

  /// 测试中
  ///
  /// In zh, this message translates to:
  /// **'测试中...'**
  String get testing;

  /// 备份中
  ///
  /// In zh, this message translates to:
  /// **'备份中...'**
  String get backingUp;

  /// 恢复中
  ///
  /// In zh, this message translates to:
  /// **'恢复中...'**
  String get restoring;

  /// 请输入服务器地址
  ///
  /// In zh, this message translates to:
  /// **'请输入服务器地址'**
  String get pleaseEnterServerAddress;

  /// 地址必须以http或https开头
  ///
  /// In zh, this message translates to:
  /// **'地址必须以 http:// 或 https:// 开头'**
  String get addressMustStartWithHttp;

  /// 请输入用户名
  ///
  /// In zh, this message translates to:
  /// **'请输入用户名'**
  String get pleaseEnterUsername;

  /// 请输入密码
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get pleaseEnterPassword;

  /// 请输入同步文件夹路径
  ///
  /// In zh, this message translates to:
  /// **'请输入同步文件夹路径'**
  String get pleaseEnterSyncFolderPath;

  /// WebDAV 配置已保存
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 配置已保存'**
  String get webdavConfigSaved;

  /// 请先启用 WebDAV 同步
  ///
  /// In zh, this message translates to:
  /// **'请先启用 WebDAV 同步'**
  String get pleaseEnableWebdavFirst;

  /// WebDAV 帮助文本
  ///
  /// In zh, this message translates to:
  /// **'• 推荐使用坚果云等专业 WebDAV 服务\n• 坚果云需要使用\"应用专用密码\"而不是登录密码\n• 立即测试：测试 WebDAV 服务器连接\n• 立即备份：单向上传，完整备份所有数据到云端\n• 从 WebDAV 恢复：下载云端数据到本地（覆盖本地）\n• 定时备份：可选择每次启动或定时自动备份'**
  String get webdavHelpText;

  /// WebDAV 使用指南
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 使用指南'**
  String get webdavGuide;

  /// 什么是 WebDAV
  ///
  /// In zh, this message translates to:
  /// **'🤔 什么是 WebDAV？'**
  String get whatIsWebdav;

  /// WebDAV 描述
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 是一种网络协议，可以让你将笔记备份到云端服务器。本应用支持使用 WebDAV 进行笔记备份和恢复。'**
  String get webdavDescription;

  /// 自定义
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get custom;

  /// 功能开发中
  ///
  /// In zh, this message translates to:
  /// **'功能正在开发中，敬请期待！'**
  String get featureInDevelopment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
