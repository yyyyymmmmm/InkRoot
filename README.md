# InkRoot

InkRoot 是一款面向个人知识记录的跨平台笔记应用，支持本地模式，也可以连接自托管 Memos 服务进行同步。应用提供 Markdown 渲染、图片、标签、提醒、搜索、WebDAV 备份、导入导出和 AI 辅助等能力。

[下载最新版本](https://github.com/yyyyymmmmm/InkRoot/releases/latest) · [问题反馈](https://github.com/yyyyymmmmm/InkRoot/issues) · [English](README.en.md)

## 当前版本

`1.1.8`

本版本集中修复笔记渲染、搜索、待办、相关笔记、标签返回路径、品牌文案和发布链路问题，并继续保持 Android Release 签名校验。

主要变化：

- 待办点击完成、主页下划线/加粗渲染、搜索结果空白和内容不一致问题已修复。
- 相关笔记、AI 点评、摘要、续写、标签推荐和洞察体验继续优化。
- 标签详情返回路径、侧边栏标签交互和关于/帮助/设置页文案继续整理。
- 品牌文案恢复为“静待沉淀，蓄势而鸣”。
- 首页笔记渲染保留用户输入的换行和排版。
- 展开按钮按渲染后的可见内容判断，减少误显示。
- 图片查看支持点击退出、原图查看和多图浏览。
- WebDAV 备份支持图片附件选项，并改进目录创建、进度和错误处理。
- 同步和刷新保留笔记创建时间，避免热力图被更新时间污染。
- 设置中新增账号与数据删除入口，并提供公开删除申请页面。
- iOS 隐私清单、权限声明和法律文档已按当前数据流更新。
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
version: 1.1.8+10108
```

发布入口：

```bash
dart tool/inkroot.dart release v1.1.8
```

这个命令会创建并推送版本 tag。GitHub Actions 收到 tag 后自动执行检查、构建并发布 Android APK/AAB、iOS、macOS、Windows 和 Linux 产物。

## 文档

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
