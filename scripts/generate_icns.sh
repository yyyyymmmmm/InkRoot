#!/bin/bash
# 生成 macOS .icns 文件

set -e

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DIR="$PROJECT_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"

echo "📦 生成 macOS .icns 文件..."
echo "📁 图标目录: $ICON_DIR"
echo

# 创建临时 iconset 目录
ICONSET_DIR="$ICON_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# 复制并重命名图标文件到 iconset 目录
cp "$ICON_DIR/app_icon_16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$ICON_DIR/app_icon_32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ICON_DIR/app_icon_32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$ICON_DIR/app_icon_64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ICON_DIR/app_icon_128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$ICON_DIR/app_icon_256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ICON_DIR/app_icon_256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$ICON_DIR/app_icon_512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ICON_DIR/app_icon_512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$ICON_DIR/app_icon_1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

echo "✅ 图标文件已复制到 iconset 目录"

# 使用 iconutil 生成 .icns 文件
iconutil -c icns "$ICONSET_DIR" -o "$ICON_DIR/AppIcon.icns"

echo "✅ 已生成 AppIcon.icns"

# 清理临时目录
rm -rf "$ICONSET_DIR"

echo
echo "🎉 macOS .icns 文件生成完成！"
echo "💡 提示：需要重新编译应用才能看到新图标"
echo "   运行: flutter clean && flutter run -d macos"
