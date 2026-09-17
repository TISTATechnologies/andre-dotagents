# dotagents dev environment and scripting.
# Run `just` for a list of recipes. Requires: https://github.com/casey/just
# shellcheck disable=SC2148,SC1007
# (justfile: not a shell script; recipe bodies are run by just with set shell)

set shell := ["bash", "-euo", "pipefail", "-c"]
set tempdir := "/tmp"

export JUST_TEMPDIR := env_var_or_default("JUST_TEMPDIR", "/tmp")
export NPM_CONFIG_CACHE := env_var_or_default("NPM_CONFIG_CACHE", "/tmp/agents-npm-cache")

# Directory containing this justfile (repository root).
root_dir := justfile_directory()

# Show list of available recipes (same as just --list).
default:
    @just --list

# Install the tooling the checks below need.
setup: install-markdownlint
    @echo "Setup complete. Run: just ci"

# Local CI: everything that gates a merge in this repository.
ci: docs-check validate-skills validate-agents validate-skills-spec test-python lint-sh
    @:

# All documentation checks: Markdown lint plus internal link validation.
docs-check: lint-md validate-doc-links
    @:

# Install markdownlint-cli2 custom rules into .markdownlint-rules (for lint-md).
install-markdownlint:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}"
    RULES_DIR=".markdownlint-rules"
    REPO_DIR=".markdownlint-repo"
    REPO_URL="https://github.com/cypher0n3/docs-as-code-tools.git"
    command -v markdownlint-cli2 >/dev/null 2>&1 || {
        echo "Error: markdownlint-cli2 not found. Install it (npm i -g markdownlint-cli2) and retry."
        exit 1
    }
    command -v git >/dev/null 2>&1 || { echo "Error: git required."; exit 1; }
    if [ ! -d "$REPO_DIR" ]; then
        git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    else
        git -C "$REPO_DIR" fetch origin main
        git -C "$REPO_DIR" merge --ff-only origin/main || true
    fi
    ln -sfn "$REPO_DIR/markdownlint-rules" "$RULES_DIR"
    echo "Custom markdownlint rules installed in $RULES_DIR."

# Lint Markdown and apply automatic fixes. Pass paths or omit for the whole repo.
lint-md *PATHS:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}"
    if [ ! -e ".markdownlint-rules" ]; then
        echo "Error: .markdownlint-rules missing. Run: just install-markdownlint"
        exit 1
    fi
    if [ -z "{{ PATHS }}" ]; then
        markdownlint-cli2 --fix '**/*.md'
    else
        markdownlint-cli2 --fix {{ PATHS }}
    fi

# Validate skill frontmatter, naming, and agent manifests.
validate-skills:
    @python3 "{{ root_dir }}/.ci_scripts/validate_skills.py" "{{ root_dir }}/skills"

# Validate Claude Code agent frontmatter, preloaded skills, and the agent index.
validate-agents:
    @python3 "{{ root_dir }}/.ci_scripts/validate_agents.py" "{{ root_dir }}/agents" "{{ root_dir }}/skills"

# Validate skills against the Agent Skills spec (skills-ref). Skipped when skills-ref is absent.
validate-skills-spec:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}"
    if ! command -v skills-ref >/dev/null 2>&1; then
        echo "skills-ref not installed; skipping specification validation."
        echo "See https://github.com/agentskills/agentskills for the reference library."
        exit 0
    fi
    status=0
    for skill in skills/*/; do
        skills-ref validate "$skill" || status=1
    done
    exit "$status"

# Validate relative Markdown links and heading anchors across the repository.
validate-doc-links:
    @python3 "{{ root_dir }}/.ci_scripts/validate_doc_links.py" "{{ root_dir }}"

# Run the offline Python unit tests for the CI helper scripts.
test-python:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}/.ci_scripts"
    python3 -m unittest discover -p 'test_*.py'

# Lint the repository's shell scripts (shellcheck). Skipped with a notice when shellcheck is absent.
lint-sh:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}"
    if ! command -v shellcheck >/dev/null 2>&1; then
        echo "shellcheck not installed; skipping shell lint."
        exit 0
    fi
    shellcheck scripts/*.sh claude/*.sh cursor/*.sh

# Link the skills, Claude agents, and global AGENTS.md into ~/.claude, ~/.cursor, ~/.gemini, ~/.codex, and ~/.grok.
install *ARGS:
    @bash "{{ root_dir }}/scripts/install.sh" {{ ARGS }}

# Show what `just install` would link, without changing anything.
install-dry-run:
    @bash "{{ root_dir }}/scripts/install.sh" --dry-run

# Remove locally installed lint tooling and caches.
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ root_dir }}"
    rm -rf .markdownlint-repo .markdownlint-rules .ci_scripts/__pycache__
    echo "Removed local lint tooling and caches."
