# Memos API 版本演进文档 (v0.21.0 → v0.27.1)

> 文档生成时间：2026-04-22
> 项目主页：https://github.com/usememos/memos
> 官方文档：https://www.usememos.com/docs

---

## 📋 版本总览

从 v0.21.0（2024年4月）到 v0.27.1（2026年4月），Memos 经历了 **7 个大版本**和多个补丁版本的迭代，API 架构从 REST 逐步迁移到 gRPC/Connect-RPC，核心功能持续增强。

| 版本号 | 发布日期 | 重要程度 | 主要变更 |
|--------|----------|----------|----------|
| **v0.27.1** | 2026-04-19 | 🟢 Latest | 用户资源名称和发布构件的补丁修复 |
| **v0.27.0** | 2026-04-18 | 🔴 Major | 实时刷新(SSE)、语音笔记、AI 转录、MCP 工具、备忘录分享 |
| **v0.26.2** | 2026-02-23 | 🟡 Patch | 修复注销、日历、删除错误等问题 |
| **v0.26.1** | 2026-02-08 | 🟡 Patch | 修复收件箱崩溃、视频附件、嵌套任务列表渲染等 |
| **v0.26.0** | 2026-01-31 | 🔴 Major | 刷新令牌轮换、React Query 迁移、角色重构(HOST→ADMIN) |
| **v0.25.3** | 2025-11-25 | 🟡 Patch | 专注模式、删除未使用的附件、主题系统标准化 |
| **v0.25.2** | 2025-10-24 | 🟡 Patch | S3 图片缩略图、瀑布流布局、系统主题检测 |
| **v0.25.1** | 2025-09-15 | 🟡 Patch | 编辑器自动补全命令、反应过滤、用户特定 SQL 转换器 |
| **v0.25.0** | 2025-07-17 | 🔴 Major | 用户会话滑动窗口、Webhook 数据存储迁移 |
| **v0.24.4** | 2025-06-02 | 🟡 Patch | Bug 修复和性能改进 |
| **v0.24.3** | 2025-05-12 | 🟡 Patch | Bug 修复和用户体验增强 |
| **v0.24.2** | 2025-03-23 | 🟡 Patch | 稳定性修复 |
| **v0.24.1** | 2025-03-13 | 🟡 Patch | 稳定性修复 |
| **v0.24.0** | 2025-02-05 | 🔴 Major | 快捷方式系统、数据库和 API 变更 |
| **v0.23.1** | 2025-01-29 | 🟡 Patch | 稳定性修复 |
| **v0.23.0** | 2024-12-16 | 🔴 Major | 数据库和 API 变更 |
| **v0.22.5** | 2024-09-03 | 🟡 Patch | Bug 修复 |
| **v0.22.4** | 2024-07-27 | 🟡 Patch | Bug 修复 |
| **v0.22.3** | 2024-07-17 | 🟡 Patch | Bug 修复 |
| **v0.22.2** | 2024-06-10 | 🟡 Patch | Bug 修复 |
| **v0.22.1** | 2024-06-01 | 🟡 Patch | Bug 修复 |
| **v0.22.0** | 2024-05-19 | 🔴 Major | 新功能和 API 变更 |
| **v0.21.0** | 2024-04-09 | 🔴 Major | 新功能和改进 |

---

## 🚀 重大 API 变更总结

### 1. v0.27.0 - 实时通信与 AI 能力升级

#### 新增 API/功能
- **Server-Sent Events (SSE)**: 新增 `/api/v1/sse` 端点，支持实时更新
  - 连接状态在用户菜单显示
  - 备忘录、评论、反应事件实时推送
  - 附件和关系变更自动触发 `memo.updated` 事件

- **MCP (Model Context Protocol) 服务器**: 新增 `/mcp` 端点
  - 使用 Streamable HTTP 协议
  - 支持 PAT (Personal Access Token) 认证
  - 提供备忘录 CRUD、评论、附件、关系、反应、标签列表等功能
  - 支持 MCP 兼容客户端集成

- **语音笔记录制**: 新增语音录制 API
  - 备忘录编辑器支持语音输入
  - 实时波形显示面板

- **AI 音频转录**:
  - 新增 Gemini 转录提供商
  - 支持 BYOK (Bring Your Own Key) 音频转录
  - 实例级 AI 提供商和转录设置

- **备忘录分享链接**:
  - 创建和撤销备忘录分享链接（可设置过期时间）
  - 支持私密和受保护的备忘录分享
  - 分享令牌验证机制

- **备忘录提及**: 支持 `@username` 提及功能
  - 自动解析和渲染提及
  - 通知系统集成

#### API 安全增强
- SMTP、S3、OAuth 凭据改为**只写**（write-only）
- 敏感实例设置限制为仅管理员可访问
- 用户邮箱对其他普通用户隐藏
- Webhook SSRF 保护（可选 `--allow-private-webhooks` 标志绕过）

#### Breaking Changes
- **移除公共 ActivityService**: 消费者应迁移到用户通知 API
- **用户资源名称改用用户名**: 从数字 ID 改为用户名格式（如 `users/alice`）
- **身份提供商资源名称使用稳定 UID**: 替换原有的自增 ID 标识符
- **移除 `disallow_public_visibility` 设置**
- **默认附件存储改为本地文件系统**（新安装）

---

### 2. v0.26.0 - 认证架构重构

#### 核心 API 变更
- **刷新令牌轮换**: 实现滑动窗口会话
  - 增强认证安全性
  - 跨标签页令牌刷新同步
  - 本地令牌状态为空时使用刷新 Cookie 恢复

- **角色重构**: `HOST` → `ADMIN`
  - 数据库迁移自动处理
  - 权限模型重命名

- **React Query 迁移**: 前端状态管理重构
  - 替换自定义状态管理
  - 改进缓存和数据同步
  - 更好的开发者体验

#### 新增功能 API
- **用户档案备忘录地图**: 新增地理位置可视化
  - Google Maps 集成
  - 地理位置标记和过滤

- **HDR 图像和视频支持**
- **视频/音频文件流式传输**: 修复内存耗尽问题
- **图片上传 EXIF 元数据剥离**: 隐私增强（位置、相机信息等）

#### 迁移到 connect-rpc
- gRPC 网关架构迁移
- 改进错误处理（统一返回 gRPC 风格错误）

#### Breaking Changes
- **移除遗留会话 Cookie 认证**
- **移除已弃用的 Sessions 和 AccessTokens 设置**
- 视频/音频附件处理方式变更（流式传输）

---

### 3. v0.25.0 - Webhook 和会话管理

#### API 变更
- **用户会话滑动窗口**: 改进会话安全性和过期管理
- **Webhook 数据存储迁移**: 从系统级移到用户设置（**需要重新配置**）
- **新增主题系统**: 多种主题变体和自定义选项

#### 功能增强
- 固定备忘录高亮显示
- RSS Feed 资源 URL 修复
- 日历导航和时间格式改进

---

### 4. v0.24.0 - 快捷方式和过滤系统

#### 核心功能
- **快捷方式系统**: 引入快捷方式功能
  - 基于标签、可见性、时间戳等条件快速过滤备忘录
  - 支持比较、集合、字符串和逻辑运算符
  - 可重用过滤器创建

#### API 变更
- 数据库架构变更（需谨慎升级，建议备份）
- 新增快捷方式相关 API 端点

---

### 5. v0.23.0 - 核心 API 稳定性

#### 改进
- Postgres 不区分大小写的备忘录搜索
- iframe 渲染修复
- 服务器名称和图标从设置加载
- 日历过滤使用 UTC 日期
- 多语言支持改进（pt-PT 等）

#### Bug 修复
- 迁移文件命名导致的启动失败修复（v0.22.5）
- 星期日开始的月份首日逻辑修复
- 未来相对日期显示修复

---

### 6. v0.22.0 - 功能扩展

#### 新功能
- 新增备忘录评论、反应、关系功能
- 增强的备忘录详情侧边栏
- 改进的附件管理

#### API 增强
- 附件 MIME 类型验证
- 统计和图像处理内存优化
- 后端测试并行执行优化

---

### 7. v0.21.0 - 基础版本

#### 核心功能
- 备忘录 CRUD 操作
- 用户认证和权限管理
- 基础备忘录过滤和搜索
- 附件管理
- 标签系统
- Markdown 渲染

---

## 🔧 API 端点变更对比

### REST API 端点演进

#### v0.21.0 - v0.23.0（旧版 REST API）
```
# 备忘录
GET    /api/memo
POST   /api/memo
PATCH  /api/memo/:memoId
DELETE /api/memo/:memoId

# 用户
GET    /api/user
POST   /api/user
PATCH  /api/user/:userId

# 资源/附件
GET    /api/resource
POST   /api/resource
DELETE /api/resource/:resourceId

# 标签
GET    /api/tag
POST   /api/tag
DELETE /api/tag/:tagName
```

#### v0.24.0+ (引入快捷方式)
```
# 新增快捷方式 API
GET    /api/shortcut
POST   /api/shortcut
PATCH  /api/shortcut/:shortcutId
DELETE /api/shortcut/:shortcutId
```

#### v0.26.0+ (Connect-RPC 迁移)
```
# 新架构（gRPC/Connect-RPC）
/api/v1/*  # 新版本化 API 路径
```

#### v0.27.0 (最新功能)
```
# SSE 实时更新
GET /api/v1/sse

# MCP 服务器
POST /mcp  # Streamable HTTP

# 备忘录分享
POST /api/v1/memos/:id/share-link
DELETE /api/v1/memos/:id/share-link
GET /api/v1/shared-memos/:shareToken

# 备忘录评论
GET /api/v1/memos/:id/comments
POST /api/v1/memos/:id/comments
DELETE /api/v1/comments/:id

# AI 转录
POST /api/v1/transcribe
GET /api/v1/ai-providers
```

---

## 🔐 认证机制演进

### v0.21.0 - v0.25.0
- Session Cookie 认证
- Access Token（JWT）
- 基础会话管理

### v0.26.0+
- **移除遗留 Session Cookie**
- 刷新令牌轮换（Refresh Token Rotation）
- 滑动窗口会话（Sliding Window Sessions）
- 跨标签页令牌同步
- localStorage 持久化认证令牌

### v0.27.0+
- Personal Access Token (PAT) 用于 MCP 集成
- 分享令牌（Share Token）用于公开/受保护的备忘录访问

---

## 📦 数据库迁移注意事项

### 需要谨慎升级的版本

#### v0.27.0
- ⚠️ **数据库和 API 变更**
- **备份建议**: 升级前务必备份数据
- 用户资源名称从 ID 改为用户名
- 身份提供商资源名称改用 UID
- ActivityService 移除

#### v0.26.0
- ⚠️ **数据库和 API 变更**
- **备份建议**: 升级前务必备份数据
- HOST 角色迁移到 ADMIN
- 认证机制重构
- 从 v0.25.3 到 v0.26.0 自动修复权限问题

#### v0.25.0
- ⚠️ **Webhook 数据存储位置变更**
- **需要手动重新配置 Webhook**

#### v0.24.0
- ⚠️ **数据库和 API 变更**
- **备份建议**: 升级前务必备份数据
- 快捷方式表创建

#### v0.23.0
- ⚠️ **数据库和 API 变更**
- **备份建议**: 升级前务必备份数据

---

## 🔗 API 文档资源

### 官方文档
- **主站**: https://www.usememos.com
- **文档**: https://www.usememos.com/docs
- **更新日志**: https://www.usememos.com/changelog
- **GitHub**: https://github.com/usememos/memos
- **API 讨论**: https://github.com/usememos/memos/issues/967

### 社区资源
- Go Package 文档: https://pkg.go.dev/github.com/usememos/memos/api/v1
- Memospot（第三方客户端）: https://memospot.github.io

### 已知问题
- API 文档尚未完全公开：许多 API（resources, tags, memo）未正式文档化
- 建议通过 GitHub Issues 和源码了解 API 细节

---

## 📊 功能对比表

| 功能 | v0.21.0 | v0.24.0 | v0.26.0 | v0.27.0 |
|------|---------|---------|---------|---------|
| 基础 CRUD | ✅ | ✅ | ✅ | ✅ |
| 用户认证 | ✅ Session | ✅ Session | ✅ Token Rotation | ✅ Token + PAT |
| 备忘录过滤 | ✅ 基础 | ✅ 高级 | ✅ 高级 | ✅ 高级 |
| 快捷方式 | ❌ | ✅ | ✅ | ✅ |
| 评论系统 | ❌ | ✅ | ✅ | ✅ |
| 反应系统 | ❌ | ✅ | ✅ | ✅ |
| React Query | ❌ | ❌ | ✅ | ✅ |
| 实时更新(SSE) | ❌ | ❌ | ❌ | ✅ |
| 语音笔记 | ❌ | ❌ | ❌ | ✅ |
| AI 转录 | ❌ | ❌ | ❌ | ✅ |
| MCP 集成 | ❌ | ❌ | ❌ | ✅ |
| 备忘录分享 | ❌ | ❌ | ❌ | ✅ |
| 提及功能 | ❌ | ❌ | ❌ | ✅ |
| 地图视图 | ❌ | ❌ | ✅ | ✅ |
| HDR 媒体 | ❌ | ❌ | ✅ | ✅ |
| Connect-RPC | ❌ | ❌ | ✅ | ✅ |

---

## ⚠️ 升级建议

### 从 v0.21.0 升级到最新版本

1. **备份数据**（强烈推荐）
   ```bash
   # 备份数据库
   cp memos_prod.db memos_prod.db.backup-$(date +%Y%m%d)
   ```

2. **渐进式升级路径**
   - v0.21.0 → v0.24.0（引入快捷方式）
   - v0.24.0 → v0.26.0（认证重构）
   - v0.26.0 → v0.27.0（实时功能）

3. **检查配置变更**
   - Webhook 配置（v0.25.0）
   - 用户资源名称引用（v0.27.0）
   - 身份提供商配置（v0.27.0）

4. **验证 API 调用**
   - 检查客户端代码中的用户资源名称格式
   - 更新 ActivityService 调用为用户通知 API
   - 测试认证流程

5. **性能优化**
   - 考虑启用 SSE 实时更新
   - 配置附件存储（本地/S3）
   - 检查图片缩略图生成

### 关键配置项

```yaml
# v0.27.0 新增配置
--allow-private-webhooks  # 允许私有 Webhook（SSRF 保护绕过）

# 存储配置
MEMOS_STORAGE_TYPE=local  # v0.27.0 默认值

# AI 功能配置
MEMOS_AI_PROVIDER=gemini
MEMOS_AI_API_KEY=your_key

# MCP 配置
# 通过 PAT 认证访问 /mcp 端点
```

---

## 🐛 已知问题和解决方案

### v0.26.0 → v0.26.1
- **问题**: 收件箱因已删除备忘录崩溃
- **解决**: 已在 v0.26.1 修复

### v0.26.0 权限问题
- **问题**: 从 v0.25.3 升级后可能出现权限错误
- **解决**: v0.26.0 包含自动修复脚本

### v0.27.0 用户资源名称
- **问题**: 旧客户端使用数字 ID 格式
- **解决**: 更新客户端代码使用 `users/username` 格式

---

## 📝 总结

Memos 从 v0.21.0 到 v0.27.1 的演进体现了以下趋势：

1. **架构现代化**: REST → gRPC/Connect-RPC 迁移
2. **实时性增强**: SSE 实时更新、语音笔记
3. **安全性提升**: 刷新令牌轮换、凭据保护、SSRF 防护
4. **AI 集成**: 音频转录、MCP 协议支持
5. **用户体验**: 备忘录分享、提及、快捷方式、主题系统
6. **开发者体验**: React Query、Connect-RPC、改进的错误处理

**升级建议**:
- 小版本升级（如 v0.27.0 → v0.27.1）: 低风险
- 大版本升级（如 v0.21.0 → v0.27.0）: 需要测试环境验证、数据备份、配置审查

---

*文档编制：dodo AI 助手 | 数据来源：GitHub usememos/memos*
