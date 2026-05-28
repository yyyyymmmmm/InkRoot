# InkRoot macOS 打包脚本

这个目录包含了用于构建和打包 InkRoot macOS 应用的所有脚本。

## 📁 文件说明

- **`build_release.sh`** - 🚀 **主发布脚本**（推荐使用）
  - 自动化完整的构建和打包流程
  - 支持版本号管理
  - 生成带版本号的DMG文件

- **`generate_icons.sh`** - 🎨 图标生成脚本
  - 从 `assets/images/logo.png` 生成所有尺寸的macOS图标
  - 生成 `.icns` 格式图标文件

- **`create_ultimate_dmg.sh`** - 📦 DMG创建脚本
  - 创建专业的DMG安装包
  - 包含绿色主题背景、箭头、中文提示

## 🚀 快速开始

### 方法1: 使用自动化脚本（推荐）

```bash
# 在项目根目录运行
./scripts/dmg/build_release.sh
```

这个脚本会：
1. 询问是否更新版本号
2. 生成应用图标
3. 清理旧构建
4. 构建macOS应用
5. 创建DMG安装包
6. 自动命名为 `InkRoot-版本号-Installer.dmg`

### 方法2: 手动步骤

```bash
# 1. 生成图标（仅在logo.png更新时需要）
./scripts/dmg/generate_icons.sh

# 2. 清理构建
flutter clean

# 3. 构建应用
flutter build macos --debug

# 4. 创建DMG
./scripts/dmg/create_ultimate_dmg.sh
```

## 📝 版本发布流程

每次发布新版本时：

1. **更新版本号**
   ```bash
   # 编辑 pubspec.yaml
   version: 1.0.9+9  # 修改这里
   ```

2. **运行发布脚本**
   ```bash
   ./scripts/dmg/build_release.sh
   ```

3. **测试安装包**
   - 双击打开DMG
   - 拖拽安装到应用程序文件夹
   - 测试应用功能

4. **发布**
   - 上传DMG到GitHub Releases
   - 更新CHANGELOG.md
   - 通知用户

## ⚙️ 配置说明

### 图标要求
- 源文件：`assets/images/logo.png`
- 推荐尺寸：1024x1024px
- 格式：PNG，透明背景

### DMG外观
- 背景：绿色渐变主题
- 图标大小：128px
- 窗口尺寸：660x450px
- 布局：左侧应用图标，右侧Applications文件夹

## 🔧 故障排除

### 问题1: 图标未更新
```bash
# 清除图标缓存
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Finder
```

### 问题2: 构建失败（代码签名）
```bash
# 使用debug模式（不需要签名）
flutter build macos --debug
```

### 问题3: DMG中文乱码
- 确保系统已安装中文字体
- 脚本会自动尝试使用 PingFang 或 STHeiti 字体

## 📦 输出文件

- **Debug版本**: `InkRoot-版本号-Installer.dmg` (~47MB)
- **Release版本**: `InkRoot-版本号-Installer.dmg` (~30MB，需要签名）

## 🎯 最佳实践

1. **每次发布前**都运行完整的构建流程
2. **测试DMG**在干净的macOS系统上安装
3. **保留旧版本**的DMG文件用于回滚
4. **更新CHANGELOG**记录每个版本的变更

## 📞 需要帮助？

如果遇到问题，请检查：
1. Flutter版本是否最新
2. macOS版本是否支持
3. 是否有足够的磁盘空间（至少1GB）
