# Contributing to InkRoot

First off, thank you for considering contributing to InkRoot! 🎉

It's people like you that make InkRoot such a great tool for everyone.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Style Guide](#style-guide)
  - [Git Commit Messages](#git-commit-messages)
  - [Dart Style Guide](#dart-style-guide)
- [Community](#community)

---

## 📜 Code of Conduct

This project and everyone participating in it is governed by the [InkRoot Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/yyyyymmmmm/InkRoot/issues) as you might find that you don't need to create one.

#### How to Submit a Good Bug Report

Bugs are tracked as [GitHub issues](https://github.com/yyyyymmmmm/InkRoot/issues). When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps which reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed** and explain what you expected to see
- **Include screenshots** if possible
- **Include your environment details**:
  - InkRoot version
  - OS version (iOS/Android)
  - Device model
  - Whether you're using local mode or server sync

**Example:**

```markdown
**Bug**: 待办事项状态无法切换

**重现步骤**:
1. 创建新笔记
2. 添加待办事项：`- [ ] 测试任务`
3. 点击复选框
4. 状态没有变化

**预期行为**: 复选框应该变为选中状态，笔记内容更新为 `- [x] 测试任务`

**实际行为**: 点击后无反应

**环境**:
- InkRoot 版本: 1.1.0
- 设备: iPhone 14 Pro
- iOS 版本: 17.0
- 模式: 本地模式

**截图**: [附上截图]
```

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/yyyyymmmmm/InkRoot/issues).

#### How to Submit a Good Enhancement Suggestion

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples** to demonstrate the steps
- **Describe the current behavior** and **explain the behavior you would like to see**
- **Explain why this enhancement would be useful**

**Example:**

```markdown
**功能建议**: 支持笔记模板

**描述**: 
希望能够创建和使用笔记模板，例如：
- 日记模板
- 会议记录模板
- 读书笔记模板

**使用场景**:
用户经常需要创建格式相同的笔记（如每日日记），每次都要重新输入固定的格式很麻烦。

**期望功能**:
1. 在设置中可以创建模板
2. 新建笔记时可以选择模板
3. 一键应用模板到新笔记

**参考**:
类似 Notion、Obsidian 的模板功能
```

### Pull Requests

#### Before Submitting a Pull Request

1. **Check existing PRs** - Search the [pull requests](https://github.com/yyyyymmmmm/InkRoot/pulls) to see if the enhancement has already been suggested
2. **Discuss first** - For major changes, please open an issue first to discuss what you would like to change
3. **Fork the repo** - Create your own fork of the repository
4. **Create a branch** - Create a new branch for your feature or bugfix

#### Pull Request Process

1. **Update documentation** - Update the README.md and CHANGELOG.md with details of changes
2. **Follow the style guide** - Ensure your code follows the project's style guide
3. **Test your changes** - Test thoroughly on both iOS and Android if possible
4. **Update tests** - Add or update tests as needed
5. **Run linter** - Run `flutter analyze` and fix any issues
6. **Format code** - Run `flutter format lib/` before committing
7. **Write meaningful commits** - Follow the [commit message guidelines](#git-commit-messages)
8. **Create the PR** - Submit your pull request with a clear description

#### Pull Request Template

```markdown
## 📝 Description
<!-- 简要描述这个 PR 做了什么 -->

## 🎯 Related Issue
<!-- 关联的 Issue，如：Fixes #123 -->

## 🔄 Type of Change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update

## ✅ Checklist
- [ ] 我的代码遵循项目的代码风格
- [ ] 我已经进行了自我审查
- [ ] 我已经添加了注释，特别是在复杂的地方
- [ ] 我已经更新了相关文档
- [ ] 我的更改没有产生新的警告
- [ ] 我已经添加了测试来证明我的修复有效或功能正常
- [ ] 新的和现有的单元测试在本地通过
- [ ] 我已经在 iOS 和 Android 上测试过（如果适用）

## 📷 Screenshots (if applicable)
<!-- 如果是 UI 变更，请添加截图 -->

## 📱 Test Environment
- Device: 
- OS Version: 
- InkRoot Version: 
```

---

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK 3.24.5+
- Dart SDK 3.9.2+
- iOS: Xcode 14.0+ (macOS only)
- Android: Android Studio 2023.1.1+

### Setup Steps

```bash
# 1. Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/InkRoot.git
cd InkRoot

# 2. Install dependencies
dart tool/inkroot.dart deps

# 3. Check your setup
dart tool/inkroot.dart doctor

# 4. Run verification
dart tool/inkroot.dart verify

# 5. Run the app
flutter run

# 6. Format code
flutter format lib/
```

For platform builds, prefer the unified maintenance CLI:

```bash
dart tool/inkroot.dart build android-debug
dart tool/inkroot.dart build ios-sim
dart tool/inkroot.dart build macos-debug
dart tool/inkroot.dart build windows-debug
dart tool/inkroot.dart build linux-debug
dart tool/inkroot.dart build web-release
```

See [docs/MAINTENANCE.md](docs/MAINTENANCE.md) for CI, Android signing, and release workflow.

### Project Structure

```
lib/
├── config/         # 配置文件
├── l10n/           # 国际化资源
├── models/         # 数据模型
├── providers/      # 状态管理
├── routes/         # 路由配置
├── screens/        # 页面 UI
├── services/       # 业务逻辑层
├── themes/         # 主题样式
├── utils/          # 工具类
├── widgets/        # 自定义组件
└── main.dart       # 应用入口
```

---

## 📖 Style Guide

### Git Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

#### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types

- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响代码含义的更改，如空格、格式化等）
- `refactor`: 代码重构（既不修复bug也不添加新功能）
- `perf`: 性能优化
- `test`: 添加或修改测试
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI/CD 相关更改

#### Examples

```bash
feat(todo): 添加待办事项功能

- 支持 Markdown 任务列表语法
- 实现交互式复选框组件
- 添加触觉反馈

Closes #123

---

fix(sync): 修复刷新后置顶状态丢失问题

改进数据合并逻辑，保留本地置顶状态

Fixes #456

---

docs: 更新 README 到 v1.1.0

添加待办事项和图片保存功能的介绍
```

### Dart Style Guide

#### 1. Follow Official Guidelines

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` to format your code
- Run `flutter analyze` before committing

#### 2. Naming Conventions

```dart
// Classes: UpperCamelCase
class NoteCard extends StatelessWidget { }

// Variables, functions: lowerCamelCase
String noteTitle = 'Hello';
void saveNote() { }

// Constants: lowerCamelCase
const double defaultFontSize = 14.0;

// Private: prefix with underscore
String _privateVariable = '';
void _privateMethod() { }

// Files: lowercase_with_underscores
note_detail_screen.dart
```

#### 3. Comments

```dart
/// 📝 使用三斜杠注释公共 API
/// 
/// 详细说明...
/// 
/// Example:
/// ```dart
/// final note = Note(title: 'Hello');
/// ```
class Note { }

// 使用双斜杠注释实现细节
void _implementation() {
  // 实现逻辑
}
```

#### 4. Import Order

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// 3. Third-party packages
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

// 4. Local imports
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/services/database_service.dart';
```

#### 5. Code Organization

```dart
class MyWidget extends StatefulWidget {
  // 1. Static constants
  static const String routeName = '/my-widget';
  
  // 2. Final fields
  final String title;
  final Function? onTap;
  
  // 3. Constructor
  const MyWidget({
    Key? key,
    required this.title,
    this.onTap,
  }) : super(key: key);
  
  // 4. Override methods
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 1. State variables
  bool _isLoading = false;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 4. Private methods
  void _loadData() {
    // Implementation
  }
  
  // 5. Dispose
  @override
  void dispose() {
    super.dispose();
  }
}
```

---

## 🌍 Community

- **GitHub Issues**: [https://github.com/yyyyymmmmm/InkRoot/issues](https://github.com/yyyyymmmmm/InkRoot/issues)
- **GitHub Discussions**: [https://github.com/yyyyymmmmm/InkRoot/discussions](https://github.com/yyyyymmmmm/InkRoot/discussions)
- **Email**: [inkroot2025@gmail.com](mailto:inkroot2025@gmail.com)
- **Website**: [https://inkroot.cn](https://inkroot.cn)

---

## 🙏 Thank You!

Thank you for contributing to InkRoot! Every contribution, no matter how small, helps make InkRoot better for everyone. 💙

---

<div align="center">

**Happy Coding!** 🚀

[Back to README](README.md) · [View License](LICENSE) · [Code of Conduct](CODE_OF_CONDUCT.md)

</div>
