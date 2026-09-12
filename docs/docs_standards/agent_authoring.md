# Agent Authoring Standards

## Overview

This document defines what a Claude Code subagent in this repository must contain, how it is named, how its model and tools are chosen, and how it is validated.
It follows the [Claude Code subagent documentation](https://code.claude.com/docs/en/sub-agents) and adds this repository's own conventions on top of it.
Every rule here is enforced by `just ci` unless the text says otherwise.

An agent is a role with a system prompt, a model, a tool allowance, and a set of preloaded skills.
A skill is a rule set that any agent tool can load.
Keep that division: an agent says who is acting and with what, and the skills it preloads say how.

## Directory Layout

Each agent is one file, `agents/<agent-name>.md`, and the filename without its extension is the agent's address.
Claude Code addresses the agent by that name, so renaming the file is a breaking change for anyone who has typed it into a workflow or a project-level override.

- [`agents/README.md`](../../agents/README.md) is the index and must link every agent; `just validate-agents` fails when one is missing.
- `just install` links the whole directory to `~/.claude/agents`, so a new file needs no installer change.
- A project overrides an agent by placing a file with the same name under its own `.claude/agents/`, which is where a version that names one codebase's recipes and identifiers belongs.

Agent names use lowercase kebab-case and read as a role: `reviewer`, `spec-author`.

## Frontmatter Contract

Every agent file opens with YAML frontmatter delimited by `---` lines.

- `name` is required and must exactly match the filename without its extension.
- `description` is required and is the routing text Claude Code uses to decide when to delegate to the agent.
- `model` is required by this repository, though Claude Code treats it as optional, and must be `sonnet`, `opus`, `haiku`, `inherit`, or a full `claude-*` model identifier.
  Prefer an alias so the agent tracks the current release of its tier.
- `tools` is a comma-separated allowlist of tool names, and `disallowedTools` a denylist; omit both to inherit every tool.
- `skills` is a YAML list of skill names, each of which must exist as `skills/<name>/SKILL.md`.
  Claude Code preloads the full text of each named skill into the agent's context at start, so every entry is paid for on every run.
- `permissionMode`, `memory`, `isolation`, `maxTurns`, `mcpServers`, and `hooks` are recognized and checked against the values Claude Code documents.

Any other key is reported as a warning rather than an error, because Claude Code adds frontmatter fields on its own schedule.
Treat a warning as a prompt to check for a typo before assuming the key is a new upstream field.

## Writing the Description

The description is read by the model, not by a person scanning a list, so it is routing text and is written as such.

- Open with one sentence saying what the agent produces.
- Add one sentence beginning "Use this agent when ..." that says the situation it is for.
- Write "Use proactively ..." instead when the main session should delegate without being asked, as the reviewer does after a change is written.
- Keep it under three sentences, and do not compare the agent to its siblings; distinct descriptions route better than descriptions that argue.

## Choosing the Model

Choose the model by what a mistake costs, not by what the agent is called.

- `opus` for roles where judgment is the product and a miss is expensive: implementation against a specification, adversarial review, and planning.
- `sonnet` for roles bounded by written conventions and a lint gate that catches drift: research, specification authoring, and feature authoring.
- `haiku` for a narrow agent that only searches or reformats and whose output is checked by something else.

Record the choice and its reason in [`agents/README.md`](../../agents/README.md), so a reader can disagree with the reasoning rather than guess at it.

## Choosing the Tools

Give an agent the smallest tool allowance its role needs, and state the prohibition in the body as well, because a tool list limits what the agent can call but the shell can still write files.

- A role that must not change the workspace, such as the reviewer or the researcher, lists read tools plus `Bash` for running checks, and its body says not to use the shell to edit.
- A role that writes only one kind of file, such as the planner or an author, lists read tools plus `Write` and `Edit`, and its body names the files it may touch.
- A role that implements code omits `tools` and inherits the full set.

## Body Structure

The body is the agent's system prompt and is held to the repository's documentation conventions, including a single H1 with no content beneath it before the first H2, content under every heading, and one sentence per line.

- Open with an H2 that states the role in one or two sentences.
- Follow with the steps to take before starting, the working rules, and how to finish and report, each under its own H2.
- Write imperative instructions aimed at the agent, and state prohibitions explicitly, because an agent follows a stated prohibition far more reliably than an implied one.
- Tell the agent to read the repository's `meta.md`, `AGENTS.md`, and `AGENTS.override.md` first and to follow them over the prompt, so the portable agent defers to the codebase it is running in.
- Do not restate a rule that lives in a preloaded skill; if the rule is missing from the skill, add it there so every tool that reads the skill sees it.
- Keep the body under about eighty lines; an agent that needs more is carrying content that belongs in a skill.

An agent file carries no HTML comments and no per-file license line, for the same reasons a skill file carries none: the file is loaded as raw text, and licensing is stated in [LICENSE](../../LICENSE).

## Portability Across Repositories

An agent here must work in any repository it is started in.

- Discover the task runner and its recipes rather than naming one repository's `just` recipes as fact; name a recipe only as an example.
- Refer to documentation by the places repositories conventionally keep it, and defer to the repository's own instruction files for the authoritative locations.
- Do not name a private repository, a machine, or an absolute path.
- Claude Code loads the project's instruction files into a subagent automatically, so the body need not repeat them.

## Validation

Run the full local gate before committing an agent change.

- `just validate-agents` checks frontmatter, naming, model and tool values, preloaded skills, the body opening, comments, and the index.
- `just lint-md agents/<agent-name>.md` applies Markdown fixes and reports what it cannot fix.
- `just ci` runs every check that CI runs.
