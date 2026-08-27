# BEGIN ACTIVE_STACK
APP_ENV := local
APP_NAME := 
FE_APP := vue
LLM_SLUG := gemma2-2b
BE_APP := python
# END ACTIVE_STACK

.PHONY: install clone run run-fe down build lint format test test-e2e smoke help

install:
	./scripts/install.sh

clone:
	./scripts/clone.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

run:
	./scripts/run.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

run-fe:
	./scripts/run-fe.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

down:
	./scripts/down.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

build:
	./scripts/build.sh

lint:
	./scripts/lint.sh

format:
	./scripts/format.sh

test:
	./scripts/test.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

test-e2e:
	./scripts/test-e2e.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

smoke:
	./scripts/smoke.sh $(word 2,$(MAKECMDGOALS)) $(word 3,$(MAKECMDGOALS)) $(word 4,$(MAKECMDGOALS)) $(word 5,$(MAKECMDGOALS))

help:
	./scripts/help.sh

%:
	@:
