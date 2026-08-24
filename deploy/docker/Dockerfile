# syntax=docker/dockerfile:1.7

FROM node:24-bookworm-slim AS build

ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /opt/dps

RUN corepack enable \
  && corepack prepare pnpm@11.7.0 --activate

COPY . .

RUN --mount=type=cache,id=dps-pnpm-store,target=/pnpm/store \
  pnpm install --frozen-lockfile

# This produces Host artifacts first, then generated Client/Typert contracts,
# then the Vite Web UI. It is deliberately not replaced by a Vite-only build.
RUN pnpm run build

FROM node:24-bookworm-slim AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    openssh-client \
    python3 \
    ripgrep \
    tini \
  && rm -rf /var/lib/apt/lists/*

ENV DSH_HOME=/home/node/.dsh
ENV HOME=/workspace
ENV NODE_ENV=production

WORKDIR /opt/dps
COPY --from=build --chown=node:node /opt/dps /opt/dps
COPY --chmod=755 deploy/docker/entrypoint.sh /usr/local/bin/dps-entrypoint

WORKDIR /workspace
USER node

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dps-entrypoint"]
CMD ["web", "--patch", "/opt/dps/deploy/docker/web.cordis.patch.yml", "--no-open", "--port", "3080"]
