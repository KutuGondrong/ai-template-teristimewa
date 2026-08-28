#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export HUSKY=0
export PYTHONDONTWRITEBYTECODE=1
unset UV_PYTHON_INSTALL_DIR

APP_ENVS="local dev prod"
FE_APPS="nuxt next vue react"
FE_NONE="no-fe"
BE_APPS="python spring"
LLM_SLUGS="deepseek-r1-1.5b qwen2.5-0.5b qwen2.5-1.5b llama3.2-1b gemma2-2b"
DEFAULT_ENV="local"
DEFAULT_FE="nuxt"
DEFAULT_LLM="deepseek-r1-1.5b"
DEFAULT_BE="python"
NEED_NODE="22.23.1"
NEED_PNPM="11.17.0"
NEED_PYTHON="3.12"
NEED_JAVA="21"

usage_clone() {
  echo "Usage: make clone <fe> <llm-slug> <python|spring> <app-name>"
  echo "Creates a new app folder next to this template: ../<app-name>"
  echo "FE: $FE_APPS"
  echo "LLM: $LLM_SLUGS"
  echo "BE: $BE_APPS"
  echo "App name: start with a letter; letters, numbers, hyphen, underscore."
}

usage_stack_cmd() {
  local cmd="$1"
  echo "Usage: make ${cmd}"
  echo "       default: $DEFAULT_ENV + $DEFAULT_FE + $DEFAULT_LLM + $DEFAULT_BE"
  echo "   or: make ${cmd} <local|dev|prod> <fe|no-fe> <llm-slug> <python|spring>"
  echo "After make clone, cd into the sibling folder, then:"
  echo "       make ${cmd}"
  echo "       make ${cmd} <local|dev|prod>"
  echo "FE: $FE_APPS"
  echo "     $FE_NONE = docker + backend only; then make run-fe <fe>"
  echo "LLM: $LLM_SLUGS"
  echo "BE: $BE_APPS"
  echo "ENV: $APP_ENVS"
}

usage_run_fe() {
  echo "Usage: make run-fe <nuxt|next|vue|react>"
  echo "       make run-fe              (uses FE from Makefile, or the only FE in this folder)"
  echo "Backend must already be up:"
  echo "       make run <local|dev|prod> no-fe <llm-slug> <python|spring>"
  echo "FE: $FE_APPS"
}

usage_run() {
  usage_stack_cmd run
}

usage_app_cmd() {
  usage_stack_cmd "$1"
}

in_list() {
  local needle="$1"
  local list="$2"
  for item in $list; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

has_frontend() {
  [ -n "${FE_APP:-}" ] && [ "$FE_APP" != "$FE_NONE" ]
}

is_run_fe_token() {
  [ "$1" = "$FE_NONE" ] || in_list "$1" "$FE_APPS"
}

load_env_file() {
  local file="$1" line key value first last
  if [ ! -f "$file" ]; then
    return 0
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      '' | '#'*) continue ;;
    esac
    case "$line" in
      *=*) ;;
      *) continue ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    case "$key" in
      export)
        key="${value%%=*}"
        value="${value#*=}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        ;;
    esac
    case "$key" in
      '' | '#'* | *[!A-Za-z0-9_]*) continue ;;
    esac
    if [ "${#value}" -ge 2 ]; then
      first="${value%"${value#?}"}"
      last="${value#"${value%?}"}"
      if [ "$first" = "$last" ] && { [ "$first" = "'" ] || [ "$first" = '"' ]; }; then
        value="${value#?}"
        value="${value%?}"
      fi
    fi
    export "$key=$value"
  done < "$file"
}

rewrite_selected_frontend_llm() {
  local source dest
  if ! has_frontend; then
    return 0
  fi
  source="$ROOT/frontend/${FE_APP}/llm/${LLM_SLUG}.json"
  dest="$ROOT/frontend/${FE_APP}/public/llm.active.json"
  if [ ! -f "$source" ]; then
    echo "Missing LLM config: ${source#"$ROOT"/}"
    usage_clone
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$source" "$dest"
  echo "Wrote ${dest#"$ROOT"/}"
}

load_docker_model() {
  local model_file="$ROOT/docker/${LLM_SLUG}/ollama.model"
  if [ ! -f "$model_file" ]; then
    echo "Missing Docker model file: ${model_file#"$ROOT"/}"
    exit 1
  fi
  OLLAMA_MODEL="$(tr -d '[:space:]' < "$model_file")"
  if [ -z "$OLLAMA_MODEL" ]; then
    echo "Empty Docker model file: ${model_file#"$ROOT"/}"
    exit 1
  fi
}

replace_active_stack_block() {
  local file="$1"
  local body="$2"
  python3 - "$file" "$body" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
body = sys.argv[2].rstrip() + "\n"
text = path.read_text(encoding="utf-8")
start = "# BEGIN ACTIVE_STACK"
end = "# END ACTIVE_STACK"
if start not in text or end not in text:
    raise SystemExit(f"Missing {start} / {end} in {path}")
before, rest = text.split(start, 1)
_, after = rest.split(end, 1)
path.write_text(f"{before}{start}\n{body}{end}{after}", encoding="utf-8")
PY
}

rewrite_root_for_combo() {
  local makefile_body
  makefile_body=$(
    printf 'APP_ENV := %s\nAPP_NAME := %s\nFE_APP := %s\nLLM_SLUG := %s\nBE_APP := %s\n' \
      "${APP_ENV:-local}" "${APP_NAME:-}" "$FE_APP" "$LLM_SLUG" "$BE_APP"
  )
  replace_active_stack_block "$ROOT/Makefile" "$makefile_body"
  echo "Updated Makefile for ${APP_NAME:-app} (${APP_ENV:-local} + $FE_APP + $LLM_SLUG + $BE_APP)"
}

install_selected_frontend() {
  if ! has_frontend; then
    return 0
  fi
  echo "Installing frontend $FE_APP"
  (cd "$(fe_dir)" && pnpm install)
}

install_selected_stack() {
  install_selected_frontend
  if [ "$BE_APP" = "python" ]; then
    echo "Syncing python $LLM_SLUG"
    (cd "$(be_dir)" && uv sync --group dev)
  fi
}

apply_combo() {
  local fe="$1"
  local slug="$2"
  local be="$3"
  FE_APP="$fe"
  BE_APP="$be"
  LLM_SLUG="$slug"
  rewrite_selected_frontend_llm
  rewrite_root_for_combo
  load_docker_model
}

load_makefile_stack() {
  eval "$(
    awk '
      /^APP_ENV := / { printf "APP_ENV=%s\n", $3 }
      /^APP_NAME := / { printf "APP_NAME=%s\n", $3 }
      /^FE_APP := / { printf "FE_APP=%s\n", $3 }
      /^LLM_SLUG := / { printf "LLM_SLUG=%s\n", $3 }
      /^BE_APP := / { printf "BE_APP=%s\n", $3 }
    ' "$ROOT/Makefile"
  )"
}

load_default_config() {
  local requested="${APP_ENV:-}"
  load_makefile_stack
  if [ -z "${FE_APP:-}" ] || [ -z "${LLM_SLUG:-}" ] || [ -z "${BE_APP:-}" ]; then
    echo "No active stack in Makefile."
    echo "From this template: make run"
    echo "Default: $DEFAULT_ENV + $DEFAULT_FE + $DEFAULT_LLM + $DEFAULT_BE"
    echo "After make clone: cd ../<app-name> && make run"
    exit 1
  fi
  if [ -n "$requested" ]; then
    APP_ENV="$requested"
  else
    APP_ENV="${APP_ENV:-local}"
  fi
  assert_cloned_dirs
  rewrite_selected_frontend_llm
  load_docker_model
}

validate_env() {
  local env="$1"
  if ! in_list "$env" "$APP_ENVS"; then
    echo "Unknown env: $env"
    usage_stack_cmd "${STACK_CMD:-run}"
    exit 1
  fi
}

has_active_stack() {
  grep -q '^FE_APP := .\+' "$ROOT/Makefile"
}

validate_combo() {
  local fe="$1"
  local slug="$2"
  local be="$3"
  if [ "$#" -ne 3 ]; then
    usage_clone
    exit 1
  fi
  if ! in_list "$fe" "$FE_APPS"; then
    echo "Unknown FE: $fe"
    usage_clone
    exit 1
  fi
  if ! in_list "$slug" "$LLM_SLUGS"; then
    echo "Unknown LLM slug: $slug"
    usage_clone
    exit 1
  fi
  if ! in_list "$be" "$BE_APPS"; then
    echo "Unknown BE: $be"
    usage_clone
    exit 1
  fi
}

validate_run_combo() {
  local fe="$1"
  local slug="$2"
  local be="$3"
  if [ "$fe" = "$FE_NONE" ]; then
    if ! in_list "$slug" "$LLM_SLUGS"; then
      echo "Unknown LLM slug: $slug"
      usage_stack_cmd "${STACK_CMD:-run}"
      exit 1
    fi
    if ! in_list "$be" "$BE_APPS"; then
      echo "Unknown BE: $be"
      usage_stack_cmd "${STACK_CMD:-run}"
      exit 1
    fi
    return 0
  fi
  validate_combo "$fe" "$slug" "$be"
}

validate_app_name() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "Missing app name."
    usage_clone
    exit 1
  fi
  if in_list "$name" "$APP_ENVS"; then
    echo "App name cannot be an env name: $name"
    exit 1
  fi
  if [ "$name" = "$FE_NONE" ]; then
    echo "no-fe is not an app name. Env comes first:"
    echo "  make run local no-fe <llm-slug> <python|spring>"
    exit 1
  fi
  if [[ "$name" == *"/"* ]] || [[ "$name" == *"\\"* ]]; then
    echo "App name cannot contain a path: $name"
    usage_clone
    exit 1
  fi
  if [[ ! "$name" =~ ^[A-Za-z][A-Za-z0-9_-]{0,62}$ ]]; then
    echo "Invalid app name: $name"
    echo "Use a folder name that starts with a letter and uses only letters, numbers, hyphen, or underscore."
    usage_clone
    exit 1
  fi
}

app_dest_dir() {
  local name="$1"
  echo "$(cd "$ROOT/.." && pwd)/$name"
}

APP_TARGET_ARGS=()
INPLACE_COMBO=0
COMBO_ENV=""
STACK_CMD=""
REQUESTED_ENV=""

looks_like_combo() {
  [ "$#" -ge 3 ] || return 1
  in_list "$1" "$FE_APPS" && in_list "$2" "$LLM_SLUGS" && in_list "$3" "$BE_APPS"
}

looks_like_run_combo() {
  [ "$#" -ge 4 ] || return 1
  in_list "$1" "$APP_ENVS" && is_run_fe_token "$2" && in_list "$3" "$LLM_SLUGS" && in_list "$4" "$BE_APPS"
}

redirect_to_cloned_app() {
  local script="$1"
  local cmd="${script%.sh}"
  shift
  APP_TARGET_ARGS=("$@")
  if [ "${#APP_TARGET_ARGS[@]}" -eq 0 ]; then
    return 0
  fi
  if looks_like_run_combo "${APP_TARGET_ARGS[@]}" || looks_like_combo "${APP_TARGET_ARGS[@]}"; then
    return 0
  fi
  local maybe="${APP_TARGET_ARGS[0]}"
  if in_list "$maybe" "$APP_ENVS"; then
    return 0
  fi
  validate_app_name "$maybe"
  local dest rest=""
  dest="$(app_dest_dir "$maybe")"
  if [ "${#APP_TARGET_ARGS[@]}" -gt 1 ]; then
    rest="${APP_TARGET_ARGS[*]:1}"
  fi
  if [ "$dest" = "$ROOT" ]; then
    if [ "${#APP_TARGET_ARGS[@]}" -gt 1 ]; then
      APP_TARGET_ARGS=("${APP_TARGET_ARGS[@]:1}")
    else
      APP_TARGET_ARGS=()
    fi
    return 0
  fi
  echo "$maybe sits next to this template, not inside it."
  if [ ! -f "$dest/scripts/$script" ]; then
    echo "No cloned app at $dest"
    echo "Clone first: make clone <fe> <llm-slug> <python|spring> $maybe"
  fi
  echo "Then:"
  echo "  cd $dest"
  if [ -n "$rest" ]; then
    echo "  make $cmd $rest"
  else
    echo "  make $cmd"
  fi
  exit 1
}

take_run_combo_args() {
  local cmd="${1:-run}"
  INPLACE_COMBO=0
  COMBO_ENV=""
  if [ "${#APP_TARGET_ARGS[@]}" -lt 3 ]; then
    return 0
  fi
  if [ "${#APP_TARGET_ARGS[@]}" -ge 4 ] && looks_like_run_combo "${APP_TARGET_ARGS[@]}"; then
    COMBO_ENV="${APP_TARGET_ARGS[0]}"
    validate_run_combo "${APP_TARGET_ARGS[1]}" "${APP_TARGET_ARGS[2]}" "${APP_TARGET_ARGS[3]}"
    APP_NAME=""
    APP_ENV="$COMBO_ENV"
    apply_combo "${APP_TARGET_ARGS[1]}" "${APP_TARGET_ARGS[2]}" "${APP_TARGET_ARGS[3]}"
    INPLACE_COMBO=1
    if [ "${#APP_TARGET_ARGS[@]}" -gt 4 ]; then
      APP_TARGET_ARGS=("${APP_TARGET_ARGS[@]:4}")
    else
      APP_TARGET_ARGS=()
    fi
    return 0
  fi
  if looks_like_combo "${APP_TARGET_ARGS[@]}"; then
    echo "Env comes right after ${cmd}: make ${cmd} <local|dev|prod> <fe> <llm-slug> <python|spring>"
    usage_stack_cmd "$cmd"
    exit 1
  fi
}

parse_stack_cmd_args() {
  STACK_CMD="$1"
  take_run_combo_args "$STACK_CMD"
  apply_default_stack_if_needed
  REQUESTED_ENV="${COMBO_ENV:-$DEFAULT_ENV}"
  if [ "${#APP_TARGET_ARGS[@]}" -eq 1 ]; then
    validate_env "${APP_TARGET_ARGS[0]}"
    REQUESTED_ENV="${APP_TARGET_ARGS[0]}"
  elif [ "${#APP_TARGET_ARGS[@]}" -ne 0 ]; then
    usage_stack_cmd "$STACK_CMD"
    exit 1
  fi
  require_active_stack "$STACK_CMD"
}

apply_default_stack_if_needed() {
  if [ "$INPLACE_COMBO" -eq 1 ]; then
    return 0
  fi
  if has_active_stack; then
    return 0
  fi
  echo "Using default stack: $DEFAULT_ENV + $DEFAULT_FE + $DEFAULT_LLM + $DEFAULT_BE"
  APP_NAME=""
  APP_ENV="${APP_ENV:-$DEFAULT_ENV}"
  apply_combo "$DEFAULT_FE" "$DEFAULT_LLM" "$DEFAULT_BE"
  INPLACE_COMBO=1
}

stack_needs_install() {
  if has_frontend && [ ! -d "$(fe_dir)/node_modules" ]; then
    return 0
  fi
  if [ "$BE_APP" = "python" ] && [ ! -d "$(be_dir)/.venv" ]; then
    return 0
  fi
  return 1
}

frontend_needs_install() {
  has_frontend && [ ! -d "$(fe_dir)/node_modules" ]
}

require_real_fe() {
  local cmd="${1:-run-fe}"
  if has_frontend; then
    return 0
  fi
  echo "No frontend selected (FE_APP=${FE_APP:-empty})."
  echo "Start one: make run-fe nuxt|next|vue|react"
  echo "Or pass a combo: make ${cmd} ${APP_ENV:-local} nuxt ${LLM_SLUG:-$DEFAULT_LLM} ${BE_APP:-$DEFAULT_BE}"
  exit 1
}

only_frontend_in_tree() {
  local app found=""
  for app in $FE_APPS; do
    if [ -f "$ROOT/frontend/$app/package.json" ]; then
      if [ -n "$found" ]; then
        return 1
      fi
      found="$app"
    fi
  done
  [ -n "$found" ] || return 1
  echo "$found"
}

export_frontend_api_urls() {
  export NUXT_PUBLIC_API_URL="${NUXT_PUBLIC_API_URL:-http://127.0.0.1:8000}"
  export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://127.0.0.1:8000}"
  export VITE_API_URL="${VITE_API_URL:-http://127.0.0.1:8000}"
}

fe_dev_origin() {
  echo "http://127.0.0.1:$(fe_dev_port "$1")"
}

verify_backend_cors_for_fe() {
  local fe="$1"
  local origin allow
  origin="$(fe_dev_origin "$fe")"
  allow="$(
    curl -s -I -X OPTIONS "http://127.0.0.1:8000/api/chat" \
      -H "Origin: ${origin}" \
      -H "Access-Control-Request-Method: POST" \
      -H "Access-Control-Request-Headers: content-type" 2>/dev/null \
      | awk -F': ' 'tolower($1)=="access-control-allow-origin"{print $2}' \
      | tr -d '\r'
  )"
  if [ "$allow" = "$origin" ]; then
    return 0
  fi
  echo "Backend CORS does not allow ${origin} (got: ${allow:-none})."
  hint_backend_cors "$fe"
  exit 1
}

require_backend_ready() {
  if curl -sf "http://127.0.0.1:8000/api/ready" >/dev/null 2>&1; then
    return 0
  fi
  echo "Backend is not ready at http://127.0.0.1:8000/api/ready"
  echo "Start it first and leave it running:"
  echo "  make run ${APP_ENV:-local} no-fe ${LLM_SLUG:-$DEFAULT_LLM} ${BE_APP:-$DEFAULT_BE}"
  exit 1
}

require_active_stack() {
  local cmd="$1"
  if ! has_active_stack; then
    echo "No stack selected."
    usage_stack_cmd "$cmd"
    exit 1
  fi
}

ensure_service_envs() {
  local service_dir example dest
  local service_dirs
  if [ -z "${APP_ENV:-}" ]; then
    return 0
  fi
  service_dirs=("$(be_dir)")
  if has_frontend; then
    service_dirs+=("$(fe_dir)")
  fi
  for service_dir in "${service_dirs[@]}"; do
    example="$service_dir/.env.${APP_ENV}.example"
    dest="$service_dir/.env.${APP_ENV}"
    if [ -f "$example" ] && [ ! -f "$dest" ]; then
      cp "$example" "$dest"
      echo "Wrote ${dest#"$ROOT"/}"
    fi
  done
}

load_service_envs() {
  if [ -z "${APP_ENV:-}" ]; then
    return 0
  fi
  load_env_file "$(be_dir)/.env.${APP_ENV}"
  if has_frontend; then
    load_env_file "$(fe_dir)/.env.${APP_ENV}"
  fi
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required. Install Docker Desktop or Docker Engine."
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Start Docker, then try again."
    exit 1
  fi
}

detect_host_os() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"
  case "$uname_s" in
    Darwin)
      HOST_OS=macos
      HOST_OS_LABEL="macOS"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null ||
        grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
        HOST_OS=wsl
        HOST_OS_LABEL="Windows (WSL)"
      else
        HOST_OS=linux
        HOST_OS_LABEL="Linux"
      fi
      ;;
    MINGW* | MSYS* | CYGWIN*)
      HOST_OS=windows
      HOST_OS_LABEL="Windows"
      ;;
    *)
      HOST_OS=unknown
      HOST_OS_LABEL="$uname_s"
      ;;
  esac
}

java21_bin_ok() {
  local bin="$1"
  [ -x "$bin" ] && "$bin" -version 2>&1 | awk 'NR == 1 { exit($0 !~ /"21[.]/) }'
}

activate_java21() {
  if command -v java >/dev/null 2>&1 && java21_bin_ok "$(command -v java)"; then
    return 0
  fi

  local detected=""
  if [ -x /usr/libexec/java_home ]; then
    detected="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
  fi
  if [ -n "$detected" ] && java21_bin_ok "$detected/bin/java"; then
    export JAVA_HOME="$detected"
    export PATH="$JAVA_HOME/bin:$PATH"
    return 0
  fi
  if [ -n "${JAVA_HOME:-}" ] && java21_bin_ok "$JAVA_HOME/bin/java"; then
    export PATH="$JAVA_HOME/bin:$PATH"
    return 0
  fi

  local candidate
  for candidate in \
    "$HOME"/.jdks/*/Contents/Home \
    "$HOME"/.jdks/* \
    "$HOME"/Library/Java/JavaVirtualMachines/*/Contents/Home \
    "$HOME"/.sdkman/candidates/java/current \
    "$HOME"/.sdkman/candidates/java/21* \
    /usr/lib/jvm/java-21-* \
    /usr/lib/jvm/temurin-21* \
    /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    "/c/Program Files/Java"/jdk-21* \
    "/c/Program Files/Microsoft"/jdk-21* \
    "/c/Program Files/Eclipse Adoptium"/jdk-21*; do
    if java21_bin_ok "$candidate/bin/java"; then
      export JAVA_HOME="$candidate"
      export PATH="$JAVA_HOME/bin:$PATH"
      return 0
    fi
    if java21_bin_ok "$candidate/bin/java.exe"; then
      export JAVA_HOME="$candidate"
      export PATH="$JAVA_HOME/bin:$PATH"
      return 0
    fi
  done
  return 1
}

intellij_present() {
  local p
  for p in \
    "/Applications/IntelliJ IDEA.app" \
    "/Applications/IntelliJ IDEA CE.app" \
    "/Applications/IntelliJ IDEA Community Edition.app" \
    "$HOME/Applications/IntelliJ IDEA.app" \
    "$HOME/Applications/IntelliJ IDEA CE.app"; do
    if [ -d "$p" ]; then
      return 0
    fi
  done
  if command -v idea >/dev/null 2>&1 || command -v idea64 >/dev/null 2>&1; then
    return 0
  fi
  if compgen -G "$HOME/Library/Application Support/JetBrains/Toolbox/apps/IDEA*" >/dev/null 2>&1; then
    return 0
  fi
  if compgen -G "$HOME/.local/share/JetBrains/Toolbox/apps/intellij-idea*" >/dev/null 2>&1; then
    return 0
  fi
  if [ -n "${PROGRAMFILES:-}" ] && compgen -G "${PROGRAMFILES}/JetBrains/IntelliJ*" >/dev/null 2>&1; then
    return 0
  fi
  if compgen -G "/c/Program Files/JetBrains/IntelliJ*" >/dev/null 2>&1; then
    return 0
  fi
  if [ -n "${LOCALAPPDATA:-}" ] &&
    compgen -G "${LOCALAPPDATA}/Programs/IntelliJ*" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

hint_git() {
  case "$HOST_OS" in
    macos) echo "xcode-select --install" ; echo "Or: https://git-scm.com" ;;
    linux) echo "sudo apt install git     (Debian/Ubuntu)" ; echo "sudo dnf install git     (Fedora)" ;;
    wsl) echo "sudo apt install git" ;;
    windows) echo "Install Git for Windows: https://git-scm.com/download/win" ; echo "Or: winget install Git.Git" ;;
    *) echo "https://git-scm.com" ;;
  esac
}

hint_make() {
  case "$HOST_OS" in
    macos) echo "xcode-select --install" ; echo "Or: brew install make" ;;
    linux) echo "sudo apt install make" ;;
    wsl) echo "sudo apt install make" ;;
    windows) echo "Use WSL2, then: sudo apt install make" ; echo "Or: choco install make" ;;
    *) echo "Install GNU Make" ;;
  esac
}

hint_volta() {
  case "$HOST_OS" in
    windows)
      echo "winget install Volta.Volta"
      echo "Or installer: https://docs.volta.sh/guide/getting-started"
      echo "Then open a new terminal so volta is on PATH."
      ;;
    *)
      echo "curl https://get.volta.sh | bash"
      echo "Then open a new terminal so volta is on PATH."
      ;;
  esac
}

hint_node() {
  echo "volta install node@${NEED_NODE}"
  echo "If volta is missing, install volta first (see above)."
}

hint_pnpm() {
  echo "volta install pnpm@${NEED_PNPM}"
  echo "If volta is missing, install volta first (see above)."
}

hint_uv() {
  case "$HOST_OS" in
    windows)
      echo "powershell -ExecutionPolicy ByPass -c \"irm https://astral.sh/uv/install.ps1 | iex\""
      echo "Docs: https://docs.astral.sh/uv/getting-started/installation/"
      echo "Then open a new terminal."
      ;;
    *)
      echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
      echo "Then open a new terminal so uv is on PATH."
      ;;
  esac
}

hint_python() {
  echo "uv python install ${NEED_PYTHON}"
  echo "If uv is missing, install uv first (see above)."
}

hint_docker() {
  case "$HOST_OS" in
    macos) echo "Install Docker Desktop: https://docs.docker.com/desktop/setup/install/mac-install/" ;;
    windows) echo "Install Docker Desktop: https://docs.docker.com/desktop/setup/install/windows-install/" ; echo "Enable the WSL2 backend, then open a new terminal." ;;
    wsl) echo "Install Docker Desktop on Windows with the WSL2 backend." ; echo "https://docs.docker.com/desktop/setup/install/windows-install/" ;;
    linux) echo "Install Docker Engine + Compose plugin:" ; echo "https://docs.docker.com/engine/install/" ;;
    *) echo "https://docs.docker.com/get-docker/" ;;
  esac
}

hint_docker_compose() {
  echo "Install the Docker Compose plugin (included with Docker Desktop)."
  echo "Linux packages: sudo apt install docker-compose-plugin"
}

hint_docker_daemon() {
  case "$HOST_OS" in
    linux) echo "sudo systemctl start docker" ; echo "Or start Docker Engine, then retry." ;;
    *) echo "Start Docker Desktop, wait until it is running, then retry." ;;
  esac
}

hint_rsync() {
  case "$HOST_OS" in
    macos) echo "xcode-select --install" ;;
    linux | wsl) echo "sudo apt install rsync" ;;
    windows) echo "Use WSL2 (sudo apt install rsync) or install rsync in Git Bash." ;;
    *) echo "Install rsync" ;;
  esac
}

hint_jdk() {
  echo "In IntelliJ IDEA: File → Project Structure → SDKs → Download JDK → ${NEED_JAVA}"
  echo "Set the same JDK: Settings → Build Tools → Gradle → Gradle JVM"
  case "$HOST_OS" in
    macos) echo "Optional: brew install --cask temurin@${NEED_JAVA}" ;;
    linux | wsl) echo "Optional: sudo apt install temurin-${NEED_JAVA}-jdk   or SDKMAN: sdk install java ${NEED_JAVA}-tem" ;;
    windows) echo "Optional: winget install EclipseAdoptium.Temurin.${NEED_JAVA}.JDK" ;;
  esac
}

hint_intellij() {
  echo "Download IntelliJ IDEA: https://www.jetbrains.com/idea/download/"
  case "$HOST_OS" in
    macos) echo "Optional: brew install --cask intellij-idea-ce" ;;
    linux | wsl) echo "Or install JetBrains Toolbox, then IntelliJ IDEA." ;;
    windows) echo "Or: winget install JetBrains.IntelliJIDEA.Community" ;;
  esac
  echo "Needed for Spring (download JDK ${NEED_JAVA} from IntelliJ)."
}

require_java21() {
  if ! activate_java21; then
    detect_host_os
    echo "JDK ${NEED_JAVA} is required for Spring (${HOST_OS_LABEL})."
    hint_jdk
    exit 1
  fi
}

prereq_ok() {
  printf '  OK     %-16s %s\n' "$1" "$2"
}

prereq_need() {
  printf '  NEED   %-16s %s\n' "$1" "$2"
}

prereq_skip() {
  printf '  SKIP   %-16s %s\n' "$1" "$2"
}

prereq_warn() {
  printf '  WARN   %-16s %s\n' "$1" "$2"
}

record_need() {
  local name="$1"
  local detail="$2"
  local how="$3"
  prereq_need "$name" "$detail"
  NEED_NAMES+=("$name")
  NEED_HOWS+=("$how")
}

print_need_fixes() {
  local i=0
  local count="${#NEED_NAMES[@]}"
  if [ "$count" -eq 0 ]; then
    return 0
  fi
  echo ""
  echo "How to install the missing tools on ${HOST_OS_LABEL}:"
  echo ""
  while [ "$i" -lt "$count" ]; do
    echo "  ${NEED_NAMES[$i]}"
    printf '%s\n' "${NEED_HOWS[$i]}" | sed 's/^/    /'
    echo ""
    i=$((i + 1))
  done
}

# scope: full (clone/run) requires Docker daemon; tools (install/test) does not.
check_prereqs() {
  local scope="${1:-full}"
  local node_ver=""
  local pnpm_ver=""
  local py_path=""
  local missing=0
  NEED_NAMES=()
  NEED_HOWS=()
  detect_host_os

  echo ""
  echo "Checking required tools on ${HOST_OS_LABEL}"
  echo "-----------------------------------------------------"

  if command -v git >/dev/null 2>&1; then
    prereq_ok git "$(git --version 2>/dev/null | head -1)"
  else
    record_need git "not installed" "$(hint_git)"
  fi

  if command -v make >/dev/null 2>&1; then
    prereq_ok make "$(make --version 2>/dev/null | head -1)"
  else
    record_need make "not installed" "$(hint_make)"
  fi

  if command -v rsync >/dev/null 2>&1; then
    prereq_ok rsync "$(rsync --version 2>/dev/null | head -1)"
  else
    record_need rsync "not installed (needed to clone an app)" "$(hint_rsync)"
  fi

  if command -v volta >/dev/null 2>&1; then
    prereq_ok volta "$(volta --version 2>/dev/null | head -1)"
  else
    record_need volta "not installed" "$(hint_volta)"
  fi

  if command -v node >/dev/null 2>&1; then
    node_ver="$(node -v 2>/dev/null | sed 's/^v//')"
    if [ "${node_ver%%.*}" = "22" ]; then
      if [ "$node_ver" = "$NEED_NODE" ]; then
        prereq_ok node "$node_ver"
      else
        prereq_ok node "$node_ver (pinned ${NEED_NODE})"
      fi
    else
      record_need node "found ${node_ver:-unknown}, need ${NEED_NODE}" "$(hint_node)"
    fi
  else
    record_need node "not installed (need ${NEED_NODE})" "$(hint_node)"
  fi

  if command -v pnpm >/dev/null 2>&1; then
    pnpm_ver="$(pnpm -v 2>/dev/null | head -1)"
    if [ "$pnpm_ver" = "$NEED_PNPM" ]; then
      prereq_ok pnpm "$pnpm_ver"
    else
      record_need pnpm "found ${pnpm_ver:-unknown}, need ${NEED_PNPM}" "$(hint_pnpm)"
    fi
  else
    record_need pnpm "not installed (need ${NEED_PNPM})" "$(hint_pnpm)"
  fi

  if command -v uv >/dev/null 2>&1; then
    prereq_ok uv "$(uv --version 2>/dev/null | head -1)"
    py_path="$(uv python find "$NEED_PYTHON" 2>/dev/null || true)"
    if [ -n "$py_path" ] && [ -x "$py_path" ]; then
      prereq_ok "python ${NEED_PYTHON}" "$("$py_path" --version 2>/dev/null | head -1)"
    else
      record_need "python ${NEED_PYTHON}" "not installed" "$(hint_python)"
    fi
  else
    record_need uv "not installed" "$(hint_uv)"
    record_need "python ${NEED_PYTHON}" "needs uv first" "$(hint_python)"
  fi

  if command -v docker >/dev/null 2>&1; then
    prereq_ok docker "$(docker --version 2>/dev/null | head -1)"
    if docker compose version >/dev/null 2>&1; then
      prereq_ok "docker compose" "$(docker compose version 2>/dev/null | head -1)"
    else
      record_need "docker compose" "Compose plugin not installed" "$(hint_docker_compose)"
    fi
    if docker info >/dev/null 2>&1; then
      prereq_ok "docker daemon" "running"
    elif [ "$scope" = "full" ]; then
      record_need "docker daemon" "not running" "$(hint_docker_daemon)"
    else
      prereq_warn "docker daemon" "not running — start it before make clone / make run"
    fi
  else
    record_need docker "not installed" "$(hint_docker)"
  fi

  if [ "${BE_APP:-}" = "spring" ]; then
    if intellij_present; then
      prereq_ok intellij "installed"
    else
      record_need intellij "not installed (required for Spring)" "$(hint_intellij)"
    fi
    if activate_java21; then
      prereq_ok "jdk ${NEED_JAVA}" "$(java -version 2>&1 | head -1)"
    else
      record_need "jdk ${NEED_JAVA}" "not installed (required for Spring)" "$(hint_jdk)"
    fi
  elif [ "${BE_APP:-}" = "python" ]; then
    prereq_skip intellij "not required (backend is python)"
    prereq_skip "jdk ${NEED_JAVA}" "not required (backend is python)"
  else
    prereq_skip intellij "needed later only if you clone spring"
    prereq_skip "jdk ${NEED_JAVA}" "needed later only if you clone spring"
  fi

  echo "-----------------------------------------------------"
  missing="${#NEED_NAMES[@]}"
  if [ "$missing" -ne 0 ]; then
    echo "Missing or wrong version: ${missing} item(s) on ${HOST_OS_LABEL}."
    print_need_fixes
    echo "Fix the NEED items, then retry."
    echo ""
    exit 1
  fi
  echo "All required tools are ready on ${HOST_OS_LABEL}."
  echo ""
}

fe_dev_port() {
  case "$1" in
    vue) echo 5173 ;;
    react) echo 5174 ;;
    nuxt) echo 3000 ;;
    next) echo 3000 ;;
    *) echo 3000 ;;
  esac
}

port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  else
    return 1
  fi
}

host_tcp_open() {
  local host="$1"
  local port="$2"
  python3 -c "import socket; s=socket.create_connection(('$host', int('$port')), 2); s.close()" 2>/dev/null
}

wait_host_tcp() {
  local host="$1"
  local port="$2"
  local i
  for i in $(seq 1 60); do
    if host_tcp_open "$host" "$port"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

stop_pid_tree() {
  local pid="${1:-}"
  local child
  [ -n "$pid" ] || return 0
  kill -0 "$pid" 2>/dev/null || return 0
  while IFS= read -r child; do
    [ -n "$child" ] || continue
    stop_pid_tree "$child"
  done < <(pgrep -P "$pid" 2>/dev/null || true)
  kill "$pid" 2>/dev/null || true
}

free_listen_port() {
  local port="${1:-}"
  local pids
  local round
  [ -n "$port" ] || return 0
  for round in 1 2 3; do
    pids="$(lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
    [ -n "$pids" ] || return 0
    # shellcheck disable=SC2086
    if [ "$round" -lt 3 ]; then
      kill $pids 2>/dev/null || true
    else
      kill -9 $pids 2>/dev/null || true
    fi
    sleep 0.2
  done
}

stop_child_pids() {
  local pid
  for pid in "$@"; do
    stop_pid_tree "$pid"
  done
}

reap_child_pids() {
  local pid
  local i
  for pid in "$@"; do
    for i in 1 2 3 4 5 6 7 8 9 10; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.2
    done
    if kill -0 "$pid" 2>/dev/null; then
      stop_pid_tree "$pid"
      kill -9 "$pid" 2>/dev/null || true
    fi
  done
  if [ "$#" -gt 0 ]; then
    wait "$@" 2>/dev/null || true
  fi
}

compose_cmd() {
  (cd "$ROOT/docker/${LLM_SLUG}" && docker compose "$@")
}

postgres_db_name() {
  awk '/POSTGRES_DB:/ { print $2; exit }' "$ROOT/docker/${LLM_SLUG}/compose.yml"
}

ensure_postgres_database() {
  local db_name
  db_name="$(postgres_db_name)"
  if [ -z "$db_name" ]; then
    echo "FAILED: Could not read POSTGRES_DB from docker/${LLM_SLUG}/compose.yml"
    exit 1
  fi
  if compose_cmd exec -T postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${db_name}'" | grep -q 1; then
    echo "Postgres database $db_name ready"
    return 0
  fi
  echo "Creating postgres database $db_name"
  if ! compose_cmd exec -T postgres createdb -U postgres "$db_name"; then
    echo "FAILED: Could not create postgres database $db_name"
    hint_postgres_port_5432 "$db_name"
    exit 1
  fi
  echo "Postgres database $db_name created"
}

verify_postgres_host_database() {
  local db_name ok=0
  db_name="$(postgres_db_name)"
  [ -n "$db_name" ] || return 0
  if command -v psql >/dev/null 2>&1; then
    PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d "$db_name" -tc "SELECT 1" 2>/dev/null | grep -q 1 && ok=1
  else
    docker run --rm -e PGPASSWORD=postgres --add-host=host.docker.internal:host-gateway postgres:16.6-alpine \
      psql -h host.docker.internal -p 5432 -U postgres -d "$db_name" -tc "SELECT 1" 2>/dev/null | grep -q 1 && ok=1
  fi
  if [ "$ok" -eq 1 ]; then
    return 0
  fi
  echo "FAILED: Database $db_name is not reachable at 127.0.0.1:5432."
  hint_postgres_port_5432 "$db_name"
  exit 1
}

hint_heading() {
  echo
  echo "How to fix:"
}

hint_postgres_port_5432() {
  local db_name="${1:-$(postgres_db_name 2>/dev/null || true)}"
  hint_heading
  echo "  Port 5432 may be used by another Postgres (not this app's Docker container)."
  echo "  1. See what listens on 5432:"
  echo "       lsof -nP -iTCP:5432 -sTCP:LISTEN"
  echo "  2. Stop other stacks:  make down   (in each other app folder)"
  echo "  3. Stop local Postgres (Homebrew):  brew services stop postgresql postgresql@16"
  if [ -n "$db_name" ]; then
    echo "  4. Create the database in this app's Postgres (if needed):"
    echo "       docker compose -f docker/${LLM_SLUG}/compose.yml exec -T postgres createdb -U postgres ${db_name}"
  fi
  echo "  5. In this folder:  make down && make run"
  hint_guide_link
}

hint_postgres_database_missing() {
  local db_name
  db_name="$(postgres_db_name 2>/dev/null || echo '<database>')"
  hint_heading
  echo "  The backend could not find Postgres database: ${db_name}"
  echo "  1. Create it in this app's Docker Postgres:"
  echo "       docker compose -f docker/${LLM_SLUG}/compose.yml exec -T postgres createdb -U postgres ${db_name}"
  echo "  2. If that fails, port 5432 is probably another Postgres — check:"
  echo "       lsof -nP -iTCP:5432 -sTCP:LISTEN"
  echo "  3. Stop other stacks (make down elsewhere), then:  make down && make run"
  hint_guide_link
}

hint_docker_unhealthy() {
  hint_heading
  echo "  Docker Postgres/Ollama did not become healthy."
  echo "  1. Check ports:"
  echo "       lsof -nP -iTCP:5432 -sTCP:LISTEN"
  echo "       lsof -nP -iTCP:11434 -sTCP:LISTEN"
  echo "  2. Stop other stacks:  make down   (in other app folders)"
  echo "  3. Retry:  make down && make run"
  hint_guide_link
}

hint_ollama_not_ready() {
  hint_heading
  echo "  Ollama is not ready on http://127.0.0.1:11434"
  echo "  1. Check port:  lsof -nP -iTCP:11434 -sTCP:LISTEN"
  echo "  2. Restart Docker:  make down && make run"
  echo "  3. Pull model manually:"
  echo "       docker compose -f docker/${LLM_SLUG}/compose.yml exec -T ollama ollama pull ${OLLAMA_MODEL:-<model>}"
  hint_guide_link
}

hint_port_in_use() {
  local port="$1"
  local label="${2:-service}"
  hint_heading
  echo "  Port ${port} (${label}) is already in use."
  echo "  1. See the process:"
  echo "       lsof -nP -iTCP:${port} -sTCP:LISTEN"
  echo "  2. Stop it or run:  make down"
  echo "  3. Retry:  make run"
  hint_guide_link
}

hint_backend_cors() {
  local fe="$1"
  hint_heading
  echo "  Backend CORS does not match frontend ${fe}."
  echo "  1. Stop make run (Ctrl+C)"
  echo "  2. Start backend again:  make run"
  echo "  3. If you changed the dev port, add it to backend CORS (see README)."
  hint_guide_link
}

hint_guide_link() {
  echo "  More help:  https://ai.teristimewa.com/"
}

print_run_stop_hint() {
  echo "To stop:"
  echo "  Ctrl+C here  — stops backend + frontend in this terminal only"
  echo "  make down    — stops Docker (Postgres + Ollama); run in another terminal, same folder"
  echo
}

print_run_stop_reminder() {
  echo
  echo "Docker (Postgres + Ollama) is still running. Stop it with:  make down"
  echo
}

print_backend_failure_hints() {
  local log="${1:-}"
  [ -n "$log" ] && [ -f "$log" ] || return 0
  if grep -qE 'InvalidCatalogNameError|database "[^"]+" does not exist' "$log" 2>/dev/null; then
    hint_postgres_database_missing
    return 0
  fi
  if grep -qE 'Connection refused|OperationalError|asyncpg|psql:|postgres|5432' "$log" 2>/dev/null; then
    hint_postgres_port_5432
    return 0
  fi
  if grep -qE 'ollama|11434' "$log" 2>/dev/null; then
    hint_ollama_not_ready
    return 0
  fi
  if grep -qE 'Address already in use|:8000' "$log" 2>/dev/null; then
    hint_port_in_use 8000 "backend API"
    return 0
  fi
  hint_heading
  echo "  Scroll up for the full error above."
  hint_guide_link
}

be_dir() {
  if [ "$BE_APP" = "spring" ]; then
    echo "$ROOT/backend/spring-boot/${LLM_SLUG}"
  else
    echo "$ROOT/backend/python/${LLM_SLUG}"
  fi
}

fe_dir() {
  echo "$ROOT/frontend/${FE_APP}"
}

assert_cloned_dirs() {
  local fe be docker_dir
  be="$(be_dir)"
  docker_dir="$ROOT/docker/${LLM_SLUG}"
  if has_frontend; then
    fe="$(fe_dir)"
    if [ ! -f "$fe/package.json" ]; then
      echo "Missing frontend ${fe#"$ROOT"/}. Clone from the template: make clone <fe> <llm-slug> <python|spring> <app-name>"
      exit 1
    fi
  fi
  if [ ! -d "$be" ]; then
    echo "Missing backend ${be#"$ROOT"/}. Clone from the template: make clone <fe> <llm-slug> <python|spring> <app-name>"
    exit 1
  fi
  if [ ! -f "$docker_dir/compose.yml" ]; then
    echo "Missing docker ${docker_dir#"$ROOT"/}/compose.yml. Clone from the template: make clone <fe> <llm-slug> <python|spring> <app-name>"
    exit 1
  fi
}

rsync_tree() {
  local src="$1"
  local dest="$2"
  if [ ! -e "$src" ]; then
    echo "Missing source: $src"
    exit 1
  fi
  mkdir -p "$dest"
  rsync -a \
    --exclude '.git/' \
    --exclude 'node_modules/' \
    --exclude '.venv/' \
    --exclude '__pycache__/' \
    --exclude '.pytest_cache/' \
    --exclude '.ruff_cache/' \
    --exclude '.nuxt/' \
    --exclude '.output/' \
    --exclude '.nitro/' \
    --exclude '.next/' \
    --exclude 'dist/' \
    --exclude 'build/' \
    --exclude '.gradle/' \
    --exclude 'coverage/' \
    --exclude 'playwright-report/' \
    --exclude 'test-results/' \
    --exclude '.DS_Store' \
    --exclude '.env.local' \
    --exclude '.env.dev' \
    --exclude '.env.prod' \
    --exclude 'e2e.env' \
    --exclude 'public/llm.active.json' \
    "$src/" "$dest/"
}

sanitize_compose_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//'
}

rewrite_compose_project_name() {
  local file="$ROOT/docker/${LLM_SLUG}/compose.yml"
  local compose_name
  compose_name="$(sanitize_compose_name "$APP_NAME")"
  if [ -z "$compose_name" ]; then
    echo "Could not build a Docker Compose project name from: $APP_NAME"
    exit 1
  fi
  python3 - "$file" "$compose_name" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
name = sys.argv[2]
lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
out = []
replaced = False
for line in lines:
    if not replaced and line.startswith("name:"):
        out.append(f"name: {name}\n")
        replaced = True
    else:
        out.append(line)
if not replaced:
    raise SystemExit(f"Missing name: in {path}")
path.write_text("".join(out), encoding="utf-8")
PY
  echo "Set Docker Compose project name to $compose_name"
}

rewrite_package_name() {
  python3 - "$ROOT/package.json" "$APP_NAME" <<'PY'
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["name"] = sys.argv[2]
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

copy_cloned_app() {
  local dest="$1"
  local fe_src docker_src be_src be_rel
  fe_src="$ROOT/frontend/${FE_APP}"
  docker_src="$ROOT/docker/${LLM_SLUG}"
  if [ "$BE_APP" = "spring" ]; then
    be_rel="backend/spring-boot/${LLM_SLUG}"
  else
    be_rel="backend/python/${LLM_SLUG}"
  fi
  be_src="$ROOT/$be_rel"

  if [ ! -f "$fe_src/package.json" ]; then
    echo "This folder is missing frontend ${FE_APP}. Clone from the full template."
    exit 1
  fi
  if [ ! -d "$be_src" ]; then
    echo "This folder is missing backend ${be_rel}. Clone from the full template."
    exit 1
  fi
  if [ ! -f "$docker_src/compose.yml" ]; then
    echo "This folder is missing docker ${LLM_SLUG}. Clone from the full template."
    exit 1
  fi
  if ! command -v rsync >/dev/null 2>&1; then
    echo "rsync is required to clone an app."
    exit 1
  fi

  mkdir -p "$dest"
  cp "$ROOT/Makefile" "$dest/Makefile"
  cp "$ROOT/package.json" "$dest/package.json"
  cp "$ROOT/.gitignore" "$dest/.gitignore"
  rsync_tree "$ROOT/scripts" "$dest/scripts"
  if [ -d "$ROOT/.husky" ]; then
    rsync_tree "$ROOT/.husky" "$dest/.husky"
  fi
  rsync_tree "$fe_src" "$dest/frontend/${FE_APP}"
  rsync_tree "$be_src" "$dest/$be_rel"
  rsync_tree "$docker_src" "$dest/docker/${LLM_SLUG}"
}
