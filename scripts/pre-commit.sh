#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fe_files=()
py_files=()
kt_files=()

while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  if [[ "$rel" == frontend/* ]]; then
    case "${rel##*.}" in
      js|ts|tsx|vue) fe_files+=("$ROOT/$rel") ;;
    esac
  elif [[ "$rel" == backend/python/* && "$rel" == *.py ]]; then
    py_files+=("$ROOT/$rel")
  elif [[ "$rel" == backend/spring-boot/* && "$rel" == *.kt ]]; then
    kt_files+=("$ROOT/$rel")
  fi
done < <(git -C "$ROOT" diff --cached --name-only --diff-filter=ACMR)

if [ "${#fe_files[@]}" -gt 0 ]; then
  "$ROOT/scripts/lint-staged-frontend.sh" "${fe_files[@]}"
fi
if [ "${#py_files[@]}" -gt 0 ]; then
  "$ROOT/scripts/lint-staged-python.sh" "${py_files[@]}"
fi
if [ "${#kt_files[@]}" -gt 0 ]; then
  "$ROOT/scripts/lint-staged-spring.sh" "${kt_files[@]}"
fi
