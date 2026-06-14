import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();
  final List<GlobalKey> _topicKeys =
      List<GlobalKey>.generate(6, (_) => GlobalKey());
  int _selectedIndex = 0;
  bool _isProgrammaticScroll = false;

  List<String> _getCategories(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    return [
      l10n?.gettingStarted ?? '开始使用',
      l10n?.noteFeatures ?? '笔记功能',
      l10n?.tagFeatures ?? '标签功能',
      l10n?.dataSync ?? '数据同步',
      l10n?.formatEditing ?? '格式编辑',
      l10n?.commonQuestions ?? '常见问题',
    ];
  }

  @override
  void dispose() {
    _contentScrollController.removeListener(_handleContentScroll);
    _categoryScrollController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : Colors.white;
    final contentBgColor =
        isDarkMode ? AppTheme.darkSurfaceColor : const Color(0xFFF5F5F5);
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final categories = _getCategories(context);

    String? currentPath;
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } on Object {
      currentPath = '/settings/help';
    }
    final isSubPage = ResponsiveUtils.isDesktop(context) &&
        currentPath.contains('/settings/');

    return Scaffold(
      key: _scaffoldKey,
      drawer: isSubPage ? null : const Sidebar(),
      drawerEdgeDragWidth:
          isSubPage ? null : MediaQuery.of(context).size.width * 0.2,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _buildLeading(context, isSubPage, backgroundColor, iconColor),
        title: Text(
          AppLocalizationsSimple.of(context)?.helpCenter ?? '帮助中心',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: ColoredBox(
        color: contentBgColor,
        child: Column(
          children: [
            _buildCategoryBar(
              categories: categories,
              isDarkMode: isDarkMode,
              backgroundColor: backgroundColor,
              textColor: textColor,
              iconColor: iconColor,
            ),
            Expanded(child: _buildScrollableHelpContent(categories.length)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _contentScrollController.addListener(_handleContentScroll);
  }

  void _selectCategory(int index) {
    if (_selectedIndex == index) {
      _scrollToTopic(index);
      return;
    }

    setState(() => _selectedIndex = index);
    _scrollSelectedCategoryIntoView(index);
    _scrollToTopic(index);
  }

  void _scrollToTopic(int index) {
    final context = _topicKeys[index].currentContext;
    if (context == null) {
      return;
    }

    _isProgrammaticScroll = true;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    ).whenComplete(() {
      _isProgrammaticScroll = false;
    });
  }

  void _handleContentScroll() {
    if (_isProgrammaticScroll || !_contentScrollController.hasClients) {
      return;
    }

    var activeIndex = _selectedIndex;
    var nearestTop = double.negativeInfinity;
    final activationY =
        MediaQuery.of(context).padding.top + kToolbarHeight + 96;

    for (var i = 0; i < _topicKeys.length; i++) {
      final keyContext = _topicKeys[i].currentContext;
      final renderBox = keyContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        continue;
      }

      final top = renderBox.localToGlobal(Offset.zero).dy;
      if (top <= activationY && top > nearestTop) {
        nearestTop = top;
        activeIndex = i;
      }
    }

    if (activeIndex != _selectedIndex) {
      setState(() => _selectedIndex = activeIndex);
      _scrollSelectedCategoryIntoView(activeIndex);
    }
  }

  void _scrollSelectedCategoryIntoView(int index) {
    if (!_categoryScrollController.hasClients) {
      return;
    }
    final targetOffset = (index * 112.0) - 32;
    _categoryScrollController.animateTo(
      targetOffset.clamp(0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildCategoryBar({
    required List<String> categories,
    required bool isDarkMode,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) =>
      Container(
        height: 56,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: ListView.builder(
          controller: _categoryScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) {
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => _selectCategory(index),
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? iconColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : textColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildScrollableHelpContent(int categoryCount) =>
      SingleChildScrollView(
        controller: _contentScrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            categoryCount,
            (index) => KeyedSubtree(
              key: _topicKeys[index],
              child: _buildContent(index),
            ),
          ),
        ),
      );

  Widget? _buildLeading(
    BuildContext context,
    bool isSubPage,
    Color backgroundColor,
    Color iconColor,
  ) {
    if (isSubPage) {
      return null;
    }

    if (widget.showBackButton && !ResponsiveUtils.isDesktop(context)) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      );
    }

    return IconButton(
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
      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _buildHelpTopic(
          icon: Icons.start,
          header: _helpText(
            zh: '开始使用',
            en: 'Getting Started',
          ),
          description: _helpText(
            zh: '快速了解当前版本的真实功能和使用方式',
            en: 'Learn the real capabilities and recommended workflow.',
          ),
          sections: [
            _HelpSection(
              title: _helpText(zh: 'InkRoot 是什么', en: 'What InkRoot Is'),
              content: _gettingStartedOverview(),
            ),
            _HelpSection(
              title: _helpText(zh: '第一次使用', en: 'First-Time Setup'),
              content: _firstTimeUseGuide(),
            ),
          ],
        );
      case 1:
        return _buildHelpTopic(
          icon: Icons.note_alt,
          header: _helpText(zh: '笔记功能', en: 'Note Features'),
          description: _helpText(
            zh: '创建、编辑、渲染和查看笔记的实际能力',
            en: 'Create, edit, render, and review notes.',
          ),
          sections: [
            _HelpSection(
              title: _helpText(zh: '创建与编辑', en: 'Create and Edit'),
              content: _noteCreateEditGuide(),
            ),
            _HelpSection(
              title: _helpText(zh: '内容展示', en: 'Content Display'),
              content: _noteDisplayGuide(),
            ),
            _HelpSection(
              title: _helpText(zh: '搜索与回顾', en: 'Search and Review'),
              content: _searchReviewGuide(),
            ),
          ],
        );
      case 2:
        return _buildHelpTopic(
          icon: Icons.tag,
          header: _helpText(zh: '标签功能', en: 'Tag Features'),
          description: _helpText(
            zh: '用标签组织和筛选笔记',
            en: 'Organize and filter notes with tags.',
          ),
          sections: [
            _HelpSection(
              title: _helpText(zh: '标签格式', en: 'Tag Format'),
              content: _tagFormatGuide(),
            ),
            _HelpSection(
              title: _helpText(zh: '标签识别', en: 'Tag Recognition'),
              content: _tagRecognitionGuide(),
            ),
          ],
        );
      case 3:
        return _buildHelpTopic(
          icon: Icons.sync,
          header: _helpText(zh: '数据同步', en: 'Data Sync'),
          description: _helpText(
            zh: 'Memos 同步、本地离线和 WebDAV 备份的边界',
            en: 'How Memos sync, offline notes, and WebDAV backup differ.',
          ),
          sections: [
            _HelpSection(
              title: _helpText(zh: 'Memos 同步', en: 'Memos Sync'),
              content: _memosSyncGuide(),
            ),
            _HelpSection(
              title: _helpText(zh: 'WebDAV 备份', en: 'WebDAV Backup'),
              content: _webdavBackupGuide(),
            ),
            _HelpSection(
              title: _helpText(zh: '导入导出', en: 'Import and Export'),
              content: _importExportGuide(),
            ),
          ],
        );
      case 4:
        return _buildHelpTopic(
          icon: Icons.edit_note,
          header: _helpText(zh: '格式编辑', en: 'Formatting'),
          description: _helpText(
            zh: '普通用户用按钮编辑，底层兼容 Memos Markdown',
            en: 'Edit visually while staying compatible with Memos Markdown.',
          ),
          sections: [
            _HelpSection(
              title: _helpText(zh: '现在怎么编辑', en: 'How Editing Works'),
              content: _formatEditingGuide(),
            ),
            _HelpSection(
              title: _helpText(zh: '常用语法兼容', en: 'Supported Syntax'),
              content: _formatSyntaxGuide(),
            ),
          ],
        );
      case 5:
        return _buildHelpTopic(
          icon: Icons.help_outline,
          header: _helpText(zh: '常见问题', en: 'FAQ'),
          description: _helpText(
            zh: '常见异常和边界说明',
            en: 'Common issues and behavior boundaries.',
          ),
          sections: [
            _HelpSection(
              title: _helpText(zh: 'Memos 版本兼容', en: 'Memos Compatibility'),
              content: _memosCompatibilityFaq(),
            ),
            _HelpSection(
              title: _helpText(zh: '连接和同步', en: 'Connection and Sync'),
              content: _connectionSyncFaq(),
            ),
            _HelpSection(
              title: _helpText(zh: 'AI 设置', en: 'AI Settings'),
              content: _aiSettingsFaq(),
            ),
            _HelpSection(
              title: _helpText(zh: '问题反馈', en: 'Feedback'),
              content: _feedbackFaq(),
            ),
          ],
        );
      default:
        return _buildContent(0);
    }
  }

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  String _helpText({required String zh, required String en}) => _isZh ? zh : en;

  Widget _buildHelpTopic({
    required IconData icon,
    required String header,
    required String description,
    required List<_HelpSection> sections,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(
            title: header,
            icon: icon,
            description: description,
          ),
          for (final section in sections)
            _buildSection(title: section.title, content: section.content),
        ],
      );

  String _gettingStartedOverview() => _helpText(
        zh: '''
InkRoot-墨鸣笔记是一款面向 Memos 用户的跨平台笔记应用。它保留 Memos 的开放数据结构，同时强化移动端记录、离线发布、图片查看、标签整理、WebDAV 备份和 AI 辅助能力。

### 当前核心能力
- **快速记录**：主页直接创建、编辑、删除和搜索笔记
- **富文本化编辑**：常用样式通过按钮写入，用户不需要记 Markdown 语法
- **Memos 兼容**：适配旧版和新版 Memos API，按服务器版本自动选择接口
- **离线可用**：网络不可用时先保存在本地，恢复网络后再同步
- **图片体验**：支持多图浏览、原图查看、保存图片和单击退出预览
- **标签整理**：支持普通标签和多级标签，侧边栏和标签页可快速筛选
- **数据备份**：支持本地备份与 WebDAV 备份/恢复，可选备份图片附件
- **AI 辅助**：可配置兼容 OpenAI 格式的服务，用于点评、续写、洞察和标签推荐
        ''',
        en: '''
InkRoot is a cross-platform note app for Memos users. It keeps the open Memos data model while improving mobile capture, offline posting, image viewing, tag organization, WebDAV backup, and AI-assisted workflows.

### Core capabilities
- **Fast capture**: create, edit, delete, and search notes from the home screen
- **Visual formatting**: apply common styles from the toolbar without memorizing Markdown
- **Memos compatible**: detects the server version and selects the matching API
- **Offline ready**: saves notes locally first when the network is unavailable
- **Image experience**: browse multiple images, view originals, save images, and tap once to exit preview
- **Tag organization**: supports normal and nested tags for fast filtering
- **Data backup**: supports local backup and WebDAV backup/restore, including optional image attachments
- **AI assistance**: supports OpenAI-compatible services for review, continuation, insights, and tag suggestions
        ''',
      );

  String _firstTimeUseGuide() => _helpText(
        zh: r'''
### 推荐流程
1. **连接服务器**：在服务器页面填写 Memos 地址和登录信息
2. **同步笔记**：首次登录后应用会拉取服务器笔记
3. **创建笔记**：点击主页“+”或启用“启动进入编辑”快速记录
4. **添加标签**：直接输入 `#标签` 或 `#父标签/子标签`
5. **备份数据**：重要资料建议开启 WebDAV 或定期本地备份

### Memos 服务器部署参考
```bash
docker run -d \
  --name memos \
  --publish 5230:5230 \
  --volume ~/.memos/:/var/opt/memos \
  neosmemo/memos:stable
```

### 注意
- 推荐使用 HTTPS，避免账号和内容明文传输
- 不同 Memos 版本 API 有差异，遇到异常时先确认服务器版本和登录方式
- 离线发布会先保存在本地，图片资源能否同步成功取决于后续上传是否完成
        ''',
        en: r'''
### Recommended flow
1. **Connect a server**: enter your Memos server address and login information
2. **Sync notes**: the app pulls server notes after the first login
3. **Create notes**: tap “+” on the home screen or enable “open editor on launch”
4. **Add tags**: type `#tag` or `#parent/child`
5. **Back up data**: enable WebDAV or export local backups for important notes

### Memos deployment reference
```bash
docker run -d \
  --name memos \
  --publish 5230:5230 \
  --volume ~/.memos/:/var/opt/memos \
  neosmemo/memos:stable
```

### Notes
- HTTPS is recommended to avoid transmitting accounts and content in plain text
- Memos APIs differ by version; check the server version and login method first when sync fails
- Offline posts are saved locally first; image sync depends on whether later upload succeeds
        ''',
      );

  String _noteCreateEditGuide() => _helpText(
        zh: '''
### 创建新笔记
- 主页右下角“+”按钮快速创建
- 支持工具栏格式化，不要求用户手写 Markdown
- 支持图片、链接、列表、待办、引用等常用格式
- 支持离线发布，网络恢复后再同步

### 编辑现有笔记
- 点击笔记卡片进入详情页
- 点击编辑按钮进入编辑模式
- 修改完成后点击保存
- 编辑时尽量保留用户原有换行、段落和空行

### 删除笔记
- 删除前会弹出确认
- 删除成功后会显示短提示，提示会自动消失
        ''',
        en: '''
### Create a note
- Tap “+” on the home screen
- Use toolbar formatting instead of writing Markdown by hand
- Supports images, links, lists, todos, quotes, and common formats
- Supports offline posting and syncs after the network recovers

### Edit a note
- Tap a note card to open the detail page
- Tap edit to enter editing mode
- Save after making changes
- Existing line breaks, paragraphs, and blank lines are preserved as much as possible

### Delete a note
- A confirmation appears before deletion
- A short auto-dismissing message appears after deletion succeeds
        ''',
      );

  String _noteDisplayGuide() => _helpText(
        zh: '''
### 主页渲染
- 主页按可见内容排版，链接、标签、图片会按渲染结果展示
- 展开按钮按渲染后的实际可见内容计算
- 不会为了排版主动合并用户换行

### 图片查看
- 打开图片后单击背景退出
- 多图可左右滑动切换
- 优先显示原图或可访问的远程资源
- 移动端保存到相册，桌面端选择保存位置
        ''',
        en: '''
### Home rendering
- The home screen lays out rendered visible content, including links, tags, and images
- The expand control is based on the actual rendered content
- User-authored line breaks are not merged for layout convenience

### Image viewer
- Tap the background once to exit
- Swipe horizontally to switch between multiple images
- Original images or accessible remote resources are preferred
- Mobile saves to Photos; desktop lets you choose a save location
        ''',
      );

  String _searchReviewGuide() => _helpText(
        zh: '''
### 搜索
- 支持按正文关键词搜索
- 支持按标签内容搜索
- 搜索结果来自本地数据库，不只限于首页已经加载的笔记

### 随机回顾
- 从已有笔记中抽取历史内容
- 适合重新发现旧想法
- 结果优先基于本地数据，不依赖网络
        ''',
        en: '''
### Search
- Search by note text
- Search by tag text
- Results come from the local database, not just the currently loaded home list

### Random review
- Samples historical notes from your library
- Useful for rediscovering old ideas
- Works primarily from local data without relying on the network
        ''',
      );

  String _tagFormatGuide() => _helpText(
        zh: '''
### 基础标签
- 标准格式为：`#标签名`
- 一条笔记可以添加多个标签
- 例如：`#工作`、`#读书笔记`、`#2026目标`

### 多级标签
- 多级标签使用：`#父标签/子标签`
- 例如：`#工作/会议`、`#读书/医学`
- 侧边栏会按层级展示，子标签归属在父标签下
        ''',
        en: '''
### Basic tags
- Standard format: `#tag`
- One note can contain multiple tags
- Examples: `#work`, `#reading`, `#2026Goals`

### Nested tags
- Use `#parent/child` for nested tags
- Examples: `#work/meeting`, `#reading/medicine`
- The sidebar shows nested tags under their parent tags
        ''',
      );

  String _tagRecognitionGuide() => _helpText(
        zh: '''
### 识别规则
- URL 里的 `#` 不会被当作标签
- Markdown 标题里的 `##` 不会被当作标签
- 标签名中不要包含空格

### 使用建议
- 命名保持稳定，避免同义标签过多
- 高频分类用一级标签，细分场景用二级标签
- 定期清理不再使用的标签
        ''',
        en: '''
### Recognition rules
- `#` inside URLs is not treated as a tag
- Markdown heading markers like `##` are not treated as tags
- Avoid spaces inside tag names

### Recommendations
- Keep names stable and avoid too many synonyms
- Use top-level tags for frequent categories and nested tags for specific contexts
- Clean unused tags periodically
        ''',
      );

  String _memosSyncGuide() => _helpText(
        zh: '''
### 服务器连接
- 应用会探测 Memos 服务器版本，并按旧版/新版 API 选择接口
- 连接时需要正确的服务器地址、账号密码或 Token
- 升级 Memos 后如果同步异常，建议重新登录

### 同步行为
- 网络正常时发布到 Memos
- 网络不可用时先保存在本地
- 网络恢复后可手动或自动同步
- 图片资源能否显示，取决于资源上传和服务器资源接口是否成功
        ''',
        en: '''
### Server connection
- The app detects the Memos server version and selects the matching API
- A correct server address, account/password, or token is required
- If sync fails after upgrading Memos, log in again

### Sync behavior
- Posts to Memos when the network is available
- Saves locally first when offline
- Sync can run manually or automatically after the network recovers
- Image visibility depends on resource upload and server resource APIs
        ''',
      );

  String _webdavBackupGuide() => _helpText(
        zh: '''
### 能做什么
- **立即备份**：单向上传本地笔记到 WebDAV
- **从 WebDAV 恢复**：单向下载云端备份并覆盖本地
- **图片附件**：可选备份可读取的本地图片和 Memos 图片
- **自动备份**：可选择每次启动或定时备份

### 注意
- WebDAV 是备份/恢复，不是实时双向协作
- 恢复会覆盖本地笔记，应用会先在 WebDAV emergency 目录保存一份本地应急快照
- 视频和无法访问的远程图片不会被备份
        ''',
        en: '''
### What it does
- **Backup now**: one-way upload of local notes to WebDAV
- **Restore from WebDAV**: one-way download that replaces local notes
- **Image attachments**: optionally backs up readable local and Memos images
- **Automatic backup**: run on app launch or at scheduled intervals

### Notes
- WebDAV is backup/restore, not real-time two-way collaboration
- Restore overwrites local notes; the app first saves a local emergency snapshot under the WebDAV emergency folder
- Videos and inaccessible remote images are not backed up
        ''',
      );

  String _importExportGuide() => _helpText(
        zh: '''
### 当前入口
- 本地备份与恢复
- 微信读书笔记导入
- Flomo 数据导入
- WebDAV 备份与恢复

### 加密备份
- 本地备份可选密码加密
- 新导出的加密备份使用 AES 加密和完整性校验
- 旧版加密备份仍可导入

### 第三方同步
- Obsidian / 思源等同步能力通常依赖 Memos 生态插件
- 页面里如出现“双向同步”字样，应以具体页面说明为准
        ''',
        en: '''
### Current entry points
- Local backup and restore
- WeRead note import
- Flomo data import
- WebDAV backup and restore

### Encrypted backups
- Local backups can be password encrypted
- Newly exported encrypted backups use AES encryption with integrity checks
- Legacy encrypted backups can still be imported

### Third-party sync
- Obsidian, SiYuan, and similar workflows usually rely on Memos ecosystem plugins
- If a page mentions “two-way sync,” follow the detailed explanation on that page
        ''',
      );

  String _formatEditingGuide() => _helpText(
        zh: '''
### 面向普通用户
- 使用工具栏按钮加粗、插入链接、创建列表和待办
- 编辑区尽量显示最终效果，而不是让用户面对一堆符号
- 保存时会转换为 Memos 可识别的 Markdown

### 为什么底层还是 Markdown
- Memos 的内容格式本身基于 Markdown
- 使用 Markdown 存储可以兼容网页端、Memos API 和导入导出
- 应用负责把常用语法包装成更像 WPS / Office 的编辑体验
        ''',
        en: '''
### For regular users
- Use toolbar buttons for bold text, links, lists, and todos
- The editor aims to show the final visual result instead of raw symbols
- On save, content is converted into Memos-compatible Markdown

### Why Markdown still exists underneath
- Memos content is Markdown-based
- Markdown storage keeps compatibility with the web app, API, and import/export
- The app wraps common syntax in an editing experience closer to WPS or Office
        ''',
      );

  String _formatSyntaxGuide() => _helpText(
        zh: '''
### 文本格式
```
**粗体文本**
*斜体文本*
~~删除线文本~~
<u>下划线文本</u>
`行内代码`
```

### 列表和待办
```
- 无序列表
1. 有序列表
- [ ] 待办
- [x] 已完成
```

### 链接和图片
```
[链接文字](https://example.com)
![图片描述](图片URL)
```
        ''',
        en: '''
### Text formatting
```
**Bold text**
*Italic text*
~~Strikethrough text~~
<u>Underlined text</u>
`Inline code`
```

### Lists and todos
```
- Unordered list
1. Ordered list
- [ ] Todo
- [x] Done
```

### Links and images
```
[Link text](https://example.com)
![Image description](image URL)
```
        ''',
      );

  String _memosCompatibilityFaq() => _helpText(
        zh: '''
### 支持哪些版本？
- 应用会探测 Memos 服务器版本，并兼容旧版和新版常用接口
- 旧版本和新版本的登录、资源、引用接口可能不同
- 如果升级 Memos 后同步异常，建议重新登录并重新拉取数据

### 为什么有些新功能不可用？
- Memos 新版本新增的能力并非所有旧版本都有
- 例如链接聚合、资源路径、引用关系等能力会受服务器版本影响
- 应用会尽量降级处理，但不能保证所有服务器版本行为完全一致
        ''',
        en: '''
### Which versions are supported?
- The app detects the Memos server version and supports common old and new APIs
- Login, resource, and reference APIs may differ between versions
- If sync fails after upgrading Memos, log in again and pull data once

### Why are some new features unavailable?
- Newer Memos capabilities do not exist in every old version
- Link aggregation, resource paths, and references depend on the server version
- The app degrades gracefully where possible, but behavior cannot be identical across all server versions
        ''',
      );

  String _connectionSyncFaq() => _helpText(
        zh: '''
### 无法连接到服务器
- 检查服务器地址是否包含 `http://` 或 `https://`
- 检查服务器是否能在浏览器打开
- 检查账号、密码或 Token 是否正确
- 自签名证书或内网地址可能受系统网络策略影响

### 离线发布图片不显示
- 文字可以先保存在本地
- 图片还需要后续成功上传到 Memos 或被 WebDAV 备份
- 如果资源上传失败，服务器端可能看不到图片
        ''',
        en: '''
### Cannot connect to the server
- Check whether the server address includes `http://` or `https://`
- Verify the server opens in a browser
- Check account, password, or token
- Self-signed certificates or local-network addresses may be affected by system network policies

### Offline image posts do not appear
- Text can be saved locally first
- Images still need to upload to Memos or be backed up by WebDAV later
- If resource upload fails, the server may not show the images
        ''',
      );

  String _aiSettingsFaq() => _helpText(
        zh: '''
### 模型怎么填？
- 直接填写服务商文档中的模型名
- 常用模型按钮只是快速填充，不限制你输入新模型
- API 地址需要填写兼容 OpenAI 格式的接口地址

### 自定义提示词
- 开启后按功能使用对应提示词
- 关闭开关会暂时停用，不会删除输入框里的内容
- 清空输入框并保存才会删除对应提示词
        ''',
        en: '''
### What should I enter for model?
- Enter the model name from your provider documentation
- Preset buttons only fill common examples; they do not limit what you can type
- The API URL should point to an OpenAI-compatible endpoint

### Custom prompts
- When enabled, each feature uses its corresponding prompt
- Turning the switch off temporarily disables it without deleting text
- Clear the field and save to remove a custom prompt
        ''',
      );

  String _feedbackFaq() => _helpText(
        zh: '''
### 反馈时建议提供
- 设备型号和系统版本
- InkRoot 应用版本
- Memos 服务器版本
- 问题截图和复现步骤
- 是否使用了 WebDAV、AI 或离线发布

### 联系方式
- 应用内反馈：设置 → 反馈建议
- 官方邮箱：${AppConfig.supportEmail}
- 官方网站：${AppConfig.officialWebsite}
- GitHub Issues：[提交问题报告](https://github.com/yyyyymmmmm/IntRoot/issues)
        ''',
        en: '''
### What to include
- Device model and system version
- InkRoot app version
- Memos server version
- Screenshots and reproduction steps
- Whether WebDAV, AI, or offline posting was involved

### Contact
- In-app feedback: Settings → Feedback
- Email: ${AppConfig.supportEmail}
- Website: ${AppConfig.officialWebsite}
- GitHub Issues: [Submit an issue](https://github.com/yyyyymmmmm/IntRoot/issues)
        ''',
      );

  Widget _buildContentHeader({
    required String title,
    required IconData icon,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final iconBgColor = AppTheme.primaryColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final headerBgColor = AppTheme.primaryColor.withValues(alpha: 0.1);
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final codeBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    final codeBlockBgColor = isDarkMode ? Colors.grey[900] : Colors.grey[200];
    final codeBlockBorderColor =
        isDarkMode ? Colors.grey[800] : Colors.grey[300];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: content,
              extensionSet: md.ExtensionSet.gitHubFlavored,
              checkboxBuilder: (value) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: value,
                    onChanged: null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
              styleSheet: MarkdownStyleSheet(
                h3: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.8,
                ),
                p: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: textColor,
                ),
                code: TextStyle(
                  backgroundColor: codeBgColor,
                  fontFamily: 'monospace',
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
                codeblockDecoration: BoxDecoration(
                  color: codeBlockBgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: codeBlockBorderColor!),
                ),
                listBullet: TextStyle(
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  const _HelpSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}
