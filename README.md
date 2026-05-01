# PWN Docker — CTF 二进制漏洞利用环境

开箱即用的 PWN 调试/攻击容器，基于 Ubuntu 22.04，集成 pwndbg + Pwngdb 联合调试，全部源切换为阿里云镜像。

## 使用说明

### 1. 构建并启动

```bash
docker compose up -d --build
```

首次构建约 5~10 分钟。之后启动只需 `docker compose up -d`。

### 2. 放入题目

将 PWN 二进制文件拷贝到 `workspace/` 目录：

```bash
cp ~/Downloads/ret2libc ./workspace/
```

### 3. 进入容器

```bash
docker compose exec pwn bash
```

容器内 `/ctf` 即宿主机的 `./workspace/`，文件实时同步。

### 4. 停止容器

```bash
docker compose stop      # 保留容器
docker compose down       # 删除容器
```

---

## 容器内常用命令

| 场景 | 命令 |
|------|------|
| 分析二进制保护 | `checksec ./binary` |
| 寻找 ROP gadget | `ROPgadget --binary ./binary` |
| 找 one_gadget | `one_gadget /lib/x86_64-linux-gnu/libc.so.6` |
| 修改 ELF 动态链接器 | `patchelf --set-interpreter ./ld.so --set-rpath ./ ./binary` |
| 调试二进制 | `gdb ./binary` |
| 查看 seccomp 规则 | `seccomp-tools dump ./binary` |
| 十六进制查看 | `xxd ./binary \| less` |
| 启动 socat 托管题目 | `socat tcp-l:8888,reuseaddr,fork exec:./binary` |
| 编译 32 位 exp | `gcc -m32 -o exp exp.c` |

### GDB 使用提示

进入 GDB 后 pwndbg 自动加载，常用命令：

```
gdb ./binary
(gdb) b *main          # 下断点
(gdb) r                # 运行
(gdb) vmmap            # 查看内存映射
(gdb) heap             # 查看堆状态 (Pwngdb)
(gdb) parseheap        # 解析堆结构 (Pwngdb)
(gdb) telescope $rsp   # 查看栈布局
(gdb) rop --grep "pop rdi"   # 搜索 gadget
```

---

## 远程调试

### GDB 远程调试

容器内启动 gdbserver：

```bash
gdbserver :1234 ./binary
```

宿主机连接：

```bash
gdb -ex "target remote localhost:1234"
```

### IDA 远程调试

IDA Pro → Debugger → Run → Remote Linux debugger：
- Host: `localhost`
- Port: `23946`

容器内启动 IDA linux_server（需自行将 `linux_server` 放入 workspace）：

```bash
./linux_server64    # 或 linux_server（32 位）
```

---

## 已安装工具

### PWN 核心

| 工具 | 来源 |
|------|------|
| pwntools | pip |
| pwndbg | GitHub |
| Pwngdb + angelheap | GitHub |
| ROPgadget | pip |
| pwncli | pip |
| one_gadget | gem |
| seccomp-tools | gem |
| z3-solver | pip |

### 二进制分析

| 工具 | 来源 |
|------|------|
| gdb + gdbserver | apt |
| radare2 | apt |
| ltrace / strace | apt |
| binutils (objdump, readelf, strings) | apt |
| patchelf | apt |
| xxd | apt |
| file | apt |

### 编译与开发

| 工具 | 来源 |
|------|------|
| gcc / g++ (x86 + x86-64, multilib) | apt |
| nasm | apt |
| make / cmake | apt |
| python3 + pip | apt |
| ruby + gem | apt |
| git / vim / nano / tmux | apt |

### 网络

| 工具 | 来源 |
|------|------|
| netcat-openbsd | apt |
| socat | apt |
| curl / wget | apt |

---

## 端口映射

| 宿主机端口 | 用途 |
|-----------|------|
| 1234 | GDB remote (gdbserver) |
| 8888 | socat / exp remote |
| 23946 | IDA Pro remote debugger |

---

## 目录结构

```
PWN-Docker/
├── Dockerfile
├── docker-compose.yml
├── README.md
├── CHANGELOG.md
├── CTFTool.md
└── workspace/          ← 题目文件放这里
```

---

## 镜像源

所有包管理器已配置为阿里云镜像，国内构建无需代理：

- apt: `mirrors.aliyun.com`
- pip: `mirrors.aliyun.com/pypi/simple`
- gem: `mirrors.aliyun.com/rubygems`
