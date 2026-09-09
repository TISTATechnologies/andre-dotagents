# CI Scripts

## Overview

These are the validation helpers that [`justfile`](../justfile) recipes and CI call.
They are Python 3 standard library only, so they run without a virtual environment or any installed package.

## Scripts

- [`validate_skills.py`](validate_skills.py) - checks that every skill directory has a `SKILL.md` with well-formed frontmatter, a `name` matching its directory, valid boolean flags, an H1 body opening, no HTML comments outside fenced code blocks, and a complete `agents/openai.yaml` when one is present.
  Field names and length limits follow the [Agent Skills specification](https://agentskills.io/specification), and the specification's advisory size guidance of 500 lines and roughly 5000 tokens is reported as a warning rather than an error.
  Unrecognized frontmatter keys are warnings, because agent tools add fields over time.
- [`validate_doc_links.py`](validate_doc_links.py) - checks that every relative Markdown link resolves on disk and that every heading anchor it carries exists in the target document.
  External links are not fetched.

## Tests

Each script has an offline unit test beside it, named `test_<script>.py`, using only `unittest`.
Run them with `just test-python`, which discovers every `test_*.py` in this directory.

## Conventions

Keep these scripts dependency-free so that a fresh clone can run `just ci` with nothing installed but `just`, `python3`, and `markdownlint-cli2`.
A check that needs a third-party package belongs in a separate recipe that states its own prerequisite.
