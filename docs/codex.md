# OpenAI Codex guide

Verified against the current official Codex manual on 2026-11-08. Observed
locally with `codex-cli` 0.167.0.

> **Type:** Codex is OpenAI's coding agent product. Codex CLI and the IDE
> extension are also harness surfaces that discover repository instructions
> and skills. This guide describes their local filesystem behavior.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent instructions | `AGENTS.md` and nested `AGENTS.md` / `AGENTS.override.md` | `~/.codex/AGENTS.md` or `AGENTS.override.md` |
| Agent Skills | `.agents/skills/<name>/SKILL.md` from the working directory through repository root | `~/.agents/skills/<name>/SKILL.md` |
| Codex settings | `.codex/config.toml` in a trusted project | `~/.codex/config.toml` |
| Command execution policy | `.codex/rules/*.rules` in a trusted project | `~/.codex/rules/*.rules` |

Administrative skills may live in `/etc/codex/skills`; system skills such as
`skill-creator` and `skill-installer` are bundled. The current skills guide
documents `~/.agents/skills`, not the older `~/.codex/skills` convention.
`CODEX_HOME` overrides the default `~/.codex` location.

## `AGENTS.md`

Codex builds one instruction chain at session start:

1. It reads the global `AGENTS.override.md`, or otherwise global `AGENTS.md`;
   only the first non-empty file at that level is used.
2. From the project root (typically the Git root) down to the current working
   directory, it reads at most one instruction file per directory.
3. In a directory, the order is `AGENTS.override.md`, `AGENTS.md`, then any
   name in `project_doc_fallback_filenames`.
4. Files are concatenated root-first, so files closer to the working directory
   appear later and override broader guidance. Empty files are skipped.

Codex stops adding files once the combined size reaches
`project_doc_max_bytes` (default 32 KiB). Keep root guidance concise and use
nested instructions only where scoping matters.

Codex does not need a pointer from `AGENTS.md` to `.agents/skills`. Skill
discovery is independent and automatic.

## Skills are Codex workflows

Codex uses Agent Skills for reusable procedures. Project discovery scans
`.agents/skills` in the current directory and every ancestor through the
repository root. Codex follows symlinks and detects skill changes
automatically; restart if an update does not appear.

Invoke a skill by typing `$` and selecting it, or browse with `/skills`.
Codex can also select a skill implicitly from its `description`. The initial
skill list uses at most 2% of the context window (or 8,000 characters when the
window is unknown), configurable with `skills.max_context_tokens`.

Keep shared frontmatter to:

```yaml
---
name: skill-name
description: Explain what this does and exactly when it should trigger.
---
```

Codex supports optional `agents/openai.yaml` metadata for UI presentation,
invocation policy (`policy.allow_implicit_invocation`), and tool dependencies.
That file is Codex/OpenAI-specific; do not require it for the portable
workflow.

Skills that share a `name` are not merged: both can appear in skill selectors,
and the manual documents no precedence between locations. Audit project,
user, and admin paths for duplicates. Individual skills can be disabled with
`[[skills.config]]` entries in `~/.codex/config.toml`.

## Do not confuse prompt rules with execution rules

`.codex/rules/*.rules` files are experimental Starlark command-execution
policies. Each `prefix_rule()` matches a command prefix and decides `allow`,
`prompt`, or `forbidden` for running it outside the sandbox; the most
restrictive match wins. They are not Markdown behavioral guidance.

Put coding conventions and workflow expectations in `AGENTS.md` or a skill.
Put command enforcement in `.codex/rules` only when a Codex-specific policy is
intended.

## Universal layout

Codex reads the shared project layout directly:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

It ignores `CLAUDE.md`, `.claude/skills`, and `.gemini/settings.json`. Do not
add duplicate Codex skills under both `.agents/skills` and a legacy
`.codex/skills` path.

## Validate

1. Start a new Codex session in the repository root.
2. Ask Codex to summarize its active instruction sources.
3. Use `/skills` and confirm each project skill appears once.
4. Invoke the skill with `$skill-name`.
5. Test a natural-language request that should and should not trigger it.
6. Use `codex execpolicy check` separately when validating `.rules` files.

## Official sources

- [Build skills](https://learn.chatgpt.com/docs/build-skills)
- [Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Codex command execution rules](https://learn.chatgpt.com/docs/agent-configuration/rules)
- [Codex customization overview](https://developers.openai.com/codex/concepts/customization)
