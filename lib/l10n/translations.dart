/// 集中管理的翻译数据类（仅支持中英文）
/// 使用映射结构存储所有翻译文本
class Translations {
  // 私有构造函数，防止实例化
  Translations._();

  /// 所有翻译数据的映射表
  /// 格式: {'key': {'zh': '中文', 'en': 'English'}}
  static final Map<String, Map<String, String>> _translations = {
    // ===== 基础UI =====
    'appTitle': {'zh': 'InkRoot', 'en': 'InkRoot'},
    'home': {'zh': '首页', 'en': 'Home'},
    'notes': {'zh': '笔记', 'en': 'Notes'},
    'tags': {'zh': '标签', 'en': 'Tags'},
    'search': {'zh': '搜索', 'en': 'Search'},
    'add': {'zh': '添加', 'en': 'Add'},
    'delete': {'zh': '删除', 'en': 'Delete'},
    'confirm': {'zh': '确认', 'en': 'Confirm'},
    'save': {'zh': '保存', 'en': 'Save'},
    'back': {'zh': '返回', 'en': 'Back'},
    'done': {'zh': '完成', 'en': 'Done'},
    'submit': {'zh': '提交', 'en': 'Submit'},

    // ===== 侧边栏 =====
    'allNotes': {'zh': '全部笔记', 'en': 'All Notes'},
    'randomReview': {'zh': '随机回顾', 'en': 'Random Review'},
    'allTags': {'zh': '全部标签', 'en': 'All Tags'},
    'account': {'zh': '账户', 'en': 'Account'},
    'dataSync': {'zh': '数据同步', 'en': 'Data Sync'},
    'notifications': {'zh': '通知', 'en': 'Notifications'},
    'help': {'zh': '帮助', 'en': 'Help'},
    'about': {'zh': '关于', 'en': 'About'},
    'logout': {'zh': '退出登录', 'en': 'Logout'},
    'dataCleanup': {'zh': '数据清理', 'en': 'Data Cleanup'},
    'laboratory': {'zh': '实验室', 'en': 'Laboratory'},
    'knowledgeGraph': {'zh': '知识图谱', 'en': 'Knowledge Graph'},
    'activityLog': {'zh': '活动记录', 'en': 'Activity Log'},
    'notificationCenter': {'zh': '通知中心', 'en': 'Notification Center'},
    'totalWords': {'zh': '总字数', 'en': 'Total Words'},
    'totalNotes': {'zh': '笔记数', 'en': 'Notes Count'},
    'totalDays': {'zh': '记录天数', 'en': 'Days Recorded'},
    'todayWords': {'zh': '今日字数', 'en': 'Today Words'},
    'todayNewNotes': {'zh': '新增笔记', 'en': 'New Notes'},
    'todayNewTags': {'zh': '新增标签', 'en': 'New Tags'},
    'functionMenu': {'zh': '功能菜单', 'en': 'Function Menu'},

    // ===== 笔记相关 =====
    'createNote': {'zh': '创建笔记', 'en': 'Create Note'},
    'copyNote': {'zh': '复制笔记', 'en': 'Copy Note'},
    'noteContent': {'zh': '笔记内容', 'en': 'Note Content'},
    'emptyNote': {'zh': '空笔记', 'en': 'Empty Note'},
    'searchResultsCount': {
      'zh': '找到 {count} 条结果',
      'en': '{count} results',
    },
    'noSearchResults': {
      'zh': '没有找到相关笔记',
      'en': 'No matching notes',
    },
    'sortNewest': {'zh': '最新', 'en': 'Newest'},
    'sortOldest': {'zh': '最旧', 'en': 'Oldest'},
    'sortUpdated': {'zh': '最近更新', 'en': 'Recently Updated'},

    // ===== 设置 =====
    'settings': {'zh': '设置', 'en': 'Settings'},
    'settingsAccountAndConnection': {
      'zh': '账户与连接',
      'en': 'Account & Connection',
    },
    'settingsGeneral': {'zh': '通用', 'en': 'General'},
    'settingsDataManagement': {'zh': '数据管理', 'en': 'Data Management'},
    'settingsSupport': {'zh': '支持', 'en': 'Support'},
    'generalSettings': {'zh': '通用设置', 'en': 'General'},
    'accountSettings': {'zh': '账户设置', 'en': 'Account'},
    'privacySettings': {'zh': '隐私设置', 'en': 'Privacy'},
    'accountInfo': {'zh': '账户信息', 'en': 'Account Info'},
    'preferences': {'zh': '偏好设置', 'en': 'Preferences'},
    'appearance': {'zh': '外观', 'en': 'Appearance'},
    'theme': {'zh': '主题', 'en': 'Theme'},
    'fontSize': {'zh': '字体大小', 'en': 'Font Size'},
    'selectFontSize': {'zh': '选择字体大小', 'en': 'Select Font Size'},
    'selectTheme': {'zh': '选择主题', 'en': 'Select Theme'},
    'selectFont': {'zh': '选择字体', 'en': 'Select Font'},
    'selectNoteVisibility': {'zh': '选择笔记状态', 'en': 'Select Note Status'},
    'language': {'zh': '语言', 'en': 'Language'},
    'sync': {'zh': '同步', 'en': 'Sync'},
    'privacy': {'zh': '隐私', 'en': 'Privacy'},
    'aiSettings': {'zh': 'AI设置', 'en': 'AI Settings'},
    'advancedSettings': {'zh': '高级设置', 'en': 'Advanced'},
    'feedback': {'zh': '反馈', 'en': 'Feedback'},
    'syncFailed': {'zh': '同步失败', 'en': 'Sync Failed'},
    'lastSync': {'zh': '上次同步', 'en': 'Last Sync'},
    'syncNow': {'zh': '立即同步', 'en': 'Sync Now'},

    // ===== 时间 =====
    'today': {'zh': '今天', 'en': 'Today'},
    'yesterday': {'zh': '昨天', 'en': 'Yesterday'},
    'noData': {'zh': '暂无数据', 'en': 'No Data'},
    'networkError': {'zh': '网络错误', 'en': 'Network Error'},
    'operationSuccess': {'zh': '操作成功', 'en': 'Success'},
    'success': {'zh': '成功', 'en': 'Success'},
    'failed': {'zh': '失败', 'en': 'Failed'},
    'updateSuccess': {'zh': '更新成功', 'en': 'Update Success'},

    // ===== 删除确认 =====
    'deleteConfirmTitle': {'zh': '确认删除', 'en': 'Confirm Delete'},
    'deleteConfirmMessage': {'zh': '确定要删除吗？', 'en': 'Are you sure to delete?'},
    'deleteSuccess': {'zh': '删除成功', 'en': 'Delete Success'},

    // ===== 登录注册 =====
    'login': {'zh': '登录', 'en': 'Login'},
    'register': {'zh': '注册', 'en': 'Register'},
    'username': {'zh': '用户名', 'en': 'Username'},
    'password': {'zh': '密码', 'en': 'Password'},
    'email': {'zh': '邮箱', 'en': 'Email'},
    'serverUrl': {'zh': '服务器地址', 'en': 'Server URL'},
    'loginButton': {'zh': '登录', 'en': 'Login'},
    'logoutButton': {'zh': '退出登录', 'en': 'Logout'},
    'localMode': {'zh': '本地运行', 'en': 'Local Mode'},
    'logoutConfirm': {'zh': '确认退出', 'en': 'Confirm Logout'},
    'logoutMessage': {'zh': '确定要退出登录吗？', 'en': 'Are you sure to logout?'},
    'keepLocal': {'zh': '保留本地数据', 'en': 'Keep Local Data'},
    'syncBeforeLogout': {'zh': '同步后退出', 'en': 'Sync & Logout'},
    'confirmLogout': {'zh': '确认退出', 'en': 'Confirm'},
    'logoutFailed': {'zh': '退出失败', 'en': 'Logout Failed'},
    'notLoggedIn': {'zh': '未登录', 'en': 'Not Logged In'},

    // ===== 语言名称 =====
    'languageSystem': {'zh': '跟随系统', 'en': 'Follow System'},
    'languageChineseSimplified': {'zh': '简体中文', 'en': 'Simplified Chinese'},
    'languageEnglish': {'zh': '英语', 'en': 'English'},
    'connectionStatus': {'zh': '连接状态', 'en': 'Connection Status'},
    'disconnected': {'zh': '未连接', 'en': 'Disconnected'},
    'diagnosing': {'zh': '诊断中...', 'en': 'Diagnosing...'},
    'connectionDiagnosis': {'zh': '连接诊断', 'en': 'Connection Diagnosis'},
    'connectionSettings': {'zh': '连接设置', 'en': 'Connection Settings'},
    'saveChanges': {'zh': '保存更改', 'en': 'Save Changes'},

    // ===== 账户信息 =====
    'nickname': {'zh': '昵称', 'en': 'Nickname'},
    'changePassword': {'zh': '修改密码', 'en': 'Change Password'},
    'oldPassword': {'zh': '旧密码', 'en': 'Old Password'},
    'newPassword': {'zh': '新密码', 'en': 'New Password'},

    // ===== 导入导出 =====
    'exportBackup': {'zh': '导出备份', 'en': 'Export Backup'},
    'importRestore': {'zh': '导入恢复', 'en': 'Import & Restore'},
    'backupInfo': {'zh': '备份信息', 'en': 'Backup Info'},
    'lastBackup': {'zh': '最后备份', 'en': 'Last Backup'},
    'backupSize': {'zh': '备份大小', 'en': 'Backup Size'},
    'exportOptions': {'zh': '导出选项', 'en': 'Export Options'},
    'exportFormat': {'zh': '导出格式', 'en': 'Export Format'},
    'includeImages': {'zh': '包含图片', 'en': 'Include Images'},
    'includeImagesSubtitle': {
      'zh': '导出时包含笔记中的图片',
      'en': 'Include images in notes when exporting',
    },
    'encryptBackup': {'zh': '加密备份', 'en': 'Encrypt Backup'},
    'encryptionOptions': {'zh': '加密选项', 'en': 'Encryption Options'},
    'encryptionPassword': {'zh': '加密密码', 'en': 'Encryption Password'},
    'startExport': {'zh': '开始导出', 'en': 'Start Export'},
    'export': {'zh': '导出', 'en': 'Export'},
    'import': {'zh': '导入', 'en': 'Import'},

    // ===== 实验室 =====
    'releasedFeatures': {'zh': '已发布功能', 'en': 'Released Features'},
    'developingFeatures': {'zh': '开发中功能', 'en': 'Developing Features'},
    'inDevelopment': {'zh': '开发中', 'en': 'In Development'},
    'experimentalNotice': {
      'zh': '实验室功能可能不稳定，使用时请注意保存重要数据',
      'en': 'Experimental features may be unstable, please save important data',
    },
    'featureDetails': {'zh': '功能特性', 'en': 'Feature Details'},
    'exploring': {
      'zh': '探索前沿功能，体验创新特性',
      'en': 'Explore cutting-edge features and experience innovation',
    },

    // ===== 反馈 =====
    'feedbackType': {'zh': '反馈类型', 'en': 'Feedback Type'},
    'bugReport': {'zh': '问题反馈', 'en': 'Bug Report'},
    'feedbackContent': {'zh': '反馈内容', 'en': 'Feedback Content'},
    'submitFeedback': {'zh': '提交反馈', 'en': 'Submit Feedback'},

    // ===== 其他通知 =====
    'updatingFailed': {'zh': '更新失败', 'en': 'Update Failed'},
    'cannotOpenLink': {'zh': '无法打开链接', 'en': 'Cannot Open Link'},
    'copiedToClipboard': {'zh': '已复制到剪贴板', 'en': 'Copied to Clipboard'},
    'deletingNote': {'zh': '正在删除笔记...', 'en': 'Deleting Note...'},
    'noteRestored': {'zh': '笔记已恢复', 'en': 'Note Restored'},
    'undo': {'zh': '撤销', 'en': 'Undo'},
    'showAll': {'zh': '显示全部', 'en': 'Show All'},
    'graphShowIsolated': {'zh': '显示孤立点', 'en': 'Show isolated'},
    'graphHideIsolated': {'zh': '隐藏孤立点', 'en': 'Hide isolated'},
    'graphBuilding': {'zh': '正在整理图谱', 'en': 'Building graph'},
    'graphOpenNote': {'zh': '打开笔记', 'en': 'Open note'},
    'graphFocusNode': {'zh': '聚焦关联', 'en': 'Focus links'},
    'graphClearSelection': {'zh': '清除选择', 'en': 'Clear selection'},
    'graphNoConnections': {'zh': '还没有引用关系', 'en': 'No linked notes yet'},
    'graphResetView': {'zh': '适配视图', 'en': 'Fit view'},

    // ===== AI设置 =====
    'aiFeatures': {'zh': 'AI功能', 'en': 'AI Features'},
    'apiConfiguration': {'zh': 'API配置', 'en': 'API Configuration'},
    'aiModel': {'zh': 'AI模型', 'en': 'AI Model'},
    'modelSelection': {'zh': '模型名称', 'en': 'Model Name'},
    'selectModel': {'zh': '常用模型示例', 'en': 'Common Model Examples'},
    'domesticModels': {'zh': '国产大模型', 'en': 'Domestic Models'},
    'apiAddress': {'zh': 'API地址', 'en': 'API Address'},
    'apiKey': {'zh': 'API密钥', 'en': 'API Key'},
    'saveConfiguration': {'zh': 'AI配置已保存', 'en': 'AI Config Saved'},

    // ===== 关于和帮助 =====
    'aboutUs': {'zh': '关于 InkRoot', 'en': 'About InkRoot'},
    'version': {'zh': '版本', 'en': 'Version'},
    'team': {'zh': '团队', 'en': 'Team'},
    'helpCenter': {'zh': '帮助中心', 'en': 'Help Center'},
    'gettingStarted': {'zh': '开始使用', 'en': 'Getting Started'},
    'quickGuide': {'zh': '快速指南', 'en': 'Quick Guide'},
    'noteFeatures': {'zh': '笔记功能', 'en': 'Note Features'},
    'tagFeatures': {'zh': '标签功能', 'en': 'Tag Features'},
    'formatEditing': {'zh': '格式编辑', 'en': 'Formatting'},
    'commonQuestions': {'zh': '常见问题', 'en': 'Common Questions'},

    // ===== 标签相关 =====
    'searchTags': {'zh': '搜索标签...', 'en': 'Search tags...'},
    'tagScanComplete': {'zh': '标签扫描完成', 'en': 'Tag scan complete'},
    'tagScanFailed': {'zh': '标签扫描失败', 'en': 'Tag scan failed'},

    // ===== 数据清理 =====
    'cleanupConfirm': {'zh': '确认清理', 'en': 'Confirm Cleanup'},
    'cleanupAllDataMessage': {
      'zh': '此操作将删除所有笔记数据。是否继续？',
      'en': 'This will delete all note data. Continue?',
    },
    'cleanupImagesMessage': {
      'zh': '此操作将删除所有未使用的图片文件。是否继续？',
      'en': 'This will delete all unused images. Continue?',
    },
    'cleanupHistoryMessage': {
      'zh': '此操作将删除所有导入导出历史记录。是否继续？',
      'en': 'This will delete all import/export history. Continue?',
    },
    'cleanupFailed': {'zh': '清理失败', 'en': 'Cleanup Failed'},
    'deleteAllHistorySubtitle': {
      'zh': '删除所有导入导出的历史记录',
      'en': 'Delete all import/export history',
    },
    'dangerOperationSubtitle': {
      'zh': '危险操作：删除所有本地笔记数据，此操作不可恢复',
      'en': 'Danger: Delete all local note data, cannot be undone',
    },
    'notesItem': {'zh': '条笔记', 'en': 'notes'},
    'imagesItem': {'zh': '张图片', 'en': 'images'},
    'notesCount': {'zh': '笔记数量', 'en': 'Notes Count'},
    'databaseSize': {'zh': '数据库大小', 'en': 'Database Size'},
    'cacheSize': {'zh': '缓存大小', 'en': 'Cache Size'},
    'imagesCount': {'zh': '图片数量', 'en': 'Images Count'},
    'refreshData': {'zh': '刷新数据', 'en': 'Refresh Data'},
    'allNotesCleanedSuccess': {'zh': '所有笔记已清理', 'en': 'All Notes Cleaned'},
    'cleanAllNotes': {'zh': '清理所有笔记', 'en': 'Clean All Notes'},

    // ===== 主页空状态 =====
    'noNotesYet': {'zh': '还没有笔记', 'en': 'No notes yet'},
    'clickToCreate': {
      'zh': '点击右下角的按钮开始创建',
      'en': 'Click the button below to start creating',
    },
    'noRelationships': {
      'zh': '笔记之间还没有建立关联',
      'en': 'No relationships between notes yet',
    },

    // ===== 引导页 =====
    'onboardingTitle1': {'zh': '随手记录', 'en': 'Capture Notes'},
    'onboardingDesc1': {
      'zh': '打开就写，文字、图片、待办和链接都能放在一条笔记里',
      'en': 'Open and write. Keep text, images, todos, and links in one note.',
    },
    'onboardingTitle2': {'zh': '用标签整理', 'en': 'Organize with Tags'},
    'onboardingDesc2': {
      'zh': '支持层级标签、搜索和回顾，记录多了也能找回来',
      'en': 'Use nested tags, search, and review to find notes later.',
    },
    'onboardingTitle3': {'zh': '随时随地同步', 'en': 'Sync Anytime, Anywhere'},
    'onboardingDesc3': {
      'zh': '可连接官方服务器或自部署 Memos，多端同步由你选择',
      'en':
          'Connect to the official server or a self-hosted Memos service. Sync is your choice.',
    },
    'onboardingTitle4': {'zh': '多平台支持', 'en': 'Multi-Platform Support'},
    'onboardingDesc4': {
      'zh': '支持手机、平板、电脑多端协作\n让你的创作思路在任何设备上延续',
      'en':
          'Support for phone, tablet, and computer collaboration\nContinue your creative flow on any device',
    },
    'getStarted': {'zh': '开始使用', 'en': 'Get Started'},
    'skip': {'zh': '跳过', 'en': 'Skip'},
    'next': {'zh': '下一步', 'en': 'Next'},

    // ===== 其他设置 =====
    'fontSelection': {'zh': '字体选择', 'en': 'Font Selection'},
    'noteVisibility': {'zh': '默认笔记状态', 'en': 'Default Note Visibility'},
    'private': {'zh': '私密', 'en': 'Private'},
    'public': {'zh': '公开', 'en': 'Public'},
    'privateDesc': {'zh': '仅自己可见', 'en': 'Visible only to you'},
    'publicDesc': {'zh': '所有人可见', 'en': 'Visible to everyone'},
    'fontFamilyDefaultDesc': {
      'zh': '系统默认，清晰现代',
      'en': 'System default, clear and modern',
    },
    'fontFamilyNotoSans': {'zh': '思源黑体', 'en': 'Noto Sans SC'},
    'fontFamilyNotoSansDesc': {
      'zh': 'Noto Sans SC，现代简洁',
      'en': 'Noto Sans SC, modern and clean',
    },
    'fontFamilyNotoSerif': {'zh': '思源宋体', 'en': 'Noto Serif SC'},
    'fontFamilyNotoSerifDesc': {
      'zh': 'Noto Serif SC，优雅复古',
      'en': 'Noto Serif SC, elegant and classic',
    },
    'fontFamilyMaShanZheng': {'zh': '楷体风格', 'en': 'Kai Style'},
    'fontFamilyMaShanZhengDesc': {
      'zh': 'Ma Shan Zheng，手写风格',
      'en': 'Ma Shan Zheng, handwriting style',
    },
    'fontFamilyZcoolXiaowei': {'zh': '站酷小薇', 'en': 'Zcool XiaoWei'},
    'fontFamilyZcoolXiaoweiDesc': {
      'zh': 'Zcool XiaoWei，圆润可爱',
      'en': 'Zcool XiaoWei, rounded and cute',
    },
    'fontFamilyZcoolQingke': {'zh': '站酷庆科', 'en': 'Zcool QingKe'},
    'fontFamilyZcoolQingkeDesc': {
      'zh': 'Zcool QingKe HuangYou，活泼俏皮',
      'en': 'Zcool QingKe, lively and playful',
    },
    'fontChangedTo': {'zh': '字体已切换为', 'en': 'Font changed to'},

    // ===== Markdown相关 =====
    'markdownSyntax': {'zh': 'Markdown语法', 'en': 'Markdown Syntax'},

    // ===== 活跃度 =====
    'activityLevel': {'zh': '活跃度', 'en': 'Activity'},
    'unreadNotifications': {'zh': '条未读', 'en': 'unread'},
    'unreadNotificationsCount': {
      'zh': '{count}条未读信息',
      'en': '{count} unread messages',
    },

    // ===== 通用对话框 =====
    'featureInDevelopment': {
      'zh': '该功能正在开发中，敬请期待！\n我们会尽快为您带来更多精彩功能。',
      'en':
          'This feature is under development, stay tuned!\nWe will bring you more exciting features soon.',
    },
    'ok': {'zh': '好的', 'en': 'OK'},

    // ===== 账户信息页面 =====
    'localUser': {'zh': '本地用户', 'en': 'Local User'},
    'createdTimeLabel': {'zh': '创建时间：', 'en': 'Created: '},
    'nicknameNotSet': {'zh': '未设置昵称', 'en': 'Nickname not set'},
    'emailNotSet': {'zh': '未设置邮箱', 'en': 'Email not set'},
    'basicInfo': {'zh': '基本信息', 'en': 'Basic Info'},
    'modifyPassword': {'zh': '修改密码', 'en': 'Change Password'},
    'syncPersonalInfo': {'zh': '立即同步', 'en': 'Sync Personal Info Now'},
    'syncPersonalInfoDesc': {
      'zh': '从服务器同步最新的个人资料',
      'en': 'Sync latest profile from server',
    },
    'logoutDesc': {
      'zh': '退出当前账号并返回登录页',
      'en': 'Logout and return to login page',
    },
    'welcomeToInkRootShort': {'zh': '欢迎使用 InkRoot', 'en': 'Welcome to InkRoot'},
    'loginToUnlockFeatures': {
      'zh': '登录后解锁更多精彩功能',
      'en': 'Login to unlock more features',
    },
    'cloudSyncFeature': {'zh': '云端同步', 'en': 'Cloud Sync'},
    'cloudSyncDesc': {
      'zh': '笔记实时同步，随时随地访问',
      'en': 'Real-time sync, access anywhere',
    },
    'aiAssistantFeature': {'zh': 'AI 助手', 'en': 'AI Assistant'},
    'aiAssistantDesc': {
      'zh': '智能总结、扩展、改进笔记内容',
      'en': 'Smart summarize, expand, and improve notes',
    },
    'remindersFeature': {'zh': '定时提醒', 'en': 'Reminders'},
    'remindersDesc': {
      'zh': '重要事项不错过，高效管理时间',
      'en': 'Never miss important tasks',
    },
    'agreeToTermsAndPrivacy': {
      'zh': '注册即表示同意用户协议和隐私政策',
      'en': 'By registering, you agree to the Terms and Privacy Policy',
    },
    'connectionNormal': {
      'zh': '服务器连接正常，数据同步正常',
      'en': 'Server connection is normal',
    },
    'notConnected': {'zh': '未连接', 'en': 'Not Connected'},
    'pleaseCheckServerSettings': {
      'zh': '请检查服务器设置',
      'en': 'Please check server settings',
    },
    'host': {'zh': '主机地址', 'en': 'Host'},
    'port': {'zh': '端口', 'en': 'Port'},
    'latency': {'zh': '延迟', 'en': 'Latency'},
    'lastSyncTime': {'zh': '上次同步', 'en': 'Last Sync'},
    'syncNowButton': {'zh': '立即同步', 'en': 'Sync Now'},
    'syncing': {'zh': '同步中...', 'en': 'Syncing...'},
    'enterServerAddress': {'zh': '请输入服务器地址', 'en': 'Enter server address'},
    'portNumber': {'zh': '端口号', 'en': 'Port Number'},
    'enterPortNumber': {'zh': '请输入端口号', 'en': 'Enter port number'},
    'useHTTPS': {'zh': '使用HTTPS安全连接', 'en': 'Use HTTPS secure connection'},
    'enterAPIKey': {'zh': '请输入API密钥', 'en': 'Enter API key'},
    'apiKeyPlaceholder': {
      'zh': '在此粘贴您从服务器获取的API密钥',
      'en': 'Paste your API key from the server here',
    },

    // ===== 意见反馈页面 =====
    'yourOpinionMatters': {'zh': '您的意见很重要', 'en': 'Your Opinion Matters'},
    'feedbackEncouragement': {
      'zh': '我们致力于不断提升产品体验，您的每一个建议都会让产品更好！感谢！',
      'en':
          'We are committed to improving product experience. Every suggestion helps!',
    },
    'quickFeedback': {'zh': '快速反馈', 'en': 'Quick Feedback'},
    'nodAndImprove': {'zh': '轻点选择，快速吐槽', 'en': 'Quick select, fast feedback'},
    'uiBeautiful': {
      'zh': '界面很漂亮，体验很棒！',
      'en': 'Beautiful UI, great experience!',
    },
    'moreTemplates': {
      'zh': '希望增加更多笔记模板',
      'en': 'Hope to add more note templates',
    },
    'fasterSync': {'zh': '同步速度可以更快一些', 'en': 'Sync speed can be faster'},
    'moreFormats': {
      'zh': '希望支持更多文件格式',
      'en': 'Hope to support more file formats',
    },
    'featureSuggestion': {'zh': '功能建议', 'en': 'Feature Suggestion'},
    'problemReport': {'zh': '问题反馈', 'en': 'Problem Report'},
    'uiOptimization': {'zh': '界面优化', 'en': 'UI Optimization'},
    'performanceIssue': {'zh': '性能问题', 'en': 'Performance Issue'},
    'other': {'zh': '其他', 'en': 'Other'},
    'feedbackTypeRequired': {'zh': '反馈类型', 'en': 'Feedback Type'},
    'pleaseSelectFeedbackType': {
      'zh': '请选择建议类型',
      'en': 'Please select feedback type',
    },
    'contactMethod': {'zh': '联系方式', 'en': 'Contact Method'},
    'contactPlaceholder': {
      'zh': '请输入邮箱或其他联系方式（选填）',
      'en': 'Email or other contact (optional)',
    },
    'feedbackContentRequired': {'zh': '反馈内容', 'en': 'Feedback Content'},
    'feedbackContentPlaceholder': {
      'zh': '请详细描述您遇到的问题或建议...\n\n我们会认真对待每一条反馈，并尽快回复您。',
      'en':
          'Please describe your issue or suggestion...\n\nWe take every feedback seriously and will respond soon.',
    },
    'sendFeedback': {'zh': '发送反馈', 'en': 'Send Feedback'},
    'deleteAllFeedback': {'zh': '清除所有反馈记录', 'en': 'Clear All Feedback'},
    'copyEmail': {'zh': '复制邮箱', 'en': 'Copy Email'},
    'feedbackSuccess': {'zh': '反馈发送成功！', 'en': 'Feedback sent successfully!'},
    'feedbackSuccessMessage': {
      'zh': '感谢您的反馈！我们会认真阅读并尽快回复您。',
      'en':
          'Thank you for your feedback! We will read it carefully and reply soon.',
    },
    'feedbackFailed': {
      'zh': '发送失败，已为您复制反馈内容到剪贴板',
      'en': 'Send failed, feedback content copied to clipboard',
    },
    'feedbackCopied': {
      'zh': '反馈内容已复制到剪贴板\n您可以直接发送到：',
      'en': 'Feedback content copied to clipboard\nYou can send directly to: ',
    },

    // ===== 导入导出页面 =====
    'importExport': {'zh': '导入导出', 'en': 'Import/Export'},
    'localBackupRestore': {'zh': '本地备份与恢复', 'en': 'Local Backup & Restore'},
    'localBackupDescription': {
      'zh': '备份数据到本地文件，或从本地文件恢复数据',
      'en': 'Backup data to local files or restore from local files',
    },
    'flomoImport': {'zh': 'Flomo 笔记导入', 'en': 'Flomo Note Import'},
    'flomoImportDescription': {
      'zh': '从 Flomo 导出的 HTML 文件导入笔记',
      'en': 'Import notes from Flomo exported HTML files',
    },
    'backupTip': {
      'zh': '💡 提示：建议定期备份数据，以防数据丢失。导入数据前请仔细检查文件格式。',
      'en':
          '💡 Tip: Regular backups recommended. Please verify file format before importing.',
    },
    'browserExtension': {'zh': 'Memos 浏览器插件', 'en': 'Memos Browser Extension'},
    'browserExtensionDescription': {
      'zh': '社区开发的浏览器扩展，支持 Chrome/Edge，可快速保存网页内容到 Memos',
      'en':
          'Community-developed browser extension for Chrome/Edge to save web content to Memos',
    },
    'exportTab': {'zh': '导出备份', 'en': 'Export'},
    'importTab': {'zh': '导入历史', 'en': 'Import'},
    'backupInfoTitle': {'zh': '备份信息', 'en': 'Backup Info'},
    'lastBackupTime': {'zh': '上次备份', 'en': 'Last Backup'},
    'neverBackedUp': {'zh': '从未备份', 'en': 'Never Backed Up'},
    'backupedNotes': {'zh': '备份笔记', 'en': 'Backed up Notes'},
    'backupSizeLabel': {'zh': '备份大小', 'en': 'Backup Size'},
    'exportOptionsTitle': {'zh': '导出选项', 'en': 'Export Options'},
    'exportFormatLabel': {'zh': '导出格式', 'en': 'Export Format'},
    'includeImagesLabel': {'zh': '包含图片', 'en': 'Include Images'},
    'includeImagesDescription': {
      'zh': '将笔记中的图片一同导出',
      'en': 'Export images in notes',
    },
    'includeTagsLabel': {'zh': '包含标签', 'en': 'Include Tags'},
    'includeTagsDescription': {'zh': '保留笔记的标签信息', 'en': 'Keep tag information'},
    'encryptionOptionsTitle': {'zh': '加密选项', 'en': 'Encryption Options'},
    'encryptBackupLabel': {'zh': '加密备份', 'en': 'Encrypt Backup'},
    'encryptBackupDescription': {
      'zh': '使用密码加密您的备份文件',
      'en': 'Encrypt your backup with password',
    },
    'encryptionPasswordLabel': {'zh': '加密密码', 'en': 'Encryption Password'},
    'startExportButton': {'zh': '导出备份', 'en': 'Export Backup'},
    'startImportButton': {'zh': '导入备份', 'en': 'Import Backup'},

    // ===== AI设置页面 =====
    'enableAIAssistant': {'zh': '启用AI助手', 'en': 'Enable AI Assistant'},
    'aiAssistantDescription': {
      'zh': '开启后可使用AI辅助功能',
      'en': 'Enable AI-powered features',
    },
    'apiConfigurationTitle': {'zh': 'API配置', 'en': 'API Configuration'},
    'apiAddressLabel': {'zh': 'API地址', 'en': 'API Address'},
    'apiKeyLabel': {'zh': 'API密钥', 'en': 'API Key'},
    'getAPIKey': {'zh': '获取API密钥', 'en': 'Get API Key'},
    'aiModelTitle': {'zh': 'AI模型', 'en': 'AI Model'},
    'modelSelectionTitle': {'zh': '模型选择', 'en': 'Model Selection'},
    'resetAppSettingsDescription': {
      'zh': '恢复所有设置为默认状态，不会删除笔记数据',
      'en': 'Reset all settings, notes will not be deleted',
    },

    // ===== 随机回顾页面 =====
    'randomReviewTitle': {'zh': '随机回顾', 'en': 'Random Review'},
    'noNotesToReview': {'zh': '没有可回顾的笔记', 'en': 'No notes to review'},
    'reviewSettings': {'zh': '回顾设置', 'en': 'Review Settings'},
    'reviewTimeRange': {'zh': '回顾时间范围：', 'en': 'Review Time Range:'},
    'reviewNotesCount': {'zh': '回顾笔记数量：', 'en': 'Number of Notes:'},
    'all': {'zh': '全部', 'en': 'All'},
    'days': {'zh': '天', 'en': 'days'},
    'items': {'zh': '条', 'en': ''},
    'lastEdited': {'zh': '最后编辑', 'en': 'Last Edited'},
    'itemsNote': {'zh': '条笔记', 'en': 'notes'},

    // ===== 反馈页面补充 =====
    'feedbackTitle': {'zh': '意见反馈', 'en': 'Feedback'},
    'feedbackWelcome': {
      'zh': '我们致力于为您提供最好的体验。您的每一个建议和反馈，都是我们前进的动力！',
      'en':
          'We are committed to providing you with the best experience. Every suggestion and feedback is our driving force!',
    },
    'enterEmailOrWechat': {
      'zh': '请输入您的邮箱或微信号（选填）',
      'en': 'Enter your email or WeChat (optional)',
    },
    'enterFeedbackContent': {'zh': '请输入您的反馈内容', 'en': 'Enter your feedback'},
    'sending': {'zh': '发送中...', 'en': 'Sending...'},
    'developerEmail': {'zh': '开发团队邮箱：', 'en': 'Developer Email: '},
    'feedbackResponseTime': {
      'zh': '我们会在 1-3 个工作日内回复您的反馈',
      'en': 'We will respond to your feedback within 1-3 business days',
    },
    'complete': {'zh': '完成', 'en': 'Complete'},

    // ===== 通用计量单位 =====
    'dayUnit': {'zh': '天', 'en': 'day(s)'},
    'noteUnit': {'zh': '条', 'en': ''},
    'minutesAgo': {'zh': '分钟前', 'en': 'minutes ago'},
    'hoursAgo': {'zh': '小时前', 'en': 'hours ago'},
    'daysAgo': {'zh': '天前', 'en': 'days ago'},
    'weeksAgo': {'zh': '周前', 'en': 'weeks ago'},
    'monthsAgo': {'zh': '个月前', 'en': 'months ago'},

    // ===== 导出导入补充 =====
    'exportSuccess': {'zh': '导出成功', 'en': 'Export Success'},
    'importSuccess': {'zh': '导入成功', 'en': 'Import Success'},
    'importing': {'zh': '导入中...', 'en': 'Importing...'},
    'exportComplete': {'zh': '导出完成', 'en': 'Export Complete'},
    'importComplete': {'zh': '导入完成', 'en': 'Import Complete'},
    'backupFileExported': {
      'zh': '备份文件已成功导出',
      'en': 'Backup file exported successfully',
    },
    'dataImported': {'zh': '数据已成功导入', 'en': 'Data imported successfully'},

    // ===== 服务器信息页面 =====
    'serverInfoReadOnlyNotice': {
      'zh': '此页面仅用于查看服务器连接状态和同步日志\n服务器设置请在登录页面配置',
      'en':
          'This page is for viewing server connection status and sync logs only\nPlease configure server settings on the login page',
    },
    'connectionInfoReadOnly': {
      'zh': '连接信息（只读）',
      'en': 'Connection Info (Read-only)',
    },
    'notConfigured': {
      'zh': '未配置',
      'en': 'Not Configured',
    },
    'enabled': {
      'zh': '已启用',
      'en': 'Enabled',
    },
    'disabled': {
      'zh': '未启用',
      'en': 'Disabled',
    },
    'modifyServerSettingsHint': {
      'zh': '要修改服务器设置，请退出登录后在登录页面配置',
      'en':
          'To modify server settings, please logout and configure on the login page',
    },
    'connectionLog': {
      'zh': '连接日志',
      'en': 'Connection Log',
    },
    'noLogRecords': {
      'zh': '暂无日志记录',
      'en': 'No log records',
    },

    // ===== 通知页面 =====
    'clear': {'zh': '清除', 'en': 'Clear'},
    'markAllRead': {'zh': '全部已读', 'en': 'Mark All Read'},
    'noNotifications': {'zh': '暂无通知', 'en': 'No notifications'},
    'noNotificationsMessage': {
      'zh': '您目前没有新的通知消息',
      'en': 'You have no new notifications',
    },
    'earlier': {'zh': '更早', 'en': 'Earlier'},
    'notificationDeleted': {'zh': '已删除通知', 'en': 'Notification deleted'},
    'refreshNotificationsFailed': {
      'zh': '刷新通知失败，请检查网络连接',
      'en': 'Failed to refresh notifications, please check network',
    },
    'markedAllAsRead': {'zh': '已全部标记为已读', 'en': 'All marked as read'},
    'operationFailed': {'zh': '操作失败', 'en': 'Operation failed'},
    'noReadNotificationsToDelete': {
      'zh': '没有已读通知可清除',
      'en': 'No read notifications to delete',
    },
    'clearReadNotifications': {
      'zh': '清除已读通知',
      'en': 'Clear Read Notifications',
    },
    'confirmClearReadNotifications': {
      'zh': '确定要清除 {count} 条已读通知吗？此操作不可恢复。',
      'en': 'Clear {count} read notifications? This cannot be undone.',
    },
    'notificationsCleared': {
      'zh': '已清除 {count} 条通知',
      'en': 'Cleared {count} notifications',
    },
    'clearFailed': {'zh': '清除失败', 'en': 'Clear failed'},
    'viewDetails': {'zh': '查看详情', 'en': 'View Details'},
    'serverResponseError': {'zh': '服务器响应错误', 'en': 'Server response error'},
    'syncWarning': {
      'zh': '同步警告: 距离上次同步已超过{hours}小时',
      'en': 'Sync warning: {hours} hours since last sync',
    },
    'notLoggedInPleaseLogin': {
      'zh': '当前未登录，请配置服务器并登录',
      'en': 'Not logged in, please configure server and login',
    },
    'startingSyncData': {'zh': '开始同步数据...', 'en': 'Starting data sync...'},
    'syncFailedNotLoggedIn': {
      'zh': '同步失败: 未登录',
      'en': 'Sync failed: Not logged in',
    },
    'syncFailedPleaseLogin': {
      'zh': '同步失败: 请先登录',
      'en': 'Sync failed: Please login first',
    },
    'syncingLocalDataToServer': {
      'zh': '正在同步本地数据到服务器...',
      'en': 'Syncing local data to server...',
    },
    'gettingLatestDataFromServer': {
      'zh': '正在从服务器获取最新数据...',
      'en': 'Getting latest data from server...',
    },
    'syncSuccessMessage': {'zh': '同步成功', 'en': 'Sync successful'},
    'syncFailedMessage': {'zh': '同步失败', 'en': 'Sync failed'},
    'startingConnectionDiagnosis': {
      'zh': '开始连接诊断...',
      'en': 'Starting connection diagnosis...',
    },
    'serverAddressNotConfigured': {
      'zh': '未配置服务器地址',
      'en': 'Server address not configured',
    },
    'diagnosisFailedNoServerAddress': {
      'zh': '诊断失败: 未配置服务器地址',
      'en': 'Diagnosis failed: No server address configured',
    },
    'parsingServerAddress': {
      'zh': '解析服务器地址...',
      'en': 'Parsing server address...',
    },
    'protocol': {'zh': '协议', 'en': 'Protocol'},
    'parseServerAddressFailed': {
      'zh': '解析服务器地址失败',
      'en': 'Failed to parse server address',
    },
    'diagnosisFailedInvalidAddress': {
      'zh': '诊断失败: 服务器地址无效',
      'en': 'Diagnosis failed: Invalid server address',
    },
    'checkingDNSResolution': {
      'zh': '检查DNS解析...',
      'en': 'Checking DNS resolution...',
    },
    'dnsResolutionSuccess': {
      'zh': 'DNS解析成功，耗时: {ms}ms',
      'en': 'DNS resolution successful, {ms}ms',
    },
    'dnsResolutionFailed': {'zh': 'DNS解析失败', 'en': 'DNS resolution failed'},
    'testingAPIConnection': {
      'zh': '测试API连接...',
      'en': 'Testing API connection...',
    },
    'apiConnectionSuccess': {
      'zh': 'API连接成功，响应时间: {ms}ms',
      'en': 'API connection successful, {ms}ms',
    },

    // ===== 导入导出页面补充 =====
    'fileName': {'zh': '文件名', 'en': 'File name'},
    'youCan': {'zh': '您可以：', 'en': 'You can:'},
    'shareBackupFile': {'zh': '分享备份文件', 'en': 'Share backup file'},
    'saveToDevice': {'zh': '保存到设备', 'en': 'Save to device'},
    'shareFailed': {'zh': '分享失败: 文件不存在', 'en': 'Share failed: File not found'},
    'successfullyImported': {'zh': '成功导入', 'en': 'Successfully imported'},
    'selectExportMethod': {'zh': '选择导出方式', 'en': 'Select Export Method'},
    'selectHowToSaveExportedFile': {
      'zh': '请选择要如何保存导出的文件：',
      'en': 'Please select how to save the exported file:',
    },

    // ===== 时间分组 =====
    'thisWeek': {'zh': '本周', 'en': 'This Week'},
    'thisMonth': {'zh': '本月', 'en': 'This Month'},

    // ===== 帮助中心 =====
    'quickStartGuide': {'zh': '快速入门指南', 'en': 'Quick Start Guide'},
    'welcomeToInkRoot': {
      'zh': '欢迎使用InkRoot-墨鸣笔记',
      'en': 'Welcome to InkRoot Notes',
    },
    'coreFeatures': {'zh': '核心特色', 'en': 'Core Features'},
    'minimalistDesign': {'zh': '极简设计', 'en': 'Minimalist Design'},
    'crossPlatform': {'zh': '跨平台支持', 'en': 'Cross-Platform'},
    'perfectCompatibility': {'zh': '完美兼容', 'en': 'Perfect Compatibility'},
    'dataSecurity': {'zh': '数据安全', 'en': 'Data Security'},
    'smartTags': {'zh': '智能标签', 'en': 'Smart Tags'},
    'appArchitecture': {'zh': '应用架构', 'en': 'App Architecture'},
    'platformSupport': {'zh': '平台支持', 'en': 'Platform Support'},
    'firstTimeUse': {'zh': '初次使用', 'en': 'First-Time Use'},
    'downloadInstall': {'zh': '下载安装', 'en': 'Download & Install'},
    'memosServerSetup': {'zh': 'Memos服务器准备', 'en': 'Memos Server Setup'},
    'serverConnection': {'zh': '服务器连接', 'en': 'Server Connection'},
    'accountLogin': {'zh': '账户登录', 'en': 'Account Login'},
    'createFirstNote': {'zh': '创建首条笔记', 'en': 'Create First Note'},

    // ===== 关于页面 =====
    'aboutInkRoot': {'zh': '关于InkRoot', 'en': 'About InkRoot'},
    'appTagline': {
      'zh': '静待沉淀，蓄势而鸣。\n你的每一次落笔，都是未来生长的根源。',
      'en':
          'Settle patiently, then speak with force.\nEvery note you take becomes a root for what comes next.',
    },
    'appIntroduction': {
      'zh': 'InkRoot 是一款面向个人记录和知识整理的笔记应用。你可以本地使用，也可以连接官方服务器或自部署 Memos 服务同步笔记。',
      'en':
          'InkRoot is a note app for personal capture and knowledge organization. You can use it locally, connect to the official server, or sync with a self-hosted Memos service.',
    },
    'appTechDescription': {
      'zh': '这些是当前版本已经开放的主要能力。不同 Memos 服务器版本的接口能力不同，应用会按服务器版本自动适配并尽量降级处理。',
      'en':
          'These are the main capabilities available in this version. Memos server APIs vary by version, so the app adapts to the detected server version and falls back where needed.',
    },
    'technicalDetails': {
      'zh':
          '当前支持 Android、iOS、macOS、Windows 和 Linux。应用提供富文本式编辑、Markdown 渲染、图片、标签、搜索、提醒、随机回顾、WebDAV 备份、导入导出和可选 AI 功能。',
      'en':
          'InkRoot currently supports Android, iOS, macOS, Windows, and Linux. It includes rich-text-style editing, Markdown rendering, images, tags, search, reminders, random review, WebDAV backup, import/export, and optional AI features.',
    },
    'securityCommitment': {
      'zh': '笔记优先保存在本机。登录、同步、WebDAV 和 AI 相关配置由你主动设置；自部署服务中的数据由对应服务器保存和管理。',
      'en':
          'Notes are stored locally first. Login, sync, WebDAV, and AI settings are configured by you; data on self-hosted services is stored and managed by those servers.',
    },
    'coreFeaturesTitle': {'zh': '核心功能', 'en': 'Core Features'},
    'contactUs': {'zh': '联系我们', 'en': 'Contact Us'},
    'contactMessage': {
      'zh': '我们非常重视用户的反馈和建议。如果您有任何问题、意见或合作意向，请随时与我们联系。',
      'en':
          'We value your feedback and suggestions. If you have any questions, comments, or collaboration proposals, please feel free to contact us.',
    },
    'feedbackSuggestions': {'zh': '反馈建议', 'en': 'Feedback & Suggestions'},
    'clickToSubmitFeedback': {
      'zh': '点击提交反馈建议',
      'en': 'Click to submit feedback',
    },
    'officialWebsite': {'zh': '官方网站', 'en': 'Official Website'},
    'communicationAddress': {'zh': '交流地址', 'en': 'Community'},
    'copyrightInfo': {'zh': '版权信息', 'en': 'Copyright'},
    'opening': {'zh': '正在打开', 'en': 'Opening'},

    // ===== 功能标签 =====
    'memosExclusiveVersion': {
      'zh': 'Memos 多版本适配',
      'en': 'Memos Version Compatibility',
    },
    'markdownSupport': {'zh': 'Markdown支持', 'en': 'Markdown Support'},
    'intelligentTagSystem': {'zh': '层级标签', 'en': 'Nested Tags'},
    'fullTextSearch': {'zh': '全文搜索', 'en': 'Full-Text Search'},
    'randomReviewFeature': {'zh': '随机回顾', 'en': 'Random Review'},
    'dataStatistics': {'zh': '数据统计', 'en': 'Data Statistics'},
    'realtimeSync': {'zh': '实时同步', 'en': 'Real-time Sync'},
    'localEncryption': {'zh': '本地加密', 'en': 'Local Encryption'},
    'multiTheme': {'zh': '多主题切换', 'en': 'Multi-Theme'},
    'offlineUse': {'zh': '离线使用', 'en': 'Offline Use'},
    'dataExport': {'zh': '数据导出', 'en': 'Data Export'},
    'imageManagement': {'zh': '图片管理', 'en': 'Image Management'},
    'privateDeployment': {'zh': '私有化部署', 'en': 'Private Deployment'},
    'lastUpdated': {
      'zh': '最后更新日期：{year}年{month}月{day}日',
      'en': 'Last Updated: {month}/{day}/{year}',
    },
    'agreementAcceptance': {'zh': '协议接受', 'en': 'Agreement Acceptance'},
    'welcomeMessage': {
      'zh':
          '欢迎使用{appName}！通过下载、安装或使用{appName}应用程序（以下简称"应用"或"服务"），您同意受本用户协议（以下简称"协议"）的约束。如果您不同意本协议的任何条款，请不要使用我们的服务。',
      'en':
          'Welcome to {appName}! By downloading, installing, or using the {appName} application (hereinafter referred to as "App" or "Service"), you agree to be bound by this User Agreement (hereinafter referred to as "Agreement"). If you do not agree to any of the terms of this Agreement, please do not use our Service.',
    },
    'importantReminder': {'zh': '重要提醒：', 'en': 'Important Notice:'},
    'serviceDescription': {'zh': '服务描述', 'en': 'Service Description'},
    'userResponsibilities': {
      'zh': '用户责任与义务',
      'en': 'User Responsibilities and Obligations',
    },
    'userResponsibilitiesContent': {
      'zh': '使用{appName}时，您同意并承诺：',
      'en': 'When using {appName}, you agree and promise to:',
    },
    'userContentResponsibility': {
      'zh': '您对通过应用创建、存储或传输的所有内容承担完全责任。',
      'en':
          'You are fully responsible for all content created, stored, or transmitted through the app.',
    },
    'dataOwnership': {'zh': '数据所有权', 'en': 'Data Ownership'},
    'dataOwnershipDeclaration': {'zh': '重要声明：', 'en': 'Important Declaration:'},
    'userContentControl': {
      'zh': '您保留对自己创建的所有内容的完整控制权。',
      'en': 'You retain complete control over all content you create.',
    },
    'disclaimer': {'zh': '免责声明', 'en': 'Disclaimer'},
    'disclaimerContent': {
      'zh':
          '您理解并同意，使用{appName}的风险完全由您自己承担。在适用法律允许的最大范围内，我们不承担任何直接、间接、偶然、特殊或后果性损害的责任，包括但不限于数据丢失、业务中断、利润损失等。',
      'en':
          'You understand and agree that you use {appName} entirely at your own risk. To the maximum extent permitted by applicable law, we are not liable for any direct, indirect, incidental, special, or consequential damages, including but not limited to data loss, business interruption, or loss of profits.',
    },
    'intellectualProperty': {'zh': '知识产权', 'en': 'Intellectual Property'},
    'openSourceRights': {
      'zh': '作为开源软件，{appName}在MIT许可证下发布，您享有以下权利：',
      'en':
          'As open-source software, {appName} is released under the MIT License, granting you the following rights:',
    },
    'openSourceObligations': {
      'zh': '使用本软件时，您必须：',
      'en': 'When using this software, you must:',
    },
    'userContentOwnership': {
      'zh': '您对自己创建的笔记内容拥有完整的知识产权，我们不声明对您的内容拥有任何权利。',
      'en':
          'You own full intellectual property rights to the notes you create. We make no claim to any rights to your content.',
    },
    'serviceChangesTermination': {
      'zh': '服务变更与终止',
      'en': 'Service Changes and Termination',
    },
    'serviceModificationRights': {
      'zh': '我们保留随时修改、更新或改进服务的权利，可能包括：',
      'en':
          'We reserve the right to modify, update, or improve the Service at any time, which may include:',
    },
    'majorChangeNotifications': {
      'zh': '重大变更将通过以下方式通知用户：',
      'en': 'Major changes will be communicated to users through:',
    },
    'serviceSuspensionConditions': {
      'zh': '在以下情况下，我们可能暂停或终止服务：',
      'en':
          'We may suspend or terminate the Service under the following circumstances:',
    },
    'terminationNotice': {
      'zh': '终止前我们将尽合理努力提前通知用户。',
      'en':
          'We will make reasonable efforts to notify users in advance of termination.',
    },
    'agreementModifications': {'zh': '协议修改', 'en': 'Agreement Modifications'},
    'agreementUpdatePolicy': {
      'zh':
          '我们可能会不时更新本用户协议。重大变更会在应用中显著展示，并要求您重新同意。\n\n继续使用应用即表示您接受修改后的协议。如果您不同意修改后的条款，应停止使用应用并可卸载软件。',
      'en':
          'We may update this User Agreement from time to time. Major changes will be prominently displayed in the app and will require your re-consent.\n\nContinued use of the app indicates your acceptance of the modified agreement. If you do not agree to the modified terms, you should stop using the app and may uninstall the software.',
    },
    'termination': {'zh': '终止', 'en': 'Termination'},
    'userTerminationRights': {
      'zh': '您可以随时停止使用InkRoot并删除应用。\n\n我们也可能在以下情况下终止您的访问权限：',
      'en':
          'You may stop using InkRoot and delete the app at any time.\n\nWe may also terminate your access under the following circumstances:',
    },
    'postTerminationObligations': {
      'zh': '终止后，您应停止使用应用并删除所有副本。',
      'en':
          'After termination, you should stop using the app and delete all copies.',
    },
    'disputeResolution': {'zh': '争议解决', 'en': 'Dispute Resolution'},
    'disputeNegotiation': {
      'zh':
          '因本协议产生的任何争议，双方应首先通过友好协商解决。协商时应本着诚实守信、互相尊重的原则。\n\n如协商无法解决争议，任何一方可向有管辖权的人民法院提起诉讼。诉讼过程中，本协议的其他条款仍应继续履行。\n\n争议协商请联系：{email}',
      'en':
          'Any disputes arising from this Agreement shall first be resolved through friendly negotiation. Negotiations should be conducted in good faith and with mutual respect.\n\nIf negotiation fails to resolve the dispute, either party may file a lawsuit with a court of competent jurisdiction. During litigation, the other provisions of this Agreement shall continue to be performed.\n\nFor dispute negotiation, contact: {email}',
    },
    'otherTerms': {'zh': '其他条款', 'en': 'Other Terms'},
    'entireAgreement': {
      'zh':
          '本协议构成双方就本服务达成的完整协议，取代之前的所有口头或书面协议。\n\n如本协议的任何条款被认定为无效或不可执行，其余条款仍然有效。\n\n本协议自您接受之日起生效，对之前的使用行为具有追溯效力。\n\n本协议以中文为准。如有其他语言版本，仅供参考，以中文版本为准。',
      'en':
          'This Agreement constitutes the entire agreement between the parties regarding the Service, superseding all prior oral or written agreements.\n\nIf any provision of this Agreement is deemed invalid or unenforceable, the remaining provisions shall remain in effect.\n\nThis Agreement takes effect from the date of your acceptance and has retroactive effect on prior use.\n\nThe Chinese version of this Agreement shall prevail. If there are versions in other languages, they are for reference only.',
    },
    'governingLaw': {'zh': '适用法律与管辖', 'en': 'Governing Law and Jurisdiction'},
    'lawJurisdiction': {
      'zh':
          '本协议的签订、效力、解释、履行和争议解决均适用中华人民共和国法律法规，不考虑法律冲突原则。\n\n因本协议引起的争议，由{address}所在地有管辖权的人民法院管辖。\n\n本协议在法律允许的范围内对双方具有约束力。如本协议与法律法规相冲突，以法律法规为准。',
      'en':
          "The conclusion, validity, interpretation, performance, and dispute resolution of this Agreement shall be governed by the laws and regulations of the People's Republic of China, without regard to conflict of law principles.\n\nDisputes arising from this Agreement shall be under the jurisdiction of the people's court with jurisdiction in the location of {address}.\n\nThis Agreement is binding on both parties to the extent permitted by law. If this Agreement conflicts with laws and regulations, the laws and regulations shall prevail.",
    },
    'contactUsAgreement': {'zh': '联系我们', 'en': 'Contact Us'},
    'contactInfo': {
      'zh':
          '如果您对本用户协议有任何疑问，请通过以下方式联系我们：\n\n反馈建议：设置 → 反馈建议（推荐）\n邮箱：{email}\n应用内反馈：设置 → 意见反馈',
      'en':
          'If you have any questions about this User Agreement, please contact us through:\n\nFeedback: Settings → Feedback (Recommended)\nEmail: {email}\nIn-app Feedback: Settings → Feedback',
    },
    'closingMessage': {
      'zh': '感谢您选择{appName}！我们致力于为您提供最佳的笔记体验。\n\n如您对本协议有任何疑问，请随时联系我们。',
      'en':
          'Thank you for choosing {appName}! We are committed to providing you with the best note-taking experience.\n\nIf you have any questions about this Agreement, please feel free to contact us.',
    },

    // ===== 忘记密码页面 =====
    'forgotPassword': {'zh': '找回密码', 'en': 'Forgot Password'},
    'functionDescription': {'zh': '功能说明', 'en': 'Function Description'},
    'forgotPasswordHelp': {
      'zh':
          'Memos服务器暂不支持在线密码重置功能。\n\n如果忘记密码，请：\n\n1. 联系服务器管理员重置密码\n2. 或通过服务器后台管理界面重置\n3. 如果是自建服务器，可通过数据库直接修改',
      'en':
          'Memos server does not currently support online password reset.\n\nIf you forgot your password, please:\n\n1. Contact the server administrator to reset your password\n2. Or reset through the server backend management interface\n3. If it is a self-hosted server, you can modify it directly through the database',
    },
    'backToLogin': {'zh': '返回登录', 'en': 'Back to Login'},
    'learnMore': {'zh': '了解详情', 'en': 'Learn More'},

    // ===== 导入导出页面补充 =====
    'importDescription': {'zh': '导入说明', 'en': 'Import Description'},
    'supportedFormatsDescription': {
      'zh': '支持导入以下格式的备份文件：',
      'en': 'Supported import formats:',
    },
    'markdownBatchImport': {
      'zh': '支持批量导入Markdown文件',
      'en': 'Batch import Markdown files supported',
    },
    'txtImportDescription': {
      'zh': '纯文本文件将作为单独笔记导入',
      'en': 'Text files will be imported as separate notes',
    },
    'htmlImportDescription': {
      'zh': '支持从其他笔记软件导出的HTML',
      'en': 'HTML exported from other note apps supported',
    },
    'importWarning': {
      'zh': '导入操作可能会影响现有数据，建议先备份当前数据',
      'en': 'Import may affect existing data, backup recommended',
    },
    'overwriteExistingNotes': {
      'zh': '覆盖现有笔记',
      'en': 'Overwrite Existing Notes',
    },
    'overwriteDescription': {
      'zh': '如果导入的笔记与现有笔记ID相同，则覆盖现有笔记',
      'en': 'Overwrite notes if IDs match',
    },
    'importAsNewNotes': {'zh': '作为新笔记导入', 'en': 'Import as New Notes'},
    'importAsNewDescription': {
      'zh': '所有导入的笔记将作为新笔记添加，不会影响现有笔记',
      'en': 'All imported notes will be added as new notes',
    },
    'importHistory': {'zh': '导入历史', 'en': 'Import History'},
    'refreshImportHistory': {'zh': '刷新导入历史', 'en': 'Refresh Import History'},
    'noImportHistory': {'zh': '暂无导入历史记录', 'en': 'No import history'},
    'setPassword': {'zh': '设置密码', 'en': 'Set Password'},
    'rememberPasswordWarning': {
      'zh': '请记住您的密码，如果忘记将无法恢复备份数据',
      'en': 'Remember your password, lost passwords cannot be recovered',
    },
    'exporting': {'zh': '导出中...', 'en': 'Exporting...'},

    // ===== 数据清理页面补充 =====
    'cleanCacheConfirm': {
      'zh': '此操作将清除应用缓存，可能会影响短期使用体验。是否继续？',
      'en':
          'This will clear app cache and may affect short-term user experience. Continue?',
    },
    'cacheCleanedSuccess': {'zh': '缓存已清理', 'en': 'Cache cleared'},
    'cleanCacheFailed': {'zh': '清理缓存失败', 'en': 'Failed to clear cache'},
    'imagesCleanedSuccess': {'zh': '图片已清理', 'en': 'Images cleared'},
    'cleanImagesFailed': {'zh': '清理图片失败', 'en': 'Failed to clear images'},
    'confirmReset': {'zh': '确认重置', 'en': 'Confirm Reset'},
    'resetSettingsConfirm': {
      'zh': '此操作将重置所有应用设置到默认状态，但不会删除笔记数据。是否继续？',
      'en':
          "This will reset all app settings to default, but won't delete notes. Continue?",
    },
    'settingsResetSuccess': {'zh': '应用设置已重置', 'en': 'App settings reset'},
    'resetSettingsFailed': {'zh': '重置设置失败', 'en': 'Failed to reset settings'},
    'historyCleanedSuccess': {
      'zh': '导入导出历史已清理',
      'en': 'Import/export history cleared',
    },
    'cleanHistoryFailed': {'zh': '清理历史失败', 'en': 'Failed to clear history'},
    'cleanupOperations': {'zh': '清理操作', 'en': 'Cleanup Operations'},
    'advancedOperations': {'zh': '高级操作', 'en': 'Advanced Operations'},
    'cleanCache': {'zh': '清除缓存', 'en': 'Clean Cache'},
    'cleanCacheDescription': {
      'zh': '删除临时文件和缓存，不会影响笔记数据',
      'en': 'Delete temporary files and cache, will not affect note data',
    },
    'cleanUnusedImages': {'zh': '清理未使用图片', 'en': 'Clean Unused Images'},
    'cleanUnusedImagesDescription': {
      'zh': '卸载被删除笔记引用的图片文件',
      'en': 'Remove images from deleted notes',
    },
    'cleanImportExportHistory': {
      'zh': '清理导入导出历史',
      'en': 'Clean Import/Export History',
    },
    'cleanImportExportDescription': {
      'zh': '删除所有导入/export历史记录',
      'en': 'Delete all import/export history records',
    },
    'resetAppSettings': {'zh': '重置应用设置', 'en': 'Reset App Settings'},
    'resetAppDescription': {
      'zh': '恢复所有设置到默认状态，不会删除笔记数据',
      'en': "Restore all settings to default, won't delete notes",
    },
    'deleteAllNotes': {'zh': '清理所有笔记', 'en': 'Delete All Notes'},
    'deleteAllNotesWarning': {
      'zh': 'Danger: Delete all local data, cannot be undone',
      'en': 'Danger: Delete all local data, cannot be undone',
    },
    'selectTagToView': {
      'zh': '选择一个标签以查看相关笔记',
      'en': 'Select a tag to view related notes',
    },

    // ===== 服务器信息页面 =====
    'notSynced': {'zh': '未同步', 'en': 'Not Synced'},
    'connected': {'zh': '已连接', 'en': 'Connected'},
    'justNow': {'zh': '刚刚', 'en': 'Just now'},
    'connectionAbnormal': {'zh': '连接异常', 'en': 'Connection Abnormal'},
    'timeout': {'zh': '超时', 'en': 'Timeout'},
    'initializingServerConnection': {
      'zh': '初始化服务器连接页面...',
      'en': 'Initializing server connection page...',
    },
    'loggedInStatusDetected': {
      'zh': '检测到已登录状态',
      'en': 'Logged-in status detected',
    },
    'currentServer': {'zh': '当前服务器', 'en': 'Current server'},
    'usingProtocol': {'zh': '使用协议', 'en': 'Protocol'},
    'parseServerUrlFailed': {
      'zh': '解析服务器 URL 失败',
      'en': 'Failed to parse server URL',
    },

    // ===== 登录页面 =====
    'loginFailedCheckCredentials': {
      'zh': '登录失败，请检查账号密码和服务器地址',
      'en': 'Login failed, please check your credentials and server address',
    },
    'loginSuccessful': {'zh': '登录成功！', 'en': 'Login Successful!'},
    'welcomeBackPreparingSpace': {
      'zh': '欢迎回来！正在为您准备个人笔记空间...',
      'en': 'Welcome back! Preparing your personal note space...',
    },
    'intelligentNoteManagement': {
      'zh': '静待沉淀，\n蓄势而鸣',
      'en': 'Settle patiently,\nthen speak with force',
    },
    'welcomeBack': {'zh': '欢迎回来', 'en': 'Welcome Back'},
    'continueCreativeJourney': {
      'zh': '继续您的创作之旅',
      'en': 'Continue your creative journey',
    },
    'createAccount': {'zh': '创建账户', 'en': 'Create Account'},
    'startYourCreativeJourney': {
      'zh': '开启您的创作之旅',
      'en': 'Start your creative journey',
    },
    'onlySupportsMemosVersion': {
      'zh': '支持多个 Memos 版本',
      'en': 'Supports multiple Memos versions',
    },
    'pleaseEnterUsername': {'zh': '请输入用户名', 'en': 'Please enter username'},
    'usernameMinLength': {
      'zh': '用户名至少需要2个字符',
      'en': 'Username must be at least 2 characters',
    },
    'usernameNoSpaces': {
      'zh': '用户名不能包含空格',
      'en': 'Username cannot contain spaces',
    },
    'pleaseEnterPassword': {'zh': '请输入密码', 'en': 'Please enter password'},
    'passwordMinLength': {
      'zh': '密码至少需要6个字符',
      'en': 'Password must be at least 6 characters',
    },
    'server': {'zh': '服务器', 'en': 'Server'},
    'customServer': {'zh': '自定义服务器', 'en': 'Custom Server'},
    'officialServer': {'zh': '官方服务器', 'en': 'Official Server'},
    'recommended': {'zh': '推荐使用', 'en': 'Recommended'},
    'serverAddressMustStartWithHttp': {
      'zh': '服务器地址必须以 http:// 或 https:// 开头',
      'en': 'Server address must start with http:// or https://',
    },
    'change': {'zh': '更改', 'en': 'Change'},
    'customize': {'zh': '自定义', 'en': 'Customize'},
    'rememberPassword': {'zh': '记住密码', 'en': 'Remember Password'},
    'saveAccountLocally': {
      'zh': '保存账号和密码到本地',
      'en': 'Save account and password locally',
    },
    'noAccount': {'zh': '还没有账号？', 'en': "Don't have an account?"},
    'registerNow': {'zh': '立即注册', 'en': 'Register Now'},
    'versionCompatibility': {
      'zh': '版本兼容性说明',
      'en': 'Version Compatibility Notes',
    },
    'contactSupport': {
      'zh': '如有疑问，请查看官方文档或联系技术支持',
      'en':
          'For any questions, please check the official documentation or contact support',
    },
    'customServerWarning': {
      'zh': '使用自定义服务器可能会影响使用体验',
      'en': 'Using a custom server may affect user experience',
    },
    'serverAddress': {'zh': '服务器地址', 'en': 'Server Address'},
    'faq': {'zh': '常见问题', 'en': 'FAQ'},
    'answerYourQuestions': {'zh': '为您解答使用中的疑问', 'en': 'Answer your questions'},
    'howToLogin': {'zh': '如何登录账号？', 'en': 'How to login?'},
    'howToLoginAnswer': {
      'zh': '输入您注册时使用的用户名和密码，即可登录。如果开启"记住密码"，下次将自动登录。',
      'en':
          'Enter the username and password you used during registration to login. If "Remember Password" is enabled, you will be automatically logged in next time.',
    },
    'whatIsServer': {'zh': '什么是服务器？', 'en': 'What is a server?'},
    'whatIsServerAnswer': {
      'zh': '服务器用于存储和同步您的笔记数据。推荐使用官方服务器，也可以使用自己部署的 Memos 服务器。',
      'en':
          'The server is used to store and sync your notes data. Official server is recommended, but you can also use your own deployed Memos server.',
    },
    'howToSyncData': {'zh': '如何同步数据？', 'en': 'How to sync data?'},
    'howToSyncDataAnswer': {
      'zh': '登录后，您的笔记将自动同步到服务器。支持多端同步，在任何设备登录都能查看您的笔记。',
      'en':
          'After login, your notes will be automatically synced to the server. Multi-device sync is supported, you can view your notes on any device.',
    },

    // ===== 注册页面 =====
    'pleaseAgreeToPolicy': {
      'zh': '请阅读并同意隐私政策及用户协议',
      'en': 'Please read and agree to the Privacy Policy and User Agreement',
    },
    'registrationSuccessful': {
      'zh': '注册成功！正在为您登录...',
      'en': 'Registration successful! Logging you in...',
    },
    'registrationFailed': {
      'zh': '注册失败，请检查信息后重试',
      'en': 'Registration failed, please check your information and try again',
    },
    'joinInkRoot': {'zh': '加入 InkRoot', 'en': 'Join InkRoot'},
    'startIntelligentNoteJourney': {
      'zh': '创建你的笔记空间',
      'en': 'Create your note space',
    },
    'startCreativeJourney': {
      'zh': '开启您的\n创作之旅',
      'en': 'Start Your\nCreative Journey',
    },
    'recordEachMoment': {
      'zh': '加入 InkRoot，记录每一个值得珍藏的时刻',
      'en': 'Join InkRoot, record every moment worth treasuring',
    },
    'usernameMinLength3': {
      'zh': '用户名至少需要3个字符',
      'en': 'Username must be at least 3 characters',
    },
    'usernameInvalidChars': {
      'zh': '用户名只能包含字母、数字、下划线和中文',
      'en':
          'Username can only contain letters, numbers, underscores and Chinese characters',
    },
    'passwordHint': {
      'zh': '至少8位，包含字母或数字',
      'en': 'At least 8 characters, containing letters or numbers',
    },
    'confirmPassword': {'zh': '确认密码', 'en': 'Confirm Password'},
    'pleaseConfirmPassword': {'zh': '请再次输入密码', 'en': 'Please confirm password'},
    'passwordMismatch': {'zh': '两次输入的密码不一致', 'en': 'Passwords do not match'},
    'autoLoginAfterRegistration': {
      'zh': '注册后自动登录',
      'en': 'Auto login after registration',
    },
    'betterExperience': {
      'zh': '为您提供更便捷的使用体验',
      'en': 'Provide you with a more convenient experience',
    },
    'agreeToTerms': {'zh': '我已阅读并同意 ', 'en': 'I have read and agree to '},
    'privacyPolicy': {'zh': '隐私政策', 'en': 'Privacy Policy'},
    'userAgreement': {'zh': '用户协议', 'en': 'User Agreement'},
    'startCreating': {'zh': '开始创作', 'en': 'Start Creating'},
    'alreadyHaveAccount': {
      'zh': '已有账号？立即登录',
      'en': 'Already have an account? Login now',
    },
    'howToRegister': {'zh': '如何注册账号？', 'en': 'How to register?'},
    'howToRegisterAnswer': {
      'zh': '填写用户名和密码（至少8位），勾选同意协议后点击"开始创作"即可注册。注册成功后将自动登录。',
      'en':
          'Fill in username and password (at least 8 characters), check the agreement box and click "Start Creating" to register. You will be automatically logged in after successful registration.',
    },
    'whatFeaturesSupported': {
      'zh': '笔记支持哪些功能？',
      'en': 'What features are supported?',
    },
    'whatFeaturesAnswer': {
      'zh': '支持富文本式编辑、Markdown 渲染、图片、标签、提醒、搜索、随机回顾、知识图谱和可选 AI 功能。',
      'en':
          'Supports rich-text-style editing, Markdown rendering, images, tags, reminders, search, random review, knowledge graph, and optional AI features.',
    },
    'isDataSafe': {'zh': '数据安全吗？', 'en': 'Is data safe?'},
    'isDataSafeAnswer': {
      'zh': '我们使用加密传输保护您的数据安全。本地数据也经过安全存储。建议定期备份重要笔记。',
      'en':
          'We use encrypted transmission to protect your data security. Local data is also stored securely. Regular backups of important notes are recommended.',
    },
    'whatIfForgotPassword': {
      'zh': '忘记密码怎么办？',
      'en': 'What if I forget my password?',
    },
    'whatIfForgotPasswordAnswer': {
      'zh': '如使用官方服务器，请联系管理员重置密码。如使用自定义服务器，请联系您的服务器管理员。',
      'en':
          'If using the official server, please contact the administrator to reset your password. If using a custom server, please contact your server administrator.',
    },
    'anyOtherQuestions': {'zh': '还有其他问题？', 'en': 'Any other questions?'},
    'viewHelpCenter': {'zh': '查看帮助中心', 'en': 'View Help Center'},

    // ===== Home页面 =====
    'createNoteFailed': {'zh': '创建笔记失败', 'en': 'Failed to create note'},
    'syncSuccess': {'zh': '同步成功', 'en': 'Sync successful'},
    'refreshSuccess': {'zh': '刷新成功', 'en': 'Refresh successful'},
    'refreshFailed': {'zh': '刷新失败', 'en': 'Refresh failed'},
    'sortBy': {'zh': '排序方式', 'en': 'Sort By'},
    'newestFirst': {'zh': '最新优先', 'en': 'Newest First'},
    'oldestFirst': {'zh': '最旧优先', 'en': 'Oldest First'},
    'updatedTime': {'zh': '更新时间', 'en': 'Updated Time'},
    'createFailed': {'zh': '创建失败', 'en': 'Create failed'},
    'addedFromShare': {'zh': '已添加来自分享的笔记', 'en': 'Added note from share'},
    'updateFailed': {'zh': '更新失败', 'en': 'Update failed'},
    'noteDeleted': {'zh': '笔记已删除', 'en': 'Note deleted'},
    'deleteFailed': {'zh': '删除失败', 'en': 'Delete failed'},
    'notePinned': {'zh': '笔记已置顶', 'en': 'Note pinned'},
    'noteUnpinned': {'zh': '笔记已取消置顶', 'en': 'Note unpinned'},
    'searchNotes': {'zh': '搜索笔记...', 'en': 'Search notes...'},
    'loading': {'zh': '加载中...', 'en': 'Loading...'},
    'loadedAllNotes': {
      'zh': '已加载全部 {count} 条笔记',
      'en': 'Loaded all {count} notes',
    },
    'enableAIFirst': {
      'zh': '请先在设置中启用AI功能',
      'en': 'Please enable AI feature in settings first',
    },
    'configureAIFirst': {
      'zh': '请先在设置中配置AI API',
      'en': 'Please configure AI API in settings first',
    },

    // ===== 笔记详情页面 =====
    'unableToOpenLink': {'zh': '无法打开链接', 'en': 'Unable to open link'},
    'linkError': {'zh': '链接错误', 'en': 'Link error'},
    'reviewCopied': {'zh': '点评内容已复制', 'en': 'Review content copied'},
    'noteUpdated': {'zh': '笔记已更新', 'en': 'Note updated'},
    'noteActions': {'zh': '笔记操作', 'en': 'Note Actions'},
    'selectAction': {
      'zh': '选择您要执行的操作',
      'en': 'Select the action you want to perform',
    },
    'edit': {'zh': '编辑', 'en': 'Edit'},
    'pinNote': {'zh': '置顶', 'en': 'Pin'},
    'unpinNote': {'zh': '取消置顶', 'en': 'Unpin'},
    'archiveNote': {'zh': '归档', 'en': 'Archive'},
    'unarchiveNote': {'zh': '取消归档', 'en': 'Unarchive'},
    'deleteNote': {'zh': '删除', 'en': 'Delete'},
    'copyContent': {'zh': '复制内容', 'en': 'Copy Content'},
    'viewHistory': {'zh': '查看历史', 'en': 'View History'},
    'aiReview': {'zh': 'AI点评', 'en': 'AI Review'},
    'aiReviewSubtitle': {'zh': 'AI Review', 'en': 'AI Review'},
    'exportAsImage': {'zh': '导出图片', 'en': 'Export as Image'},
    'contentCopied': {'zh': '内容已复制', 'en': 'Content copied'},
    'copyFailed': {'zh': '复制失败', 'en': 'Copy failed'},
    'confirmDelete': {'zh': '确认删除', 'en': 'Confirm Delete'},
    'deleteNoteMessage': {
      'zh': '确定要删除这条笔记吗？此操作不可恢复。',
      'en':
          'Are you sure you want to delete this note? This action cannot be undone.',
    },
    'notLoggedInOrAPINotInitialized': {
      'zh': '未登录或API服务未初始化',
      'en': 'Not logged in or API service not initialized',
    },
    'currentUserInfoEmpty': {
      'zh': '当前用户信息为空',
      'en': 'Current user information is empty',
    },
    'userInfoSyncSuccess': {
      'zh': '用户信息同步成功',
      'en': 'User information synchronized successfully',
    },
    'allAPIVersionsFailed': {
      'zh': '所有API版本都无法获取用户信息',
      'en': 'All API versions failed to get user information',
    },
    'allAPIVersionsUpdateFailed': {
      'zh': '所有API版本更新失败',
      'en': 'All API versions failed to update',
    },
    'cannotGetUsername': {'zh': '无法获取用户名', 'en': 'Cannot get username'},
    'allPasswordUpdateFailed': {
      'zh': '所有API版本密码更新失败',
      'en': 'All API versions failed to update password',
    },

    // ===== 实验室页面 =====
    'telegramBot': {'zh': 'Telegram 助手', 'en': 'Telegram Bot'},
    'telegramBotDesc': {
      'zh': '连接 InkRoot_Bot，实现跨平台笔记同步',
      'en': 'Connect InkRoot_Bot for cross-platform note syncing',
    },
    'stableRunning': {'zh': '稳定运行', 'en': 'Stable'},
    'voiceToText': {'zh': '语音转文字', 'en': 'Voice to Text'},
    'voiceToTextDesc': {
      'zh': '语音录制自动转换为文字笔记',
      'en': 'Auto convert voice recordings to text notes',
    },
    'aiNoteAssistant': {'zh': 'AI 笔记助手', 'en': 'AI Note Assistant'},
    'aiNoteAssistantDesc': {
      'zh': '智能分析和优化您的笔记内容',
      'en': 'Intelligently analyze and optimize your notes',
    },
    'expectedNextRelease': {'zh': '预计下个版本发布', 'en': 'Expected in next release'},
    'connectInkRootBot': {'zh': '连接 InkRoot_Bot', 'en': 'Connect InkRoot_Bot'},
    'telegramBotDialogContent': {
      'zh':
          '在 Telegram 中搜索 @InkRoot_Bot，连接机器人后即可发送消息自动创建笔记。支持 Markdown 格式，实时同步到 InkRoot 应用。',
      'en':
          'Search @InkRoot_Bot in Telegram, connect the bot to automatically create notes from messages. Supports Markdown format, syncs to InkRoot in real-time.',
    },
    'voiceToTextDialogContent': {
      'zh': '在笔记编辑器中点击麦克风按钮即可开始语音识别。支持离线识别，无需联网。识别过程中可随时暂停和继续，文字将自动插入到编辑器中。',
      'en':
          'Click the microphone button in the note editor to start voice recognition. Supports offline recognition, no internet required. You can pause and resume anytime, text will be automatically inserted.',
    },

    // AI 智能助手
    'aiSmartAssistant': {'zh': 'AI 智能助手', 'en': 'AI Smart Assistant'},
    'aiSmartAssistantDesc': {
      'zh': '相关笔记推荐、智能续写、标签生成、内容摘要',
      'en': 'Related notes, smart writing, tags, summaries',
    },
    'aiAssistantFeatures': {
      'zh': 'AI 智能助手包含以下功能：',
      'en': 'AI Smart Assistant includes:',
    },
    'relatedNotesRecommend': {'zh': '📌 相关笔记推荐', 'en': '📌 Related Notes'},
    'relatedNotesDesc': {
      'zh': '根据内容查找可能相关的笔记',
      'en': 'Find notes that may be related by content',
    },
    'smartContinueWriting': {'zh': '✍️ 智能续写', 'en': '✍️ Smart Writing'},
    'smartContinueWritingDesc': {
      'zh': '根据上下文智能续写笔记内容',
      'en': 'Continue writing based on context',
    },
    'tagGeneration': {'zh': '🏷️ 标签生成', 'en': '🏷️ Tag Generation'},
    'tagGenerationDesc': {
      'zh': '自动分析笔记内容生成相关标签',
      'en': 'Auto generate tags from content',
    },
    'contentSummary': {'zh': '📝 内容摘要', 'en': '📝 Content Summary'},
    'contentSummaryDesc': {
      'zh': '快速生成笔记内容摘要',
      'en': 'Quickly generate note summaries',
    },
    'aiAssistantTip': {
      'zh': '💡 提示：在笔记详情页点击右下角魔法棒图标即可使用',
      'en': '💡 Tip: Click the magic wand icon in note details',
    },

    // 笔记批注
    'noteAnnotation': {'zh': '笔记批注', 'en': 'Note Annotations'},
    'noteAnnotationDesc': {
      'zh': '为笔记添加评论、问题、想法等批注信息',
      'en': 'Add comments, questions, ideas to notes',
    },
    'testing': {'zh': '测试中', 'en': 'Testing'},
    'annotationIntro': {
      'zh': '为笔记添加批注，记录你的想法、问题和评论：',
      'en': 'Add annotations to record your thoughts, questions and comments:',
    },
    'annotationComment': {'zh': '💬 评论', 'en': '💬 Comment'},
    'annotationCommentDesc': {
      'zh': '添加对笔记内容的评论和反思',
      'en': 'Add comments and reflections',
    },
    'annotationQuestion': {'zh': '❓ 问题', 'en': '❓ Question'},
    'annotationQuestionDesc': {
      'zh': '记录阅读时产生的疑问',
      'en': 'Record questions while reading',
    },
    'annotationIdea': {'zh': '💡 想法', 'en': '💡 Idea'},
    'annotationIdeaDesc': {
      'zh': '记录灵感和新想法',
      'en': 'Record inspirations and new ideas',
    },
    'annotationImportant': {'zh': '⚠️ 重要', 'en': '⚠️ Important'},
    'annotationImportantDesc': {
      'zh': '标记重要信息和关键点',
      'en': 'Mark important info and key points',
    },
    'annotationWarning': {
      'zh': '⚠️ 功能暂时不稳定，请自行斟酌使用。批注数据仅保存在本地，不会同步到服务器。',
      'en':
          '⚠️ Feature is unstable. Annotations are local only, not synced to server.',
    },
    'annotationUsageTip': {
      'zh': '💡 使用方法：在笔记列表或详情页点击批注图标 🟠 即可查看和管理批注',
      'en': '💡 Usage: Click the annotation icon 🟠 in note list or details',
    },
    'iKnow': {'zh': '我知道了', 'en': 'I Know'},

    // ===== AI设置页面 =====
    'doubaoModel': {'zh': '豆包 Pro', 'en': 'Doubao Pro'},
    'zhipuModel': {'zh': '智谱 GLM-4', 'en': 'Zhipu GLM-4'},
    'baichuanModel': {'zh': '百川智能', 'en': 'Baichuan AI'},
    'unknownModel': {'zh': '未知模型', 'en': 'Unknown Model'},
    'deepseekchat': {'zh': 'DeepSeek Chat', 'en': 'DeepSeek Chat'},
    'deepseekchatDesc': {
      'zh': '快速响应，适合日常对话',
      'en': 'Fast response, suitable for daily conversations',
    },
    'deepseekReasoner': {'zh': 'DeepSeek Reasoner', 'en': 'DeepSeek Reasoner'},
    'deepseekReasonerDesc': {
      'zh': '深度思考，适合复杂推理',
      'en': 'Deep thinking, suitable for complex reasoning',
    },
    'gpt4o': {'zh': 'GPT-4o', 'en': 'GPT-4o'},
    'gpt4oDesc': {
      'zh': '最新旗舰，强大全能',
      'en': 'Latest flagship, powerful and versatile',
    },
    'gpt4oMini': {'zh': 'GPT-4o Mini', 'en': 'GPT-4o Mini'},
    'gpt4oMiniDesc': {
      'zh': '轻量快速，性价比高',
      'en': 'Lightweight and fast, cost-effective',
    },
    'gpt4Turbo': {'zh': 'GPT-4 Turbo', 'en': 'GPT-4 Turbo'},
    'gpt4TurboDesc': {'zh': '强大推理', 'en': 'Powerful reasoning'},
    'gpt35Turbo': {'zh': 'GPT-3.5 Turbo', 'en': 'GPT-3.5 Turbo'},

    // ===== 设置页面 =====
    'waitPatiently': {'zh': '静待沉淀', 'en': 'Settle Patiently'},
    'poiseToResound': {'zh': '蓄势而鸣', 'en': 'Speak With Force'},
    'focusAndAccumulate': {
      'zh': '你的每一次落笔，都是未来生长的根源！',
      'en': 'Every note you take becomes a root for what comes next.',
    },

    // ===== 隐私政策页面 =====
    'privacyPolicyTitle': {'zh': '隐私政策', 'en': 'Privacy Policy'},
    'importantStatement': {'zh': '重要声明', 'en': 'Important Statement'},
    'informationCollection': {
      'zh': '信息收集与处理',
      'en': 'Information Collection and Processing',
    },
    'dataTransmissionSecurity': {
      'zh': '数据传输与安全',
      'en': 'Data Transmission and Security',
    },
    'privacyPolicyContent1': {
      'zh': '我们不收集以下信息：',
      'en': 'We do not collect the following information:',
    },
    'privacyPolicyContent2': {
      'zh': '本地存储的信息：',
      'en': 'Locally stored information:',
    },
    'privacyPolicyContent3': {'zh': '技术实现：', 'en': 'Technical implementation:'},
    'privacyPolicyContent4': {
      'zh': '这些信息仅存储在您的设备上，不会传输给我们或任何第三方。',
      'en':
          'This information is only stored on your device and is not transmitted to us or any third party.',
    },
    'privacyPolicyContent5': {'zh': '主要数据流向：', 'en': 'Main data flow:'},
    'privacyPolicyContent6': {
      'zh': '数据安全保障：',
      'en': 'Data security guarantee:',
    },

    // ===== NoteEditor Widget =====
    'editorPlaceholder': {'zh': '现在的想法是...', 'en': "What's on your mind..."},
    'thinkingNow': {'zh': '现在的想法是...', 'en': "What's on your mind..."},
    'listening': {'zh': '正在聆听...', 'en': 'Listening...'},
    'recognizing': {'zh': '识别中', 'en': 'Recognizing'},
    'tapToStop': {'zh': '点击停止', 'en': 'Tap to stop'},
    'saveFailed': {'zh': '保存失败', 'en': 'Save failed'},
    'selectImageFailed': {'zh': '选择图片失败', 'en': 'Failed to select image'},
    'noteNotFound': {'zh': '找不到要引用的笔记', 'en': 'Referenced note not found'},
    'referenceInserted': {
      'zh': '引用内容已插入，保存笔记后将自动建立引用关系',
      'en': 'Reference inserted, will be linked after saving the note',
    },
    'referenceCreatedSuccess': {
      'zh': '引用关系已创建',
      'en': 'Reference created successfully',
    },
    'needMicPermission': {
      'zh': '需要麦克风权限才能使用语音识别',
      'en': 'Microphone permission required for speech recognition',
    },
    'pinned': {'zh': '置顶', 'en': 'Pinned'},
    'unpinned': {'zh': '取消置顶', 'en': 'Unpinned'},
    'later': {'zh': '稍后', 'en': 'Later'},

    // ===== 权限引导对话框 =====
    'permissionsReady': {'zh': '✅ 权限已就绪', 'en': '✅ Permissions Ready'},
    'permissionsRequired': {'zh': '需要权限', 'en': 'Permissions Required'},
    'allPermissionsGrantedMessage': {
      'zh': '所有权限已开启，可以正常使用提醒功能',
      'en': 'All permissions granted, reminders are ready to use',
    },
    'pleaseEnablePermissionsMessage': {
      'zh': '为了准时收到笔记提醒，请开启以下权限',
      'en':
          'To receive timely note reminders, please enable the following permissions',
    },
    'notificationPermission': {'zh': '通知权限', 'en': 'Notification Permission'},
    'allowAppNotifications': {
      'zh': '允许应用显示通知',
      'en': 'Allow app to show notifications',
    },
    'exactAlarm': {'zh': '精确闹钟', 'en': 'Exact Alarm'},
    'allowExactAlarmDescription': {
      'zh': '允许在特定时间触发提醒',
      'en': 'Allow reminders at specific times',
    },
    'backgroundRunning': {'zh': '后台运行', 'en': 'Background Running'},
    'allowBackgroundDescription': {
      'zh': '允许应用在后台保持活跃',
      'en': 'Allow app to stay active in background',
    },
    'openSettingsInstructions': {
      'zh': '点击下方"打开设置"按钮，在应用设置中开启权限后，点击"重新检查"',
      'en':
          'Click "Open Settings" below, enable permissions in app settings, then click "Recheck"',
    },
    'openSettings': {'zh': '打开设置', 'en': 'Open Settings'},
    'recheck': {'zh': '重新检查', 'en': 'Recheck'},
    'postponeSettings': {'zh': '稍后设置', 'en': 'Postpone'},

    // ===== NoteCard侧滑按钮 =====
    'pinAction': {'zh': '置顶', 'en': 'Pin'},
    'unpinAction': {'zh': '取消置顶', 'en': 'Unpin'},
    'deleteAction': {'zh': '删除', 'en': 'Delete'},
    'noteCreatedSuccess': {'zh': '笔记已创建', 'en': 'Note created'},
    'quickActions': {'zh': '快捷操作', 'en': 'Quick Actions'},
    'copyNoteContent': {
      'zh': '复制笔记内容到剪贴板',
      'en': 'Copy note content to clipboard',
    },
    'systemShare': {'zh': '系统分享', 'en': 'System Share'},
    'useSystemShare': {'zh': '使用系统分享功能', 'en': 'Use system share'},
    'noteSummary': {'zh': '笔记摘要', 'en': 'Note Summary'},
    'sharePermissionConfirmation': {
      'zh': '分享权限确认',
      'en': 'Share Permission Confirmation',
    },
    'sharePermissionMessage': {
      'zh': '要分享此笔记，需要将其设置为公开状态。\n任何拥有链接的人都可以查看该笔记的内容。',
      'en':
          'To share this note, it needs to be set to public.\nAnyone with the link can view the note content.',
    },
    'confirmAndShare': {'zh': '确定并分享', 'en': 'Confirm and Share'},
    'pleaseLoginToShare': {
      'zh': '请先登录后再使用分享链接功能',
      'en': 'Please login first to use share link feature',
    },
    'generatingHighQualityImage': {
      'zh': '生成高质量分享图片需要一些时间',
      'en': 'Generating high-quality share image takes some time',
    },
    'analyzingImages': {'zh': '正在分析图片...', 'en': 'Analyzing images...'},
    'loadingImages': {'zh': '正在加载图片...', 'en': 'Loading images...'},
    'generatingShareImage': {
      'zh': '正在生成分享图片...',
      'en': 'Generating share image...',
    },
    'savingImage': {'zh': '正在保存图片...', 'en': 'Saving image...'},
    'shareFailedRetry': {
      'zh': '生成分享链接失败，请稍后再试',
      'en': 'Failed to generate share link, please try again later',
    },
    'loginRequired': {'zh': '需要登录', 'en': 'Login Required'},
    'shareUnknownError': {
      'zh': '生成分享链接时发生未知错误，请稍后重试',
      'en':
          'Unknown error occurred while generating share link, please try again later',
    },
    'setReminderTime': {'zh': '设置提醒时间', 'en': 'Set Reminder Time'},
    'customizeShareContent': {
      'zh': '自定义分享内容和选项',
      'en': 'Customize share content and options',
    },
    'changeTime': {'zh': '修改时间', 'en': 'Change Time'},
    'selectDate': {'zh': '选择日期', 'en': 'Select Date'},
    'selectTime': {'zh': '选择时间', 'en': 'Select Time'},
    'timeUpdated': {'zh': '时间已更新', 'en': 'Time Updated'},
    'viewOriginalImage': {'zh': '查看原图', 'en': 'View Original'},
    'saveImage': {'zh': '保存图片', 'en': 'Save Image'},
    'fitScreen': {'zh': '适应屏幕', 'en': 'Fit Screen'},
    'fillScreen': {'zh': '填满屏幕', 'en': 'Fill Screen'},
    'loadingHDImage': {'zh': '正在加载高清原图...', 'en': 'Loading HD image...'},
    'imageLoadError': {'zh': '无法加载图片', 'en': 'Failed to load image'},
    'cannotDisplayImage': {'zh': '无法显示图片', 'en': 'Cannot display image'},
    'allImagesCount': {'zh': '全部图片 ({count})', 'en': 'All Images ({count})'},
    'timeUpdateFailed': {'zh': '时间更新失败', 'en': 'Time Update Failed'},
    'viewCreationTime': {
      'zh': '查看创建时间详细信息',
      'en': 'View creation time details',
    },
    'share': {'zh': '分享', 'en': 'Share'},
    'cancel': {'zh': '取消', 'en': 'Cancel'},
    'saveAndShare': {'zh': '保存并分享', 'en': 'Save and Share'},
    'generatingShareLink': {
      'zh': '正在生成分享链接...',
      'en': 'Generating share link...',
    },
    'reviewCopiedShort': {'zh': '✨ 点评已复制', 'en': '✨ Review copied'},
    'aiReviewCompleted': {'zh': '✨ AI点评完成！', 'en': '✨ AI review ready!'},
    'aiReviewTitle': {'zh': '给你的点评', 'en': 'Your Review'},
    'aiReadingNote': {'zh': 'AI正在阅读笔记...', 'en': 'AI is reading...'},
    'aiAnalyzing': {'zh': 'AI正在分析中...', 'en': 'AI is analyzing...'},
    'startInsightWithCount': {
      'zh': '开始洞察 ({count} 条笔记)',
      'en': 'Start Insight ({count} notes)',
    },
    'copyReview': {'zh': '复制点评', 'en': 'Copy Review'},
    'close': {'zh': '关闭', 'en': 'Close'},
    'loadingHighRes': {
      'zh': '正在加载高清原图...',
      'en': 'Loading high-resolution image...',
    },
    'cannotLoadImage': {'zh': '无法加载图片', 'en': 'Cannot load image'},
    'networkFailedNoCache': {
      'zh': '网络连接失败且无缓存',
      'en': 'Network connection failed and no cache',
    },
    'authFailedNoCache': {
      'zh': '认证失败且无缓存',
      'en': 'Authentication failed and no cache',
    },
    'unsupportedImageFormat': {
      'zh': '不支持的图片格式',
      'en': 'Unsupported image format',
    },
    'allImages': {'zh': '全部图片 ({count})', 'en': 'All Images ({count})'},
    'loadFailed': {'zh': '加载失败', 'en': 'Load Failed'},

    // ===== 版本更新 =====
    'newVersionAvailable': {'zh': '发现新版本', 'en': 'New Version Available'},
    'latestVersion': {
      'zh': '最新版本：{version}',
      'en': 'Latest version: {version}',
    },
    'updateAvailableMessage': {
      'zh': '墨鸣笔记有新版本可用，建议立即更新以体验新功能！',
      'en':
          'A new version of InkRoot is available. Update now to experience new features!',
    },
    'updateNotes': {'zh': '更新内容：', 'en': "What's New:"},
    'remindMeLater': {'zh': '稍后再说', 'en': 'Remind Me Later'},
    'goToUpdate': {'zh': '前往更新', 'en': 'Update'},
    'updateNow': {'zh': '立即更新', 'en': 'Update Now'},

    // ===== 分享相关 =====
    'sharedText': {'zh': '收到分享的文本', 'en': 'Received shared text'},
    'sharedImage': {'zh': '收到分享的图片', 'en': 'Received shared image'},
    'sharedImages': {'zh': '收到分享的图片', 'en': 'Received shared images'},
    'sharedFile': {'zh': '收到分享的文件', 'en': 'Received shared file'},
    'sharedFromOther': {'zh': '来自分享的', 'en': 'Shared from'},
    'sharedImagesCount': {
      'zh': '来自分享的图片 ({count}张)',
      'en': 'Shared images ({count})',
    },
    'sharedFiles': {'zh': '分享的文件：', 'en': 'Shared files:'},

    // ===== 排序和筛选 =====
    'fromNewToOld': {'zh': '从新到旧', 'en': 'Newest to Oldest'},
    'fromOldToNew': {'zh': '从旧到新', 'en': 'Oldest to Newest'},
    'filterNotes': {'zh': '筛选笔记', 'en': 'Filter Notes'},
    'totalWordCount': {'zh': '总字数', 'en': 'Total Words'},

    // ===== 登录状态 =====
    'online': {'zh': '在线', 'en': 'Online'},
    'offline': {'zh': '离线', 'en': 'Offline'},
    'clearLocalData': {'zh': '清空本地数据', 'en': 'Clear Local Data'},
    'keepLocalData': {'zh': '保留本地数据', 'en': 'Keep Local Data'},

    // ===== 功能菜单 =====
    'featureMenu': {'zh': '功能菜单', 'en': 'Feature Menu'},
    'noAvailableTags': {'zh': '暂无可用标签', 'en': 'No Available Tags'},

    // ===== AI洞察相关 =====
    'keywords': {'zh': '关键词', 'en': 'Keywords'},
    'inputKeywords': {'zh': '输入想要洞察的关键词', 'en': 'Enter keywords for insights'},
    'timeRange': {'zh': '时间范围', 'en': 'Time Range'},
    'selectAnalysisTimeRange': {
      'zh': '选择要分析的时间段',
      'en': 'Select time range to analyze',
    },
    'includeTags': {'zh': '包含标签', 'en': 'Include Tags'},
    'selectIncludeTags': {'zh': '选择要包含的标签', 'en': 'Select tags to include'},
    'excludeTags': {'zh': '排除标签', 'en': 'Exclude Tags'},
    'selectExcludeTags': {'zh': '选择要排除的标签', 'en': 'Select tags to exclude'},
    'insightResults': {'zh': '洞察结果', 'en': 'Insight Results'},
    'aiGeneratedAnalysis': {
      'zh': '根据当前筛选生成的整理结果',
      'en': 'Organized result generated from the current filter',
    },
    'allTime': {'zh': '全部', 'en': 'All Time'},
    'openInNewWindow': {'zh': '在新窗口打开', 'en': 'Open in New Window'},

    // ===== 权限和设置提示 =====
    'permissionRequired': {
      'zh': '需要通知权限',
      'en': 'Notification Permission Required',
    },
    'permissionInstructions': {
      'zh': '为了准时提醒您，InkRoot需要发送通知。请在iPhone设置中找到InkRoot，开启"允许通知"，并启用"时间敏感通知"。',
      'en':
          'To send you timely reminders, InkRoot needs notification permission. Please find InkRoot in iPhone Settings, enable "Allow Notifications" and turn on "Time Sensitive Notifications".',
    },
    'operationSteps': {'zh': '操作步骤：', 'en': 'Steps:'},
    'permissionStepGuide': {
      'zh': '1. 点击"去设置"按钮\n2. 找到"通知"权限\n3. 开启权限开关\n4. 返回应用重试',
      'en':
          '1. Tap "Go to Settings"\n2. Find "Notifications" permission\n3. Turn on the switch\n4. Return to app and retry',
    },
    'goToSettings': {'zh': '去设置', 'en': 'Go to Settings'},
    'rateLimitExceeded': {
      'zh': '请求过于频繁，请稍后再试',
      'en': 'Rate limit exceeded, please try again later',
    },
    'streamResponseNotImplemented': {
      'zh': '流式响应功能待实现',
      'en': 'Streaming response not yet implemented',
    },
    'noTitle': {'zh': '无标题', 'en': 'No Title'},
    'view': {'zh': '查看', 'en': 'View'},

    // ===== 通知相关 =====
    'noteReminder': {'zh': '笔记提醒', 'en': 'Note Reminder'},
    'noteReminderDescription': {
      'zh': '笔记定时提醒通知',
      'en': 'Note reminder notifications',
    },
    'dismiss': {'zh': '关闭', 'en': 'Dismiss'},

    // ===== 时间相关 =====
    'last7Days': {'zh': '近7天', 'en': 'Last 7 Days'},
    'last30Days': {'zh': '近30天', 'en': 'Last 30 Days'},
    'last1Year': {'zh': '近1年', 'en': 'Last Year'},

    // ===== 笔记详情页 =====
    'noteDetail': {'zh': '笔记详情', 'en': 'Note Details'},
    'editNote': {'zh': '编辑', 'en': 'Edit'},
    'linkNote': {'zh': '链接', 'en': 'Link'},
    'deleteNoteConfirmTitle': {'zh': '删除笔记', 'en': 'Delete Note'},
    'deleteNoteConfirmMessage': {
      'zh': '确定要删除这条笔记吗？删除后无法恢复。',
      'en':
          'Are you sure you want to delete this note? This action cannot be undone.',
    },
    'referenceDetails': {'zh': '引用详情', 'en': 'Reference Details'},
    'viewReferenceRelations': {'zh': '查看笔记引用关系', 'en': 'View note references'},
    'detailedInfo': {'zh': '详细信息', 'en': 'Detailed Info'},
    'viewCreationTimeInfo': {
      'zh': '查看创建时间等信息',
      'en': 'View creation time and other info',
    },
    'clickToModifyReminder': {
      'zh': '点击修改或取消提醒',
      'en': 'Click to modify or cancel reminder',
    },
    'shareSettings': {'zh': '分享设置', 'en': 'Share Settings'},
    'manageNoteVisibility': {'zh': '管理笔记可见性', 'en': 'Manage note visibility'},
    'createdTime': {'zh': '创建时间', 'en': 'Created Time'},
    'characterCount': {'zh': '字符数量', 'en': 'Character Count'},
    'characters': {'zh': '字符', 'en': 'characters'},
    'tagCount': {'zh': '标签数量', 'en': 'Tag Count'},
    'tagsCount': {'zh': '个标签', 'en': 'tags'},
    'shareNote': {'zh': '分享笔记', 'en': 'Share Note'},
    'shareLink': {'zh': '分享链接', 'en': 'Share Link'},
    'generateShareLink': {'zh': '生成分享链接', 'en': 'Generate share link'},
    'shareImage': {'zh': '分享图片', 'en': 'Share Image'},
    'generateImageShare': {'zh': '生成图片分享', 'en': 'Generate image share'},

    // ===== AI提示词 =====
    'aiSystemPrompt': {
      'zh':
          '你是一个专业的内容分析助手。请基于用户提供的笔记内容，进行深入分析并提供有价值的见解。你的回复应该：\n1. 客观准确\n2. 有深度和洞察力\n3. 提供可操作的建议\n4. 语言简洁清晰\n\n请用中文回复。',
      'en':
          "You are a professional content analysis assistant. Based on the user's notes, provide in-depth analysis and valuable insights. Your response should be:\n1. Objective and accurate\n2. Deep and insightful\n3. Provide actionable suggestions\n4. Clear and concise\n\nPlease respond in English.",
    },

    // ===== 笔记编辑器 =====
    'image': {'zh': '图片', 'en': 'Image'},
    'addNoteReference': {'zh': '添加笔记引用', 'en': 'Add Note Reference'},
    'selectNoteToReference': {
      'zh': '选择要引用的笔记，建立笔记间的关联关系',
      'en': 'Select a note to reference and create connections',
    },
    'noNotesToReference': {'zh': '暂无笔记可引用', 'en': 'No notes to reference'},
    'noMatchingNotes': {'zh': '没有找到相关笔记', 'en': 'No matching notes found'},
    'createNotesFirst': {
      'zh': '先创建一些笔记再来建立引用关系',
      'en': 'Create some notes first before adding references',
    },

    // ===== NoteCard相关 =====
    'expand': {'zh': '展开', 'en': 'Expand'},
    'collapse': {'zh': '收起', 'en': 'Collapse'},
    'fullText': {'zh': '全文', 'en': 'Full'},
    'cancelFailed': {'zh': '取消失败', 'en': 'Cancel failed'},
    'pleaseEnableNotificationFirst': {
      'zh': '请先开启通知权限才能设置提醒',
      'en': 'Please enable notification permission first',
    },
    'needNotificationPermission': {
      'zh': '需要开启通知权限',
      'en': 'Notification permission required',
    },
    'notificationSteps': {
      'zh': '为了准时收到笔记提醒，请按以下步骤操作：',
      'en': 'To receive timely note reminders, please follow these steps:',
    },
    'tapAppSettingsButton': {
      'zh': '🔥 点击下方"应用设置"按钮，然后：',
      'en': '🔥 Tap "App Settings" button below, then:',
    },
    'returnToSettings': {
      'zh': '6️⃣ 返回手机"设置"主页',
      'en': '6️⃣ Return to phone Settings',
    },
    'enableAutoStart': {
      'zh': '7️⃣ 搜索"自启动" → 找到InkRoot → 开启✅',
      'en': '7️⃣ Search "Auto-start" → Find InkRoot → Enable✅',
    },
    'disableBatteryOptimization': {
      'zh': '8️⃣ 搜索"电池优化" → InkRoot → 不限制✅',
      'en': '8️⃣ Search "Battery optimization" → InkRoot → No restrictions✅',
    },
    'autoStartWarning': {
      'zh': '不开启自启动和电池优化，应用关闭后就收不到提醒！',
      'en':
          "Without auto-start and battery optimization, you won't receive reminders after closing the app!",
    },
    'batteryOptimization': {'zh': '电池优化', 'en': 'Battery Optimization'},
    'appSettings': {'zh': '应用设置', 'en': 'App Settings'},

    // ===== Preferences相关 =====
    'unknown': {'zh': '未知', 'en': 'Unknown'},
    'syncInterval': {'zh': '同步间隔', 'en': 'Sync Interval'},
    'rememberPasswordEnabled': {
      'zh': '已同时开启记住密码功能',
      'en': 'Remember password enabled',
    },

    // ===== AccountInfo相关 =====
    'userInfoEmpty': {'zh': '用户信息为空', 'en': 'User information is empty'},
    'currentPasswordVerificationFailed': {
      'zh': '当前密码验证失败',
      'en': 'Current password verification failed',
    },
    'currentPasswordIncorrect': {
      'zh': '当前密码不正确',
      'en': 'Current password is incorrect',
    },
    'avatarUpdated': {'zh': '头像已更新', 'en': 'Avatar updated'},
    'modifyNickname': {'zh': '修改昵称', 'en': 'Modify Nickname'},
    'pleaseEnterNewNickname': {
      'zh': '请输入新的昵称',
      'en': 'Please enter new nickname',
    },
    'nicknameUpdateSuccess': {
      'zh': '昵称更新成功',
      'en': 'Nickname updated successfully',
    },
    'nicknameUpdateFailed': {'zh': '昵称更新失败', 'en': 'Failed to update nickname'},
    'modifyBio': {'zh': '修改简介', 'en': 'Modify Bio'},
    'bio': {'zh': '简介', 'en': 'Bio'},
    'pleaseEnterNewBio': {'zh': '请输入新的简介', 'en': 'Please enter new bio'},
    'bioUpdateSuccess': {'zh': '简介更新成功', 'en': 'Bio updated successfully'},
    'bioUpdateFailed': {'zh': '简介更新失败', 'en': 'Failed to update bio'},
    'modifyEmail': {'zh': '修改邮箱', 'en': 'Modify Email'},
    'pleaseEnterNewEmail': {
      'zh': '请输入新的邮箱地址',
      'en': 'Please enter new email address',
    },
    'userInfoSyncFailed': {'zh': '同步失败', 'en': 'Sync failed'},
    'resourceServiceNotInitialized': {
      'zh': '资源服务未初始化',
      'en': 'Resource service is not initialized',
    },
    'uploadedAvatarUrlMissing': {
      'zh': '无法获取上传的头像URL',
      'en': 'Unable to get uploaded avatar URL',
    },
    'uploadAvatarFailed': {
      'zh': '上传头像失败',
      'en': 'Failed to upload avatar',
    },
    'emailUpdateSuccess': {
      'zh': '邮箱更新成功',
      'en': 'Email updated successfully',
    },
    'emailUpdateFailed': {
      'zh': '邮箱更新失败',
      'en': 'Failed to update email',
    },
    'currentPasswordLabel': {'zh': '当前密码', 'en': 'Current password'},
    'enterCurrentPassword': {
      'zh': '请输入当前密码',
      'en': 'Please enter current password',
    },
    'enterNewPassword': {
      'zh': '请输入新密码',
      'en': 'Please enter new password',
    },
    'enterNewPasswordWithMin': {
      'zh': '请输入新密码（至少3位）',
      'en': 'Please enter new password (at least 3 characters)',
    },
    'confirmNewPassword': {'zh': '确认新密码', 'en': 'Confirm new password'},
    'enterNewPasswordAgain': {
      'zh': '请再次输入新密码',
      'en': 'Please enter new password again',
    },
    'newPasswordTooShort': {
      'zh': '新密码至少需要3位',
      'en': 'New password must be at least 3 characters',
    },
    'newPasswordMismatch': {
      'zh': '两次输入的新密码不一致',
      'en': 'The new passwords do not match',
    },
    'newPasswordSameAsCurrent': {
      'zh': '新密码不能与当前密码相同',
      'en': 'New password cannot be the same as current password',
    },
    'passwordUpdateSuccessRelogin': {
      'zh': '密码修改成功，请重新登录',
      'en': 'Password updated. Please log in again.',
    },
    'passwordUpdateFailedCheckCurrent': {
      'zh': '密码修改失败，请检查当前密码是否正确',
      'en': 'Failed to update password. Please check the current password.',
    },
    'passwordUpdateFailed': {
      'zh': '密码修改失败',
      'en': 'Failed to update password',
    },
    'routeErrorTitle': {'zh': '错误', 'en': 'Error'},
    'invalidTagName': {'zh': '标签名称无效', 'en': 'Invalid tag name'},
    'pageLoadFailed': {'zh': '页面加载失败', 'en': 'Failed to load page'},
    'pageNotFound': {'zh': '页面未找到', 'en': 'Page not found'},
    'pageLost': {'zh': '哎呀，页面走丢了!', 'en': 'This page is missing.'},
    'requestPath': {'zh': '请求路径: {path}', 'en': 'Request path: {path}'},
    'saveImageToGallery': {
      'zh': '保存图片到相册',
      'en': 'Save image to Photos',
    },
    'storagePermissionRequiredForImage': {
      'zh': '需要存储权限才能保存图片',
      'en': 'Storage permission is required to save images',
    },
    'imageSavedToGallery': {
      'zh': '图片已保存到相册',
      'en': 'Image saved to Photos',
    },
    'imageSavedToDevice': {
      'zh': '图片已保存到设备',
      'en': 'Image saved to device',
    },
    'saveImageFailed': {'zh': '保存图片失败', 'en': 'Failed to save image'},
    'downloadImageFailed': {
      'zh': '下载图片失败',
      'en': 'Failed to download image',
    },
    'imageDataEmpty': {'zh': '图片数据为空', 'en': 'Image data is empty'},
    'imagePathInvalid': {
      'zh': '图片路径已失效',
      'en': 'Image path is no longer valid',
    },
    'imageNotFound': {'zh': '图片不存在', 'en': 'Image not found'},
    'referenceNoteMissing': {
      'zh': '引用的笔记不存在或已被删除 (ID: {id})',
      'en': 'The referenced note does not exist or was deleted (ID: {id})',
    },
    'discardEditTitle': {'zh': '放弃本次编辑？', 'en': 'Discard this edit?'},
    'unsavedChangesMessage': {
      'zh': '当前修改尚未保存。',
      'en': 'Your changes have not been saved.',
    },
    'discard': {'zh': '放弃', 'en': 'Discard'},
    'addLink': {'zh': '添加链接', 'en': 'Add link'},
    'displayText': {'zh': '显示文字', 'en': 'Display text'},
    'linkAddress': {'zh': '链接地址', 'en': 'Link URL'},

    // ===== SnackBarUtils相关 =====
    'networkConnectionFailed': {
      'zh': '网络连接失败，请检查网络设置',
      'en': 'Network connection failed, please check network settings',
    },
    'connectionTimeout': {
      'zh': '连接超时，请检查网络或稍后重试',
      'en': 'Connection timeout, please check network or try again later',
    },
    'serverResponseFormatError': {
      'zh': '服务器响应格式错误，请检查服务器地址',
      'en': 'Server response format error, please check server address',
    },
    'loginInfoExpired': {
      'zh': '登录信息已过期，请重新登录',
      'en': 'Login information expired, please log in again',
    },
    'noAccessPermission': {
      'zh': '没有访问权限，请联系管理员',
      'en': 'No access permission, please contact administrator',
    },
    'resourceNotFound': {
      'zh': '请求的资源不存在，请检查服务器地址',
      'en': 'Requested resource does not exist, please check server address',
    },
    'serverInternalError': {
      'zh': '服务器内部错误，请稍后重试',
      'en': 'Server internal error, please try again later',
    },
    'serverTemporarilyUnavailable': {
      'zh': '服务器暂时不可用，请稍后重试',
      'en': 'Server temporarily unavailable, please try again later',
    },
    'retry': {'zh': '重试', 'en': 'Retry'},

    // ===== DatabaseService相关 =====
    'invalidBackupFileFormat': {
      'zh': '无效的备份文件格式',
      'en': 'Invalid backup file format',
    },
    'fileNameContentMismatch': {
      'zh': '文件名和内容数量不匹配',
      'en': 'File name and content count mismatch',
    },

    // ===== 引用关系相关 =====
    'referenceRelations': {'zh': '引用关系', 'en': 'Reference Relations'},
    'viewAllReferences': {
      'zh': '查看此笔记的所有引用关系',
      'en': 'View all references of this note',
    },
    'noReferences': {'zh': '暂无引用关系', 'en': 'No references'},
    'canAddReferencesWhenEditing': {
      'zh': '在编辑笔记时可以添加引用关系',
      'en': 'You can add references when editing notes',
    },
    'referenceCreated': {'zh': '引用关系已创建', 'en': 'Reference created'},
    'referenceFailed': {'zh': '引用失败', 'en': 'Reference failed'},
    'createReferenceFailed': {
      'zh': '创建引用关系失败',
      'en': 'Failed to create reference',
    },
    'errorCreatingReference': {
      'zh': '创建引用关系时发生错误',
      'en': 'Error occurred while creating reference',
    },
    'references': {'zh': '引用关系', 'en': 'References'},

    // ===== 侧滑操作 =====
    'reminder': {'zh': '提醒', 'en': 'Remind'},

    // ===== 关于我们 =====
    'emailAddress': {'zh': '电子邮件', 'en': 'Email Address'},
    'wechat': {'zh': '微信', 'en': 'WeChat'},

    // ===== 导入导出 =====
    'selectImportMethod': {'zh': '选择导入方式', 'en': 'Select Import Method'},
    'storagePermissionRequired': {
      'zh': '需要存储权限',
      'en': 'Storage Permission Required',
    },
    'storagePermissionMessage': {
      'zh': '为了能够导出备份文件，需要授予"所有文件访问权限"。\n\n'
          '请按照以下步骤操作：\n'
          '1. 点击"允许访问所有文件"\n'
          '2. 找到并允许"InkRoot-墨鸣笔记"的权限',
      'en':
          'To export backup files, you need to grant "All Files Access" permission.\n\n'
              'Please follow these steps:\n'
              '1. Tap "Allow access to all files"\n'
              '2. Find and allow permission for "InkRoot"',
    },
    'allFilesAccessRequired': {
      'zh': '需要"所有文件访问权限"才能导出文件',
      'en': 'All files access permission is required to export files',
    },
    'storagePermissionRequiredForExport': {
      'zh': '需要存储权限才能导出文件',
      'en': 'Storage permission is required to export files',
    },
    'unsupportedExportFormat': {
      'zh': '不支持的导出格式',
      'en': 'Unsupported export format',
    },

    // ===== 笔记详情页-提醒相关 =====
    'reminderSet': {'zh': '提醒已设置', 'en': 'Reminder Set'},
    'setReminder': {'zh': '设置提醒', 'en': 'Set Reminder'},
    'clickToModifyOrCancel': {
      'zh': '点击修改或取消提醒',
      'en': 'Click to modify or cancel reminder',
    },
    'setNoteReminderTime': {'zh': '设置笔记提醒时间', 'en': 'Set note reminder time'},
    'currentReminderTime': {'zh': '当前提醒时间', 'en': 'Current Reminder Time'},
    'modifyReminderTime': {'zh': '修改提醒时间', 'en': 'Modify Reminder Time'},
    'cancelReminder': {'zh': '取消提醒', 'en': 'Cancel Reminder'},
    'reminderCancelled': {'zh': '已取消提醒', 'en': 'Reminder cancelled'},
    'enableNotificationFirst': {
      'zh': '请先开启通知权限才能设置提醒',
      'en': 'Please enable notification permission first',
    },
    'desktopReminderUnsupported': {
      'zh': '当前桌面系统暂不支持系统级定时提醒，请在手机或 macOS 上设置',
      'en':
          'System scheduled reminders are not supported on this desktop platform yet. Set reminders on mobile or macOS.',
    },
    'reminderTimeMustBeFuture': {
      'zh': '提醒时间必须在未来',
      'en': 'Reminder time must be in the future',
    },
    'setReminderFailed': {'zh': '设置提醒失败', 'en': 'Failed to set reminder'},
    'setReminderFailedRetry': {
      'zh': '设置提醒失败，请稍后重试',
      'en': 'Failed to set reminder, please try again later',
    },

    // ===== 笔记详情页-详细信息 =====
    'creationTime': {'zh': '创建时间', 'en': 'Creation Time'},
    'characterCountLabel': {'zh': '字符数量', 'en': 'Character Count'},
    'charactersUnit': {'zh': '字符', 'en': 'characters'},
    'tagsCountLabel': {'zh': '标签数量', 'en': 'Tags Count'},
    'tagsUnit': {'zh': '个标签', 'en': 'tags'},

    // ===== 笔记详情页-分享相关 =====
    'shareLinkTitle': {'zh': '分享链接', 'en': 'Share Link'},
    'noteMadePublic': {
      'zh': '您的笔记已设置为公开，任何人都可以通过链接访问',
      'en':
          'Your note has been made public and can be accessed by anyone with the link',
    },
    'linkCopied': {'zh': '链接已复制', 'en': 'Link copied'},
    'linkCopiedToClipboard': {
      'zh': '链接已复制到剪贴板',
      'en': 'Link copied to clipboard',
    },
    'copyLink': {'zh': '复制链接', 'en': 'Copy Link'},
    'shareAction': {'zh': '分享', 'en': 'Share'},
    'generateShareLinkFailed': {
      'zh': '生成分享链接失败，请稍后再试',
      'en': 'Failed to generate share link, please try again later',
    },
    'copyLinkFailed': {
      'zh': '复制链接失败，请稍后再试',
      'en': 'Failed to copy link, please try again later',
    },
    'serverUrlEmpty': {'zh': '服务器地址为空', 'en': 'Server URL is empty'},
    'cannotMakeNotePublic': {
      'zh': '无法将笔记设置为公开',
      'en': 'Cannot make note public',
    },

    // ===== 数据清理页面 =====
    'resetSettingsDescription': {
      'zh': '将所有应用设置恢复到默认状态，不会删除笔记数据',
      'en': 'Reset all app settings to default, note data will not be deleted',
    },

    // ===== AI设置页面 =====
    'getApiKey': {'zh': '获取API密钥', 'en': 'Get API Key'},

    // ===== 首页其他 =====
    'noNotesMatchingCriteria': {
      'zh': '没有符合条件的笔记',
      'en': 'No notes matching criteria',
    },
    'contentCopiedToClipboard': {
      'zh': '内容已复制到剪贴板',
      'en': 'Content copied to clipboard',
    },

    // ===== Flomo导入页面 =====
    'flomoNoteImport': {'zh': 'Flomo 笔记导入', 'en': 'Flomo Note Import'},
    'importInstructions': {'zh': '导入说明', 'en': 'Import Instructions'},
    'flomoImportStep1': {
      'zh': '1. 在 Flomo 应用中，进入"设置 > 账号详情 > 导出所有数据"',
      'en': '1. In Flomo app, go to "Settings > Account > Export All Data"',
    },
    'flomoImportStep2': {
      'zh': '2. 导出后会得到一个包含 HTML 文件和 file 目录的文件夹',
      'en':
          '2. You will get a folder containing HTML files and a file directory',
    },
    'flomoImportStep3': {
      'zh': '3. 📁 将整个导出文件夹保存到"文件"App中（iCloud Drive或本地）',
      'en':
          '3. 📁 Save the entire export folder to Files app (iCloud Drive or local)',
    },
    'flomoImportStep4': {
      'zh': '4. 点击下方"选择Flomo导出文件夹"按钮',
      'en': '4. Tap "Select Flomo Export Folder" button below',
    },
    'flomoImportStep5': {
      'zh': '5. 标签会自动识别（以 # 开头的文本）',
      'en': '5. Tags will be auto-detected (text starting with #)',
    },
    'flomoExportWarning': {
      'zh': 'Flomo 每 7 天只能导出一次，请妥善保管导出的文件',
      'en':
          'Flomo can only export once every 7 days, please keep the exported files safe',
    },
    'selectFile': {'zh': '选择文件', 'en': 'Select File'},
    'selectFlomoExportFolder': {
      'zh': '选择 Flomo 导出文件夹',
      'en': 'Select Flomo Export Folder',
    },
    'selectFlomoHtmlFile': {
      'zh': '选择 Flomo HTML 文件',
      'en': 'Select Flomo HTML File',
    },
    'alreadyInTagPage': {
      'zh': '已在标签页中',
      'en': 'Already in tag page',
    },
    'expectedImportNotes': {
      'zh': '预计导入 {count} 条笔记',
      'en': 'Expected to import {count} notes',
    },
    'containsImages': {
      'zh': '包含 {total} 张图片',
      'en': 'Contains {total} images',
    },
    'imagesMissing': {
      'zh': ' (⚠️ {missing} 张缺失)',
      'en': ' (⚠️ {missing} missing)',
    },
    'imageFileMissing': {'zh': '图片文件缺失', 'en': 'Image Files Missing'},
    'imagesDetected': {
      'zh': '检测到 {total} 张图片，但只找到 {existing} 张',
      'en': 'Detected {total} images, but only found {existing}',
    },
    'possibleReasons': {'zh': '可能原因：', 'en': 'Possible reasons:'},
    'htmlAndFileSeparated': {
      'zh': '• HTML文件和file目录不在同一位置',
      'en': '• HTML file and file directory are separated',
    },
    'fileFolderMoved': {
      'zh': '• file目录被移动或删除',
      'en': '• file directory was moved or deleted',
    },
    'exportDataIncomplete': {
      'zh': '• 导出数据不完整',
      'en': '• Export data is incomplete',
    },
    'solutionTip': {'zh': '💡 解决方法：', 'en': '💡 Solution:'},
    'ensureHtmlAndFile': {
      'zh': '1. 确保Flomo导出的HTML文件和file目录在同一文件夹中',
      'en': '1. Ensure HTML file and file directory are in the same folder',
    },
    'reselectFolder': {
      'zh': '2. 重新点击"选择Flomo导出文件夹"，选择包含HTML和file目录的整个文件夹',
      'en': '2. Re-select the folder containing both HTML and file directory',
    },
    'doNotMoveFiles': {
      'zh': '3. 不要单独移动HTML文件或file目录',
      'en': '3. Do not move HTML file or file directory separately',
    },
    'importOptions': {'zh': '导入选项', 'en': 'Import Options'},
    'preserveTags': {'zh': '保留标签', 'en': 'Preserve Tags'},
    'preserveTagsDesc': {
      'zh': '将 Flomo 中的 # 标签导入为笔记标签',
      'en': 'Import # tags from Flomo as note tags',
    },
    'preserveTime': {'zh': '保留时间', 'en': 'Preserve Time'},
    'preserveTimeDesc': {
      'zh': '尽可能保留笔记的创建时间',
      'en': 'Preserve note creation time if possible',
    },
    'importAsNew': {'zh': '作为新笔记导入', 'en': 'Import as New Notes'},
    'importAsNewDesc': {
      'zh': '所有导入的笔记将作为新笔记添加',
      'en': 'All imported notes will be added as new notes',
    },
    'importImages': {'zh': '导入图片', 'en': 'Import Images'},
    'importImagesDesc': {
      'zh': '导入笔记中的图片附件（图片会被复制到本地存储）',
      'en': 'Import image attachments (images will be copied to local storage)',
    },
    'smartDeduplication': {'zh': '智能去重', 'en': 'Smart Deduplication'},
    'detectDuplicates': {'zh': '检测重复笔记', 'en': 'Detect Duplicates'},
    'detectDuplicatesDesc': {
      'zh': '基于内容和时间智能识别重复笔记',
      'en': 'Intelligently detect duplicates based on content and time',
    },
    'whenDuplicatesFound': {'zh': '发现重复笔记时：', 'en': 'When duplicates found:'},
    'autoSkip': {'zh': '自动跳过', 'en': 'Auto Skip'},
    'autoSkipDesc': {
      'zh': '静默跳过所有重复笔记',
      'en': 'Silently skip all duplicates',
    },
    'askMe': {'zh': '询问我', 'en': 'Ask Me'},
    'askMeDesc': {
      'zh': '让我选择要导入哪些重复笔记（推荐）',
      'en': 'Let me choose which duplicates to import (recommended)',
    },
    'importAll': {'zh': '全部导入', 'en': 'Import All'},
    'importAllDesc': {
      'zh': '忽略重复检测，全部作为新笔记导入',
      'en': 'Ignore duplicates, import all as new notes',
    },
    'notePreview': {'zh': '笔记预览（前5条）', 'en': 'Note Preview (First 5)'},
    'startImport': {'zh': '开始导入', 'en': 'Start Import'},
    'dirNotExist': {'zh': '目录不存在', 'en': 'Directory does not exist'},
    'noHtmlFileInFolder': {
      'zh': '该文件夹中没有找到HTML文件',
      'en': 'No HTML file found in this folder',
    },
    'selectFolderFailed': {
      'zh': '选择文件夹失败',
      'en': 'Failed to select folder',
    },
    'fileNotExist': {'zh': '文件不存在', 'en': 'File does not exist'},
    'selectFileFailed': {
      'zh': '选择文件失败',
      'en': 'Failed to select file',
    },
    'previewFileFailed': {
      'zh': '预览文件失败',
      'en': 'Failed to preview file',
    },
    'noValidNotesInFile': {
      'zh': '文件中没有找到有效的笔记内容',
      'en': 'No valid notes found in file',
    },
    'pleaseSelectFileFirst': {
      'zh': '请先选择文件',
      'en': 'Please select a file first',
    },
    'userCancelledImport': {
      'zh': '用户取消导入',
      'en': 'Import cancelled by user',
    },
    'importFailed': {'zh': '导入失败', 'en': 'Import Failed'},
    'importSuccessful': {'zh': '导入成功', 'en': 'Import Successful'},
    'importedFromFlomo': {
      'zh': '成功从 Flomo 导入：',
      'en': 'Successfully imported from Flomo:',
    },
    'notesImported': {'zh': '{count} 条笔记', 'en': '{count} notes'},
    'imagesImported': {
      'zh': '{imported} 张图片{total}',
      'en': '{imported} images{total}',
    },
    'totalImages': {'zh': ' (共 {count} 张)', 'en': ' (of {count})'},
    'duplicatesSkipped': {
      'zh': '跳过重复 {count} 条',
      'en': 'Skipped {count} duplicates',
    },
    'imagesMissingCount': {
      'zh': '{count} 张图片未找到',
      'en': '{count} images not found',
    },
    'viewSkippedDuplicates': {
      'zh': '查看跳过的重复笔记',
      'en': 'View Skipped Duplicates',
    },
    'skippedDuplicates': {
      'zh': '跳过的重复笔记',
      'en': 'Skipped Duplicates',
    },
    'exactMatch': {'zh': '精确匹配', 'en': 'Exact Match'},
    'contentOnly': {'zh': '内容相同', 'en': 'Content Only'},
    'time': {'zh': '时间', 'en': 'Time'},
    'duplicatesFoundTitle': {
      'zh': '发现重复笔记',
      'en': 'Duplicates Found',
    },
    'duplicatesCount': {
      'zh': '共 {total} 条 (精确: {exact}, 内容相同: {contentOnly})',
      'en': 'Total {total} (Exact: {exact}, Content: {contentOnly})',
    },
    'selectedToImportHint': {
      'zh': '选中的笔记将被导入，未选中的将跳过',
      'en': 'Selected notes will be imported, unselected will be skipped',
    },
    'selectAll': {'zh': '全选', 'en': 'Select All'},
    'deselectAll': {'zh': '取消全选', 'en': 'Deselect All'},
    'skipAll': {'zh': '全部跳过', 'en': 'Skip All'},
    'importSelected': {
      'zh': '导入选中 ({count})',
      'en': 'Import Selected ({count})',
    },
    'toImport': {'zh': '待导入', 'en': 'To Import'},
    'existing': {'zh': '已存在', 'en': 'Existing'},
    'tryOtherKeywords': {
      'zh': '尝试使用其他关键词搜索',
      'en': 'Try other keywords',
    },

    // ===== 标签页面 =====
    'noTagsYet': {'zh': '还没有任何标签', 'en': 'No tags yet'},
    'noMatchingTags': {'zh': '未找到匹配的标签', 'en': 'No matching tags'},
    'tagsHelp': {
      'zh': '标签可以帮助你更好地组织和查找笔记',
      'en': 'Tags help you organize and find notes better',
    },
    'howToUseTags': {'zh': '如何使用标签', 'en': 'How to Use Tags'},
    'expandAll': {'zh': '展开所有', 'en': 'Expand All'},
    'collapseAll': {'zh': '收起所有', 'en': 'Collapse All'},
    'expandAllTags': {'zh': '展开全部', 'en': 'Expand All'},
    'expandAllTagsWithCount': {
      'zh': '展开全部 ({count}个标签)',
      'en': 'Expand All ({count} tags)',
    },
    'startWriting': {'zh': '开始写笔记', 'en': 'Start Writing'},

    // ===== 标签页面使用提示 =====
    'createTagByTyping': {
      'zh': '在笔记中输入 #标签名 创建标签',
      'en': 'Type #tagname in notes to create tags',
    },
    'hierarchicalTags': {
      'zh': '使用 / 创建层级标签，如 #工作/项目A',
      'en': 'Use / for hierarchical tags, e.g. #work/projectA',
    },
    'hierarchicalTagsShort': {
      'zh': '使用 / 创建层级标签（如 #工作/项目A）',
      'en': 'Use / for nested tags (e.g. #work/projectA)',
    },
    'clickTagToView': {
      'zh': '点击标签查看所有相关笔记',
      'en': 'Click tags to view related notes',
    },

    // ===== WebDAV设置页面 =====
    'custom': {'zh': '自定义', 'en': 'Custom'},
    'passwordAppSpecific': {
      'zh': '密码（应用专用密码）',
      'en': 'Password (App-Specific)',
    },
    'notLoginPassword': {
      'zh': '不是登录密码，需在服务商处生成',
      'en': 'Not the login password. Generate it from your service provider.',
    },
    'clickHelpIcon': {
      'zh': '点击右上角 ? 查看如何获取',
      'en': 'Tap ? for instructions',
    },

    // ===== 偏好设置页面 =====
    'sidebarCustomization': {'zh': '侧边栏', 'en': 'Sidebar'},
    'adjustMenuDisplay': {
      'zh': '调整菜单显示与排序',
      'en': 'Adjust menu display and sorting',
    },

    // ===== 侧边栏自定义页面 =====
    'customizeSidebar': {'zh': '自定义侧边栏', 'en': 'Customize Sidebar'},
    'headerComponents': {'zh': '头部组件', 'en': 'Header Components'},
    'showProfileCenter': {'zh': '显示个人中心', 'en': 'Show Profile Center'},
    'avatarUsernameLogin': {
      'zh': '头像、用户名和登录按钮',
      'en': 'Avatar, username and login button',
    },
    'showActivityLog': {'zh': '显示活动记录', 'en': 'Show Activity Log'},
    'showNoteCreationCalendar': {
      'zh': '展示笔记创建活动日历',
      'en': 'Show note creation activity calendar',
    },
    'menuItems': {'zh': '菜单项', 'en': 'Menu Items'},
    'longPressDragToReorder': {
      'zh': '长按拖动可调整顺序',
      'en': 'Long press and drag to reorder',
    },
    'confirmResetSidebar': {
      'zh': '确定要恢复侧边栏的默认设置吗？\n\n这将重置所有菜单项的显示状态和排序。',
      'en':
          'Reset sidebar to default settings?\n\nThis will reset all menu item visibility and sorting.',
    },
    'defaultHome': {'zh': '默认首页', 'en': 'Default Home'},
    'allNotesIsDefaultHome': {
      'zh': '💡 "全部笔记"是默认首页，无法隐藏或移动',
      'en': '💡 "All Notes" is the default home, cannot be hidden or moved',
    },
    'restoreDefaultSettings': {
      'zh': '恢复默认设置',
      'en': 'Restore Default Settings',
    },
    'profileOrSettingsRequired': {
      'zh': '个人中心和设置至少保留一个',
      'en': 'Keep at least Profile or Settings visible',
    },
    'defaultSettingsRestored': {
      'zh': '已恢复默认设置',
      'en': 'Default settings restored',
    },
    'sidebarConfigSaved': {
      'zh': '侧边栏配置已保存',
      'en': 'Sidebar config saved',
    },

    // ===== 通用弹窗与操作 =====
    'reset': {'zh': '重置', 'en': 'Reset'},
    'allow': {'zh': '允许', 'en': 'Allow'},
    'denyPermission': {'zh': '暂不授权', 'en': 'Not now'},
    'authorizeNow': {'zh': '立即授权', 'en': 'Allow now'},
    'permissionTip': {
      'zh': '💡 提示：授权后可以正常使用相关功能',
      'en': '💡 Tip: Grant permission to use related features',
    },
    'permissionStepTitle': {'zh': '操作步骤：', 'en': 'Steps:'},
    'permissionStepGeneral': {
      'zh': '1. 点击"去设置"按钮\n2. 找到相应权限开关\n3. 开启权限后返回应用\n4. 重新尝试使用功能',
      'en':
          '1. Tap "Go to Settings"\n2. Find the related permission\n3. Enable it and return to the app\n4. Try again',
    },
    'permissionStepShort': {
      'zh': '请按以下步骤操作：\n1. 点击"去设置"\n2. 找到相应权限开关\n3. 开启权限后返回应用',
      'en':
          'Please follow these steps:\n1. Tap "Go to Settings"\n2. Find the related permission\n3. Enable it and return to the app',
    },
    'permissionStepSpeech': {
      'zh': '1. 点击"去设置"按钮\n2. 找到"麦克风"和"语音识别"\n3. 开启权限开关\n4. 返回应用重试',
      'en':
          '1. Tap "Go to Settings"\n2. Find "Microphone" and "Speech Recognition"\n3. Enable permissions\n4. Return and try again',
    },
    'permissionStepNotification': {
      'zh': '1. 点击"去设置"按钮\n2. 找到"通知"权限\n3. 开启权限开关\n4. 返回应用重试',
      'en':
          '1. Tap "Go to Settings"\n2. Find "Notifications"\n3. Enable permission\n4. Return and try again',
    },

    // ===== 图片操作 =====
    'imageActionsTitle': {'zh': '图片操作', 'en': 'Image Actions'},
    'saveToGallery': {'zh': '保存到相册', 'en': 'Save to Photos'},
    'saveAction': {'zh': '保存', 'en': 'Save'},
    'preparingShareImage': {
      'zh': '准备分享图片...',
      'en': 'Preparing image...',
    },
    'imageShareText': {
      'zh': '来自 InkRoot 的图片分享',
      'en': 'Image shared from InkRoot',
    },
    'cannotGetImageFile': {
      'zh': '无法获取图片文件',
      'en': 'Cannot get image file',
    },
    'shareImageFailed': {
      'zh': '分享图片失败',
      'en': 'Failed to share image',
    },
    'savingFailed': {'zh': '保存失败', 'en': 'Save failed'},

    // ===== 标签配色 =====
    'tagColorTitle': {'zh': '标签配色', 'en': 'Tag Color'},
    'previewEffect': {'zh': '预览效果', 'en': 'Preview'},
    'presetColors': {'zh': '预设配色', 'en': 'Presets'},
    'selectPreset': {'zh': '选择预设', 'en': 'Presets'},
    'customColor': {'zh': '自定义', 'en': 'Custom'},
    'backgroundColor': {'zh': '背景色', 'en': 'Background'},
    'textColor': {'zh': '文字色', 'en': 'Text'},

    // ===== 个性化页面 =====
    'personalization': {'zh': '个性化', 'en': 'Personalization'},
    'clearDataTooltip': {'zh': '清除数据', 'en': 'Clear data'},
    'clearAllDataTitle': {'zh': '清除所有数据', 'en': 'Clear all data'},
    'clearLearningPreferencesMessage': {
      'zh': '确定要清除所有学习偏好数据吗？这将重置个性化推荐。',
      'en':
          'Clear all learning preference data? This will reset personalized recommendations.',
    },
    'allDataCleared': {'zh': '已清除所有数据', 'en': 'All data cleared'},
    'noDataYet': {'zh': '暂无数据', 'en': 'No Data Yet'},
    'personalizationEmptyHint': {
      'zh': '开始使用相关笔记后，这里会显示你的使用统计',
      'en': 'After using related notes, your usage statistics will appear here',
    },
    'usageStats': {'zh': '使用统计', 'en': 'Usage Stats'},
    'totalClicks': {'zh': '总点击', 'en': 'Clicks'},
    'averageDuration': {'zh': '平均时长', 'en': 'Avg Duration'},
    'topTags': {'zh': '高频标签', 'en': 'Top Tags'},
    'relationTypes': {'zh': '关系类型', 'en': 'Relation Types'},
    'recentActivity': {'zh': '最近活动', 'en': 'Recent Activity'},
    'relationContinue': {'zh': '📚 延续学习', 'en': '📚 Continue'},
    'relationComplement': {'zh': '🧩 补充知识', 'en': '🧩 Complement'},
    'relationCompare': {'zh': '🔄 对比分析', 'en': '🔄 Compare'},
    'relationQa': {'zh': '❓ 问答', 'en': '❓ Q&A'},
    'relationPractice': {'zh': '🎯 实践', 'en': '🎯 Practice'},

    // ===== 性能看板 =====
    'performanceMonitoring': {'zh': '性能监控', 'en': 'Performance'},
    'performanceMetrics': {'zh': '性能指标', 'en': 'Metrics'},
    'currentFps': {'zh': '当前FPS', 'en': 'Current FPS'},
    'logStats': {'zh': '日志统计', 'en': 'Logs'},
    'errorCount': {'zh': '错误', 'en': 'Errors'},
    'warningCount': {'zh': '警告', 'en': 'Warnings'},
    'totalCount': {'zh': '总计', 'en': 'Total'},
    'recentErrors': {'zh': '最近错误:', 'en': 'Recent errors:'},
    'tracing': {'zh': '链路追踪', 'en': 'Tracing'},
    'recentOperationCount': {
      'zh': '最近操作: {count}个',
      'en': 'Recent operations: {count}',
    },
    'metricAppLaunch': {'zh': '应用启动', 'en': 'App Launch'},
    'metricPageLoad': {'zh': '页面加载', 'en': 'Page Load'},
    'metricNetworkRequest': {'zh': '网络请求', 'en': 'Network Request'},
    'metricDatabaseQuery': {'zh': '数据库查询', 'en': 'Database Query'},
    'metricImageLoad': {'zh': '图片加载', 'en': 'Image Load'},

    // ===== 语音识别 =====
    'speechPermissionTitle': {'zh': '语音识别权限', 'en': 'Speech Permission'},
    'speechPermissionMessage': {
      'zh': '语音识别功能需要访问您的麦克风来录制语音并转换为文字。\n\n这将帮助您快速输入笔记内容。',
      'en':
          'Speech recognition needs microphone access to record speech and convert it to text.\n\nThis helps you quickly enter note content.',
    },
    'microphonePermissionTitle': {'zh': '麦克风权限', 'en': 'Microphone Permission'},
    'microphonePermissionDenied': {
      'zh': '麦克风权限被拒绝',
      'en': 'Microphone permission denied',
    },
    'microphonePermissionMessage': {
      'zh': '语音识别功能需要访问麦克风来录制您的语音并转换为文字。',
      'en':
          'Speech recognition needs microphone access to record your voice and convert it to text.',
    },
    'microphoneSettingsMessage': {
      'zh': '请在设置中手动开启麦克风权限以使用语音识别功能。',
      'en':
          'Please enable microphone permission in Settings to use speech recognition.',
    },
    'speechPermissionDenied': {
      'zh': '语音识别权限被拒绝',
      'en': 'Speech recognition permission denied',
    },
    'speechSettingsMessage': {
      'zh': '请在设置中手动开启语音识别权限。',
      'en': 'Please enable speech recognition permission in Settings.',
    },
    'speechPermissionRequiredTitle': {
      'zh': '需要麦克风权限',
      'en': 'Microphone Permission Required',
    },
    'speechPermissionRequiredMessage': {
      'zh': '语音识别功能需要麦克风和语音识别权限。',
      'en':
          'Speech recognition requires microphone and speech recognition permissions.',
    },
    'speechRecognitionUnavailable': {
      'zh': '语音识别不可用',
      'en': 'Speech Recognition Unavailable',
    },
    'localSpeechUnavailable': {
      'zh': '本地语音识别功能暂时不可用。',
      'en': 'Local speech recognition is temporarily unavailable.',
    },
    'speechUnavailableReasons': {
      'zh': '• Android: 缺少 Google 服务\n• iOS: 系统版本过低\n• 网络连接问题',
      'en':
          '• Android: Google services are missing\n• iOS: System version is too old\n• Network connection issue',
    },
    'suggestion': {'zh': '💡 建议', 'en': '💡 Suggestion'},
    'cloudSpeechSuggestion': {
      'zh': '您可以使用云端语音识别功能（百度语音），识别准确率更高。',
      'en':
          'You can use cloud speech recognition for higher recognition accuracy.',
    },
    'useCloudRecognition': {
      'zh': '使用云端识别',
      'en': 'Use Cloud Recognition',
    },
    'cloudRecognitionNotConfigured': {
      'zh': '云端识别未配置',
      'en': 'Cloud Recognition Not Configured',
    },
    'baiduSpeechNotConfigured': {
      'zh': '百度语音识别 API 尚未配置。',
      'en': 'Baidu Speech Recognition API is not configured.',
    },

    // ===== Flomo 导入 =====
    'htmlFileNotFoundTitle': {
      'zh': '未找到HTML文件',
      'en': 'HTML file not found',
    },
    'htmlFileNotFoundMessage': {
      'zh':
          '在选择的文件夹中未找到HTML文件。\n\n这可能是Android文件访问权限问题。\n\n建议：请直接选择HTML文件而不是文件夹。',
      'en':
          'No HTML file was found in the selected folder.\n\nThis may be caused by Android file access permissions.\n\nSuggestion: Select the HTML file directly instead of a folder.',
    },
    'selectHtmlFile': {'zh': '选择HTML文件', 'en': 'Select HTML File'},

    // ===== 本地备份保存 =====
    'errorTitle': {'zh': '错误', 'en': 'Error'},
    'chooseSaveLocation': {'zh': '选择保存位置', 'en': 'Choose Save Location'},
    'userCancelledSave': {'zh': '用户取消保存', 'en': 'Save cancelled'},
    'fileSaveFailed': {'zh': '文件保存失败', 'en': 'Failed to save file'},
    'saveToAppDirectoryFailed': {
      'zh': '保存到应用目录失败',
      'en': 'Failed to save to app directory',
    },
    'backupShareSubject': {'zh': 'InkRoot-墨鸣笔记备份', 'en': 'InkRoot Backup'},
    'backupShareText': {
      'zh': '墨鸣笔记导出备份：{fileName}',
      'en': 'InkRoot backup export: {fileName}',
    },
    'fileSharedToSave': {
      'zh': '文件已通过分享发送，您可以选择保存到文件管理器',
      'en': 'File shared. You can save it to a file manager.',
    },
    'localSaveSuccessTitle': {'zh': '保存成功', 'en': 'Saved'},
    'fileSavedTo': {'zh': '文件已成功保存到：', 'en': 'File saved to:'},
    'findFileInManager': {
      'zh': '您可以在文件管理器中找到该文件。',
      'en': 'You can find this file in your file manager.',
    },
    'fileSavedTitle': {'zh': '文件已保存', 'en': 'File Saved'},
    'fileSavedToPrivateDirectory': {
      'zh': '文件已保存到应用私有目录：{fileName}',
      'en': 'File saved to the app private directory: {fileName}',
    },
    'androidSaveLimitHint': {
      'zh': '由于Android系统限制，建议您通过分享将文件保存到可访问的位置。',
      'en':
          'Due to Android system restrictions, use Share to save the file to an accessible location.',
    },
    'shareNow': {'zh': '立即分享', 'en': 'Share Now'},
    'localSaveFailedTitle': {
      'zh': '本地保存失败',
      'en': 'Local Save Failed',
    },
    'localSaveFailedMessage': {
      'zh': '无法将文件保存到本地存储。是否改用分享方式，您可以通过分享选择保存位置？',
      'en':
          'Unable to save the file locally. Use Share instead so you can choose a save location?',
    },
    'shareSave': {'zh': '分享保存', 'en': 'Share to Save'},

    // ===== WebDAV 操作反馈 =====
    'invalidServerAddress': {
      'zh': '服务器地址格式不正确',
      'en': 'Invalid server address',
    },
    'webdavHttpsRequired': {
      'zh': '请使用 https://。仅 localhost、127.0.0.1 和内网地址允许 http://',
      'en':
          'Use https://. http:// is allowed only for localhost and private LAN addresses.',
    },
    'syncPathMustStartWithSlash': {
      'zh': '同步路径必须以 / 开头',
      'en': 'Sync path must start with /',
    },
    'connectionTestSuccess': {
      'zh': '连接测试成功',
      'en': 'Connection test succeeded',
    },
    'connectionTestFailed': {
      'zh': '连接测试失败，请检查配置',
      'en': 'Connection test failed. Check your settings.',
    },
    'testFailed': {'zh': '测试失败', 'en': 'Test failed'},
    'backupCompleted': {'zh': '备份完成', 'en': 'Backup completed'},
    'restoreCompleted': {'zh': '恢复完成', 'en': 'Restore completed'},
    'backupFailed': {'zh': '备份失败', 'en': 'Backup failed'},
    'restoreFailed': {'zh': '恢复失败', 'en': 'Restore failed'},
    'backupServiceUnavailable': {
      'zh': '备份服务未初始化',
      'en': 'Backup service is not ready',
    },
    'restoreServiceUnavailable': {
      'zh': '恢复服务未初始化',
      'en': 'Restore service is not ready',
    },
    'imagesBackupAttempted': {
      'zh': '图片：已尝试备份',
      'en': 'Images: backup attempted',
    },
    'webdavResourcesUploaded': {
      'zh': '资源：{count} 个',
      'en': 'Resources: {count}',
    },
    'webdavBackupNotesCount': {
      'zh': '笔记：{count} 条',
      'en': 'Notes: {count}',
    },
    'restoredNotesCount': {
      'zh': '已恢复：{count} 条笔记',
      'en': 'Restored: {count} notes',
    },
    'errorsCount': {'zh': '错误：{count}', 'en': 'Errors: {count}'},
  };

  /// 获取翻译文本
  /// [key] - 翻译键
  /// [languageCode] - 语言代码 (zh, en)
  /// [fallback] - 备用文本（可选）
  static String get(String key, String languageCode, {String? fallback}) {
    final translations = _translations[key];
    if (translations == null) {
      return fallback ?? key;
    }

    return translations[languageCode] ??
        translations['en'] ?? // 英文作为备选
        translations['zh'] ?? // 中文作为备选
        fallback ??
        key;
  }

  /// 检查是否支持某个语言
  static bool isLanguageSupported(String languageCode) =>
      languageCode == 'zh' || languageCode == 'en';

  /// 获取所有支持的语言代码
  static List<String> getSupportedLanguages() => ['zh', 'en'];
}
