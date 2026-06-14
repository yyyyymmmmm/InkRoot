# InkRoot

InkRoot 是一款面向个人知识记录的跨平台笔记应用，支持本地模式，也可以连接自托管 Memos 服务进行同步。应用提供 Markdown 渲染、图片、标签、提醒、搜索、WebDAV 备份、导入导出和 AI 辅助等能力。

[下载最新版本](https://github.com/yyyyymmmmm/InkRoot/releases/latest) · [问题反馈](https://github.com/yyyyymmmmm/InkRoot/issues) · [English](README.en.md)

## 当前版本

`1.1.0`

本版本重点改进了编辑体验、首页渲染、图片查看、WebDAV 备份、Memos 兼容、时间线合并、国际化和项目发布流程。

主要变化：

- 首页笔记渲染保留用户输入的换行和排版。
- 展开按钮按渲染后的可见内容判断，减少误显示。
- 图片查看支持点击退出、原图查看和多图浏览。
- WebDAV 备份支持图片附件选项，并改进目录创建、进度和错误处理。
- 同步和刷新保留笔记创建时间，避免热力图被更新时间污染。
- 维护 CLI 覆盖检查、构建和发布入口。
- GitHub Actions 覆盖 Android、iOS、macOS、Windows 和 Linux。

## 功能

- 本地笔记和 Memos 云端同步。
- Markdown 渲染、待办事项、链接、图片和标签。
- 多层级标签，例如 `#工作/项目A`。
- 全文搜索、置顶、提醒和随机回顾。
- 图片上传、预览、保存和多图浏览。
- WebDAV 备份和恢复，可选择是否备份图片附件。
- Flomo、微信读书等数据导入。
- AI 辅助写作和自定义提示词。
- 中文和英文界面。
- Android、iOS、macOS、Windows 和 Linux 构建。

## 下载

发布包在 [GitHub Releases](https://github.com/yyyyymmmmm/InkRoot/releases) 页面提供。

Android 用户下载 APK 后安装。
Windows 用户下载压缩包后运行应用。
Linux 用户下载压缩包后解压运行。
iOS 和 macOS 包当前用于测试分发。

## 开发

安装 Flutter 后运行：

```bash
flutter pub get
dart tool/inkroot.dart verify
```

常用命令：

```bash
dart tool/inkroot.dart doctor
dart tool/inkroot.dart analyze
dart tool/inkroot.dart test
dart tool/inkroot.dart build android-debug
dart tool/inkroot.dart build ios-sim
dart tool/inkroot.dart build macos-debug
dart tool/inkroot.dart build windows-debug
dart tool/inkroot.dart build linux-debug
```

不同桌面或移动平台需要对应系统环境。例如 iOS 和 macOS 需要 macOS 与 Xcode，Windows 需要 Windows 与 Visual Studio C++ 桌面组件，Linux 需要 GTK、CMake 和 Ninja。

## 发布

版本号统一维护在 `pubspec.yaml`：

```yaml
version: 1.1.0+10100
```

发布入口：

```bash
dart tool/inkroot.dart release v1.1.0
```

这个命令会创建并推送版本 tag。GitHub Actions 收到 tag 后自动执行检查、构建并发布 Android、iOS、macOS、Windows 和 Linux 产物。

## 文档

- [维护指南](docs/MAINTENANCE.md)
- [更新日志](CHANGELOG.md)
- [安全政策](SECURITY.md)
- [贡献指南](CONTRIBUTING.md)

## 许可证

InkRoot 使用 MIT License。详见 [LICENSE](LICENSE)。
