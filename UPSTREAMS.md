# Upstream and upgrade policy

`main` is the DeepSeek Harness source baseline plus the small dps deployment
overlay. The legacy Tauri desktop application is preserved separately in the
`desktop-shell-legacy` branch and is deliberately not merged into this branch.

| Role | Source | Pinned revision |
| --- | --- | --- |
| Product source | `deepseek-ai/deepseek-harness` | `dsh-v0.1.1-rc.2` / `b150a551b8d465e31e418e1b2eaf5e79bbb7d28e` |
| Docker deployment reference | `runzhliu/deepseek-harness-docker` | `42c44a9c618ccb121e2f836856e05922b2633474` |

The Docker project is a community reference, not an official DeepSeek image or
official Compose distribution. dps builds the image from this repository's
source and retains the official MIT license in `LICENSE`.

## Upgrade workflow

1. Add or refresh the official remote: `git remote add upstream https://github.com/deepseek-ai/deepseek-harness.git`.
2. Fetch the chosen official tag, create an integration branch, and rebase the
   dps overlay commits onto it. Do not merge `desktop-shell-legacy`.
3. Resolve only deployment/documentation conflicts under `deploy/docker/`,
   `compose.yaml`, `.env.example`, `.dockerignore`, and this file.
4. Run `pnpm install --frozen-lockfile`, `pnpm run build`, `pnpm run typecheck`,
   and `pnpm test`. A Host API or DTO change must complete the full build so
   Typert regenerates and verifies the Client contract before the Vite UI is
   rebuilt.
5. Run `docker compose up -d --build`, verify the health check and
   `http://127.0.0.1:3080/`, then commit the exact source and Docker reference
   revisions here.

## Development boundary

`apps/web` is not a standalone Vite application: `pnpm dsh web` injects
`window.__DSH_BOOT__` and serves the same-origin `/api` gateway. Frontend work
belongs in `apps/web` and `packages/client/*`; Host capabilities use
`@Remote`/`@RemoteScope`, and the browser invokes them through `ctx.remote`.
Do not add a separate HTTP API proxy or CORS policy for this local deployment.
