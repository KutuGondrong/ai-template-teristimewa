#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/lib.sh"
require_java21
slugs=()
for file in "$@"; do
  relative="${file#"$ROOT"/}"
  slugs+=("$(printf '%s' "$relative" | awk -F/ '{print $3}')")
done
for slug in $(printf '%s\n' "${slugs[@]}" | sort -u); do
  project="$ROOT/backend/spring-boot/$slug"
  (cd "$project" && ./gradlew ktlintFormat ktlintCheck --no-daemon)
  git add "$project"
done
