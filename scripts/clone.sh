#!/usr/bin/env bash
set -euo pipefail
export HUSKY=0
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

if [ "$#" -ne 4 ]; then
  usage_clone
  exit 1
fi

validate_combo "$1" "$2" "$3"
validate_app_name "$4"
FE_APP="$1"
LLM_SLUG="$2"
BE_APP="$3"
APP_NAME="$4"
check_prereqs

DEST="$(app_dest_dir "$APP_NAME")"
if [ "$DEST" = "$ROOT" ]; then
  echo "App name cannot be this template folder."
  exit 1
fi
if [ -e "$DEST" ]; then
  echo "Destination already exists: $DEST"
  echo "Choose another app name or remove that folder."
  exit 1
fi

echo "Cloning $FE_APP + $LLM_SLUG + $BE_APP to $DEST"
copy_cloned_app "$DEST"

ROOT="$DEST"
APP_ENV=local
apply_combo "$FE_APP" "$LLM_SLUG" "$BE_APP"
rewrite_compose_project_name
rewrite_package_name
"$DEST/scripts/write-app-readme.sh"

if [ ! -d "$ROOT/.git" ]; then
  git -C "$ROOT" init >/dev/null
  git -C "$ROOT" config core.hooksPath .husky
fi

assert_cloned_dirs
ensure_service_envs
load_service_envs
install_selected_stack
require_docker

echo "Pulling docker $LLM_SLUG"
compose_cmd pull
echo "Pulling model $OLLAMA_MODEL"
compose_cmd up -d ollama
compose_cmd exec -T ollama ollama pull "$OLLAMA_MODEL" || {
  echo "Starting ollama pull via host after up"
  compose_cmd up -d
  sleep 3
  compose_cmd exec -T ollama ollama pull "$OLLAMA_MODEL"
}
compose_cmd stop ollama

echo "Cloned $FE_APP + $LLM_SLUG + $BE_APP to $DEST"
echo "This template folder was not changed."
echo "The new folder README is for $FE_APP + $LLM_SLUG + $BE_APP only."
echo "Next:"
echo "  cd $DEST"
echo "  make run"
