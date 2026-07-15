#!/usr/bin/env bash
# auto-pull.sh
# Continuously checks GitHub for new commits and pulls them automatically.
# Combined with Docker's hot reload (Vite/nodemon), any change you commit
# on GitHub will show up in your browser within a few seconds automatically
# — no need to run "git pull" by hand.
#
# Usage: ./auto-pull.sh
# Stop it anytime with Ctrl+C.

set -uo pipefail

INTERVAL=5   # how often to check GitHub, in seconds
BRANCH="main"

echo "🔄 Auto-pull started — checking GitHub every ${INTERVAL}s for changes on '${BRANCH}'."
echo "   Press Ctrl+C to stop."
echo ""

while true; do
  # Fetch latest info from GitHub without merging yet
  git fetch origin "$BRANCH" --quiet

  LOCAL=$(git rev-parse "$BRANCH")
  REMOTE=$(git rev-parse "origin/$BRANCH")

  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "📥 New changes detected on GitHub — pulling now..."
    if git pull origin "$BRANCH"; then
      echo "✅ Pulled successfully. Docker will hot-reload automatically."
    else
      echo "⚠️  Pull failed (likely a conflict). Please resolve manually:"
      echo "   git status"
    fi
    echo ""
  fi

  sleep "$INTERVAL"
done
