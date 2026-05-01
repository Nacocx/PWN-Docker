# PWN Docker — CTF 二进制漏洞利用环境

基于 Ubuntu 24.04，集成 pwndbg + Pwngdb 联合调试的 PWN 容器。apt 源切换阿里云镜像，国内构建无需代理。

## 使用说明

### 1. 构建并启动

```bash
docker compose up -d --build
```

首次构建约 5~10 分钟，后续启动只需 `docker compose up -d`。

### 2. 放入题目

将 PWN 二进制文件拷贝到 `workspace/` 目录：

```bash
cp ~/Downloads/pwn_challenge ./workspace/
```

### 3. 进入容器

```bash
docker compose exec pwn bash
```

容器内 `/ctf` 即宿主机 `./workspace/`，文件实时同步。

### 4. 停止

```bash
docker compose stop       # 保留容器
docker compose down       # 删除容器
```

---

## 容器内常用操作

| 场景 | 命令 |
|------|------|
| 分析二进制保护 | `pwn checksec ./binary` |
| 调试 | `gdb ./binary` |
| 查找 libc 偏移 | `objdump -T ./libc.so.6 \| grep system` |
| 修改动态链接器 | `patchelf --set-interpreter ./ld.so --set-rpath ./ ./binary` |
| 编译 32 位程序 | `gcc -m32 -o exp exp.c` |
| 汇编 shellcode | `nasm -f elf64 shell.asm -o shell.o` |
| 托管题目 TCP | `socat tcp-l:8888,reuseaddr,fork exec:./binary` |
| 远程调试服务 | `gdbserver :1234 ./binary` |
| 系统调用追踪 | `strace ./binary` |
| 库调用追踪 | `ltrace ./binary` |
| 十六进制查看 | `xxd ./binary` |
| 终端分屏 | `tmux` |

### GDB 提示

进入 GDB 后 pwndbg + Pwngdb 自动加载：

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

### GDB remote

```bash
# 容器内
gdbserver :1234 ./binary

# 宿主机
gdb -ex "target remote localhost:1234"
```

### IDA Pro remote

IDA Pro → Debugger → Run → Remote Linux debugger
- Host: `localhost`
- Port: `23946`

将 `linux_server` / `linux_server64` 放入 workspace 后运行即可。

---

## 端口映射

| 宿主机端口 | 用途 |
|-----------|------|
| `1234` | GDB remote (gdbserver) |
| `8888` | socat / exp remote |
| `23946` | IDA Pro remote debugger |

---

## 已安装工具

### PWN 核心
| 工具 | 来源 | 说明 |
|------|------|------|
| pwntools | [GitHub](https://github.com/Gallopsled/pwntools) | exp 编写框架 |
| pwndbg | [GitHub](https://github.com/pwndbg/pwndbg) | GDB 增强插件 |
| Pwngdb | [GitHub](https://github.com/scwuaptx/Pwngdb) | GDB 增强插件 |

### 编译与构建
| 工具 | 来源 | 说明 |
|------|------|------|
| gcc / g++ | apt | x86-64 编译器 |
| gcc-multilib / g++-multilib | apt | 32 位编译支持 |
| nasm | apt | 汇编器 |
| make / cmake | apt | 构建系统 |
| patchelf | apt | 修改 ELF interpreter / rpath |

### 调试与分析
| 工具 | 来源 | 说明 |
|------|------|------|
| gdb / gdbserver | apt | GNU 调试器 |
| binutils | apt | objdump, readelf, strings 等 |
| elfutils | apt | eu-readelf, eu-addr2line 等 |
| ltrace / strace | apt | 库/系统调用追踪 |
| file / xxd | apt | 文件类型识别 / 十六进制 dump |
| libc6-dbg | apt | libc 调试符号 |
| libc6-dev-i386 | apt | 32 位 libc 开发文件 |

### 网络与终端
| 工具 | 来源 | 说明 |
|------|------|------|
| netcat-openbsd | apt | 网络工具 |
| socat | apt | 网络转发 / 题目托管 |
| curl / wget | apt | 文件下载 |
| git / vim / nano | apt | 编辑与版本控制 |
| tmux | apt | 终端复用 |
| ruby | apt | Ruby 运行时（可按需 gem install） |

---

## 镜像源

| 组件 | 源 |
|------|-----|
| apt | `mirrors.aliyun.com` |
| pip | PyPI 默认源 |

---

## 项目结构

```
PWN-Docker/
├── Dockerfile
├── docker-compose.yml
├── README.md
├── CHANGELOG.md
├── CTFTool.md
└── workspace/          ← 题目文件放这里
```
