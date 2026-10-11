# Docker Deployment — Full Stack (with BFF)

Deploys CaudalFlow as two services built from this repository:

| Service | Image | What it does |
|---------|-------|--------------|
| `web`   | `caudalflow-web` | Multi-stage build (node:22 → nginx:1.29). Serves the static frontend and reverse-proxies `/api/*` to the BFF with streaming-friendly settings (`proxy_buffering off`, long timeouts). |
| `bff`   | `caudalflow-bff` | node:22 running `apps/bff/src/server.ts` via `tsx` — the `/api/llm` proxy and `/api/agent` endpoint. |

The LangGraph Python agent (`apps/agent`) is intentionally not included: the
active BFF talks to LLM APIs directly and has no runtime dependency on it.

## Quick start

```bash
cd docker
docker compose up -d --build
```

Open http://localhost:8088 (the port avoids 8080, which OrbStack reserves on
the host). To change it:

```bash
WEB_PORT=9090 docker compose up -d --build
```

## Configuration — `docker/data/`

Server-side configuration lives on the host in `docker/data/` (never inside
the images — the directory is excluded from the build context):

```bash
cp data/bff.env.example data/bff.env
# edit data/bff.env — API keys, AGENT_RUNTIME, …
docker compose up -d   # recreate to pick up env changes
```

- `data/bff.env` is optional — the stack boots without it. Without server-side
  keys, enter an API key in the browser **Settings** panel; it is sent
  per-request and wins over `bff.env`.
- Everything else about a workspace (canvas, chats) is stored in the browser's
  localStorage — there is no server-side database, so `data/` holds config
  only.

## Logs & troubleshooting

```bash
docker compose logs -f web   # nginx access log = ground truth for "did a request reach the BFF"
docker compose logs -f bff
```

- `502` from `/api/*` right after `up`: the BFF is still starting; retry in a
  second.
- Quick routing check without any API key:

  ```bash
  curl -s -X POST http://localhost:8088/api/llm -H 'x-llm-provider: nope'
  # → {"error":"Unknown provider: nope"}  (proves nginx → BFF works)
  ```

## Rebuild after code changes

```bash
docker compose build       # or: docker compose up -d --build
```

## CI — prebuilt images on GHCR

[`.github/workflows/docker.yml`](../.github/workflows/docker.yml) builds both
images on every push to `main` (and build-only validation on PRs) for
`linux/amd64` + `linux/arm64`, publishing to GitHub Container Registry:

- `ghcr.io/<owner>/caudalflow/web:latest`
- `ghcr.io/<owner>/caudalflow/bff:latest`
- plus `sha-<short>` tags for pinning an exact commit

Deploy with the prebuilt images instead of building locally:

```bash
WEB_IMAGE=ghcr.io/<owner>/caudalflow/web:latest \
BFF_IMAGE=ghcr.io/<owner>/caudalflow/bff:latest \
docker compose up -d
```

The GHCR packages are created private on first push — make them public in the
package settings, or `docker login ghcr.io` first to pull them privately.
