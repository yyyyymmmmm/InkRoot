# Memos API 完整版本兼容性验证报告

## 📊 测试覆盖范围

### 测试版本（7个主版本）

| 序号 | 测试版本 | 代表版本系列 | 端口 | 关键特性 | 兼容性状态 |
|-----|---------|------------|------|---------|----------|
| 1 | v0.21.0 | v0.21.x (1个版本) | 5230 | 基线版本 | ✅ 已验证 |
| 2 | v0.22.5 | v0.22.x (6个版本) | 5231 | API v1不兼容更新 | 🔄 需测试 |
| 3 | v0.23.1 | v0.23.x (2个版本) | 5232 | 标签重构 | 🔄 需测试 |
| 4 | v0.24.4 | v0.24.x (5个版本) | 5233 | 数据库&API变更 | 🔄 需测试 |
| 5 | v0.25.3 | v0.25.x (4个版本) | 5234 | 数据库&API变更 | 🔄 需测试 |
| 6 | v0.26.2 | v0.26.x (3个版本) | 5235 | Token刷新机制 | ✅ 已验证 |
| 7 | v0.27.1 | v0.27.x (2个版本) | 5236 | Username路径变更 | ✅ 已验证 |

**总计**: 7个测试版本，代表23个实际版本

---

## 🎯 测试策略

### 为什么选择这7个版本？

1. **v0.21.0** - 基线版本，所有API的起点
2. **v0.22.5** - v0.22系列最稳定版本，验证第一个Breaking Change（API v1不兼容更新）
3. **v0.23.1** - 验证标签重构（property→payload）的兼容性
4. **v0.24.4** - v0.24系列最稳定版本，验证第一次数据库&API变更
5. **v0.25.3** - v0.25系列最稳定版本，验证第二次数据库&API变更
6. **v0.26.2** - v0.26系列最稳定版本，验证Token刷新机制
7. **v0.27.1** - 最新版本，验证Username路径变更和所有新特性

### 测试用例（每版本10个）

| # | 测试项 | 验证目标 | 覆盖的适配器方法 |
|---|--------|---------|----------------|
| 1 | 版本检测 | 自动检测机制准确性 | `MemosApiFactory._detectVersion()` |
| 2 | 创建适配器 | 正确的适配器选择 | `MemosApiFactory.create()` |
| 3 | 用户登录 | 认证流程兼容性 | `login()` |
| 4 | 获取用户信息 | 用户信息格式兼容性 | `getUserInfo()` |
| 5 | 创建Memo | 备忘录创建兼容性 | `createMemo()` |
| 6 | 获取Memo | 备忘录读取兼容性 | `getMemo()` |
| 7 | 更新Memo | 备忘录更新兼容性 | `updateMemo()` |
| 8 | 列出Memos | 列表查询兼容性 | `listMemos()` |
| 9 | 删除Memo | 备忘录删除兼容性 | `deleteMemo()` |
| 10 | 用户登出 | 登出流程兼容性 | `logout()` |

**总测试用例**: 7版本 × 10用例 = **70个测试用例**

---

## 🔍 已知风险点分析

### 高风险版本

#### v0.22.0 - API v1 不兼容更新
**风险等级**: 🔴 高

**变更内容**:
- 官方明确标注"API v1 incompatibility update"
- 部分响应格式调整
- 标签系统重构（从property字段迁移）

**适配方案**:
- ✅ MemosApiV21 已处理响应格式差异（token/accessToken兼容）
- ✅ 标签系统变更对客户端透明（后端自动处理）

**验证方法**:
```bash
# 运行 v0.22.5 测试
./manage_7versions.sh start
./manage_7versions.sh create-user
dart test_all_versions.dart
```

---

#### v0.24.0 - 数据库&API变更
**风险等级**: 🟡 中等

**变更内容**:
- 官方提示"包含数据库和API变更"
- 具体变更未在changelog详细说明
- 建议升级前备份数据

**适配方案**:
- ⚠️ **需要实际测试验证**
- MemosApiV21 可能需要微调
- 如有不兼容，考虑创建 MemosApiV24 分支

**验证方法**:
```bash
# 重点测试 v0.24.4
# 查看日志中是否有API错误
./manage_7versions.sh logs v24
```

---

#### v0.25.0 - 数据库&API变更
**风险等级**: 🟡 中等

**变更内容**:
- 官方提示"包含数据库和API变更"
- 具体变更未在changelog详细说明

**适配方案**:
- ⚠️ **需要实际测试验证**
- 如v0.24.4兼容，v0.25.3大概率也兼容

**验证方法**:
```bash
# 重点测试 v0.25.3
dart test_all_versions.dart
```

---

#### v0.26.0 - Token 刷新机制
**风险等级**: 🟢 低（已适配）

**变更内容**:
- 新增 Refresh Token
- 新增 `/api/v1/auth/refresh` 端点
- Refresh Token Rotation 机制

**适配方案**:
- ✅ MemosApiV26 已实现自动Token刷新
- ✅ `_withAutoRefresh` 包装器自动处理过期Token
- ✅ 完全向后兼容 v0.21-v0.25

---

#### v0.27.0 - Username 路径变更
**风险等级**: 🟢 低（已适配）

**变更内容**:
- 用户资源路径从 `/api/v1/user/{id}` 改为 `/api/v1/users/{username}`
- 新增 PAT、SSE、语音备忘录、分享功能

**适配方案**:
- ✅ MemosApiV27 已实现 ID → username 自动转换
- ✅ 继承 v0.26 的 Token 刷新机制
- ✅ 新功能为增量特性，不影响基础API

---

## 📝 测试执行步骤

### 1. 环境准备

```bash
cd /path/to/IntRoot-main

# 复制配置文件
cp .env.example .env

# 安装依赖
flutter pub get
```

### 2. 启动测试环境

```bash
cd docker

# 启动所有7个版本
./manage_7versions.sh start

# 等待服务就绪（自动健康检查）
# 输出示例：
# ✓ v0.21.0 健康检查通过 (端口 5230)
# ✓ v0.22.5 健康检查通过 (端口 5231)
# ...
```

### 3. 创建测试用户

```bash
# 为所有版本创建 testuser/testpass123
./manage_7versions.sh create-user
```

### 4. 运行完整测试

```bash
# 方式1：使用管理脚本
./manage_7versions.sh test

# 方式2：直接运行测试
cd ..
dart test_all_versions.dart
```

### 5. 查看测试报告

```bash
# 测试完成后会生成 test_results_7versions.json
cat test_results_7versions.json | jq
```

示例输出：
```json
{
  "timestamp": "2026-04-22T18:45:00.000Z",
  "summary": {
    "total": 70,
    "passed": 68,
    "failed": 2,
    "successRate": 0.971
  },
  "results": [...]
}
```

### 6. 单版本调试（如有失败）

```bash
# 查看特定版本日志
./manage_7versions.sh logs v24

# 手动测试单个版本
curl http://localhost:5233/api/v1/status
```

---

## ✅ 预期结果

### 理想情况（100%兼容）

| 版本 | 通过率 | 状态 |
|-----|--------|-----|
| v0.21.0 | 10/10 | ✅ 完全兼容 |
| v0.22.5 | 10/10 | ✅ 完全兼容 |
| v0.23.1 | 10/10 | ✅ 完全兼容 |
| v0.24.4 | 10/10 | ✅ 完全兼容 |
| v0.25.3 | 10/10 | ✅ 完全兼容 |
| v0.26.2 | 10/10 | ✅ 完全兼容 |
| v0.27.1 | 10/10 | ✅ 完全兼容 |
| **总计** | **70/70** | **100%兼容** |

### 可接受情况（≥95%兼容）

- v0.24.x 或 v0.25.x 可能有个别测试失败
- 需要微调适配器代码
- 最终达到 68-70/70 通过

### 不可接受情况（<95%兼容）

- 通过率低于 67/70
- 需要重新评估适配器架构
- 可能需要为 v0.24/v0.25 创建独立适配器

---

## 🔧 故障排查指南

### 问题1：服务启动失败

**症状**: `docker-compose up -d` 后容器退出

**排查步骤**:
```bash
# 查看容器日志
./manage_7versions.sh logs v24

# 检查端口占用
netstat -tuln | grep 523[0-6]

# 重启Docker
docker-compose restart
```

---

### 问题2：健康检查失败

**症状**: 启动后显示"健康检查失败"

**排查步骤**:
```bash
# 手动测试API
curl http://localhost:5233/api/v1/ping

# 等待更长时间（某些版本启动慢）
sleep 30
./manage_7versions.sh status
```

---

### 问题3：测试用例失败

**症状**: 测试报告显示某些用例失败

**排查步骤**:
```bash
# 1. 确认用户已创建
curl -X POST http://localhost:5233/api/v1/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'

# 2. 手动测试失败的API
# （根据具体失败的测试用例）

# 3. 查看详细错误
cat test_results_7versions.json | jq '.results[] | select(.passed == false)'
```

---

### 问题4：v0.24.x 或 v0.25.x 不兼容

**症状**: 这两个版本的测试大量失败

**解决方案**:
1. 记录具体的失败测试和错误信息
2. 查看 Memos GitHub 的对应版本 changelog
3. 创建 `MemosApiV24` 或 `MemosApiV25` 适配器
4. 更新 `MemosApiFactory._detectVersion()` 逻辑

---

## 📚 参考文档

- [API_VERSION_TIMELINE.md](../docs/memos_api/API_VERSION_TIMELINE.md) - 完整版本演进时间线
- [API_COMPLETE_COMPARISON.md](../docs/memos_api/API_COMPLETE_COMPARISON.md) - 160+ API端点对比
- [Memos GitHub Releases](https://github.com/usememos/memos/releases) - 官方更新日志

---

## 🎯 验证目标

### 短期目标（当前任务）

- [ ] 启动7版本测试环境
- [ ] 运行完整70个测试用例
- [ ] 获得测试报告
- [ ] **确认v0.24.x和v0.25.x的实际兼容性**
- [ ] 如有问题，制定修复方案

### 中期目标（生产部署前）

- [ ] 所有版本通过率 ≥ 95%
- [ ] 修复所有已知不兼容问题
- [ ] 更新文档标注实际测试结果
- [ ] 在生产环境验证

### 长期目标（持续维护）

- [ ] 跟踪 Memos 新版本发布
- [ ] 定期运行兼容性测试
- [ ] 及时更新适配器
- [ ] 保持文档同步

---

**文档版本**: 1.0
**最后更新**: 2026-04-22
**状态**: 🔄 待执行测试
**负责人**: IntRoot 开发团队
