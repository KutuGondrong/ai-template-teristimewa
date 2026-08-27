#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
slugs=()
for file in "$@"; do
  relative="${file#"$ROOT"/}"
  slugs+=("$(printf '%s' "$relative" | awk -F/ '{print $3}')")
done
for slug in $(printf '%s\n' "${slugs[@]}" | sort -u); do
  project="$ROOT/backend/python/$slug"
  (cd "$project" && uv run ruff format app worker tests)
  (cd "$project" && uv run ruff check --fix app worker tests)
  (cd "$project" && uv run ruff check app worker tests)
  git add "$project"
done
