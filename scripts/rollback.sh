#!/usr/bin/env bash
# rollback.sh
# Restores the last known-good ("previous") images and restarts the stack
# with them. Can be run automatically by deploy.sh after a failed health
# check, or manually at any time: ./scripts/rollback.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
set -a; source .env 2>/dev/null; set +a

BACKEND_IMAGE="docker-auto-deploy-backend"
FRONTEND_IMAGE="docker-auto-deploy-frontend"
TAG="${TAG:-current}"

echo "################################################"
echo "# ROLLING BACK TO PREVIOUS VERSION"
echo "################################################"

ROLLBACK_POSSIBLE=1

if docker image inspect "${BACKEND_IMAGE}:previous" > /dev/null 2>&1; then
  docker tag "${BACKEND_IMAGE}:previous" "${BACKEND_IMAGE}:${TAG}"
  echo "Restored ${BACKEND_IMAGE}:${TAG} from previous image."
else
  echo "⚠️  No ${BACKEND_IMAGE}:previous image found — cannot roll back backend."
  ROLLBACK_POSSIBLE=0
fi

if docker image inspect "${FRONTEND_IMAGE}:previous" > /dev/null 2>&1; then
  docker tag "${FRONTEND_IMAGE}:previous" "${FRONTEND_IMAGE}:${TAG}"
  echo "Restored ${FRONTEND_IMAGE}:${TAG} from previous image."
else
  echo "⚠️  No ${FRONTEND_IMAGE}:previous image found — cannot roll back frontend."
  ROLLBACK_POSSIBLE=0
fi

if [ "$ROLLBACK_POSSIBLE" -eq 0 ]; then
  echo "❌ Rollback incomplete: no previous version was recorded yet."
  echo "   This usually only happens on the very first deploy."
  exit 1
fi

docker compose up -d --force-recreate backend frontend

if "$ROOT_DIR/scripts/health-check.sh" "http://localhost:${BACKEND_PORT:-5000}/api/health" 10 3; then
  echo "✅ Rollback successful — previous version is running and healthy again."
  exit 0
else
  echo "❌ Rollback deployed, but health check still fails. Manual investigation needed."
  exit 1
fi
