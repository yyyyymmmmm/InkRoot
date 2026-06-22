# 项目结构与构建指南

这份文档用于维护 InkRoot 项目。重点回答三个问题：

- 仓库里的主要文件和文件夹分别负责什么。
- Flutter 业务代码、平台代码、脚本和 CI 的边界在哪里。
- 后续怎样在本地构建，怎样通过 GitHub Actions 云端构建和发布。

本文只描述工程结构和构建流程，不记录任何密码、Token、证书口令或服务器口令。

## 仓库总览

InkRoot 是 Flutter 跨平台应用。核心业务代码在 `lib/`，各平台外壳在 `android/`、`ios/`、`macos/`、`windows/`、`linux/`、`web/`，自动化入口集中在 `tool/inkroot.dart` 和 `.github/workflows/`。

常用维护入口：

- `pubspec.yaml`：应用版本、依赖、资源入口。版本号以这里为准。
- `lib/main.dart`：Flutter 应用启动入口。
- `lib/config/`：应用级配置、品牌、资源路径、服务器和公开 URL。
- `lib/providers/app_provider.dart`：核心状态管理入口。
- `lib/routes/app_router.dart`：页面路由入口。
- `tool/inkroot.dart`：项目 CLI，负责检查、测试、构建和打 tag 发布。
- `.github/workflows/ci.yml`：主分支和 PR 的持续集成。
- `.github/workflows/release.yml`：正式 tag 的云端发布构建。

## 顶层文件说明

- `.gitignore`：排除本地生成物、构建产物、签名文件、密钥和临时目录。
- `.gitleaks.toml`：密钥扫描配置，CI 会用它阻止 Token、密码、私钥进入仓库。
- `.metadata`：Flutter 项目元数据，通常不手动修改。
- `README.md`：中文项目首页，面向用户和维护者的简要说明。
- `README.en.md`：英文项目首页。
- `CHANGELOG.md`：中文更新日志，发布时用于生成 Release Notes。
- `CHANGELOG.en.md`：英文更新日志。
- `CODE_OF_CONDUCT.md`：社区行为准则。
- `CONTRIBUTING.md`：贡献指南。
- `LICENSE`：开源许可证。
- `SECURITY.md`：安全政策和漏洞反馈方式。
- `analysis_options.yaml`：当前 Dart/Flutter 静态分析规则。
- `analysis_options_strict.yaml`：更严格的分析规则备用文件。
- `flutter_native_splash.yaml`：Flutter 启动屏生成配置。
- `l10n.yaml`：Flutter 国际化生成配置。
- `pubspec.yaml`：项目名称、描述、版本、依赖、资源和 Flutter 配置。
- `pubspec.lock`：依赖锁定文件，用于保证本地和 CI 依赖版本一致。

## 顶层目录说明

- `.github/`：GitHub 相关配置，包括 Issue 模板、PR 模板、Dependabot 和 Actions。
- `android/`：Android 原生工程，包含 Gradle 配置、包名、权限、图标、启动页、通知图标、Kotlin 原生代码和签名读取逻辑。
- `ios/`：iOS 原生工程，包含 Xcode 工程、Info.plist、权限说明、隐私清单、启动页、图标、CocoaPods 配置和本地 Pod。
- `macos/`：macOS 原生工程，包含 Xcode 工程、菜单、图标、权限和窗口入口。
- `windows/`：Windows 原生工程，包含 CMake、Win32 Runner、资源文件和应用图标。
- `linux/`：Linux 原生工程，包含 CMake、GTK Runner 和 Flutter 插件注册。
- `web/`：Flutter Web 外壳文件。当前 App 发布流程不构建 Web。
- `assets/`：应用资源，当前主要放图片和字体文件。
- `docs/`：项目文档、维护说明、商店合规说明、用户指南、API 说明和官网静态协议页。
- `lib/`：Flutter/Dart 业务代码。
- `scripts/`：辅助脚本，例如 iOS unsigned IPA、DMG、Windows 包和 release notes。
- `test/`：单元测试和 widget 测试。
- `tool/`：项目级 Dart CLI。
- `release/`：历史发布产物目录。正式新版本以 GitHub Releases 为准。
- `key/`：本地签名材料目录，必须只保存在本机，不提交到 Git。
- `build/`、`.dart_tool/`、`coverage/`：构建、依赖和测试覆盖率生成物。

## lib 代码架构

`lib/` 是应用主体，建议按下面的职责边界维护。

- `lib/main.dart`
  - 应用启动入口。
  - 初始化 Flutter、Provider、主题、路由和基础服务。

- `lib/config/`
  - `app_config.dart`：全局配置、服务地址、公开 URL、云端校验 AppID/AppKey 默认值等。
  - `app_identity.dart`：应用名称、品牌标识等身份信息。
  - `asset_config.dart`：图片、Logo 等资源路径统一入口。

- `lib/l10n/`
  - `app_zh.arb`、`app_en.arb`：中文和英文文案源文件。
  - `app_localizations*.dart`：Flutter 国际化生成或兼容文件。
  - `translations.dart`：部分旧文案兼容入口。
  - 新增用户可见文案时，优先放进 ARB，不要散落在业务页面里。

- `lib/models/`
  - 纯数据模型和枚举。
  - 例如笔记、用户、公告、提醒、WebDAV 配置、侧边栏配置、标签颜色、排序状态、云校验响应等。
  - 这一层不应该直接写 UI。

- `lib/providers/`
  - Provider 状态管理。
  - `app_provider.dart` 管理应用主状态、笔记列表、同步、筛选、刷新、配置加载等。
  - `app_provider_sync.part.dart` 是同步相关逻辑的 part 文件，用于拆分主 Provider 体积。

- `lib/routes/`
  - `app_router.dart` 定义页面路由、错误页和特殊入口。
  - 新页面应该在这里注册路由，并确认返回路径是否符合实际使用场景。

- `lib/screens/`
  - 页面级 UI，每个文件通常对应一个完整页面。
  - 核心页面包括首页、详情页、标签页、设置页、登录注册、帮助、关于、WebDAV、AI 设置、导入导出、随机回顾、知识图谱、通知、账号删除等。
  - 页面内只保留页面组织逻辑，复杂业务尽量下沉到 `services/`、`utils/` 或 `widgets/`。

- `lib/services/`
  - 业务服务层。
  - 包括 API、数据库、Memos 同步、WebDAV、AI、相关笔记、标签统计、语音、权限、通知、监控、性能、导入解析等。
  - 涉及网络、数据库、文件、平台能力、第三方服务的代码优先放这里。

- `lib/themes/`
  - 应用主题、字体排版和文字样式入口。
  - 修改全局字号、颜色、组件样式时先看这里，避免页面里重复硬编码。

- `lib/utils/`
  - 无状态工具函数和辅助类。
  - 包括 Markdown/Memos 内容转换、标签解析、待办解析、时间处理、图片工具、响应式工具、日志、错误处理、分享图片等。

- `lib/widgets/`
  - 可复用 UI 组件。
  - 包括笔记卡片、编辑器、Markdown 渲染器、图片查看器、侧边栏、标签树、热力图、相关笔记面板、权限弹窗、更新弹窗等。
  - 多个页面共享的 UI 不要复制到 `screens/`。

## 关键业务文件

- `lib/widgets/note_editor.dart`：笔记编辑器，负责输入、工具栏、链接、富文本式 Markdown 操作等。
- `lib/widgets/memo_editing_controller.dart`：编辑器文本控制逻辑。
- `lib/widgets/memos_markdown_renderer.dart`：主页和详情页 Markdown 渲染核心。
- `lib/widgets/simple_memo_content.dart`：简化笔记内容展示。
- `lib/widgets/note_card.dart`：首页笔记卡片、展开收起、图片和交互入口。
- `lib/widgets/image_viewer_screen.dart`：图片预览、多图浏览和退出交互。
- `lib/widgets/sidebar.dart`：侧边栏、标签入口和导航。
- `lib/widgets/tag_tree_item.dart`：层级标签树 UI。
- `lib/screens/home_screen.dart`：首页整体页面。
- `lib/screens/note_detail_screen.dart`：笔记详情页。
- `lib/screens/tag_notes_screen.dart`：标签下笔记列表。
- `lib/screens/settings_screen.dart`：设置页入口。
- `lib/screens/about_screen.dart`：关于页。
- `lib/screens/help_screen.dart`：帮助页。
- `lib/screens/ai_settings_screen.dart`：AI 配置页。
- `lib/screens/webdav_settings_screen.dart`：WebDAV 设置和测试入口。
- `lib/services/database_service.dart`：本地数据库和迁移。
- `lib/services/api_service.dart`：服务端 API 抽象。
- `lib/services/api_service_factory.dart`：本地模式、官方服务器、自托管服务器之间的服务创建。
- `lib/services/memos_api_service_fixed.dart`：Memos API 对接。
- `lib/services/memos_resource_service.dart`：Memos 图片和资源处理。
- `lib/services/incremental_sync_service.dart`：增量同步。
- `lib/services/sync_merge_helper.dart`：同步合并策略，涉及创建时间、更新时间和冲突处理。
- `lib/services/webdav_service.dart`：WebDAV 基础访问。
- `lib/services/webdav_sync_engine.dart`：WebDAV 备份和恢复流程。
- `lib/services/ai_review_service.dart`：AI 点评。
- `lib/services/ai_insight_engine.dart`：AI 洞察。
- `lib/services/ai_enhanced_service.dart`：摘要、续写、标签推荐等增强能力。
- `lib/services/intelligent_related_notes_service.dart`：相关笔记计算。
- `lib/services/local_note_analysis_service.dart`：本地笔记分析。
- `lib/services/tag_ai_service.dart`：标签推荐和标签洞察。
- `lib/services/umeng_analytics_service.dart`：友盟统计，目前主要用于 Android。
- `lib/services/sentry_monitoring_service.dart`：Sentry 监控。

## lib 文件速查表

这一节按源码目录列出主要 Dart 文件的职责，后续定位问题时可以先按这里找入口。

### lib/config

- `app_config.dart`：应用全局配置中心，包括服务器、公开链接、功能开关默认值、告警阈值、云端校验默认配置和构建环境读取。
- `app_identity.dart`：应用身份信息，例如产品名、品牌标识和对外展示名称。
- `asset_config.dart`：统一管理应用内图片、Logo 等资源路径。

### lib/l10n

- `app_zh.arb`：中文文案源。
- `app_en.arb`：英文文案源。
- `app_localizations.dart`：Flutter 国际化主入口。
- `app_localizations_zh.dart`：中文本地化实现。
- `app_localizations_en.dart`：英文本地化实现。
- `app_localizations_simple.dart`：项目内轻量本地化兼容入口。
- `translations.dart`：历史翻译映射和兼容工具。

### lib/models

- `annotation_model.dart`：批注、回复、批注类型等数据结构。
- `announcement_model.dart`：登录页或应用公告的数据结构。
- `app_config_model.dart`：应用配置数据结构。
- `cloud_verification_models.dart`：官方云校验请求和响应模型。
- `load_more_state.dart`：分页加载状态模型。
- `note_model.dart`：笔记核心模型，包含内容、标签、资源、时间、引用、批注等字段。
- `notion_field_mapping.dart`：Notion 同步时的字段映射模型。
- `reminder_notification_model.dart`：提醒通知数据模型。
- `sidebar_config.dart`：侧边栏菜单、排序、隐藏项和展示配置。
- `sort_order.dart`：排序枚举和排序状态。
- `tag_color_model.dart`：标签颜色配置模型。
- `user_model.dart`：用户账号、登录态和用户信息模型。
- `webdav_config.dart`：WebDAV 地址、账号、路径、图片备份选项等配置模型。

### lib/providers

- `app_provider.dart`：应用主状态管理，承接笔记、用户、同步、搜索、标签、设置和 UI 状态。
- `app_provider_sync.part.dart`：`app_provider.dart` 的同步逻辑拆分文件。

### lib/routes

- `app_router.dart`：全局路由表，负责页面路径、跳转、错误页和特殊入口。

### lib/screens

- `about_screen.dart`：关于页，展示品牌、版本、介绍和相关链接。
- `account_deletion_screen.dart`：账号与数据删除入口和说明。
- `account_info_screen.dart`：账号信息查看和编辑。
- `ai_settings_screen.dart`：AI 服务配置、自定义提示词和模型输入。
- `data_cleanup_screen.dart`：本地数据清理页面。
- `feedback_screen.dart`：问题反馈页面。
- `flomo_import_screen.dart`：Flomo 数据导入页面。
- `forgot_password_screen.dart`：忘记密码流程。
- `help_screen.dart`：帮助中心页面。
- `home_screen.dart`：首页笔记流、搜索、发布入口、侧边栏和主交互。
- `import_export_main_screen.dart`：导入导出功能聚合入口。
- `knowledge_graph_screen_custom.dart`：知识图谱页面。
- `laboratory_screen.dart`：实验室页面，目前作为开发中占位。
- `legal_document_screen.dart`：法律文档聚合页。
- `local_backup_restore_screen.dart`：本地备份和恢复页面。
- `login_screen.dart`：登录、官方服务器和自部署服务器连接入口。
- `note_detail_screen.dart`：笔记详情、编辑、图片、AI、相关笔记和更多操作入口。
- `notifications_screen.dart`：通知和提醒列表。
- `notion_settings_screen.dart`：Notion 同步配置页。
- `onboarding_screen.dart`：首次使用引导。
- `performance_dashboard_screen.dart`：性能指标和日志调试页面。
- `preferences_screen.dart`：偏好设置页面。
- `privacy_policy_screen.dart`：隐私政策展示页。
- `random_review_screen.dart`：随机回顾页面。
- `register_screen.dart`：注册页面。
- `server_info_screen.dart`：服务器信息和连接管理。
- `settings_screen.dart`：设置首页。
- `sidebar_customization_screen.dart`：侧边栏自定义排序、隐藏和展示配置。
- `tag_notes_screen.dart`：某个标签下的笔记列表。
- `tags_screen.dart`：全部标签列表和标签管理。
- `user_agreement_screen.dart`：用户协议展示页。
- `user_preferences_screen.dart`：用户行为偏好和学习数据查看。
- `webdav_settings_screen.dart`：WebDAV 配置、测试、备份和恢复入口。
- `weread_import_screen.dart`：微信读书数据导入页面。

### lib/services

- `ai_enhanced_service.dart`：AI 摘要、续写、标签推荐等增强能力。
- `ai_insight_engine.dart`：洞察生成逻辑。
- `ai_related_notes_service.dart`：AI 相关笔记能力。
- `ai_review_service.dart`：AI 点评能力。
- `alert_service.dart`：告警规则和关键指标告警。
- `announcement_service.dart`：公告拉取、缓存和展示判断。
- `api_service.dart`：应用服务端 API 抽象。
- `api_service_factory.dart`：根据本地模式、官方服务器、自部署服务器创建 API 服务。
- `app_info_service.dart`：应用版本、包信息和平台信息。
- `baidu_realtime_speech_service.dart`：百度实时语音识别。
- `baidu_speech_service.dart`：百度语音识别封装。
- `cloud_verification_service.dart`：官方服务器校验、AppID/AppKey 验证和登录前置检查。
- `database_service.dart`：SQLite 本地数据库、表结构、迁移、读写和缓存。
- `deepseek_api_service.dart`：DeepSeek/OpenAI 兼容 AI API 调用。
- `feature_flag_service.dart`：功能开关、本地缓存和远程配置读取。
- `graph_data_service.dart`：知识图谱数据生成。
- `graph_isolate_service.dart`：知识图谱或重计算任务的 isolate 处理。
- `incremental_sync_service.dart`：增量同步流程。
- `intelligent_related_notes_service.dart`：本地相关笔记算法。
- `ios_permission_service.dart`：iOS 权限处理。
- `ios_update_service.dart`：iOS 更新策略，避免 iOS 使用应用内下载安装包更新。
- `local_note_analysis_service.dart`：本地笔记内容分析。
- `local_reference_service.dart`：本地引用关系处理。
- `logger_service.dart`：结构化日志服务。
- `memos_api_service_fixed.dart`：Memos API 对接实现。
- `memos_resource_service.dart`：Memos 图片资源上传、下载和解析。
- `note_actions_service.dart`：笔记常用操作聚合。
- `note_sorting_helper.dart`：笔记排序辅助。
- `note_tags_helper.dart`：笔记标签提取和处理。
- `notes_pagination_helper.dart`：笔记分页加载辅助。
- `notification_service.dart`：本地通知基础服务。
- `notion_api_service.dart`：Notion API 调用。
- `notion_sync_service.dart`：Notion 同步流程。
- `observability_service.dart`：日志、追踪和可观测性能力。
- `performance_monitor_service.dart`：性能计时、指标采集和报告。
- `permission_manager.dart`：跨平台权限管理。
- `preferences_service.dart`：SharedPreferences 配置读写。
- `reminder_notification_service.dart`：提醒通知调度。
- `sentry_monitoring_service.dart`：Sentry 错误上报。
- `simple_permission_service.dart`：简化权限请求封装。
- `speech_service.dart`：语音输入统一入口。
- `sync_merge_helper.dart`：同步合并、去重、时间字段保护和冲突处理。
- `sync_status_helper.dart`：同步状态展示辅助。
- `tag_ai_service.dart`：标签推荐和标签洞察。
- `tag_stats_service.dart`：标签统计。
- `umeng_analytics_service.dart`：友盟统计封装。
- `unified_reference_manager.dart`：双向引用关系管理。
- `user_behavior_service.dart`：用户点击、偏好学习和个性化权重。
- `webdav_service.dart`：WebDAV 基础请求、目录、上传下载。
- `webdav_sync_engine.dart`：WebDAV 备份、恢复、图片附件处理。
- `weread_parser.dart`：微信读书导入解析。

### lib/themes

- `app_theme.dart`：应用颜色、组件基础主题和明暗模式样式。
- `app_typography.dart`：应用排版体系。
- `typography.dart`：文字样式兼容或补充定义。

### lib/utils

- `error_handler.dart`：统一错误处理辅助。
- `image_cache_manager.dart`：图片缓存管理。
- `image_utils.dart`：图片压缩、保存、格式和路径处理。
- `logger.dart`：轻量日志工具。
- `memos_content_helper.dart`：Memos 内容格式处理。
- `memos_markdown_converter.dart`：Memos Markdown 和应用渲染格式转换。
- `network_utils.dart`：网络状态和请求辅助。
- `performance_tracker.dart`：性能追踪辅助。
- `responsive_utils.dart`：响应式布局工具。
- `share_image_widget.dart`：分享图片渲染组件辅助。
- `share_utils.dart`：分享图片和系统分享能力。
- `snackbar_utils.dart`：统一 Toast/SnackBar 展示。
- `tag_path_utils.dart`：层级标签路径处理。
- `tag_utils.dart`：标签解析、格式化和清洗。
- `text_analysis_utils.dart`：文本分析辅助。
- `text_style_helper.dart`：动态字体和文字样式辅助。
- `time_utils.dart`：时间格式化、创建时间和更新时间处理。
- `todo_parser.dart`：Markdown 待办项解析和切换。

### lib/widgets

- `animated_checkbox.dart`：自定义动画复选框。
- `annotations_sidebar.dart`：批注侧边栏。
- `cached_avatar.dart`：头像缓存显示组件。
- `desktop_layout.dart`：桌面端布局容器。
- `heatmap.dart`：笔记热力图。
- `image_viewer_screen.dart`：图片预览和多图浏览。
- `intelligent_related_notes_sheet.dart`：智能相关笔记面板。
- `interactive_markdown.dart`：可交互 Markdown，支持待办点击。
- `ios_datetime_picker.dart`：iOS 风格日期时间选择器。
- `memo_editing_controller.dart`：编辑器控制器。
- `memos_markdown_renderer.dart`：Memos Markdown 渲染器。
- `note_card.dart`：首页笔记卡片。
- `note_editor.dart`：笔记编辑器。
- `note_more_options_menu.dart`：笔记更多操作菜单。
- `permission_dialog.dart`：权限请求弹窗。
- `permission_guide_dialog.dart`：权限引导弹窗。
- `privacy_policy_dialog.dart`：首次启动隐私协议弹窗。
- `progress_overlay.dart`：全局进度遮罩。
- `references_sidebar.dart`：引用关系侧边栏。
- `related_notes_bottom_sheet.dart`：相关笔记底部弹层。
- `saveable_image.dart`：可保存图片组件。
- `share_image_preview_screen.dart`：分享图片预览页。
- `sidebar.dart`：应用侧边栏。
- `simple_memo_content.dart`：简化笔记内容展示。
- `tag_color_picker.dart`：标签颜色选择器。
- `tag_tree_item.dart`：层级标签树节点。
- `update_dialog.dart`：更新提示弹窗。

## docs 目录

- `docs/README.md`：文档索引。
- `docs/MAINTENANCE.md`：版本、检查、构建和发布维护流程。
- `docs/STORE_COMPLIANCE.md`：App Store 和 Google Play 提交前检查。
- `docs/PROJECT_STRUCTURE_AND_BUILD.md`：当前这份结构和构建指南。
- `docs/api/README.md`：API 说明英文入口。
- `docs/api/README.zh.md`：API 说明中文入口。
- `docs/architecture/README.md`：架构概览。
- `docs/architecture/adr/`：架构决策记录。
- `docs/development/debugging.md`：调试说明。
- `docs/development/troubleshooting.md`：常见问题排查。
- `docs/user-guide/`：用户使用指南。
- `docs/site/privacy.html`：官网隐私政策静态页。
- `docs/site/agreement.html`：官网用户协议静态页。
- `docs/site/account-deletion.html`：官网账号与数据删除说明页。

官网协议页更新后，需要同步部署到 `inkroot.cn`，同时确认应用内法律文档和公开网页内容一致。

## 平台目录

### Android

主要文件：

- `android/app/build.gradle`：Android 应用配置。包名为 `com.didichou.inkroot`，版本来自 `pubspec.yaml`，Release 构建强制要求签名配置。
- `android/app/src/main/AndroidManifest.xml`：权限、Activity、Provider、应用入口配置。
- `android/app/src/debug/AndroidManifest.xml`：Debug 专用配置。
- `android/app/src/profile/AndroidManifest.xml`：Profile 专用配置。
- `android/app/src/main/kotlin/com/didichou/inkroot/MainActivity.kt`：Android 主 Activity。
- `android/app/src/main/kotlin/com/didichou/inkroot/AlarmReceiver.kt`：提醒通知相关广播接收。
- `android/app/src/main/kotlin/com/didichou/inkroot/ReleaseLog.kt`：原生日志辅助。
- `android/app/src/main/res/`：Android 图标、启动页、通知图标、主题和文件共享路径。
- `android/gradle.properties`、`android/settings.gradle`、`android/build.gradle`：Gradle 工程配置。
- `android/inkroot-new-cert.der`：用于校验正式签名证书的公开证书材料，不是私钥。

不要提交：

- `android/key.properties`
- `android/inkroot-new-release.keystore`
- 任何 `.keystore`、`.jks`、`.p12`、`.pem` 私密文件

### iOS

主要文件：

- `ios/Podfile`：CocoaPods 配置。iOS 最低版本为 13.0，使用官方 CocoaPods 源，并保留本地 `SDWebImageWebPCoder`。
- `ios/Podfile.lock`：Pod 版本锁定。
- `ios/ExportOptions.plist`：导出 IPA 的配置。
- `ios/Runner/Info.plist`：Bundle、权限文案、版本元数据等。
- `ios/Runner/PrivacyInfo.xcprivacy`：Apple 隐私清单。
- `ios/Runner/Runner.entitlements`：iOS 权限能力。
- `ios/Runner/AppDelegate.swift`：iOS 应用启动入口。
- `ios/Runner/SceneDelegate.swift`：iOS Scene 生命周期入口。
- `ios/Runner/Assets.xcassets/`：App 图标、启动图和背景。
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`：启动屏。
- `ios/local_pods/SDWebImageWebPCoder-0.15.0/`：本地 Pod，用于稳定构建 WebP 图片支持。

当前 GitHub Release 构建的是 unsigned IPA，用于测试分发和构建验证。App Store 上架仍需要在 Apple Developer 账号下用正式证书、Bundle ID、Provisioning Profile 归档上传。

### macOS

主要文件：

- `macos/Podfile`、`macos/Podfile.lock`：macOS CocoaPods 配置和锁定。
- `macos/Runner/Info.plist`：macOS 应用元数据。
- `macos/Runner/MainFlutterWindow.swift`：macOS Flutter 窗口入口。
- `macos/Runner/AppDelegate.swift`：macOS 应用生命周期。
- `macos/Runner/Release.entitlements`、`macos/Runner/DebugProfile.entitlements`：macOS 权限能力。
- `macos/Runner/Assets.xcassets/`：macOS 图标。
- `macos/Runner/Base.lproj/MainMenu.xib`：macOS 菜单和主窗口资源。

GitHub Release 当前产出 macOS zip 包。若要面向公网分发安装包，后续还需要 Apple Developer ID 签名和 notarization。

### Windows

主要文件：

- `windows/CMakeLists.txt`：Windows 顶层 CMake 配置。
- `windows/runner/`：Win32 Runner 源码。
- `windows/runner/Runner.rc`：Windows 资源配置，包含图标和版本资源。
- `windows/runner/resources/app_icon.ico`：Windows 应用图标。
- `windows/flutter/`：Flutter 生成的插件注册和构建桥接文件。

Windows 构建必须在 Windows 环境，并安装 Visual Studio C++ 桌面组件。

### Linux

主要文件：

- `linux/CMakeLists.txt`：Linux 顶层 CMake 配置。
- `linux/runner/`：GTK Runner 源码。
- `linux/flutter/`：Flutter 插件注册和构建桥接文件。

Linux 构建需要 GTK、CMake、Ninja、pkg-config、libsecret、curl、c-ares 等系统依赖。

### Web

主要文件：

- `web/index.html`：Flutter Web HTML 外壳。
- `web/manifest.json`：Web App manifest。
- `web/icons/`、`web/favicon.png`：Web 图标。

当前 App 发布流程明确不构建 Web。如果以后要恢复 Web，需要单独评估存储、权限、文件、图片和同步能力在浏览器里的限制。

## assets 目录

- `assets/images/logo.png`：主 Logo。
- `assets/images/black2logo.png`：黑色或深色场景 Logo。
- `assets/fonts/`：字体文件。当前 `pubspec.yaml` 没有启用这些字体作为 Flutter font family，应用主要使用系统字体和 Google Fonts 能力。

新增资源后需要同时检查：

- 是否已在 `pubspec.yaml` 的 `flutter.assets` 或字体配置中声明。
- 是否有版权或商用授权问题。
- 是否影响包体积。

## scripts 和 tool

优先使用 `tool/inkroot.dart`，它是统一维护入口。

`tool/inkroot.dart` 支持：

- `doctor`：运行 `flutter doctor -v`。
- `deps`：运行 `flutter pub get`。
- `analyze`：运行 `flutter analyze`。
- `test`：运行 `flutter test`。
- `test --coverage`：运行测试并生成覆盖率。
- `verify`：依次执行依赖安装、分析和测试。
- `verify --coverage`：执行完整检查并生成覆盖率。
- `store-check`：检查版本、包名、签名约束、权限、隐私清单、公开 URL、云校验配置和 Release 工作流关键项。
- `build android-debug`：构建 Android Debug APK。
- `build android-release`：构建 Android Release APK，需要本地签名文件。
- `build android-aab`：构建 Android Release AAB，需要本地签名文件。
- `build ios-sim`：构建 iOS 模拟器包，需要 macOS、Xcode、CocoaPods。
- `build ios-unsigned-ipa`：构建 iOS unsigned IPA，需要 macOS、Xcode、CocoaPods。
- `build macos-debug`、`build macos-release`：构建 macOS 应用。
- `build windows-debug`、`build windows-release`：构建 Windows 应用。
- `build linux-debug`、`build linux-release`：构建 Linux 应用。
- `run ios-sim`：运行 iOS 模拟器。
- `run macos`：运行 macOS。
- `run <deviceId>`：运行到指定 Flutter 设备。
- `release vX.Y.Z`：校验版本和工作区干净后创建并推送 tag，触发云端 Release。
- `clean`：运行 `flutter clean`。

辅助脚本：

- `scripts/ci.sh`：旧 CI 入口，保留兼容。
- `scripts/build_unsigned_ipa.sh`：构建 iOS unsigned IPA，并处理 CocoaPods 安装重试。
- `scripts/clean_apple_xattrs.sh`：清理 Apple 扩展属性，减少签名和构建异常。
- `scripts/release_notes.py`：从更新日志提取指定版本 Release Notes。
- `scripts/create_dmg.sh`、`scripts/create_release_dmg.sh`、`scripts/dmg/`：macOS DMG 打包辅助。
- `scripts/generate_desktop_icons.py`、`scripts/generate_icns.sh`：桌面图标生成辅助。
- `scripts/windows/build_windows.bat`：Windows 构建辅助。
- `scripts/IOS_UNSIGNED_BUILD.md`、`scripts/windows/README.md`、`scripts/dmg/README.md`：脚本文档。

## test 目录

- `test/unit/`：单元测试，覆盖模型、数据库、Memos API、同步、标签、AI、本地分析、WebDAV、待办解析等。
- `test/widget_tests/`：组件测试，覆盖编辑器、Markdown 渲染、笔记卡片展开、表单校验、UI 组件等。
- `test/widget_test.dart`：Flutter 默认入口改造后的基础 widget 测试。
- `test/widget_test.dart.bak`：历史备份文件，后续清理测试结构时可评估是否删除。

常用测试命令：

```bash
dart tool/inkroot.dart test
dart tool/inkroot.dart test --coverage
dart tool/inkroot.dart verify
dart tool/inkroot.dart verify --coverage
```

## 本地开发准备

基础要求：

- Flutter stable。
- Dart SDK 随 Flutter 安装。
- Git。
- Android Studio 或 Android SDK，用于 Android。
- macOS + Xcode + CocoaPods，用于 iOS 和 macOS。
- Windows + Visual Studio C++ 桌面组件，用于 Windows。
- Linux GTK/CMake/Ninja 依赖，用于 Linux。

首次拉取后：

```bash
git clone https://github.com/yyyyymmmmm/InkRoot.git
cd InkRoot
dart tool/inkroot.dart doctor
dart tool/inkroot.dart deps
dart tool/inkroot.dart verify
```

如果只想快速运行到当前连接设备：

```bash
dart tool/inkroot.dart run
```

如果要运行 iOS 模拟器：

```bash
dart tool/inkroot.dart run ios-sim
```

如果要运行 macOS：

```bash
dart tool/inkroot.dart run macos
```

## 本地构建

Android Debug：

```bash
dart tool/inkroot.dart build android-debug
```

Android Release APK：

```bash
dart tool/inkroot.dart build android-release
```

Android Release AAB：

```bash
dart tool/inkroot.dart build android-aab
```

iOS 模拟器：

```bash
dart tool/inkroot.dart build ios-sim
```

iOS unsigned IPA：

```bash
dart tool/inkroot.dart build ios-unsigned-ipa
```

macOS：

```bash
dart tool/inkroot.dart build macos-release
```

Windows：

```bash
dart tool/inkroot.dart build windows-release
```

Linux：

```bash
dart tool/inkroot.dart build linux-release
```

当前机器无法构建所有平台。iOS 和 macOS 只能在 macOS 构建，Windows 只能在 Windows 构建，Linux 只能在 Linux 构建。云端构建通过不同 GitHub Runner 分别完成。

## Android 本地签名

Release APK/AAB 需要本地签名文件。工程会读取：

- `android/key.properties`
- `android/inkroot-new-release.keystore`

`android/key.properties` 需要包含：

```properties
storeFile=../inkroot-new-release.keystore
storePassword=你的本地密码
keyAlias=你的 alias
keyPassword=你的本地密码
```

这些文件必须留在本机，不要提交。`.gitignore` 已经排除它们。构建时如果缺少签名配置，`android/app/build.gradle` 会主动失败，避免产出无法覆盖安装或签名错误的正式包。

正式签名必须保持一致，否则用户无法覆盖安装旧版本。每次发版前至少检查：

```bash
dart tool/inkroot.dart store-check
dart tool/inkroot.dart build android-release
dart tool/inkroot.dart build android-aab
```

## iOS 和 macOS 签名

当前 CLI 和 GitHub Release 流程：

- iOS 云端产出 unsigned IPA，用于构建验证和测试分发，不等同于 App Store 可直接上架包。
- macOS 云端产出 zip 包，不包含 Developer ID 公证流程。

App Store 正式上架仍需要：

- Apple Developer Program 账号。
- Bundle ID：`com.didichou.inkroot`。
- App Store Connect 应用记录。
- Distribution Certificate。
- App Store Provisioning Profile。
- Xcode Archive。
- App Store Connect 上传和审核信息。

后续如需完全自动化 iOS/macOS 签名发布，可以在 GitHub Actions 增加 Apple 证书、Provisioning Profile、App Store Connect API Key 和 notarization 流程。不要把 Apple 私钥或证书明文放入仓库。

## 版本号规则

版本号统一在 `pubspec.yaml`：

```yaml
version: 1.1.10+10110
```

含义：

- `1.1.10`：用户看到的版本名。
- `10110`：构建号，Android versionCode、iOS/macOS build number 等会从这里派生。

发布 tag 必须匹配版本名。比如：

```yaml
version: 1.1.10+10110
```

对应 tag：

```bash
v1.1.10
```

不要在 Android、iOS、macOS、Windows、Linux 平台文件里手动重复改版本号，除非明确知道该平台文件不是 Flutter 版本链路的一部分。

## 云端 CI

`.github/workflows/ci.yml` 会在 PR、主分支 push 和手动触发时运行。

默认检查：

- `dart tool/inkroot.dart store-check`
- `dart tool/inkroot.dart verify --coverage`
- gitleaks 密钥扫描
- Android Debug APK
- iOS Simulator App
- macOS Debug App
- Windows Debug App
- Linux Debug App

手动触发 CI 时如果启用 `release_build`，Android 会恢复签名 secrets 并构建 Release APK/AAB。

当前 CI 不构建 Web。

## 云端正式发布

正式发布由 `.github/workflows/release.yml` 处理。触发方式是推送 `vX.Y.Z` tag。

发布前本地流程：

```bash
dart tool/inkroot.dart store-check
dart tool/inkroot.dart verify
git status --short
git add pubspec.yaml CHANGELOG.md CHANGELOG.en.md docs README.md
git commit -m "chore: prepare vX.Y.Z"
git push origin main
dart tool/inkroot.dart release vX.Y.Z
```

`release` 命令会检查：

- tag 格式正确。
- tag 和 `pubspec.yaml` 的版本名一致。
- 工作区没有未提交改动。
- 本地和远端都没有同名 tag。

tag 推送后，GitHub Actions 会执行：

- 版本和 tag 匹配检查。
- Release Notes 提取。
- Store 检查、Analyze、Test。
- gitleaks 密钥扫描。
- Android 签名 secrets 检查。
- Android Release APK 和 AAB 构建。
- Android 签名证书指纹校验。
- iOS unsigned IPA 构建。
- macOS Release App 打包。
- Windows Release App 打包。
- Linux Release App 打包。
- 创建 GitHub Release 并上传产物。

当前 Release 产物包括：

- `InkRoot-vX.Y.Z-android.apk`
- `InkRoot-vX.Y.Z-android.aab`
- iOS unsigned `.ipa`
- macOS `.zip`
- Windows `.zip`
- Linux `.tar.gz`

当前 Release 不构建 Web。

## GitHub Actions Secrets

Release 工作流至少需要这些 Secrets：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

可选构建参数：

- `UMENG_ANDROID_APPKEY`
- `UMENG_IOS_APPKEY`
- `UMENG_CHANNEL`
- `SENTRY_DSN`

这些值只放在 GitHub Repository Secrets 或本机环境变量里，不写入仓库文档，不写入源码注释，不写入 issue，不写入 commit。

本地临时构建可以用环境变量传入可选参数：

```bash
UMENG_ANDROID_APPKEY=xxx \
UMENG_CHANNEL=official \
SENTRY_DSN=xxx \
dart tool/inkroot.dart build android-release
```

## 不要提交的内容

不要提交：

- Android keystore、JKS、P12、P8、mobileprovision、私钥、证书密码。
- `android/key.properties`。
- `.env`、服务器密码、GitHub Token、云服务 Token。
- 用户导出的笔记、数据库、备份包、WebDAV 备份。
- `build/`、`.dart_tool/`、Pod 生成目录、Gradle 缓存、Xcode DerivedData。
- 手动下载的临时压缩包和安装包。

提交前建议执行：

```bash
git status --short
git diff --check
dart tool/inkroot.dart store-check
dart tool/inkroot.dart verify
```

## 常见维护任务

新增页面：

- 在 `lib/screens/` 新建页面。
- 在 `lib/routes/app_router.dart` 注册路由。
- 页面文案进入 `lib/l10n/*.arb`。
- 共享组件放到 `lib/widgets/`。
- 业务逻辑尽量放到 `lib/services/` 或 `lib/providers/`。

新增接口或同步能力：

- 网络/API 逻辑放到 `lib/services/`。
- 数据结构放到 `lib/models/`。
- 本地存储改动需要更新 `lib/services/database_service.dart` 并补迁移测试。
- 涉及 Memos 内容格式时同步检查 `memos_content_helper.dart`、`memos_markdown_converter.dart` 和渲染器。

新增用户可见文案：

- 修改 `lib/l10n/app_zh.arb` 和 `lib/l10n/app_en.arb`。
- 运行 `dart tool/inkroot.dart deps` 或 Flutter 生成流程。
- 检查长文本、英文、动态字体下是否溢出。

新增图片或图标：

- 放入 `assets/images/` 或对应平台资源目录。
- 更新 `pubspec.yaml` 或平台资源配置。
- 检查浅色、深色、桌面、移动端显示效果。

修改版本并发布：

- 改 `pubspec.yaml`。
- 更新 `CHANGELOG.md` 和 `CHANGELOG.en.md`。
- 跑 `store-check` 和 `verify`。
- 提交并推送 main。
- 执行 `dart tool/inkroot.dart release vX.Y.Z`。
- 等待 GitHub Actions Release 全部成功。

修改签名：

- 谨慎处理。正式签名变化会影响 Android 覆盖安装和商店升级链路。
- 修改前备份旧签名材料。
- 修改后必须验证证书指纹、APK、AAB 和覆盖安装。
- 不要把签名密码写进仓库。

## 出问题时先看哪里

构建依赖失败：

- 运行 `dart tool/inkroot.dart doctor`。
- 运行 `flutter clean` 或 `dart tool/inkroot.dart clean` 后重新 `deps`。
- iOS/macOS 检查 Xcode、CocoaPods、Podfile 和网络访问。

Android Release 失败：

- 检查 `android/key.properties` 是否存在且字段完整。
- 检查 keystore 路径是否正确。
- 检查签名 alias 和密码是否匹配。
- 检查 CI Secrets 是否完整。

iOS 构建失败：

- 先运行 `dart tool/inkroot.dart deps`。
- 检查 `pod install` 是否成功。
- 检查 `ios/Podfile` 是否被误改。
- 检查是否在 OneDrive、iCloud 等文件同步目录导致扩展属性问题，必要时运行 `scripts/clean_apple_xattrs.sh`。

页面文案不对或没有国际化：

- 搜索硬编码中文或英文。
- 把用户可见文案迁移到 ARB。
- 检查帮助页、设置页、关于页、法律页是否和实际功能一致。

笔记渲染、搜索、同步异常：

- Markdown 和 Memos 格式先看 `lib/widgets/memos_markdown_renderer.dart`、`lib/utils/memos_content_helper.dart`、`lib/utils/memos_markdown_converter.dart`。
- 搜索显示先看 `home_screen.dart`、`note_card.dart`、`simple_memo_content.dart`。
- 同步时间和热力图先看 `sync_merge_helper.dart`、`incremental_sync_service.dart`、`database_service.dart`。

## 推荐工作流

日常开发：

```bash
git pull --rebase
dart tool/inkroot.dart deps
dart tool/inkroot.dart verify
dart tool/inkroot.dart run ios-sim
```

提交前：

```bash
dart tool/inkroot.dart store-check
dart tool/inkroot.dart verify
git diff --check
git status --short
```

正式发布：

```bash
dart tool/inkroot.dart store-check
dart tool/inkroot.dart verify
git push origin main
dart tool/inkroot.dart release vX.Y.Z
```

发布后：

- 打开 GitHub Actions Release 工作流，确认所有 job 成功。
- 打开 GitHub Releases，确认所有产物都已上传。
- 下载 Android APK 做覆盖安装测试。
- 下载桌面包做启动测试。
- 如要上架商店，使用对应商店要求的正式签名和提交流程继续处理。
