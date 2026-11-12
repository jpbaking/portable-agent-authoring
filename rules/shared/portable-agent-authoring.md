# Portable agent authoring

This is a user-global rule installed by the `portable-agent-authoring`
toolkit. It applies only to tasks that create or change agent instructions.
For every other task, ignore it and do not mention it.

## When it applies

The task creates, edits, migrates, converts, mirrors, reviews, or installs
any of the following, for any harness, whether the user names one harness or
several:

- an Agent Skill: a `SKILL.md` and its directory;
- persistent agent instructions: `AGENTS.md`, `AGENTS.override.md`,
  `CLAUDE.md`, `GEMINI.md`, or a rules directory such as `.agents/rules/`,
  `.claude/rules/`, `.cline/rules/`, or `.clinerules/`;
- a reusable workflow or custom command, such as files under
  `.claude/commands/`, `.gemini/commands/`, `.opencode/commands/`,
  `.cline/workflows/`, or `.clinerules/workflows/`, or an Antigravity
  workflow;
- the user-global equivalents of any of these, under `~/.agents/`,
  `~/.claude/`, `~/.codex/`, `~/.gemini/`, `~/.cline/`, or
  `~/.config/opencode/`.

It does not apply to reading those files without changing them, or to
ordinary code changes.

## What to do

1. Before writing anything, use the `universal-agent-authoring` skill and
   follow it.
2. If the deliverable is agent tooling that other people install, such as a
   toolkit repository, an `AGENT-INSTALL.md`, or an install prompt, also use
   the `agent-toolkit-authoring` skill.
3. If a skill is not available in this harness, read its `SKILL.md` from the
   first of these locations that exists and follow it, resolving its
   `references/` paths relative to that skill's directory:
   - `~/.agents/skills/<skill>/SKILL.md`
   - `~/.claude/skills/<skill>/SKILL.md`
   - `~/.gemini/antigravity-cli/skills/<skill>/SKILL.md`

   If none exists, say that the toolkit's skills are not installed, and
   continue only if the user agrees.
4. If the user explicitly asks for something the skills advise against, such
   as a project `GEMINI.md` or a symlinked mirror, state the trade-off once,
   then follow the user's decision.

## What not to do

- Do not create, migrate, or "fix" agent artifacts the user did not ask
  about.
- Do not suggest this toolkit, or mention this rule, outside the tasks above.
