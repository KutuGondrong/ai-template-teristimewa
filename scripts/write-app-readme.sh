#!/usr/bin/env bash
set -euo pipefail
# Writes README.md, README.id.md, and help.sh for this app's FE + LLM + BE + Docker.
# Used by make clone. Safe to re-run after the Makefile stack is set.
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

load_makefile_stack
if [ -z "${FE_APP:-}" ] || [ -z "${LLM_SLUG:-}" ] || [ -z "${BE_APP:-}" ]; then
  echo "No active stack in Makefile. Cannot write app README."
  exit 1
fi
if [ -z "${APP_NAME:-}" ]; then
  echo "No APP_NAME in Makefile. This script is for a cloned app after make clone."
  exit 1
fi
load_docker_model

LLM_JSON="$ROOT/frontend/${FE_APP}/llm/${LLM_SLUG}.json"
if [ ! -f "$LLM_JSON" ]; then
  echo "Missing LLM config: ${LLM_JSON#"$ROOT"/}"
  exit 1
fi

python3 - "$ROOT" "$APP_NAME" "$FE_APP" "$LLM_SLUG" "$BE_APP" "$OLLAMA_MODEL" "$LLM_JSON" <<'PY'
from pathlib import Path
import json
import sys

root = Path(sys.argv[1])
app_name = sys.argv[2]
fe = sys.argv[3]
slug = sys.argv[4]
be = sys.argv[5]
ollama_model = sys.argv[6]
llm = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))

fe_label = {
    "nuxt": "Nuxt",
    "next": "Next.js",
    "vue": "Vue",
    "react": "React",
}[fe]
be_label = {
    "python": "Python (FastAPI)",
    "spring": "Spring Boot (Kotlin)",
}[be]
be_path = f"backend/python/{slug}" if be == "python" else f"backend/spring-boot/{slug}"
fe_path = f"frontend/{fe}"
docker_path = f"docker/{slug}"
llm_name = llm.get("name") or slug
llm_ver = llm.get("version") or ""
llm_title = f"{llm_name} {llm_ver}".strip()
ram = llm.get("ram_min_gb") or "?"
about_en = llm.get("about_en") or ""
about_id = llm.get("about_id") or ""
weight = llm.get("weight") or ""
vendor = llm.get("vendor") or ""
license = llm.get("license") or ""

if be == "python":
    tools_en = """| Git | `xcode-select --install` or [git-scm](https://git-scm.com) | [Git for Windows](https://git-scm.com) | `sudo apt install git` |
| **Docker** (required) | [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) | [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) | Engine + Compose plugin |
| Volta + Node 22 + pnpm | `curl https://get.volta.sh \\| bash` then `volta install node@22` and `volta install pnpm` | installer from volta.sh | same as macOS |
| uv + Python 3.12 | `curl -LsSf https://astral.sh/uv/install.sh \\| sh` then `uv python install 3.12` | PowerShell installer from [uv](https://docs.astral.sh/uv/) | same as macOS |
| Make | `xcode-select --install` or `brew install make` | WSL2: `sudo apt install make` | `sudo apt install make` |"""
    tools_id = """| Git | `xcode-select --install` atau git-scm | Git for Windows | `sudo apt install git` |
| **Docker** (wajib) | Docker Desktop | Docker Desktop | Engine + plugin Compose |
| Volta + Node 22 + pnpm | `curl https://get.volta.sh \\| bash` lalu `volta install node@22` dan `volta install pnpm` | installer volta.sh | sama seperti macOS |
| uv + Python 3.12 | `curl -LsSf https://astral.sh/uv/install.sh \\| sh` lalu `uv python install 3.12` | installer PowerShell uv | sama seperti macOS |
| Make | CLT atau `brew install make` | WSL2: `sudo apt install make` | `sudo apt install make` |"""
    spring_en = ""
    spring_id = ""
    be_env_en = f"- Python: `{be_path}/settings.yaml`, `settings.{{local,dev,prod}}.yaml`, `.env.*.example`"
    be_env_id = f"- Python: `{be_path}/settings.yaml`, `settings.{{local,dev,prod}}.yaml`, `.env.*.example`"
    install_en = f"`make install` installs `{fe_path}` (pnpm) and `{be_path}` (uv)."
    install_id = f"`make install` meng-install `{fe_path}` (pnpm) dan `{be_path}` (uv)."
else:
    tools_en = """| Git | `xcode-select --install` or [git-scm](https://git-scm.com) | [Git for Windows](https://git-scm.com) | `sudo apt install git` |
| **Docker** (required) | [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) | [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) | Engine + Compose plugin |
| Volta + Node 22 + pnpm | `curl https://get.volta.sh \\| bash` then `volta install node@22` and `volta install pnpm` | installer from volta.sh | same as macOS |
| Make | `xcode-select --install` or `brew install make` | WSL2: `sudo apt install make` | `sudo apt install make` |
| IntelliJ IDEA + JDK 21 | IntelliJ can download JDK 21 | same | same |"""
    tools_id = """| Git | `xcode-select --install` atau git-scm | Git for Windows | `sudo apt install git` |
| **Docker** (wajib) | Docker Desktop | Docker Desktop | Engine + plugin Compose |
| Volta + Node 22 + pnpm | `curl https://get.volta.sh \\| bash` lalu `volta install node@22` dan `volta install pnpm` | installer volta.sh | sama seperti macOS |
| Make | CLT atau `brew install make` | WSL2: `sudo apt install make` | `sudo apt install make` |
| IntelliJ IDEA + JDK 21 | JDK 21 bisa diunduh dari IntelliJ | sama | sama |"""
    spring_en = """
For Spring, open this project in IntelliJ IDEA, then use **File → Project
Structure → SDK → Download JDK** and select version 21. Set the same JDK under
**Settings → Build Tools → Gradle → Gradle JVM**. The scripts automatically
detect IntelliJ-downloaded JDKs in `~/.jdks`.
"""
    spring_id = """
Untuk Spring, buka project ini di IntelliJ IDEA lalu pilih **File → Project
Structure → SDK → Download JDK** dan gunakan versi 21. Pilih JDK yang sama di
**Settings → Build Tools → Gradle → Gradle JVM**. Script otomatis mencari JDK
yang diunduh IntelliJ di `~/.jdks`.
"""
    be_env_en = f"- Spring: `{be_path}/application.yml` and `application-{{local,dev,prod}}.yml`"
    be_env_id = f"- Spring: `{be_path}/application.yml` dan `application-{{local,dev,prod}}.yml`"
    install_en = f"`make install` installs `{fe_path}` (pnpm). Gradle downloads on first `make run` / `make test`."
    install_id = f"`make install` meng-install `{fe_path}` (pnpm). Gradle diunduh saat `make run` / `make test` pertama."

readme_en = f"""# {app_name}

English README. [Bahasa Indonesia](README.id.md)

This folder is one cloned app: **{fe_label}** + **{llm_title}** + **{be_label}**.
Docker Compose in `{docker_path}` runs Postgres and Ollama (`{ollama_model}`).

## What you need first

| Tool | macOS | Windows | Linux |
|---|---|---|---|
{tools_en}

Check: `git --version`, `docker --version`, `docker compose version`, `node --version`, `pnpm --version`, `make --version`.
{"Also `uv --version`." if be == "python" else "Also `java -version` (21)."}

`make run`, `make test`, and `make test-e2e` print a tool check first. Docker Desktop/Engine must be **running** before `make run`.
{spring_en}
## This stack

| Part | Path |
|---|---|
| Frontend | `{fe_path}` ({fe_label}) |
| Backend | `{be_path}` ({be_label}) |
| Docker | `{docker_path}/compose.yml` (Postgres + Ollama) |
| Model | `{ollama_model}` — {about_en} |

RAM (host + Docker): about **{ram} GB**. Weight {weight}{" · " + vendor if vendor else ""}{" · " + license if license else ""}.

## Run

From **this folder** (not the template):

```bash
make run
```

Env **local** by default. Other envs:

```bash
make run local
make run dev
make run prod
```

Backend only, then frontend in another terminal:

```bash
make run local no-fe {slug} {be}
make run-fe
```

There is no `make clone` here and no extra combo args. This app is already {fe} + {slug} + {be}.

Open http://localhost:3000 (UI). API Swagger is http://localhost:8000/docs on local/dev. Prod has no Swagger; use http://localhost:8000/api/health.

## Test

Keep `make run` going in another terminal for e2e and smoke:

```bash
make test
make test-e2e
make smoke
make down
```

Same env flag as run:

```bash
make test local
make test-e2e local
make smoke dev
make down
```

E2E credentials: copy `{fe_path}/e2e.env.example` to `{fe_path}/e2e.env`.

{install_en}

## Commands

| Make | What it does |
|---|---|
| `make run` | docker + backend + frontend (env=local) |
| `make run local\\|dev\\|prod` | same stack, chosen env |
| `make run local no-fe {slug} {be}` | docker + backend only |
| `make run-fe` | frontend only; backend must already be up |
| `make test` | unit tests for {fe_label} + {be_label} |
| `make test-e2e` | Playwright against the running UI |
| `make smoke` | health checks (API, UI, Ollama) |
| `make down` | stop Docker for `{slug}` |
| `make install` | install this stack only |
| `make build` / `make lint` / `make format` | this stack |

Without Make: `./scripts/run.sh`, `./scripts/run.sh local`, `./scripts/test.sh`.

## Envs

There is no root `.env`. Each service owns `local` / `dev` / `prod` files:

- Frontend: `{fe_path}/.env.local.example` / `.env.dev.example` / `.env.prod.example`
{be_env_en}
- LLM about page: `{fe_path}/llm/{slug}.json`. `make run` rewrites `{fe_path}/public/llm.active.json`
"""

readme_id = f"""# {app_name}

README Bahasa Indonesia. [English](README.md)

Folder ini satu app hasil clone: **{fe_label}** + **{llm_title}** + **{be_label}**.
Docker Compose di `{docker_path}` menjalankan Postgres dan Ollama (`{ollama_model}`).

## Yang perlu dipasang dulu

| Tool | macOS | Windows | Linux |
|---|---|---|---|
{tools_id}

Cek: `git --version`, `docker --version`, `docker compose version`, `node --version`, `pnpm --version`, `make --version`.
{"Juga `uv --version`." if be == "python" else "Juga `java -version` (21)."}

`make run`, `make test`, dan `make test-e2e` menampilkan cek tool dulu. Docker harus **menyala** sebelum `make run`.
{spring_id}
## Stack ini

| Bagian | Path |
|---|---|
| Frontend | `{fe_path}` ({fe_label}) |
| Backend | `{be_path}` ({be_label}) |
| Docker | `{docker_path}/compose.yml` (Postgres + Ollama) |
| Model | `{ollama_model}` — {about_id} |

RAM (host + Docker): sekitar **{ram} GB**. Bobot {weight}{" · " + vendor if vendor else ""}{" · " + license if license else ""}.

## Jalanin

Dari **folder ini** (bukan template):

```bash
make run
```

Env default **local**. Env lain:

```bash
make run local
make run dev
make run prod
```

Backend saja, lalu frontend di terminal lain:

```bash
make run local no-fe {slug} {be}
make run-fe
```

Tidak ada `make clone` di sini dan tidak ada argumen combo. App ini sudah {fe} + {slug} + {be}.

Buka http://localhost:3000 (UI). Swagger API: http://localhost:8000/docs di local/dev. Prod tidak punya Swagger; pakai http://localhost:8000/api/health.

## Test

Biarkan `make run` jalan di terminal lain untuk e2e dan smoke:

```bash
make test
make test-e2e
make smoke
make down
```

Flag env sama seperti run:

```bash
make test local
make test-e2e local
make smoke dev
make down
```

Kredensial E2E: salin `{fe_path}/e2e.env.example` ke `{fe_path}/e2e.env`.

{install_id}

## Perintah

Sama seperti README English: `make run`, `make run local|dev|prod`, `make run-fe`, `make test`, `make test-e2e`, `make smoke`, `make down`, `make install`, `make build`, `make lint`, `make format`.

Tanpa Make: `./scripts/run.sh`, `./scripts/run.sh local`, `./scripts/test.sh`.

## Env

Tidak ada `.env` di root. Tiap service punya file `local` / `dev` / `prod`:

- Frontend: `{fe_path}/.env.local.example` / `.env.dev.example` / `.env.prod.example`
{be_env_id}
- Halaman about LLM: `{fe_path}/llm/{slug}.json`. `make run` menulis ulang `{fe_path}/public/llm.active.json`
"""

help_txt = f"""make run              start {fe} + {slug} + {be} (env=local)
make run local|dev|prod
make run local no-fe {slug} {be}
make run-fe           frontend only; backend must already be up
make test             unit tests for this stack
make test-e2e         Playwright; keep backend + frontend going
make smoke            health checks; keep backend + frontend going
make down             stop docker {slug}
make install          pnpm in {fe_path}{" + uv sync in " + be_path if be == "python" else ""}
make build / lint / format
This cloned app has no make clone. Stack is already {fe} + {slug} + {be}.
"""

(root / "README.md").write_text(readme_en.strip() + "\n", encoding="utf-8")
(root / "README.id.md").write_text(readme_id.strip() + "\n", encoding="utf-8")
(root / "scripts" / "help.sh").write_text(
    "#!/usr/bin/env bash\nset -euo pipefail\ncat <<'EOF'\n"
    + help_txt
    + "EOF\n",
    encoding="utf-8",
)
print(f"Wrote README.md, README.id.md, and scripts/help.sh for {app_name} ({fe} + {slug} + {be})")
PY
chmod +x "$ROOT/scripts/help.sh"
