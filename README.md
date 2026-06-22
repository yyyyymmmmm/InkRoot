# InkRoot

InkRoot 是一款面向个人知识记录的跨平台笔记应用。它可以本地优先使用，也可以连接官方服务器或自托管 Memos 服务进行同步。应用提供 Memos 兼容 Markdown、图片、标签、提醒、搜索、WebDAV 备份、导入导出、系统分享、小组件和可选 AI 辅助等能力。

[下载最新版本](https://github.com/yyyyymmmmm/InkRoot/releases/latest) · [问题反馈](https://github.com/yyyyymmmmm/InkRoot/issues) · [English](README.en.md)

## 当前版本

`1.1.13`

本版本集中修复 Android 分享闪退、分享内容为空白、自部署 Memos 0.26/0.27/0.29 登录或同步失败、随机回顾小组件占位显示和 iOS 分享扩展构建问题，并继续完善小组件、系统分享、Memos 兼容和多端构建链路。

主要变化：

- Android 和 iOS 小组件新增快速记录、随机回顾两个独立入口。
- 随机回顾小组件支持真实笔记内容选择、刷新配置和随机切换。
- Android 系统分享统一支持浏览器、阅读器、系统选中文本、相册、文件管理器等入口。
- iOS 新增系统分享扩展，支持从浏览器、阅读器、相册和文件 App 分享内容到 InkRoot。
- Memos 0.21.0 至 0.29.1 兼容链路继续增强，提升自部署服务器登录、账号读取、资源和同步初始化成功率。
- 语音识别新增用户自定义讯飞配置入口。
- 知识图谱优化视觉样式、缩放、节点点击和大数据量渲染性能。
- Windows、macOS、Linux 桌面端字体大小设置改为整体界面缩放体验。
- Markdown 标题、引用、链接、下划线和相关笔记引用渲染继续优化。
- 标签路径解析、侧边栏标签返回路径和中文标签打开体验继续修复。
- AI 设置页、模型输入、自定义提示词和快速上手文案继续整理。
- 首页笔记渲染保留用户输入的换行和排版。
- 展开按钮按渲染后的可见内容判断，减少误显示。
- 图片查看支持点击退出、原图查看和多图浏览。
- WebDAV 备份支持图片附件选项，并改进目录创建、进度和错误处理。
- 同步和刷新保留笔记创建时间，避免热力图被更新时间污染。
- 设置中新增账号与数据删除入口，并提供公开删除申请页面。
- iOS 隐私清单、权限声明和法律文档已按当前数据流更新。
- 官网已更新产品首页、下载页、使用指南、FAQ、完整更新日志和法律页面。
- 维护 CLI 覆盖检查、构建和发布入口。
- GitHub Actions 覆盖 Android、iOS、macOS、Windows 和 Linux。

## 功能

- 本地笔记、官方服务器和自部署 Memos 同步。
- Markdown 渲染、待办事项、链接、图片和标签。
- 多层级标签，例如 `#工作/项目A`。
- 全文搜索、置顶、提醒和随机回顾。
- 图片上传、预览、保存和多图浏览。
- WebDAV 备份和恢复，可选择是否备份图片附件。
- Flomo、微信读书等数据导入。
- Android 和 iOS 系统分享入口。
- 快速记录和随机回顾桌面小组件。
- AI 辅助写作和自定义提示词。
- 中文和英文界面。
- Android、iOS、macOS、Windows 和 Linux 构建。

## 下载

发布包在 [GitHub Releases](https://github.com/yyyyymmmmm/InkRoot/releases) 页面提供。

GitHub Releases 的 Android APK 用于手动安装和测试分发；Google Play 上架使用发布流程生成的签名 AAB。
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
dart tool/inkroot.dart store-check
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
version: 1.1.13+10113
```

发布入口：

```bash
dart tool/inkroot.dart release v1.1.13
```

这个命令会创建并推送版本 tag。GitHub Actions 收到 tag 后自动执行检查、构建并发布 Android APK/AAB、iOS、macOS、Windows 和 Linux 产物。

## 文档

- [项目结构与构建指南](docs/PROJECT_STRUCTURE_AND_BUILD.md)
- [维护指南](docs/MAINTENANCE.md)
- [商店合规清单](docs/STORE_COMPLIANCE.md)
- [更新日志](CHANGELOG.md)
- [安全政策](SECURITY.md)
- [贡献指南](CONTRIBUTING.md)

## 法律与隐私

- [隐私政策](https://inkroot.cn/privacy.html)
- [用户协议](https://inkroot.cn/agreement.html)
- [账号与数据删除](https://inkroot.cn/account-deletion.html)

## 许可证

InkRoot 使用 MIT License。详见 [LICENSE](LICENSE)。
