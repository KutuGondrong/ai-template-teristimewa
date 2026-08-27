#!/usr/bin/env bash
set -euo pipefail
cat <<'EOF'
make install          pnpm in each frontend + uv sync in each python backend
make clone <fe> <llm-slug> <python|spring> <app-name>
                      copy that stack to ../<app-name> (sibling of this template)
                      then: cd ../<app-name> && make run
make run              start default stack (local + nuxt + deepseek-r1-1.5b + python)
make run <local|dev|prod> <fe|no-fe> <llm-slug> <python|spring>
make run-fe <fe>      frontend only; backend must already be up (make run … no-fe)
make test / test-e2e / smoke / down
                      same args as make run
After clone, cd ../<app-name> then:
make run              start that cloned stack (env=local)
make run local|dev|prod
make run-fe           frontend only (or make run-fe <fe>)
make test / test-e2e / smoke / down
                      same args as make run
make build
make lint / make format
EOF
