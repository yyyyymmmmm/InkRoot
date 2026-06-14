# InkRoot Windows 构建指南

## 📋 前置要求

### 1. 安装 Flutter
- 下载 Flutter SDK: https://flutter.dev/docs/get-started/install/windows
- 配置环境变量
- 运行 `flutter doctor` 检查环境

### 2. 安装 Visual Studio
- 下载 Visual Studio 2022 Community: https://visualstudio.microsoft.com/
- 安装时选择 "使用C++的桌面开发" 工作负载
- 包含以下组件：
  - MSVC v143 - VS 2022 C++ x64/x86 生成工具
  - Windows 10/11 SDK
  - C++ CMake tools for Windows

### 3. 启用 Windows 桌面支持
```bash
flutter config --enable-windows-desktop
```

## 🔨 构建步骤

### 方法1: 使用构建脚本（推荐）

1. 打开命令提示符（CMD）或 PowerShell
2. 切换到项目目录
3. 运行统一维护 CLI：
```bash
dart tool/inkroot.dart build windows-debug
```

也可以运行旧脚本：
```bash
scripts\windows\build_windows.bat
```

### 方法2: 手动构建

```bash
# 1. 清理旧构建
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建 Release 版本
flutter build windows --release
```

构建完成后，可执行文件位于：
```
build\windows\x64\runner\Release\inkroot.exe
```

## 📦 打包安装程序

### 选项1: 使用 Inno Setup（推荐）

1. **下载 Inno Setup**
   - 官网: https://jrsoftware.org/isinfo.php
   - 下载并安装 Inno Setup 6

2. **创建安装脚本** (`installer.iss`)
```iss
[Setup]
AppName=InkRoot
AppVersion=1.1.0
DefaultDirName={autopf}\InkRoot
DefaultGroupName=InkRoot
OutputDir=installer
OutputBaseFilename=InkRoot-1.1.0-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\InkRoot"; Filename: "{app}\inkroot.exe"
Name: "{autodesktop}\InkRoot"; Filename: "{app}\inkroot.exe"

[Run]
Filename: "{app}\inkroot.exe"; Description: "启动 InkRoot"; Flags: postinstall nowait skipifsilent
```

3. **编译安装程序**
   - 右键点击 `installer.iss`
   - 选择 "Compile"
   - 生成的安装程序在 `installer` 文件夹

### 选项2: 使用 MSIX（Microsoft Store）

```bash
# 1. 添加 msix 依赖到 pubspec.yaml
dependencies:
  msix: ^3.16.7

# 2. 配置 msix
msix_config:
  display_name: InkRoot
  publisher_display_name: Your Name
  identity_name: com.didichou.inkroot
  msix_version: 1.1.0.0
  logo_path: assets/images/logo.png

# 3. 创建 MSIX 包
flutter pub run msix:create
```

## 🧪 测试

### 本地测试
1. 运行 Debug 版本：
```bash
flutter run -d windows
```

2. 测试 Release 版本：
```bash
build\windows\x64\runner\Release\inkroot.exe
```

### 安装程序测试
1. 运行生成的安装程序
2. 完成安装向导
3. 从开始菜单或桌面快捷方式启动应用
4. 测试所有功能

## 📝 注意事项

### 1. 依赖项
确保所有必需的 DLL 文件都包含在 Release 文件夹中：
- `flutter_windows.dll`
- `msvcp140.dll`
- `vcruntime140.dll`
- `vcruntime140_1.dll`

### 2. 资源文件
确保以下资源正确打包：
- 应用图标
- 字体文件
- 图片资源

### 3. 权限
某些功能可能需要管理员权限：
- 文件系统访问
- 网络访问
- 自动启动

### 4. 代码签名（可选）
为了避免 Windows Defender 警告，建议对应用进行代码签名：
```bash
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com inkroot.exe
```

## 🐛 常见问题

### 问题1: Visual Studio 未找到
**解决方案**: 
- 确保安装了 Visual Studio 2022
- 运行 `flutter doctor -v` 检查配置
- 重新安装 "使用C++的桌面开发" 工作负载

### 问题2: CMake 错误
**解决方案**:
- 确保安装了 CMake tools
- 更新 Visual Studio 到最新版本

### 问题3: 缺少 DLL 文件
**解决方案**:
- 安装 Visual C++ Redistributable
- 下载: https://aka.ms/vs/17/release/vc_redist.x64.exe

### 问题4: 应用无法启动
**解决方案**:
- 检查是否缺少依赖的 DLL
- 使用 Dependency Walker 分析依赖
- 确保所有资源文件都已打包

## 📚 参考资料

- [Flutter Windows 桌面支持](https://docs.flutter.dev/desktop#windows)
- [Inno Setup 文档](https://jrsoftware.org/ishelp/)
- [MSIX 打包指南](https://pub.dev/packages/msix)
- [Windows 应用签名](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptography-tools)

## 🎉 发布清单

- [ ] 构建 Release 版本
- [ ] 测试所有功能
- [ ] 创建安装程序
- [ ] 测试安装程序
- [ ] 代码签名（可选）
- [ ] 准备发布说明
- [ ] 上传到发布平台
- [ ] 更新文档
