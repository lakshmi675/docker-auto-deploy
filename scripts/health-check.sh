#!/usr/bin/env bash
# health-check.sh
# Polls the backend /api/health endpoint until it responds healthy,
# or until the retry budget runs out. Used by deploy.sh and rollback.sh.
#
# Usage: ./health-check.sh [url] [max_attempts] [delay_seconds]

set -uo pipefail

URL="${1:-http://localhost:${BACKEND_PORT:-5000}/api/health}"
MAX_ATTEMPTS="${2:-10}"
DELAY="${3:-3}"

echo "Health-checking $URL (up to $MAX_ATTEMPTS attempts, ${DELAY}s apart)..."

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -fs "$URL" > /dev/null 2>&1; then
    echo "✅ Healthy after attempt $attempt"
    exit 0
  fi
  echo "  attempt $attempt/$MAX_ATTEMPTS: not healthy yet, retrying in ${DELAY}s..."
  sleep "$DELAY"
done

echo "❌ Health check failed after $MAX_ATTEMPTS attempts"
exit 1
