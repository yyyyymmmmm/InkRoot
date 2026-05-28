#!/bin/bash

# InkRoot macOS 发布构建脚本
# 自动化构建和打包流程

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   InkRoot macOS 发布构建工具${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 获取版本号
VERSION=$(grep "version:" pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
echo -e "${GREEN}📦 当前版本: ${VERSION}${NC}"
echo ""

# 询问是否更新版本号
read -p "是否需要更新版本号？(y/N): " update_version
if [[ $update_version =~ ^[Yy]$ ]]; then
    read -p "请输入新版本号 (当前: $VERSION): " new_version
    if [ ! -z "$new_version" ]; then
        # 更新pubspec.yaml中的版本号
        sed -i '' "s/version: .*/version: $new_version/" pubspec.yaml
        VERSION=$new_version
        echo -e "${GREEN}✅ 版本号已更新为: ${VERSION}${NC}"
    fi
fi
echo ""

# 步骤1: 生成图标
echo -e "${YELLOW}🎨 步骤 1/4: 生成应用图标...${NC}"
./scripts/dmg/generate_icons.sh
echo ""

# 步骤2: 清理构建
echo -e "${YELLOW}🧹 步骤 2/4: 清理旧构建...${NC}"
flutter clean
echo ""

# 步骤3: 构建应用
echo -e "${YELLOW}🔨 步骤 3/4: 构建 macOS 应用...${NC}"
read -p "构建类型 (debug/release，默认debug): " build_type
build_type=${build_type:-debug}

if [ "$build_type" = "release" ]; then
    echo -e "${RED}⚠️  Release构建需要代码签名！${NC}"
    read -p "确认继续？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    flutter build macos --release
else
    flutter build macos --debug
fi
echo ""

# 步骤4: 创建DMG
echo -e "${YELLOW}📦 步骤 4/4: 创建 DMG 安装包...${NC}"
./scripts/dmg/create_ultimate_dmg.sh

# 重命名DMG文件包含版本号
if [ -f "InkRoot-Installer.dmg" ]; then
    mv InkRoot-Installer.dmg "InkRoot-${VERSION}-Installer.dmg"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 构建完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}📦 安装包: InkRoot-${VERSION}-Installer.dmg${NC}"
    echo -e "${BLUE}💾 大小: $(du -h "InkRoot-${VERSION}-Installer.dmg" | cut -f1)${NC}"
    echo ""
    echo -e "${YELLOW}📝 下一步:${NC}"
    echo "  1. 测试安装包"
    echo "  2. 上传到发布平台"
    echo "  3. 更新 CHANGELOG.md"
    echo ""
else
    echo -e "${RED}❌ DMG创建失败！${NC}"
    exit 1
fi
