FROM node:22-bookworm AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        build-essential \
        python3 \
        cmake \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .

ENV OPENCLAW_A2UI_SKIP_MISSING=1
RUN pnpm build

# Ensure optional dirs exist for multi-stage copy even if missing from repo
RUN mkdir -p /app/assets /app/extensions /app/skills /app/docs

ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install
RUN pnpm ui:build

RUN CI=true pnpm prune --prod

FROM node:22-bookworm-slim AS runner

ENV NODE_ENV=production
ENV OPENCLAW_PREFER_PNPM=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/openclaw.mjs /app/openclaw.mjs
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/assets /app/assets
COPY --from=builder /app/extensions /app/extensions
COPY --from=builder /app/skills /app/skills
COPY --from=builder /app/docs /app/docs
COPY --from=builder /app/node_modules /app/node_modules

RUN mkdir -p /home/node/.openclaw/sessions \
    && chown -R node:node /home/node/.openclaw /app

USER node

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:18789/health || exit 1

CMD ["node", "openclaw.mjs", "gateway", "--port", "18789", "--verbose"]
