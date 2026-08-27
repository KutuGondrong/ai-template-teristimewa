#!/usr/bin/env bash
set -euo pipefail
export CI="${CI:-true}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/lib.sh"

for app in nuxt next vue react; do
  if [ -f "$ROOT/frontend/$app/package.json" ]; then
    echo "Build $app"
    (cd "$ROOT/frontend/$app" && pnpm run build)
  fi
done

if activate_java21; then
  for slug in deepseek-r1-1.5b qwen2.5-0.5b qwen2.5-1.5b llama3.2-1b gemma2-2b; do
    if [ -x "$ROOT/backend/spring-boot/$slug/gradlew" ]; then
      echo "Build spring $slug"
      (cd "$ROOT/backend/spring-boot/$slug" && ./gradlew bootJar --no-daemon)
    fi
  done
else
  echo "Skipping Spring build: JDK 21 is not installed"
fi
