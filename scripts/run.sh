#!/usr/bin/env bash
set -euo pipefail
export HUSKY=0
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

redirect_to_cloned_app "$(basename "$0")" "$@"
parse_stack_cmd_args run
load_makefile_stack
APP_ENV="$REQUESTED_ENV"
check_prereqs
load_default_config
if [ "$INPLACE_COMBO" -eq 1 ] || stack_needs_install; then
  install_selected_stack
fi
ensure_service_envs
load_service_envs
export APP_ENV
"$ROOT/scripts/docker-up.sh"

BE_PATH="$(be_dir)"
FE_PATH=""
if has_frontend; then
  FE_PATH="$(fe_dir)"
fi
CHILD_PIDS=()
BE_PID=""
FE_PID=""
cleanup() {
  trap - EXIT INT TERM
  local started_be=0
  [ -n "${BE_PID:-}" ] && started_be=1
  if [ "${#CHILD_PIDS[@]}" -gt 0 ]; then
    stop_child_pids "${CHILD_PIDS[@]}"
  fi
  if [ "$started_be" -eq 1 ]; then
    free_listen_port 8000
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

if port_in_use 8000; then
  fail "Port 8000 already in use. Stop the other backend or run make down."
fi
if has_frontend && port_in_use "$(fe_dev_port "$FE_APP")"; then
  fail "Port $(fe_dev_port "$FE_APP") already in use. Stop the other frontend."
fi

echo "Starting backend $BE_APP ($LLM_SLUG) env=$APP_ENV"
if [ "$BE_APP" = "python" ]; then
  (
    cd "$BE_PATH"
    exec env APP_ENV="$APP_ENV" uv run ai-api
  ) &
else
  require_java21
  (
    cd "$BE_PATH"
    exec env SPRING_PROFILES_ACTIVE="$APP_ENV" ./gradlew bootRun --no-daemon
  ) &
fi
BE_PID="$!"
CHILD_PIDS+=("$BE_PID")

echo "Waiting for http://127.0.0.1:8000/api/ready"
ready=0
for _ in $(seq 1 90); do
  if ! kill -0 "$BE_PID" 2>/dev/null; then
    fail "Backend ($BE_APP) exited before it was ready. Scroll up for the error."
  fi
  if curl -sf "http://127.0.0.1:8000/api/ready" >/dev/null 2>&1; then
    ready=1
    echo "Backend ready"
    break
  fi
  sleep 2
done
if [ "$ready" -ne 1 ]; then
  fail "Backend ($BE_APP) did not become ready at http://127.0.0.1:8000/api/ready"
fi

if ! has_frontend; then
  echo
  echo "OK  fe=no-fe  llm=$LLM_SLUG  be=$BE_APP  env=$APP_ENV"
  if [ "$APP_ENV" = "prod" ]; then
    echo "API  http://localhost:8000/api/health"
  else
    echo "API  http://localhost:8000/docs"
  fi
  echo "Start a frontend in another terminal:"
  echo "  make run-fe nuxt|next|vue|react"
  echo

  while kill -0 "$BE_PID" 2>/dev/null; do
    sleep 2
  done
  fail "Backend ($BE_APP) stopped. Scroll up for the error."
fi

FE_PORT="$(fe_dev_port "$FE_APP")"
verify_backend_cors_for_fe "$FE_APP"

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
  if ! kill -0 "$BE_PID" 2>/dev/null; then
    fail "Backend ($BE_APP) stopped while the frontend was starting. Scroll up for the error."
  fi
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
if [ "$APP_ENV" = "prod" ]; then
  echo "API  http://127.0.0.1:8000/api/health"
else
  echo "API  http://127.0.0.1:8000/docs"
fi
echo

while kill -0 "$BE_PID" 2>/dev/null && kill -0 "$FE_PID" 2>/dev/null; do
  sleep 2
done
if ! kill -0 "$BE_PID" 2>/dev/null; then
  fail "Backend ($BE_APP) stopped. Scroll up for the error."
fi
fail "Frontend ($FE_APP) stopped. Scroll up for the error."
