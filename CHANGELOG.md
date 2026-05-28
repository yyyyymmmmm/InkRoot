# Changelog

All notable changes to InkRoot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.9] - 2025-11-22 ~ 2025-11-24

### ✨ 重大功能更新

#### 🔄 **Notion 数据同步** - 与 Notion 工作区实时同步（2025-11-24 新增）
- **双向同步支持**
  - 仅同步到 Notion - 本地笔记 → Notion
  - 仅从 Notion 同步 - Notion → 本地笔记
  - 双向同步 - 本地笔记 ↔ Notion
  - 灵活选择同步方向，满足不同使用场景

- **自动同步功能**
  - 笔记创建时自动同步至 Notion
  - 笔记编辑时自动同步至 Notion
  - 下拉刷新触发同步
  - 智能防重复同步机制

- **Notion 设置页面**
  - 访问令牌配置和测试
  - 数据库选择和字段映射
  - 同步方向选择
  - 自动同步开关
  - 立即同步按钮

- **技术实现**
  - 新增 `NotionApiService` - Notion API 封装
  - 新增 `NotionSyncService` - Notion 同步逻辑
  - 新增 `notion_settings_screen.dart` - Notion 设置界面
  - `AppProvider` 集成自动同步逻辑

#### 📓 **Obsidian 集成** - 通过第三方插件实现双向同步（2025-11-24 新增）
- **插件兼容性**
  - 完全兼容 [obsidian-memos-sync](https://github.com/RyoJerryYu/obsidian-memos-sync) 插件
  - 支持 Memos API v0.21.0 标准
  - 支持每日笔记自动集成
  - 支持增量同步

- **导入导出页面集成**
  - 新增 Obsidian 数据同步入口
  - 点击跳转到插件下载页面
  - 专业化的功能描述
  - 统一的UI设计风格

#### 📖 **微信读书笔记导入** - 批量导入阅读笔记（2025-11-24 新增）
- **智能解析功能**
  - 自动识别书籍信息（书名、作者）
  - 自动解析笔记数量和章节
  - 智能提取笔记内容
  - 保留原始结构和格式

- **导入设置**
  - 自定义标签（默认：微信读书 + 书名）
  - 章节作为二级标签选项
  - 导入前预览和检查
  - 批量导入进度显示

- **用户体验**
  - 详细的使用说明
  - 粘贴区域友好提示
  - 格式检查和验证
  - 导入结果统计

- **技术实现**
  - 新增 `WeReadParser` - 微信读书笔记解析服务
  - 新增 `weread_import_screen.dart` - 微信读书导入页面
  - 智能文本解析算法
  - 支持多种笔记格式

### 🎨 UI/UX 优化

#### 导入导出页面文案优化（2025-11-24 新增）
- **专业化表达**
  - 本地备份与恢复：将笔记数据导出为本地文件，支持从备份文件恢复数据
  - Flomo 笔记导入：支持从 Flomo 导出的 HTML 文件批量导入笔记内容
  - 微信读书笔记导入：支持从微信读书导出的笔记文本批量导入，自动识别书籍信息和标注内容
  - Notion 数据同步：与 Notion 工作区实时同步笔记数据，支持双向同步与自动同步功能
  - Obsidian 数据同步：通过第三方插件实现与 Obsidian 的双向同步，支持每日笔记自动集成
  - Memos 浏览器扩展：第三方浏览器扩展程序，支持 Chrome/Edge，可快速收集网页内容至 Memos

- **统一术语**
  - "插件" → "扩展"
  - "保存" → "收集"
  - "口语化" → "专业化"

- **数据安全提示**
  - 💡 数据安全提示：建议定期备份笔记数据。导入前请确认文件格式正确，避免数据丢失。

### 🌍 国际化支持

#### 新增翻译
- **Notion 同步**（30+条）
  - 所有 Notion 设置界面文本
  - 同步方向选项和描述
  - 自动同步相关文本
  - 错误提示和成功消息

- **Obsidian 集成**（5+条）
  - Obsidian 同步标题和描述
  - 插件下载引导文本

- **微信读书导入**（20+条）
  - 导入页面所有文本
  - 使用说明和提示
  - 高级选项说明
  - 导入结果消息

- **导入导出页面**（10+条）
  - 所有功能卡片标题和描述
  - 数据安全提示文本

### 🔧 技术改进

#### 新增文件
- `lib/services/notion_api_service.dart` - Notion API 服务
- `lib/services/notion_sync_service.dart` - Notion 同步服务
- `lib/services/weread_parser.dart` - 微信读书解析服务
- `lib/screens/notion_settings_screen.dart` - Notion 设置页面
- `lib/screens/weread_import_screen.dart` - 微信读书导入页面

#### 修改文件
- `lib/providers/app_provider.dart` - 集成 Notion 自动同步
- `lib/screens/home_screen.dart` - 下拉刷新触发 Notion 同步
- `lib/screens/import_export_main_screen.dart` - 新增 Notion/Obsidian/WeRead 入口
- `lib/l10n/app_localizations_simple.dart` - 新增 80+ 条国际化文本

#### 架构优化
- Notion 同步采用异步非阻塞设计
- 防重复同步机制
- 智能错误处理和日志记录
- 模块化服务设计

### 📊 统计数据

- 新增文件：5个
- 修改文件：15+个
- 新增代码：约 3500 行
- 新增国际化：80+条（中英双语）
- 新增功能：3个重大功能（Notion/Obsidian/WeRead）

### 🔗 相关链接

- [Obsidian Memos Sync 插件](https://github.com/RyoJerryYu/obsidian-memos-sync)
- [Notion API 文档](https://developers.notion.com/)
- [Memos v0.21.0](https://github.com/usememos/memos/releases/tag/v0.21.0)

#### 📝 **批注系统** - 专业级笔记批注功能（2025-11-22）
- **批注侧边栏** - 对标主流笔记应用的专业设计
  - 底部滑出式侧边栏，支持拖动调整高度
  - 响应式布局，完美适配手机、平板、桌面端
  - 批注类型筛选（全部/评论/问题/想法/重要/待办）
  - 批注数量统计和实时更新
  - 空状态友好提示

- **多种批注类型** - 满足不同场景需求
  - 💬 评论 (Comment) - 一般性批注
  - ❓ 问题 (Question) - 记录疑问
  - 💡 想法 (Idea) - 灵感记录
  - ⭐ 重要 (Important) - 重点标记
  - ✅ 待办 (To-do) - 任务提醒
  - 每种类型配有专属图标和颜色

- **批注管理功能**
  - 添加批注：支持选择类型和输入内容
  - 编辑批注：修改内容和类型
  - 删除批注：确认对话框防止误删
  - 标记已解决：待办类型可标记完成状态
  - 时间显示：智能相对时间（刚刚/分钟前/小时前/天前）

- **批注入口优化**
  - 主页笔记卡片：右下角显示批注图标和数量
  - 点击批注图标：直接打开批注侧边栏
  - 笔记详情页：更多菜单中的"查看批注"选项
  - 详情页底部：批注区域展示和快速添加

#### 🔗 **引用关系侧边栏** - 全新的引用管理体验（2025-11-22）
- **引用侧边栏设计** - 与批注侧边栏保持一致
  - 底部滑出式设计，可拖动调整
  - 响应式布局适配多种设备
  - 引用类型筛选（全部/引用的笔记/被引用）
  - 引用数量统计

- **引用关系可视化**
  - ↗️ 引用的笔记（正向引用）- 蓝色标识
  - ↙️ 被引用（反向引用）- 绿色标识
  - 引用卡片显示笔记预览和创建时间
  - 点击卡片直接跳转到对应笔记

- **引用入口优化**
  - 主页笔记卡片：显示引用箭头和数量
  - 点击箭头：直接打开引用侧边栏
  - 笔记详情页：更多菜单中的"引用详情"选项

#### 🎨 **AI设置增强** - 自定义AI提示词（2025-11-22）
- **自定义提示词支持**
  - 洞察提示词 (Insight Prompt)
  - 点评提示词 (Review Prompt)
  - 续写提示词 (Continuation Prompt)
  - 标签洞察提示词 (Tag Insight Prompt)
  - 标签推荐提示词 (Tag Recommendation Prompt)

- **提示词管理**
  - 每个提示词都有清晰的说明和作用范围
  - 支持多行输入，方便编写复杂提示词
  - 留空自动使用系统默认提示词
  - 实时保存，即改即用

### 🌍 **完整国际化支持** - 中英文双语无缝切换

#### 批注功能国际化
- 批注侧边栏：标题、筛选、空状态、时间格式
- 批注类型：评论/问题/想法/重要/待办
- 批注对话框：添加、编辑、删除
- 成功提示：批注已添加/已更新/已删除/已标记为已解决

#### 引用功能国际化
- 引用侧边栏：标题、筛选、空状态
- 引用类型：引用的笔记/被引用
- 引用卡片：类型标签、时间显示

#### AI设置国际化
- 自定义提示词：所有标题和说明
- 输入框提示：所有提示文本
- 帮助信息：作用范围说明

#### 笔记详情页国际化
- 批注区域：标题、按钮、空状态提示

### 🎨 UI/UX 改进

- **侧边栏统一设计** - 批注和引用使用一致的设计语言
  - 底部滑出动画流畅自然
  - 支持拖动调整高度（0.5-0.95屏幕高度）
  - 圆角设计更现代
  - 深色模式完美适配

- **响应式布局** - 完美适配多种设备
  - 手机：全屏显示
  - 平板：80%宽度
  - 桌面：固定400px宽度

- **交互优化**
  - 点击批注/引用图标直接打开侧边栏
  - 批注类型选择使用ChoiceChip，更直观
  - 筛选按钮支持图标+文字，更清晰
  - 空状态提示友好，引导用户操作

### 🐛 Bug修复

- 修复批注对话框在主页显示为方框的问题
- 修复AI设置自定义提示词显示为方框的问题
- 修复引用箭头点击无响应的问题
- 修复批注类型文本未使用国际化的问题
- 修复时间格式化方法调用错误
- 修复重复声明导致的编译错误

### 🔧 技术改进

- **代码结构优化**
  - 新增 `AnnotationsSidebar` 组件
  - 新增 `ReferencesSidebar` 组件
  - 优化 `NoteActionsService` 服务
  - 完善 `AppLocalizationsSimple` 国际化

- **性能优化**
  - 批注侧边栏使用Provider监听，实时更新
  - 引用关系计算优化，减少重复查询
  - 国际化文本缓存，提升渲染性能

### 📊 统计数据

- 新增文件：2个（AnnotationsSidebar、ReferencesSidebar）
- 修改文件：10+个
- 新增国际化字符串：50+条
- 代码行数：+2000行
- 支持语言：中文、英文

---

## [1.0.8] - 2025-10-30

### 🌍 Added
- **完整国际化支持** - 中文/English 双语切换
  - 全面国际化：笔记编辑器、笔记卡片、侧边栏
  - 对话框组件：权限、隐私政策、更新提示
  - 功能界面：Flomo导入、标签页、WebDAV设置、偏好设置
  - 账户信息页面：未登录状态引导
  - 登录注册页面：服务器选择、表单验证
  - 字体选择：所有字体名称和描述
  - 侧边栏自定义：菜单项、提示信息
  - 服务层消息：操作反馈、错误提示

- **标签系统增强** - 层级标签和标签管理
  - 支持多层级标签结构（使用 `/` 分隔）
  - 标签树形展示和折叠
  - 标签颜色自定义
  - 标签统计和可视化
  - 相关标签推荐（AI驱动）
  - 标签搜索和过滤

- **Flomo 笔记导入** - 完整的数据迁移方案
  - 支持从 Flomo 导出的 HTML 文件导入
  - 智能解析笔记内容和标签
  - 保留原始创建时间
  - 图片资源自动迁移
  - 智能去重功能
  - 导入进度和结果反馈

### 🐛 Fixed
- **修复图片路径问题** - 升级/重装后图片不显示
  - 改用相对路径存储图片（`images/xxx.jpg`）
  - 避免iOS容器UUID变化导致的路径失效
  - 自动解析相对路径为完整路径
  - 添加详细的错误提示
- 修复部分界面布局问题
- 修复标签解析异常
- 修复同步冲突处理

### 🔧 Changed
- **优化项目结构** - 符合GitHub开源规范
  - 删除编译产物 `build/` (~300-500MB)
  - 删除第三方依赖 `ios/Pods/` (~30-50MB)
  - 删除备份文件 `*.bak*`
  - 删除系统文件 `.DS_Store`
  - 删除自动生成文件
  - 项目体积减少约 400-600MB

- **优化 AI 功能逻辑**
  - 改进 AI 接口调用效率
  - 优化错误处理和重试机制
  - 降低 Token 消耗
  - 增强上下文理解

- **优化 WebDAV 同步逻辑**
  - 改进同步性能和稳定性
  - 优化冲突检测算法
  - 支持增量同步
  - 更友好的错误提示

### 🎨 Improved
- 所有UI文本支持英文显示，更适合国际用户
- 图片加载错误提示更友好
- 代码注释优化，添加大厂标准说明
- 标签管理界面更直观
- 导入流程更清晰

---

## [1.0.7] - 2025-10-25

### 🎉 Added
- **待办事项功能** - 完整的 Markdown 任务列表支持
  - 支持 `- [ ]` / `- [x]` 语法
  - 点击复选框直接切换完成状态
  - 精美的动画效果（AnimatedCheckbox 组件）
  - 触觉反馈（iOS/Android 原生振动）
  - 自动保存到笔记内容，实时同步
  - 交互式 Markdown 渲染（InteractiveMarkdown）
  - 待办事项解析器（TodoParser）

- **图片保存功能** - 笔记图片一键保存
  - 图片长按弹出"保存图片"选项
  - 智能权限请求和引导
  - 自动保存到系统相册
  - 保存成功提示和相册定位
  - 支持所有图片格式（JPG、PNG、GIF、WebP 等）
  - SaveableImage 组件封装

- **笔记置顶功能** - 重要笔记置顶显示
  - 支持客户端置顶
  - 支持服务器同步（使用 memo_organizer API）
  - 刷新后状态不丢失

- **新增核心组件**
  - `animated_checkbox.dart` - 动画复选框组件
  - `saveable_image.dart` - 可保存图片组件
  - `interactive_markdown.dart` - 交互式 Markdown 渲染
  - `note_more_options_menu.dart` - 笔记更多选项菜单
  - `intelligent_related_notes_sheet.dart` - 智能相关笔记底部表单
  - `todo_parser.dart` - 待办事项解析工具
  - `tag_utils.dart` - 标签处理工具

- **新增服务**
  - `ai_insight_engine.dart` - AI 洞察引擎
  - `intelligent_related_notes_service.dart` - 智能相关笔记服务
  - `ios_update_service.dart` - iOS 更新服务
  - `note_actions_service.dart` - 笔记操作服务
  - `user_behavior_service.dart` - 用户行为服务

### 🎨 Improved
- **AI 功能优化** - 更智能的写作助手
  - 优化 DeepSeek API 调用流程，响应速度提升
  - 改进 Prompt 和参数配置，内容生成质量更高
  - 增强相关笔记推荐准确度
  - 优化 AI 设置界面交互体验

- **更多菜单优化** - 更便捷的操作
  - 重新设计"更多"菜单样式（NoteMoreOptionsMenu）
  - 新增置顶/取消置顶功能
  - 优化分享功能和选项
  - 改进导出功能的清晰度
  - 优化菜单布局、图标和文字

### 🐛 Fixed
- **修复刷新后置顶状态丢失** - 改进数据合并逻辑
  - 优化 `fetchNotesFromServer` 方法
  - 合并时保留本地的 `isPinned` 状态（客户端优先策略）
  - 添加服务器端同步支持（通过 `updateMemoOrganizer` API）

- **修复 Android Firebase 错误** - 禁用不必要的集成
  - 在 `main.dart` 中禁用 Sentry 的自动 Firebase 性能追踪
  - 在 `app_provider.dart` 中添加 Firebase 错误过滤
  - 确保项目不使用 Firebase 时不会报错

- **修复图片加载问题** - 优化图片缓存和加载策略
- **修复同步冲突** - 改进服务器同步和本地数据合并逻辑

### 🔧 Technical
- 版本号：1.0.7+10007（从 1.0.6+6 升级）
- 新增 11 个核心文件
- 优化了 54 个文件
- 项目大小：110MB（清理后）

---

## [1.0.6] - 2025-10-23

### 🐛 Fixed
- **修复 WebDAV 同步问题**
  - 修复同步冲突处理逻辑
  - 优化同步失败重试机制
  - 改进文件上传稳定性

### ⚡ Performance
- **优化启动速度** - 启动时间减少 30%
  - 改进资源加载策略
  - 优化启动流程

### 🎨 UI/UX
- **新增启动页** - 精美的原生启动页
  - 支持深色/浅色主题自适应
  - 优化启动体验

- **优化个人中心**
  - 改进个人信息展示界面
  - 优化头像上传和更新体验
  - 完善用户信息编辑功能

### 🔧 Other
- 修复部分 Bug
- 提升整体稳定性

---

## [1.0.5] - 2025-10-19

### 🎉 Added
- **隐私合规功能**
  - 首次启动显示隐私政策弹窗
  - 符合应用商店审核规范

- **友盟统计 SDK**
  - 支持 iOS 和 Android 双平台数据统计
  - 帮助改进产品体验

- **AI 相关笔记服务**
  - 智能分析笔记关联关系
  - 支持笔记推荐功能

- **WebDAV 服务重构**
  - 拆分为独立模块（webdav_service + webdav_sync_engine）
  - 提升稳定性

### 🎨 UI/UX
- **隐私政策弹窗** - 简洁优雅的大厂风格设计
- **相关笔记底部表单** - 优化笔记关联查看体验
- **简化备忘录内容展示** - 提升阅读体验

### 🐛 Fixed
- 修复 iOS 模拟器运行时 Umeng SDK 兼容性问题
- 修复 Android 端 Umeng 事件上报的 ClassCastException 错误
- 修复路由重定向导致 splash 页面被跳过的问题
- 修复 onboarding_screen.dart 中的编译错误

### 🔧 Technical
- 版本号：1.0.5+6（从 1.0.4+5 升级）
- 新增 5 个服务文件、3 个 Widget 组件
- iOS Podfile 新增 Umeng 依赖
- 原生代码更新（AppDelegate.swift、MainActivity.kt）

---

## [1.0.4] - 2025-10-08

### 🎉 Added
- **AI 智能助手** - 集成 DeepSeek AI
  - 智能写作辅助
  - 内容优化和扩展

- **自定义字体**
  - 支持 4 档字体大小（小、标准、大、特大）
  - 6 种精选字体（SF Pro Display、思源黑体、思源宋体、楷体风格、站酷小薇、站酷庆科）

- **英语支持** - 完整的英文界面翻译

- **知识图谱功能**
  - 可视化展示笔记关联关系
  - 构建知识网络

- **热力图月份切换** - 支持查看不同月份的笔记活跃度

### 🔧 Improved
- 优化通知中心 UI 设计（时间分组、滑动删除、触觉反馈）
- 优化登录/注册页面（新增 FAQ 帮助）
- 改进偏好设置页面（新增字体设置分组）
- 统一应用主题配色和视觉风格

### 🐛 Fixed
- 修复部分界面显示问题
- 修复通知相关 Bug
- 修复字体切换后部分界面未刷新的问题
- 优化各项功能稳定性

---

## [1.0.3] - 2025-10-06

### 🎉 Added
- 更新到 Flutter 3.35.5
- 优化 APK 构建配置，支持分架构构建
- 更新主题系统，适配最新 Material Design 3

### 🔧 Improved
- 修复头像加载问题
- 优化图片缓存机制
- 改进网络请求错误处理

### 🐛 Fixed
- 修复部分 Android 设备通知不显示的问题
- 修复语音识别在某些设备上崩溃的问题
- 修复深色模式下部分文字看不清的问题

---

## [1.0.2] - 2025-09-30

### 🎉 Added
- 实验室新增企业微信对接功能
- 新增笔记统计功能
- 新增随机回顾功能

### 🔧 Improved
- 修复头像加载问题
- 优化笔记列表加载性能
- 改进同步机制，减少流量消耗

### 🐛 Fixed
- 修复已知 Bug
- 修复部分 iOS 设备闪退问题

---

## [1.0.1] - 2025-09-20

### 🎉 Initial Release
- ✨ 完整的笔记管理功能
- 📱 Android 和 iOS 双平台支持
- 🔄 Memos 服务器同步
- 🎤 语音识别功能
- 🏷️ 标签系统
- ⏰ 定时提醒
- 🌓 深色模式
- 📝 Markdown 支持
- 🖼️ 图片管理
- 🔍 全文搜索
- 📊 笔记统计
- 🌍 多语言支持

---

## [Unreleased]

### Planned Features
- 📱 平板适配
- 📁 文件夹功能
- 🔗 笔记分享链接
- 🎨 自定义主题颜色
- 📎 附件支持（PDF、音频、视频）
- 🔒 笔记加密
- 📊 更丰富的数据可视化
- 🌍 更多语言支持（日文、韩文）

---

[1.0.7]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.7
[1.0.6]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.6
[1.0.5]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.5
[1.0.4]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.4
[1.0.3]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.3
[1.0.2]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.2
[1.0.1]: https://github.com/yyyyymmmmm/IntRoot/releases/tag/v1.0.1
[Unreleased]: https://github.com/yyyyymmmmm/IntRoot/compare/v1.0.7...HEAD

