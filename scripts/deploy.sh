#!/usr/bin/env bash
# deploy.sh
# The main auto-deploy entrypoint.
#
# Flow:
#   1. Run validate.sh (lint + build check) for frontend & backend.
#      -> If validation fails, deployment is BLOCKED and the currently
#         running containers are left completely untouched.
#   2. If validation passes, snapshot the currently running images as
#      "previous" so we can roll back to them if needed.
#   3. Build fresh images and start them with docker compose.
#   4. Health-check the new backend/frontend.
#      -> If healthy, deployment succeeds.
#      -> If unhealthy, automatically roll back to the previous images.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
set -a; source .env 2>/dev/null; set +a

BACKEND_IMAGE="docker-auto-deploy-backend"
FRONTEND_IMAGE="docker-auto-deploy-frontend"
TAG="${TAG:-current}"

echo ""
echo "################################################"
echo "# STEP 1: VALIDATION"
echo "################################################"
if ! "$ROOT_DIR/scripts/validate.sh"; then
  echo ""
  echo "🚫 Deployment BLOCKED — validation failed."
  echo "   The previously running containers are untouched and keep serving traffic."
  exit 1
fi

echo ""
echo "################################################"
echo "# STEP 2: SNAPSHOT CURRENT IMAGES AS 'previous'"
echo "################################################"
if docker image inspect "${BACKEND_IMAGE}:${TAG}" > /dev/null 2>&1; then
  docker tag "${BACKEND_IMAGE}:${TAG}" "${BACKEND_IMAGE}:previous"
  echo "Snapshotted ${BACKEND_IMAGE}:${TAG} -> ${BACKEND_IMAGE}:previous"
else
  echo "No existing ${BACKEND_IMAGE}:${TAG} image yet (first deploy)."
fi

if docker image inspect "${FRONTEND_IMAGE}:${TAG}" > /dev/null 2>&1; then
  docker tag "${FRONTEND_IMAGE}:${TAG}" "${FRONTEND_IMAGE}:previous"
  echo "Snapshotted ${FRONTEND_IMAGE}:${TAG} -> ${FRONTEND_IMAGE}:previous"
else
  echo "No existing ${FRONTEND_IMAGE}:${TAG} image yet (first deploy)."
fi

echo ""
echo "################################################"
echo "# STEP 3: BUILD & START NEW VERSION"
echo "################################################"
docker compose build
if [ $? -ne 0 ]; then
  echo "❌ Docker build failed unexpectedly after validation passed."
  echo "   Leaving previously running containers in place."
  exit 1
fi

docker compose up -d

echo ""
echo "################################################"
echo "# STEP 4: HEALTH CHECK NEW VERSION"
echo "################################################"
if "$ROOT_DIR/scripts/health-check.sh" "http://localhost:${BACKEND_PORT:-5000}/api/health" 10 3; then
  echo ""
  echo "✅✅✅ DEPLOYMENT SUCCESSFUL — new version is live and healthy."
  exit 0
else
  echo ""
  echo "⚠️  New version failed its health check. Rolling back automatically..."
  "$ROOT_DIR/scripts/rollback.sh"
  exit 1
fi
