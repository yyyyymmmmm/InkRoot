// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '墨鸣笔记';

  @override
  String get preferences => '偏好设置';

  @override
  String get appearance => '外观';

  @override
  String get themeSelection => '主题选择';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '纸白';

  @override
  String get themeDark => '幽谷';

  @override
  String get themeSystemDesc => '跟随系统设置';

  @override
  String get themeLightDesc => '浅色主题';

  @override
  String get themeDarkDesc => '深色主题';

  @override
  String get fontSize => '字体大小';

  @override
  String get fontSizeMini => '极小';

  @override
  String get fontSizeSmall => '小';

  @override
  String get fontSizeNormal => '标准';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeXLarge => '特大';

  @override
  String get fontSizeMiniDesc => '最小字体，节省空间';

  @override
  String get fontSizeSmallDesc => '适合阅读大量文字';

  @override
  String get fontSizeNormalDesc => '默认字体大小';

  @override
  String get fontSizeLargeDesc => '更易于阅读';

  @override
  String get fontSizeXLargeDesc => '最大字体';

  @override
  String get fontFamily => '字体选择';

  @override
  String get sync => '同步';

  @override
  String get autoSync => '自动同步';

  @override
  String get autoSyncDesc => '定期自动同步笔记';

  @override
  String get syncInterval => '同步间隔';

  @override
  String get privacy => '隐私';

  @override
  String get defaultNoteVisibility => '默认笔记状态';

  @override
  String get visibilityPrivate => '私有';

  @override
  String get visibilityPublic => '公开';

  @override
  String get visibilityPrivateDesc => '仅自己可见';

  @override
  String get visibilityPublicDesc => '所有人可见';

  @override
  String get other => '其他';

  @override
  String get rememberPassword => '记住密码';

  @override
  String get rememberPasswordDesc => '保存账号和密码到本地';

  @override
  String get autoLogin => '自动登录';

  @override
  String get autoLoginDesc => '启动应用时跳过登录页面直接进入';

  @override
  String get autoShowEditor => '启动自动弹出编辑框';

  @override
  String get autoShowEditorDesc => '打开应用时自动弹出笔记编辑框，快速记录灵感';

  @override
  String get autoShowEditorEnabled => '已开启启动自动弹出编辑框';

  @override
  String get autoShowEditorDisabled => '已关闭启动自动弹出编辑框';

  @override
  String get language => '语言选择';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectTheme => '选择主题';

  @override
  String get selectFontSize => '选择字体大小';

  @override
  String get selectFont => '选择字体';

  @override
  String get selectDefaultNoteVisibility => '选择默认笔记状态';

  @override
  String get selectLanguage => '选择语言';

  @override
  String themeChanged(String themeName) {
    return '主题已切换为$themeName';
  }

  @override
  String fontSizeChanged(String sizeName) {
    return '字体大小已设置为$sizeName';
  }

  @override
  String fontChanged(String fontName) {
    return '字体已切换为$fontName';
  }

  @override
  String defaultNoteVisibilityChanged(String visibility) {
    return '默认笔记状态已设置为$visibility';
  }

  @override
  String get rememberPasswordEnabled => '已同时开启记住密码功能';

  @override
  String languageChanged(String language) {
    return '语言已切换为$language';
  }

  @override
  String get shareImageTitle => '生成分享图';

  @override
  String get shareImageGenerating => '生成中...';

  @override
  String get shareImageGeneratingPreview => '正在生成预览（加载图片中...）';

  @override
  String get shareImageLoadingImages => '图片加载中，请稍候...';

  @override
  String get shareImageGenerationFailed => '预览生成失败';

  @override
  String get shareImageChangeTemplate => '更换模板';

  @override
  String get shareImageSave => '保存图片';

  @override
  String get shareImageShare => '分享';

  @override
  String get shareImageSaving => '正在保存图片...';

  @override
  String get shareImageSavingToAlbum => '正在保存到相册，请稍候';

  @override
  String get shareImageSaveSuccess => '图片已保存到相册';

  @override
  String get shareImageSaveFailed => '保存失败，请检查相册权限';

  @override
  String get shareImageShareFailed => '分享失败';

  @override
  String get shareImageWaitForPreview => '请等待预览生成完成';

  @override
  String get shareImageFontSizeTitle => '字体大小';

  @override
  String get shareImageFontSizeDesc => '拖动滑块实时预览效果';

  @override
  String get shareImageFontSizeReset => '重置 (17px)';

  @override
  String get shareImageFontSizeDone => '完成';

  @override
  String get shareTemplateSimple => '简约风格';

  @override
  String get shareTemplateCard => '卡片风格';

  @override
  String get shareTemplateGradient => '渐变风格';

  @override
  String get shareTemplateMinimal => '极简风格';

  @override
  String get shareTemplateMagazine => '杂志风格';

  @override
  String get shareImageFontSettings => '字体设置';

  @override
  String get aiAssistant => 'AI 智能助手';

  @override
  String get aiContinueWriting => 'AI 续写';

  @override
  String get aiContinueWritingDesc => '基于已有内容智能续写';

  @override
  String get aiSmartTags => '智能标签';

  @override
  String get aiSmartTagsDesc => '自动生成精准标签';

  @override
  String get aiRelatedNotes => '相关笔记';

  @override
  String get aiSummary => '智能摘要';

  @override
  String get aiProcessing => 'AI 处理中...';

  @override
  String get aiContinueWritingProcessing => '✨ AI 正在续写中...';

  @override
  String get aiContinueWritingSuccess => '✅ AI 续写完成！';

  @override
  String get aiTagsProcessing => '🏷️ AI 正在生成标签...';

  @override
  String aiTagsSuccess(int count) {
    return '✅ 生成了 $count 个标签！';
  }

  @override
  String get aiSummaryProcessing => '🤖 AI 正在生成摘要...';

  @override
  String get aiSummarySuccess => '✅ 摘要生成成功！';

  @override
  String get aiRelatedNotesProcessing => '🔍 AI 正在查找相关笔记...';

  @override
  String get aiRelatedNotesEmpty => '暂无相关笔记';

  @override
  String get aiConfigRequired => '请先在设置中配置 AI';

  @override
  String get aiApiConfigRequired => '请先在 AI 设置中配置 API';

  @override
  String get aiContentRequired => '请先输入一些内容';

  @override
  String get aiGenerateSummaryFailed => '生成摘要失败，请稍后重试';

  @override
  String get aiRelatedNotesTitle => '相关笔记';

  @override
  String get aiRelatedNotesFeature => 'AI 相关笔记';

  @override
  String get aiRelatedNotesFeatureDesc => '智能推荐与当前笔记相关的其他笔记';

  @override
  String get aiContinueWritingFeature => 'AI 续写';

  @override
  String get aiContinueWritingFeatureDesc => '基于已有内容智能续写笔记';

  @override
  String get aiSmartTagsAndSummary => 'AI 智能标签 & 摘要';

  @override
  String get aiSmartTagsAndSummaryDesc => '自动生成精准标签和智能摘要';

  @override
  String get wechatAssistant => '微信小助手';

  @override
  String get wechatAssistantDesc => '通过微信直接输入快速记录笔记，支持文字、图片';

  @override
  String get featureCompleted => '已完成';

  @override
  String get aiRelatedNotesUsage => '在笔记详情页点击右下角的 AI 按钮即可查看相关笔记';

  @override
  String get aiContinueWritingUsage => '在编辑笔记时点击工具栏的 AI 按钮，选择续写功能';

  @override
  String get aiSmartTagsAndSummaryUsage => '编辑笔记时使用 AI 按钮生成标签，详情页使用智能摘要功能';

  @override
  String get understood => '知道了';

  @override
  String get webdavSync => 'WebDAV 同步';

  @override
  String get enableWebdavSync => '启用 WebDAV 同步';

  @override
  String get serverAddress => '服务器地址';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get syncFolder => '同步文件夹';

  @override
  String get testNow => '立即测试';

  @override
  String get backupNow => '立即备份';

  @override
  String get restoreFromWebdav => '从 WebDAV 恢复';

  @override
  String get enableTimedBackup => '启用定时备份';

  @override
  String get autoBackupToWebdav => '自动备份笔记到 WebDAV';

  @override
  String get backupTiming => '备份时机';

  @override
  String get everyStartup => '每次启动';

  @override
  String get every15Minutes => '15分钟';

  @override
  String get every30Minutes => '30分钟';

  @override
  String get every1Hour => '1小时';

  @override
  String get testing => '测试中...';

  @override
  String get backingUp => '备份中...';

  @override
  String get restoring => '恢复中...';

  @override
  String get pleaseEnterServerAddress => '请输入服务器地址';

  @override
  String get addressMustStartWithHttp => '地址必须以 http:// 或 https:// 开头';

  @override
  String get pleaseEnterUsername => '请输入用户名';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get pleaseEnterSyncFolderPath => '请输入同步文件夹路径';

  @override
  String get webdavConfigSaved => 'WebDAV 配置已保存';

  @override
  String get pleaseEnableWebdavFirst => '请先启用 WebDAV 同步';

  @override
  String get webdavHelpText =>
      '• 推荐使用坚果云等专业 WebDAV 服务\n• 坚果云需要使用\"应用专用密码\"而不是登录密码\n• 立即测试：测试 WebDAV 服务器连接\n• 立即备份：单向上传，完整备份所有数据到云端\n• 从 WebDAV 恢复：下载云端数据到本地（覆盖本地）\n• 定时备份：可选择每次启动或定时自动备份';

  @override
  String get webdavGuide => 'WebDAV 使用指南';

  @override
  String get whatIsWebdav => '🤔 什么是 WebDAV？';

  @override
  String get webdavDescription =>
      'WebDAV 是一种网络协议，可以让你将笔记备份到云端服务器。本应用支持使用 WebDAV 进行笔记备份和恢复。';

  @override
  String get custom => '自定义';

  @override
  String get featureInDevelopment => '功能正在开发中，敬请期待！';
}
