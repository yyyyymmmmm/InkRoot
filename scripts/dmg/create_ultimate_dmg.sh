#!/bin/bash

# 终极完美DMG创建脚本 - 修复Applications图标
set -e

APP_NAME="InkRoot"
APP_PATH="build/macos/Build/Products/Release/inkroot.app"
DMG_NAME="InkRoot-v1.0.9-macOS-Installer.dmg"
VOLUME_NAME="Install InkRoot"
BACKGROUND_DIR="dmg_background"
BACKGROUND_FILE="background.png"

echo "🚀 创建终极完美DMG安装包..."

# 清理
rm -rf dmg_temp temp.dmg "$DMG_NAME" "$BACKGROUND_DIR"

# 创建背景图
mkdir -p "$BACKGROUND_DIR"

echo "🎨 创建绿色主题背景图..."
cat > "$BACKGROUND_DIR/create_background.py" <<'PYTHON'
from PIL import Image, ImageDraw, ImageFont
import sys

# 创建背景图 - 绿色主题
width, height = 660, 450
img = Image.new('RGB', (width, height))

# 创建绿色渐变背景
draw = ImageDraw.Draw(img)
for y in range(height):
    r = int(240 + (255 - 240) * y / height)
    g = int(250 + (255 - 250) * y / height)
    b = int(245 + (255 - 245) * y / height)
    draw.line([(0, y), (width, y)], fill=(r, g, b))

# 左上角装饰圆圈
draw.ellipse([20, 20, 120, 120], fill='#5FB878', outline='#4FA568', width=3)
draw.ellipse([40, 40, 100, 100], fill='#E8F5E9')

# 绘制绿色箭头
arrow_y = 200
arrow_start_x = 280
arrow_end_x = 380
draw.line([(arrow_start_x, arrow_y), (arrow_end_x, arrow_y)], fill='#5FB878', width=5)
arrow_head = [(arrow_end_x, arrow_y), (arrow_end_x - 18, arrow_y - 12), (arrow_end_x - 18, arrow_y + 12)]
draw.polygon(arrow_head, fill='#5FB878')

# 添加文字（使用系统字体）
try:
    font_large = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 28)
    font_medium = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 18)
    font_small = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 14)
except:
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 28)
        font_medium = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 18)
        font_small = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 14)
    except:
        font_large = font_medium = font_small = ImageFont.load_default()

draw.text((330, 60), "欢迎安装 InkRoot", anchor="mm", fill='#2E7D32', font=font_large)
draw.text((330, 340), "拖动应用图标到右侧文件夹", anchor="mm", fill='#5FB878', font=font_medium)
draw.text((330, 380), "智能笔记管理 · 让思考更有条理", anchor="mm", fill='#81C784', font=font_small)

img.save(sys.argv[1], 'PNG')
print("✅ 背景图创建成功")
PYTHON

# 创建背景图
if command -v python3 &> /dev/null; then
    python3 "$BACKGROUND_DIR/create_background.py" "$BACKGROUND_DIR/$BACKGROUND_FILE" 2>/dev/null || {
        echo "⚠️  使用简单背景"
        convert -size 660x450 'gradient:#E8F5E9-#FFFFFF' "$BACKGROUND_DIR/$BACKGROUND_FILE" 2>/dev/null || true
    }
fi

# 创建临时文件夹
mkdir -p dmg_temp/.background

# 复制背景图
if [ -f "$BACKGROUND_DIR/$BACKGROUND_FILE" ]; then
    cp "$BACKGROUND_DIR/$BACKGROUND_FILE" dmg_temp/.background/
fi

# 复制应用
cp -R "$APP_PATH" dmg_temp/

# 创建临时DMG（不包含Applications链接）
echo "💿 创建DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder dmg_temp -ov -format UDRW temp.dmg

# 挂载
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen temp.dmg | grep -E '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_DIR="/Volumes/$VOLUME_NAME"
sleep 2

# 在挂载的DMG中创建Applications符号链接
echo "🔗 创建Applications链接..."
ln -s /Applications "$MOUNT_DIR/Applications"

# 设置外观
echo "🎨 设置DMG外观..."
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 760, 550}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set text size of viewOptions to 14
        try
            set background picture of viewOptions to file ".background:$BACKGROUND_FILE"
        end try
        delay 1
        set position of item "inkroot.app" of container window to {180, 200}
        set position of item "Applications" of container window to {480, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# 卸载
echo "📤 完成设置..."
sync
sync
hdiutil detach "$DEVICE"

# 压缩
echo "🗜️  压缩..."
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"

# 清理
rm -f temp.dmg
rm -rf dmg_temp "$BACKGROUND_DIR"

echo ""
echo "✅ 终极完美DMG创建完成！"
echo "📦 文件: $DMG_NAME"
echo "💾 大小: $(du -h "$DMG_NAME" | cut -f1)"
echo ""
echo "🎉 包含："
echo "   ✓ 绿色主题背景"
echo "   ✓ 绿色箭头指示"
echo "   ✓ 应用图标"
echo "   ✓ Applications文件夹图标（正确显示）"
echo "   ✓ 中文提示文字"
