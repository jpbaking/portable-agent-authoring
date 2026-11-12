# Gemini CLI guide

Verified against current Gemini CLI documentation on 2026-11-08. Observed
locally with Gemini CLI 0.67.0.

> **Type:** Gemini CLI is Google's open-source terminal coding harness. Gemini
> models are the agents running inside it. It is a different harness from
> Antigravity CLI (`agy`); see the [`agy` guide](agy.md).

Gemini CLI's documentation states that it was replaced by Antigravity CLI on
June 18, 2026 for unpaid-tier and Google One users, and that it has not been
optimized for the newest Gemini models. It is still released (v0.67.0 on
2026-11-04) and used through paid and enterprise access, so this guide covers
it separately.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent context | `GEMINI.md` in workspace directories and their ancestors, plus just-in-time files near accessed paths | `~/.gemini/GEMINI.md` |
| Context filename setting | `.gemini/settings.json` → `context.fileName` | `~/.gemini/settings.json` → `context.fileName` |
| Agent Skills | `.agents/skills/<name>/SKILL.md` or `.gemini/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/` or `~/.gemini/skills/<name>/` |
| Custom commands | `.gemini/commands/**/*.toml` | `~/.gemini/commands/**/*.toml` |
| Extensions | Host-managed | `gemini extensions` |

Workspace settings override user settings.

## Context files

Gemini CLI reads `GEMINI.md` by default, **not** `AGENTS.md`. The
`context.fileName` setting accepts a list of names:

```json
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
```

The universal layout commits this to `.gemini/settings.json`. Keeping
`GEMINI.md` in the list preserves any user-global `~/.gemini/GEMINI.md`;
the project itself has no `GEMINI.md`, so `AGENTS.md` loads once.

Context loading works in three tiers: the global file, workspace directories
and their ancestors, and just-in-time discovery when a tool accesses a path
(scanning that directory and its ancestors up to a trusted root). Discovered
files are concatenated. `/memory show` displays the combined context and
`/memory reload` re-scans.

### Why not a `GEMINI.md` bridge?

Gemini CLI supports `@file.md` imports, so a one-line `GEMINI.md` containing
`@AGENTS.md` would also work for Gemini CLI. Avoid it in a universal repository:
`agy` reads both `AGENTS.md` and `GEMINI.md` cumulatively and uses a different
include syntax, so the bridge adds a stray file to `agy`'s rules and invites
duplicated rule bodies. Use the settings adapter instead.

If a project cannot commit `.gemini/settings.json`, set the same
`context.fileName` value in `~/.gemini/settings.json`.

## Trusted folders

Folder trust is on by default (`security.folderTrust.enabled`). In an
untrusted workspace, Gemini CLI does not load the project's
`.gemini/settings.json`, custom commands, or MCP servers. With 0.67.0,
workspace skills were also not listed in an untrusted folder, while
user-global skills were.

Trust the project before validating; otherwise the `context.fileName`
adapter and `.agents/skills` do not take effect.

## Skills

Agent Skills are enabled by default (`skills.enabled`). Discovery precedence,
lowest to highest: built-in, extension, user, workspace. Within the user and
workspace tiers, `.agents/skills/` takes precedence over `.gemini/skills/`.
Same-name skills resolve to the higher-precedence copy.

Use the shared tree:

```text
.agents/skills/review-api/
  SKILL.md
  references/
  scripts/
  assets/
```

Gemini CLI documents `name` (matching the directory) and `description` as the
skill metadata. At startup, enabled skills' names and descriptions enter the
system prompt. When a task matches, the model calls `activate_skill`; the user
confirms, and the `SKILL.md` body and the skill directory are added to the
conversation and allowed paths.

Management commands:

- `/skills list [all] [nodesc]`, `/skills enable <name>`,
  `/skills disable <name>`, `/skills reload`;
- `gemini skills list [--all]`, `gemini skills install <source>`,
  `gemini skills uninstall <name>`.

## Explicit invocation

Gemini CLI has no slash command per skill. The feature request
[google-gemini/gemini-cli#21165](https://github.com/google-gemini/gemini-cli/issues/21165)
was still open on 2026-11-08. Invoke a skill by naming it:

> Use the `review-api` skill.

If a project wants a slash shortcut, add an optional Gemini-only command
adapter at `.gemini/commands/review-api.toml`:

```toml
description = "Use the review-api skill."
prompt = """
Use the `review-api` skill for this request. Activate it and follow its
SKILL.md instructions exactly. Ask for any required input that is missing.

{{args}}
"""
```

Keep it thin: no copy of the procedure. Custom commands do not load in
untrusted folders, and a future native `/skill-name` could collide with it, so
this adapter is not part of the default universal layout. `agy` does not read
`.gemini/commands`.

## Custom commands are not universal workflows

TOML custom commands support `{{args}}`, `!{shell}` injection, and `@{file}`
injection. Those are Gemini CLI-specific. For a reusable cross-harness
procedure, write an Agent Skill. `agy`'s import converts legacy Gemini CLI
commands into skills, which confirms the skill as the portable form.

## Universal layout

Gemini CLI consumes:

```text
AGENTS.md                       # via context.fileName
.gemini/settings.json           # adapter: context.fileName
.agents/skills/<name>/SKILL.md  # shared skill tree
```

It ignores `CLAUDE.md` and `.claude/skills`. Do not also install the same
skill into `.gemini/skills`.

## Validate

1. Trust the project, then start a fresh `gemini` session in the root.
2. Run `/memory show`; confirm `AGENTS.md` is loaded exactly once.
3. Run `/skills list`; confirm each skill appears once with an `.agents/skills`
   location.
4. Ask "Use the `skill-name` skill" and approve the activation prompt.
5. Test a natural-language request that should trigger the skill.
6. Check `~/.agents/skills` and `~/.gemini/skills` for same-name copies.

## Official sources

- [Provide context with GEMINI.md](https://geminicli.com/docs/cli/gemini-md/)
- [Agent Skills](https://geminicli.com/docs/cli/skills/)
- [Creating Agent Skills](https://geminicli.com/docs/cli/creating-skills/)
- [Custom commands](https://geminicli.com/docs/cli/custom-commands/)
- [Settings](https://geminicli.com/docs/cli/settings/)
- [Trusted folders](https://geminicli.com/docs/cli/trusted-folders/)
- [Gemini CLI releases](https://github.com/google-gemini/gemini-cli/releases)
