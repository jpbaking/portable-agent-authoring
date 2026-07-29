# Antigravity CLI (`agy`) guide

Verified against current Google documentation on 2026-07-29. The locally
available `agy` 1.1.8 binary was also checked for its advertised discovery
templates.

> **Type:** `agy` is a terminal harness—the CLI surface that hosts and
> orchestrates Antigravity agents. It is not itself a custom agent definition.
> This guide targets Antigravity CLI, not every behavior of the Antigravity 2.0
> desktop application.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent instructions | `AGENTS.md` or `GEMINI.md` | `~/.gemini/GEMINI.md` |
| Agent Skills | `.agents/skills/<name>/SKILL.md` | `~/.gemini/antigravity-cli/skills/<name>/SKILL.md` |
| Custom agents | `.agents/agents/<name>/agent.md` | `~/.gemini/config/agents/<name>/agent.md` |
| Plugins | `.agents/plugins/<name>/` | `~/.gemini/antigravity-cli/plugins/<name>/` |

For universal projects, use `AGENTS.md` and `.agents/skills`. Do not add a
`GEMINI.md` copy containing the same rules.

The CLI migration guide explicitly says that `agy` continues to parse
workspace `AGENTS.md` and `GEMINI.md`, and that its workspace skill path is
`.agents/skills`. The current binary advertises
`{workspace}/.agents/skills/{skill_name}/SKILL.md` and
`{appDataDir}/skills/{skill_name}/SKILL.md`.

## Rules

Use root `AGENTS.md` for shared, always-relevant repository instructions.
Antigravity also has Markdown rule files under `.agents/rules/`, with
activation modes such as always-on, manual, model-decided, and glob-based.
Those activation settings are host adapters, not portable rule metadata.

Global `agy` guidance belongs in `~/.gemini/GEMINI.md`. Keep user-global rules
short and do not duplicate project instructions there.

Antigravity permissions are a separate enforcement layer. Do not translate
allow, ask, or deny entries into prompt rules.

## Skills and workflows

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

The agent sees skill metadata first and reads the full `SKILL.md` when the task
matches. A clear name mention can force attention; the CLI also exposes skills
as slash commands such as `/review-api`.

Antigravity's desktop documentation has a separate “Workflows” feature backed
by Markdown and slash commands. For a procedure that must work in other
harnesses, make the Agent Skill authoritative. Keep a dedicated Antigravity
workflow only when it adds Antigravity-only orchestration that the skill cannot
express.

## Current documentation discrepancy

Google's CLI “Plugins & skills” page still includes an example using a flat
`.agents/skills/format-tests.md` file. Google's current Agent Skills page, the
CLI migration guide, and `agy` 1.1.8's own discovery template use the open
`<name>/SKILL.md` layout.

For new universal work, use `<name>/SKILL.md`. Treat the flat-file example as a
CLI compatibility form, not the cross-harness source. Re-test after upgrading
`agy` if a legacy flat skill must remain.

The global path also differs by surface:

- Antigravity's general/desktop skills page documents
  `~/.gemini/config/skills/`.
- The CLI migration and CLI plugins pages document
  `~/.gemini/antigravity-cli/skills/`.

Because this guide targets `agy`, use the CLI-specific path.

## Universal layout

`agy` needs no rule shim in the recommended repository:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

Claude Code's `CLAUDE.md` and `.claude/skills` shims are irrelevant to `agy`
unless another selected harness needs them. Do not instruct `agy` through
`AGENTS.md` to scan a non-native skill directory; that would not register the
skills with the harness.

## Validate

1. Start a fresh `agy` session from the intended project root.
2. Ask the agent to summarize the loaded `AGENTS.md` rules.
3. Invoke `/skill-name`, then try a natural-language prompt matching the
   description.
4. Confirm the skill is listed once and resolves to `.agents/skills`.
5. Keep `GEMINI.md`, `.agents/rules`, and plugin rules from duplicating the same
   semantic body.

## Official sources

- [Antigravity CLI overview](https://antigravity.google/docs/cli-overview)
- [Migrating from Gemini CLI](https://antigravity.google/docs/gcli-migration)
- [Plugins & skills for the CLI](https://antigravity.google/docs/cli-plugins)
- [Agent Skills](https://antigravity.google/docs/skills)
- [Rules and workflows](https://antigravity.google/docs/rules-workflows)
- [Custom agents in the CLI](https://antigravity.google/docs/cli/commands/agents)
- [CLI permissions](https://antigravity.google/docs/cli-permissions)
