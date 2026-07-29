# Cline guide

Verified against current Cline documentation and changelog on 2026-07-29.

> **Type:** Cline is a coding-agent harness/client available across IDE and CLI
> surfaces. It can run models from multiple providers; Cline is the host, not
> the underlying model.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Universal persistent instructions | `AGENTS.md` | `~/.agents/AGENTS.md` |
| Native Cline rules | `.clinerules/*.md` or `.txt` | `~/Documents/Cline/Rules/` (also check `~/Cline/Rules/` on Linux/WSL) |
| Recommended native skills | `.cline/skills/<name>/SKILL.md` | `~/.cline/skills/<name>/SKILL.md` |
| Compatible project skills | `.clinerules/skills/<name>/` or `.claude/skills/<name>/` | — |
| Invocation workflow shims | `.clinerules/workflows/<name>.md` | Host-specific |

For the universal layout, let Cline read `AGENTS.md` and the generated
`.claude/skills` shim. Generate a matching workflow shortcut for every skill.
A separate `.cline/skills` copy is unnecessary.

## Rules

Cline recognizes root `AGENTS.md` as a cross-tool rule type and shows it in the
Rules panel. It also reads global cross-tool instructions from
`~/.agents/AGENTS.md`.

Use `.clinerules/` only for Cline-specific modular rules or conditional
activation. A rule without frontmatter is always active. A conditional rule
uses Cline's `paths` frontmatter:

```yaml
---
paths:
  - "src/components/**"
  - "**/*.test.ts"
---
```

Do not copy the same always-on body into both `AGENTS.md` and `.clinerules/`.
Cline combines detected rule types; duplicate input wastes context and can make
precedence unclear.

## Skills and workflows

Cline loads skill metadata at startup, then uses its internal `use_skill` tool
to read `SKILL.md` when relevant. Users can explicitly invoke an enabled skill
as `/skill-name`.

The current Cline skills page documents:

- `.cline/skills/` as the recommended project path;
- `.clinerules/skills/` and `.claude/skills/` as compatible project paths;
- `~/.cline/skills/` as the global path;
- global skills taking precedence over same-name project skills.

Because `.claude/skills` is also Claude Code's required project path, it is the
smallest documented Cline adapter in a universal repository.

Cline's custom workflow format lives under `.clinerules/workflows/` and is
invoked as `/your-workflow.md`. Cline does not require a workflow wrapper for a
skill—the skill already has `/skill-name`—but this repository's policy
generates a workflow shortcut for consistent explicit invocation.

For a skill named `review-api`, generate
`.clinerules/workflows/review-api.md`:

```markdown
# Use the skill

Use the `review-api` skill for this request. Follow its `SKILL.md`
instructions exactly. Use relevant context already supplied by the user and
ask for any required input that is missing.
```

Invoke it as `/review-api.md`. Keep this file thin: do not copy the procedure
from `SKILL.md`, add Cline-specific workflow steps, or create a second source
of truth.

## `.agents/skills` caveat

Cline's changelog has moved a built-in PR skill to `.agents/skills`, and
GitHub's current `gh skill install` documentation identifies
`.agents/skills` as a shared Cline project destination. However, Cline's own
current skills reference does not list that path.

Do not depend solely on `.agents/skills` for Cline until the selected Cline
release demonstrably discovers it. In a repository that contains both
`.agents/skills` and `.claude/skills`, inspect the Skills panel or `/skills`:
newer releases may expose both copies. Keep generated shims byte-identical and resolve
any duplicate entry instead of assuming a precedence rule.

## Universal layout

Cline directly consumes:

```text
AGENTS.md
.claude/skills/<name>/SKILL.md
.clinerules/workflows/<name>.md
```

It does not need `CLAUDE.md`; that file exists for Claude Code. The workflow
file is only an invocation shim. Persistent Cline-only path rules remain
separate.

## Validate

1. Open a fresh task and confirm `AGENTS.md` appears in the Rules panel.
2. Open the Skills panel or `/skills`; confirm each skill is enabled and listed
   once.
3. Invoke `/skill-name.md` and confirm it delegates to the intended skill.
4. Invoke native `/skill-name` and test implicit activation separately.
5. Inspect `~/.cline/skills` for a same-name global override.
6. If both `.agents/skills` and `.claude/skills` are scanned, verify which entry
   Cline resolves and remove unneeded Cline-specific duplicates.

## Official sources

- [Cline rules](https://docs.cline.bot/customization/cline-rules)
- [Cline skills](https://docs.cline.bot/customization/skills)
- [Using commands and custom workflows](https://docs.cline.bot/core-workflows/using-commands)
- [Cline changelog](https://github.com/cline/cline/blob/main/CHANGELOG.md)
- [GitHub CLI skill installation paths](https://cli.github.com/manual/gh_skill_install)
