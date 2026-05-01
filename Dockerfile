FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive


# 安装必要工具
RUN apt update && apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    curl \
    wget \
    vim \
    nano \
    python3 \
    python3-pip \
    python3-dev \
    sudo \
    file \
    ltrace \
    strace \
    netcat \
    socat \
    gdb \
    gdbserver \
    && apt clean

RUN pip3 install --no-cache-dir \
    pwntools \
    ropper \
    keystone-engine \
    unicorn \
    capstone

# 配置 pwndbg 和 Pwngdb 联合调试, 经过我的验证,下面的配置不会冲突
RUN git clone https://github.com/pwndbg/pwndbg /opt/pwndbg \
    && cd /opt/pwndbg \
    && ./setup.sh

RUN git clone https://github.com/scwuaptx/Pwngdb.git /opt/Pwngdb

RUN cat <<EOF >> /root/.gdbinit
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


# 配置其他工具
RUN apt install -y \
    radare2 \
    binutils \
    elfutils \
    && apt clean


WORKDIR /ctf

# 默认 bash
CMD ["/bin/bash"]