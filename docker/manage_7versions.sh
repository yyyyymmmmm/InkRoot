#!/bin/bash

# Memos 7版本测试环境管理脚本
# 支持版本：v0.21.0, v0.22.5, v0.23.1, v0.24.4, v0.25.3, v0.26.2, v0.27.1

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本配置
declare -A VERSIONS=(
    ["v21"]="5230:v0.21.0:memos-v021"
    ["v22"]="5231:v0.22.5:memos-v022"
    ["v23"]="5232:v0.23.1:memos-v023"
    ["v24"]="5233:v0.24.4:memos-v024"
    ["v25"]="5234:v0.25.3:memos-v025"
    ["v26"]="5235:v0.26.2:memos-v026"
    ["v27"]="5236:v0.27.1:memos-v027"
)

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Memos 7版本测试环境管理工具${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_usage() {
    cat << EOF

用法: $0 <command> [options]

命令:
    start          启动所有版本的Memos服务
    stop           停止所有服务
    restart        重启所有服务
    status         查看所有服务状态
    create-user    为所有版本创建测试用户
    logs <version> 查看指定版本的日志 (v21/v22/v23/v24/v25/v26/v27)
    clean          清理所有数据并重置环境
    test           运行完整兼容性测试

示例:
    $0 start
    $0 status
    $0 logs v27
    $0 create-user
    $0 test

EOF
}

check_health() {
    local port=$1
    local version=$2
    
    for i in {1..30}; do
        if curl -sf "http://localhost:$port/api/v1/ping" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $version 健康检查通过 (端口 $port)"
            return 0
        fi
        sleep 2
    done
    
    echo -e "${RED}✗${NC} $version 健康检查失败 (端口 $port)"
    return 1
}

cmd_start() {
    print_header
    echo ""
    echo -e "${GREEN}正在启动7个版本的Memos服务...${NC}"
    echo ""
    
    docker-compose up -d
    
    echo ""
    echo -e "${YELLOW}等待服务就绪...${NC}"
    echo ""
    
    local all_healthy=true
    for key in "${!VERSIONS[@]}"; do
        IFS=':' read -r port version container <<< "${VERSIONS[$key]}"
        if ! check_health "$port" "$version"; then
            all_healthy=false
        fi
    done
    
    echo ""
    if [ "$all_healthy" = true ]; then
        echo -e "${GREEN}✓ 所有服务已启动并就绪！${NC}"
        echo ""
        echo "访问地址："
        for key in "${!VERSIONS[@]}"; do
            IFS=':' read -r port version container <<< "${VERSIONS[$key]}"
            echo "  • $version: http://localhost:$port"
        done
    else
        echo -e "${YELLOW}⚠ 部分服务未通过健康检查，请运行 'status' 命令查看详情${NC}"
    fi
    echo ""
}

cmd_stop() {
    print_header
    echo ""
    echo -e "${YELLOW}正在停止所有服务...${NC}"
    docker-compose stop
    echo -e "${GREEN}✓ 所有服务已停止${NC}"
    echo ""
}

cmd_restart() {
    cmd_stop
    sleep 2
    cmd_start
}

cmd_status() {
    print_header
    echo ""
    echo -e "${BLUE}服务状态：${NC}"
    echo ""
    
    docker-compose ps
    
    echo ""
    echo -e "${BLUE}端口映射：${NC}"
    for key in "${!VERSIONS[@]}"; do
        IFS=':' read -r port version container <<< "${VERSIONS[$key]}"
        echo "  • $version: localhost:$port → $container"
    done
    echo ""
}

cmd_logs() {
    local version_key=$1
    
    if [ -z "$version_key" ]; then
        echo -e "${RED}错误: 请指定版本 (v21/v22/v23/v24/v25/v26/v27)${NC}"
        echo "示例: $0 logs v27"
        exit 1
    fi
    
    IFS=':' read -r port version container <<< "${VERSIONS[$version_key]}"
    
    if [ -z "$container" ]; then
        echo -e "${RED}错误: 未知版本 '$version_key'${NC}"
        echo "可用版本: v21, v22, v23, v24, v25, v26, v27"
        exit 1
    fi
    
    print_header
    echo ""
    echo -e "${BLUE}查看 $version 日志 (Ctrl+C 退出)${NC}"
    echo ""
    
    docker-compose logs -f "$container"
}

cmd_create_user() {
    print_header
    echo ""
    echo -e "${GREEN}为所有版本创建测试用户...${NC}"
    echo ""
    
    local username="testuser"
    local password="testpass123"
    
    for key in "${!VERSIONS[@]}"; do
        IFS=':' read -r port version container <<< "${VERSIONS[$key]}"
        
        echo -e "创建用户 $username 于 $version (端口 $port)..."
        
        # 尝试创建用户（如果已存在会失败，但不影响）
        curl -sf "http://localhost:$port/api/v1/auth/signup" \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$username\",\"password\":\"$password\"}" \
            > /dev/null 2>&1 && echo -e "${GREEN}  ✓ 用户创建成功${NC}" || echo -e "${YELLOW}  • 用户可能已存在${NC}"
    done
    
    echo ""
    echo -e "${GREEN}✓ 完成！${NC}"
    echo "用户名: $username"
    echo "密码: $password"
    echo ""
}

cmd_clean() {
    print_header
    echo ""
    echo -e "${YELLOW}⚠️  警告: 此操作将删除所有数据并重置环境！${NC}"
    echo -n "确认继续？(yes/no): "
    read -r confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "操作已取消"
        exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}停止并删除所有容器和数据卷...${NC}"
    docker-compose down -v
    
    echo -e "${GREEN}✓ 环境已清理${NC}"
    echo ""
}

cmd_test() {
    print_header
    echo ""
    echo -e "${GREEN}运行7版本完整兼容性测试...${NC}"
    echo ""
    
    # 检查是否所有服务都在运行
    echo "检查服务状态..."
    local all_running=true
    for key in "${!VERSIONS[@]}"; do
        IFS=':' read -r port version container <<< "${VERSIONS[$key]}"
        if ! curl -sf "http://localhost:$port/api/v1/ping" > /dev/null 2>&1; then
            echo -e "${RED}✗${NC} $version 未运行"
            all_running=false
        fi
    done
    
    if [ "$all_running" = false ]; then
        echo ""
        echo -e "${YELLOW}请先启动所有服务: $0 start${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 所有服务运行正常${NC}"
    echo ""
    
    # 运行测试
    if [ -f "test_all_versions.dart" ]; then
        dart test_all_versions.dart
    else
        echo -e "${RED}错误: 未找到 test_all_versions.dart${NC}"
        exit 1
    fi
}

# 主逻辑
case "${1:-}" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs "$2"
        ;;
    create-user)
        cmd_create_user
        ;;
    clean)
        cmd_clean
        ;;
    test)
        cmd_test
        ;;
    *)
        print_header
        print_usage
        exit 1
        ;;
esac
