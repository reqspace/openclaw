#!/bin/sh
# Reset config from read-only source on every container start.
# The Control UI can modify $OPENCLAW_STATE_DIR/openclaw.json at runtime,
# but /etc/openclaw/clean-config.json is root-owned and read-only.
# This ensures the gateway always starts with a known-good config.

mkdir -p "$OPENCLAW_STATE_DIR" 2>/dev/null || true
cp /etc/openclaw/clean-config.json "$OPENCLAW_STATE_DIR/openclaw.json"

exec "$@"
