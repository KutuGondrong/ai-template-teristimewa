#!/usr/bin/env bash
set -euo pipefail
export HUSKY=0
export CI="${CI:-true}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

if [ -d "$ROOT/.git" ]; then
  git -C "$ROOT" config core.hooksPath .husky
fi

check_prereqs tools

echo "Installing frontends"
for app in nuxt next vue react; do
  if [ -f "$ROOT/frontend/$app/package.json" ]; then
    echo "pnpm install $app"
    (cd "$ROOT/frontend/$app" && pnpm install)
  fi
done

echo "Syncing python backends"
for slug in deepseek-r1-1.5b qwen2.5-0.5b qwen2.5-1.5b llama3.2-1b gemma2-2b; do
  if [ -f "$ROOT/backend/python/$slug/pyproject.toml" ]; then
    echo "uv sync $slug"
    (cd "$ROOT/backend/python/$slug" && uv sync --group dev)
  fi
done

echo "Install done"
