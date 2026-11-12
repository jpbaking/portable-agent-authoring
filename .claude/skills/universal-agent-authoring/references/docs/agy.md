# Antigravity CLI (`agy`) guide

Verified against current Google documentation and the Antigravity CLI
changelog on 2026-11-08. Observed locally with `agy` 1.5.3.

> **Type:** `agy` is a terminal harness—the CLI surface that hosts and
> orchestrates Antigravity agents. It is not itself a custom agent definition.
> This guide targets Antigravity CLI, not every behavior of the Antigravity
> desktop app or IDE. Gemini CLI is a separate harness; see the
> [Gemini CLI guide](gemini.md).

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent instructions | `AGENTS.md`, `GEMINI.md`, `.agents/AGENTS.md`, or `.agents/GEMINI.md` in the workspace and each parent up to the repository root | `~/.gemini/AGENTS.md` or `~/.gemini/GEMINI.md` (also `~/.gemini/config/AGENTS.md` / `GEMINI.md`) |
| Modular rules | `.agents/rules/*.md` (legacy `.agent/rules/`) | `~/.gemini/config/rules/*.md` |
| Agent Skills | `.agents/skills/<name>/SKILL.md` in the workspace and each parent up to the repository root (legacy `.agent/skills`) | `~/.gemini/antigravity-cli/skills/<name>/`, `~/.gemini/skills/<name>/`, or `~/.gemini/config/skills/<name>/` |
| Custom agents | `.agents/agents/` | `~/.gemini/config/agents/` |
| Plugins | `.agents/plugins/<name>/` | `~/.gemini/config/plugins/<name>/` |
| MCP servers | `.agents/mcp_config.json` | `~/.gemini/config/mcp_config.json` |

For universal projects, use `AGENTS.md` and `.agents/skills`. Do not add a
`GEMINI.md` copy containing the same rules.

`agy` does not read workspace `.gemini/skills/`; the migration guide says to
relocate those folders to `.agents/skills/`. It also does not document reading
a workspace `.gemini/settings.json`, so the Gemini CLI adapter in the
universal layout does not affect it.

## Rules

`AGENTS.md` and `GEMINI.md` carry no frontmatter and are always active. Rules
are cumulative across levels rather than replacement-based, and the docs do
not state which file wins when both exist in one folder—another reason to keep
only `AGENTS.md`. Rules are not loaded from subfolders below the workspace
folder.

Files under `.agents/rules/` need frontmatter with a valid `trigger`, or
Antigravity silently discards them:

| `trigger` | Behavior |
| --- | --- |
| `always_on` | Full content every turn |
| `model_decision` | Path and required `description` first; full rule read when relevant |
| `glob` | Activates when files matching required `globs` are touched |
| `manual` | `@` mention only; the CLI does not support rule mentions |

These activation settings are host adapters, not portable rule metadata.

Limits: each rule file is truncated at 24,000 bytes (after includes are
expanded), and all global and `always_on` rules share a 20,000-token budget.
Over budget, the largest files are demoted to path-and-description pointers.

Global `agy` guidance belongs in `~/.gemini/GEMINI.md` or
`~/.gemini/AGENTS.md`. `~/.gemini/GEMINI.md` is also Gemini CLI's global
context file, so one file can serve both Google harnesses. Keep user-global
rules short and do not duplicate project instructions there.

Antigravity permissions are a separate enforcement layer. Do not translate
allow, ask, or deny entries into prompt rules.

## Skills

Use a standard skill directory:

```text
.agents/skills/review-api/
  SKILL.md
  references/
  scripts/
  assets/
```

Minimum frontmatter:

```yaml
---
name: review-api
description: Reviews API changes for compatibility and security. Use for API implementation or review requests.
---
```

The docs mark `name` optional (defaulting to the folder name) and
`description` required, but `agy`'s own validator warns when `name` is
missing or does not match its folder, and when a `SKILL.md` body exceeds
24 KB. Always include both fields.

The agent sees skill metadata first and reads the full `SKILL.md` when the task
matches. Each skill is also a slash command in the TUI, such as `/review-api`.
After adding a skill mid-session, run `/skills reload`.

The docs do not state a precedence order for the same skill name in several
locations. Audit workspace, global, and plugin skills for duplicates.

## Workflows

Antigravity's workflow feature is now documented under the IDE, with a
"Workflows to Skills" migration guide, and `agy plugin validate` warns that
plugins do not load `workflows/` Markdown files. Make the Agent Skill
authoritative for any cross-harness procedure. Keep an Antigravity-only
workflow only when it adds orchestration that a skill cannot express.

## Global skill path choice

`agy` reads three global skill folders. `~/.gemini/skills/` is also a Gemini
CLI user skill folder, so installing into it makes both Google harnesses see
the skill—and makes Gemini CLI list a duplicate if the same skill is also in
`~/.agents/skills/`. For a user-global mirror, prefer the CLI-specific
`~/.gemini/antigravity-cli/skills/`.

## Universal layout

`agy` needs no rule or skill shim:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

`CLAUDE.md`, `.claude/skills`, and `.gemini/settings.json` are irrelevant to
`agy`. Do not instruct `agy` through `AGENTS.md` to scan a non-native skill
directory; that would not register the skills with the harness.

## Validate

1. Start a fresh `agy` session from the intended project root.
2. Ask the agent to summarize the loaded `AGENTS.md` rules; check `/context`
   for the loaded files.
3. Run `/skills`; confirm the skill is listed once and resolves to
   `.agents/skills`.
4. Invoke `/skill-name`, then try a natural-language prompt matching the
   description.
5. Keep `GEMINI.md`, `.agents/rules`, and plugin rules from duplicating the same
   semantic body.

## Official sources

- [Antigravity CLI overview](https://antigravity.google/docs/cli-overview)
- [Migrating from Gemini CLI](https://antigravity.google/docs/cli/gcli-migration)
- [Agent Skills](https://antigravity.google/docs/skills)
- [Rules](https://antigravity.google/docs/rules)
- [Plugins](https://antigravity.google/docs/plugins?tab=cli)
- [CLI permissions](https://antigravity.google/docs/cli-permissions)
- [Antigravity CLI changelog](https://raw.githubusercontent.com/google-antigravity/antigravity-cli/refs/heads/main/CHANGELOG.md)
