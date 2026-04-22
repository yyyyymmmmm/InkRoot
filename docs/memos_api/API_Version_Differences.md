# Memos API 版本差异对比文档

> 对比范围：v0.21.0 → v0.27.1
> 更新日期：2026-04-22

---

## 📊 版本差异总览

### API 端点路径变化

| 版本 | API 路径前缀 | 说明 |
|------|------------|------|
| v0.21.0 | `/api/v1/` | 引入 v1 API |
| v0.22.0 - v0.23.0 | `/api/v1/` | 保持不变 |
| v0.24.0 | `/api/v1/` + 新增快捷方式端点 | 新增 `/api/v1/shortcut` |
| v0.25.0 - v0.27.0 | `/api/v1/` | 保持不变 |

**结论**: ✅ **API 路径前缀稳定**，v0.21.0 的 `/api/v1/` 路径在所有后续版本中保持兼容。

---

## 🔐 认证机制演进

### v0.21.0 - v0.25.0：基础认证
```javascript
// 登录
POST /api/v1/auth/signin
{
  "username": "user",
  "password": "pass"
}

// 响应
{
  "user": {...},
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

// 使用
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**特点**
- ✅ 单一 Access Token
- ❌ 无自动刷新
- ❌ Token 过期需要重新登录

### v0.26.0+：刷新令牌轮换
```javascript
// 登录
POST /api/v1/auth/signin
{
  "username": "user",
  "password": "pass"
}

// 响应
{
  "user": {...},
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresAt": 1234567890
}

// 刷新
POST /api/v1/auth/refresh
{
  "refreshToken": "eyJ..."
}
```

**特点**
- ✅ Access Token（短期）+ Refresh Token（长期）
- ✅ 自动令牌轮换
- ✅ 跨标签页同步
- ✅ 更高安全性

### v0.27.0+：新增 PAT
```javascript
// 创建 Personal Access Token
POST /api/v1/user/access-tokens
{
  "description": "MCP Integration",
  "expiresAt": 1735689600
}

// 响应
{
  "accessToken": "memos_pat_xxxxxx"
}
```

**用途**
- MCP 集成
- 第三方应用
- 长期 API 访问

---

## 📝 备忘录 API 差异

### 基础 CRUD（✅ 全版本兼容）

| 接口 | v0.21.0 | v0.24.0 | v0.26.0 | v0.27.0 | 兼容性 |
|------|---------|---------|---------|---------|--------|
| `POST /api/v1/memo` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `GET /api/v1/memo` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `GET /api/v1/memo/{id}` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `PATCH /api/v1/memo/{id}` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |
| `DELETE /api/v1/memo/{id}` | ✅ | ✅ | ✅ | ✅ | ✅ 完全兼容 |

### 组织状态（置顶）

| 接口 | v0.21.0 | v0.24.0 | v0.26.0 | v0.27.0 |
|------|---------|---------|---------|---------|
| `POST /api/v1/memo/{id}/organizer` | ✅ | ✅ | ✅ | ✅ |

**请求格式保持不变**：
```json
{
  "pinned": true
}
```

### v0.24.0 新增：快捷方式过滤

```javascript
// 查询参数新增
GET /api/v1/memo?shortcutId=1
```

**向后兼容**：旧客户端可以忽略此参数，不影响基础功能。

### v0.27.0 新增：提及过滤

```javascript
// 查询参数新增
GET /api/v1/memo?mentionedMe=true
```

---

## 👤 用户 API 差异

### 获取用户信息（✅ 全版本兼容）

| 接口 | v0.21.0 - v0.27.0 | 兼容性 |
|------|------------------|--------|
| `GET /api/v1/user/me` | ✅ 保持一致 | ✅ 完全兼容 |

### 角色名称变更

| 版本 | 角色名称 | 迁移 |
|------|---------|------|
| v0.21.0 - v0.25.0 | `HOST`, `USER` | - |
| v0.26.0+ | `ADMIN`, `USER` | ✅ 自动迁移 |

**客户端兼容性处理**：
```javascript
function isAdmin(user) {
  // ✅ 兼容两种角色名称
  return user.role === 'ADMIN' || user.role === 'HOST';
}
```

### 用户资源名称变更（⚠️ v0.27.0 Breaking）

| 版本 | 格式 | 示例 |
|------|------|------|
| v0.21.0 - v0.26.0 | `users/{id}` | `users/1` |
| v0.27.0+ | `users/{username}` | `users/alice` |

**兼容性影响**：
- ❌ 如果代码中硬编码了 `users/1` 格式，需要更新
- ❌ 如果根据用户 ID 构造 API 路径，需要改用 username

---

## 🆕 新增功能对比

### v0.24.0：快捷方式系统

**新增 API**：
- `POST /api/v1/shortcut` - 创建快捷方式
- `GET /api/v1/shortcut` - 获取快捷方式列表
- `GET /api/v1/shortcut/{id}` - 获取快捷方式
- `PATCH /api/v1/shortcut/{id}` - 更新快捷方式
- `DELETE /api/v1/shortcut/{id}` - 删除快捷方式

**向后兼容性**: ✅ 不影响旧客户端

### v0.26.0：媒体增强

**新特性**：
- 视频/音频流式传输
- HDR 图像和视频支持
- 图片 EXIF 元数据剥离
- 用户档案地图视图

**向后兼容性**: ✅ 媒体访问接口不变

### v0.27.0：实时通信与 AI

**新增 API**：
- `GET /api/v1/sse` - Server-Sent Events
- `POST /api/v1/memo/voice-note` - 语音笔记
- `POST /api/v1/transcribe` - AI 转录
- `POST /mcp` - MCP 服务器
- `POST /api/v1/memo/{id}/share` - 分享链接
- `GET /api/v1/notifications` - 通知列表

**Breaking Changes**：
- ❌ 移除 `/api/v1/activities` (改用 `/api/v1/notifications`)
- ⚠️ 用户资源名称格式变更

---

## ⚠️ Breaking Changes 汇总

### v0.21.0 → v0.26.0

✅ **无 Breaking Changes**
- 所有接口向后兼容
- 角色名称自动迁移
- 认证机制升级但保持兼容

### v0.26.0 → v0.27.0

❌ **有 Breaking Changes**

1. **用户资源名称**
   - 旧: `users/1`
   - 新: `users/alice`
   - 影响: 硬编码路径的代码需要更新

2. **ActivityService 移除**
   - 旧: `GET /api/v1/activities`
   - 新: `GET /api/v1/notifications`
   - 影响: 使用活动流的代码需要迁移

3. **身份提供商资源名称**
   - 使用 UID 替代自增 ID
   - 影响: SSO 集成需要更新

---

## 📦 数据库架构变更

### v0.24.0

**新增表**：
```sql
CREATE TABLE shortcut (
  id INTEGER PRIMARY KEY,
  creator_id INTEGER,
  name TEXT,
  filter TEXT,
  is_pinned BOOLEAN,
  created_ts BIGINT,
  updated_ts BIGINT
);
```

### v0.26.0

**角色迁移**：
```sql
UPDATE user SET role = 'ADMIN' WHERE role = 'HOST';
```

### v0.27.0

**新增表**：
```sql
CREATE TABLE notification (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  type TEXT,
  content TEXT,
  memo_id INTEGER,
  actor_id INTEGER,
  read BOOLEAN,
  created_at BIGINT
);

CREATE TABLE share_link (
  id INTEGER PRIMARY KEY,
  memo_id INTEGER,
  share_token TEXT UNIQUE,
  expires_at BIGINT,
  allow_comments BOOLEAN,
  created_at BIGINT
);
```

---

## 🔄 响应格式差异

### 成功响应（✅ 全版本一致）

```json
{
  "id": 100,
  "content": "Memo content",
  "visibility": "PRIVATE",
  "createdTs": 1234567890,
  "updatedTs": 1234567891
}
```

### 错误响应

#### v0.21.0 - v0.25.0
```json
{
  "error": "Memo not found"
}
```

#### v0.26.0+（gRPC 风格）
```json
{
  "code": "NOT_FOUND",
  "message": "Memo not found"
}
```

**兼容性处理**：
```javascript
function handleError(response) {
  const data = await response.json();

  // ✅ 兼容两种错误格式
  const message = data.message || data.error;
  const code = data.code || response.status;

  throw new Error(`${code}: ${message}`);
}
```

---

## 🎯 查询参数对比

### GET /api/v1/memo 支持的参数

| 参数 | v0.21.0 | v0.24.0 | v0.26.0 | v0.27.0 | 说明 |
|------|---------|---------|---------|---------|------|
| `limit` | ✅ | ✅ | ✅ | ✅ | 每页数量 |
| `offset` | ✅ | ✅ | ✅ | ✅ | 偏移量 |
| `tag` | ✅ | ✅ | ✅ | ✅ | 标签过滤 |
| `visibility` | ✅ | ✅ | ✅ | ✅ | 可见性过滤 |
| `createdTsAfter` | ✅ | ✅ | ✅ | ✅ | 时间范围 |
| `createdTsBefore` | ✅ | ✅ | ✅ | ✅ | 时间范围 |
| `content` | ✅ | ✅ | ✅ | ✅ | 内容搜索 |
| `shortcutId` | ❌ | ✅ | ✅ | ✅ | 快捷方式过滤 |
| `mentionedMe` | ❌ | ❌ | ❌ | ✅ | 提及过滤 |

**向后兼容性**: ✅ 旧参数在新版本中继续有效

---

## 📊 功能可用性矩阵

| 功能 | v0.21.0 | v0.24.0 | v0.26.0 | v0.27.0 |
|------|---------|---------|---------|---------|
| 备忘录 CRUD | ✅ | ✅ | ✅ | ✅ |
| 用户认证 | ✅ Token | ✅ Token | ✅ Token + Refresh | ✅ Token + PAT |
| 附件上传 | ✅ | ✅ | ✅ 流式 | ✅ 流式 |
| 标签系统 | ✅ | ✅ | ✅ | ✅ 增强 |
| 搜索过滤 | ✅ 基础 | ✅ 基础 | ✅ 基础 | ✅ 基础 |
| 快捷方式 | ❌ | ✅ | ✅ | ✅ |
| 评论系统 | ✅ | ✅ | ✅ | ✅ |
| 反应系统 | ✅ | ✅ | ✅ | ✅ |
| 地图视图 | ❌ | ❌ | ✅ | ✅ |
| HDR 媒体 | ❌ | ❌ | ✅ | ✅ |
| 实时更新(SSE) | ❌ | ❌ | ❌ | ✅ |
| 语音笔记 | ❌ | ❌ | ❌ | ✅ |
| AI 转录 | ❌ | ❌ | ❌ | ✅ |
| MCP 集成 | ❌ | ❌ | ❌ | ✅ |
| 备忘录分享 | ❌ | ❌ | ❌ | ✅ |
| 提及功能 | ❌ | ❌ | ❌ | ✅ |

---

## 🔧 兼容性适配策略

### 策略 1：最小版本支持（推荐）

**目标**: 支持 v0.21.0+
**方法**: 只使用所有版本共有的接口

```javascript
class MemosApiClient {
  // ✅ 核心接口（v0.21.0+）
  async createMemo(content, visibility) {
    return fetch('/api/v1/memo', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ content, visibility })
    });
  }

  async getMemos(params = {}) {
    const query = new URLSearchParams(params);
    return fetch(`/api/v1/memo?${query}`, {
      headers: { 'Authorization': `Bearer ${this.token}` }
    });
  }

  async updateMemo(id, content, visibility) {
    return fetch(`/api/v1/memo/${id}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ content, visibility })
    });
  }

  async deleteMemo(id) {
    return fetch(`/api/v1/memo/${id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${this.token}` }
    });
  }
}
```

### 策略 2：版本检测 + 特性降级

**目标**: 检测服务器版本，动态启用高级功能

```javascript
class MemosApiClient {
  constructor(baseUrl, token) {
    this.baseUrl = baseUrl;
    this.token = token;
    this.version = null;
    this.features = {};
  }

  async detectVersion() {
    try {
      // 尝试访问 SSE 端点
      const sseResponse = await fetch(`${this.baseUrl}/api/v1/sse`, {
        headers: { 'Authorization': `Bearer ${this.token}` }
      });

      if (sseResponse.status !== 404) {
        this.version = '0.27.0';
        this.features.sse = true;
        this.features.voiceNote = true;
        this.features.mcp = true;
        this.features.share = true;
        return;
      }
    } catch (e) {}

    try {
      // 尝试访问快捷方式端点
      const shortcutResponse = await fetch(`${this.baseUrl}/api/v1/shortcut`, {
        headers: { 'Authorization': `Bearer ${this.token}` }
      });

      if (shortcutResponse.status !== 404) {
        this.version = '0.24.0';
        this.features.shortcuts = true;
        return;
      }
    } catch (e) {}

    // 默认为 v0.21.0
    this.version = '0.21.0';
  }

  async getMemos(params = {}) {
    // 如果支持快捷方式且提供了 shortcutId
    if (this.features.shortcuts && params.shortcutId) {
      return this._getMemosWithShortcut(params);
    }

    // 降级到基础查询
    return this._getMemosBasic(params);
  }

  async enableRealtimeUpdates(callbacks) {
    if (!this.features.sse) {
      console.warn('SSE not supported, falling back to polling');
      this._startPolling(callbacks);
      return;
    }

    this._connectSSE(callbacks);
  }
}
```

### 策略 3：多版本适配层

**目标**: 为不同版本提供统一接口

```javascript
class MemosApiAdapter {
  constructor(baseUrl, token, version) {
    this.client = this._createClient(baseUrl, token, version);
  }

  _createClient(baseUrl, token, version) {
    if (version.startsWith('0.27')) {
      return new MemosApiV27(baseUrl, token);
    } else if (version.startsWith('0.26')) {
      return new MemosApiV26(baseUrl, token);
    } else if (version.startsWith('0.24')) {
      return new MemosApiV24(baseUrl, token);
    } else {
      return new MemosApiV21(baseUrl, token);
    }
  }

  // 统一接口
  async createMemo(content, visibility) {
    return this.client.createMemo(content, visibility);
  }

  async getMemos(params) {
    return this.client.getMemos(params);
  }

  // 特性检测
  supportsFeature(feature) {
    return this.client.supportsFeature(feature);
  }
}
```

---

## 📋 兼容性检查清单

### 必须检查的项目

#### ✅ 认证相关
- [ ] Token 格式（Bearer Token）
- [ ] Token 刷新机制（v0.26.0+）
- [ ] 错误处理（401 / 403）

#### ✅ API 端点
- [ ] `/api/v1/memo` CRUD 操作
- [ ] `/api/v1/user/me` 用户信息
- [ ] `/api/v1/auth/signin` 登录
- [ ] `/api/v1/auth/signout` 登出

#### ⚠️ 角色名称
- [ ] 兼容 `HOST` 和 `ADMIN`
- [ ] 权限判断逻辑

#### ⚠️ 用户资源名称（v0.27.0）
- [ ] 避免硬编码 `users/1` 格式
- [ ] 使用 `username` 而非 `userId`

#### ⚠️ 错误格式
- [ ] 兼容旧错误格式（`error`）
- [ ] 兼容新错误格式（`code`/`message`）

---

## 🎯 推荐升级路径

### 路径 1：保守升级
```
v0.21.0 → v0.24.0 → v0.26.0 → v0.27.0
```
- 每次升级测试核心功能
- 逐步启用新特性
- 最稳妥但耗时较长

### 路径 2：跳跃升级
```
v0.21.0 → v0.26.0 → v0.27.0
```
- 跳过 v0.24.0（快捷方式可选）
- 重点测试认证机制变更
- 适合不需要快捷方式的项目

### 路径 3：直接最新
```
v0.21.0 → v0.27.1
```
- 一次性升级到最新版
- 需要完整测试所有功能
- 适合新项目或重构

---

## 🔗 相关资源

- **官方迁移指南**: https://www.usememos.com/docs/migration
- **API 文档**: https://www.usememos.com/docs/api
- **更新日志**: https://www.usememos.com/changelog
- **GitHub Releases**: https://github.com/usememos/memos/releases

---

*文档版本：1.0 | 最后更新：2026-04-22*
