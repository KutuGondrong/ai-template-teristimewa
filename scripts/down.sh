#!/usr/bin/env bash
set -euo pipefail
export HUSKY=0
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

redirect_to_cloned_app "$(basename "$0")" "$@"
parse_stack_cmd_args down
load_makefile_stack
APP_ENV="$REQUESTED_ENV"
load_default_config
echo "Stopping docker $LLM_SLUG"
compose_cmd down || true
