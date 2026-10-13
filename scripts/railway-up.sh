#!/usr/bin/env bash
# KK Online — source Railway env and deploy current (or given) directory
# Usage: bash railway-up.sh [/path/to/deploy-dir]
# Hard rule: confirm you are linked to the CORRECT project before running
# (do not overwrite another product morph — see SKILL.md §19).
set -euo pipefail

DIR="${1:-.}"
cd "$DIR"

source "$HOME/.railway/env" 2>/dev/null || true
export PATH="$HOME/.railway/bin:$PATH"

if ! command -v railway >/dev/null 2>&1; then
  echo "railway CLI not found in PATH" >&2
  exit 127
fi

echo "cwd: $(pwd)"
railway whoami || { echo "Not logged in — run: railway login" >&2; exit 1; }
echo "status:"
railway status || true
echo "Deploying with: railway up -y --detach"
railway up -y --detach
echo "Done. Watch Dashboard / railway logs; then smoke-http.sh <url>"
