<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./src/assets/branding/mono-slate.svg">
  <img src="./src/assets/branding/paper-red.svg" alt="Spacelanes Proxy" width="144">
</picture>

# Spacelanes Proxy

**运行状态，一目了然。服务配置，尽在掌握。**

CLI Proxy API 后端与 Spacelanes 管理界面，一起构建与部署。<br>
提供商、凭据、配额与日志，一个 HTML 文件即可管理。

[![后端：v8](https://img.shields.io/badge/Backend-v8-5865F2?style=flat-square)](https://github.com/router-for-me/CLIProxyAPI)
[![单文件构建](https://img.shields.io/badge/Build-single_HTML-0F766E?style=flat-square)](#部署)
[![许可证：MIT](https://img.shields.io/badge/License-MIT-64748B?style=flat-square)](LICENSE)

[English](README.md) · **简体中文**

[快速开始](#快速开始) · [功能一览](#功能一览) · [本地开发](#本地开发) · [下载发布版本](https://github.com/router-for-me/Cli-Proxy-API-Management-Center/releases)

</div>

---

## 一个界面，掌握服务全貌

从日常配置到故障排查，让常用操作触手可及。

| 配置服务 | 接入模型 | 观察运行 |
| --- | --- | --- |
| 可视化或 YAML 编辑，保存前查看差异。 | 统一管理提供商密钥、认证文件与 OAuth 授权。 | 查看服务状态、提供商配额与请求日志。 |

**单文件部署** · **响应式布局** · **四种界面语言**

> [!IMPORTANT]
> 本仓库包含 `backend/` 中的 **CLI Proxy API v8 后端** 和 `src/` 中的 Spacelanes 前端。Docker 栈从同一地址提供两者。前端仅使用 **v8 Management API**（`/v8/management`）与 v8 配置结构，不提供 v0 回退；插件资源与自定义扩展保留后端声明的路径。

## 快速开始

使用下方的完整 Portainer 栈，或设置 `MANAGEMENT_PASSWORD` 后在本仓库运行
`docker compose up -d --build`。

1. 启动完整栈。
2. 打开 `http://<host>:8080`。
3. 输入管理密码，保留自动检测的地址并连接。

单文件界面 `dist/index.html` 仍可独立部署为现有后端的 `management.html`。

页面会根据当前 URL 自动识别 API 地址，也支持手动修改。

> [!NOTE]
> **管理密钥**用于登录本界面；`access.api-keys` 中的客户端密钥用于请求代理接口，两者不能混用。

<details>
<summary><strong>连接设置与远程访问</strong></summary>

支持 `localhost:8317`、`https://example.com:8317` 或 `http://example.com:8317/v8/management` 等地址格式；管理接口后缀会被自动移除。

管理请求使用 `Authorization: Bearer <MANAGEMENT_KEY>`。远程访问可能需要在服务端开启 `management.allow-remote: true`。完整鉴权规则与服务端限制请参考[后端文档](https://github.com/router-for-me/CLIProxyAPI)。

</details>

<details>
<summary><strong>从 v7 升级</strong></summary>

请先升级后端并备份 `config.yaml`。后端读取时返回 v8 配置结构，成功的 v8 配置写入会迁移磁盘文件。编辑器仅写入 v8 字段：

- `access.api-keys`：访问代理的客户端密钥。
- 顶层 `api-keys`：上游提供商分组。

</details>

## 功能一览

| 模块 | 你可以做什么 |
| --- | --- |
| **仪表盘** | 快速查看连接状态、服务版本、构建时间与可用模型概览。 |
| **配置面板** | 可视化编辑常用设置与客户端密钥；也可使用支持搜索、高亮和保存前差异预览的 YAML 编辑器。 |
| **AI 提供商** | 配置 Gemini、Codex、Claude、Vertex 与 OpenAI 兼容提供商，管理密钥、请求头、代理和模型映射。 |
| **认证文件与 OAuth** | 上传、下载和整理凭据，通过 OAuth 或设备码流程连接支持的提供商，管理模型别名与排除规则。 |
| **配额** | 查看支持的提供商的配额与使用情况，包括 Claude、Antigravity、Codex、Kimi 和 xAI/Grok 等。 |
| **日志** | 自动刷新、搜索日志、隐藏管理端流量，以及下载请求错误日志。 |
| **插件** | 在已声明支持插件的后端上使用插件管理功能。 |
| **系统信息** | 检查更新、查看可用模型，以及清理本地登录数据。 |

支持 **English、简体中文、繁體中文和 Русский**，自动识别浏览器语言，也可手动切换。响应式布局适配桌面、平板与手机，支持现代 Chrome、Firefox、Safari 和 Edge 浏览器。

## 部署

如需自行构建单文件界面，使用 **Bun 1.4.3**：

```bash
bun install --frozen-lockfile
bun run build
```

产物为 **`dist/index.html`**，JavaScript、CSS 与打包资源均已内联。发布工作流会将其重命名为 `management.html`，供后端托管。

使用 `bun run preview` 本地预览。建议通过 HTTP 服务访问，直接用 `file://` 打开可能受到浏览器 CORS 限制。

### 完整镜像栈 / Portainer

[容器工作流](.github/workflows/docker.yml) 从本仓库源码构建并发布两个镜像：

- `ghcr.io/endlesszombiez/spacelanes:latest`：Spacelanes 前端与 Nginx 网关。
- `ghcr.io/endlesszombiez/spacelanes:backend-latest`：[backend/](backend/) 中的 CLI Proxy API 后端。

两者均支持 `linux/amd64` 和 `linux/arm64`。推送到 `main` 发布 `latest`；`v*` 标签
发布对应版本，并生成 `sha-<commit>` 标签。后端标签使用 `backend-` 前缀，例如
`backend-latest`、`backend-v1.2.3` 和 `backend-sha-<commit>`。两者共享现有 GHCR 包的可见性。
发布前会测试登录、鉴权和数据持久化。
Pull request 只构建和测试，不发布镜像。

在 **Portainer → Stacks → Add stack** 中添加环境变量 `MANAGEMENT_PASSWORD`，
设置为登录时输入的密码。可使用 `openssl rand -base64 32` 生成的完整字符串，
无需解码。不要把真实密码写入镜像或提交到仓库。

将 [compose.portainer.yaml](compose.portainer.yaml) 粘贴到 Docker Standalone 主机的
Web editor 中：

```yaml
services:
  backend:
    image: ghcr.io/endlesszombiez/spacelanes:backend-latest
    pull_policy: always
    environment:
      MANAGEMENT_PASSWORD: "${MANAGEMENT_PASSWORD:?Set MANAGEMENT_PASSWORD in Portainer stack environment variables}"
      ANTIGRAVITY_OAUTH_CLIENT_ID: "${ANTIGRAVITY_OAUTH_CLIENT_ID:-}"
      ANTIGRAVITY_OAUTH_CLIENT_SECRET: "${ANTIGRAVITY_OAUTH_CLIENT_SECRET:-}"
    volumes:
      - spacelanes-data:/data
    restart: unless-stopped

  spacelanes:
    image: ghcr.io/endlesszombiez/spacelanes:latest
    pull_policy: always
    depends_on:
      backend:
        condition: service_healthy
    ports:
      - "${SPACELANES_PORT:-8080}:8080"
    restart: unless-stopped

volumes:
  spacelanes-data:
```

打开 **http://YOUR-DOCKER-HOST-IP:8080**，保留自动检测的服务器地址，输入
`MANAGEMENT_PASSWORD` 登录。Nginx 按原始路径转发管理 API、代理、OAuth 和插件请求，
无需另外部署后端或填写后端地址。代理客户端使用 `http://YOUR-DOCKER-HOST-IP:8080/v1`
及配置页面中的客户端 API 密钥。首次启动会生成随机客户端密钥，与管理密码独立。

`spacelanes-data` 卷保存 `/data` 下的 `config.yaml`、认证文件、数据库、日志和插件。
仅首次启动复制默认配置；更新镜像保留之后的配置修改。请备份该卷，删除卷会重置数据。
更改 `MANAGEMENT_PASSWORD` 并重新部署即可更改登录密码，不会清空配置。

更新时拉取两个镜像并重新部署。普通 Compose 可运行
`docker compose -f compose.portainer.yaml pull`，然后运行
`docker compose -f compose.portainer.yaml up -d`。GHCR 的 `spacelanes` 包需设为 **Public**
才能匿名拉取，否则请在 Portainer 配置具有 `read:packages` 权限的 GHCR 凭据。

### Docker Compose / 本地构建

在环境或未提交的 `.env` 文件中设置 `MANAGEMENT_PASSWORD`，然后运行：

```bash
docker compose up -d --build
```

打开 **http://localhost:8080** 并用该密码登录。`SPACELANES_PORT` 设置主机端口，
`VERSION` 设置前端版本。两个服务均使用非 root 用户和健康检查；后端通过栈网络
由 Nginx 转发。上游自带管理面板已禁用，避免覆盖 Spacelanes。

`backend/` 包含后端源码快照。[backend/UPSTREAM.json](backend/UPSTREAM.json) 记录
版本、提交、归档哈希和本地修改，[backend/LICENSE](backend/LICENSE) 保留 MIT 许可证。
Go 依赖由 `go.mod` 与 `go.sum` 固定，Dockerfile 为每个架构编译支持 CGO 的后端。
Antigravity OAuth 需要在后端设置 `ANTIGRAVITY_OAUTH_CLIENT_ID` 和
`ANTIGRAVITY_OAUTH_CLIENT_SECRET`。使用该提供商时请在 Portainer 栈环境变量中提供；
源码中的内置 OAuth 凭据已移除。其他提供商与管理登录不需要这两个变量。
提供商 OAuth 可能需要 localhost 回调或 SSH 隧道；UI 的粘贴回调流程使用同一公开地址。
只有选择 CLI 登录流程时才需要按提供商发布额外回调端口。

运行 `docker compose down` 停止栈，命名卷会保留。

<details>
<summary><strong>发布细节</strong></summary>

- `vX.Y.Z` 格式的标签会触发[发布工作流](.github/workflows/release.yml)。
- UI 版本在构建时注入，依次取自 `VERSION`、git tag、package 版本，最终回退为 `dev`。
- 使用 Hash 路由与 ES2020 构建目标，保持部署简单。

</details>

## 本地开发

```bash
bun install --frozen-lockfile
bun run dev
```

打开 `http://localhost:5173`，连接你的后端实例。

**技术栈**：React 19 · TypeScript 6 · Vite 8 · Zustand · Axios · React Router 7 · Motion · CodeMirror 6 · SCSS Modules · i18next。

| 命令 | 用途 |
| --- | --- |
| `bun run dev` | 启动 Vite 开发服务器 |
| `bun run build` | TypeScript 编译与生产构建 |
| `bun run preview` | 本地预览构建产物 |
| `bun run test` | 运行 Bun 测试 |
| `bun run lint` | 运行 ESLint，警告不视为失败 |
| `bun run type-check` | 运行 `tsc --noEmit` |
| `bun run verify` | 运行测试、lint 与构建 |
| `bun run format` | 使用 Prettier 格式化源文件 |

欢迎提交 Issue 与 PR。请附上复现步骤、后端与 UI 版本、界面改动截图和验证结果。仓库约定见 [AGENTS.md](AGENTS.md)。

## 安全提示

请妥善保管管理密钥。启用 **记住密码** 后，密钥会以可逆混淆形式保存在浏览器存储中，**这不是加密**。

建议使用可信设备或独立浏览器配置。开启远程管理前，请评估服务的暴露范围。

## 常见问题

<details>
<summary><strong>连接或鉴权失败</strong></summary>

- **无法连接 / 401**：检查 API 地址与管理密钥；远程连接可能需要服务端开启远程管理。
- **反复鉴权失败**：服务端可能临时封禁远程 IP。

</details>

<details>
<summary><strong>页面缺失、功能不支持或测试失败</strong></summary>

- **日志页面不显示**：请在基础设置中开启“写入日志文件”。
- **功能提示不支持**：检查后端版本与相关接口是否启用，部分能力依赖后端支持。
- **无法获取模型列表**：查询 `/v1/models` 至少需要一个代理 API Key。
- **OpenAI 提供商测试失败**：测试在浏览器侧执行，受提供商网络可达性与 CORS 策略影响；失败不一定代表后端无法连接。

</details>

---

<div align="center">

[CLI Proxy API](https://github.com/router-for-me/CLIProxyAPI) · [反馈问题](https://github.com/router-for-me/Cli-Proxy-API-Management-Center/issues) · [MIT 许可证](LICENSE)

</div>
