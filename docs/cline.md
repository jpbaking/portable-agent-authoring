# Cline guide

Verified against current Cline documentation, changelog (4.1.26), and
upstream source on 2026-11-08.

> **Type:** Cline is a coding-agent harness/client available across IDE and CLI
> surfaces. It can run models from multiple providers; Cline is the host, not
> the underlying model.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Universal persistent instructions | `AGENTS.md` | `~/.agents/AGENTS.md` |
| Native Cline rules | `.cline/rules/` or legacy `.clinerules/` | `~/.cline/rules/`, `~/Documents/Cline/Rules/` (also `~/Cline/Rules/`) |
| Agent Skills | `.agents/skills/`, `.claude/skills/`, `.cline/skills/`, or legacy `.clinerules/skills/` | `~/.cline/skills/` or `~/.agents/skills/` |
| Workflows | `.cline/workflows/` or legacy `.clinerules/workflows/` | `~/.cline/workflows/`, `~/Documents/Cline/Workflows/` |

`CLINE_DIR` replaces `~/.cline/` as the global configuration directory. Cline's
configuration reference marks `.clinerules/` as the legacy workspace layout;
the shared SDK names it deprecated.

For the universal layout, Cline reads `AGENTS.md` and `.agents/skills`
directly. It needs no Cline-specific file.

## Rules

Cline recognizes root `AGENTS.md` as a cross-tool rule type and shows it in the
Rules panel. It also reads global cross-tool instructions from
`~/.agents/AGENTS.md`, and detects `.cursorrules` and `.windsurfrules`. It does
not document reading `CLAUDE.md`. Workspace and global rules combine, and
workspace rules win on conflict.

Use `.cline/rules/` only for Cline-specific modular rules or conditional
activation. A rule without frontmatter is always active. A conditional rule
uses Cline's `paths` frontmatter, currently the only supported conditional:

```yaml
---
paths:
  - "src/components/**"
  - "**/*.test.ts"
---
```

Do not copy the same always-on body into both `AGENTS.md` and `.cline/rules/`.
Cline combines detected rule types; duplicate input wastes context and can make
precedence unclear.

## Skills

Cline loads skill metadata at startup and activates a matching skill through
its `skills` tool, which reads the full `SKILL.md`. Users can force a skill with
`/skill-name`. Skills are enabled by default and can be toggled individually.

The skills page documents `name` (matching the directory, kebab-case) and
`description` (at most 1,024 characters), and recommends keeping `SKILL.md`
under about 5k tokens.

### Discovery and collisions

Cline's skills page lists `.cline/skills/` (recommended), `.clinerules/skills/`,
and `.claude/skills/`. Its configuration reference also lists `.agents/skills/`
and `~/.agents/skills/`, and upstream source scans all of them. Changelog
4.1.24 restored `.claude/skills` discovery after the SDK migration.

In upstream source, project directories are scanned in this order:
`.clinerules/skills`, `.cline/skills`, `.claude/skills`, `.agents/skills`; then
`~/.cline/skills` and `~/.agents/skills`; then enterprise remote skills.
Skills are deduplicated by `name`, and the last one found wins. So:

- in the universal layout, both `.agents/skills/<name>` and the generated
  `.claude/skills/<name>` mirror are seen, but Cline lists the skill once and
  resolves it to `.agents/skills`;
- a same-name global skill overrides the project skill, and an enterprise
  skill overrides both.

This order comes from source, not the published docs. Keep the mirror
byte-identical so the resolution does not matter, and recheck it in the Skills
panel after upgrading.

## Workflows

Cline workflows are Markdown files under `.cline/workflows/` (legacy
`.clinerules/workflows/`) invoked from the slash menu. Since 4.1.4, skills
appear alongside workflows in that menu, and same-name commands are
disambiguated rather than shadowed.

Earlier versions of this repository generated a
`.clinerules/workflows/<name>.md` shortcut for every skill. That is no longer
recommended: Cline's native `/skill-name` already provides explicit
invocation, and a same-name workflow adds a duplicate menu entry. To migrate,
delete generated shims that only delegated to a skill, after confirming
nothing else invokes them.

Keep a workflow only for Cline-specific orchestration that a skill cannot
express, and do not copy a skill's procedure into it.

## Universal layout

Cline directly consumes:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

It also sees the `.claude/skills` mirror (resolved as above). It does not need
`CLAUDE.md` or `.gemini/settings.json`. Persistent Cline-only path rules remain
separate.

## Validate

1. Open a fresh task and confirm `AGENTS.md` appears in the Rules panel.
2. Open the Skills panel or `/skills`; confirm each skill is enabled, listed
   once, and points at `.agents/skills`.
3. Invoke `/skill-name` and test implicit activation separately.
4. Inspect `~/.cline/skills` and `~/.agents/skills` for a same-name global
   override.
5. Confirm no leftover delegating workflow shims remain in
   `.clinerules/workflows/` or `.cline/workflows/`.

## Official sources

- [Cline rules](https://docs.cline.bot/customization/cline-rules)
- [Cline skills](https://docs.cline.bot/customization/skills)
- [Cline configuration reference](https://docs.cline.bot/getting-started/config)
- [Using commands](https://docs.cline.bot/core-workflows/using-commands)
- [Cline changelog](https://github.com/cline/cline/blob/main/CHANGELOG.md)
- [Cline SDK storage paths (source)](https://github.com/cline/cline/blob/main/sdk/packages/shared/src/storage/paths.ts)
