# Reshell

基于 **Go** 的 C2（Command & Control）实验平台：单进程同时提供 **Web 管理面板**、**TCP 监听器**、**载荷下载与一键上线脚本**，被控端为 **C/C++**（Windows / Linux amd64），通过 **二进制 Stub 修补（C2EMBED1）** 注入回连参数，生成载荷时**不需要**在本机调用 g++ 编译器。

---

## 开发意图

1. **技术架构**：在受控环境中理解典型 C2 的分层设计——管理面（HTTP + JWT + 内嵌前端）、浏览器实时通道（WebSocket）、数据面（TCP 监听与自定义协议）、以及「模板 PE/ELF + 配置块修补」的载荷流水线。  
2. **授权安全测试**：仅用于**自有设备**、**实验室靶机**或**书面授权**的渗透/红队演练；用于未授权系统属违法，本项目不提供也不鼓励此类用途。  
3. **可复现、易部署**：服务端依赖 **纯 Go + 内嵌 SQLite（glebarez/sqlite，默认 `CGO_ENABLED=0`）**，便于单二进制拷贝部署。

---

## 克隆后从零跑通（必读）

按顺序做即可在本机打开面板；**不要求**事先准备 Stub 也能先启动服务（仅登录与界面）。

| 步骤 | 操作 |
|------|------|
| 1 | 安装 **Go 1.21 或以上**（`go version` 可验证）。 |
| 2 | 进入**仓库根目录**（该目录下必须有 `go.mod`、`config.yaml`）。 |
| 3 | 拉依赖：`go mod download` |
| 4 | 编辑 **`config.yaml`**：至少修改 `auth.login_password`、`auth.jwt_secret`（生产环境勿使用默认弱口令）。 |
| 5 | 启动：`go run ./cmd/server` 或先 `go build -trimpath -ldflags="-s -w" -o c2-server.exe ./cmd/server` 再运行生成的可执行文件。 |
| 6 | 浏览器访问 **`config.yaml` 里 `server.addr` 对应的地址**（默认一般为 `http://127.0.0.1:8080` 或 `http://localhost:8080`，若写成 `:8080` 则监听所有网卡）。 |
| 7 | 使用你在配置中设置的 **`login_password`** 登录。 |

**常见启动失败：**

- `load config failed` / `read config`：当前工作目录下**没有** `config.yaml`。请 `cd` 到含配置文件的目录再执行，或在该目录下放一份 `config.yaml`。  
- 端口被占用：修改 `server.addr` 为其他端口，或结束占用进程。

---

## Stub 模板（载荷生成 / 一键上线下载）

以下能力**依赖**带 **C2EMBED1** 魔数的预编译模板文件；若缺失，服务仍可运行，但**载荷生成**、**连接指令里触发的 exe/elf 下载**会报错。

| 文件（相对 `data/stubs/`） | 用途 |
|---------------------------|------|
| `windows_x64.exe` | Windows x64 载荷 |
| `windows_x86.exe` | Windows x86 载荷（本次并未开发，但提供了win适配源码，可自行使用mingw32进行编译） |
| `linux_amd64.elf` | Linux amd64 载荷 |

查找顺序（摘要）：环境变量 **`C2_STUB_DIR`** → 可执行文件同目录下的 `data/stubs` → 当前工作目录下的 `data/stubs`。也可使用 **`go build -tags=stubembed`** 将模板内嵌（见 `internal/payload/stub_embed_on.go`）。自行编译模板时源码在 **`client/native/`**，可配合仓库内 **`scripts/`** 下脚本与本地工具链。

---

## 首次监听与上线（简要）

1. 在 **监听管理** 中 **新增监听**：填写 **监听地址**（如 `0.0.0.0:4444`）、**外网连接地址**（客户端回连用，一般为 `IP:端口` 或域名形式，需与实际可达地址一致）。  
2. 在列表中对该监听点击 **启动**，状态为 **online**。  
3. 点击 **连接指令**：侧栏展示**单行命令**（PowerShell / Linux / certutil / mshta 等），复制到目标环境执行。  
4. **公网或「本机用 localhost 开面板、肉鸡在远端」**时：在 **`config.yaml`** 中配置 **`server.public_host`** 为对客户端可达的 IP 或域名（勿填 `0.0.0.0`），否则连接指令里的 HTTP 地址可能仍指向 `127.0.0.1`，远端无法拉取载荷。

---

## 界面预览

以下图片位于仓库 **`pic/`** 目录（`1.png` … `13.png`）。在 **GitHub / Gitee** 等浏览 `README.md` 时会自动加载相对路径图片，无需额外配置。

### 1. 仪表盘

![仪表盘](pic/1.png)

- **安全管控中心 / 仪表盘**：监听与客户端统计、历史设备数、服务器时间。  
- **配置信息**：版本、Web 端口等。  
- **本机资源**：CPU、内存、磁盘、虚拟内存占用及网络概况。

### 2. 监听管理 — 新增监听

![新增监听抽屉](pic/2.png)

- 侧栏进入 **监听管理**，点击 **新增监听** 打开表单。  
- 填写 **监听地址**、**外网连接地址**、心跳与可选 **VKey / 加密盐** 后保存。

### 3. 监听管理 — 连接指令（单行）

![连接指令侧栏](pic/3.png)

- 监听 **online** 后，点击 **连接指令** 打开右侧抽屉，可复制 **Windows / Linux** 单行上线命令（含 PowerShell、curl、wget、certutil、mshta 等）。  
- 使用 **退出** 或 **×** 关闭抽屉。

### 4. 载荷生成 — 配置

![载荷生成配置](pic/4.png)

- **选择监听器**、**目标操作系统**（Windows x64 / Linux amd64）。  
- Windows 可选 **隐藏控制台**（PE 子系统改为 GUI）。  
- 说明文案提示从 `data/stubs/` 修补模板并输出到 `data/generated/`。

### 5. 载荷生成 — 成功与下载

![载荷生成结果](pic/5.png)

- 点击 **生成载荷** 成功后，在 **生成结果** 区域下载已修补的可执行文件。

### 6. 客户端管理 — 列表与实时通知

![客户端列表](pic/6.png)

- **实时通知** 通过 WebSocket 提示连接状态。  
- **客户端列表** 展示外网/内网 IP、归属地、用户、主机名、OS、进程、在线状态等，可 **管理** 进入详情或 **删除**。

### 7. 设备详情 — 基本信息与功能入口

![设备详情](pic/7.png)

- **基本信息 / 硬件与上线信息**：系统版本、权限、CPU/显卡/内存/磁盘、上下线时间等。  
- **功能面板**：终端、文件、隧道、截图、监控、开机自启等入口。

### 8. 远程终端

![交互式终端](pic/8.png)

- **终端**：WebSocket 交互式 Shell（Windows `cmd` / Linux `bash` PTY），支持连接、断开、清屏。

### 9. 文件管理

![文件管理](pic/9.png)

- 左侧 **文件树**，右侧当前目录列表；支持进入目录、新建、上传、下载及与工作目录 **同步**。

### 10. 隧道代理（SOCKS5 等）

![隧道代理](pic/10.png)

- **创建隧道**：名称、类型（如 SOCKS5）、本地监听端口、可选账号密码。  
- 下方为隧道列表与 **使用说明**（代理链配置示例等）。

### 11. 屏幕截图

![屏幕截图](pic/11.png)

- 选择清晰度后 **下发截图**，在页面查看或放大；与实时监控为独立能力。

### 12. 屏幕监控

![屏幕监控](pic/12.png)

- 设置 **间隔**、**质量** 后 **开始监控**，轮询展示最新一帧；离开前 **停止监控**。

### 13. 开机自启

![开机自启](pic/13.png)

- 选择自启方式后 **设置自启** 或 **移除自启**；具体是否在目标系统生效取决于 **操作系统与客户端实现**（Linux 侧见服务端逻辑；Windows 请以当前客户端代码为准）。

---

## 功能说明（与当前代码一致）

### 服务端与面板

- **配置**：`config.yaml` 与进程**当前工作目录**一致；含 `server.addr`、`auth.login_password`、`auth.jwt_secret`、`database.path`、`logging.level`；可选 **`server.public_host`**（见上文）。  
- **认证**：登录密码 + **JWT**；受保护页面与 `/api/*` 需有效会话。  
- **健康检查**：`GET /healthz`。  
- **仪表盘**：监听/客户端统计、本机 CPU/内存/磁盘等（`gopsutil`）。  
- **静态资源**：`webdist/static` 内嵌进二进制，无需单独部署 `templates/`。

### 监听器（TCP）

- 面板中 **增删改查** 监听；**启动/停止** 对应 **TCP** `Listen`。  
- **连接指令**：由后端生成多种单行/脚本 URL，指向本机 HTTP 上的 stager 或载荷（见下节）。

### 载荷与上线

- **载荷生成**：从 Stub 修补后写入 **`data/generated/`**；当前仅 **`bin`** 格式；目标：**Windows x64 / x86**、**Linux amd64**。可选 **`hide_console`**（Windows PE 改为 GUI 子系统）。  
- **HTTP 直链（无需登录）**：`GET /payload/ps1/:id`、`GET /payload_exe/:id`、`GET /payload/{id}.elf`、`GET /payload/{id}.hta`（HTA 内嵌与 ps1 相同的拉取逻辑）。

### 客户端能力（上线后）

- **终端、文件、进程、截图/监控、SOCKS5 隧道** 等（依客户端与平台实现）。  
- **Linux 开机自启**：systemd 用户单元、XDG autostart、crontab 等（名称含 `reshell-c2-agent`）。**Windows** 面板下发的 `autostart_set` / `autostart_remove` 在当前源码中为**未实现占位**。

### 其他

- **`cmd/linuxagent`**：独立 Linux Agent 入口（需 `GOOS=linux` 编译），与面板 Stub 流程并存时以你实际部署为准。  
- **数据库**：SQLite（默认 `data/c2.db`），首次运行自动创建。

---

## 环境要求

- **Go 1.21+**  
- 服务端：**Linux amd64** 或 **Windows** 均可。  
- **载荷**：依赖 Stub 文件（见上文）；不要求服务端生成时调用 g++。

---

## 编译与运行命令摘要

```bash
# 开发运行（须在含 config.yaml 的目录）
go mod download
go run ./cmd/server
```

```powershell
# Windows 编译示例
go build -trimpath -ldflags="-s -w" -o c2-server.exe ./cmd/server
.\c2-server.exe
```

```powershell
# 交叉编译 Linux amd64 服务端
.\scripts\build-server.ps1 -Target linux
# 或手动：
$env:GOOS="linux"; $env:GOARCH="amd64"; $env:CGO_ENABLED="0"
go build -trimpath -ldflags="-s -w" -o c2-server-linux ./cmd/server
```

---

## 配置项摘要（`config.yaml`）

| 项 | 含义 |
|----|------|
| `server.addr` | HTTP 监听，如 `:8080`、`127.0.0.1:8080` |
| `server.public_host` | 可选；客户端可访问的 Web 主机名或 IP（无端口）；**连接指令与载荷内嵌 Web 地址优先使用**，避免误用 `localhost` |
| `auth.login_password` | 面板登录密码 |
| `auth.jwt_secret` | JWT 密钥，须足够随机 |
| `database.path` | SQLite 路径 |
| `logging.level` | 如 `info`、`debug` |

修改后需**重启进程**。

---

## 目录结构（简要）

| 路径 | 说明 |
|------|------|
| `cmd/server` | 服务端入口 |
| `internal/server` | 路由、鉴权、页面与 API |
| `internal/listener` | TCP 监听 |
| `internal/agent`、`internal/channels`、`internal/websocket` | 连接与通道 |
| `internal/payload` | Stub 与 C2EMBED1 修补 |
| `internal/tunnel` | SOCKS5 |
| `client/native` | 被控端 C++ 源码 |
| `webdist` | 前端模板与静态资源（embed） |
| `data/stubs` | 载荷模板（须含 C2EMBED1） |
| `data/generated` | 生成载荷输出 |
| `scripts` | 构建脚本 |

---

## 安全与合规

- 修改默认密码与 JWT；限制配置文件与数据库文件权限。  
- 防火墙放行所需端口。  
- 仅在**有权测试**的环境使用。

---
## 注！
- 本c2没有bin形式的shellcode，各位安全研究人员如果想使用对应功能可以使用donut工具转换成相对计算基址shellcode或者自尽进行指令替换编写，请谅解！
## 许可证与第三方

- 本项目源码（除第三方组件外）以 **MIT** 许可发布，见根目录 **`LICENSE`**。  
- 终端界面使用 **xterm.js**（`webdist/static/xterm`），遵循其许可证。
