import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:inkroot/config/app_config.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/responsive_utils.dart';
import 'package:inkroot/widgets/sidebar.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, this.showBackButton = false});
  
  final bool showBackButton;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  List<String> _getCategories(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    return [
      l10n?.gettingStarted ?? '开始使用',
      l10n?.noteFeatures ?? '笔记功能',
      l10n?.tagFeatures ?? '标签功能',
      l10n?.dataSync ?? '数据同步',
      l10n?.markdownSyntax ?? 'Markdown语法',
      l10n?.commonQuestions ?? '常见问题',
    ];
  }

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;
    final categories = _getCategories(context);

    // 判断是否是从设置页进入的子页面（通过路由路径判断）
    // 在嵌套Navigator中可能无法获取GoRouterState，需要安全处理
    String? currentPath;
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (e) {
      // 在嵌套Navigator中，假设是子页面
      currentPath = '/settings/help';
    }
    // 只在桌面端的Master-Detail布局中才认为是子页面
    final isSubPage = ResponsiveUtils.isDesktop(context) && 
        currentPath.contains('/settings/'); // 桌面端且路径包含 /settings/，说明是设置页的子页面

    return Scaffold(
      key: _scaffoldKey,
      drawer: isSubPage ? null : const Sidebar(), // 子页面不需要侧边栏
      // 🎯 大厂标准：侧滑区域设为屏幕20%（参考微信/支付宝）
      drawerEdgeDragWidth: isSubPage ? null : MediaQuery.of(context).size.width * 0.2,
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
      body: Column(
        children: [
          // 分类导航条
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
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
          ),

          // 内容区域
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: categories
                  .map(
                    (category) => ColoredBox(
                      color: contentBgColor,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(categories.indexOf(category)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 构建AppBar的leading部分
  Widget? _buildLeading(BuildContext context, bool isSubPage, Color backgroundColor, Color iconColor) {
    // 调试信息
    debugPrint('🔍 HelpScreen - showBackButton: ${widget.showBackButton}');
    debugPrint('🔍 HelpScreen - isSubPage: $isSubPage');
    debugPrint('🔍 HelpScreen - isDesktop: ${ResponsiveUtils.isDesktop(context)}');
    
    // Master-Detail布局中不显示按钮
    if (isSubPage) {
      debugPrint('🔍 HelpScreen - 返回 null (isSubPage)');
      return null;
    }
    
    // 如果设置了showBackButton且在移动端，显示返回按钮
    if (widget.showBackButton && !ResponsiveUtils.isDesktop(context)) {
      debugPrint('🔍 HelpScreen - 返回返回按钮');
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      );
    }
    
    debugPrint('🔍 HelpScreen - 返回侧边栏按钮');
    
    // 否则显示侧边栏按钮
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
      onPressed: () {
        _scaffoldKey.currentState?.openDrawer();
      },
    );
  }

  // 根据选中的索引构建相应的内容
  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _buildGettingStarted();
      case 1:
        return _buildNotesFeatures();
      case 2:
        return _buildTagsFeatures();
      case 3:
        return _buildDataSync();
      case 4:
        return _buildMarkdownGuide();
      case 5:
        return _buildFAQ();
      default:
        return _buildGettingStarted();
    }
  }

  // 开始使用
  Widget _buildGettingStarted() {
    final l10n = AppLocalizationsSimple.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: l10n?.gettingStarted ?? '开始使用',
          icon: Icons.start,
          description:
              l10n?.quickStartDescription ?? '快速了解InkRoot-墨鸣笔记的基本功能和使用方式',
        ),
        _buildSection(
          title: l10n?.welcomeToInkRoot ?? '欢迎使用InkRoot-墨鸣笔记',
          content: '''
InkRoot-墨鸣笔记是一款基于Memos系统打造的极简跨平台笔记应用，专为追求高效记录与深度积累的用户设计。应用完美对接Memos 0.21.0版本，基于Flutter 3.32.5构建，提供纯净优雅的写作体验。

### 核心特色
- **极简设计**：Material Design 3设计语言，纯净界面专注内容创作
- **跨平台支持**：Flutter架构，Android、iOS全平台支持
- **完美兼容**：专为Memos 0.21.0版本深度优化，API稳定可靠
- **数据安全**：本地SQLite加密存储，HTTPS安全传输，支持私有化部署
- **Markdown支持**：完整的Markdown语法支持，代码高亮，所见即所得
- **智能标签**：灵活的分类管理系统，支持多级标签和快速筛选
- **全文搜索**：强大的搜索功能，快速定位任何内容
- **数据统计**：写作热力图，直观展示创作历程和活跃度

### 应用架构
- **主页**：笔记创建、浏览和管理，支持多种排序方式
- **标签页**：按标签分类整理笔记，可视化标签管理
- **随机回顾**：智能推荐历史笔记，重温精彩内容
- **个人中心**：账户管理、头像设置、密码修改、个人资料
- **设置**：主题切换、数据管理、服务器配置、隐私设置
- **实验室**：新功能预览和高级设置

### 平台支持
- **Android**：Android 5.0 (API 21) 及以上版本
- **iOS**：iOS 12.0 及以上版本  
- **Web**：现代浏览器支持，支持PWA安装
          ''',
        ),
        _buildSection(
          title:
              AppLocalizationsSimple.of(context)?.quickStartGuide ?? '快速入门指南',
          content: r'''
### 初次使用
1. **下载安装**：从GitHub Releases或官方渠道下载最新版本
2. **Memos服务器准备**：确保拥有Memos 0.21.0服务器（支持Docker部署或二进制安装）
3. **服务器连接**：在应用中配置Memos服务器地址和认证信息
4. **账户登录**：使用已有账户登录或注册新用户
5. **创建首条笔记**：点击"+"按钮开始您的笔记之旅

### Memos服务器部署（可选）
如果您还没有Memos服务器，可以使用Docker快速部署：
```bash
docker run -d \
  --name memos \
  --publish 5230:5230 \
  --volume ~/.memos/:/var/opt/memos \
  neosmemo/memos:stable
```

### 服务器连接配置
1. 打开侧边栏，点击"设置"
2. 选择"连接到Memos服务器"
3. 输入完整的服务器地址（如：https://your-memos.com:5230）
4. 选择登录方式：
   - **用户名密码**：输入注册时的用户名和密码
   - **Token登录**：使用API Token（推荐，更安全）
5. 点击"连接"进行验证和登录

⚠️ **重要提示**：
- 本应用专为Memos 0.21.0版本优化，其他版本可能存在兼容性问题
- 推荐使用HTTPS协议确保数据传输安全
- 确保服务器网络可达，防火墙已正确配置

### 笔记创建与编辑
1. **创建笔记**：在主页点击右下角"+"按钮
2. **编辑内容**：在编辑器中输入内容，支持完整Markdown语法
3. **添加标签**：使用"#标签名"格式添加标签（如：#工作 #学习）
4. **插入图片**：点击图片按钮从相册选择或拍照上传
5. **保存笔记**：点击"发送"按钮保存到本地和云端

### 个人资料管理
1. **进入个人页面**：点击侧边栏顶部的个人信息区域
2. **修改基本信息**：更新昵称、邮箱、个人简介等
3. **更换头像**：点击头像选择新图片并自动上传
4. **密码修改**：验证当前密码后设置新密码（至少3位字符）
5. **数据统计**：查看笔记数量、标签统计、活跃度等信息
          ''',
        ),
      ],
    );
  }

  // 笔记功能
  Widget _buildNotesFeatures() {
    final l10n = AppLocalizationsSimple.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: l10n?.noteFeatures ?? '笔记功能',
          icon: Icons.note_alt,
          description: l10n?.noteFeaturesDescription ?? '全面了解InkRoot-墨鸣笔记的核心功能',
        ),
        _buildSection(
          title: '笔记创建与编辑',
          content: '''
### 创建新笔记
- 主页右下角"+"按钮快速创建
- 支持富文本Markdown语法
- 实时预览渲染效果
- 自动保存草稿内容

### 编辑现有笔记
- 点击笔记卡片进入详情页
- 点击编辑按钮进入编辑模式
- 修改完成后点击"保存"按钮
- 支持版本历史记录

### 笔记删除
- 在笔记详情页点击删除图标
- 支持批量删除操作
- 删除前会弹出确认对话框
- 已删除笔记可在服务器端恢复

### 内容格式化
- **Markdown语法**：标题、列表、引用、代码块
- **文本样式**：粗体、斜体、删除线
- **链接插入**：支持网页链接和图片
- **代码高亮**：多种编程语言语法高亮
          ''',
        ),
        _buildSection(
          title: '笔记管理与组织',
          content: '''
### 排序方式
- **时间倒序**：最新创建的笔记在顶部（默认）
- **时间正序**：按创建时间正序排列
- **更新时间**：按最后修改时间排序
- **智能排序**：结合访问频率和时间

### 搜索功能
- **全文搜索**：快速定位笔记内容
- **标签筛选**：按标签类别过滤
- **时间范围**：指定时间段内的笔记
- **模糊匹配**：支持模糊关键字搜索

### 视图模式
- **列表视图**：紧凑显示更多笔记
- **卡片视图**：详细预览笔记内容
- **网格视图**：适合图片较多的笔记
- **时间轴**：按时间顺序展示笔记
          ''',
        ),
        _buildSection(
          title: '随机回顾系统',
          content: '''
### 功能介绍
随机回顾是InkRoot的特色功能，通过算法从您的笔记库中智能选取内容，帮助您重新发现被遗忘的想法和灵感。

### 使用方法
1. 从侧边栏进入"随机回顾"
2. 系统自动展示精选笔记
3. 左右滑动浏览不同内容
4. 点击笔记可查看完整内容

### 智能推荐
- **时间衰减**：优先推荐较久远的笔记
- **标签关联**：根据当前兴趣推荐相关笔记
- **访问频率**：平衡热门和冷门内容
- **内容质量**：优先推荐较长或有价值的笔记

### 个性化设置
- 设置回顾时间范围（7天/30天/全部）
- 选择特定标签的笔记回顾
- 调整推荐频率和数量
- 排除特定类型的笔记
          ''',
        ),
      ],
    );
  }

  // 标签功能
  Widget _buildTagsFeatures() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(
            title: '标签功能',
            icon: Icons.tag,
            description: '了解如何使用标签组织和管理您的笔记',
          ),
          _buildSection(
            title: '标签基础',
            content: '''
### 什么是标签？
标签是一种灵活的分类方式，帮助您组织和查找笔记。一条笔记可以添加多个标签，一个标签也可以应用于多条笔记。

### 标签格式
- 标准格式为：`#标签名`
- 标签名可以包含中文、英文、数字和下划线
- 例如：`#工作`、`#读书笔记`、`#2023目标`

### 标签优势
- 比传统文件夹更灵活
- 一条笔记可以同时属于多个分类
- 快速筛选和组织相关内容
          ''',
          ),
          _buildSection(
            title: '添加和使用标签',
            content: '''
### 如何添加标签
- 在创建或编辑笔记时，直接在内容中使用`#标签名`格式
- 可以在一条笔记中添加多个标签
- 例如：`今天完成了项目方案 #工作 #项目 #完成`

### 查看标签笔记
1. 从侧边栏进入"标签"页面
2. 查看所有已使用的标签列表
3. 点击任意标签，查看包含该标签的所有笔记
4. 点击笔记可查看详情或进行编辑

### 标签管理技巧
- 使用一致的命名方式，便于记忆和查找
- 适当使用多级标签，如`#工作_会议`、`#工作_报告`
- 定期整理标签，保持系统的清晰和高效
          ''',
          ),
          _buildSection(
            title: '标签页功能',
            content: '''
### 标签页功能介绍
- 展示所有已使用的标签
- 点击标签筛选相关笔记
- 可直接在标签页中编辑笔记
- 支持刷新和重新扫描标签

### 标签页操作指南
- **查看标签笔记**：点击标签查看相关笔记
- **编辑笔记**：点击笔记右上角的编辑图标
- **查看笔记详情**：点击笔记内容区域
- **刷新标签**：点击刷新按钮更新标签列表
- **扫描标签**：点击标签图标重新扫描所有笔记中的标签
          ''',
          ),
        ],
      );

  // 数据同步
  Widget _buildDataSync() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(
            title: '数据同步',
            icon: Icons.sync,
            description: '了解InkRoot与Memos服务器的数据同步机制',
          ),
          _buildSection(
            title: 'Memos服务器连接',
            content: r'''
### 服务器要求
- **版本要求**：必须使用Memos 0.21.0版本，专为此版本深度优化
- **部署方式**：支持Docker容器部署、二进制文件部署或源码编译部署
- **网络访问**：确保服务器可以正常访问，默认端口5230
- **HTTPS支持**：强烈推荐使用HTTPS协议保障数据安全
- **数据库支持**：SQLite（默认）、PostgreSQL、MySQL
- **权限配置**：确保账户有完整的读写权限

### Docker快速部署Memos服务器
如果您需要搭建自己的Memos服务器：
```bash
# 创建数据目录
mkdir -p ~/.memos

# 运行Memos容器
docker run -d \
  --name memos \
  --publish 5230:5230 \
  --volume ~/.memos/:/var/opt/memos \
  neosmemo/memos:stable
```

### 连接配置步骤
1. **获取服务器信息**
   - 完整服务器地址（如：https://memos.example.com:5230）
   - 用户名和密码（或API Token）
   - 确认服务器版本为0.21.0

2. **应用内配置**
   - 打开侧边栏 > "设置" > "连接到Memos服务器"
   - 输入完整服务器地址（必须包含协议前缀http://或https://）
   - 选择认证方式：
     * **用户名密码**：输入注册的用户名和密码
     * **Token登录**：使用API Token（更安全，推荐）
   - 点击"连接"进行验证

3. **连接验证流程**
   - 应用自动测试网络连接性
   - 验证Memos API版本兼容性
   - 进行用户身份认证
   - 同步基础用户信息和权限
   - 拉取最新笔记数据

### 连接状态说明
- **已连接**：绿色指示灯，数据实时双向同步
- **连接中**：黄色指示灯，正在建立连接或重连
- **连接失败**：红色指示灯，检查网络配置和服务器状态
- **离线模式**：灰色指示灯，仅本地存储，网络恢复后自动同步

### 常见连接问题
- **无法连接**：检查服务器地址格式和网络连通性
- **版本不兼容**：确认服务器为Memos 0.21.0版本
- **认证失败**：验证用户名密码或Token的正确性
- **SSL错误**：对于自签名证书，可能需要特殊配置
          ''',
          ),
          _buildSection(
            title: '同步机制详解',
            content: '''
### 实时同步
- **创建笔记**：立即上传到服务器
- **编辑笔记**：自动保存并同步修改
- **删除笔记**：同步删除操作到服务器
- **标签变更**：实时更新标签系统

### 冲突解决
- **时间戳优先**：以最新修改时间为准
- **内容对比**：检测实际内容差异
- **用户选择**：重要冲突提示用户决定
- **备份保护**：冲突内容自动备份

### 离线支持
- **本地缓存**：离线时可正常使用
- **智能队列**：网络恢复后自动同步
- **冲突检测**：上线时检查数据一致性
- **断点续传**：大文件分块上传

### 数据安全
- **加密传输**：HTTPS协议保护数据传输
- **本地加密**：敏感数据本地加密存储
- **访问控制**：基于Token的权限管理
- **备份恢复**：定期自动备份，支持数据恢复
          ''',
          ),
          _buildSection(
            title: '数据导入导出',
            content: '''
### 导出功能
- **全量导出**：导出所有笔记和标签
- **选择性导出**：按标签或时间范围导出
- **格式支持**：JSON、Markdown、HTML格式
- **附件处理**：包含图片等附件资源

### 导入功能
- **Memos数据**：从其他Memos实例导入
- **Markdown文件**：批量导入Markdown格式笔记
- **其他格式**：支持常见笔记应用格式
- **智能去重**：避免重复导入相同内容

### 备份策略
- **自动备份**：连接服务器时自动备份
- **手动备份**：在设置中手动创建备份
- **定期备份**：设置定期备份提醒
- **版本管理**：保留多个备份版本

### 数据迁移
- **服务器迁移**：在不同Memos服务器间迁移
- **设备迁移**：在不同设备间同步数据
- **平台迁移**：从其他笔记应用迁移到InkRoot
- **格式转换**：支持多种数据格式转换
          ''',
          ),
        ],
      );

  // Markdown语法指南
  Widget _buildMarkdownGuide() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(
            title: 'Markdown语法指南',
            icon: Icons.code,
            description: '学习在笔记中使用Markdown格式化文本',
          ),
          _buildSection(
            title: 'Markdown基础',
            content: '''
### 什么是Markdown？
Markdown是一种轻量级标记语言，让您使用纯文本格式编写文档，并转换成结构化的HTML显示。InkRoot-墨鸣笔记支持Markdown语法，让您的笔记更加丰富多彩。

### Markdown优势
- 简单易学，使用纯文本
- 专注于内容而非排版
- 可读性强，即使不转换也易于阅读
- 跨平台兼容性好
          ''',
          ),
          _buildSection(
            title: '常用Markdown语法',
            content: '''
### 标题
```
# 一级标题
## 二级标题
### 三级标题
```

### 文本格式
```
**粗体文本**
*斜体文本*
~~删除线文本~~
`行内代码`
```

### 列表
```
- 无序列表项1
- 无序列表项2
  - 嵌套列表项

1. 有序列表项1
2. 有序列表项2
```

### 引用
```
> 这是一段引用文本
> 可以跨多行
```

### 链接和图片
```
[链接文字](https://example.com)
![图片描述](图片URL)
```

### 代码块
```
这里是代码块
可以包含多行代码
```

### 表格
```
| 表头1 | 表头2 |
| ----- | ----- |
| 单元格1 | 单元格2 |
| 单元格3 | 单元格4 |
```
          ''',
          ),
          _buildSection(
            title: 'Markdown在InkRoot-墨鸣笔记中的应用',
            content: '''
### 为什么在InkRoot-墨鸣笔记中使用Markdown？
- 结构化笔记内容，提高可读性
- 统一格式，美观整洁
- 实现更复杂的文本排版效果

### 使用建议
- 使用标题层级组织笔记结构
- 使用列表整理条目和步骤
- 使用引用突出重要信息
- 使用代码块保存代码或格式化文本
- 结合标签系统，进一步提高笔记管理效率

### InkRoot-墨鸣笔记中的特殊语法
- 标签格式：`#标签名`
- 使用三个反引号(```)创建代码块
- 支持表格和大部分常用Markdown语法
          ''',
          ),
        ],
      );

  // 常见问题
  Widget _buildFAQ() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(
            title: '常见问题',
            icon: Icons.help_outline,
            description: '解答使用InkRoot-墨鸣笔记时可能遇到的问题',
          ),
          _buildSection(
            title: '版本兼容性问题',
            content: '''
### 为什么只支持Memos 0.21.0版本？
- **API稳定性**：0.21.0版本API接口稳定，经过充分测试
- **功能完整性**：该版本包含InkRoot所需的全部API功能
- **兼容性保障**：不同版本的API差异较大，专版本优化确保最佳体验
- **安全考虑**：0.21.0版本包含重要的安全更新和修复

### 如何确认Memos服务器版本？
1. 访问服务器管理后台
2. 查看"关于"或"系统信息"页面
3. 确认版本号为0.21.0
4. 如版本不符，建议升级到指定版本

### 使用其他版本会有什么问题？
- **连接失败**：API接口不兼容导致无法连接
- **功能异常**：部分功能可能无法正常使用
- **数据同步错误**：可能出现数据同步失败
- **安全风险**：较老版本可能存在安全漏洞
          ''',
          ),
          _buildSection(
            title: '连接和同步问题',
            content: '''
### 无法连接到Memos服务器？
1. **检查网络连接**：确保设备网络正常
2. **验证服务器地址**：确认地址格式正确（如：https://memos.example.com）
3. **检查服务器状态**：确认服务器正常运行
4. **防火墙设置**：检查是否被防火墙阻止
5. **SSL证书**：HTTPS站点需要有效的SSL证书

### 登录时提示用户名或密码错误？
- **检查凭据**：确认用户名和密码正确
- **大小写敏感**：注意用户名和密码的大小写
- **Token方式**：推荐使用API Token登录，更安全稳定
- **权限检查**：确认账户有足够的访问权限

### 笔记无法同步到服务器？
- **网络状态**：检查网络连接是否稳定
- **存储空间**：确认服务器存储空间充足
- **权限验证**：检查登录Token是否过期
- **重新登录**：尝试退出后重新登录
- **检查日志**：查看应用错误日志获取详细信息

### 离线时能否继续使用？
- **本地存储**：离线时可正常创建和编辑笔记
- **自动缓存**：应用会自动缓存最近的笔记内容
- **同步队列**：网络恢复后会自动同步离线期间的操作
- **冲突处理**：上线时会智能处理可能的数据冲突
          ''',
          ),
          _buildSection(
            title: '账户和个人信息问题',
            content: '''
### 如何修改个人头像？
1. **进入个人页面**：点击侧边栏顶部的个人信息区域
2. **点击头像**：在个人信息页面点击头像图标
3. **选择图片**：从设备相册中选择新头像
4. **自动上传**：应用会自动上传并更新头像
5. **即时生效**：头像修改后立即在所有界面生效

### 头像显示异常或无法加载？
- **网络问题**：检查网络连接是否正常
- **图片格式**：确保使用JPEG或PNG格式图片
- **文件大小**：建议头像文件小于2MB
- **清除缓存**：尝试退出应用后重新进入
- **重新上传**：删除当前头像后重新上传

### 如何修改登录密码？
1. **进入个人信息页面**：点击侧边栏个人信息区域
2. **点击修改密码**：在基本信息设置中找到"修改密码"
3. **输入当前密码**：验证身份，输入当前登录密码
4. **设置新密码**：输入新密码并确认（至少3位字符）
5. **自动退出**：密码修改成功后会自动退出，需重新登录

### 忘记密码怎么办？
- **服务器重置**：联系Memos服务器管理员重置密码
- **找回功能**：部分服务器支持邮箱找回密码功能
- **管理员协助**：请求管理员帮助重置或创建新账户
- **备用登录**：如有API Token，可使用Token登录后修改密码
          ''',
          ),
          _buildSection(
            title: '笔记和标签问题',
            content: '''
### 标签未被正确识别？
- **格式检查**：确保使用"#标签名"格式，标签前有#号
- **字符限制**：标签名支持中文、英文、数字和下划线
- **空格问题**：标签名中不能包含空格
- **分隔方式**：多个标签之间用空格分隔
- **刷新列表**：编辑后点击标签页面的刷新按钮

### Markdown格式不生效？
- **语法检查**：确认Markdown语法正确
- **预览模式**：在笔记详情页查看渲染效果
- **支持范围**：检查是否使用了支持的Markdown语法
- **特殊字符**：某些特殊字符可能需要转义
- **应用重启**：尝试重启应用后查看效果

### 笔记搜索功能不准确？
- **关键词完整**：使用完整的关键词进行搜索
- **标签搜索**：可以通过标签进行精确筛选
- **刷新索引**：尝试下拉刷新重新建立搜索索引
- **内容同步**：确保笔记内容已完全同步
- **搜索范围**：检查是否选择了正确的搜索范围

### 如何批量管理笔记？
- **标签筛选**：通过标签页面批量查看同类笔记
- **时间筛选**：按创建或修改时间查看特定时期的笔记
- **搜索结果**：在搜索结果中进行批量操作
- **导出功能**：可批量导出特定条件的笔记
          ''',
          ),
          _buildSection(
            title: '应用性能和故障排除',
            content: '''
### 应用启动慢或卡顿？
- **设备性能**：检查设备存储空间和内存使用情况
- **笔记数量**：大量笔记可能影响启动速度
- **网络请求**：启动时的同步操作可能影响响应速度
- **重启应用**：完全关闭应用后重新启动
- **设备重启**：尝试重启设备释放系统资源

### 数据丢失或损坏？
- **本地备份**：检查设备本地是否有备份数据
- **服务器恢复**：登录服务器查看云端数据
- **版本历史**：Memos服务器可能保留历史版本
- **紧急恢复**：联系技术支持协助数据恢复
- **预防措施**：建议定期手动备份重要数据

### 如何彻底重置应用？
1. **清除应用数据**：在设备设置中清除应用数据
2. **重新安装**：卸载应用后重新安装
3. **服务器数据**：清除本地数据不会影响服务器数据
4. **重新配置**：重置后需要重新配置服务器连接
5. **数据同步**：重新登录后可从服务器恢复数据

### 技术支持与联系方式
如遇到其他问题或需要技术支持，请通过以下方式联系我们：

#### 官方支持渠道
- **应用内反馈**：设置 → 反馈建议（推荐，最快响应）
- **官方邮箱**：${AppConfig.supportEmail}
- **官方网站**：${AppConfig.officialWebsite}
- **在线客服**：https://kf.didichou.site（工作时间：9:00-22:00）

#### 开源社区支持
- **GitHub Issues**：[提交问题报告](https://github.com/yyyyymmmmm/IntRoot/issues)
- **GitHub Discussions**：[功能建议和讨论](https://github.com/yyyyymmmmm/IntRoot/discussions)
- **项目主页**：https://github.com/yyyyymmmmm/IntRoot

#### Memos官方资源
- **Memos官网**：https://usememos.com
- **Memos GitHub**：https://github.com/usememos/memos
- **Memos文档**：https://usememos.com/docs/

📧 **提交问题时请提供以下信息以便快速定位问题：**
- 设备型号和操作系统版本
- InkRoot应用版本
- Memos服务器版本
- 详细的错误描述和重现步骤
- 相关的错误截图或日志信息

💬 **响应时间承诺：**
- 应用内反馈：24小时内回复
- 邮件咨询：48小时内回复
- GitHub Issues：72小时内回复
- 在线客服：工作时间内30分钟回复
          ''',
          ),
        ],
      );

  // 内容头部
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
    final iconBgColor = isDarkMode
        ? AppTheme.primaryColor.withOpacity(0.2)
        : AppTheme.primaryColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
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
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
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

  // 内容区块
  Widget _buildSection({required String title, required String content}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final headerBgColor = isDarkMode
        ? AppTheme.primaryColor.withOpacity(0.2)
        : AppTheme.primaryColor.withOpacity(0.1);
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
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
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
              extensionSet: md.ExtensionSet.gitHubFlavored, // 🎯 启用GitHub风格Markdown（支持待办事项）
              checkboxBuilder: (value) {
                // 🎯 自定义复选框渲染（待办事项支持）
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    value: value,
                    onChanged: null, // 只读模式
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
