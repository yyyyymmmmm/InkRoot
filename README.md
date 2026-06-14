<div align="center">
  <img src="assets/images/logo.png" alt="InkRoot Logo" width="120" height="120">
  
# InkRoot - 墨鸣笔记

  **一款基于 Memos 系统打造的第三方极简笔记应用**
  
  ---
  
  专为追求高效记录与深度积累的用户设计。它帮助你默默书写、静心沉淀，让每一次落笔都成为未来思想生根发芽的力量。
  
  完美对接 Memos 服务器，保障数据安全与私密，适合个人及团队的知识管理需求。
  
  无论是快速捕捉灵感，还是系统性整理思考，墨鸣都助你沉淀积累，厚积薄发。

-  [![GitHub release](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/yyyyymmmmm/InkRoot/releases)
  [![Flutter](https://img.shields.io/badge/Flutter-3.35.5-02569B?logo=flutter)](https://flutter.dev)
  [![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yyyyymmmmm/InkRoot/blob/master/LICENSE)
  [![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](https://github.com/yyyyymmmmm/InkRoot)
  [![Downloads](https://img.shields.io/github/downloads/yyyyymmmmm/InkRoot/total.svg)](https://github.com/yyyyymmmmm/InkRoot/releases)

  [官方网站](https://inkroot.cn) · [下载安装](https://github.com/yyyyymmmmm/InkRoot/releases) · [问题反馈](https://github.com/yyyyymmmmm/InkRoot/issues)

  ---

  ## 🎉 最新版本 v1.1.0
  
  ### 🆕 本次更新亮点
  
  <table>
  <tr>
    <td width="50%">
      
  ### 🧰 工程维护升级
  接近大厂仓库维护方式
  
  - 新增统一维护 CLI
  - GitHub Actions 全端构建
  - PR/Issue 模板
  - Dependabot 依赖更新
  
    </td>
    <td width="50%">
      
  ### 🔐 Android 签名流程
  Release 签名安全接入
  
  - 本地密钥不入库
  - GitHub Secrets 注入
  - Debug 构建无需签名
  - Release 构建自动签名
  
    </td>
  </tr>
  <tr>
    <td>
      
  ### 📝 编辑与渲染优化
  更接近富文本笔记体验
  
  - 输入时隐藏 Markdown 噪音
  - 首页保留用户排版
  - Memos Markdown 渲染增强
  - 展开逻辑更准确
  
    </td>
    <td>
      
  ### ☁️ 同步与备份增强
  WebDAV 与 Memos 兼容继续完善
  
  - WebDAV 图片备份开关
  - 多版本 Memos API 探测
  - 同步时间线修正
  - 备份恢复容错增强
  
    </td>
  </tr>
  <tr>
    <td>
      
  ### 🔗 引用关系侧边栏
  全新的引用管理体验
  
  - 底部滑出式侧边栏
  - 引用类型筛选
  - 点击箭头直接打开
  - 引用卡片可跳转
  
    </td>
    <td>
      
  ### 🎨 UI/UX 优化
  专业化文案与体验提升
  
  - 导入导出页面优化
  - 统一专业术语
  - 数据安全提示
  - 80+条国际化翻译
  
    </td>
  </tr>
  </table>
  
  ### 📦 持续完善的功能
  
  <table>
  <tr>
    <td width="50%">
      
  ### 💻 macOS平台支持
  全新支持macOS桌面应用
  
  - 原生macOS应用体验
  - 专业DMG安装包
  - 完整构建打包脚本
  - 支持macOS 10.14+
  
    </td>
    <td width="50%">
      
  ### ⏰ 笔记时间修改
  灵活的时间管理功能
  
  - 手动修改笔记更新时间
  - 日期选择器国际化
  - 自动同步到服务器
  - 实时显示更新时间
  
    </td>
  </tr>
  <tr>
    <td>
      
  ### 🔗 引用关系优化
  更清晰的引用关系
  
  - 修复引用箭头显示问题
  - 优化双向链接可视化
  - 改进引用关系展示
  - 更清晰的关联关系
  
    </td>
    <td>
      
  ### ⚡ WebDAV增量同步
  大幅提升同步性能
  
  - 只同步变化的笔记
  - 减少90%+网络流量
  - 智能合并避免冲突
  - 支持多设备协作
  
    </td>
  </tr>
  </table>
  
  ### 🐛 重要修复
  
  - 🔧 **修复云配置容错** - 服务端失败态返回字符串时不再触发类型异常
  - 📝 **修复首页展开判断** - 链接、标签、图片等渲染后短内容不再误显示展开
  - 🖼️ **优化图片查看器** - 点击退出、原图查看和多图浏览体验更接近系统相册
  - 🕒 **修复同步时间线** - 普通刷新优先使用服务端时间，离线发布回写保留本地创建时间
  - ☁️ **增强 WebDAV 备份** - 图片附件备份、递归目录创建、错误提示和进度处理更稳
  - 🌍 **补齐部分国际化** - 帮助页、备份、WebDAV、提醒等页面文案继续收敛到 i18n
  
  <div align="center">
  
  **[📥 下载最新版本](https://github.com/yyyyymmmmm/InkRoot/releases/latest)** · **[📋 完整更新日志](CHANGELOG.md)**
  
  </div>

</div>

---

## 📖 目录

- [✨ 特性](#-特性)
- [📱 系统要求](#-系统要求)
- [🚀 快速开始](#-快速开始)
- [📦 安装部署](#-安装部署)
- [🏗️ 项目架构](#️-项目架构)
- [⚙️ 配置说明](#️-配置说明)
- [🛠️ 开发指南](#️-开发指南)
- [📝 API 文档](#-api-文档)
- [📚 完整文档](#-完整文档)
- [🧪 测试指南](#-测试指南)
- [🚀 开发路线图](#-开发路线图)
- [🔐 隐私与数据安全](#-隐私与数据安全)
- [📄 许可证](#-许可证)
- [📧 联系方式](#-联系方式)

---

## ✨ 特性

### 🎯 核心功能

- **📝 Markdown 支持** - 完整的 Markdown 语法支持，包括代码高亮、表格、任务列表等
- **✅ 待办事项** - 交互式任务列表，点击复选框即可切换状态，支持触觉反馈和动画效果
- **☁️ 云端同步** - 完美对接 Memos 服务器，支持实时同步与离线编辑，WebDAV 同步支持
- **🎤 语音识别** - 内置语音转文字功能，快速记录灵感
- **🖼️ 图片管理** - 支持图片上传、预览、裁剪、压缩，长按保存到相册，智能权限引导
- **🏷️ 标签系统** - 支持多层级标签（`#工作/项目A`），灵活分类，AI 推荐相关标签，标签统计可视化
- **🔍 全文搜索** - 强大的搜索功能，支持标题、内容、标签多维度搜索
- **⏰ 智能提醒** - 定时提醒通知，不错过重要事项
- **🌓 深色模式** - 护眼舒适的日夜双主题自动切换
- **🕸️ 知识图谱** - 可视化展示笔记关联关系，构建知识网络
- **📊 活跃热力图** - 支持月份切换，直观展示笔记创建活跃度
- **🤖 AI 智能助手** - DeepSeek AI 加持，智能优化笔记内容、相关笔记推荐
- **📌 笔记置顶** - 重要笔记置顶显示，支持云端同步，刷新不丢失
- **🔤 自定义字体** - 支持多种字体和字号，个性化阅读体验
- **🌍 多语言支持** - 完整的中文/English 界面切换，所有 UI 和消息已国际化
- **📥 数据迁移** - 支持从 Flomo、微信读书导入笔记，智能解析内容、标签和图片，保留创建时间
- **🔄 Notion 同步** - 与 Notion 工作区实时同步笔记数据，支持双向同步与自动同步功能
- **📓 Obsidian 集成** - 通过第三方插件实现与 Obsidian 的双向同步，支持每日笔记自动集成
- **🔐 隐私合规** - 符合应用商店规范的隐私政策弹窗
- **📊 数据统计** - 集成友盟统计，帮助改进产品体验

### 💡 特色亮点

#### 使用灵活性
- **🆓 本地模式** - 无需服务器，开箱即用，完全免费
- **☁️ 云端同步** - 可选连接 Memos 服务器实现多设备同步
- **🔒 数据私有** - 本地模式数据不上传；云端模式数据存储在你自己的服务器

#### 特色功能
- **🤖 AI 智能助手** - DeepSeek AI 驱动，智能优化和扩展笔记内容
- **🔤 自定义字体** - 4档字体大小 + 6种精选字体，打造个性化阅读体验
- **🌍 多语言支持** - 完整支持中文、英文界面切换
- **🎤 语音识别** - 实时语音转文字，快速记录灵感
- **📌 笔记引用** - `[[笔记标题]]` 创建双向链接，构建知识网络
- **🔗 反向链接** - 自动显示哪些笔记引用了当前笔记
- **🕸️ 知识图谱** - 可视化展示笔记关联网络，交互式探索知识结构
- **📊 活跃热力图** - 支持月份切换，追踪笔记创建习惯
- **🎲 随机回顾** - 智能推荐历史笔记，巩固记忆
- **⏰ 智能提醒** - 定时通知，不错过重要事项
- **🔍 全文搜索** - 快速查找任何笔记内容

#### 技术优势
- **📤 导入导出** - 支持 JSON/Markdown 格式，数据完全可控
- **🔄 多平台同步** - 支持 Memos、WebDAV、Notion 多种同步方式，增量同步节省流量
- **🔌 开放生态** - 兼容 Obsidian 插件，构建完整知识管理生态系统
- **📱 跨平台** - 同时支持 iOS 和 Android 双平台
- **🎨 精美界面** - 采用 Material Design 3 设计语言
- **⚡ 高性能** - 本地 SQLite 数据库，响应迅速
- **🔐 安全存储** - 敏感信息使用安全存储加密
- **📝 Markdown** - 完整支持 Markdown 语法，包括代码高亮、表格、任务列表

### 🆕 实验室功能

- **🤖 AI 智能助手** - DeepSeek AI 集成，智能写作辅助（设置→AI设置）
- **🏢 企业微信集成** - 支持企业微信通知推送
- **📊 数据统计** - 笔记数量、字数统计与分析
- **🎲 随机回顾** - 随机抽取历史笔记进行回顾
- **📌 本地引用** - 笔记间双向链接功能
- **🕸️ 知识图谱** - 可视化笔记关联关系，构建知识网络

---

## 📱 系统要求

### 用户端要求

#### iOS

- **最低版本**: iOS 13.0+
- **推荐版本**: iOS 15.0+
- **架构支持**: arm64
- **安装方式**: App Store / TestFlight / IPA 旁加载

#### Android

- **最低版本**: Android 6.0 (API 23)+
- **推荐版本**: Android 11.0 (API 30)+
- **架构支持**: arm64-v8a, armeabi-v7a, x86_64
- **安装方式**: APK 直接安装 / 各大应用商店

#### macOS

- **最低版本**: macOS 10.14 (Mojave)+
- **推荐版本**: macOS 12.0 (Monterey)+
- **架构支持**: Intel x86_64, Apple Silicon (M1/M2/M3)
- **安装方式**: DMG 安装包

#### Windows

- **最低版本**: Windows 10 (1809)+
- **推荐版本**: Windows 11
- **架构支持**: x64
- **安装方式**: EXE 安装包 / 便携版

### 开发环境要求

#### 通用环境

| 组件 | 版本要求 | 备注 |
|------|---------|------|
| **Flutter SDK** | 3.24.5+ | **推荐 3.35.5** |
| **Dart SDK** | 3.0.0+ | **推荐 3.9.2** (随 Flutter 安装) |
| **Git** | 最新稳定版 | 用于版本控制 |

#### Android 开发环境（⚠️ 重要）

由于 Android 环境配置较为复杂，请严格按照以下版本配置：

| 组件 | 版本要求 | 下载地址 | 说明 |
|------|---------|---------|------|
| **Android Studio** | 2023.1.1+ | [官网下载](https://developer.android.com/studio) | **推荐 2025.1.1 (Ladybug)** |
| **Android SDK Platform** | API 23 - API 36 | Android Studio SDK Manager | **必需 API 23, 推荐 API 34/35** |
| **Android SDK Build-Tools** | 35.0.0 | Android Studio SDK Manager | **最新版本** |
| **Android SDK Platform-Tools** | 35.0.0+ | 随 SDK 安装 | adb、fastboot 等工具 |
| **Android SDK Command-line Tools** | 最新版 | Android Studio SDK Manager | 命令行工具 |
| **Android Emulator** | 35.6.11+ | Android Studio SDK Manager | 可选，用于模拟器调试 |
| **JDK** | JDK 11 或 JDK 21 | Android Studio 自带 | **推荐使用 Android Studio 自带的 JDK 21** |
| **Gradle** | 8.12 | 自动下载 | 已在项目中配置 |
| **NDK** | 27.0.12077973 | Android Studio SDK Manager | 原生开发工具包 |
| **Kotlin** | 1.9.0+ | 随 Android Studio 安装 | Kotlin 编译器 |

#### Android 环境配置步骤（完整版）

1. **安装 Android Studio**
   ```bash
   # 下载地址
   https://developer.android.com/studio
   
   # 安装后启动 Android Studio
   # 首次启动会自动下载 Android SDK
   ```

2. **配置 Android SDK**
   
   打开 Android Studio > Settings (或 Preferences) > Appearance & Behavior > System Settings > Android SDK
   
   **SDK Platforms 标签页** - 勾选以下版本：
   - ✅ Android 14.0 (UpsideDownCake) - API 34
   - ✅ Android 13.0 (Tiramisu) - API 33  
   - ✅ Android 12.0 (S) - API 31
   - ✅ Android 11.0 (R) - API 30
   - ✅ Android 10.0 (Q) - API 29
   - ✅ Android 6.0 (Marshmallow) - API 23 **(必需，项目最低要求)**
   
   **SDK Tools 标签页** - 勾选以下工具：
   - ✅ Android SDK Build-Tools 35.0.0
   - ✅ NDK (Side by side) 27.0.12077973
   - ✅ Android SDK Command-line Tools (latest)
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
   - ✅ Intel x86 Emulator Accelerator (HAXM installer) - 如果使用 Intel CPU
   
   点击 **Apply** 开始下载安装

3. **配置环境变量**
   
   **Windows:**
   ```powershell
   # 系统环境变量中添加
   ANDROID_HOME = D:\AndroidSdk  # 你的 SDK 路径
   
   # Path 中添加
   %ANDROID_HOME%\platform-tools
   %ANDROID_HOME%\tools
   %ANDROID_HOME%\tools\bin
   ```
   
   **macOS/Linux:**
   ```bash
   # 在 ~/.bashrc 或 ~/.zshrc 中添加
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   ```

4. **配置 Flutter 环境**
   ```bash
   # 设置 Android SDK 路径
   flutter config --android-sdk $ANDROID_HOME
   
   # 设置 JDK 路径（使用 Android Studio 自带的 JDK）
   flutter config --jdk-dir "D:\Android\jbr"  # Windows
   flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"  # macOS
   
   # 接受 Android 许可协议
   flutter doctor --android-licenses
   # 全部输入 y 接受
   ```

5. **验证环境配置**
   ```bash
   flutter doctor -v
   
   # 应该看到：
   # [✓] Flutter (Channel stable, 3.35.5)
   # [✓] Android toolchain - develop for Android devices (Android SDK version 35.0.0)
   # [✓] Android Studio (version 2025.1.1)
   ```

#### iOS 开发环境（仅 macOS）

| 组件 | 版本要求 | 下载地址 | 说明 |
|------|---------|---------|------|
| **Xcode** | 14.0+ | App Store | **推荐最新版** |
| **iOS SDK** | 13.0+ | 随 Xcode 安装 | |
| **CocoaPods** | 1.11.0+ | `sudo gem install cocoapods` | iOS 依赖管理 |
| **Command Line Tools** | 最新版 | `xcode-select --install` | Xcode 命令行工具 |

#### iOS 环境配置步骤

1. **安装 Xcode**
   - 从 App Store 下载安装 Xcode
   - 首次启动会自动安装组件

2. **安装命令行工具**
   ```bash
   xcode-select --install
   ```

3. **安装 CocoaPods**
   ```bash
   sudo gem install cocoapods
   pod setup
   ```

4. **配置 Xcode**
   ```bash
   # 设置 Xcode 路径
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   
   # 同意许可协议
   sudo xcodebuild -license accept
   ```

5. **验证环境**
   ```bash
   flutter doctor -v
   
   # 应该看到：
   # [✓] Xcode - develop for iOS and macOS
   ```

### 🔧 环境问题排查

如果 `flutter doctor` 检查出现问题：

#### Android 相关问题

1. **找不到 Android SDK**
   ```bash
   flutter config --android-sdk <你的SDK路径>
   ```

2. **JDK 版本不对**
   ```bash
   # 使用 Android Studio 自带的 JDK
   flutter config --jdk-dir "D:\Android\jbr"
   ```

3. **许可协议未接受**
   ```bash
   flutter doctor --android-licenses
   # 全部输入 y
   ```

4. **Gradle 下载慢**
   ```bash
   # 已配置腾讯云镜像
   # 如果还是慢，可以手动下载 gradle-8.12-all.zip
   # 放到 C:\Users\你的用户名\.gradle\wrapper\dists\
   ```

#### iOS 相关问题（macOS）

1. **CocoaPods 安装失败**
   ```bash
   # 使用 Homebrew 安装
   brew install cocoapods
   ```

2. **找不到 Xcode**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

---

## 🚀 快速开始

### 1. 选择使用模式

InkRoot 支持两种使用模式，根据需求选择：

#### 💡 模式一：本地模式（推荐新手）

**无需服务器，开箱即用！**

- ✅ 安装后直接使用，无需配置
- ✅ 所有数据存储在本地
- ✅ 完全离线可用
- ✅ 隐私保护，数据不上传
- ✅ 支持全部核心功能

**适合场景：**
- 个人笔记管理
- 不需要多设备同步
- 重视数据隐私

**使用方法：**
1. 安装应用
2. 跳过服务器配置
3. 直接开始记笔记！

---

#### ☁️ 模式二：云端同步模式（可选）

**需要 Memos 服务器，支持多设备同步。**

**版本兼容：已支持 Memos v0.21.x 到 v0.28.x 的主要 API 差异，并会自动探测服务器版本。**

**选项A: 使用 Docker 部署 Memos（推荐）**

```bash
docker run -d \
  --name memos \
  --publish 5230:5230 \
  --volume ~/.memos/:/var/opt/memos \
  neosmemo/memos:latest
```

**版本要求说明：**
- ✅ **已适配**：v0.21.x、v0.22-v0.25、v0.26+、v0.27/v0.28 的主要登录、笔记、引用、附件接口差异
- ⚠️ **不建议**：v0.20.x 及以下，API 差异较大
- 📌 **建议**：新部署优先使用较新的稳定版；已有 v0.21.x 服务可继续使用
- 🧪 **说明**：不同 Memos 版本能力不同，例如附件、引用、链接等功能会按服务端能力降级

**选项B: 下载 Memos 二进制文件**

前往 [Memos Releases](https://github.com/usememos/memos/releases) 下载需要的稳定版本。

**选项C: 使用官方演示服务器（仅测试用）**

```
服务器地址: https://memos.didichou.site
版本: 以实际服务端为准
注意：演示服务器数据可能会被定期清理，不建议长期使用
```

### 2. 配置应用（如果选择云端同步模式）

如果选择云端同步模式，需要配置服务器：

1. 打开 InkRoot 应用
2. 进入「设置」→「服务器信息」
3. 输入你的 Memos 服务器地址
   - 格式：`http://your-server:5230` 或 `https://your-domain.com`
   - 应用会自动探测 Memos 版本并选择对应 API
4. 注册新账号或登录现有账号

**如果选择本地模式，跳过此步骤！**

### 3. 开始使用

#### 📝 基础功能
- 点击「+」按钮创建新笔记
- 使用 Markdown 语法编写内容
- 添加标签方便分类：`#标签名`
- 支持上传和管理图片

#### 🌟 特色功能（亮点）

**1. 语音识别** 🎤
- 点击麦克风图标开始语音输入
- 实时转换语音为文字
- 支持中文、英文识别
- 连续识别模式

**2. 本地引用（笔记链接）** 📌
- 使用 `[[笔记标题]]` 创建引用
- 自动生成双向链接
- 点击引用快速跳转
- 查看反向链接（哪些笔记引用了当前笔记）

**3. 智能提醒** ⏰
- 为笔记设置定时提醒
- 支持一次性和重复提醒
- 通知点击直达笔记内容

**4. 随机回顾** 🎲
- 随机抽取历史笔记复习
- 支持按标签筛选
- 帮助巩固记忆

**5. 数据导入导出** 📤
- 导出为 JSON 或 Markdown
- 支持批量导出
- 数据完全可控

**6. 全文搜索** 🔍
- 快速搜索笔记内容
- 支持标题、内容、标签搜索
- 实时搜索建议

**7. 知识图谱** 🕸️
- 可视化展示笔记之间的引用关系
- 交互式节点探索，点击节点快速跳转
- 通过 `[[笔记标题]]` 建立笔记链接
- 自动构建知识网络图

**8. 活跃热力图** 📊
- 查看每日笔记创建数量
- 支持切换不同月份查看
- 追踪笔记习惯和活跃度

**9. AI 智能助手** 🤖
- 智能优化笔记内容
- 内容扩展和补充
- 自动总结和提炼要点
- 智能问答和知识查询
- 配置：设置 > AI 设置

**10. 自定义字体** 🔤
- 4档字体大小可选：小、标准、大、特大
- 6种精选字体：
  - SF Pro Display（默认，现代简洁）
  - 思源黑体（优雅易读）
  - 思源宋体（经典宋体）
  - 楷体风格（传统书法）
  - 站酷小薇（活泼可爱）
  - 站酷庆科（个性鲜明）
- 实时预览效果
- 配置：设置 > 偏好设置 > 字体设置

**11. 多语言支持** 🌍
- 完整支持中文、英文
- 自动跟随系统语言
- 可手动切换语言
- 配置：设置 > 偏好设置 > 语言选择

**12. 待办事项** ✅
- 使用 `- [ ]` 创建待办事项
- 使用 `- [x]` 标记已完成
- 点击复选框直接切换状态
- 精美的动画效果和触觉反馈
- 自动保存，实时同步
- 示例：
  ```markdown
  - [ ] 未完成的任务
  - [x] 已完成的任务
  ```

**13. 图片保存** 📷
- 笔记中的图片长按可保存
- 智能权限请求引导
- 自动保存到系统相册
- 支持所有图片格式

---

## 📦 安装部署

### 方式一：从源码构建

#### 前置要求

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.24.5+
- [Git](https://git-scm.com/)
- iOS 开发需要 Xcode 14.0+
- Android 开发需要 Android Studio 或 Android SDK

#### 克隆仓库

```bash
git clone https://github.com/yyyyymmmmm/InkRoot.git
cd InkRoot
```

#### 统一维护 CLI

```bash
dart tool/inkroot.dart doctor
dart tool/inkroot.dart verify
```

#### 构建 Android APK

```bash
# Debug APK（无需签名）
dart tool/inkroot.dart build android-debug

# Release APK（需要 android/key.properties 和 keystore）
dart tool/inkroot.dart build android-release
```

构建完成后，APK 文件位于：`build/app/outputs/flutter-apk/`

Android 签名文件不进入 Git。详细流程见 [维护指南](docs/MAINTENANCE.md)。

#### 构建 iOS IPA

```bash
# iOS 模拟器构建（无需签名）
dart tool/inkroot.dart build ios-sim

# 未签名 IPA（真机分发仍需额外签名/安装工具）
dart tool/inkroot.dart build ios-unsigned-ipa
```

构建完成后，IPA 文件位于：`build/ios/ipa/`

#### 构建 macOS DMG

```bash
# 方法1: 使用统一 CLI
dart tool/inkroot.dart build macos-debug

# 方法2: 创建 DMG
./scripts/dmg/build_release.sh
```

构建完成后，DMG 文件位于项目根目录：`InkRoot-版本号-Installer.dmg`

**详细说明**：参考 [macOS 构建指南](scripts/dmg/README.md)

#### 构建 Windows 安装包

```bash
# 方法1: 使用统一 CLI
dart tool/inkroot.dart build windows-debug

# 方法2: 使用构建脚本
scripts\windows\build_windows.bat
```

构建完成后，可执行文件位于：`build\windows\x64\runner\Release\inkroot.exe`

**详细说明**：参考 [Windows 构建指南](scripts/windows/README.md)

#### 构建 Linux

```bash
dart tool/inkroot.dart build linux-debug
```

完整维护和 CI 说明见 [维护指南](docs/MAINTENANCE.md)。

### 方式二：下载预编译版本

访问 [Releases 页面](https://github.com/yyyyymmmmm/InkRoot/releases) 下载最新版本。

**⚠️ 安装提示**：
- Android 安装时可能提示"未知来源"或"风险应用"，这是正常现象
- InkRoot 是开源应用，代码完全公开，请放心安装
- 如有问题请通过 GitHub Issues 反馈

---

## 🏗️ 项目架构

### 技术栈

| 技术 | 说明 | 版本 |
|------|------|------|
| **Flutter** | 跨平台 UI 框架 | 3.35.5 |
| **Dart** | 编程语言 | 3.9.2 |
| **Provider** | 状态管理 | ^6.1.2 |
| **GoRouter** | 路由管理 | ^10.2.0 |
| **SQLite** | 本地数据库 | sqflite ^2.3.3 |
| **flutter_local_notifications** | 本地通知 | ^17.2.3 |
| **speech_to_text** | 语音识别 | ^7.3.0 |
| **image_picker** | 图片选择 | ^1.1.2 |
| **flutter_markdown** | Markdown 渲染 | ^0.6.23 |
| **http** | 网络请求 | ^1.2.2 |
| **webdav_client** | WebDAV 同步 | ^1.2.2 |
| **google_fonts** | 字体库 | ^6.2.1 |
| **graphview** | 知识图谱可视化 | ^1.5.0 |
| **Umeng SDK** | 数据统计（原生） | iOS & Android |

### 项目结构

```
InkRoot/
├── android/                    # Android 原生代码
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/        # Kotlin 代码
│   │   │   ├── res/           # Android 资源
│   │   │   └── AndroidManifest.xml
│   │   ├── build.gradle       # 应用级 Gradle 配置
│   │   └── key.properties     # 签名配置
│   └── build.gradle           # 项目级 Gradle 配置
│
├── ios/                        # iOS 原生代码
│   ├── Runner/
│   │   ├── AppDelegate.swift  # 应用代理
│   │   ├── Info.plist         # iOS 配置
│   │   └── Assets.xcassets/   # iOS 资源
│   ├── Podfile                # CocoaPods 配置
│   └── Runner.xcodeproj/      # Xcode 项目
│
├── lib/                        # Flutter 源代码
│   ├── config/                 # 配置文件
│   │   ├── app_config.dart    # 应用配置（服务器地址、版本信息等）
│   │   └── asset_config.dart  # 资源配置
│   │
│   ├── l10n/                   # 国际化资源（7个文件）
│   │   ├── app_localizations.dart        # 本地化基类
│   │   ├── app_localizations_simple.dart # 简化的本地化实现
│   │   ├── app_localizations_zh.dart     # 中文本地化
│   │   ├── app_localizations_en.dart     # 英文本地化
│   │   ├── app_zh.arb                    # 中文资源文件
│   │   ├── app_en.arb                    # 英文资源文件
│   │   └── translations.dart             # 翻译工具
│   │
│   ├── models/                 # 数据模型（12个文件）
│   │   ├── annotation_model.dart          # 批注模型
│   │   ├── announcement_model.dart        # 公告模型
│   │   ├── app_config_model.dart          # 应用配置模型
│   │   ├── cloud_verification_models.dart # 云验证模型
│   │   ├── load_more_state.dart           # 加载状态模型
│   │   ├── note_model.dart                # 笔记模型（核心）
│   │   ├── reminder_notification_model.dart  # 提醒通知模型
│   │   ├── sidebar_config.dart            # 侧边栏配置模型
│   │   ├── sort_order.dart                # 排序选项模型
│   │   ├── tag_color_model.dart           # 标签颜色模型
│   │   ├── user_model.dart                # 用户模型
│   │   └── webdav_config.dart             # WebDAV配置模型
│   │
│   ├── providers/              # 状态管理
│   │   └── app_provider.dart  # 全局应用状态（核心）
│   │
│   ├── routes/                 # 路由配置
│   │   └── app_router.dart    # GoRouter 路由配置
│   │
│   ├── screens/                # 页面 UI（33个文件）
│   │   ├── about_screen.dart             # 关于页面
│   │   ├── account_info_screen.dart      # 账户信息页
│   │   ├── ai_settings_screen.dart       # AI设置页
│   │   ├── data_cleanup_screen.dart      # 数据清理页
│   │   ├── feedback_screen.dart          # 反馈页面
│   │   ├── flomo_import_screen.dart      # Flomo导入页 🆕
│   │   ├── forgot_password_screen.dart   # 忘记密码页
│   │   ├── help_screen.dart              # 帮助页面
│   │   ├── home_screen.dart              # 主页（核心）
│   │   ├── import_export_main_screen.dart # 导入导出主页 🆕
│   │   ├── knowledge_graph_screen_custom.dart  # 知识图谱页
│   │   ├── laboratory_screen.dart        # 实验室功能页
│   │   ├── local_backup_restore_screen.dart # 本地备份恢复页 🆕
│   │   ├── login_screen.dart             # 登录页
│   │   ├── note_detail_screen.dart       # 笔记详情页（核心）
│   │   ├── notion_settings_screen.dart   # Notion设置页
│   │   ├── notifications_screen.dart     # 通知管理页
│   │   ├── onboarding_screen.dart        # 引导页
│   │   ├── performance_dashboard_screen.dart # 性能仪表板页
│   │   ├── preferences_screen.dart       # 偏好设置页
│   │   ├── privacy_policy_screen.dart    # 隐私政策页
│   │   ├── random_review_screen.dart     # 随机回顾页
│   │   ├── register_screen.dart          # 注册页
│   │   ├── server_info_screen.dart       # 服务器信息页
│   │   ├── settings_screen.dart          # 设置页
│   │   ├── sidebar_customization_screen.dart # 侧边栏自定义页 🆕
│   │   ├── tag_notes_screen.dart         # 标签笔记页 🆕
│   │   ├── tags_screen.dart              # 标签管理页
│   │   ├── user_agreement_screen.dart    # 用户协议页
│   │   ├── user_preferences_screen.dart  # 用户偏好页 🆕
│   │   ├── webdav_settings_screen.dart   # WebDAV设置页
│   │   └── weread_import_screen.dart     # 微信读书导入页
│   │
│   ├── services/               # 业务逻辑层（40个文件）
│   │   ├── ai_enhanced_service.dart      # AI 增强服务
│   │   ├── ai_insight_engine.dart        # AI 洞察引擎 🆕
│   │   ├── ai_related_notes_service.dart # AI 相关笔记服务
│   │   ├── alert_service.dart            # 告警服务
│   │   ├── announcement_service.dart     # 公告服务
│   │   ├── api_service_factory.dart      # API 服务工厂
│   │   ├── api_service.dart              # API 服务基类
│   │   ├── cloud_verification_service.dart # 云验证服务
│   │   ├── database_service.dart         # 本地数据库服务（核心）
│   │   ├── deepseek_api_service.dart     # DeepSeek AI API 服务
│   │   ├── flomo_parser.dart             # Flomo解析服务 🆕
│   │   ├── feature_flag_service.dart     # 功能开关服务
│   │   ├── graph_data_service.dart       # 知识图谱数据服务
│   │   ├── incremental_sync_service.dart # 增量同步服务
│   │   ├── intelligent_related_notes_service.dart # 智能相关笔记 🆕
│   │   ├── ios_permission_service.dart   # iOS权限服务
│   │   ├── ios_update_service.dart       # iOS更新服务 🆕
│   │   ├── local_reference_service.dart  # 本地引用服务
│   │   ├── logger_service.dart           # 日志服务
│   │   ├── memos_api_service_fixed.dart  # Memos API 实现
│   │   ├── memos_resource_service.dart   # Memos资源管理服务
│   │   ├── note_actions_service.dart     # 笔记操作服务 🆕
│   │   ├── notion_api_service.dart       # Notion API服务
│   │   ├── notion_sync_service.dart      # Notion同步服务
│   │   ├── notification_service.dart     # 通知服务
│   │   ├── observability_service.dart    # 可观测性服务
│   │   ├── performance_monitor_service.dart # 性能监控服务
│   │   ├── permission_manager.dart       # 权限管理服务
│   │   ├── preferences_service.dart      # 本地偏好设置服务
│   │   ├── reminder_notification_service.dart # 提醒通知服务
│   │   ├── sentry_monitoring_service.dart # Sentry监控服务
│   │   ├── simple_permission_service.dart # 简化权限服务
│   │   ├── speech_service.dart           # 语音识别服务
│   │   ├── tag_ai_service.dart           # 标签AI服务 🆕
│   │   ├── umeng_analytics_service.dart  # 友盟统计服务
│   │   ├── unified_reference_manager.dart # 统一引用管理
│   │   ├── user_behavior_service.dart    # 用户行为服务 🆕
│   │   ├── webdav_service.dart           # WebDAV 服务
│   │   ├── webdav_sync_engine.dart       # WebDAV 同步引擎
│   │   └── weread_parser.dart            # 微信读书解析服务
│   │
│   ├── themes/                 # 主题样式（3个文件）
│   │   ├── app_theme.dart     # 应用主题定义
│   │   ├── app_typography.dart # 字体排版
│   │   └── typography.dart    # 排版工具
│   │
│   ├── utils/                  # 工具类（15个文件）
│   │   ├── error_handler.dart        # 错误处理器
│   │   ├── image_cache_manager.dart  # 图片缓存管理
│   │   ├── image_utils.dart          # 图片工具
│   │   ├── logger.dart               # 日志工具
│   │   ├── memos_markdown_converter.dart # Memos Markdown转换
│   │   ├── network_utils.dart        # 网络工具
│   │   ├── performance_tracker.dart  # 性能追踪器
│   │   ├── responsive_utils.dart     # 响应式布局工具
│   │   ├── share_image_widget.dart   # 分享图片组件
│   │   ├── share_utils.dart          # 分享工具
│   │   ├── snackbar_utils.dart       # 提示框工具
│   │   ├── tag_utils.dart            # 标签工具 🆕
│   │   ├── text_style_helper.dart    # 文本样式助手
│   │   ├── time_utils.dart           # 时间工具
│   │   └── todo_parser.dart          # 待办事项解析器 🆕
│   │
│   ├── widgets/                # 自定义组件（24个文件）
│   │   ├── animated_checkbox.dart         # 动画复选框
│   │   ├── annotations_sidebar.dart       # 批注侧边栏
│   │   ├── cached_avatar.dart             # 缓存头像组件
│   │   ├── desktop_layout.dart            # 桌面布局
│   │   ├── heatmap.dart                   # 活跃热力图组件
│   │   ├── intelligent_related_notes_sheet.dart # 智能相关笔记
│   │   ├── interactive_markdown.dart      # 交互式Markdown
│   │   ├── ios_datetime_picker.dart       # iOS日期时间选择器
│   │   ├── note_card.dart                 # 笔记卡片组件
│   │   ├── note_editor.dart               # 笔记编辑器
│   │   ├── note_more_options_menu.dart    # 笔记更多选项
│   │   ├── permission_dialog.dart         # 权限请求对话框
│   │   ├── permission_guide_dialog.dart   # 权限引导对话框
│   │   ├── privacy_policy_dialog.dart     # 隐私政策弹窗
│   │   ├── progress_overlay.dart          # 进度遮罩层
│   │   ├── references_sidebar.dart        # 引用侧边栏
│   │   ├── related_notes_bottom_sheet.dart # 相关笔记底部表单
│   │   ├── saveable_image.dart            # 可保存图片组件
│   │   ├── share_image_preview_screen.dart # 分享图片预览
│   │   ├── sidebar.dart                   # 侧边栏组件
│   │   ├── simple_memo_content.dart       # 简化备忘录内容
│   │   ├── tag_color_picker.dart          # 标签颜色选择器
│   │   ├── tag_tree_item.dart             # 标签树项组件
│   │   └── update_dialog.dart             # 更新提示对话框
│   │
│   └── main.dart               # 应用入口
│
├── assets/                     # 资源文件
│   ├── images/                 # 图片资源（2个文件）
│   │   ├── black2logo.png     # 黑色Logo
│   │   └── logo.png           # 应用图标
│   └── fonts/                  # 字体文件（5个文件）
│       ├── SF-Mono-Regular.ttf
│       ├── SF-Pro-Display-Bold.ttf
│       ├── SF-Pro-Display-Light.ttf
│       ├── SF-Pro-Display-Medium.ttf
│       └── SF-Pro-Display-Regular.ttf
│
├── docs/                       # 项目文档
│   ├── api/                    # API 文档
│   │   ├── README.md           # API 参考文档（中文）
│   │   └── README.zh.md        # API 参考文档（中文）
│   ├── architecture/           # 架构文档
│   │   ├── adr/                # 架构决策记录
│   │   │   └── README.md       # ADR 索引
│   │   └── README.md           # 架构概述
│   ├── development/            # 开发文档
│   │   ├── debugging.md        # 调试指南
│   │   └── troubleshooting.md  # 故障排除
│   ├── user-guide/             # 用户指南
│   │   ├── README.md           # 用户手册
│   │   └── getting-started.md  # 快速入门
│   ├── TAG_FEATURES_V2.md      # 标签功能设计文档 🆕
│   ├── UX_OPTIMIZATION_TAGS.md # 标签UX优化文档 🆕
│   └── README.md               # 文档索引
│
├── scripts/                    # 构建脚本
│   └── dmg/                    # macOS DMG 打包脚本
│       ├── create_dmg.sh       # DMG 创建脚本
│       ├── background.png      # DMG 背景图
│       └── README.md           # 打包说明
│
├── releases/                   # 发布文件（不上传Git）
├── dmg_assets/                 # macOS DMG 资源
│
├── pubspec.yaml               # Flutter 项目配置
├── pubspec.lock               # 依赖锁定文件
├── analysis_options.yaml      # 代码分析配置
├── analysis_options_strict.yaml # 严格代码分析配置
├── flutter_native_splash.yaml # 启动屏幕配置
├── l10n.yaml                  # 国际化配置
├── README.md                  # 项目说明文档（中文）
├── README.en.md               # 项目说明文档（英文）
├── CHANGELOG.md               # 变更日志
├── LICENSE                    # MIT开源协议
├── CONTRIBUTING.md            # 贡献指南
├── CODE_OF_CONDUCT.md         # 行为准则
├── SECURITY.md                # 安全政策
├── TESTING.md                 # 测试指南（英文）
├── TESTING.zh.md              # 测试指南（中文）
├── .gitignore                 # Git忽略规则
├── .editorconfig              # 编辑器配置
├── .env.example               # 环境变量示例
└── build/                     # 构建产物（不上传Git）
```

### 📊 维护状态

- 版本单一真源：`pubspec.yaml`
- 本地维护入口：`dart tool/inkroot.dart`
- CI 覆盖：Analyze、Test、Secret Scan、Android、iOS 模拟器、macOS、Windows、Linux
- 发版说明：见 [维护指南](docs/MAINTENANCE.md)
- Android 签名：见 [Android 签名说明](scripts/ANDROID_SIGNING.md)

### 架构设计

InkRoot 采用分层架构设计，核心代码按 UI、状态管理、业务服务和数据层组织：

```
┌─────────────────────────────────────┐
│         Presentation Layer          │  UI 层（Screens + Widgets）
│  (Flutter Widgets & Screens)        │
└─────────────────────────────────────┘
              ↓↑
┌─────────────────────────────────────┐
│        State Management Layer       │  状态管理层（Provider）
│           (Provider)                 │
└─────────────────────────────────────┘
              ↓↑
┌─────────────────────────────────────┐
│         Business Logic Layer        │  业务逻辑层（Services）
│           (Services)                 │
└─────────────────────────────────────┘
              ↓↑
┌──────────────────┬──────────────────┐
│   Data Layer     │   Data Layer     │  数据层
│  (Local SQLite)  │ (Remote Memos)   │
└──────────────────┴──────────────────┘
```

#### 数据流

1. **用户操作** → UI 组件
2. **UI 组件** → 触发 Provider 状态更新
3. **Provider** → 调用 Service 层业务逻辑
4. **Service** → 与本地数据库或远程 API 交互
5. **数据返回** → 更新 Provider 状态 → UI 自动刷新

---

## ⚙️ 配置说明

### Memos 服务器配置

#### 支持的版本

- Memos API v1
- 已适配 v0.21.x 到 v0.28.x 的主要 API 差异
- 不建议使用 v0.20.x 及以下版本

#### 服务器地址格式

```
# HTTP (本地测试)
http://localhost:5230
http://192.168.1.100:5230

# HTTPS (生产环境推荐)
https://your-domain.com
https://memos.example.com
```

### 应用配置文件

主要配置位于 `lib/config/app_config.dart`。运行时版本号来自打包元数据，也就是 `pubspec.yaml` 中的 `version` 字段：

```dart
class AppConfig {
  static String get appVersion => AppInfoService.version;
  static String get buildNumber => AppInfoService.buildNumber;
}
```

### 权限配置

#### iOS 权限 (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限以使用语音识别功能</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限以选择和保存图片</string>

<key>NSCameraUsageDescription</key>
<string>需要相机权限以拍摄照片</string>
```

#### Android 权限 (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

---

## 🛠️ 开发指南

### 环境搭建

#### 1. 安装 Flutter

参考 [Flutter 官方文档](https://flutter.dev/docs/get-started/install)

```bash
# 检查 Flutter 环境
flutter doctor

# 输出示例：
# [✓] Flutter (Channel stable, 3.35.5)
# [✓] Android toolchain
# [✓] Xcode (iOS 开发)
# [✓] Android Studio
```

#### 2. 克隆项目

```bash
git clone https://github.com/yyyyymmmmm/InkRoot.git
cd InkRoot
```

#### 3. 安装依赖

```bash
flutter pub get
```

#### 4. 配置开发环境

```bash
# 查看可用设备
flutter devices

# 运行应用（开发模式）
flutter run

# 运行在指定设备
flutter run -d <device-id>
```

### 开发规范

#### 代码风格

- 遵循 [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- 使用 `flutter format` 格式化代码
- 提交前运行 `flutter analyze` 检查代码

#### 命名规范

- 文件名：使用小写 + 下划线（如：`note_detail_screen.dart`）
- 类名：使用大驼峰（如：`NoteDetailScreen`）
- 变量名：使用小驼峰（如：`noteTitle`）
- 常量名：使用小写 + 下划线（如：`api_base_url`）

#### Git 提交规范

```
feat: 新功能
fix: 修复问题
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具相关

示例：
feat: 添加语音识别功能
fix: 修复笔记同步失败的问题
docs: 更新 README 安装说明
```

### 调试技巧

#### 启用调试日志

在 `lib/config/app_config.dart` 中设置：

```dart
static const bool debugMode = true;
static const bool verboseLogging = true;
static const bool enableNetworkLogging = true;
```

#### 查看网络请求

```bash
# 使用 Charles 或 Fiddler 抓包
flutter run --dart-define=ENABLE_NETWORK_LOGGING=true
```

#### 性能分析

```bash
# 启动性能分析
flutter run --profile

# 打开 DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 📝 API 文档

InkRoot 使用 Memos v1 API。以下是主要接口说明：

### 认证接口

#### 用户登录

```http
POST /api/v1/auth/signin
Content-Type: application/json

{
  "username": "your_username",
  "password": "your_password"
}

Response:
{
  "user": {
    "id": 1,
    "username": "your_username",
    "email": "user@example.com",
    ...
  },
  "accessToken": "jwt_token_here"
}
```

#### 用户注册

```http
POST /api/v1/auth/signup
Content-Type: application/json

{
  "username": "your_username",
  "password": "your_password",
  "email": "user@example.com"
}
```

### 笔记接口

#### 获取笔记列表

```http
GET /api/v1/memo?limit=20&offset=0
Authorization: Bearer {access_token}

Response:
[
  {
    "id": 1,
    "content": "笔记内容",
    "visibility": "PRIVATE",
    "createdTs": 1234567890,
    "updatedTs": 1234567890,
    ...
  }
]
```

#### 创建笔记

```http
POST /api/v1/memo
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "content": "笔记内容",
  "visibility": "PRIVATE"
}
```

#### 更新笔记

```http
PATCH /api/v1/memo/{id}
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "content": "更新后的内容"
}
```

#### 删除笔记

```http
DELETE /api/v1/memo/{id}
Authorization: Bearer {access_token}
```

### 资源接口

#### 上传图片

```http
POST /api/v1/resource/blob
Authorization: Bearer {access_token}
Content-Type: multipart/form-data

file: <binary_data>
```

#### 获取资源列表

```http
GET /api/v1/resource?limit=20&offset=0
Authorization: Bearer {access_token}
```

更多 API 详情请参考：
- [InkRoot API 文档](docs/api/README.md) - 完整的 API 参考文档
- [Memos API 文档](https://github.com/usememos/memos#api) - Memos 官方文档

---

## 📚 完整文档

InkRoot 提供了完整的文档体系，帮助你更好地使用和开发：

### 📖 用户文档

- **[用户指南](docs/user-guide/README.md)** - 完整的用户使用手册
  - [快速入门](docs/user-guide/getting-started.md) - 从零开始使用 InkRoot
  - [功能详解](docs/user-guide/features/) - 各个功能的详细说明
  - [常见问题](docs/user-guide/faq.md) - 常见问题解答
  - [故障排除](docs/user-guide/troubleshooting.md) - 问题解决方案

### 🔧 开发者文档

- **[开发指南](CONTRIBUTING.md)** - 如何参与项目开发
  - [调试指南](docs/development/debugging.md) - 调试技巧和工具
  - [故障排除](docs/development/troubleshooting.md) - 开发常见问题
  - [代码规范](CONTRIBUTING.md#dart-style-guide) - 编码标准

### 🏗️ 架构文档

- **[架构文档](docs/architecture/README.md)** - 系统架构设计
  - [架构概述](docs/architecture/README.md#architecture-overview) - 整体架构说明
  - [架构决策记录 (ADR)](docs/architecture/adr/README.md) - 重要架构决策
  - [数据库设计](docs/architecture/database-schema.md) - 数据库结构
  - [安全设计](docs/architecture/security-design.md) - 安全架构

### 📝 API 文档

- **[API 参考](docs/api/README.md)** - 完整的 API 文档
  - [认证接口](docs/api/README.md#authentication) - 用户认证
  - [笔记接口](docs/api/README.md#notes-memos) - 笔记 CRUD
  - [资源接口](docs/api/README.md#resources-images-files) - 图片和文件
  - [使用示例](docs/api/README.md#examples) - 代码示例

### 🧪 测试文档

- **[测试指南](TESTING.md)** - 测试策略和最佳实践
  - [单元测试](TESTING.md#unit-tests) - 测试个别组件
  - [Widget 测试](TESTING.md#widget-tests) - 测试 UI 组件
  - [集成测试](TESTING.md#integration-tests) - 测试完整流程
  - [运行测试](TESTING.md#running-tests) - 如何运行测试

### 📋 其他文档

- [变更日志](CHANGELOG.md) - 版本更新记录
- [发布说明](RELEASE_NOTES.md) - 最新版本说明
- [安全政策](SECURITY.md) - 安全相关信息
- [行为准则](CODE_OF_CONDUCT.md) - 社区行为规范

### 🌍 多语言文档

- 🇨🇳 [中文文档](README.md) - 当前文档
- 🇺🇸 [English Documentation](README.en.md) - English version

---

## 🧪 测试指南

InkRoot 遵循严格的测试标准，确保代码质量。

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage

# 运行特定测试文件
flutter test test/unit/models/note_model_test.dart

# 运行集成测试
flutter test integration_test/app_test.dart
```

### 测试覆盖率目标

| 组件 | 目标覆盖率 |
|------|-----------|
| Models | 90% |
| Services | 80% |
| Widgets | 70% |
| Screens | 60% |
| Utils | 85% |
| **总体** | **75%** |

### 编写测试

```dart
// 单元测试示例
test('should parse markdown todo items', () {
  // Arrange
  final note = NoteModel(
    content: '- [ ] Todo item\n- [x] Completed',
  );

  // Act
  final todos = note.getTodoItems();

  // Assert
  expect(todos.length, 2);
  expect(todos[0].isCompleted, false);
  expect(todos[1].isCompleted, true);
});
```

更多测试相关信息，请查看 [完整测试指南](TESTING.md)。

---

## 📜 更新日志

### v1.0.7 (2025-10-25)

#### 🎉 新增功能
- ✅ **待办事项功能** - 完整的 Markdown 任务列表支持
  - 支持 `- [ ]` / `- [x]` 语法
  - 点击复选框直接切换完成状态
  - 精美的动画效果（AnimatedCheckbox 组件）
  - 触觉反馈（iOS/Android 原生振动）
  - 自动保存到笔记内容，实时同步
  - 交互式 Markdown 渲染（InteractiveMarkdown）
  - 待办事项解析器（TodoParser）

- 📷 **图片保存功能** - 笔记图片一键保存
  - 图片长按弹出"保存图片"选项
  - 智能权限请求和引导
  - 自动保存到系统相册
  - 保存成功提示和相册定位
  - 支持所有图片格式（JPG、PNG、GIF、WebP 等）
  - SaveableImage 组件封装

#### 🤖 AI 功能优化
- 🤖 **AI 响应速度提升** - 优化 DeepSeek API 调用流程
- 🤖 **内容生成质量改进** - 优化 Prompt 和参数配置
- 🤖 **相关笔记推荐增强** - 智能分析笔记关联度
- 🤖 **AI 设置界面优化** - 改进交互体验和配置选项

#### 📋 更多菜单优化
- 📋 **重新设计"更多"菜单** - 全新的 NoteMoreOptionsMenu 组件
- 📌 **置顶/取消置顶** - 新增笔记置顶功能，支持服务器同步
- 📤 **分享功能增强** - 优化分享选项和样式
- 📁 **导出功能改进** - 更清晰的导出选项
- 🎨 **菜单布局优化** - 改进图标、文字、分组

#### 🐛 重要 Bug 修复
- 🐛 **修复刷新后置顶状态丢失** - 改进数据合并逻辑，保留本地置顶状态
- 🐛 **修复 Android Firebase 错误** - 禁用 Sentry 自动 Firebase 集成，过滤相关错误
- 🐛 **修复图片加载问题** - 优化图片缓存和加载策略
- 🐛 **修复同步冲突** - 改进服务器同步和本地数据合并

#### 🔧 技术优化
- 🔧 新增 7 个核心文件（TodoParser、AnimatedCheckbox、SaveableImage、InteractiveMarkdown、NoteMoreOptionsMenu 等）
- 🔧 优化 AppProvider 数据合并逻辑
- 🔧 改进 Memos API Service，新增 memo_organizer 接口
- 🔧 优化性能追踪和错误处理

#### 📦 技术细节
- 📦 版本号：1.0.7+10007（从 1.0.6+6 升级）
- 📦 新增 7 个核心组件和工具类
- 📦 优化了 54 个文件
- 📦 项目大小：110MB（清理后）

---

### v1.0.6 (2025-10-23)

#### 🐛 修复
- 🐛 **修复WebDAV同步问题** - 修复同步冲突、优化重试机制、改进文件上传稳定性

#### ⚡ 性能优化
- 🚀 **优化启动速度** - 启动时间减少30%，改进资源加载策略
- 🎨 **增加启动页** - 新增精美的原生启动页，支持深色/浅色主题自适应

#### 🎨 UI/UX
- 🎨 **优化个人中心** - 改进个人信息展示、优化头像上传体验

#### 🔧 其他
- 🔧 修复部分Bug，提升整体稳定性

### v1.0.5 (2025-10-19)

#### 🎉 新增
- ✨ **隐私合规功能** - 首次启动显示隐私政策弹窗，符合应用商店审核规范
- ✨ **友盟统计SDK** - 支持 iOS 和 Android 双平台数据统计，帮助改进产品
- ✨ **AI相关笔记服务** - 智能分析笔记关联关系，支持笔记推荐功能
- ✨ **AI增强服务** - 优化AI响应速度，提升内容生成质量
- ✨ **WebDAV服务重构** - 拆分为独立模块（webdav_service + webdav_sync_engine），提升稳定性

#### 🎨 UI/UX
- 🎨 **隐私政策弹窗** - 简洁优雅的大厂风格设计，支持点击查看完整协议
- 🎨 **相关笔记底部表单** - 优化笔记关联查看体验
- 🎨 **简化备忘录内容展示** - 提升阅读体验，减少加载时间

#### 🔧 优化
- 🔧 优化应用启动流程，确保隐私政策弹窗正常显示
- 🔧 改进原生代码通信（iOS/Android MethodChannel）
- 🔧 优化 PreferencesService，新增隐私政策同意状态存储

#### 🐛 修复
- 🐛 修复 iOS 模拟器运行时 Umeng SDK 兼容性问题
- 🐛 修复 Android 端 Umeng 事件上报的 ClassCastException 错误
- 🐛 修复路由重定向导致 splash 页面被跳过的问题
- 🐛 修复 onboarding_screen.dart 中的编译错误

#### 📦 技术细节
- 📦 版本号：1.0.5+6（从 1.0.4+5 升级）
- 📦 新增 5 个服务文件、3 个 Widget 组件
- 📦 iOS Podfile 新增 Umeng 依赖（UMCommon、UMDevice、UMAPM）
- 📦 原生代码更新（AppDelegate.swift、MainActivity.kt）

---

### v1.0.4 (2025-10-08)

#### 🎉 新增
- ✨ **AI 智能助手** - 集成 DeepSeek AI，智能写作辅助
- ✨ **自定义字体** - 支持 4 档字体大小 + 6 种精选字体
- ✨ **英语支持** - 完整的英文界面翻译
- ✨ **知识图谱功能** - 可视化展示笔记关联关系，构建知识网络
- ✨ **热力图月份切换** - 支持查看不同月份的笔记活跃度
- ✨ **笔记详情页优化** - 完善"更多"功能菜单

#### 🔧 优化
- 🔧 优化通知中心UI设计（时间分组、滑动删除、触觉反馈）
- 🔧 优化登录/注册页面（新增FAQ帮助）
- 🔧 改进偏好设置页面（新增字体设置分组）
- 🔧 统一应用主题配色和视觉风格

#### 🐛 修复
- 🐛 修复部分界面显示问题
- 🐛 修复通知相关Bug
- 🐛 修复字体切换后部分界面未刷新的问题
- 🐛 优化各项功能稳定性

### v1.0.3 (2025-10-06)

#### 🎉 新增
- ✨ 更新到 Flutter 3.35.5
- ✨ 优化 APK 构建配置，支持分架构构建
- ✨ 更新主题系统，适配最新 Material Design 3

#### 🔧 优化
- 🔧 修复头像加载问题
- 🔧 优化图片缓存机制
- 🔧 改进网络请求错误处理

#### 🐛 修复
- 🐛 修复部分 Android 设备通知不显示的问题
- 🐛 修复语音识别在某些设备上崩溃的问题
- 🐛 修复深色模式下部分文字看不清的问题

### v1.0.2 (2025-09-30)

#### 🆕 新增
- 🏢 实验室新增企业微信对接功能
- 📊 新增笔记统计功能
- 🎲 新增随机回顾功能

#### 🔧 优化
- 🔧 修复头像加载问题
- 🔧 优化笔记列表加载性能
- 🔧 改进同步机制，减少流量消耗

#### 🐛 修复
- 🐛 修复已知 Bug
- 🐛 修复部分 iOS 设备闪退问题

### v1.0.1 (2025-09-20)

#### 🎉 首次发布
- ✨ 完整的笔记管理功能
- 📱 Android 和 iOS 双平台支持
- 🔄 Memos 服务器同步
- 🎤 语音识别功能
- 🏷️ 标签系统
- ⏰ 定时提醒
- 🌓 深色模式

---

## 🚀 开发路线图

### ✅ 已完成功能（v1.0.0 - v1.0.7）

#### 核心功能
- ✅ **Markdown 支持** - 完整语法支持，代码高亮、表格、任务列表
- ✅ **待办事项** - 交互式任务列表，点击切换状态（v1.0.7）
- ✅ **本地模式** - 无需服务器，开箱即用
- ✅ **云端同步** - 适配 Memos 多版本 API，支持实时同步
- ✅ **WebDAV 同步** - 支持 WebDAV 服务器同步
- ✅ **离线编辑** - 离线可用，自动同步

#### AI 智能功能（已深度集成）
- ✅ **DeepSeek AI 集成** - 智能写作助手（v1.0.4）
- ✅ **AI 内容优化** - 智能优化和扩展笔记内容（v1.0.7）
- ✅ **相关笔记推荐** - AI 分析笔记关联关系（v1.0.7）
- ✅ **AI 洞察引擎** - 深度分析笔记内容和结构（v1.0.7）
- ✅ **智能相关笔记** - AI 驱动的笔记关联推荐（v1.0.7）

#### 多媒体功能
- ✅ **图片管理** - 上传、预览、裁剪、压缩
- ✅ **图片保存** - 长按保存到相册（v1.0.7）
- ✅ **语音识别** - 实时语音转文字

#### 组织与管理
- ✅ **标签系统** - 灵活的标签分类和管理
- ✅ **笔记置顶** - 重要笔记置顶显示（v1.0.7）
- ✅ **全文搜索** - 多维度快速搜索
- ✅ **笔记引用** - `[[笔记标题]]` 双向链接
- ✅ **反向链接** - 自动显示引用关系
- ✅ **知识图谱** - 可视化展示笔记关联网络（v1.0.4）

#### 智能提醒与回顾
- ✅ **定时提醒** - 支持一次性和重复提醒
- ✅ **随机回顾** - 随机抽取历史笔记复习

#### 数据管理
- ✅ **导入导出** - JSON/Markdown 格式导出
- ✅ **批量导出** - 支持批量备份
- ✅ **数据统计** - 笔记数量、字数统计

#### 用户体验
- ✅ **深色模式** - 日夜双主题自动切换
- ✅ **自定义字体** - 4 档字号 + 6 种字体（v1.0.4）
- ✅ **多语言支持** - 中文、英文（v1.0.4）
- ✅ **活跃热力图** - 月份切换查看活跃度（v1.0.4）
- ✅ **隐私合规** - 隐私政策弹窗（v1.0.5）
- ✅ **友盟统计** - 使用数据分析（v1.0.5）
- ✅ **精美启动页** - 主题自适应启动屏幕（v1.0.6）

---

### 🚀 近期计划（v1.1.0 - v1.2.0）

#### 1️⃣ 对接微信助手（v1.1.0）🔥
- 💬 **企业微信机器人** - 笔记推送到企业微信群
- 📤 **微信分享优化** - 一键分享笔记到微信
- 🔔 **微信消息提醒** - 笔记提醒通过微信推送
- 📱 **微信小程序** - 快速查看和创建笔记
- *基础企业微信对接已在 v1.0.2 实验室中测试*

#### 2️⃣ 视频等附件支持（v1.1.0）📎
- 🎬 **视频附件** - 支持 MP4、MOV 等格式
- 🎵 **音频附件** - 支持 MP3、WAV、M4A 等格式
- 📄 **文档附件** - 支持 PDF、Word、Excel 等
- 📎 **附件管理** - 统一的附件查看和管理
- 🔗 **附件同步** - 支持服务器和 WebDAV 同步
- 💾 **离线播放** - 本地缓存，离线可用

#### 3️⃣ 自定义主题（v1.1.0）🎨
- 🌈 **预设主题** - 10+ 精美主题配色
- 🎨 **自定义配色** - 完全自定义主题颜色
- 🖌️ **主题编辑器** - 可视化主题设计工具
- 📤 **主题分享** - 导出和导入主题配置
- 🌙 **独立深色主题** - 深色和浅色主题独立配置
- *基础字体自定义已在 v1.0.4 实现*

#### 4️⃣ 更多语言支持（v1.1.0）🌍
- 🇯🇵 **日文** - 完整的日语界面翻译
- 🇰🇷 **韩文** - 完整的韩语界面翻译
- 🇪🇸 **西班牙语** - 西班牙语支持
- 🇫🇷 **法语** - 法语界面支持
- 🇩🇪 **德语** - 德语界面支持
- 🌐 **社区翻译** - 开放翻译贡献渠道
- *英文支持已在 v1.0.4 实现*

#### 5️⃣ 其他功能增强（v1.1.x）
- 📱 **平板适配** - 优化 iPad 和 Android 平板体验
- 📁 **文件夹功能** - 支持笔记分文件夹管理
- 🔗 **笔记分享链接** - 生成分享链接和二维码
- 🔍 **高级搜索** - 正则表达式、多条件组合搜索
- 🔒 **笔记加密** - 单条笔记加密保护
- 📊 **数据可视化增强** - 更丰富的统计图表

#### 6️⃣ 性能优化（v1.1.x）
- 💾 **内存优化** - 降低内存占用
- 🖼️ **图片加载优化** - 智能预加载
- 🔄 **同步机制改进** - 冲突处理、断点续传
- 🔋 **电池优化** - 降低后台耗电

---

### 🔮 中期计划（v1.3.0 - v2.0.0）

#### AI 功能增强（v1.3.0）🤖
- 🧠 **智能分类** - AI 自动为笔记分类打标签
- 📝 **智能摘要** - 自动生成笔记摘要
- 🔍 **语义搜索** - 基于语义理解的智能搜索
- 💬 **AI 对话** - 与笔记库对话，智能问答
- 🌐 **多模型支持** - 支持 GPT、Claude 等多种 AI 模型
- *基础 AI 深度集成已在 v1.0.4 - v1.0.7 完成*

#### 多平台扩展（v1.4.0 - v1.5.0）
- 📱 **Widget 小部件** - iOS 和 Android 桌面小部件
- ⌚ **Apple Watch** - 快速记录和查看笔记
- 🖥️ **桌面版** - macOS 和 Windows 客户端
- 🔗 **浏览器扩展** - Chrome/Safari/Firefox 快速剪藏

---

### 🌟 长期愿景（v2.0+）

#### 开放生态（v2.0+）🤝
- 🔌 **插件系统** - 支持第三方插件开发
- 🛠️ **插件商店** - 社区插件市场
- 📚 **API 开放** - 完整的 REST API 和 SDK
- 🌐 **Webhook 集成** - 与第三方服务集成
- 💻 **开发者文档** - 完善的插件开发文档
- 🎨 **主题商店** - 社区主题分享平台

#### 平台统一（v2.5+）
- 🌐 **多平台统一** - 一套账号，全平台同步
- ☁️ **云端存储** - 官方云存储服务（可选）
- 🔄 **实时同步** - 毫秒级实时多端同步
- 📱 **统一体验** - 所有平台一致的用户体验

---

### 💡 参与讨论

我们非常重视社区的声音！

- 💬 **功能建议**：[GitHub Discussions](https://github.com/yyyyymmmmm/InkRoot/discussions)
- 🐛 **Bug 反馈**：[GitHub Issues](https://github.com/yyyyymmmmm/InkRoot/issues)
- 📧 **直接联系**：[inkroot2025@gmail.com](mailto:inkroot2025@gmail.com)

**你的每一个建议都可能成为下一个版本的功能！** 🚀

---

## 🔐 隐私与数据安全

InkRoot 非常重视用户隐私和数据安全。

### 数据存储

#### 本地模式
- ✅ **所有数据存储在本地设备**
- ✅ **不上传到任何服务器**
- ✅ **数据完全由你控制**
- ✅ **可随时导出备份**

#### 云端模式
- ✅ **数据存储在你自己的 Memos 服务器**
- ✅ **不经过第三方服务器**
- ✅ **支持自建服务器，保障数据私有**
- ✅ **传输过程使用 HTTPS 加密**

### 数据统计

从 v1.0.5 开始，InkRoot 集成了友盟统计 SDK，用于收集应用使用数据，帮助我们改进产品体验。

#### 收集的数据
- 📊 应用启动次数
- 📊 页面访问情况
- 📊 功能使用频率
- 📊 错误和崩溃日志
- 📊 设备型号和系统版本

#### 不收集的数据
- ❌ **笔记内容**
- ❌ **个人身份信息**
- ❌ **账号密码**
- ❌ **服务器地址**
- ❌ **任何敏感数据**

#### 数据使用
- 仅用于改进产品体验
- 帮助优化应用性能
- 发现和修复问题
- 不会出售给第三方
- 不会用于广告推送

### 隐私政策

详细隐私政策请访问：[https://inkroot.cn/privacy.html](https://inkroot.cn/privacy.html)

如有隐私相关问题，请联系：[inkroot2025@gmail.com](mailto:inkroot2025@gmail.com)

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

```
MIT License

Copyright (c) 2025 InkRoot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📧 联系方式

- **开发者邮箱**: [inkroot2025@gmail.com](mailto:inkroot2025@gmail.com)
- **官方网站**: [https://inkroot.cn](https://inkroot.cn)
- **GitHub 仓库**: [https://github.com/yyyyymmmmm/InkRoot](https://github.com/yyyyymmmmm/InkRoot)
- **问题反馈**: [GitHub Issues](https://github.com/yyyyymmmmm/InkRoot/issues)
- **功能建议**: [GitHub Discussions](https://github.com/yyyyymmmmm/InkRoot/discussions)

---

## 🔗 相关链接

- **Memos 项目**: [https://github.com/usememos/memos](https://github.com/usememos/memos)
- **DeepSeek AI**: [https://www.deepseek.com](https://www.deepseek.com)
- **Flutter 官网**: [https://flutter.dev](https://flutter.dev)
- **Material Design 3**: [https://m3.material.io](https://m3.material.io)
- **Dart 语言**: [https://dart.dev](https://dart.dev)
- **Google Fonts**: [https://fonts.google.com](https://fonts.google.com)

---

## 🙏 致谢

感谢以下开源项目和贡献者：

- **[Flutter](https://flutter.dev)** - Google 的跨平台 UI 框架
- **[Memos](https://github.com/usememos/memos)** - 优秀的开源笔记服务
- **[DeepSeek](https://www.deepseek.com)** - 强大的 AI 语言模型
- **[Material Design](https://material.io)** - Google 的设计语言系统
- **[Google Fonts](https://fonts.google.com)** - 免费商用字体库
- 所有为本项目做出贡献的开发者
- 所有提供反馈和建议的用户

---

## 🌟 支持项目

如果这个项目对你有帮助，请给我们一个 ⭐️ Star！

你也可以通过以下方式支持我们：

- 🌟 给项目点个 Star
- 🐛 提交 Bug 报告
- 💡 提出功能建议
- 📝 改进文档
- 💻 贡献代码
- 🌐 帮助翻译
- 📢 分享给更多人

---

## 📈 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yyyyymmmmm/InkRoot&type=Date)](https://star-history.com/#yyyyymmmmm/InkRoot&Date)

---

<div align="center">

### Made with ❤️ by InkRoot

**如果觉得不错，请给我们一个 ⭐️**

[⬆ 回到顶部](#inkroot---墨鸣笔记)

</div>
