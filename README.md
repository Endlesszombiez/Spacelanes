<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./src/assets/branding/mono-slate.svg">
  <img src="./src/assets/branding/paper-red.svg" alt="Spacelanes Proxy" width="144">
</picture>

# Spacelanes Proxy

**Your proxy, at a glance. Your configuration, in control.**

CLI Proxy API and its Spacelanes management UI, built and served together.<br>
Manage providers, credentials, quotas, and logs — from a single HTML file.

[![Backend: v8](https://img.shields.io/badge/Backend-v8-5865F2?style=flat-square)](https://github.com/router-for-me/CLIProxyAPI)
[![Single-file build](https://img.shields.io/badge/Build-single_HTML-0F766E?style=flat-square)](#deployment)
[![License: MIT](https://img.shields.io/badge/License-MIT-64748B?style=flat-square)](LICENSE)

**English** · [简体中文](README_CN.md)

[Get started](#quick-start) · [Features](#features) · [Development](#development) · [Releases](https://github.com/router-for-me/Cli-Proxy-API-Management-Center/releases)

</div>

---

## One place to manage your instance

From everyday configuration to troubleshooting, keep the essentials close at hand.

| Configure | Connect | Observe |
| --- | --- | --- |
| Edit settings visually or in YAML, with a diff before saving. | Manage provider keys, auth files, and OAuth flows. | Check instance status, provider quotas, and request logs. |

**Single-file deployment** · **Responsive layout** · **Four UI languages**

> [!IMPORTANT]
> This repository includes the **CLI Proxy API v8 backend** in `backend/` and the Spacelanes frontend in `src/`. The Docker stack builds and serves both through one address. The frontend uses the **v8 Management API** (`/v8/management`) and v8 configuration layout, with no v0 fallback. Plugin resources and custom extensions retain their backend-declared paths.

## Quick start

For a complete deployment, use the [Portainer stack](#published-stack--portainer) below, or set
`MANAGEMENT_PASSWORD` and run `docker compose up -d --build` from this checkout.

1. Start the stack.
2. Open `http://<host>:8080`.
3. Enter your **management password** and connect using the detected address.

The standalone single-file UI remains available at `dist/index.html`; an existing compatible
backend can host it as `management.html`.

The API address is detected from the page URL and can be changed manually.

> [!NOTE]
> The **management key** signs you into this UI. Client keys in `access.api-keys` authorize requests to the proxy — they are not interchangeable.

<details>
<summary><strong>Connection settings & remote access</strong></summary>

The UI accepts addresses such as `localhost:8317`, `https://example.com:8317`, or `http://example.com:8317/v8/management`; the management suffix is removed automatically.

Management requests use `Authorization: Bearer <MANAGEMENT_KEY>`. Remote access may require `management.allow-remote: true` on the server. See the [backend documentation](https://github.com/router-for-me/CLIProxyAPI) for authentication rules and server-side limits.

</details>

<details>
<summary><strong>Upgrading from v7</strong></summary>

Upgrade the backend first and back up `config.yaml`. The backend returns the v8 configuration layout on reads; a successful v8 configuration write migrates the stored file. The editor only writes v8 fields:

- `access.api-keys`: client keys for accessing the proxy.
- Top-level `api-keys`: upstream provider groups.

</details>

## Features

| Area | What you can do |
| --- | --- |
| **Dashboard** | See connection status, server version, build date, and model availability at a glance. |
| **Configuration** | Edit common settings and client keys visually, or use the YAML editor with search, highlighting, and a save diff preview. |
| **AI providers** | Configure Gemini, Codex, Claude, Vertex, and OpenAI-compatible providers; manage keys, headers, proxies, and model mappings. |
| **Auth files & OAuth** | Upload, download, and organize credentials; connect supported providers with OAuth or device flows; manage model aliases and exclusions. |
| **Quotas** | Inspect quota and usage information for supported providers, including Claude, Antigravity, Codex, Kimi, and xAI/Grok. |
| **Logs** | Follow logs with auto-refresh, search, hide management traffic, and download request error logs. |
| **Plugins** | Access plugin management when the connected backend advertises support. |
| **System** | Check for updates, inspect available models, and clear local login data. |

Supports **English, 简体中文, 繁體中文, and Русский**, with browser-language detection and a manual language switch. Responsive layouts support desktop, tablet, and mobile use in modern Chrome, Firefox, Safari, and Edge.

## Deployment

To build your own single-file UI, use **Bun 1.4.3**:

```bash
bun install --frozen-lockfile
bun run build
```

The output is **`dist/index.html`**, with JavaScript, CSS, and bundled assets inlined. The release workflow renames it to `management.html` for backend hosting.

Use `bun run preview` to preview locally. Prefer an HTTP server over opening the file via `file://`, which can encounter browser CORS restrictions.

### Published stack / Portainer

[The container workflow](.github/workflows/docker.yml) builds **both components from this
repository** and publishes two images to GitHub Container Registry:

- `ghcr.io/endlesszombiez/spacelanes:latest` — the Spacelanes UI and Nginx gateway.
- `ghcr.io/endlesszombiez/spacelanes:backend-latest` — the CLI Proxy API backend in [backend/](backend/).

Both support `linux/amd64` and `linux/arm64`. Frontend tags are `latest`, `v*`, and
`sha-<commit>`; backend tags have the `backend-` prefix (`backend-latest`, `backend-v*`,
and `backend-sha-<commit>`). Both images share the existing GHCR package and its visibility. The workflow tests
v8 login, rejected credentials, client authentication, and persistent data before publishing.
Pull requests build and test the stack without publishing images.

In **Portainer → Stacks → Add stack**, add an environment variable named
`MANAGEMENT_PASSWORD` with the password you want to enter at login. A password generated with
`openssl rand -base64 32` works: use the complete output literally, without decoding it.
Set this in Portainer, not in an image or committed YAML file.

Paste [compose.portainer.yaml](compose.portainer.yaml) into the Web editor on a Docker
Standalone host (the same file works with ordinary Docker Compose):

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

Open **http://YOUR-DOCKER-HOST-IP:8080**, leave the detected server address selected,
and log in with `MANAGEMENT_PASSWORD`. Nginx forwards Management API, proxy, OAuth, and
plugin requests to the backend using their original paths. No separate backend address is
needed. Proxy clients use `http://YOUR-DOCKER-HOST-IP:8080/v1` and a **client API key** from
Configuration → client keys. First startup generates a random client key; it is separate
from your management password.

The `spacelanes-data` volume stores `config.yaml`, auth files, the local database, logs,
and installed plugins under `/data`. The initial configuration is copied only when the
volume has no `config.yaml`; image updates preserve subsequent changes made in the UI.
Back up this volume. Removing it resets the configuration and credentials.

Redeploy with image pulling enabled to update both services. Changing `MANAGEMENT_PASSWORD`
and redeploying changes the login password without resetting stored configuration. With
Compose outside Portainer, use `docker compose -f compose.portainer.yaml pull` followed by
`docker compose -f compose.portainer.yaml up -d`.

The GHCR `spacelanes` package must be public for anonymous pulls. If you fork this repository,
set your package's visibility to **Public**, or configure Portainer with GHCR credentials
that have `read:packages` access.

### Docker Compose / local builds

Set `MANAGEMENT_PASSWORD` in your environment or an untracked `.env` file, then build both
services from this checkout:

```bash
docker compose up -d --build
```

Open **http://localhost:8080** and log in with that password. Set `SPACELANES_PORT` to change
the host port and `VERSION` to label the frontend build. Both services run as non-root users
and expose health checks; the backend is reachable through Nginx on the stack network.
The backend's bundled upstream management panel is disabled so it cannot replace Spacelanes.

`backend/` contains the upstream source snapshot, not a prebuilt binary or a runtime download.
[backend/UPSTREAM.json](backend/UPSTREAM.json) records its release, exact commit, archive hash,
and local changes; [backend/LICENSE](backend/LICENSE) retains the upstream MIT license.
Go dependencies are pinned by `backend/go.mod` and `backend/go.sum`. The backend Dockerfile
compiles the binary with CGO support for each target architecture. See
[docker/backend.Dockerfile](docker/backend.Dockerfile) for its Go toolchain version.

Antigravity OAuth requires `ANTIGRAVITY_OAUTH_CLIENT_ID` and
`ANTIGRAVITY_OAUTH_CLIENT_SECRET` on the backend. Set them in the Portainer stack environment
if you use that provider. The imported backend's embedded OAuth credentials were removed;
login and refresh now use these runtime values. Other providers and management login do not
require these variables.

Provider OAuth flows can require a localhost callback or an SSH tunnel, depending on the
provider. The UI's callback-paste flow uses this same public address; use backend CLI flags
or publish the provider-specific callback port only if you choose a CLI login flow.

Stop the stack with `docker compose down`; the named volume is retained.

<details>
<summary><strong>Release details</strong></summary>

- Tags matching `vX.Y.Z` trigger [the release workflow](.github/workflows/release.yml).
- The UI version is injected at build time from `VERSION`, then git tags, then the package version, with `dev` as the final fallback.
- Hash routing and an ES2020 build target keep deployment simple.

</details>

## Development

```bash
bun install --frozen-lockfile
bun run dev
```

Open `http://localhost:5173` and connect to your backend instance.

**Built with** React 19 · TypeScript 6 · Vite 8 · Zustand · Axios · React Router 7 · Motion · CodeMirror 6 · SCSS Modules · i18next.

| Command | Purpose |
| --- | --- |
| `bun run dev` | Start the Vite dev server |
| `bun run build` | TypeScript compilation + production build |
| `bun run preview` | Serve the build locally |
| `bun run test` | Run Bun tests |
| `bun run lint` | Run ESLint; warnings are not treated as failures |
| `bun run type-check` | Run `tsc --noEmit` |
| `bun run verify` | Run tests, lint, and build |
| `bun run format` | Format source files with Prettier |

Issues and PRs are welcome. Include reproduction steps, backend and UI versions, screenshots for UI changes, and verification results. See [AGENTS.md](AGENTS.md) for repository conventions.

## Security

Treat the management key as a secret. When **remember password** is enabled, it is persisted in browser storage using reversible obfuscation — **not encryption**.

Use a trusted device or dedicated browser profile. Enable remote management only after evaluating the exposure of your server.

## Troubleshooting

<details>
<summary><strong>Connection or authentication problems</strong></summary>

- **Cannot connect / 401:** check the API address and management key. Remote connections may require remote management to be enabled.
- **Repeated authentication failures:** the server may temporarily block remote IPs.

</details>

<details>
<summary><strong>Missing pages, unsupported features, or failed tests</strong></summary>

- **Logs page missing:** enable “Logging to file” in Basic Settings.
- **Feature unsupported:** check the backend version and whether the relevant endpoint is enabled. Some capabilities depend on backend support.
- **Model list unavailable:** querying `/v1/models` requires at least one proxy API key.
- **OpenAI provider test fails:** this test runs in the browser and depends on the provider's network reachability and CORS policy. Failure does not necessarily mean the backend cannot reach it.

</details>

---

<div align="center">

[CLI Proxy API](https://github.com/router-for-me/CLIProxyAPI) · [Report an issue](https://github.com/router-for-me/Cli-Proxy-API-Management-Center/issues) · [MIT License](LICENSE)

</div>
