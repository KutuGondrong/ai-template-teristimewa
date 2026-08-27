#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

redirect_to_cloned_app "$(basename "$0")" "$@"
parse_stack_cmd_args smoke
load_makefile_stack
APP_ENV="$REQUESTED_ENV"
require_real_fe smoke

FE_PORT="$(fe_dev_port "$FE_APP")"

curl -fsS "http://127.0.0.1:8000/api/health" >/dev/null
curl -fsS "http://127.0.0.1:8000/api/ready" >/dev/null
curl -fsS "http://127.0.0.1:$FE_PORT" >/dev/null
curl -fsS "http://127.0.0.1:11434/api/tags" >/dev/null

echo "Smoke check passed for $FE_APP + $LLM_SLUG + $BE_APP env=$APP_ENV${APP_NAME:+ ($APP_NAME)}"
