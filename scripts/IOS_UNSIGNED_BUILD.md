# iOS 未签名 IPA 构建指南

## 📱 概述

本指南说明如何构建未签名的 IPA 文件用于真机测试。未签名的 IPA 可以通过第三方工具（如爱思助手、iMazing）安装到 iPhone 上进行测试。

## 🎯 适用场景

- ✅ 真机测试（无需 Apple 开发者账号）
- ✅ 内部测试分发
- ✅ 快速验证功能
- ❌ 不适用于 App Store 发布
- ❌ 不适用于 TestFlight 分发

## 🔧 前置要求

### 必需工具

1. **macOS 系统**
   - macOS 10.14 (Mojave) 或更高版本

2. **Flutter SDK**
   - 版本: 3.24.5 或更高
   - 验证: `flutter --version`

3. **Xcode**
   - 版本: 14.0 或更高
   - 验证: `xcodebuild -version`

4. **CocoaPods**
   - 版本: 1.11.0 或更高
   - 验证: `pod --version`
   - 安装: `sudo gem install cocoapods`

### 安装工具（选择其一）

**方式一: 爱思助手（推荐）**
- 下载地址: https://www.i4.cn/
- 支持: Windows + macOS
- 特点: 免费、简单、无需越狱

**方式二: iMazing**
- 下载地址: https://imazing.com/
- 支持: Windows + macOS
- 特点: 功能强大，但需付费

**方式三: Sideloadly**
- 下载地址: https://sideloadly.io/
- 支持: Windows + macOS
- 特点: 免费、支持自签名

## 🚀 快速开始

### 方法一: 使用自动化脚本（推荐）

```bash
# 1. 进入项目目录
cd /path/to/IntRoot

# 2. 运行构建脚本
./scripts/build_unsigned_ipa.sh
```

脚本会自动完成以下步骤：
1. ✅ 清理旧的构建文件
2. ✅ 获取 Flutter 依赖
3. ✅ 安装 CocoaPods 依赖
4. ✅ 构建 iOS Release 版本（不签名）
5. ✅ 打包成 IPA 文件
6. ✅ 在 Finder 中显示输出文件

**输出位置:**
```
build/ios/unsigned/InkRoot-1.0.9-unsigned.ipa
```

### 方法二: 手动构建

如果自动化脚本失败，可以手动执行以下步骤：

#### 步骤 1: 清理项目

```bash
flutter clean
rm -rf build/ios/unsigned
mkdir -p build/ios/unsigned
```

#### 步骤 2: 获取依赖

```bash
# Flutter 依赖
flutter pub get

# iOS 依赖
cd ios
pod install
cd ..
```

#### 步骤 3: 构建 iOS 应用（不签名）

```bash
flutter build ios --release --no-codesign
```

#### 步骤 4: 打包 IPA

```bash
# 创建 Payload 目录
mkdir -p build/ios/unsigned/Payload

# 复制 .app 文件
cp -r build/ios/iphoneos/Runner.app build/ios/unsigned/Payload/

# 打包成 IPA
cd build/ios/unsigned
zip -r InkRoot-1.0.9-unsigned.ipa Payload

# 清理临时文件
rm -rf Payload
```

## 📲 安装到 iPhone

### 使用爱思助手安装

1. **连接设备**
   - 使用 USB 线连接 iPhone 到 Mac
   - 在 iPhone 上信任此电脑

2. **打开爱思助手**
   - 启动爱思助手应用
   - 等待识别设备

3. **安装 IPA**
   - 点击"应用游戏" → "安装应用"
   - 选择构建的 IPA 文件
   - 等待安装完成

4. **信任证书**
   - 在 iPhone 上打开"设置" → "通用" → "VPN与设备管理"
   - 找到开发者证书
   - 点击"信任"

### 使用 iMazing 安装

1. **连接设备**
   - 连接 iPhone 到 Mac
   - 启动 iMazing

2. **安装应用**
   - 选择设备
   - 点击"管理应用"
   - 拖拽 IPA 文件到窗口
   - 等待安装完成

### 使用 Sideloadly 安装

1. **打开 Sideloadly**
   - 连接 iPhone
   - 选择 IPA 文件

2. **输入 Apple ID**
   - 输入你的 Apple ID（免费账号即可）
   - Sideloadly 会自动签名并安装

3. **信任证书**
   - 在设置中信任开发者

## 🔍 故障排查

### 问题 1: flutter build ios 失败

**错误信息:**
```
Error: No valid code signing certificates were found
```

**解决方案:**
确保使用了 `--no-codesign` 参数：
```bash
flutter build ios --release --no-codesign
```

### 问题 2: Pod install 失败

**错误信息:**
```
[!] CocoaPods could not find compatible versions
```

**解决方案:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
```

### 问题 3: 找不到 Runner.app

**错误信息:**
```
错误: 找不到 Runner.app 文件
```

**解决方案:**
检查构建是否成功：
```bash
ls -la build/ios/iphoneos/
```

如果没有 Runner.app，重新构建：
```bash
flutter clean
flutter build ios --release --no-codesign
```

### 问题 4: iPhone 安装后无法打开

**错误信息:**
```
未受信任的企业级开发者
```

**解决方案:**
1. 打开 iPhone "设置"
2. 进入"通用" → "VPN与设备管理"
3. 找到开发者证书
4. 点击"信任"

### 问题 5: 爱思助手无法识别设备

**解决方案:**
1. 重新插拔 USB 线
2. 在 iPhone 上点击"信任此电脑"
3. 重启爱思助手
4. 更新 iTunes（如果使用 Windows）

## 📝 注意事项

### ⚠️ 重要提示

1. **未签名 IPA 的限制**
   - ❌ 无法通过 Xcode 直接安装
   - ❌ 无法上传到 TestFlight
   - ❌ 无法发布到 App Store
   - ✅ 可以通过第三方工具安装
   - ✅ 适合快速测试

2. **证书有效期**
   - 免费 Apple ID 签名: 7天
   - 付费开发者账号签名: 1年
   - 企业证书签名: 1年

3. **设备限制**
   - 免费账号: 最多3台设备
   - 付费账号: 最多100台设备

### 🔒 安全建议

1. **不要分发未签名的 IPA**
   - 仅用于内部测试
   - 不要上传到公共平台

2. **保护 Apple ID**
   - 使用 Sideloadly 时注意账号安全
   - 建议使用专门的测试账号

3. **版本管理**
   - 为每个测试版本添加版本号
   - 记录测试设备和反馈

## 📊 构建信息

### 输出文件

```
build/ios/unsigned/
├── InkRoot-1.0.9-unsigned.ipa    # 未签名的 IPA 文件
└── build.log                      # 构建日志（如果有错误）
```

### 文件大小

- 预期大小: 约 50-80 MB
- 如果超过 100 MB，检查是否包含了不必要的资源

### 版本信息

- 应用名称: InkRoot
- 版本号: 从 pubspec.yaml 自动读取
- Bundle ID: com.inkroot.app

## 🆘 获取帮助

如果遇到问题：

1. **查看构建日志**
   ```bash
   flutter build ios --release --no-codesign --verbose
   ```

2. **检查环境**
   ```bash
   flutter doctor -v
   ```

3. **提交 Issue**
   - GitHub: https://github.com/yyyyymmmmm/IntRoot/issues
   - 附上错误日志和环境信息

## 📚 相关文档

- [Flutter iOS 构建文档](https://docs.flutter.dev/deployment/ios)
- [爱思助手使用教程](https://www.i4.cn/news_detail_38.html)
- [iOS 代码签名指南](https://developer.apple.com/support/code-signing/)

## 🔄 更新日志

- **v1.0.9** (2025-11-22)
  - 创建未签名 IPA 构建脚本
  - 添加详细的构建和安装说明
  - 支持自动化构建流程
