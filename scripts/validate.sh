#!/usr/bin/env bash
# validate.sh
# Runs ESLint and a build check on both frontend and backend using
# throwaway Node containers, so the host machine doesn't need Node installed.
# Exits 0 if everything passes, non-zero if anything fails.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_IMAGE="node:20-alpine"

echo "=============================================="
echo " Running validation (lint + build check)"
echo "=============================================="

FAILED=0

echo ""
echo "--- [1/4] Backend: npm install + eslint ---"
docker run --rm \
  -v "$ROOT_DIR/backend:/app" -w /app "$NODE_IMAGE" \
  sh -c "npm install --no-audit --no-fund && npm run lint"
if [ $? -ne 0 ]; then
  echo "❌ Backend lint failed"
  FAILED=1
else
  echo "✅ Backend lint passed"
fi

echo ""
echo "--- [2/4] Backend: syntax check ---"
docker run --rm \
  -v "$ROOT_DIR/backend:/app" -w /app "$NODE_IMAGE" \
  sh -c "node --check server.js && for f in \$(find src -name '*.js'); do node --check \"\$f\" || exit 1; done"
if [ $? -ne 0 ]; then
  echo "❌ Backend syntax check failed"
  FAILED=1
else
  echo "✅ Backend syntax check passed"
fi

echo ""
echo "--- [3/4] Frontend: npm install + eslint ---"
docker run --rm \
  -v "$ROOT_DIR/frontend:/app" -w /app "$NODE_IMAGE" \
  sh -c "npm install --no-audit --no-fund && npm run lint"
if [ $? -ne 0 ]; then
  echo "❌ Frontend lint failed"
  FAILED=1
else
  echo "✅ Frontend lint passed"
fi

echo ""
echo "--- [4/4] Frontend: build check ---"
docker run --rm \
  -v "$ROOT_DIR/frontend:/app" -w /app "$NODE_IMAGE" \
  sh -c "npm install --no-audit --no-fund && npm run build"
if [ $? -ne 0 ]; then
  echo "❌ Frontend build failed"
  FAILED=1
else
  echo "✅ Frontend build passed"
fi

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "=============================================="
  echo " ✅ VALIDATION PASSED"
  echo "=============================================="
  exit 0
else
  echo "=============================================="
  echo " ❌ VALIDATION FAILED"
  echo "=============================================="
  exit 1
fi
