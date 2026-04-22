# IntRoot 项目架构文档

> **版本**: 2.0 (2026-04-21 重构版)
> **作者**: 项目组
> **更新**: 2026-04-21

---

## 目录

1. [架构概述](#架构概述)
2. [模块化设计](#模块化设计)
3. [目录结构](#目录结构)
4. [核心模块详解](#核心模块详解)
5. [数据流](#数据流)
6. [设计模式](#设计模式)
7. [最佳实践](#最佳实践)

---

## 架构概述

IntRoot 采用 **MVVM + Mixin + Service Layer** 架构，通过模块化设计实现高内聚低耦合。

### 架构分层

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│      (Screens & Widgets)            │
├─────────────────────────────────────┤
│         Business Logic Layer        │
│      (Providers with Mixins)        │
├─────────────────────────────────────┤
│          Service Layer              │
│   (API, Database, Storage)          │
├─────────────────────────────────────┤
│          Data Layer                 │
│        (Models & DTOs)              │
└─────────────────────────────────────┘
```

### 核心原则

1. **单一职责**：每个模块只负责一个功能领域
2. **依赖倒置**：高层模块不依赖低层模块，依赖抽象
3. **开闭原则**：对扩展开放，对修改封闭
4. **接口隔离**：客户端不应依赖它不使用的接口

---

## 模块化设计

### 重构成果（2026-04-21）

通过模块化重构，主文件行数减少 **47.5%**，创建 **18个功能模块**：

| 文件 | 重构前 | 重构后 | 减少 |
|------|-------|-------|------|
| home_screen.dart | 3470行 | 2311行 | -33% |
| app_provider.dart | 5172行 | 2674行 | -48% |
| share_utils.dart | 3243行 | 1249行 | -61.5% |

### 模块列表

#### 1. Provider 模块（7个）

**位置**: `lib/providers/app_provider_modules/`

| 模块 | 行数 | 职责 |
|------|------|------|
| **app_provider_auth.dart** | 1042 | 用户认证（注册/登录/登出/Token管理） |
| **app_provider_notes.dart** | 1392 | 笔记操作（CRUD/搜索/排序/标签/引用/同步） |
| **app_provider_webdav.dart** | 366 | WebDAV同步（备份/恢复/配置/定时任务） |
| **app_provider_announcement.dart** | 203 | 公告管理（初始化/刷新/已读标记） |
| **app_provider_cloud_verification.dart** | 160 | 云验证（加载/更新/版本检查） |
| **app_provider_notion.dart** | 138 | Notion同步（同步/配置） |
| **app_provider_config.dart** | 131 | 配置管理（主题/暗黑模式/语言） |

**集成方式（Dart Mixin）**：
```dart
class AppProvider with ChangeNotifier,
    AppProviderAuth,
    AppProviderAnnouncement,
    AppProviderCloudVerification,
    AppProviderConfig,
    AppProviderNotes,
    AppProviderNotion,
    AppProviderWebDav {
  // 主类只保留核心状态和初始化逻辑
}
```

#### 2. Home Screen 模块（5个）

**位置**: `lib/screens/home/`

| 模块 | 行数 | 职责 |
|------|------|------|
| **home_ai_insight.dart** | 806 | AI洞察对话（洞察生成/对话管理/UI渲染） |
| **home_layouts.dart** | 765 | 布局组件（通知栏/空状态/骨架屏/加载指示器） |
| **home_note_form.dart** | 161 | 笔记表单（创建/编辑笔记的表单UI） |
| **home_search_helper.dart** | 66 | 搜索辅助（搜索逻辑封装） |
| **home_note_list_ui.dart** | 238 | 列表UI（笔记列表渲染） |

#### 3. Note Detail 模块（4个）

**位置**: `lib/screens/note_detail/`

| 模块 | 行数 | 职责 |
|------|------|------|
| **note_detail_ai_helper.dart** | 332 | AI助手（AI评审/优化建议） |
| **note_detail_image_helper.dart** | 167 | 图片处理（图片网格/预览/上传） |
| **note_detail_link_handler.dart** | 88 | 链接处理（双向链接解析/跳转） |
| **note_detail_todo_handler.dart** | 95 | 待办事项（TODO状态切换） |

#### 4. Share 模块（2个）

**位置**: `lib/utils/share_modules/`

| 模块 | 行数 | 职责 |
|------|------|------|
| **share_template_simple.dart** | 996 | Simple/Flomo模板（并发图片加载/Markdown渲染） |
| **share_template_card.dart** | 892 | Card/ModernCard模板（现代卡片布局） |

---

## 目录结构

```
IntRoot-main/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── config/
│   │   └── app_config.dart                # 应用配置
│   ├── models/                            # 数据模型
│   │   ├── note_model.dart                # 笔记模型
│   │   ├── user_model.dart                # 用户模型
│   │   ├── announcement_model.dart        # 公告模型
│   │   └── ...
│   ├── services/                          # 服务层
│   │   ├── api_service.dart               # API服务基类
│   │   ├── database_service.dart          # 数据库服务
│   │   ├── memos_api_service_fixed.dart   # Memos API
│   │   ├── webdav_service.dart            # WebDAV服务
│   │   ├── notion_sync_service.dart       # Notion服务
│   │   └── ...
│   ├── providers/                         # 状态管理
│   │   ├── app_provider.dart              # 主Provider (2674行)
│   │   └── app_provider_modules/          # Provider模块
│   │       ├── app_provider_auth.dart
│   │       ├── app_provider_notes.dart
│   │       ├── app_provider_webdav.dart
│   │       ├── app_provider_announcement.dart
│   │       ├── app_provider_cloud_verification.dart
│   │       ├── app_provider_notion.dart
│   │       └── app_provider_config.dart
│   ├── screens/                           # 页面
│   │   ├── home_screen.dart               # 首页 (2311行)
│   │   ├── home/                          # 首页模块
│   │   │   ├── home_ai_insight.dart
│   │   │   ├── home_layouts.dart
│   │   │   ├── home_note_form.dart
│   │   │   ├── home_search_helper.dart
│   │   │   └── home_note_list_ui.dart
│   │   ├── note_detail_screen.dart        # 笔记详情
│   │   ├── note_detail/                   # 详情模块
│   │   │   ├── note_detail_ai_helper.dart
│   │   │   ├── note_detail_image_helper.dart
│   │   │   ├── note_detail_link_handler.dart
│   │   │   └── note_detail_todo_handler.dart
│   │   └── preferences_screen.dart        # 设置页面
│   ├── utils/                             # 工具类
│   │   ├── share_utils.dart               # 分享工具 (1249行)
│   │   ├── share_modules/                 # 分享模块
│   │   │   ├── share_template_simple.dart
│   │   │   └── share_template_card.dart
│   │   ├── logger.dart                    # 日志工具
│   │   └── ...
│   └── widgets/                           # 通用组件
│       ├── cached_avatar.dart
│       ├── note_card.dart
│       └── ...
├── assets/                                # 资源文件
│   ├── images/
│   └── fonts/
├── .env                                   # 环境配置
├── pubspec.yaml                           # 依赖配置
├── README.md                              # 项目说明
├── ARCHITECTURE.md                        # 架构文档（本文件）
└── CHANGELOG_2026-04-21.md               # 更新日志
```

---

## 核心模块详解

### 1. AppProvider（主Provider）

**文件**: `lib/providers/app_provider.dart`

**职责**：
- 应用全局状态管理
- 协调各功能模块
- 提供统一的状态访问接口

**核心状态**：
```dart
class AppProvider with ChangeNotifier, /* 7个Mixin */ {
  // 用户相关
  User? _user;

  // 笔记相关
  List<Note> _notes = [];
  bool _isLoading = false;
  LoadMoreState _loadMoreState = LoadMoreState.idle;

  // 服务实例
  ApiService? _apiService;
  DatabaseService _databaseService = DatabaseService();

  // 配置
  AppConfig _appConfig = AppConfig();

  // ... 其他状态
}
```

**Mixin集成**：
通过 `with` 关键字混入7个功能模块，实现代码复用：
- 认证功能（Auth）
- 笔记操作（Notes）
- WebDAV同步（WebDav）
- 公告管理（Announcement）
- 云验证（CloudVerification）
- Notion同步（Notion）
- 配置管理（Config）

### 2. AppProviderNotes（笔记模块）

**文件**: `lib/providers/app_provider_modules/app_provider_notes.dart`

**核心功能**：

1. **笔记CRUD**
   - `createNote()` - 创建笔记
   - `updateNote()` - 更新笔记
   - `deleteNote()` - 删除笔记（乐观更新）
   - `restoreNote()` - 撤销删除

2. **笔记查询**
   - `getNoteById()` - 根据ID获取
   - `loadNotesFromLocal()` - 从本地加载
   - `loadInitialNotes()` - 分页加载（三阶段）

3. **笔记操作**
   - `togglePinStatus()` - 切换置顶
   - `sortNotes()` - 排序
   - `updateNoteTags()` - 更新标签

4. **标签管理**
   - `extractTags()` - 提取标签
   - `getAllTags()` - 获取所有标签
   - `refreshAllNoteTagsWithDatabase()` - 刷新标签

5. **引用处理**
   - `_processNoteReferences()` - 处理双向链接
   - `_cleanupReferencesForDeletedNote()` - 清理引用

6. **同步**
   - `syncNotesWithServer()` - 完整同步
   - `syncNotesToServer()` - 推送同步

### 3. HomeScreen（首页）

**文件**: `lib/screens/home_screen.dart`

**模块化拆分**：

| 功能 | 原位置 | 新模块 |
|------|-------|-------|
| AI洞察对话 | home_screen.dart | home_ai_insight.dart |
| 通知栏/空状态/骨架屏 | home_screen.dart | home_layouts.dart |
| 笔记表单 | home_screen.dart | home_note_form.dart |
| 搜索逻辑 | home_screen.dart | home_search_helper.dart |
| 列表UI | home_screen.dart | home_note_list_ui.dart |

**集成方式**：
```dart
// 显示AI洞察对话
void _showAiInsightDialog() {
  showAiInsightDialog(context); // 调用独立模块
}

// 构建通知栏
Widget _buildNotificationBanner() {
  return buildNotificationBanner(...); // 调用独立模块
}
```

### 4. ShareUtils（分享工具）

**文件**: `lib/utils/share_utils.dart`

**模块化拆分**：

原3243行拆分为：
- **主文件** (1249行)：入口方法、Canvas引擎、保存/分享
- **share_template_simple.dart** (996行)：Simple/Flomo模板
- **share_template_card.dart** (892行)：Card/ModernCard模板

**性能优化**：
- 并发图片加载（减少50-80%加载时间）
- LRU缓存机制（避免重复下载）
- 进度回调支持（用户体验优化）

---

## 数据流

### 典型数据流（笔记创建）

```
1. 用户输入笔记内容
   └─> home_note_form.dart

2. 调用 Provider 创建方法
   └─> AppProvider.createNote()
       └─> app_provider_notes.dart (Mixin)

3. 保存到数据库
   └─> DatabaseService.insertNote()

4. 同步到服务器
   └─> MemosApiService.createMemo()

5. 更新UI状态
   └─> notifyListeners()
       └─> home_screen.dart (重新构建)
```

### 同步数据流（WebDAV备份）

```
1. 用户触发备份
   └─> AppProvider.performManualWebDavBackup()
       └─> app_provider_webdav.dart (Mixin)

2. 导出笔记数据
   └─> DatabaseService.getAllNotes()

3. 生成JSON
   └─> jsonEncode(notes)

4. 上传到WebDAV
   └─> WebDavService.uploadFile()

5. 记录备份时间
   └─> PreferencesService.setLastBackupTime()
```

---

## 设计模式

### 1. Mixin模式（核心）

**应用场景**：AppProvider模块化

**优点**：
- 代码复用不依赖继承
- 多个Mixin可组合使用
- 100%向后兼容

**示例**：
```dart
// 定义Mixin
mixin AppProviderAuth on ChangeNotifier {
  Future<bool> login(String username, String password) async {
    // 登录逻辑
    notifyListeners();
    return true;
  }
}

// 使用Mixin
class AppProvider with ChangeNotifier, AppProviderAuth {
  // 自动拥有login()方法
}
```

### 2. Provider模式（状态管理）

**应用场景**：全局状态管理

**优点**：
- 依赖注入，解耦UI和业务逻辑
- 响应式更新，自动重建Widget
- 易于测试

**示例**：
```dart
// 提供状态
ChangeNotifierProvider(
  create: (_) => AppProvider(),
  child: MyApp(),
)

// 消费状态
Consumer<AppProvider>(
  builder: (context, provider, child) {
    return Text(provider.user?.name ?? 'Guest');
  },
)
```

### 3. Repository模式（数据访问）

**应用场景**：数据层抽象

**优点**：
- 分离数据来源（本地/远程）
- 统一数据访问接口
- 易于切换数据源

**示例**：
```dart
class NoteRepository {
  final DatabaseService _db;
  final ApiService _api;

  // 获取笔记（优先本地，失败则远程）
  Future<Note?> getNote(String id) async {
    return await _db.getNote(id) ?? await _api.getNote(id);
  }
}
```

### 4. Service模式（业务逻辑封装）

**应用场景**：复杂业务逻辑

**优点**：
- 单一职责，每个Service专注一个领域
- 可复用，多个Provider可共享Service
- 易于测试

**示例**：
```dart
class WebDavSyncService {
  Future<bool> backup(List<Note> notes) async {
    // WebDAV备份逻辑
  }

  Future<List<Note>> restore() async {
    // WebDAV恢复逻辑
  }
}
```

---

## 最佳实践

### 1. 代码规范

**文件行数限制**：
- 主文件 ≤ 2700 行
- 模块文件 ≤ 1000 行
- 单个类 ≤ 500 行
- 单个方法 ≤ 50 行

**命名规范**：
```dart
// 类名：大驼峰
class UserProfile {}

// 方法名：小驼峰
void getUserProfile() {}

// 私有成员：下划线开头
String _privateField;
void _privateMethod() {}

// 常量：大写下划线
const int MAX_RETRY_COUNT = 3;

// 文件名：小写下划线
// user_profile_screen.dart
```

### 2. 模块化原则

**何时拆分模块？**
- 单个文件 > 1000 行
- 功能职责不单一
- 多处重复代码
- 测试困难

**如何拆分？**
1. 识别独立功能领域
2. 提取到独立文件
3. 定义清晰的接口
4. 通过Mixin或导入集成

### 3. 性能优化

**列表性能**：
```dart
// ✅ 使用ListView.builder（按需构建）
ListView.builder(
  itemCount: notes.length,
  itemBuilder: (context, index) => NoteCard(notes[index]),
)

// ❌ 避免ListView(children: ...)（一次性构建所有）
```

**图片缓存**：
```dart
// ✅ 使用缓存
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
)

// ❌ 避免直接Image.network（每次重新下载）
```

**状态管理**：
```dart
// ✅ 局部刷新
Consumer<AppProvider>(
  builder: (context, provider, child) {
    return Text(provider.user.name); // 只刷新这个Text
  },
)

// ❌ 避免全局刷新
// 整个页面rebuild
```

### 4. 错误处理

**统一错误处理**：
```dart
try {
  await apiService.createNote(note);
} on NetworkException catch (e) {
  showError('网络错误：${e.message}');
} on AuthException catch (e) {
  showError('认证失败，请重新登录');
} catch (e) {
  showError('未知错误：$e');
  logger.error('Unexpected error', error: e);
}
```

### 5. 测试

**单元测试**：
```dart
test('createNote should add note to list', () async {
  final provider = AppProvider();
  final note = Note(id: '1', content: 'Test');

  await provider.createNote(note);

  expect(provider.notes.length, 1);
  expect(provider.notes.first.id, '1');
});
```

**集成测试**：
```dart
testWidgets('HomeScreen should display notes', (tester) async {
  await tester.pumpWidget(MyApp());

  expect(find.byType(NoteCard), findsWidgets);
});
```

---

## 附录

### A. 依赖关系图

```
┌─────────────────┐
│   Screens       │
│ (Presentation)  │
└────────┬────────┘
         │ depends on
         ↓
┌─────────────────┐
│   Providers     │
│ (Business Logic)│
└────────┬────────┘
         │ depends on
         ↓
┌─────────────────┐
│   Services      │
│ (API, Database) │
└────────┬────────┘
         │ depends on
         ↓
┌─────────────────┐
│    Models       │
│  (Data Objects) │
└─────────────────┘
```

### B. 模块依赖关系

```
AppProvider (主类)
  ├─ with AppProviderAuth (认证)
  ├─ with AppProviderNotes (笔记)
  │    └─ uses DatabaseService
  │    └─ uses ApiService
  ├─ with AppProviderWebDav (WebDAV)
  │    └─ uses WebDavService
  ├─ with AppProviderNotion (Notion)
  │    └─ uses NotionSyncService
  ├─ with AppProviderAnnouncement (公告)
  ├─ with AppProviderCloudVerification (云验证)
  └─ with AppProviderConfig (配置)
```

### C. 技术选型理由

| 技术 | 选型理由 |
|------|---------|
| **Flutter** | 跨平台、高性能、生态成熟 |
| **Provider** | 官方推荐、简单易用、性能优秀 |
| **Mixin** | 代码复用、灵活组合、无继承限制 |
| **SQLite** | 轻量级、离线支持、全文搜索 |
| **WebDAV** | 开放标准、自主可控、隐私保护 |

---

**文档版本**: 2.0
**最后更新**: 2026-04-21
**维护者**: 项目组
