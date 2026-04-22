#!/bin/bash

# 生成macOS应用图标
set -e

LOGO_PATH="assets/images/logo.png"
ICON_SET="macos/Runner/Assets.xcassets/AppIcon.appiconset"

echo "🎨 开始生成macOS应用图标..."

if [ ! -f "$LOGO_PATH" ]; then
    echo "❌ 找不到logo文件: $LOGO_PATH"
    exit 1
fi

# 创建图标集目录
mkdir -p "$ICON_SET"

# 生成各种尺寸的图标
echo "📐 生成不同尺寸的图标..."

sips -z 16 16 "$LOGO_PATH" --out "$ICON_SET/app_icon_16.png"
sips -z 32 32 "$LOGO_PATH" --out "$ICON_SET/app_icon_32.png"
sips -z 64 64 "$LOGO_PATH" --out "$ICON_SET/app_icon_64.png"
sips -z 128 128 "$LOGO_PATH" --out "$ICON_SET/app_icon_128.png"
sips -z 256 256 "$LOGO_PATH" --out "$ICON_SET/app_icon_256.png"
sips -z 512 512 "$LOGO_PATH" --out "$ICON_SET/app_icon_512.png"
sips -z 1024 1024 "$LOGO_PATH" --out "$ICON_SET/app_icon_1024.png"

# 创建Contents.json
cat > "$ICON_SET/Contents.json" <<'JSON'
{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "app_icon_64.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "app_icon_1024.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON

echo "✅ 图标生成完成！"
echo "📁 位置: $ICON_SET"
echo ""
echo "⚠️  需要重新构建应用才能看到新图标："
echo "   flutter clean"
echo "   flutter build macos --debug"
