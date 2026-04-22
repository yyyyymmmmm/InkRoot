# Memos API 版本演进时间线（v0.21.0 - v0.27.1）

## 完整版本列表

v0.21.0 → v0.22.0 (5个版本) → v0.23.0 (1个版本) → v0.24.0 (4个版本) → v0.25.0 (3个版本) → v0.26.0 (2个版本) → v0.27.0 (1个版本)

**总计：23个发布版本**

---

## v0.21.0（2024年初）
**基线版本**

### 核心特性
- `/api/v1/` REST API 体系建立
- JWT Bearer Token 认证机制
- 基础 CRUD 操作
- 用户系统（基于数字ID）
- 标签系统（property字段存储）

### 认证端点
```
POST /api/v1/auth/signin    - 用户登录（返回 token 或 accessToken）
POST /api/v1/auth/signout   - 用户登出
POST /api/v1/auth/signup    - 用户注册
```

### Memo 端点
```
GET    /api/v1/memo          - 列出备忘录
POST   /api/v1/memo          - 创建备忘录
GET    /api/v1/memo/{id}     - 获取单个备忘录
PATCH  /api/v1/memo/{id}     - 更新备忘录
DELETE /api/v1/memo/{id}     - 删除备忘录
```

### 用户端点
```
GET   /api/v1/user           - 列出用户
GET   /api/v1/user/{id}      - 获取用户信息
PATCH /api/v1/user/{id}      - 更新用户信息
```

---

## v0.22.0（2024年6月）
**⚠️ BREAKING CHANGE - API v1 不兼容更新**

### 重大变更
1. **API v1 不兼容更新**
   - 官方文档：https://memos.apidocumentation.com/reference
   - 部分响应格式调整
   - 部分请求参数变更

2. **标签系统重构**
   - 从 `property` 字段迁移到独立存储
   - 支持显示关联 Memo 数量
   - 更精确的搜索功能

3. **S3 存储改进**
   - 使用 Pre-signed URL
   - 支持同步删除

4. **数据库迁移**
   - 需要执行 migration
   - 建议升级前备份数据

### 新增端点
```
GET /api/v1/memo/property     - 获取 Memo 属性（v0.22.1+）
```

### IntRoot 兼容性
- ✅ **完全兼容** - 通过 MemosApiV21 适配器处理响应格式差异
- 标签系统变更对客户端透明（后端自动处理）
- S3 存储变更不影响基础 API 调用

---

## v0.22.1 - v0.22.5（2024年6-10月）
**渐进式改进版本**

### v0.22.1（2024年7月）
- 新增快速过滤功能（链接、待办、代码）
- 新增 Memo 相关设置（自动折叠、双击编辑）
- 新增 `/api/v1/memo/property` 端点
- 登出时正确删除 Access Token

### v0.22.2（2024年7月）
- 统计面板显示未完成待办
- 修复 XSS 漏洞（HTML 渲染）
- 支持泰语

### v0.22.3（2024年8月）
- **新增 UID 支持**
  - `GET /api/v1/memo/uid/{uid}` - 通过 UID 获取 Memo
  - `GET /api/v1/resource/uid/{uid}` - 通过 UID 获取资源
- 内联编辑器支持
- 树状标签显示
- 登出时删除 Access Token（修复）
- `PATCH /api/v1/memo` 修复（#3600）

### v0.22.4（2024年9月）
- 新增 `--password-auth` 标志控制用户名密码登录
- 修改 Memo 时支持更改日期
- `--public` 标志默认值改为 false（默认禁用注册）
- 新增日历视图
- 移除 Timeline 页面
- 修复 XSS 漏洞（代码块）

### v0.22.5（2024年10月）
- 新增 Memo 评论开关设置
- 重新引入缩略图功能
- 支持管理员编辑其他用户 Memo
- 新增周起始日设置
- 支持按时间正序排列

### IntRoot 兼容性（v0.22.x 系列）
- ✅ **完全兼容** - 所有版本通过 MemosApiV21 适配器支持
- UID 端点为**新增功能**，不影响原有 ID 端点
- 无 Breaking Changes

---

## v0.23.0 - v0.23.1（2024年11-12月）
**UI/UX 增强版本**

### v0.23.0（2024年11月）
- 支持禁用更改用户名和昵称
- 移动端图片预览支持缩放
- 日历过滤使用 UTC 日期
- 新增下拉刷新功能
- 新增"显示更少"功能（Memo 展开时）
- 支持移除已完成待办项
- 支持键盘导航图片查看
- **标签从 property 移至 payload**（重构，v0.23.1）
- 支持全局默认 Memo 可见性设置

### v0.23.1（2024年12月）
- **重要重构：标签从 property 移至 payload**
- Memo 过滤器持久化到 URL 查询参数
- 日期选择器导航改进
- 支持 S3 URL 样式设置
- 支持多语言（捷克语、格鲁吉亚语、印尼语、葡萄牙语等）

### API 变化
- 标签存储位置变更（内部重构，API 接口保持兼容）
- **无 Breaking Changes**

### IntRoot 兼容性
- ✅ **完全兼容** - MemosApiV21 适配器自动处理标签字段变化
- 所有新增功能为 UI/UX 改进，不影响 API 层

---

## v0.24.0 - v0.24.4（2024年12月-2025年1月）
**数据库和API变更**

### v0.24.0（2024年12月）
⚠️ **包含数据库和API变更，升级需谨慎**

#### 主要变更
- 数据库 Schema 升级
- API 端点调整（具体变更未在 Changelog 详述）
- 建议升级前备份数据

#### 新增功能
- Webhook 改进
- 资源管理增强
- 性能优化

### v0.24.1 - v0.24.4（2025年1月）
- Bug 修复和稳定性改进
- 多语言翻译更新
- UI 细节优化

### IntRoot 兼容性
- ⚠️ **需要测试** - 因包含 API 变更
- 建议使用 Docker 测试环境验证
- MemosApiV21 适配器**可能需要调整**

---

## v0.25.0 - v0.25.3（2025年1-2月）
**数据库和API变更**

### v0.25.0（2025年1月）
⚠️ **包含数据库和API变更，升级需谨慎**

#### 主要变更
- 数据库 Schema 升级
- API 端点调整
- 建议升级前备份数据

### v0.25.1 - v0.25.3
- Bug 修复和稳定性改进
- 修复 DeleteMemoTag 端点参数冲突（#4985）
- 性能优化

### IntRoot 兼容性
- ⚠️ **需要测试** - 因包含 API 变更
- 建议使用 Docker 测试环境验证

---

## v0.26.0 - v0.26.2（2025年2-3月）
**⚠️ BREAKING CHANGE - Token 刷新机制**

### v0.26.0（2025年2月）
**重大变更：引入 Token 刷新机制**

#### 新增认证端点
```
POST /api/v1/auth/refresh    - 刷新 Access Token
```

#### 认证流程变更
1. **登录响应新增 Refresh Token**
   ```json
   {
     "accessToken": "eyJ...",
     "refreshToken": "eyJ..."  // 新增
   }
   ```

2. **Token 刷新流程（Refresh Token Rotation）**
   - Access Token 过期时，使用 Refresh Token 换取新 Token
   - 每次刷新返回新的 Access Token 和 Refresh Token
   - 自动轮换机制提升安全性

3. **向后兼容**
   - 旧版 Token 仍可使用（无 Refresh Token）
   - 建议客户端升级到新机制

### v0.26.1 - v0.26.2
- Token 刷新机制稳定性改进
- Bug 修复

### IntRoot 兼容性
- ✅ **通过 MemosApiV26 适配器支持**
- 自动 Token 刷新包装器（`_withAutoRefresh`）
- 完全向后兼容 v0.21-v0.25

---

## v0.27.0 - v0.27.1（2025年3-4月）
**⚠️ BREAKING CHANGE - 用户资源路径变更**

### v0.27.0（2025年3月）
**重大变更：用户资源路径从 ID 改为 username**

#### 用户端点变更
```diff
旧格式（v0.26.2及更早）:
- GET   /api/v1/user/{id}
- PATCH /api/v1/user/{id}

新格式（v0.27.0+）:
+ GET   /api/v1/users/{username}
+ PATCH /api/v1/users/{username}
```

#### 新增功能
1. **个人访问令牌（PAT）**
   ```
   POST   /api/v1/users/{username}/access_tokens    - 创建 PAT
   GET    /api/v1/users/{username}/access_tokens    - 列出 PAT
   DELETE /api/v1/users/{username}/access_tokens/{id} - 删除 PAT
   ```

2. **服务器推送事件（SSE）**
   ```
   GET /api/v1/memo/stream    - SSE 流式更新（实时同步）
   ```

3. **语音备忘录**
   ```
   POST /api/v1/voice    - 上传语音文件转文字
   ```

4. **备忘录分享**
   ```
   POST   /api/v1/memo/{id}/share    - 创建分享链接
   DELETE /api/v1/memo/{id}/share    - 取消分享
   ```

#### 其他改进
- Markdown 渲染引擎升级
- 性能优化
- UI/UX 改进

### v0.27.1（2025年4月）
- Bug 修复和稳定性改进
- 多语言翻译更新

### IntRoot 兼容性
- ✅ **通过 MemosApiV27 适配器支持**
- 自动 ID → username 转换
- 继承 v0.26 的 Token 刷新机制
- 完全向后兼容 v0.21-v0.26

---

## 📊 Breaking Changes 汇总

| 版本 | 类型 | 影响 | IntRoot适配方案 |
|------|------|------|----------------|
| **v0.22.0** | API v1 不兼容更新 | 响应格式变化、标签系统重构 | ✅ MemosApiV21 处理格式差异 |
| **v0.24.0** | 数据库&API变更 | 未详细说明的 API 调整 | ⚠️ 需测试验证 |
| **v0.25.0** | 数据库&API变更 | 未详细说明的 API 调整 | ⚠️ 需测试验证 |
| **v0.26.0** | Token 刷新机制 | 新增 Refresh Token 和刷新端点 | ✅ MemosApiV26 自动刷新 |
| **v0.27.0** | 用户资源路径变更 | ID → username | ✅ MemosApiV27 自动转换 |

---

## 🎯 IntRoot 适配器版本映射

| 适配器版本 | 支持的Memos版本 | 核心特性 |
|-----------|----------------|---------|
| **MemosApiV21** | v0.21.0 - v0.25.x | 基线实现，处理基础API和格式差异 |
| **MemosApiV26** | v0.26.0 - v0.26.2 | 继承V21 + Token自动刷新 |
| **MemosApiV27** | v0.27.0 - v0.27.1 | 继承V26 + username转换 + SSE/PAT/语音/分享 |

---

## 📝 升级建议

### 从 v0.21.x 升级到 v0.22.x
- ✅ 安全升级
- 使用 MemosApiV21 适配器
- 标签系统变更对客户端透明

### 从 v0.22.x 升级到 v0.24.x / v0.25.x
- ⚠️ 建议先在测试环境验证
- 包含数据库 migration
- 可能需要调整适配器代码

### 从 v0.25.x 升级到 v0.26.x
- ✅ 推荐升级（获得Token刷新安全特性）
- 使用 MemosApiV26 适配器
- 完全向后兼容

### 从 v0.26.x 升级到 v0.27.x
- ✅ 推荐升级（最新特性）
- 使用 MemosApiV27 适配器
- 获得 SSE、PAT、语音备忘录等新功能

---

## 🔍 测试验证清单

### 验证 v0.24.x / v0.25.x 兼容性
```bash
# 启动 Docker 测试环境
cd docker
./manage.sh start

# 运行完整测试套件
dart test/api_compatibility_test.dart
```

### 重点测试场景
- [ ] v0.24.0 基础 CRUD 操作
- [ ] v0.24.x 标签系统功能
- [ ] v0.25.0 基础 CRUD 操作
- [ ] v0.25.x 用户信息获取
- [ ] v0.26.0 Token 刷新机制
- [ ] v0.27.0 username 转换
- [ ] v0.27.0 SSE 实时更新（可选）

---

## 📚 参考资源

- **官方文档**：https://memos.apidocumentation.com/reference
- **GitHub Releases**：https://github.com/usememos/memos/releases
- **IntRoot 项目文档**：`/docs/memos_api/`
  - `API_COMPLETE_COMPARISON.md` - 完整API对比
  - `v0.21.0_API_Documentation.md` - v0.21.0 完整API
  - `v0.26.0_API_Documentation.md` - v0.26.0 完整API
  - `v0.27.0_API_Documentation.md` - v0.27.0 完整API

---

**文档版本**：1.0
**最后更新**：2026-04-22
**维护者**：IntRoot 开发团队
