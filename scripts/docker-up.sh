#!/usr/bin/env bash
set -euo pipefail
export HUSKY=0
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

require_docker
load_default_config
ensure_service_envs
load_service_envs

echo "Starting docker $LLM_SLUG"
if ! compose_cmd up -d --wait --wait-timeout 120; then
  echo "FAILED: Docker services did not become healthy."
  echo "If port 5432 or 11434 is already in use, stop that container (make down in the other app) and retry."
  exit 1
fi

echo "Waiting for postgres on 127.0.0.1:5432"
if ! wait_host_tcp 127.0.0.1 5432; then
  echo "FAILED: Postgres is up in Docker but 127.0.0.1:5432 is not reachable from this machine."
  exit 1
fi
echo "Postgres ready"

echo "Waiting for ollama"
ollama_ready=0
for _ in $(seq 1 60); do
  if curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
    echo "Ollama ready"
    ollama_ready=1
    break
  fi
  sleep 2
done
if [ "$ollama_ready" -ne 1 ]; then
  echo "FAILED: Ollama did not become ready on http://127.0.0.1:11434"
  exit 1
fi

if ! compose_cmd exec -T ollama ollama show "$OLLAMA_MODEL" >/dev/null 2>&1; then
  echo "Pulling model $OLLAMA_MODEL"
  if ! compose_cmd exec -T ollama ollama pull "$OLLAMA_MODEL"; then
    echo "FAILED: Could not pull Ollama model $OLLAMA_MODEL"
    exit 1
  fi
fi
