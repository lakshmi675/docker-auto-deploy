#!/usr/bin/env bash
# auto-pull.sh
# Continuously checks GitHub for new commits and pulls them automatically.

set -uo pipefail

INTERVAL=5
BRANCH="main"

echo "🔄 Auto-pull started — checking GitHub every ${INTERVAL}s for changes on '${BRANCH}'."
echo "   Press Ctrl+C to stop."
echo ""

while true; do
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
