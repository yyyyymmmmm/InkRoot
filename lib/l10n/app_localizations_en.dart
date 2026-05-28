// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'InkRoot Notes';

  @override
  String get preferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSelection => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDesc => 'Follow system settings';

  @override
  String get themeLightDesc => 'Light theme';

  @override
  String get themeDarkDesc => 'Dark theme';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontSizeMini => 'Mini';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeNormal => 'Normal';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeXLarge => 'Extra Large';

  @override
  String get fontSizeMiniDesc => 'Minimum font size, space-saving';

  @override
  String get fontSizeSmallDesc => 'Suitable for reading large amounts of text';

  @override
  String get fontSizeNormalDesc => 'Default font size';

  @override
  String get fontSizeLargeDesc => 'Easier to read';

  @override
  String get fontSizeXLargeDesc => 'Maximum font size';

  @override
  String get fontFamily => 'Font';

  @override
  String get sync => 'Sync';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get autoSyncDesc => 'Automatically sync notes periodically';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String get privacy => 'Privacy';

  @override
  String get defaultNoteVisibility => 'Default Note Visibility';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityPrivateDesc => 'Only visible to you';

  @override
  String get visibilityPublicDesc => 'Visible to everyone';

  @override
  String get other => 'Other';

  @override
  String get rememberPassword => 'Remember Password';

  @override
  String get rememberPasswordDesc => 'Save account and password locally';

  @override
  String get autoLogin => 'Auto Login';

  @override
  String get autoLoginDesc => 'Skip login page when starting the app';

  @override
  String get autoShowEditor => 'Auto Show Editor on Launch';

  @override
  String get autoShowEditorDesc =>
      'Automatically open note editor when app starts, quickly capture inspiration';

  @override
  String get autoShowEditorEnabled => 'Auto show editor on launch enabled';

  @override
  String get autoShowEditorDisabled => 'Auto show editor on launch disabled';

  @override
  String get language => 'Language';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get selectFontSize => 'Select Font Size';

  @override
  String get selectFont => 'Select Font';

  @override
  String get selectDefaultNoteVisibility => 'Select Default Note Visibility';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String themeChanged(String themeName) {
    return 'Theme changed to $themeName';
  }

  @override
  String fontSizeChanged(String sizeName) {
    return 'Font size set to $sizeName';
  }

  @override
  String fontChanged(String fontName) {
    return 'Font changed to $fontName';
  }

  @override
  String defaultNoteVisibilityChanged(String visibility) {
    return 'Default note visibility set to $visibility';
  }

  @override
  String get rememberPasswordEnabled => 'Remember password feature enabled';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String get shareImageTitle => 'Generate Share Image';

  @override
  String get shareImageGenerating => 'Generating...';

  @override
  String get shareImageGeneratingPreview =>
      'Generating preview (loading images...)';

  @override
  String get shareImageLoadingImages => 'Loading images, please wait...';

  @override
  String get shareImageGenerationFailed => 'Preview generation failed';

  @override
  String get shareImageChangeTemplate => 'Change Template';

  @override
  String get shareImageSave => 'Save Image';

  @override
  String get shareImageShare => 'Share';

  @override
  String get shareImageSaving => 'Saving image...';

  @override
  String get shareImageSavingToAlbum => 'Saving to album, please wait';

  @override
  String get shareImageSaveSuccess => 'Image saved to album';

  @override
  String get shareImageSaveFailed =>
      'Save failed, please check album permissions';

  @override
  String get shareImageShareFailed => 'Share failed';

  @override
  String get shareImageWaitForPreview => 'Please wait for preview to complete';

  @override
  String get shareImageFontSizeTitle => 'Font Size';

  @override
  String get shareImageFontSizeDesc => 'Drag slider for live preview';

  @override
  String get shareImageFontSizeReset => 'Reset (17px)';

  @override
  String get shareImageFontSizeDone => 'Done';

  @override
  String get shareTemplateSimple => 'Simple';

  @override
  String get shareTemplateCard => 'Card';

  @override
  String get shareTemplateGradient => 'Gradient';

  @override
  String get shareTemplateMinimal => 'Minimal';

  @override
  String get shareTemplateMagazine => 'Magazine';

  @override
  String get shareImageFontSettings => 'Font Settings';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiContinueWriting => 'AI Continue';

  @override
  String get aiContinueWritingDesc =>
      'Intelligently continue based on existing content';

  @override
  String get aiSmartTags => 'Smart Tags';

  @override
  String get aiSmartTagsDesc => 'Automatically generate precise tags';

  @override
  String get aiRelatedNotes => 'Related Notes';

  @override
  String get aiSummary => 'Smart Summary';

  @override
  String get aiProcessing => 'AI processing...';

  @override
  String get aiContinueWritingProcessing => '✨ AI is continuing...';

  @override
  String get aiContinueWritingSuccess => '✅ AI continue completed!';

  @override
  String get aiTagsProcessing => '🏷️ AI is generating tags...';

  @override
  String aiTagsSuccess(int count) {
    return '✅ Generated $count tags!';
  }

  @override
  String get aiSummaryProcessing => '🤖 AI is generating summary...';

  @override
  String get aiSummarySuccess => '✅ Summary generated successfully!';

  @override
  String get aiRelatedNotesProcessing => '🔍 AI is finding related notes...';

  @override
  String get aiRelatedNotesEmpty => 'No related notes found';

  @override
  String get aiConfigRequired => 'Please configure AI in settings first';

  @override
  String get aiApiConfigRequired => 'Please configure AI API in settings first';

  @override
  String get aiContentRequired => 'Please enter some content first';

  @override
  String get aiGenerateSummaryFailed =>
      'Failed to generate summary, please try again later';

  @override
  String get aiRelatedNotesTitle => 'Related Notes';

  @override
  String get aiRelatedNotesFeature => 'AI Related Notes';

  @override
  String get aiRelatedNotesFeatureDesc =>
      'Intelligently recommend notes related to the current note';

  @override
  String get aiContinueWritingFeature => 'AI Continue Writing';

  @override
  String get aiContinueWritingFeatureDesc =>
      'Intelligently continue writing based on existing content';

  @override
  String get aiSmartTagsAndSummary => 'AI Smart Tags & Summary';

  @override
  String get aiSmartTagsAndSummaryDesc =>
      'Automatically generate precise tags and smart summaries';

  @override
  String get wechatAssistant => 'WeChat Assistant';

  @override
  String get wechatAssistantDesc =>
      'Quickly record notes via WeChat, supports text and images';

  @override
  String get featureCompleted => 'Completed';

  @override
  String get aiRelatedNotesUsage =>
      'Click the AI button in the bottom right corner of the note details page to view related notes';

  @override
  String get aiContinueWritingUsage =>
      'Click the AI button in the toolbar when editing notes and select the continue writing feature';

  @override
  String get aiSmartTagsAndSummaryUsage =>
      'Use the AI button to generate tags when editing notes, and use the smart summary feature on the details page';

  @override
  String get understood => 'Got it';

  @override
  String get webdavSync => 'WebDAV Sync';

  @override
  String get enableWebdavSync => 'Enable WebDAV Sync';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get syncFolder => 'Sync Folder';

  @override
  String get testNow => 'Test Now';

  @override
  String get backupNow => 'Backup Now';

  @override
  String get restoreFromWebdav => 'Restore from WebDAV';

  @override
  String get enableTimedBackup => 'Enable Timed Backup';

  @override
  String get autoBackupToWebdav => 'Auto backup notes to WebDAV';

  @override
  String get backupTiming => 'Backup Timing';

  @override
  String get everyStartup => 'Every Startup';

  @override
  String get every15Minutes => '15 Minutes';

  @override
  String get every30Minutes => '30 Minutes';

  @override
  String get every1Hour => '1 Hour';

  @override
  String get testing => 'Testing...';

  @override
  String get backingUp => 'Backing up...';

  @override
  String get restoring => 'Restoring...';

  @override
  String get pleaseEnterServerAddress => 'Please enter server address';

  @override
  String get addressMustStartWithHttp =>
      'Address must start with http:// or https://';

  @override
  String get pleaseEnterUsername => 'Please enter username';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get pleaseEnterSyncFolderPath => 'Please enter sync folder path';

  @override
  String get webdavConfigSaved => 'WebDAV config saved';

  @override
  String get pleaseEnableWebdavFirst => 'Please enable WebDAV sync first';

  @override
  String get webdavHelpText =>
      '• Recommend using professional WebDAV services like Nutstore\n• Nutstore requires using \"App-specific password\" instead of login password\n• Test Now: Test WebDAV server connection\n• Backup Now: One-way upload, full backup of all data to cloud\n• Restore from WebDAV: Download cloud data to local (overwrite local)\n• Timed Backup: Choose to auto backup on every startup or timed intervals';

  @override
  String get webdavGuide => 'WebDAV Usage Guide';

  @override
  String get whatIsWebdav => '🤔 What is WebDAV?';

  @override
  String get webdavDescription =>
      'WebDAV is a network protocol that allows you to backup notes to a cloud server. This app supports using WebDAV for note backup and recovery.';

  @override
  String get custom => 'Custom';

  @override
  String get featureInDevelopment => 'Feature in development, stay tuned!';
}
