# Local Docker deployment

1. Copy `.env.example` to `.env` and set `DEEPSEEK_API_KEY`.
2. Run `docker compose up -d --build` from the repository root.
3. Open `http://127.0.0.1:3080/`.

The published port is bound only to `127.0.0.1`; it is not reachable from the
LAN. Harness sessions, configuration, and credentials persist in the named
`dps-dsh-home` volume. The prior `dsh-data` volume is intentionally neither
mounted nor removed by this deployment.

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
