# Local AI template

English README. [Bahasa Indonesia](README.id.md)

![AI Teristimewa home page](assets/home-page-ai-template.png)

**User-friendly guide:** Step-by-step documentation at [https://ai.teristimewa.com/](https://ai.teristimewa.com/)

## What you need first

Install these on your machine **before** you clone this repo.


| Tool                   | macOS                                                                                    | Windows                                                                          | Linux                   |
| ---------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ----------------------- |
| Git                    | `xcode-select --install` or [git-scm](https://git-scm.com)                               | [Git for Windows](https://git-scm.com)                                           | `sudo apt install git`  |
| **Docker** (required)  | [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)             | [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) | Engine + Compose plugin |
| Volta + Node 22 + pnpm | `curl https://get.volta.sh | bash` then `volta install node@22` and `volta install pnpm` | installer from volta.sh, same volta commands                                     | same as macOS           |
| uv + Python 3.12       | `curl -LsSf https://astral.sh/uv/install.sh | sh` then `uv python install 3.12`          | PowerShell installer from [uv](https://docs.astral.sh/uv/)                       | same as macOS           |
| Make                   | `xcode-select --install` or `brew install make`                                          | WSL2: `sudo apt install make`                                                    | `sudo apt install make` |
| IntelliJ IDEA + JDK 21 | only for Spring; IntelliJ can download JDK 21                                            | same                                                                             | same                    |


Check: `git --version`, `docker --version`, `docker compose version`, `node --version`, `pnpm --version`, `uv --version`, `make --version`.

`make clone`, `make run`, `make install`, `make test`, and `make test-e2e` print a tool check first. The log shows your OS (macOS, Linux, Windows, or WSL) and marks each tool **OK**, **NEED**, or **SKIP**. If Volta, Node 22, pnpm 11.17.0, uv, Python 3.12, Docker, rsync, or (for Spring) IntelliJ IDEA and JDK 21 is missing or the wrong version, they stop and print the install command for that OS.

Docker Desktop/Engine must be **running** before `make clone` / `make run`.

For Spring, open a Spring project in IntelliJ IDEA, then use **File → Project
Structure → SDK → Download JDK** and select version 21. Set the same JDK under
**Settings → Build Tools → Gradle → Gradle JVM**. The scripts automatically
detect IntelliJ-downloaded JDKs in `~/.jdks`. SDKMAN is an optional Java version
manager, similar to Volta/FVM; it is not required.

## After you have this template

Without cloning, `make run` starts the default stack: **local** + **nuxt** + **deepseek-r1-1.5b** + **python**.

```bash
make run
```

That installs that stack if needed and starts docker + backend + frontend.

To keep Docker and the backend up while you switch frontends (Nuxt / Next / Vue / React), start backend only, then pick a frontend in another terminal:

```bash
make run local no-fe deepseek-r1-1.5b python
make run-fe nuxt
```

`Ctrl+C` on `make run-fe` stops that UI only. Then `make run-fe next` (or `vue` / `react`). `Ctrl+C` on `make run … no-fe` stops the backend. `make down` stops Docker.

Same args for tests and smoke (keep backend + frontend going in other terminals for e2e/smoke):

```bash
make test
make test-e2e
make smoke
make down
```

Another combo in this template — env comes right after the command:

```bash
make run local nuxt deepseek-r1-1.5b python
make test local nuxt deepseek-r1-1.5b python
make test-e2e local nuxt deepseek-r1-1.5b python
make smoke local nuxt deepseek-r1-1.5b python
```

To copy a combo into a **new sibling folder** next to this template (`../<app-name>`), clone, then `cd` into that folder and run there:

```bash
make clone nuxt deepseek-r1-1.5b python my-ai-chat
cd ../my-ai-chat
make run
```

Example: template at `…/ai/ai-template-teristimewa`, cloned app at `…/ai/my-ai-chat`. Do not run `make run my-ai-chat` from the template.

Without Make: `./scripts/run.sh`, or `./scripts/run.sh local nuxt deepseek-r1-1.5b python`, or `./scripts/run.sh local no-fe deepseek-r1-1.5b python` then `./scripts/run-fe.sh nuxt`. After clone: `cd ../my-ai-chat` and `./scripts/run.sh`.

`make clone` does not rename this template. It writes the combo into the new app's `Makefile`, installs that stack, pulls that Docker model, and **replaces that app's README** so it only describes that frontend, backend, and Docker. It does not start the apps.

There is no `make dev`. In the cloned folder, `make run` uses env **local**. To pick env after clone:

```bash
make run local
make run dev
make run prod
make test local
make test-e2e local
make smoke local
```

Env files are currently the same. Each service still has its own `local` / `dev` / `prod` files.

FE: `nuxt` | `next` | `vue` | `react` | `no-fe` (backend only; then `make run-fe`)  
LLM: `deepseek-r1-1.5b` | `qwen2.5-0.5b` | `qwen2.5-1.5b` | `llama3.2-1b` | `gemma2-2b`  
BE: `python` | `spring`

App name: start with a letter; letters, numbers, hyphen, or underscore (example: `my-ai-chat`).

Open the UI at **[http://127.0.0.1:5174](http://127.0.0.1:5174)** (react), **5173** (vue), or **3000** (nuxt/next). API Swagger is [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) on local/dev. Prod has no Swagger; use [http://127.0.0.1:8000/api/health](http://127.0.0.1:8000/api/health).

### Dev ports & CORS

Chat and the LLM go through the **backend on port 8000** (Ollama on 11434 in Docker), not through the UI port. Dev servers bind to **127.0.0.1**; the default API URL is **[http://127.0.0.1:8000](http://127.0.0.1:8000)** (so session cookies work).

Default dev ports are already in backend CORS (3000, 5173, 5174 — both `localhost` and `127.0.0.1`). If chat fails after switching frontends, **restart the backend** (`Ctrl+C`, then `make run … no-fe` again). `make run-fe` refuses to start when backend CORS does not match.


| Frontend   | Dev URL                                        |
| ---------- | ---------------------------------------------- |
| nuxt, next | [http://127.0.0.1:3000](http://127.0.0.1:3000) |
| vue        | [http://127.0.0.1:5173](http://127.0.0.1:5173) |
| react      | [http://127.0.0.1:5174](http://127.0.0.1:5174) |


If you run the UI on **another port** (e.g. `pnpm dev -- --port 3001`), add that origin to backend **CORS** or the browser will block API calls.

**Python** (`backend/python/<slug>/`):

- `settings.yaml` or `settings.local.yaml` — add under `cors_origins`:

```yaml
cors_origins:
  - "http://localhost:3001"
  - "http://127.0.0.1:3001"
```

- or `.env.local` — `CORS_ORIGINS` as a JSON array:

```bash
CORS_ORIGINS='["http://localhost:3001","http://127.0.0.1:3001"]'
```

**Spring** — add the same URLs in `backend/spring-boot/<slug>/src/main/kotlin/com/teristimewa/ai/api/WebConfig.kt` (`.allowedOrigins(...)`).

Restart the backend after changing CORS.

Stop: `make down` in the same folder you started (`make run`). Another cloned app: from this template, `make clone … other-ai-chat`, then `cd` into that sibling.

`make install` in this template installs every frontend and python backend. You do not need it before `make run` or `make clone`; those install only the selected stack.

### RAM (host + Docker)

- qwen2.5-0.5b — light, ~8 GB
- qwen2.5-1.5b / llama3.2-1b — ~8–12 GB
- deepseek-r1-1.5b — ~12 GB
- gemma2-2b — heavy, ~16 GB



## Commands


| Make                                        | Script                                                                        |
| ------------------------------------------- | ----------------------------------------------------------------------------- |
| `make install`                              | `./scripts/install.sh`                                                        |
| `make clone <fe> <slug> <be> <app-name>`    | sibling folder; README there is only for that FE + BE + Docker                |
| `make run`                                  | default: local + nuxt + deepseek-r1-1.5b + python                             |
| `make run <env> <fe> <slug> <be>`           | start that stack in this template (env first)                                 |
| `make run <env> no-fe <slug> <be>`          | docker + backend only                                                         |
| `make run-fe <fe>`                          | frontend only (`nuxt` | `next` | `vue` | `react`); backend must already be up |
| `make run local|dev|prod`                   | after clone, in that folder: same stack, chosen env                           |
| `make test` / `test-e2e` / `smoke` / `down` | same args as `make run`                                                       |
| `make build`                                | production builds for all apps                                                |
| `make lint` / `make format`                 | ESLint + Ruff + ktlint                                                        |


E2E credentials: copy `e2e.env.example` in the frontend app to `e2e.env`.

## Envs

There is no root `.env`. Each service owns `local` / `dev` / `prod` files (same values for now) and its `.gitignore`:

- Frontend: `frontend/<app>/.env.local.example` / `.env.dev.example` / `.env.prod.example`
- Python: `backend/python/<slug>/settings.yaml`, `settings.{local,dev,prod}.yaml`, `.env.*.example`
- Spring: `application.yml` and `application-{local,dev,prod}.yml`
- Root `.gitignore` only covers root `package.json` leftovers (`/node_modules/`, `/.pnpm-store/`)
- LLM about page: `frontend/<app>/llm/<slug>.json` (committed). `make clone` / `make run` rewrites only the selected frontend's `public/llm.active.json`

