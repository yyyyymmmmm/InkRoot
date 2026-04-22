# Memos API 完整版本对比文档

> **对比范围**: v0.21.0 - v0.27.1 所有版本
> **对比维度**: 认证机制、API 端点、请求参数、响应格式、Breaking Changes
> **文档日期**: 2026-04-22

---

## 📋 目录

1. [版本总览](#版本总览)
2. [认证机制对比](#认证机制对比)
3. [API 端点完整对比](#api-端点完整对比)
4. [请求参数对比](#请求参数对比)
5. [响应格式对比](#响应格式对比)
6. [Breaking Changes 汇总](#breaking-changes-汇总)
7. [IntRoot 项目使用的 API 对比](#introot-项目使用的-api-对比)
8. [升级建议](#升级建议)

---

## 版本总览

### 版本发布时间线

| 版本 | 发布日期 | 主要特性 | 重要程度 |
|------|---------|---------|---------|
| **v0.21.0** | 2024-Q1 | 基础功能完整 | 🟢 Stable |
| v0.21.1 | 2024-Q1 | Bug 修复 | 🔵 Patch |
| v0.22.0 | 2024-Q2 | UI 改进 | 🟡 Minor |
| v0.23.0 | 2024-Q2 | 性能优化 | 🟡 Minor |
| v0.23.1 | 2024-Q2 | Bug 修复 | 🔵 Patch |
| v0.23.2 | 2024-Q2 | 安全修复 | 🔵 Patch |
| **v0.24.0** | 2024-Q3 | Shortcuts 系统 | 🟡 Minor |
| v0.24.1 | 2024-Q3 | Bug 修复 | 🔵 Patch |
| v0.25.0 | 2024-Q3 | WebDAV 同步 | 🟡 Minor |
| v0.25.1 | 2024-Q4 | Bug 修复 | 🔵 Patch |
| **v0.26.0** | 2024-Q4 | Token 刷新机制 | 🟠 Major Feature |
| v0.26.1 | 2024-Q4 | Bug 修复 | 🔵 Patch |
| v0.26.2 | 2024-Q4 | 性能优化 | 🔵 Patch |
| **v0.27.0** | 2025-Q1 | SSE + 语音笔记 | 🟠 Major Feature |
| v0.27.1 | 2025-Q1 | Bug 修复 | 🔵 Patch |

---

## 认证机制对比

### 概览

| 版本 | 认证方式 | Token 格式 | Token 生命周期 | Refresh Token | 支持 |
|------|---------|-----------|---------------|---------------|------|
| **v0.21.0-v0.25.x** | JWT | Bearer Token | 固定（无过期） | ❌ 不支持 | Session Cookie + Token |
| **v0.26.0-v0.26.x** | JWT | Bearer Token | 可配置过期时间 | ✅ 支持 Rotation | Token + Refresh Token |
| **v0.27.0+** | JWT | Bearer Token | 可配置过期时间 | ✅ 支持 Rotation | Token + Refresh + PAT |

### v0.21.0-v0.25.x 认证

#### 登录接口
```http
POST /api/v1/auth/signin
Content-Type: application/json

{
  "username": "alice",
  "password": "secret123"
}
```

#### 响应格式
```json
{
  "user": {
    "id": 1,
    "username": "alice",
    "email": "alice@example.com",
    "nickname": "Alice",
    "role": "USER"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### 使用 Token
```http
GET /api/v1/memo
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### v0.26.0+ 认证

#### 登录接口（相同）
```http
POST /api/v1/auth/signin
Content-Type: application/json

{
  "username": "alice",
  "password": "secret123"
}
```

#### 响应格式（新增字段）
```json
{
  "user": {
    "id": 1,
    "username": "alice",
    "email": "alice@example.com",
    "nickname": "Alice",
    "role": "USER"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": 1640995200
}
```

#### Token 刷新（新增）
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**响应**:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": 1640995200
}
```

### v0.27.0+ 认证（新增 PAT）

#### Personal Access Token（新）
```http
POST /api/v1/auth/pat
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "name": "My Application",
  "expiresAt": "2025-12-31T23:59:59Z"
}
```

**响应**:
```json
{
  "token": "memos_pat_1234567890abcdef",
  "name": "My Application",
  "expiresAt": "2025-12-31T23:59:59Z"
}
```

---

## API 端点完整对比

### 认证相关 API

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/auth/signin` | POST | ✅ | ✅ | ✅ | ✅ | 登录 |
| `/api/v1/auth/signout` | POST | ✅ | ✅ | ✅ | ✅ | 登出 |
| `/api/v1/auth/signup` | POST | ✅ | ✅ | ✅ | ✅ | 注册 |
| `/api/v1/auth/refresh` | POST | ❌ | ❌ | ✅ | ✅ | Token 刷新 |
| `/api/v1/auth/pat` | POST | ❌ | ❌ | ❌ | ✅ | 创建 PAT |
| `/api/v1/auth/pat` | GET | ❌ | ❌ | ❌ | ✅ | 获取 PAT 列表 |
| `/api/v1/auth/pat/{id}` | DELETE | ❌ | ❌ | ❌ | ✅ | 删除 PAT |

### 用户相关 API

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/user` | GET | ✅ | ✅ | ✅ | ✅ | 获取用户列表 |
| `/api/v1/user/me` | GET | ✅ | ✅ | ✅ | ✅ | 获取当前用户 |
| `/api/v1/user/{id}` | GET | ✅ | ✅ | ✅ | ⚠️ | 获取用户详情 |
| `/api/v1/user/{id}` | PATCH | ✅ | ✅ | ✅ | ❌ | 更新用户（已废弃） |
| `/api/v1/users/{username}` | GET | ❌ | ❌ | ❌ | ✅ | 获取用户（新格式） |
| `/api/v1/users/{username}` | PATCH | ❌ | ❌ | ❌ | ✅ | 更新用户（新格式） |
| `/api/v1/user/{id}/setting` | GET | ✅ | ✅ | ✅ | ✅ | 获取用户设置 |
| `/api/v1/user/{id}/setting` | PATCH | ✅ | ✅ | ✅ | ✅ | 更新用户设置 |

**⚠️ Breaking Change (v0.27.0)**:
- 用户资源标识从数字 ID 改为 username
- 路径从 `/api/v1/user/{id}` 改为 `/api/v1/users/{username}`

### 备忘录相关 API

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/memo` | GET | ✅ | ✅ | ✅ | ✅ | 获取备忘录列表 |
| `/api/v1/memo` | POST | ✅ | ✅ | ✅ | ✅ | 创建备忘录 |
| `/api/v1/memo/{id}` | GET | ✅ | ✅ | ✅ | ✅ | 获取单个备忘录 |
| `/api/v1/memo/{id}` | PATCH | ✅ | ✅ | ✅ | ✅ | 更新备忘录 |
| `/api/v1/memo/{id}` | DELETE | ✅ | ✅ | ✅ | ✅ | 删除备忘录 |
| `/api/v1/memo/{id}/organizer` | POST | ✅ | ✅ | ✅ | ✅ | 更新组织状态（置顶） |
| `/api/v1/memo/{id}/relation` | GET | ✅ | ✅ | ✅ | ✅ | 获取关联 |
| `/api/v1/memo/{id}/relation` | POST | ✅ | ✅ | ✅ | ✅ | 创建关联 |
| `/api/v1/memo/{id}/relation/{relId}` | DELETE | ✅ | ✅ | ✅ | ✅ | 删除关联 |
| `/api/v1/memo/{id}/resource` | GET | ✅ | ✅ | ✅ | ✅ | 获取资源列表 |
| `/api/v1/memo/{id}/comment` | GET | ✅ | ✅ | ✅ | ✅ | 获取评论 |
| `/api/v1/memo/{id}/comment` | POST | ✅ | ✅ | ✅ | ✅ | 添加评论 |
| `/api/v1/memo/{id}/share` | POST | ❌ | ❌ | ❌ | ✅ | 创建分享链接 |
| `/api/v1/memo/{id}/share/{key}` | DELETE | ❌ | ❌ | ❌ | ✅ | 删除分享链接 |
| `/api/v1/share/{key}` | GET | ❌ | ❌ | ❌ | ✅ | 访问分享 |

### 资源相关 API

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/resource` | GET | ✅ | ✅ | ✅ | ✅ | 获取资源列表 |
| `/api/v1/resource` | POST | ✅ | ✅ | ✅ | ✅ | 上传资源 |
| `/api/v1/resource/{id}` | GET | ✅ | ✅ | ✅ | ✅ | 获取资源 |
| `/api/v1/resource/{id}` | PATCH | ✅ | ✅ | ✅ | ✅ | 更新资源 |
| `/api/v1/resource/{id}` | DELETE | ✅ | ✅ | ✅ | ✅ | 删除资源 |
| `/api/v1/resource/{id}/blob` | GET | ✅ | ✅ | ✅ | ✅ | 下载资源 |

### 标签相关 API

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/tag` | GET | ✅ | ✅ | ✅ | ✅ | 获取标签列表 |
| `/api/v1/tag` | POST | ✅ | ✅ | ✅ | ✅ | 创建标签 |
| `/api/v1/tag/{name}` | DELETE | ✅ | ✅ | ✅ | ✅ | 删除标签 |
| `/api/v1/tag:rename` | POST | ✅ | ✅ | ✅ | ✅ | 重命名标签 |

### 快捷方式 API（v0.24.0+）

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/shortcut` | GET | ❌ | ✅ | ✅ | ✅ | 获取快捷方式列表 |
| `/api/v1/shortcut` | POST | ❌ | ✅ | ✅ | ✅ | 创建快捷方式 |
| `/api/v1/shortcut/{id}` | GET | ❌ | ✅ | ✅ | ✅ | 获取快捷方式 |
| `/api/v1/shortcut/{id}` | PATCH | ❌ | ✅ | ✅ | ✅ | 更新快捷方式 |
| `/api/v1/shortcut/{id}` | DELETE | ❌ | ✅ | ✅ | ✅ | 删除快捷方式 |

### 实时通信 API（v0.27.0+）

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/sse` | GET | ❌ | ❌ | ❌ | ✅ | Server-Sent Events |
| `/api/v1/webhook` | GET | ❌ | ❌ | ❌ | ✅ | 获取 Webhook 列表 |
| `/api/v1/webhook` | POST | ❌ | ❌ | ❌ | ✅ | 创建 Webhook |
| `/api/v1/webhook/{id}` | DELETE | ❌ | ❌ | ❌ | ✅ | 删除 Webhook |

### 系统相关 API

| 端点 | 方法 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `/api/v1/ping` | GET | ✅ | ✅ | ✅ | ✅ | 健康检查 |
| `/api/v1/status` | GET | ✅ | ✅ | ✅ | ✅ | 系统状态 |
| `/api/v1/system/setting` | GET | ✅ | ✅ | ✅ | ✅ | 获取系统设置 |
| `/api/v1/system/setting` | PATCH | ✅ | ✅ | ✅ | ✅ | 更新系统设置 |

---

## 请求参数对比

### getMemos 查询参数

| 参数 | 类型 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `creatorId` | int | ✅ | ✅ | ✅ | ✅ | 创建者 ID |
| `rowStatus` | string | ✅ | ✅ | ✅ | ✅ | 状态（NORMAL/ARCHIVED） |
| `pinned` | bool | ✅ | ✅ | ✅ | ✅ | 是否置顶 |
| `tag` | string | ✅ | ✅ | ✅ | ✅ | 标签过滤 |
| `visibility` | string | ✅ | ✅ | ✅ | ✅ | 可见性 |
| `limit` | int | ✅ | ✅ | ✅ | ✅ | 返回数量 |
| `offset` | int | ✅ | ✅ | ✅ | ✅ | 偏移量 |
| `filter` | string | ❌ | ✅ | ✅ | ✅ | CEL 过滤表达式 |

**v0.24.0 新增**: `filter` 参数支持 CEL（Common Expression Language）过滤

**示例**:
```http
GET /api/v1/memo?filter=visibility=="PUBLIC"&&hasTag("important")
```

### createMemo 请求体

| 字段 | 类型 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `content` | string | ✅ | ✅ | ✅ | ✅ | 内容（必填） |
| `visibility` | string | ✅ | ✅ | ✅ | ✅ | 可见性 |
| `resourceIdList` | int[] | ✅ | ✅ | ✅ | ✅ | 资源 ID 列表 |
| `relationList` | object[] | ✅ | ✅ | ✅ | ✅ | 关联列表 |
| `pinned` | bool | ❌ | ❌ | ❌ | ✅ | 创建时置顶 |

### updateUser 请求体

| 字段 | 类型 | v0.21 | v0.24 | v0.26 | v0.27 | 说明 |
|------|------|-------|-------|-------|-------|------|
| `username` | string | ✅ | ✅ | ✅ | ✅ | 用户名 |
| `nickname` | string | ✅ | ✅ | ✅ | ✅ | 昵称 |
| `email` | string | ✅ | ✅ | ✅ | ✅ | 邮箱 |
| `avatarUrl` | string | ✅ | ✅ | ✅ | ✅ | 头像 URL |
| `description` | string | ✅ | ✅ | ✅ | ✅ | 描述 |
| `role` | string | ✅ | ✅ | ⚠️ | ⚠️ | 角色（v0.26+ 改名） |

**v0.26.0 Breaking Change**: 角色名称变更
- `HOST` → `ADMIN`（v0.26.0+）

---

## 响应格式对比

### 用户对象

#### v0.21.0-v0.26.x
```json
{
  "id": 1,
  "username": "alice",
  "role": "USER",
  "email": "alice@example.com",
  "nickname": "Alice",
  "avatarUrl": "https://example.com/avatar.jpg",
  "createdTs": 1640995200,
  "updatedTs": 1640995200,
  "rowStatus": "NORMAL"
}
```

#### v0.27.0+
```json
{
  "name": "users/alice",           // ← 新增：资源名称
  "id": 1,
  "username": "alice",
  "role": "USER",
  "email": "alice@example.com",
  "nickname": "Alice",
  "avatarUrl": "https://example.com/avatar.jpg",
  "createdTs": 1640995200,
  "updatedTs": 1640995200,
  "rowStatus": "NORMAL"
}
```

### 备忘录对象

#### v0.21.0-v0.26.x
```json
{
  "id": 123,
  "creatorId": 1,
  "createdTs": 1640995200,
  "updatedTs": 1640995200,
  "rowStatus": "NORMAL",
  "content": "Hello world",
  "visibility": "PRIVATE",
  "pinned": false,
  "resourceList": [],
  "relationList": []
}
```

#### v0.27.0+
```json
{
  "name": "memos/123",             // ← 新增：资源名称
  "uid": "abc123def",              // ← 新增：全局唯一 ID
  "id": 123,
  "creatorId": 1,
  "creator": "users/alice",        // ← 新增：创建者资源名称
  "createdTs": 1640995200,
  "updatedTs": 1640995200,
  "rowStatus": "NORMAL",
  "content": "Hello world",
  "visibility": "PRIVATE",
  "pinned": false,
  "resourceList": [],
  "relationList": [],
  "reactions": []                  // ← 新增：表情反应
}
```

### 错误响应

#### v0.21.0-v0.25.x
```json
{
  "error": "Memo not found"
}
```

#### v0.26.0+
```json
{
  "code": "NOT_FOUND",
  "message": "Memo not found",
  "details": {
    "resource": "memo",
    "id": 123
  }
}
```

---

## Breaking Changes 汇总

### v0.26.0 Breaking Changes

#### 1. 角色名称变更
```diff
- "role": "HOST"
+ "role": "ADMIN"
```

**影响**: 角色检查逻辑需要更新

#### 2. 认证响应字段变更
```diff
# v0.21.0-v0.25.x
{
-  "token": "..."
}

# v0.26.0+
{
+  "accessToken": "...",
+  "refreshToken": "...",
+  "expiresAt": 1640995200
}
```

**影响**: 需要适配新的响应格式

### v0.27.0 Breaking Changes

#### 1. 用户资源路径变更 ⚠️ **最重要**
```diff
# v0.21.0-v0.26.x
- PATCH /api/v1/user/1

# v0.27.0+
+ PATCH /api/v1/users/alice
```

**影响**:
- 所有用户更新操作需要使用 username 而非 ID
- 需要先调用 `/api/v1/user/me` 获取 username

#### 2. 响应格式新增字段
```diff
# 用户对象
{
+  "name": "users/alice"
}

# 备忘录对象
{
+  "name": "memos/123",
+  "uid": "abc123def",
+  "creator": "users/alice",
+  "reactions": []
}
```

**影响**: 可能影响 JSON 反序列化

---

## IntRoot 项目使用的 API 对比

### IntRoot 实际使用的 10 个 API

| API 方法 | 端点 | v0.21 | v0.24 | v0.26 | v0.27 | 兼容性 |
|---------|------|-------|-------|-------|-------|--------|
| `createAccessToken()` | POST `/api/v1/auth/signin` | ✅ | ✅ | ⚠️ | ⚠️ | 响应格式变化 |
| `logout()` | POST `/api/v1/auth/signout` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `getUserInfo()` | GET `/api/v1/user/me` | ✅ | ✅ | ✅ | ⚠️ | 响应新增字段 |
| `updateUserInfo()` | PATCH `/api/v1/user/{id}` | ✅ | ✅ | ✅ | ❌ | v0.27 路径变更 |
| `createMemo()` | POST `/api/v1/memo` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `getMemos()` | GET `/api/v1/memo` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `getMemo()` | GET `/api/v1/memo/{id}` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `updateMemo()` | PATCH `/api/v1/memo/{id}` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `deleteMemo()` | DELETE `/api/v1/memo/{id}` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `updateMemoOrganizer()` | POST `/api/v1/memo/{id}/organizer` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |

### 兼容性统计

| 兼容性级别 | 数量 | 百分比 | API 列表 |
|-----------|------|--------|---------|
| ✅ **完全兼容** | 7 | 70% | logout, createMemo, getMemos, getMemo, updateMemo, deleteMemo, updateMemoOrganizer |
| ⚠️ **需适配** | 3 | 30% | createAccessToken, getUserInfo, updateUserInfo |

### 适配器处理方案

#### 1. createAccessToken - 响应格式适配
```dart
final data = jsonDecode(response.body);
// ✅ 自动兼容两种格式
final token = data['accessToken'] ?? data['token'];
```

#### 2. getUserInfo - 响应字段兼容
```dart
// v0.27.0 新增 'name' 字段，但不影响现有逻辑
final userInfo = jsonDecode(response.body);
// 现有代码继续使用 'id', 'username' 等字段
```

#### 3. updateUserInfo - 路径自动转换 ⚠️
```dart
// 获取 username
final currentUser = await getUserInfo();
final identifier = currentUser['username'] ?? userId.toString();

// ✅ 自动选择正确的路径
// v0.21-v0.26: /api/v1/user/1
// v0.27+: /api/v1/users/alice
await _api.updateUser(identifier, updates);
```

---

## 升级建议

### 从 v0.21.0 升级到 v0.24.0

**变更内容**: 新增 Shortcuts 系统

**升级建议**: ✅ **推荐升级**
- 主要是功能新增，无破坏性变更
- 可选择性使用新功能
- 原有 API 100% 兼容

**升级步骤**:
1. 直接替换服务器版本
2. 无需修改客户端代码
3. 可选：使用新的 Shortcuts API

### 从 v0.21.0 升级到 v0.26.0

**变更内容**: Token 刷新机制 + 角色重命名

**升级建议**: ⚠️ **谨慎升级**
- 认证响应格式变化
- 角色名称变更（`HOST` → `ADMIN`）
- 需要适配代码

**升级步骤**:
1. ✅ **使用 IntRoot 适配器**：自动处理所有变化
2. 适配器自动兼容 `token` 和 `accessToken`
3. 可选：实现 Token 自动刷新逻辑

### 从 v0.21.0 升级到 v0.27.0

**变更内容**: 用户资源路径变更 + SSE + 语音笔记

**升级建议**: ⚠️ **必须使用适配器**
- 用户更新 API 路径完全变更
- 不使用适配器会导致更新用户失败
- 新功能丰富（SSE、语音笔记、分享链接）

**升级步骤**:
1. ✅ **必须使用 IntRoot 适配器**
2. 适配器自动转换用户 ID 为 username
3. 可选：使用 SSE 实时更新功能
4. 可选：使用语音笔记功能

### 升级路径推荐

```
v0.21.0 → v0.24.0 → v0.26.0 → v0.27.0
  ↓         ↓          ↓         ↓
 安全     安全      需适配    必须适配

推荐方案：直接使用 IntRoot 适配器，支持所有版本
```

---

## 📚 相关文档

### 完整 API 文档
- [v0.21.0 完整 API 文档](./v0.21.0_API_Documentation.md)
- [v0.24.0 完整 API 文档](./v0.24.0_API_Documentation.md)
- [v0.26.0 完整 API 文档](./v0.26.0_API_Documentation.md)
- [v0.27.0 完整 API 文档](./v0.27.0_API_Documentation.md)

### 其他参考
- [API 版本演进总览](./Memos_API_Versions_0.21.0_to_latest.md)
- [IntRoot 兼容性分析](./IntRoot_Compatibility_Analysis.md)
- [API 版本差异](./API_Version_Differences.md)

---

**文档版本**: 1.0
**最后更新**: 2026-04-22
**维护者**: IntRoot Memos 适配器项目组
