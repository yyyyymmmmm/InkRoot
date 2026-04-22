#!/bin/bash

# ============================================
# InkRoot iOS 未签名 IPA 构建脚本
# 用于真机测试（需要通过第三方工具如爱思助手安装）
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="InkRoot"
VERSION=$(grep "version:" "$PROJECT_DIR/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUMBER=$(grep "version:" "$PROJECT_DIR/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f2)
OUTPUT_DIR="$PROJECT_DIR/build/ios/unsigned"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  InkRoot iOS 未签名 IPA 构建${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}应用名称:${NC} $APP_NAME"
echo -e "${GREEN}版本号:${NC} $VERSION ($BUILD_NUMBER)"
echo -e "${GREEN}输出目录:${NC} $OUTPUT_DIR"
echo ""

# 步骤1: 清理旧的构建
echo -e "${YELLOW}[1/6] 清理旧的构建文件...${NC}"
cd "$PROJECT_DIR"
flutter clean
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 步骤2: 获取依赖
echo -e "${YELLOW}[2/6] 获取 Flutter 依赖...${NC}"
flutter pub get

# 步骤3: 安装 CocoaPods 依赖
echo -e "${YELLOW}[3/6] 安装 CocoaPods 依赖...${NC}"
cd "$PROJECT_DIR/ios"
pod install

# 步骤4: 构建 iOS Release 版本（不签名）
echo -e "${YELLOW}[4/6] 构建 iOS Release 版本...${NC}"
cd "$PROJECT_DIR"

# 使用 flutter build ios 命令，不进行代码签名
flutter build ios --release --no-codesign

# 步骤5: 创建 Payload 目录并打包
echo -e "${YELLOW}[5/6] 打包 IPA 文件...${NC}"

# 找到构建的 .app 文件
APP_PATH="$PROJECT_DIR/build/ios/iphoneos/Runner.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}错误: 找不到 Runner.app 文件${NC}"
    echo -e "${RED}路径: $APP_PATH${NC}"
    exit 1
fi

# 创建 Payload 目录
PAYLOAD_DIR="$OUTPUT_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"

# 复制 .app 到 Payload 目录
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

# 打包成 IPA
IPA_NAME="${APP_NAME}-${VERSION}-unsigned.ipa"
IPA_PATH="$OUTPUT_DIR/$IPA_NAME"

cd "$OUTPUT_DIR"
zip -r "$IPA_NAME" Payload

# 清理临时文件
rm -rf Payload

# 步骤6: 验证 IPA 文件
echo -e "${YELLOW}[6/6] 验证 IPA 文件...${NC}"

if [ -f "$IPA_PATH" ]; then
    FILE_SIZE=$(du -h "$IPA_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ✅ IPA 构建成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}文件名称:${NC} $IPA_NAME"
    echo -e "${GREEN}文件大小:${NC} $FILE_SIZE"
    echo -e "${GREEN}文件路径:${NC} $IPA_PATH"
    echo ""
    echo -e "${BLUE}📱 安装说明:${NC}"
    echo -e "  1. 使用爱思助手、iMazing 或其他第三方工具"
    echo -e "  2. 连接 iPhone 到电脑"
    echo -e "  3. 导入并安装此 IPA 文件"
    echo ""
    echo -e "${YELLOW}⚠️  注意事项:${NC}"
    echo -e "  - 此 IPA 未签名，无法通过 Xcode 或 TestFlight 安装"
    echo -e "  - 需要使用第三方工具（如爱思助手）进行安装"
    echo -e "  - 安装后可能需要在设置中信任开发者证书"
    echo ""
    
    # 在 Finder 中显示文件
    open "$OUTPUT_DIR"
else
    echo -e "${RED}错误: IPA 文件创建失败${NC}"
    exit 1
fi
