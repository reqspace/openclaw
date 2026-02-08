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

# Create data directories for Railway/cloud deployment
RUN mkdir -p /data/.openclaw /app/.openclaw

# Bake config into image at a path no volume mount can overwrite
COPY openclaw-cloud-config.json /app/openclaw-cloud-config.json
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app /data/.openclaw

# Security hardening: Run as non-root user
USER node

# Default state dir for cloud deployments
ENV OPENCLAW_STATE_DIR=/app/.openclaw
# Force config path — highest priority, bypasses all other config discovery
ENV OPENCLAW_CONFIG_PATH=/app/openclaw-cloud-config.json

# Entrypoint copies config to state dir, then runs CMD
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]
