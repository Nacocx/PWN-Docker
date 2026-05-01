FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV TZ=Asia/Shanghai

# ============================================================
# 阿里云 apt 源 + 启用 i386 架构
# ============================================================

# RUN echo "deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list \
#     && echo "deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list \
#     && echo "deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list \
#     && echo "deb http://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse" >> /etc/apt/sources.list \
#     && echo "deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list

RUN dpkg --add-architecture i386

# ============================================================
# 系统基础包 + PWN 工具链
# ============================================================
RUN apt-get update && apt-get install -y \
    # -- 编译工具链 --
    build-essential \
    gcc \
    g++ \
    gcc-multilib \
    g++-multilib \
    make \
    cmake \
    nasm \
    # -- 调试 / 分析 --
    gdb \
    gdbserver \
    ltrace \
    strace \
    file \
    xxd \
    binutils \
    elfutils \
    patchelf \
    # -- 网络工具 --
    netcat-openbsd \
    socat \
    curl \
    wget \
    # -- 编辑 / 终端复用 --
    git \
    vim \
    nano \
    tmux \
    # -- Python3 环境 --
    python3 \
    python3-pip \
    python3-dev \
    # -- Ruby 环境 (one_gadget 依赖) --
    ruby \
    ruby-dev \
    # -- 32 位调试依赖 --
    libc6-dev-i386 \
    libc6-dbg \
    # -- 其他 --
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# pip 阿里云镜像 + Python PWN 工具
# ============================================================
# RUN pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ \
#     && pip3 install --no-cache-dir \
#     pwntools 

RUN pip3 install --no-cache-dir --break-system-packages \
    pwntools

# ============================================================
# pwndbg — GDB 增强插件
# ============================================================
RUN git clone https://github.com/pwndbg/pwndbg /opt/pwndbg \
    && cd /opt/pwndbg \
    && ./setup.sh

# ============================================================
# Pwngdb — GDB 增强插件 (与 pwndbg 兼容)
# ============================================================
RUN git clone https://github.com/scwuaptx/Pwngdb.git /opt/Pwngdb

# ============================================================
# 配置 GDB 初始化脚本
# ============================================================
RUN cat <<'EOF' > /root/.gdbinit
source /opt/pwndbg/gdbinit.py
source /opt/Pwngdb/pwngdb.py
source /opt/Pwngdb/angelheap/gdbinit.py

define hook-run
python
import angelheap
angelheap.init_angelheap()
end
end
EOF

WORKDIR /ctf
CMD ["/bin/bash"]
