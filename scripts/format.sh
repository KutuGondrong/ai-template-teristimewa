#!/usr/bin/env bash
set -euo pipefail
export CI="${CI:-true}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/lib.sh"
java_ready=0
if activate_java21; then
  java_ready=1
fi
for app in nuxt next vue react; do
  if [ -f "$ROOT/frontend/$app/package.json" ]; then
    echo "Format $app"
    (cd "$ROOT/frontend/$app" && pnpm exec eslint . --fix) || true
  fi
done
for slug in deepseek-r1-1.5b qwen2.5-0.5b qwen2.5-1.5b llama3.2-1b gemma2-2b; do
  if [ -f "$ROOT/backend/python/$slug/pyproject.toml" ]; then
    (cd "$ROOT/backend/python/$slug" && uv run ruff format app worker tests && uv run ruff check --fix app worker tests) || true
  fi
  if [ "$java_ready" -eq 1 ] && [ -x "$ROOT/backend/spring-boot/$slug/gradlew" ]; then
    (cd "$ROOT/backend/spring-boot/$slug" && ./gradlew ktlintFormat --quiet) || true
  fi
done
if [ "$java_ready" -ne 1 ]; then
  echo "Skipping ktlint format: JDK 21 is not installed"
fi
