FROM node:22-bookworm

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Create data directories and gateway config for Railway/cloud deployment
RUN mkdir -p /data/.openclaw /app/.openclaw && \
    printf 'gateway:\n  trustedProxies:\n    - "100.64.0.0/10"\n    - "10.0.0.0/8"\n    - "172.16.0.0/12"\n    - "192.168.0.0/16"\n' > /app/.openclaw/config.yaml

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app /data/.openclaw

# Security hardening: Run as non-root user
USER node

# Default state dir for cloud deployments
ENV OPENCLAW_STATE_DIR=/app/.openclaw

# Start gateway server bound to LAN for container platforms.
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]
