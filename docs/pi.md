# Pi guide

Verified against the current Pi site and upstream repository documentation on
2026-07-29.

> **Type:** Pi describes itself as a minimal terminal coding harness. The model
> running inside Pi is the agent. Pi is intentionally extensible through
> skills, prompt templates, TypeScript extensions, and packages.

The upstream repository and npm package were renamed in 2026 from
`badlogic/pi-mono` / `@mariozechner/pi-coding-agent` to
`earendil-works/pi` / `@earendil-works/pi-coding-agent`. Old GitHub links
currently redirect, but new documentation should use the current names.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent context | `AGENTS.md` (or `CLAUDE.md`) in current/ancestor directories | `~/.pi/agent/AGENTS.md` |
| Shared Agent Skills | `.agents/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` |
| Pi-native Agent Skills | `.pi/skills/<name>/SKILL.md` | `~/.pi/agent/skills/<name>/SKILL.md` |
| Prompt templates | `.pi/prompts/*.md` | `~/.pi/agent/prompts/*.md` |
| Extensions | `.pi/extensions/` | `~/.pi/agent/extensions/` |

Project-local resources load only after the project is trusted.

## Context rules

Pi loads `AGENTS.md` or `CLAUDE.md` at startup from:

- `~/.pi/agent/AGENTS.md`;
- parent directories walking up from the current working directory;
- the current directory.

Matching context files are concatenated. For a universal project, use
`AGENTS.md`; do not add a same-body `CLAUDE.md` for Pi. The repository's
`CLAUDE.md` bridge exists only for Claude Code.

Context loading can be disabled with `--no-context-files`, so tests should
confirm it has not been turned off.

## Skills

Pi implements the Agent Skills standard and supports the shared project path
`.agents/skills` from the working directory through ancestors to the Git root.
It also supports `.pi/skills`, `~/.agents/skills`, and
`~/.pi/agent/skills`, plus explicit paths and Pi packages.

Pi scans metadata at startup and tells the model to read the full `SKILL.md`
when relevant. Explicit commands use a namespaced form:

```text
/skill:review-api
/skill:review-api optional arguments
```

Skill commands are controlled by `enableSkillCommands` in settings. A clear
name mention is the fallback when commands are disabled.

Pi validates the standard naming and description limits, warns on most
violations, and skips a skill with no description. When names collide, it
warns and keeps the first discovered skill, so audit project and global paths.

Pi supports optional standard metadata and experimental host behavior, but a
universal skill should retain only `name` and `description`.

## Prompt templates are not universal workflows

Pi prompt templates are Markdown snippets under `.pi/prompts` or
`~/.pi/agent/prompts`. They expand with `/name` and support positional
arguments, defaults, and slicing.

Those substitutions and command names are Pi-specific. For a reusable
cross-harness procedure, create an Agent Skill. Keep a prompt template only as
a thin Pi-only convenience layer, and do not maintain a second full procedure
inside it.

Pi packages can distribute extensions, skills, prompts, and themes. Package
manifests and executable extensions are host-specific distribution and
automation layers; the skill content inside a package can remain portable.

## Universal layout

Pi reads the shared files directly:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

It needs neither `.pi/skills` nor a Pi prompt template for a universal project.
Do not install the same skill into both `.agents/skills` and `.pi/skills`.

## Validate

1. Trust the project, then start a fresh Pi session in the intended directory.
2. Check the startup header for the loaded `AGENTS.md` and skills.
3. Invoke `/skill:skill-name` and test implicit selection separately.
4. Check `.pi/skills`, `.agents/skills`, `~/.pi/agent/skills`, and
   `~/.agents/skills` for collisions.
5. Confirm no Pi prompt template duplicates the skill's procedure.

## Official sources

- [Pi project site](https://pi.dev/)
- [Pi coding-agent README](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md)
- [Pi Agent Skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md)
- [Pi prompt templates](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/prompt-templates.md)
- [Pi packages](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md)
