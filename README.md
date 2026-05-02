# PWN Docker — CTF 二进制漏洞利用环境

基于 Ubuntu 24.04，集成 pwndbg + Pwngdb + 多架构模拟的 PWN 容器。

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/Nacocx/PWN-Docker.git
cd PWN-Docker

# 启动容器（首次自动拉取/构建镜像）
./PWN-Docker.sh start

# 进入容器
./PWN-Docker.sh exec
```

## 管理命令

| 命令 | 说明 |
|------|------|
| `./PWN-Docker.sh start` | 启动容器（后台运行） |
| `./PWN-Docker.sh exec` | 进入容器的 zsh |
| `./PWN-Docker.sh stop` | 停止容器 |
| `./PWN-Docker.sh restart` | 重启容器 |
| `./PWN-Docker.sh build` | 本地构建镜像 |
| `./PWN-Docker.sh pull` | 从 GHCR 拉取最新镜像 |
| `./PWN-Docker.sh status` | 查看容器运行状态 |
| `./PWN-Docker.sh logs` | 查看容器日志 |
| `./PWN-Docker.sh remove` | 删除容器（保留镜像） |
| `./PWN-Docker.sh help` | 显示帮助 |

## 放入题目

将 PWN 二进制文件拷贝到 `workspace/` 目录，容器内 `/ctf` 实时同步：

```bash
cp ~/Downloads/pwn_challenge ./workspace/
```

## Shell 环境

- **Shell**: Zsh + Starship 提示符
- **插件**: zsh-autosuggestions（自动建议）、zsh-syntax-highlighting（语法高亮）
- **Fuzzy finder**: Ctrl+R 搜索历史、Ctrl+T 搜索文件

## 容器内常用操作

### 分析

```bash
pwn checksec ./binary        # 查看保护机制
file ./binary                 # 文件类型
readelf -a ./binary           # ELF 结构分析
objdump -T ./libc.so.6        # 查找 libc 符号偏移
seccomp-tools dump ./binary   # seccomp 规则分析
```

### 调试

```bash
gdb ./binary                  # pwndbg + Pwngdb 自动加载
gdbserver :1234 ./binary      # 启动远程调试服务
strace ./binary               # 系统调用追踪
ltrace ./binary               # 库调用追踪
```

### GDB 常用命令

```
b *main          # 下断点
r                # 运行
vmmap            # 查看内存映射
heap             # 查看堆状态 (Pwngdb)
parseheap        # 解析堆结构 (Pwngdb)
telescope $rsp   # 查看栈布局
rop --grep "pop rdi"  # 搜索 ROP gadget
```

### 编译

```bash
gcc -o exp exp.c              # 编译 64 位
gcc -m32 -o exp exp.c         # 编译 32 位
nasm -f elf64 shell.asm       # 汇编 shellcode
```

### 多架构

```bash
qemu-mips ./mips_binary       # 运行 MIPS 二进制
qemu-arm ./arm_binary         # 运行 ARM 二进制
```

### 网络

```bash
socat tcp-l:8888,reuseaddr,fork exec:./binary   # 托管题目
```

## 端口映射

| 宿主机端口 | 用途 |
|-----------|------|
| `1234` | GDB remote (gdbserver) |
| `8888` | socat / exp remote |
| `23946` | IDA Pro remote debugger |

## 远程调试

### GDB remote

```bash
# 容器内
gdbserver :1234 ./binary

# 宿主机
gdb -ex "target remote localhost:1234"
```

### IDA Pro

IDA Pro → Debugger → Run → Remote Linux debugger：
- Host: `localhost`
- Port: `23946`

## 已安装工具

| 类别 | 工具 |
|------|------|
| PWN | pwntools, pwndbg, Pwngdb |
| 编译 | gcc, g++, gcc-multilib, nasm, make, cmake, patchelf |
| 调试 | gdb, gdbserver, ltrace, strace, objdump, readelf, xxd |
| 网络 | netcat-openbsd, socat, curl, wget |
| 多架构 | qemu-user, binfmt-support (ARM/MIPS/...) |
| Shell | zsh, starship, fzf, zsh-autosuggestions, zsh-syntax-highlighting |
| 其他 | git, vim, tmux, ruby, python3 |

## 项目结构

```
PWN-Docker/
├── Dockerfile
├── docker-compose.yml
├── PWN-Docker.sh
├── .github/workflows/build.yml
└── workspace/         ← 题目文件放这里（git 忽略内容）
```

## 镜像

预构建镜像发布在 GitHub Container Registry：

```
ghcr.io/nacocx/pwn-toolkit:latest
```

仅 `Dockerfile` 或 `build.yml` 变更时自动触发 CI 构建。
