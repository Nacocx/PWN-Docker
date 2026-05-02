#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[-]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[*]${NC} $1"; }

# ============================================================
# 0. 系统检测
# ============================================================
if [[ "$(uname)" != "Linux" ]]; then
    err "当前仅支持 Linux 系统。macOS 请使用 Docker 版本。"
fi

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
else
    err "未检测到支持的包管理器 (apt/dnf/yum/pacman)。"
fi

info "检测到系统: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
info "包管理器: $PKG_MANAGER"

# ============================================================
# 1. 启用 i386 架构 (仅 Debian/Ubuntu)
# ============================================================
if [ "$PKG_MANAGER" = "apt" ]; then
    log "启用 i386 架构..."
    $SUDO dpkg --add-architecture i386
    $SUDO apt-get update
fi

# ============================================================
# 2. 安装系统基础包 + PWN 工具链
# ============================================================
log "安装系统基础包..."

install_apt() {
    $SUDO apt-get install -y \
        build-essential \
        gcc \
        g++ \
        gcc-multilib \
        g++-multilib \
        make \
        cmake \
        nasm \
        gdb \
        gdbserver \
        ltrace \
        strace \
        file \
        xxd \
        binutils \
        elfutils \
        patchelf \
        netcat-openbsd \
        socat \
        curl \
        wget \
        zsh \
        fzf \
        git \
        vim \
        nano \
        tmux \
        python3 \
        python3-pip \
        python3-dev \
        ruby \
        ruby-dev \
        libc6-dev-i386 \
        libc6-dbg \
        qemu-user \
        binfmt-support \
        sudo
}

install_dnf() {
    $SUDO dnf install -y \
        gcc gcc-c++ make cmake nasm \
        gdb gdb-gdbserver ltrace strace file binutils \
        elfutils-libelf-devel patchelf \
        nmap-ncat socat curl wget \
        zsh fzf git vim nano tmux \
        python3 python3-pip python3-devel \
        ruby ruby-devel \
        glibc-devel.i686 glibc-devel \
        qemu-user-binfmt
}

install_yum() {
    $SUDO yum install -y \
        gcc gcc-c++ make cmake nasm \
        gdb ltrace strace file binutils \
        patchelf \
        socat curl wget \
        zsh git vim nano tmux \
        python3 python3-pip python3-devel \
        ruby ruby-devel \
        qemu-user
}

install_pacman() {
    $SUDO pacman -S --noconfirm \
        base-devel gcc make cmake nasm \
        gdb ltrace strace file binutils patchelf \
        openbsd-netcat socat curl wget \
        zsh fzf git vim nano tmux \
        python python-pip \
        ruby \
        qemu-user-binfmt
}

case "$PKG_MANAGER" in
    apt)    install_apt ;;
    dnf)    install_dnf ;;
    yum)    install_yum ;;
    pacman) install_pacman ;;
esac

# ============================================================
# 3. 安装 Python PWN 工具
# ============================================================
log "安装 Python PWN 工具..."
pip3 install --no-cache-dir --break-system-packages pwntools

# ============================================================
# 4. 安装 pwndbg — GDB 增强插件
# ============================================================
PWN_HOME="${PWN_HOME:-$HOME/.pwn}"

if [ -d "$PWN_HOME/pwndbg" ]; then
    warn "pwndbg 已存在，跳过。"
else
    log "克隆 pwndbg..."
    git clone https://github.com/pwndbg/pwndbg "$PWN_HOME/pwndbg"
    log "安装 pwndbg..."
    cd "$PWN_HOME/pwndbg"
    ./setup.sh
fi

# ============================================================
# 5. 安装 Pwngdb — 堆利用辅助插件
# ============================================================
if [ -d "$PWN_HOME/Pwngdb" ]; then
    warn "Pwngdb 已存在，跳过。"
else
    log "克隆 Pwngdb..."
    git clone https://github.com/scwuaptx/Pwngdb.git "$PWN_HOME/Pwngdb"
fi

# ============================================================
# 6. 配置 GDB 初始化脚本
# ============================================================
log "配置 GDB 初始化脚本..."

if [ -f "$HOME/.gdbinit" ]; then
    warn "~/.gdbinit 已存在，备份为 ~/.gdbinit.bak"
    cp "$HOME/.gdbinit" "$HOME/.gdbinit.bak"
fi

cat > "$HOME/.gdbinit" <<EOF
source $PWN_HOME/pwndbg/gdbinit.py
source $PWN_HOME/Pwngdb/pwngdb.py
source $PWN_HOME/Pwngdb/angelheap/gdbinit.py

define hook-run
python
import angelheap
angelheap.init_angelheap()
end
end
EOF

# ============================================================
# 7. 配置 Zsh + Starship + 插件
# ============================================================
log "配置 Zsh..."

# zsh-autosuggestions
if [ -d "$HOME/.zsh-autosuggestions" ]; then
    warn "zsh-autosuggestions 已存在，跳过。"
else
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ -d "$HOME/.zsh-syntax-highlighting" ]; then
    warn "zsh-syntax-highlighting 已存在，跳过。"
else
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh-syntax-highlighting"
fi

# Starship
if command -v starship &>/dev/null; then
    warn "starship 已安装，跳过。"
else
    log "安装 Starship 提示符..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# zshrc
if [ -f "$HOME/.zshrc" ]; then
    warn "~/.zshrc 已存在，备份为 ~/.zshrc.bak"
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi

FZF_BASE="/usr/share/doc/fzf"
[ -d "/usr/share/fzf" ] && FZF_BASE="/usr/share/fzf"

cat > "$HOME/.zshrc" <<ZSH_EOF
source \$HOME/.zsh-autosuggestions/zsh-autosuggestions.zsh
source \$HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf 集成
[ -f "$FZF_BASE/completion.zsh" ] && source "$FZF_BASE/completion.zsh"
[ -f "$FZF_BASE/key-bindings.zsh" ] && source "$FZF_BASE/key-bindings.zsh"

eval "\$(starship init zsh)"
ZSH_EOF

# 设为默认 shell
if [ "$SHELL" != "$(which zsh)" ]; then
    log "将 zsh 设为默认 shell..."
    $SUDO chsh -s "$(which zsh)" "$USER"
fi

# ============================================================
# 8. 创建工作目录
# ============================================================
if [ ! -d "$HOME/ctf" ]; then
    mkdir -p "$HOME/ctf"
    log "创建 CTF 工作目录: ~/ctf"
fi

echo ""
echo "============================================"
echo -e "${GREEN}  PWN 环境配置完成！${NC}"
echo "============================================"
echo ""
echo "  工作目录: ~/ctf"
echo "  GDB 插件: pwndbg + Pwngdb (angelheap)"
echo "  Shell  : zsh + starship"
echo ""
echo "  请执行 'zsh' 或重新登录以切换 Shell。"
echo "============================================"
