#!/usr/bin/env bash
set -euo pipefail
export HUSKY=0
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

if [ "$#" -ge 1 ] && in_list "$1" "$FE_APPS"; then
  FE_CHOICE="$1"
  if [ "$#" -ne 1 ]; then
    usage_run_fe
    exit 1
  fi
elif [ "$#" -ge 1 ]; then
  if in_list "$1" "$APP_ENVS"; then
    echo "run-fe does not take an env. Start the backend with make run <env> no-fe ..., then:"
    usage_run_fe
    exit 1
  fi
  redirect_to_cloned_app "$(basename "$0")" "$@"
  FE_CHOICE=""
else
  FE_CHOICE=""
fi

load_makefile_stack
if [ -z "${LLM_SLUG:-}" ] || [ -z "${BE_APP:-}" ]; then
  echo "No stack in Makefile. Start the backend first:"
  echo "  make run $DEFAULT_ENV no-fe $DEFAULT_LLM $DEFAULT_BE"
  usage_run_fe
  exit 1
fi

if [ -n "$FE_CHOICE" ]; then
  FE_APP="$FE_CHOICE"
elif ! has_frontend; then
  picked="$(only_frontend_in_tree || true)"
  if [ -z "$picked" ]; then
    usage_run_fe
    exit 1
  fi
  FE_APP="$picked"
  echo "Using the only frontend in this folder: $FE_APP"
fi

APP_ENV="${APP_ENV:-$DEFAULT_ENV}"
check_prereqs tools
rewrite_selected_frontend_llm
rewrite_root_for_combo
assert_cloned_dirs
if frontend_needs_install; then
  install_selected_frontend
fi
ensure_service_envs
load_service_envs
export APP_ENV

FE_PATH="$(fe_dir)"
CHILD_PIDS=()
FE_PID=""
cleanup() {
  trap - EXIT INT TERM
  if [ "${#CHILD_PIDS[@]}" -gt 0 ]; then
    stop_child_pids "${CHILD_PIDS[@]}"
  fi
  if [ -n "${FE_PORT:-}" ]; then
    free_listen_port "$FE_PORT"
  fi
  if [ "${#CHILD_PIDS[@]}" -gt 0 ]; then
    reap_child_pids "${CHILD_PIDS[@]}"
  fi
}
trap cleanup EXIT INT TERM

fail() {
  echo
  echo "FAILED: $1"
  echo "Stack: env=$APP_ENV  fe=$FE_APP  llm=$LLM_SLUG  be=$BE_APP"
  exit 1
}

require_backend_ready

FE_PORT="$(fe_dev_port "$FE_APP")"
verify_backend_cors_for_fe "$FE_APP"

if port_in_use "$FE_PORT"; then
  fail "Port $FE_PORT already in use. Stop the other frontend (Ctrl+C on make run-fe)."
fi

echo "Starting frontend $FE_APP env=$APP_ENV (http://127.0.0.1:$FE_PORT)"
export_frontend_api_urls
(
  cd "$FE_PATH"
  exec pnpm run dev
) &
FE_PID="$!"
CHILD_PIDS+=("$FE_PID")

echo "Waiting for http://127.0.0.1:$FE_PORT"
fe_ready=0
for _ in $(seq 1 90); do
  if ! kill -0 "$FE_PID" 2>/dev/null; then
    fail "Frontend ($FE_APP) exited before it was ready. Scroll up for the error."
  fi
  if curl -s -o /dev/null --connect-timeout 1 "http://127.0.0.1:$FE_PORT" >/dev/null 2>&1; then
    fe_ready=1
    echo "Frontend ready"
    break
  fi
  sleep 2
done
if [ "$fe_ready" -ne 1 ]; then
  fail "Frontend ($FE_APP) did not become ready at http://127.0.0.1:$FE_PORT"
fi

echo
echo "OK  fe=$FE_APP  llm=$LLM_SLUG  be=$BE_APP  env=$APP_ENV"
echo "UI   http://127.0.0.1:$FE_PORT"
echo "Ctrl+C stops this frontend only. Backend stays up."
echo

while kill -0 "$FE_PID" 2>/dev/null; do
  sleep 2
  if ! curl -sf "http://127.0.0.1:8000/api/ready" >/dev/null 2>&1; then
    fail "Backend stopped. Keep make run … no-fe going in the other terminal."
  fi
done
fail "Frontend ($FE_APP) stopped. Scroll up for the error."
