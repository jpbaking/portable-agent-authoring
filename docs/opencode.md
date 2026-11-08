# OpenCode guide

Verified against the current OpenCode V2 documentation on 2026-11-08 (latest
release v2.2.6, 2026-11-06). Not observed locally.

> **Type:** OpenCode is an open-source, provider-independent coding harness
> with terminal, desktop, and web clients over a shared server. The model it
> runs is the agent. This guide targets OpenCode V2; V1 behavior is noted only
> where migration matters.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent instructions | `AGENTS.md` in the workspace and each ancestor up to the project root; nested files on demand | `~/.config/opencode/AGENTS.md` |
| Extra instructions | `instructions` array in `opencode.json(c)` | `instructions` in `~/.config/opencode/opencode.json(c)` |
| Agent Skills | `.opencode/skills/`, plus compatibility `.agents/skills/` and `.claude/skills/`, in the working directory and each ancestor up to the project root | `~/.config/opencode/skills/`, plus compatibility `~/.agents/skills/` and `~/.claude/skills/` |
| Custom commands | `.opencode/commands/*.md` | `~/.config/opencode/commands/*.md` |
| Settings | `opencode.json(c)` or `.opencode/opencode.json(c)` | `~/.config/opencode/opencode.json(c)` |

A system directory (`/etc/opencode` on Linux, `/Library/Application
Support/opencode` on macOS, `%ProgramData%\opencode` on Windows) can also hold
settings, agents, commands, and skills for every user. Managed settings take
the highest precedence.

## Instructions

OpenCode V2 recognizes `AGENTS.md` only. Unlike V1, it does not fall back to
`CLAUDE.md` or `~/.claude/CLAUDE.md`, so the universal `CLAUDE.md` bridge is
invisible to it and cannot cause a double read.

At session start, OpenCode loads the global file, then every `AGENTS.md` from
the workspace directory upward—to the home directory, or to the project root
for workspaces outside home. Files are combined **nearest-first**:

```text
~/.config/opencode/AGENTS.md
packages/web/AGENTS.md      # current workspace
packages/AGENTS.md
AGENTS.md                   # project root
```

That is the reverse of Codex and Claude Code, which put the nearest file last.
OpenCode combines the files and does not resolve conflicts, so do not rely on
ordering to override broader guidance; state scope explicitly instead.

`AGENTS.md` files below the workspace load when the agent reads or lists a path
in that area. Edits to the global or upward-discovered files are picked up
before the next model request; edits to an already-loaded nested file need a
new session. `OPENCODE_DISABLE_PROJECT_CONFIG=1` skips project discovery.

OpenCode does not document expanding `@path` imports inside `AGENTS.md`. To
load extra files deterministically, use the host-specific `instructions`
array, which accepts paths, globs, `~/` paths, and URLs. Do not list
`AGENTS.md` there; it is already discovered.

## Skills

OpenCode discovers skills automatically from the locations above. A source can
hold `<id>/SKILL.md` directories (nestable in grouping folders up to six levels)
or flat `<id>.md` files at the source root; the universal layout uses only the
directory form. Extra local directories or HTTP catalogs can be added with the
`skills` array in `opencode.json(c)`.

The **path determines the skill ID**; frontmatter `name` is only a display
label. Keep `name` identical to the directory name, as the universal rules
require, so the ID and the name agree. OpenCode recommends, but does not
enforce, the portable `^[a-z0-9]+(-[a-z0-9]+)*$` pattern and 1–64 characters.
Skills without a `description` are not advertised to the model.

The model loads a skill with OpenCode's `skill` tool. Users load one explicitly
by mentioning it as `@skill-id`. There is no per-skill slash command.

Host-only frontmatter: `metadata.opencode/autoinvoke` and
`disable-model-invocation` hide a skill from the model's list. Skill access is
controlled with `permissions` rules (`action: "skill"`) in config. Keep both
out of the universal `SKILL.md`.

### Precedence and collisions

Sources register from lower to higher precedence; the later one wins a
same-ID collision:

1. built-in skills;
2. `.claude/skills` — global first, then farthest ancestor toward the working
   directory;
3. `.agents/skills` — same order;
4. `~/.config/opencode/skills`;
5. project `.opencode/skills`, root toward the working directory;
6. explicit `skills` config entries.

Consequences for the universal layout:

- OpenCode sees both `.agents/skills/<name>` and the generated
  `.claude/skills/<name>` mirror, and loads the `.agents/skills` copy. Keep them
  byte-identical.
- A project `.agents/skills` skill overrides a same-ID `~/.agents/skills` or
  `~/.claude/skills` global skill.
- A same-ID skill in `~/.config/opencode/skills` or `.opencode/skills`
  overrides the universal project skill. Audit those paths.

`OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` stopped `.claude/skills` discovery in
V1; the V2 docs do not list it, so do not depend on it to deduplicate.

## Commands are not universal workflows

Markdown commands under `.opencode/commands/` run as `/name` and support
`$ARGUMENTS`, positional `$1`…, and `` !`shell` `` injection. Nested files map to
slash-separated names, such as `/team/review`. Those features are
OpenCode-specific.

For a cross-harness procedure, write an Agent Skill. If a project wants a slash
shortcut, add an optional thin adapter at `.opencode/commands/review-api.md`:

```markdown
---
description: Use the review-api skill.
---

Use the `review-api` skill for this request. Load it and follow its SKILL.md
instructions exactly. Ask for any required input that is missing.

$ARGUMENTS
```

Do not copy the skill's procedure into the command.

## Universal layout

OpenCode reads the shared files directly:

```text
AGENTS.md
.agents/skills/<name>/SKILL.md
```

It also sees the `.claude/skills` mirror (resolved as above). It ignores
`CLAUDE.md` and `.gemini/settings.json`, and needs neither `.opencode/skills`
nor `opencode.json` for a universal project. Do not install the same skill
into both `.agents/skills` and `.opencode/skills`.

## Migrating from V1

V1 read `CLAUDE.md` when no `AGENTS.md` existed, and `~/.claude/CLAUDE.md`
when `~/.config/opencode/AGENTS.md` was missing. A repository that relied on
that fallback must add `AGENTS.md` for V2. V2 still discovers V1's singular
`.opencode/skill/`, `.opencode/command/`, and `.opencode/agent/` directories,
but the plural forms are preferred. V1's `skills.paths` / `skills.urls` config
becomes a single `skills` array.

## Validate

1. Start a fresh OpenCode session in the project root.
2. Ask the agent to summarize its loaded project instructions; confirm the
   `AGENTS.md` content appears once.
3. Ask the agent to list available skills; confirm each appears once.
4. Invoke `@skill-name` and test a natural-language request separately.
5. Check `.opencode/skills`, `~/.config/opencode/skills`, `~/.agents/skills`,
   and `~/.claude/skills` for same-ID overrides.
6. Review `permissions` rules for a `skill` deny or ask that hides the skill.

## Official sources

- [Instructions](https://opencode.ai/docs/instructions/)
- [Skills](https://opencode.ai/docs/skills/)
- [Commands](https://opencode.ai/docs/commands/)
- [Config](https://opencode.ai/docs/config/)
- [Permissions](https://opencode.ai/docs/permissions/)
- [Migrate from V1](https://opencode.ai/docs/migrate-v1/)
- [OpenCode releases](https://github.com/anomalyco/opencode/releases)
