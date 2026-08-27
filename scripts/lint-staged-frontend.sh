#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
apps=()
for file in "$@"; do
  relative="${file#"$ROOT"/}"
  app="$(printf '%s' "$relative" | awk -F/ '{print $2}')"
  case "$app" in
    nuxt|next|vue|react) apps+=("$app") ;;
  esac
done
for app in $(printf '%s\n' "${apps[@]}" | sort -u); do
  (cd "$ROOT/frontend/$app" && pnpm exec eslint . --fix)
  (cd "$ROOT/frontend/$app" && pnpm run lint)
  git add "$ROOT/frontend/$app"
done
