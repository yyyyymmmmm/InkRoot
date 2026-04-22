# Memos API 多版本适配器 - 完整实现

<div align="center">

**IntRoot 项目的 Memos API 兼容层**

支持 Memos v0.21.0 - v0.27.1 的所有版本

[文档](#-文档) • [快速开始](#-快速开始) • [测试](#-测试) • [贡献](#-贡献)

</div>

---

## 📖 概述

本项目为 IntRoot Flutter 应用提供了一个完整的 Memos API 多版本适配器，实现了从 v0.21.0 到 v0.27.1 的全版本兼容。通过适配器模式（Adapter Pattern）+ 工厂模式（Factory Pattern）的设计，自动检测 Memos 服务器版本并选择合适的适配器。

### 核心特性

- ✅ **自动版本检测** - 通过3级检测机制自动识别服务器版本
- ✅ **零破坏性集成** - 保持原有 API 接口不变，内部使用适配器
- ✅ **完整版本覆盖** - 支持23个Memos版本（v0.21.0 - v0.27.1）
- ✅ **Token自动刷新** - v0.26.0+ 自动处理Token过期和刷新
- ✅ **类型安全** - 完整的Dart类型注解和空安全
- ✅ **Docker测试环境** - 4版本并行测试环境，60+测试用例
- ✅ **完整文档** - 每个版本的API文档、对比分析、迁移指南

---

## 🏗️ 架构设计

### 适配器继承链

```
IMemosApi (抽象接口)
    ↓
MemosApiV21 (基线实现, v0.21.0-v0.25.x)
    ↓
MemosApiV26 (Token刷新, v0.26.0-v0.26.2)
    ↓
MemosApiV27 (Username路径, v0.27.0-v0.27.1)
```

### 版本映射

| Memos 版本 | 适配器 | 关键特性 |
|-----------|-------|---------|
| v0.21.0 - v0.25.x | MemosApiV21 | 基础API、格式兼容处理 |
| v0.26.0 - v0.26.2 | MemosApiV26 | + Token自动刷新机制 |
| v0.27.0 - v0.27.1 | MemosApiV27 | + username路径 + SSE + PAT |

### 文件结构

```
IntRoot-main/
├── lib/services/
│   ├── memos_api_interface.dart       # 统一接口定义
│   ├── memos_api_v21.dart            # v0.21 基线实现
│   ├── memos_api_v26.dart            # v0.26 Token刷新
│   ├── memos_api_v27.dart            # v0.27 Username路径
│   ├── memos_api_factory.dart        # 工厂类（版本检测）
│   └── memos_api_service_fixed.dart  # IntRoot兼容层
├── docs/
│   ├── FIXES_DETAILED.md             # 修复详情文档
│   └── memos_api/
│       ├── API_VERSION_TIMELINE.md        # 完整版本演进时间线⭐
│       ├── API_COMPLETE_COMPARISON.md     # 完整API对比
│       ├── v0.21.0_API_Documentation.md   # v0.21.0 完整API
│       ├── v0.24.0_API_Documentation.md   # v0.24.0 完整API
│       ├── v0.26.0_API_Documentation.md   # v0.26.0 完整API
│       ├── v0.27.0_API_Documentation.md   # v0.27.0 完整API
│       ├── API_Version_Differences.md     # 版本差异详解
│       └── IntRoot_Compatibility_Analysis.md
├── docker/
│   ├── docker-compose.yml            # 4版本测试环境
│   └── manage.sh                     # 环境管理脚本
├── test/
│   ├── api_compatibility_test.dart   # 60+测试用例
│   └── .env.example                  # 测试配置模板
├── .gitignore                        # Git忽略规则（含.env）
├── pubspec.yaml                      # Dart依赖配置
└── README.md                         # 本文件
```

---

## 🚀 快速开始

### 1. 依赖安装

```bash
# 进入项目目录
cd IntRoot-main

# 安装Dart依赖
flutter pub get
```

### 2. 配置测试环境

```bash
# 复制环境变量模板
cp test/.env.example test/.env

# 编辑配置（可选，默认配置已可用）
vim test/.env
```

### 3. 启动Docker测试环境

```bash
cd docker

# 启动所有版本服务
./manage.sh start

# 等待服务就绪
./manage.sh status

# 为每个版本创建测试用户
./manage.sh create-user
```

### 4. 运行测试

```bash
cd ..
dart test/api_compatibility_test.dart
```

---

## 🧪 测试

### 测试覆盖

- ✅ **版本检测测试**（4个版本）
- ✅ **认证测试**（登录/登出）
- ✅ **Memo CRUD测试**（创建/读取/更新/删除）
- ✅ **用户信息测试**
- ✅ **Token刷新测试**（v0.26+）
- ✅ **类型安全测试**（ID格式验证）
- **总计：60+ 测试用例**

### Docker测试环境管理

```bash
# 查看状态
./docker/manage.sh status

# 查看日志
./docker/manage.sh logs v21    # 查看v0.21.0日志
./docker/manage.sh logs v27    # 查看v0.27.1日志

# 停止环境
./docker/manage.sh stop

# 清理数据（重置到初始状态）
./docker/manage.sh clean
```

### 测试配置（.env）

```env
# v0.21.0 测试服务器
MEMOS_V21_BASE_URL=http://localhost:5230
MEMOS_V21_USERNAME=testuser
MEMOS_V21_PASSWORD=testpass123

# v0.24.0 测试服务器
MEMOS_V24_BASE_URL=http://localhost:5231
MEMOS_V24_USERNAME=testuser
MEMOS_V24_PASSWORD=testpass123

# v0.26.0 测试服务器
MEMOS_V26_BASE_URL=http://localhost:5232
MEMOS_V26_USERNAME=testuser
MEMOS_V26_PASSWORD=testpass123

# v0.27.1 测试服务器
MEMOS_V27_BASE_URL=http://localhost:5233
MEMOS_V27_USERNAME=testuser
MEMOS_V27_PASSWORD=testpass123
```

---

## 📚 文档

### 必读文档

1. **[API_VERSION_TIMELINE.md](docs/memos_api/API_VERSION_TIMELINE.md)** ⭐
   - 23个版本完整演进时间线
   - 每个版本的Breaking Changes详解
   - IntRoot兼容性分析

2. **[API_COMPLETE_COMPARISON.md](docs/memos_api/API_COMPLETE_COMPARISON.md)**
   - 160+ API端点完整对比
   - 请求/响应格式变化
   - 升级建议和迁移路径

3. **[FIXES_DETAILED.md](docs/FIXES_DETAILED.md)**
   - 类型安全修复详情
   - 测试用例修复说明
   - 代码审查要点

### 版本文档

- [v0.21.0 API 完整文档](docs/memos_api/v0.21.0_API_Documentation.md)
- [v0.24.0 API 完整文档](docs/memos_api/v0.24.0_API_Documentation.md)
- [v0.26.0 API 完整文档](docs/memos_api/v0.26.0_API_Documentation.md)
- [v0.27.0 API 完整文档](docs/memos_api/v0.27.0_API_Documentation.md)

---

## 🔑 核心API使用示例

### 自动版本检测

```dart
import 'services/memos_api_factory.dart';

// 自动检测版本并创建适配器
final api = await MemosApiFactory.create('https://your-memos-server.com');
print('检测到版本: ${api.adapterVersion}');
```

### 登录认证

```dart
// 登录（自动处理Token）
final result = await api.login('username', 'password');
print('登录成功，用户名: ${result['username']}');

// v0.26.0+ 自动处理Token刷新，无需手动调用
```

### Memo操作

```dart
// 创建Memo
final memo = await api.createMemo(
  content: 'Hello, Memos!',
  visibility: 'PRIVATE',
);

// 获取Memo（类型安全）
final fetchedMemo = await api.getMemo(memo['id'] as int);

// 更新Memo
await api.updateMemo(
  memoId: memo['id'] as int,
  content: 'Updated content',
);

// 删除Memo
await api.deleteMemo(memo['id'] as int);
```

---

## ⚠️ 重要注意事项

### Breaking Changes

| 版本 | 变更内容 | 影响 | 适配方案 |
|------|---------|------|---------|
| v0.22.0 | API v1不兼容更新 | 响应格式变化 | ✅ MemosApiV21自动处理 |
| v0.24.0 | 数据库&API变更 | 部分端点调整 | ⚠️ 需测试验证 |
| v0.25.0 | 数据库&API变更 | 部分端点调整 | ⚠️ 需测试验证 |
| v0.26.0 | Token刷新机制 | 新增Refresh Token | ✅ MemosApiV26自动刷新 |
| v0.27.0 | 用户路径变更 | ID→username | ✅ MemosApiV27自动转换 |

### 安全提示

1. **绝不提交 .env 文件到版本控制**
   - `.gitignore` 已配置忽略所有 `.env` 文件
   - 生产环境密钥请使用环境变量注入

2. **Token安全**
   - Access Token 和 Refresh Token 存储在内存
   - 登出时自动清除Token

3. **测试环境隔离**
   - Docker测试环境与生产环境严格隔离
   - 使用专用测试账号

---

## 🛠️ 开发指南

### 添加新版本支持

1. 检查新版本的Breaking Changes
2. 决定是创建新适配器还是扩展现有适配器
3. 继承合适的基类（通常是最新适配器）
4. 覆盖有变化的方法
5. 更新 `MemosApiFactory._detectVersion()`
6. 添加测试用例
7. 更新文档

### 代码风格

- 遵循 Dart 官方风格指南
- 所有公开方法必须有文档注释
- 类型安全优先（避免使用 `dynamic`）
- 异常处理要具体（不要吞掉异常）

---

## 🤝 贡献

欢迎提交Issue和Pull Request！

### 提交前检查清单

- [ ] 代码通过 `dart analyze`
- [ ] 测试通过 `dart test/api_compatibility_test.dart`
- [ ] 更新相关文档
- [ ] 提交信息清晰（遵循 Conventional Commits）

---

## 📄 许可证

本项目遵循 IntRoot 项目的许可证。

---

## 🙏 致谢

- [Memos](https://github.com/usememos/memos) - 优秀的开源笔记应用
- IntRoot 开发团队
- 所有贡献者

---

**最后更新**: 2026-04-22
**维护者**: IntRoot 开发团队
**项目状态**: ✅ 生产就绪
