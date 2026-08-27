#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

redirect_to_cloned_app "$(basename "$0")" "$@"
parse_stack_cmd_args test-e2e
load_makefile_stack
APP_ENV="$REQUESTED_ENV"
require_real_fe test-e2e
check_prereqs tools
load_default_config
echo "E2E for $FE_APP env=$APP_ENV (stack must already be up: make run … no-fe + make run-fe)"
(cd "$ROOT/frontend/$FE_APP" && pnpm run test:e2e)
