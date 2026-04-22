#!/bin/bash

# Memos 多版本测试环境管理脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查 Docker 和 Docker Compose
check_requirements() {
    print_info "检查环境依赖..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    print_success "环境检查通过"
}

# 启动所有 Memos 实例
start_all() {
    print_info "启动所有 Memos 实例..."
    docker-compose -f "$COMPOSE_FILE" up -d

    print_info "等待服务启动..."
    sleep 10

    check_status
}

# 停止所有实例
stop_all() {
    print_info "停止所有 Memos 实例..."
    docker-compose -f "$COMPOSE_FILE" down
    print_success "所有实例已停止"
}

# 重启所有实例
restart_all() {
    print_info "重启所有 Memos 实例..."
    docker-compose -f "$COMPOSE_FILE" restart
    sleep 5
    check_status
}

# 查看日志
logs() {
    local service=$1
    if [ -z "$service" ]; then
        docker-compose -f "$COMPOSE_FILE" logs -f --tail=100
    else
        docker-compose -f "$COMPOSE_FILE" logs -f --tail=100 "$service"
    fi
}

# 检查服务状态
check_status() {
    print_info "检查服务状态..."
    echo ""

    local versions=("021:5230" "024:5231" "026:5232" "027:5233")

    for ver_port in "${versions[@]}"; do
        IFS=':' read -r version port <<< "$ver_port"
        local url="http://localhost:$port/api/v1/ping"

        echo -n "  v0.$version.0 (端口 $port): "

        if curl -s -f -m 2 "$url" > /dev/null 2>&1; then
            print_success "运行中"
        else
            print_error "未运行"
        fi
    done

    echo ""
}

# 清理所有数据
clean_all() {
    print_warning "这将删除所有 Memos 数据，是否继续? (yes/no)"
    read -r confirm

    if [ "$confirm" != "yes" ]; then
        print_info "取消操作"
        return
    fi

    print_info "停止并删除所有容器和数据..."
    docker-compose -f "$COMPOSE_FILE" down -v
    print_success "清理完成"
}

# 创建测试用户
create_test_users() {
    print_info "创建测试用户..."

    local versions=("021:5230" "024:5231" "026:5232" "027:5233")

    for ver_port in "${versions[@]}"; do
        IFS=':' read -r version port <<< "$ver_port"
        local url="http://localhost:$port/api/v1/auth/signup"

        echo -n "  v0.$version.0: "

        response=$(curl -s -X POST "$url" \
            -H "Content-Type: application/json" \
            -d '{
                "username": "testuser",
                "password": "testpass123",
                "nickname": "Test User"
            }' || echo "ERROR")

        if echo "$response" | grep -q "token\|accessToken"; then
            print_success "用户创建成功"
        elif echo "$response" | grep -q "already exists"; then
            print_warning "用户已存在"
        else
            print_error "创建失败"
        fi
    done

    echo ""
    print_info "测试用户凭据："
    echo "  用户名: testuser"
    echo "  密码: testpass123"
}

# 显示帮助信息
show_help() {
    cat << EOF
Memos 多版本测试环境管理工具

用法: $0 <command>

命令:
  start       启动所有 Memos 实例
  stop        停止所有实例
  restart     重启所有实例
  status      检查服务状态
  logs [服务] 查看日志（可选指定服务：memos-v021/v024/v026/v027）
  create-user 创建测试用户（用户名: testuser, 密码: testpass123）
  clean       清理所有数据（谨慎使用）
  help        显示帮助信息

示例:
  $0 start               # 启动所有实例
  $0 status              # 查看状态
  $0 logs memos-v027     # 查看 v0.27.0 日志
  $0 create-user         # 创建测试用户

服务端口映射:
  v0.21.0 -> http://localhost:5230
  v0.24.0 -> http://localhost:5231
  v0.26.0 -> http://localhost:5232
  v0.27.0 -> http://localhost:5233

EOF
}

# 主函数
main() {
    check_requirements

    case "${1:-help}" in
        start)
            start_all
            echo ""
            print_info "服务已启动，现在可以创建测试用户："
            echo "  $0 create-user"
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        status)
            check_status
            ;;
        logs)
            logs "$2"
            ;;
        create-user)
            create_test_users
            ;;
        clean)
            clean_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
