# Local Docker deployment and desktop shell

The canonical split deployment lives in `docker/`:

1. Copy `docker/.env.example` to `docker/.env` and set `DEEPSEEK_API_KEY`.
2. Run `docker compose up -d --build` from `docker/`.
3. Open `http://127.0.0.1:3080/`, or build and start the WebView shell with
   `scripts/start.bat`.

`src-tauri/` is intentionally a minimal Tauri 2 shell. It waits for the Docker
backend, opens the same-origin Harness UI only after it is ready, and falls
back to a bundled "请先启动 Docker 后端服务" page. It neither starts nor manages
the dsh process and contains no API key. Build it on a Windows machine with a
Rust toolchain and the matching Tauri CLI installed:

```powershell
cd src-tauri
cargo tauri build
```

The published port is bound only to `127.0.0.1`; it is not reachable from the
LAN. Harness sessions, configuration, and credentials persist in the named
`dps-dsh-home` volume. The prior `dsh-data` volume is intentionally neither
mounted nor removed by this deployment.

The default `DSH_WORKSPACE=../workspace` is deliberately separate from this
deployment checkout: Harness reads a workspace `.env`, while `docker/.env`
contains protected launch-time settings such as `DEEPSEEK_API_KEY`.
Point `DSH_WORKSPACE` to another project only when its own `.env` does not
declare those protected launch-time variables.

For source development, install dependencies and run the full build before
starting the Web profile:

```powershell
pnpm install --frozen-lockfile
pnpm run build
pnpm dsh web --no-open
```

`pnpm run dev:web` is only the Web rebuild watcher used alongside the managed
`pnpm dsh web` process. Do not start bare Vite: it cannot inject the Harness
boot manifest or provide the same-origin `/api` contract.
