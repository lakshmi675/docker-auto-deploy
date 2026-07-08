#!/usr/bin/env bash
# watch.sh
# Watches frontend/ and backend/ source for changes and automatically
# triggers deploy.sh on every save — this is the "Auto Deploy" trigger.
# Requires `nodemon` on the host (npm install -g nodemon) since it's
# already a project dependency.
#
# Usage: ./scripts/watch.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "👀 Watching frontend/src and backend/src for changes..."
echo "   Every save will run: validate -> deploy -> (rollback if unhealthy)"

npx --yes nodemon \
  --watch frontend/src \
  --watch backend/src \
  --watch backend/server.js \
  --ext js,jsx,json \
  --delay 1 \
  --exec "$ROOT_DIR/scripts/deploy.sh"
