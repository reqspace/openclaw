#!/bin/sh
# Ensure state dir exists (volume mount may create empty dir)
mkdir -p "$OPENCLAW_STATE_DIR" 2>/dev/null || true

# Copy immutable config into state dir so gateway can find it
# OPENCLAW_CONFIG_PATH points here — highest priority, can't be overridden
cp /app/openclaw-cloud-config.json "$OPENCLAW_STATE_DIR/openclaw.json" 2>/dev/null || true

exec "$@"
