#!/bin/zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

usage() {
    cat <<'EOF'
PWN-Docker — CTF PWN 环境管理脚本

用法: ./PWN-Docker.sh <command>

命令:
  start     启动容器（后台运行）
  stop      停止容器
  restart   重启容器
  exec      进入容器的 zsh
  build     构建/重新构建镜像
  pull      从 GHCR 拉取最新镜像
  status    查看容器运行状态
  logs      查看容器日志
  remove    删除容器（保留镜像）
  help      显示此帮助

示例:
  ./PWN-Docker.sh start
  ./PWN-Docker.sh exec
  ./PWN-Docker.sh logs
EOF
}

compose() {
    docker compose -f "$COMPOSE_FILE" "$@"
}

case "${1:-help}" in
    start)
        echo "==> 启动容器..."
        compose up -d
        echo "==> 容器已启动，使用 './PWN-Docker.sh exec' 进入。"
        ;;
    stop)
        echo "==> 停止容器..."
        compose stop
        ;;
    restart)
        echo "==> 重启容器..."
        compose restart
        ;;
    exec)
        echo "==> 进入容器..."
        compose exec pwn zsh
        ;;
    build)
        echo "==> 构建镜像..."
        compose build --no-cache
        ;;
    pull)
        echo "==> 拉取最新镜像..."
        compose pull
        ;;
    status)
        compose ps
        ;;
    logs)
        compose logs -f --tail=50
        ;;
    remove)
        echo "==> 删除容器..."
        compose down
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "错误: 未知命令 '$1'"
        echo
        usage
        exit 1
        ;;
esac
