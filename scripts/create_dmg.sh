#!/bin/bash
# 创建 macOS DMG 安装包

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 开始创建 macOS DMG 安装包...${NC}"
echo

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 读取版本号
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
APP_NAME="InkRoot"
DMG_NAME="${APP_NAME}-${VERSION}-macOS"

echo -e "${BLUE}应用名称:${NC} $APP_NAME"
echo -e "${BLUE}版本号:${NC} $VERSION"
echo -e "${BLUE}DMG名称:${NC} $DMG_NAME.dmg"
echo

# 检查 Release 构建是否存在
APP_PATH="build/macos/Build/Products/Release/inkroot.app"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ 找不到 Release 构建！${NC}"
    echo -e "${YELLOW}💡 请先运行: flutter build macos --release${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 找到 Release 构建${NC}"

# 创建临时目录
TMP_DIR="build/dmg_tmp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo -e "${BLUE}📁 准备 DMG 内容...${NC}"

# 复制应用到临时目录
cp -R "$APP_PATH" "$TMP_DIR/"

# 创建 Applications 快捷方式
ln -s /Applications "$TMP_DIR/Applications"

# 创建 DMG 背景目录（可选）
mkdir -p "$TMP_DIR/.background"

# 输出目录
OUTPUT_DIR="build/dmg"
mkdir -p "$OUTPUT_DIR"
OUTPUT_PATH="$OUTPUT_DIR/$DMG_NAME.dmg"

# 删除旧的 DMG（如果存在）
if [ -f "$OUTPUT_PATH" ]; then
    echo -e "${YELLOW}🗑️  删除旧的 DMG 文件${NC}"
    rm "$OUTPUT_PATH"
fi

echo -e "${BLUE}🔨 创建 DMG 文件...${NC}"

# 创建临时 DMG
TMP_DMG="$OUTPUT_DIR/tmp_$DMG_NAME.dmg"
hdiutil create -srcfolder "$TMP_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size 200m \
    "$TMP_DMG"

echo -e "${GREEN}✅ 临时 DMG 创建成功${NC}"

# 挂载临时 DMG
echo -e "${BLUE}📂 挂载 DMG...${NC}"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_DIR=$(hdiutil info | grep "$DEVICE" | awk '{print $3}')

# 如果挂载目录为空，尝试另一种方法
if [ -z "$MOUNT_DIR" ]; then
    MOUNT_DIR="/Volumes/$APP_NAME"
fi

echo -e "${GREEN}✅ DMG 已挂载到: $MOUNT_DIR${NC}"
echo -e "${GREEN}✅ 设备: $DEVICE${NC}"

# 设置 DMG 窗口属性（使用 AppleScript）
echo -e "${BLUE}🎨 设置 DMG 窗口样式...${NC}"

osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 450}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "inkroot.app" of container window to {150, 150}
        set position of item "Applications" of container window to {450, 150}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

echo -e "${GREEN}✅ DMG 窗口样式设置完成${NC}"

# 卸载临时 DMG
echo -e "${BLUE}📤 卸载 DMG...${NC}"
hdiutil detach "$DEVICE" || hdiutil detach "$MOUNT_DIR" || true

echo -e "${GREEN}✅ DMG 已卸载${NC}"

# 转换为压缩的只读 DMG
echo -e "${BLUE}🗜️  压缩 DMG...${NC}"
hdiutil convert "$TMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$OUTPUT_PATH"

echo -e "${GREEN}✅ DMG 压缩完成${NC}"

# 清理临时文件
echo -e "${BLUE}🧹 清理临时文件...${NC}"
rm -rf "$TMP_DIR"
rm "$TMP_DMG"

echo -e "${GREEN}✅ 临时文件已清理${NC}"
echo

# 显示文件信息
DMG_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 DMG 安装包创建成功！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 文件路径:${NC} $OUTPUT_PATH"
echo -e "${BLUE}📊 文件大小:${NC} $DMG_SIZE"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# 在 Finder 中显示
open -R "$OUTPUT_PATH"
