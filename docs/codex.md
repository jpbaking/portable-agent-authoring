# OpenAI Codex guide

Verified against the current official Codex manual on 2026-07-29.

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

The current Codex skills guide documents `~/.agents/skills`, not the older
`~/.codex/skills` convention. Prefer the documented path for new installs.

## `AGENTS.md`

Codex builds one instruction chain at session start:

1. It reads the global `AGENTS.override.md`, or otherwise global `AGENTS.md`.
2. From the project root down to the current working directory, it reads at
   most one instruction file per directory.
3. In a directory, the order is `AGENTS.override.md`, `AGENTS.md`, then any
   configured fallback filename.
4. Files closer to the working directory appear later and therefore override
   broader guidance.

The default combined project-instruction limit is 32 KiB. Keep root guidance
concise and use nested instructions only where scoping matters.

Codex does not need a pointer from `AGENTS.md` to `.agents/skills`. Skill
discovery is independent and automatic.

## Skills are Codex workflows

Codex uses Agent Skills for reusable procedures. Project discovery scans
`.agents/skills` in the current directory and its ancestors through the
repository root. User-global skills live in `~/.agents/skills`; administrative
skills may live in `/etc/codex/skills`.

Invoke a skill by typing `$` and selecting it, or browse with `/skills`.
Codex can also select a skill implicitly from its `description`.

Keep shared frontmatter to:

```yaml
---
name: skill-name
description: Explain what this does and exactly when it should trigger.
---
```

Codex supports optional `agents/openai.yaml` metadata for UI presentation,
invocation policy, and tool dependencies. That file is Codex/OpenAI-specific;
do not require it for the portable workflow.

The universal repository policy uses generated skill shims rather than
symlinks. Codex reads the authoritative `.agents/skills` copy directly.

## Do not confuse prompt rules with execution rules

`.codex/rules/*.rules` files are Starlark command-execution policies. They
control whether matching command prefixes are allowed, require a prompt, or
are forbidden outside the sandbox. They are not Markdown behavioral guidance.

Put coding conventions and workflow expectations in `AGENTS.md` or a skill.
Put command enforcement in `.codex/rules` only when a Codex-specific policy is
intended.

## Universal layout

Codex reads the shared project layout directly:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

It ignores the Claude bridge and generated shim unless another integration explicitly
adds those locations. Do not add duplicate Codex skills under both
`.agents/skills` and a legacy `.codex/skills` path.

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
