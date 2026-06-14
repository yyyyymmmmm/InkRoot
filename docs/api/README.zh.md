# InkRoot API 文档

InkRoot 与 Memos 服务器集成的完整 API 参考文档。

---

## 📋 目录

- [概述](#概述)
- [认证](#认证)
- [基础 URL](#基础-url)
- [API 端点](#api-端点)
- [错误处理](#错误处理)
- [速率限制](#速率限制)
- [示例](#示例)

---

## 🌐 概述

InkRoot 使用 Memos v1 API 进行服务器同步。本文档涵盖所有可用的 API 端点及其用法。

### 支持的版本

- **Memos API**: v1
- **Memos 服务器**: 已适配 v0.21.x 到 v0.28.x 的主要 API 差异
- **协议**: HTTP/HTTPS
- **格式**: JSON

### API 特性

- **RESTful 设计**: 标准 REST API 原则
- **JSON 格式**: 所有请求和响应使用 JSON
- **Token 认证**: 基于 JWT 的身份验证
- **支持 CORS**: 支持跨域请求

---

## 🔐 认证

### 认证方式

InkRoot 使用 JWT (JSON Web Token) 认证。

#### 1. 用户登录

**端点**: `POST /api/v1/auth/signin`

**请求**:
```json
{
  "username": "your_username",
  "password": "your_password"
}
```

**响应**:
```json
{
  "user": {
    "id": 1,
    "username": "your_username",
    "email": "user@example.com",
    "role": "USER",
    "createdTs": 1640995200,
    "updatedTs": 1640995200
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### 2. 用户注册

**端点**: `POST /api/v1/auth/signup`

**请求**:
```json
{
  "username": "new_user",
  "password": "secure_password",
  "email": "user@example.com"
}
```

**响应**:
```json
{
  "user": {
    "id": 2,
    "username": "new_user",
    "email": "user@example.com",
    "role": "USER",
    "createdTs": 1640995200,
    "updatedTs": 1640995200
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### 3. 使用访问令牌

在 `Authorization` 请求头中包含访问令牌：

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🌍 基础 URL

### 生产环境
```
https://your-memos-server.com
```

### 本地开发
```
http://localhost:5230
```

### 官方演示（仅测试）
```
https://memos.didichou.site
```

---

## 📝 API 端点

### 笔记 (Memos)

#### 获取笔记列表

**端点**: `GET /api/v1/memo`

**查询参数**:
- `limit` (整数, 可选): 返回笔记数量 (默认: 20)
- `offset` (整数, 可选): 分页偏移量 (默认: 0)
- `tag` (字符串, 可选): 按标签过滤
- `visibility` (字符串, 可选): 按可见性过滤 (PRIVATE, PUBLIC, PROTECTED)

**请求**:
```bash
GET /api/v1/memo?limit=20&offset=0
Authorization: Bearer {access_token}
```

**响应**:
```json
[
  {
    "id": 1,
    "creatorId": 1,
    "content": "# 我的第一条笔记\n\n这是一条带有 **markdown** 的测试笔记。",
    "visibility": "PRIVATE",
    "pinned": false,
    "createdTs": 1640995200,
    "updatedTs": 1640995200,
    "resourceList": [
      {
        "id": 1,
        "filename": "image.png",
        "type": "image/png",
        "size": 12345
      }
    ],
    "relationList": []
  }
]
```

#### 获取单条笔记

**端点**: `GET /api/v1/memo/{id}`

**请求**:
```bash
GET /api/v1/memo/123
Authorization: Bearer {access_token}
```

**响应**:
```json
{
  "id": 123,
  "creatorId": 1,
  "content": "笔记内容",
  "visibility": "PRIVATE",
  "pinned": false,
  "createdTs": 1640995200,
  "updatedTs": 1640995200
}
```

#### 创建笔记

**端点**: `POST /api/v1/memo`

**请求**:
```json
{
  "content": "# 新笔记\n\n支持 markdown 语法的笔记内容。",
  "visibility": "PRIVATE"
}
```

**响应**:
```json
{
  "id": 124,
  "creatorId": 1,
  "content": "# 新笔记\n\n支持 markdown 语法的笔记内容。",
  "visibility": "PRIVATE",
  "pinned": false,
  "createdTs": 1640995200,
  "updatedTs": 1640995200
}
```

#### 更新笔记

**端点**: `PATCH /api/v1/memo/{id}`

**请求**:
```json
{
  "content": "更新后的内容",
  "visibility": "PUBLIC"
}
```

**响应**:
```json
{
  "id": 124,
  "content": "更新后的内容",
  "visibility": "PUBLIC",
  "updatedTs": 1640995300
}
```

#### 删除笔记

**端点**: `DELETE /api/v1/memo/{id}`

**请求**:
```bash
DELETE /api/v1/memo/124
Authorization: Bearer {access_token}
```

**响应**:
```json
{
  "success": true
}
```

#### 置顶/取消置顶笔记

**端点**: `POST /api/v1/memo/{id}/organizer`

**请求**:
```json
{
  "pinned": true
}
```

**响应**:
```json
{
  "success": true,
  "pinned": true
}
```

---

### 资源 (图片、文件)

#### 上传资源

**端点**: `POST /api/v1/resource/blob`

**请求**:
```bash
POST /api/v1/resource/blob
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

file: <二进制数据>
```

**响应**:
```json
{
  "id": 10,
  "filename": "image.png",
  "type": "image/png",
  "size": 123456,
  "createdTs": 1640995200,
  "publicId": "abc123xyz",
  "downloadUrl": "/api/v1/resource/10/download"
}
```

#### 获取资源列表

**端点**: `GET /api/v1/resource`

**查询参数**:
- `limit` (整数, 可选): 资源数量 (默认: 20)
- `offset` (整数, 可选): 分页偏移量 (默认: 0)

**请求**:
```bash
GET /api/v1/resource?limit=20&offset=0
Authorization: Bearer {access_token}
```

**响应**:
```json
[
  {
    "id": 10,
    "filename": "image.png",
    "type": "image/png",
    "size": 123456,
    "createdTs": 1640995200
  }
]
```

#### 获取资源

**端点**: `GET /api/v1/resource/{id}`

**请求**:
```bash
GET /api/v1/resource/10
Authorization: Bearer {access_token}
```

**响应**: 二进制文件数据

#### 删除资源

**端点**: `DELETE /api/v1/resource/{id}`

**请求**:
```bash
DELETE /api/v1/resource/10
Authorization: Bearer {access_token}
```

**响应**:
```json
{
  "success": true
}
```

---

### 标签

#### 获取所有标签

**端点**: `GET /api/v1/tag`

**请求**:
```bash
GET /api/v1/tag
Authorization: Bearer {access_token}
```

**响应**:
```json
[
  {
    "name": "工作",
    "count": 15
  },
  {
    "name": "个人",
    "count": 8
  }
]
```

---

### 用户

#### 获取当前用户

**端点**: `GET /api/v1/user/me`

**请求**:
```bash
GET /api/v1/user/me
Authorization: Bearer {access_token}
```

**响应**:
```json
{
  "id": 1,
  "username": "your_username",
  "email": "user@example.com",
  "role": "USER",
  "createdTs": 1640995200,
  "updatedTs": 1640995200
}
```

#### 更新用户资料

**端点**: `PATCH /api/v1/user/me`

**请求**:
```json
{
  "email": "newemail@example.com",
  "nickname": "新昵称"
}
```

**响应**:
```json
{
  "id": 1,
  "username": "your_username",
  "email": "newemail@example.com",
  "nickname": "新昵称",
  "updatedTs": 1640995300
}
```

---

## ❌ 错误处理

### 错误响应格式

所有错误遵循以下格式：

```json
{
  "error": "错误消息",
  "code": "ERROR_CODE",
  "details": "额外的错误详情"
}
```

### HTTP 状态码

| 代码 | 说明 | 含义 |
|------|------|------|
| 200 | OK | 请求成功 |
| 201 | Created | 资源创建成功 |
| 400 | Bad Request | 请求参数无效 |
| 401 | Unauthorized | 缺少或无效的身份验证 |
| 403 | Forbidden | 权限不足 |
| 404 | Not Found | 资源未找到 |
| 409 | Conflict | 资源冲突（如重复） |
| 429 | Too Many Requests | 超过速率限制 |
| 500 | Internal Server Error | 服务器错误 |
| 503 | Service Unavailable | 服务暂时不可用 |

### 常见错误代码

```json
// 无效凭据
{
  "error": "用户名或密码无效",
  "code": "INVALID_CREDENTIALS"
}

// 未授权访问
{
  "error": "需要身份验证",
  "code": "UNAUTHORIZED"
}

// 笔记未找到
{
  "error": "笔记未找到",
  "code": "MEMO_NOT_FOUND"
}

// 超过速率限制
{
  "error": "请求过多",
  "code": "RATE_LIMIT_EXCEEDED",
  "retryAfter": 60
}
```

---

## ⏱️ 速率限制

### 限制

- **默认**: 每用户每分钟 100 次请求
- **认证**: 每 IP 每分钟 10 次请求
- **文件上传**: 每用户每分钟 20 次请求

### 速率限制响应头

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

### 处理速率限制

```dart
if (response.statusCode == 429) {
  final retryAfter = int.parse(
    response.headers['retry-after'] ?? '60'
  );
  await Future.delayed(Duration(seconds: retryAfter));
  // 重试请求
}
```

---

## 💡 示例

### 完整工作流示例

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class MemosApiClient {
  final String baseUrl;
  String? _accessToken;

  MemosApiClient(this.baseUrl);

  // 1. 登录
  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
    } else {
      throw Exception('登录失败');
    }
  }

  // 2. 获取笔记
  Future<List<dynamic>> getNotes({int limit = 20, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/memo?limit=$limit&offset=$offset'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('加载笔记失败');
    }
  }

  // 3. 创建笔记
  Future<Map<String, dynamic>> createNote(String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/memo'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': content,
        'visibility': 'PRIVATE',
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('创建笔记失败');
    }
  }

  // 4. 上传图片
  Future<Map<String, dynamic>> uploadImage(
    List<int> imageBytes,
    String filename,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/resource/blob'),
    );
    
    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('上传图片失败');
    }
  }
}

// 使用示例
void main() async {
  final client = MemosApiClient('https://memos.example.com');
  
  // 登录
  await client.login('username', 'password');
  
  // 获取笔记
  final notes = await client.getNotes();
  print('加载了 ${notes.length} 条笔记');
  
  // 创建笔记
  final newNote = await client.createNote('# 你好世界\n\n我的第一条笔记！');
  print('创建笔记: ${newNote['id']}');
}
```

---

## 📚 其他资源

- [Memos GitHub 仓库](https://github.com/usememos/memos)
- [Memos API 源代码](https://github.com/usememos/memos/tree/main/api)
- [OpenAPI 规范](openapi.yaml) _(计划中)_
- [English API Documentation](README.md) - 英文版 API 文档

---

## 🤝 贡献

文档中发现错误？请[提交 issue](https://github.com/yyyyymmmmm/InkRoot/issues) 或提交 pull request。

---

<div align="center">

**API 文档** | [InkRoot](https://github.com/yyyyymmmmm/InkRoot)

[返回主 README](../../README.md) | [English Version](README.md)

</div>
