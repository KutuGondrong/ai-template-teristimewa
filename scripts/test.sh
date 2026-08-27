#!/usr/bin/env bash
set -euo pipefail
export CI="${CI:-true}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/lib.sh"

redirect_to_cloned_app "$(basename "$0")" "$@"
parse_stack_cmd_args test
load_makefile_stack
APP_ENV="$REQUESTED_ENV"
require_real_fe test
check_prereqs tools
if [ "$INPLACE_COMBO" -eq 1 ] || stack_needs_install; then
  install_selected_stack
fi

status=0
echo "Test frontend $FE_APP"
(cd "$(fe_dir)" && pnpm run test) || status=1
if [ "$BE_APP" = "python" ]; then
  echo "Test python $LLM_SLUG"
  (cd "$(be_dir)" && uv run pytest -q) || status=1
elif activate_java21; then
  echo "Test spring $LLM_SLUG"
  (cd "$(be_dir)" && ./gradlew test --no-daemon) || status=1
else
  echo "Skipping Spring tests: JDK 21 is not installed"
  status=1
fi
exit "$status"
