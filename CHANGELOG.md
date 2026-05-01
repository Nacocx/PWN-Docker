# PWN Docker 更新日志

## 2026-05-02 — 基于 CTFTool 参考的全面升级

### 镜像源切换

| 组件 | 旧源 | 新源 |
|------|------|------|
| apt | `archive.ubuntu.com` / `security.ubuntu.com` | `mirrors.aliyun.com` |
| pip | `pypi.org` (默认) | `mirrors.aliyun.com/pypi/simple` |
| gem | `rubygems.org` (默认) | `mirrors.aliyun.com/rubygems` |

### 新增工具

**PWN 专项（参考 CTFTool.md PWN 章节）：**

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| `ROPgadget` | ROP gadget 搜索，编写 ROP exp | pip |
| `pwncli` | PWN 题调试/攻击辅助，本地调试与远程攻击快速切换 | pip |
| `one_gadget` | 一键 RCE gadget 查找（libc 中 execve 调用） | gem |
| `seccomp-tools` | seccomp sandbox 规则分析 | gem |
| `z3-solver` | 约束求解器，符号执行 / 复杂约束求解场景 | pip |

**编译与构建增强：**

| 工具 | 用途 |
|------|------|
| `gcc-multilib` / `g++-multilib` | 32 位二进制编译支持 |
| `nasm` | 汇编器（shellcode 编写） |
| `patchelf` | 修改 ELF 的 interpreter / rpath（libc 切换） |
| `libc6-dev-i386` | 32 位 libc 开发头文件 |
| `libc6-dbg` | libc 调试符号 |

**效率工具：**

| 工具 | 用途 |
|------|------|
| `tmux` | 终端复用（GDB 分屏调试） |
| `xxd` | 十六进制 dump / 转换 |
| `netcat-openbsd` | 更完善的 netcat 变体（替代传统 netcat） |

### 改进项

1. **apt 源重写** — 使用 `sed` 将 Ubuntu 官方源域名替换为阿里云镜像，同时覆盖 `archive.ubuntu.com` 和 `security.ubuntu.com`
2. **apt-get 替代 apt** — 脚本化构建中 `apt-get` 行为更稳定，避免 `apt` 的交互式输出
3. **清理优化** — 新增 `rm -rf /var/lib/apt/lists/*`，减少镜像层体积
4. **HEREDOC 引用保护** — gdbinit 写入使用 `<<'EOF'`（单引号保护），防止 shell 误解析 Python 代码中的 `$` 等字符
5. **时区设置** — 新增 `TZ=Asia/Shanghai`，避免交互式时区配置
6. **分层优化** — 按功能拆分为独立 RUN 层（系统包 / pip / gem / pwndbg / Pwngdb），便于缓存复用和维护

### 文件变更

- `Dockerfile` — 重写
- `CHANGELOG.md` — 新增（本文档）
- `docker-compose.yml` — 新增，一键启停
- `workspace/` — 新增，挂载 PWN 二进制文件的目录

### 快速开始（推荐 compose）

```bash
# 构建并启动（后台运行）
docker compose up -d --build

# 进入容器
docker compose exec pwn bash

# 停止
docker compose stop

# 停止并删除
docker compose down
```

### 添加 PWN 题目

将二进制文件放入 `./workspace/` 目录，容器内 `/ctf/` 路径下即可直接访问：

```bash
cp ~/Downloads/pwn_challenge ./workspace/
docker compose exec pwn bash
# 容器内: cd /ctf && ./pwn_challenge
```

### 传统 docker 命令（可选）

```bash
# 构建
docker build -t pwn-toolkit:latest .

# 交互式运行
docker run -it --rm -v ./workspace:/ctf pwn-toolkit:latest

# 带端口映射（远程 GDB 调试）
docker run -it --rm -v ./workspace:/ctf -p 1234:1234 -p 8888:8888 pwn-toolkit:latest
```
