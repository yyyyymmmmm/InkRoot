# InkRoot API Documentation

Complete API reference for InkRoot integration with Memos server.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Base URL](#base-url)
- [API Endpoints](#api-endpoints)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Examples](#examples)

---

## 🌐 Overview

InkRoot uses the Memos v1 API for server synchronization. This documentation covers all available API endpoints and their usage.

### Supported Versions

- **Memos API**: v1
- **Memos Server**: v0.21.0 only
- **Protocol**: HTTP/HTTPS
- **Format**: JSON

### API Characteristics

- **RESTful Design**: Standard REST API principles
- **JSON Format**: All requests and responses use JSON
- **Token Authentication**: JWT-based authentication
- **CORS Enabled**: Cross-origin requests supported

---

## 🔐 Authentication

### Authentication Methods

InkRoot uses JWT (JSON Web Token) authentication.

#### 1. User Login

**Endpoint**: `POST /api/v1/auth/signin`

**Request**:
```json
{
  "username": "your_username",
  "password": "your_password"
}
```

**Response**:
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

#### 2. User Registration

**Endpoint**: `POST /api/v1/auth/signup`

**Request**:
```json
{
  "username": "new_user",
  "password": "secure_password",
  "email": "user@example.com"
}
```

**Response**:
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

#### 3. Using Access Token

Include the access token in the `Authorization` header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🌍 Base URL

### Production
```
https://your-memos-server.com
```

### Local Development
```
http://localhost:5230
```

### Official Demo (Testing Only)
```
https://memos.didichou.site
```

---

## 📝 API Endpoints

### Notes (Memos)

#### Get Note List

**Endpoint**: `GET /api/v1/memo`

**Query Parameters**:
- `limit` (integer, optional): Number of notes to return (default: 20)
- `offset` (integer, optional): Pagination offset (default: 0)
- `tag` (string, optional): Filter by tag
- `visibility` (string, optional): Filter by visibility (PRIVATE, PUBLIC, PROTECTED)

**Request**:
```bash
GET /api/v1/memo?limit=20&offset=0
Authorization: Bearer {access_token}
```

**Response**:
```json
[
  {
    "id": 1,
    "creatorId": 1,
    "content": "# My First Note\n\nThis is a test note with **markdown**.",
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

#### Get Single Note

**Endpoint**: `GET /api/v1/memo/{id}`

**Request**:
```bash
GET /api/v1/memo/123
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "id": 123,
  "creatorId": 1,
  "content": "Note content here",
  "visibility": "PRIVATE",
  "pinned": false,
  "createdTs": 1640995200,
  "updatedTs": 1640995200
}
```

#### Create Note

**Endpoint**: `POST /api/v1/memo`

**Request**:
```json
{
  "content": "# New Note\n\nNote content with markdown support.",
  "visibility": "PRIVATE"
}
```

**Response**:
```json
{
  "id": 124,
  "creatorId": 1,
  "content": "# New Note\n\nNote content with markdown support.",
  "visibility": "PRIVATE",
  "pinned": false,
  "createdTs": 1640995200,
  "updatedTs": 1640995200
}
```

#### Update Note

**Endpoint**: `PATCH /api/v1/memo/{id}`

**Request**:
```json
{
  "content": "Updated content",
  "visibility": "PUBLIC"
}
```

**Response**:
```json
{
  "id": 124,
  "content": "Updated content",
  "visibility": "PUBLIC",
  "updatedTs": 1640995300
}
```

#### Delete Note

**Endpoint**: `DELETE /api/v1/memo/{id}`

**Request**:
```bash
DELETE /api/v1/memo/124
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "success": true
}
```

#### Pin/Unpin Note

**Endpoint**: `POST /api/v1/memo/{id}/organizer`

**Request**:
```json
{
  "pinned": true
}
```

**Response**:
```json
{
  "success": true,
  "pinned": true
}
```

---

### Resources (Images, Files)

#### Upload Resource

**Endpoint**: `POST /api/v1/resource/blob`

**Request**:
```bash
POST /api/v1/resource/blob
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

file: <binary_data>
```

**Response**:
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

#### Get Resource List

**Endpoint**: `GET /api/v1/resource`

**Query Parameters**:
- `limit` (integer, optional): Number of resources (default: 20)
- `offset` (integer, optional): Pagination offset (default: 0)

**Request**:
```bash
GET /api/v1/resource?limit=20&offset=0
Authorization: Bearer {access_token}
```

**Response**:
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

#### Get Resource

**Endpoint**: `GET /api/v1/resource/{id}`

**Request**:
```bash
GET /api/v1/resource/10
Authorization: Bearer {access_token}
```

**Response**: Binary file data

#### Delete Resource

**Endpoint**: `DELETE /api/v1/resource/{id}`

**Request**:
```bash
DELETE /api/v1/resource/10
Authorization: Bearer {access_token}
```

**Response**:
```json
{
  "success": true
}
```

---

### Tags

#### Get All Tags

**Endpoint**: `GET /api/v1/tag`

**Request**:
```bash
GET /api/v1/tag
Authorization: Bearer {access_token}
```

**Response**:
```json
[
  {
    "name": "work",
    "count": 15
  },
  {
    "name": "personal",
    "count": 8
  }
]
```

---

### User

#### Get Current User

**Endpoint**: `GET /api/v1/user/me`

**Request**:
```bash
GET /api/v1/user/me
Authorization: Bearer {access_token}
```

**Response**:
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

#### Update User Profile

**Endpoint**: `PATCH /api/v1/user/me`

**Request**:
```json
{
  "email": "newemail@example.com",
  "nickname": "New Nickname"
}
```

**Response**:
```json
{
  "id": 1,
  "username": "your_username",
  "email": "newemail@example.com",
  "nickname": "New Nickname",
  "updatedTs": 1640995300
}
```

---

## ❌ Error Handling

### Error Response Format

All errors follow this format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": "Additional error details"
}
```

### HTTP Status Codes

| Code | Description | Meaning |
|------|-------------|---------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict (e.g., duplicate) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Server temporarily unavailable |

### Common Error Codes

```json
// Invalid credentials
{
  "error": "Invalid username or password",
  "code": "INVALID_CREDENTIALS"
}

// Unauthorized access
{
  "error": "Authentication required",
  "code": "UNAUTHORIZED"
}

// Note not found
{
  "error": "Note not found",
  "code": "MEMO_NOT_FOUND"
}

// Rate limit exceeded
{
  "error": "Too many requests",
  "code": "RATE_LIMIT_EXCEEDED",
  "retryAfter": 60
}
```

---

## ⏱️ Rate Limiting

### Limits

- **Default**: 100 requests per minute per user
- **Authentication**: 10 requests per minute per IP
- **File Upload**: 20 requests per minute per user

### Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

### Handling Rate Limits

```dart
if (response.statusCode == 429) {
  final retryAfter = int.parse(
    response.headers['retry-after'] ?? '60'
  );
  await Future.delayed(Duration(seconds: retryAfter));
  // Retry request
}
```

---

## 💡 Examples

### Complete Workflow Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class MemosApiClient {
  final String baseUrl;
  String? _accessToken;

  MemosApiClient(this.baseUrl);

  // 1. Login
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
      throw Exception('Login failed');
    }
  }

  // 2. Get notes
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
      throw Exception('Failed to load notes');
    }
  }

  // 3. Create note
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
      throw Exception('Failed to create note');
    }
  }

  // 4. Upload image
  Future<Map<String, dynamic>> uploadImage(List<int> imageBytes, String filename) async {
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
      throw Exception('Failed to upload image');
    }
  }
}

// Usage
void main() async {
  final client = MemosApiClient('https://memos.example.com');
  
  // Login
  await client.login('username', 'password');
  
  // Get notes
  final notes = await client.getNotes();
  print('Loaded ${notes.length} notes');
  
  // Create note
  final newNote = await client.createNote('# Hello World\n\nMy first note!');
  print('Created note: ${newNote['id']}');
}
```

---

## 📚 Additional Resources

- [Memos GitHub Repository](https://github.com/usememos/memos)
- [Memos API Source Code](https://github.com/usememos/memos/tree/main/api)
- [OpenAPI Specification](openapi.yaml) _(planned)_

---

## 🤝 Contributing

Found an error in the documentation? Please [open an issue](https://github.com/yyyyymmmmm/IntRoot/issues) or submit a pull request.

---

<div align="center">

**API Documentation** | [InkRoot](https://github.com/yyyyymmmmm/IntRoot)

[Back to Main README](../../README.md)

</div>

