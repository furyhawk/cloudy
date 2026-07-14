# AGENTS.md

## Purpose
- This repository is primarily infrastructure-as-code for Docker Compose, Docker Swarm, Kubernetes, Helm, and Ansible.
- There is also a small Python Flask service in `webhook/` and a Streamlit app in `src/`.
- Prefer narrow, low-risk edits. Many files are deployment manifests where a small typo can break production behavior.

## Agent Priorities
- Preserve the existing structure and conventions of the file you are editing.
- Favor minimal diffs over broad refactors.
- Do not rotate secrets, change domains, or alter deployment targets unless the task explicitly requires it.
- Treat `archive/` as historical unless the task explicitly mentions it.
- When changing runtime configuration, update only the active path (`compose/`, `swarm/`, `cluster/`, `ansible/`, `webhook/`, `src/`) relevant to the request.

## Rule Files
- No `.cursor/rules/` directory was found.
- No `.cursorrules` file was found.
- No `.github/copilot-instructions.md` file was found.
- This file therefore acts as the main agent guidance for the repository.

## Repository Areas
- `makefile`: top-level operator commands for Compose and Swarm deploys.
- `compose.yml` + `compose/`: Docker Compose configuration assembled via `include:`.
- `swarm/`: Docker Swarm stacks, environment-driven labels, and Traefik config.
- `cluster/`: Kubernetes manifests and Helm charts.
- `ansible/`: playbooks and RKE2 automation.
- `webhook/`: Poetry-managed Flask app.
- `src/`: Streamlit app and Python requirements.
- `scripts/`: setup, build, and smoke-test scripts.

## Build Commands
- Full local compose stack: `make serve`
- Stop local compose stack: `make down`
- Validate merged compose config: `docker compose -f compose.yml config`
- Bring local compose stack up manually: `docker compose -f compose.yml up -d --build --pull always`
- Legacy CI-style compose build path: `./scripts/build.sh`
- Local Streamlit app only: `streamlit run src/app.py`
- Local webhook app only: `cd webhook && poetry run python http_server.py`
- Swarm core deploy: `make deploy-core`
- Swarm app deploy: `make deploy-apps`
- Swarm services deploy: `make deploy-services`
- Ansible RKE2 cluster bootstrap: `cd ansible/rke2 && ansible-playbook site.yaml -i inventory/hosts.ini --key-file ~/.ssh/id_rsa -K`

## Fast Debug Workflow
- Use this order for quicker triage: identify failing unit -> inspect recent logs -> verify rendered config -> apply smallest restart.
- Find suspect Swarm services quickly: `docker service ls`
- Inspect service state and recent task failures: `docker service ps <service> --no-trunc`
- Tail recent service logs with timestamps: `docker service logs --since 10m <service>`
- Follow logs live during a rollout: `docker service logs -f <service>`
- Restart only one service after config changes: `docker service update --force <service>`
- Confirm service converged after update: `docker service ps <service>`
- Validate compose syntax and env interpolation before deploy: `docker compose -f compose.yml config`
- Render a Swarm stack file locally for sanity checks: `docker compose -f swarm/<stack>.yml config`
- For SearXNG specifically, runtime config is host-mounted at `/var/data/config/searxng`; repo edits in `swarm/searxng/` require syncing to host path before restart.
- For Traefik/router issues, verify labels and entrypoints first, then check `traefik` service logs before changing domains or ports.
- Prefer `--since 5m` or `--since 10m` during incident response to avoid scanning stale logs.

## Lint And Validation Commands
- There is no repo-wide lint target or CI workflow checked into the repository.
- There are no configured `ruff`, `black`, `flake8`, `mypy`, `yamllint`, `ansible-lint`, or `pytest` configs in the root.
- Use syntax and render validation that matches the area you changed.
- Compose validation: `docker compose -f compose.yml config`
- Swarm file validation: `docker stack deploy --compose-file ./swarm/<stack>.yml <stack> --dry-run` is not available in Docker Swarm, so use `docker compose config` patterns where possible and review label/env interpolation carefully.
- Helm chart render check: `helm template test-release cluster/coder-chart`
- Helm chart lint check: `helm lint cluster/coder-chart`
- Helm dependency check for `cluster/code-server`: `helm dependency update cluster/code-server`
- Kubernetes manifest spot check: `kubectl apply --dry-run=client -f <file>`
- Ansible syntax check: `ansible-playbook --syntax-check <playbook> -i <inventory>`
- Python webhook dependency install: `cd webhook && poetry install`
- Python webhook quick import/run check: `cd webhook && poetry run python http_server.py`

## Test Commands
- Main end-to-end smoke test script: `./scripts/test.sh`
- Legacy CI path: `./scripts/travis.sh`
- The smoke test expects a populated `.env`, reachable hosts, and a running local Traefik/Compose environment.
- It verifies redirects and dashboard auth using values from `.env`.
- Helm chart test hook exists for `cluster/coder-chart`; after install, run: `helm test <release-name>`
- There are example/test deployment files under `test/`, but no unified automated test runner is wired to them.
- There are currently no checked-in Python unit tests for `webhook/` or `src/`.

## Running A Single Test
- There is no first-class single-test command for the main smoke suite in `./scripts/test.sh`; it is a single shell script.
- To run one smoke assertion, copy the relevant `curl` command from `./scripts/test.sh` and execute it directly.
- For Helm, the narrowest useful check is a single chart render/lint:
- `helm lint cluster/coder-chart`
- `helm template test-release cluster/coder-chart`
- For a single Kubernetes manifest, use: `kubectl apply --dry-run=client -f path/to/file.yaml`
- For a single Ansible playbook, use: `ansible-playbook --syntax-check path/to/playbook.yml -i inventory`
- If Python tests are added later, the expected targeted form would be: `cd webhook && poetry run pytest path/to/test_file.py::test_name`
- Do not claim pytest support exists today unless you also add the test dependency and test files.

## Working Safely With Config
- Many YAML files interpolate env vars like `${DOMAINNAME}`, `${POSTGRES_PASSWORD}`, or `${VAR?Variable not set}`.
- Preserve existing variable names exactly; accidental renames will break deployments.
- Prefer existing anchors and aliases, such as `x-environment` blocks, over duplicating env declarations.
- Preserve quoting style when editing Traefik labels or shell-sensitive strings.
- Be careful with `$` escaping inside labels and regex replacements.
- Avoid changing published ports, hostnames, or Traefik router rules unless explicitly requested.

## Code Style: General
- Match the local style of the file you touch rather than imposing a new formatter.
- Keep YAML keys, Helm templates, and Ansible tasks visually aligned and easy to scan.
- Prefer small, direct changes over restructuring files.
- Keep comments only when they explain a non-obvious operational constraint.
- Reuse existing naming patterns like `api_server`, `postgres_db`, `streamlit-fin`, and `deploy-core`.
- Preserve file-specific indentation conventions: YAML uses spaces, Make uses tabs for recipe lines, shell scripts use the existing shell style.

## Imports
- In Python, keep imports at the top of the file.
- Prefer standard library imports first, then third-party imports.
- Avoid unused imports.
- Follow the existing concise import style unless you are already refactoring the file for readability.
- When touching `webhook/http_server.py` or `src/app.py`, it is acceptable to improve import ordering if part of a necessary edit.

## Formatting
- YAML: two-space indentation, no tab characters.
- Helm templates: preserve current whitespace trimming markers like `{{-` and `-}}`.
- Python: use four-space indentation even though some existing files are inconsistent.
- Shell: keep `set -e` or `set -ev` when present; do not remove safety flags casually.
- Markdown: keep bullets short and operational.
- Do not introduce large-scale formatting churn in files that are otherwise working.

## Types And Data Shapes
- Python code in this repo is lightly typed today; there is no mypy configuration.
- Add type hints when they clarify new or changed Python logic, but do not force a repo-wide typing conversion.
- For YAML, respect the existing scalar style and only quote when interpolation, special characters, or parser ambiguity require it.
- Keep environment values as strings unless the target format clearly expects booleans or integers.
- In Helm values and templates, preserve the expected shape of objects and lists; changing key structure is usually a breaking change.

## Naming Conventions
- Docker Compose services commonly use snake_case or hyphenated names already established in the file; follow the surrounding pattern.
- Ansible task names should be descriptive imperative phrases.
- Kubernetes resource names should stay lowercase and DNS-safe.
- Python function names should be `snake_case`.
- Python constants and environment variable names should be uppercase.
- Keep public-facing hostnames and router names consistent with nearby services.

## Error Handling
- Do not swallow errors silently in new Python code.
- Avoid bare `except:`; catch specific exceptions where practical.
- Return clear HTTP responses in Flask handlers.
- In shell scripts, prefer failing fast over ignoring command failures.
- In Ansible, use `register`, `when`, and `changed_when` intentionally; do not mark tasks changed without a reason.
- In deployment config, prefer explicit required vars like `${VAR?Variable not set}` for critical settings.

## Python-Specific Notes
- `webhook/http_server.py` currently uses minimal Flask code and would benefit from improved formatting and more explicit error handling when modified.
- `src/app.py` contains Streamlit logic with some inconsistent spacing and a bare `except:`; fix such issues only when your change touches that area.
- Preserve current runtime entrypoints unless the task explicitly changes startup behavior.

## Ansible-Specific Notes
- Prefer fully qualified module names such as `ansible.builtin.command` where the surrounding file already uses them.
- Keep playbooks idempotent where possible.
- Avoid unnecessary `shell` usage when `command`, `template`, `copy`, or dedicated modules work.
- Respect existing inventory and variable layout under `ansible/rke2/inventory/`.
- Be cautious with `become_user`, `changed_when`, and cluster bootstrap sequencing.

## Helm And Kubernetes Notes
- Render Helm templates locally before making broad chart changes.
- Preserve helper usage like `include`, `toYaml`, `nindent`, and existing label helpers.
- Avoid renaming values keys unless you also update every template consumer.
- Maintain probe, volume, and securityContext structure unless there is a concrete reason to change them.
- For plain manifests, keep apiVersion, kind, metadata, and spec ordering consistent with nearby files.

## Docker And Traefik Notes
- Traefik labels are heavily used and are sensitive to quoting and interpolation.
- Keep router, middleware, and service label names consistent across related files.
- Prefer extending shared env blocks and shared network definitions over one-off duplication.
- Be careful with `host-gateway`, mounted Docker sockets, and certificate storage paths.
- Do not commit real secrets into compose, swarm, or manifest files.

## When Unsure
- Validate the smallest affected surface first.
- Prefer commands that only render or syntax-check before commands that deploy.
- If a task spans multiple deployment systems, confirm which path is active before editing all of them.
- Document assumptions in the final response if the repo does not provide a definitive source of truth.
