#!/bin/bash

# InkRoot iOS unsigned archive helper.
# This artifact is for CI smoke checks and internal packaging only.
# App Store/TestFlight submission must use a signed Xcode archive.

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
echo -e "${BLUE}  InkRoot iOS unsigned build${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}App:${NC} $APP_NAME"
echo -e "${GREEN}Version:${NC} $VERSION ($BUILD_NUMBER)"
echo -e "${GREEN}Output:${NC} $OUTPUT_DIR"
echo ""

# 步骤1: 清理旧的构建
echo -e "${YELLOW}[1/6] Cleaning previous build...${NC}"
cd "$PROJECT_DIR"
flutter clean
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 步骤2: 获取依赖
echo -e "${YELLOW}[2/6] Resolving Flutter dependencies...${NC}"
flutter pub get

# 步骤3: 安装 CocoaPods 依赖
echo -e "${YELLOW}[3/6] Installing CocoaPods dependencies...${NC}"
cd "$PROJECT_DIR/ios"
pod install

# 步骤4: 构建 iOS Release 版本（不签名）
echo -e "${YELLOW}[4/6] Building iOS release without codesigning...${NC}"
cd "$PROJECT_DIR"

BUILD_DEFINES=()
BUILD_DEFINES+=("--dart-define=ENVIRONMENT=${ENVIRONMENT:-production}")
if [ -n "${CLOUD_VERIFY_APP_ID:-}" ]; then
    BUILD_DEFINES+=("--dart-define=CLOUD_VERIFY_APP_ID=${CLOUD_VERIFY_APP_ID}")
fi
if [ -n "${CLOUD_VERIFY_APP_KEY:-}" ]; then
    BUILD_DEFINES+=("--dart-define=CLOUD_VERIFY_APP_KEY=${CLOUD_VERIFY_APP_KEY}")
fi

flutter build ios --release --no-codesign "${BUILD_DEFINES[@]}"

# 步骤5: 创建 Payload 目录并打包
echo -e "${YELLOW}[5/6] Packaging IPA...${NC}"

# 找到构建的 .app 文件
APP_PATH="$PROJECT_DIR/build/ios/iphoneos/Runner.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Runner.app was not found${NC}"
    echo -e "${RED}Path: $APP_PATH${NC}"
    exit 1
fi

if [ ! -f "$APP_PATH/PrivacyInfo.xcprivacy" ]; then
    echo -e "${RED}Error: PrivacyInfo.xcprivacy was not copied into Runner.app${NC}"
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
echo -e "${YELLOW}[6/6] Verifying IPA...${NC}"

if [ -f "$IPA_PATH" ]; then
    FILE_SIZE=$(du -h "$IPA_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  IPA build succeeded${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}File:${NC} $IPA_NAME"
    echo -e "${GREEN}Size:${NC} $FILE_SIZE"
    echo -e "${GREEN}Path:${NC} $IPA_PATH"
    echo ""
    echo -e "${YELLOW}Note:${NC} This IPA is unsigned and is not an App Store/TestFlight submission artifact."
    echo ""
    
    if command -v open >/dev/null 2>&1 && [ -z "${CI:-}" ]; then
        open "$OUTPUT_DIR"
    fi
else
    echo -e "${RED}Error: IPA was not created${NC}"
    exit 1
fi
