---
name: universal-agent-authoring
description: Create, migrate, update, or audit agent skills (SKILL.md), persistent instruction files (AGENTS.md, CLAUDE.md, GEMINI.md, rules directories), and reusable workflows or custom slash commands so one authoritative source works across Antigravity CLI (agy), OpenAI Codex, Claude Code, Gemini CLI, Cline, and OpenCode. Use when asked to write, add, convert, port, mirror, sync, or review a skill, rule, workflow, command, or agent instructions for any of these harnesses, in a project or in user-global paths, even when only one harness is named. Not for configuring only permissions, hooks, sandboxing, models, or MCP servers, and not for ordinary code changes. For a repository that distributes agent tooling for other people to install, also use the agent-toolkit-authoring skill.
---

# Universal agent authoring

Create or change agent skills, persistent rules, and workflows so that one
authoritative source works in Antigravity CLI (`agy`), OpenAI Codex, Claude
Code, Gemini CLI, Cline, and OpenCode, with only the host adapters each
harness requires.

The normative guide and the per-harness guides are bundled with this skill:

| File | Read it when |
| --- | --- |
| `references/universal-agent-authoring.md` | Always, completely, before writing anything |
| `references/docs/agy.md`, `codex.md`, `claude.md`, `gemini.md`, `cline.md`, `opencode.md` | That harness is in scope and the task goes beyond the shared project layout: user-global paths, nested or path-scoped rules, host-only features, legacy commands or workflows, or collisions |
| `references/agent-toolkit-repositories.md` | The deliverable is tooling other people install; then also use the `agent-toolkit-authoring` skill |

The guides record the date they were verified. If the user asks for current
behavior, or what you observe contradicts a guide, re-check the official
sources listed at the end of the relevant harness guide and report the
difference instead of silently choosing one.

## Inputs

Determine these from the request and the repository. Ask only for what you
cannot determine, and ask before writing.

1. **Artifact**: persistent rules, a skill, a vendor workflow or command to
   migrate, a path-scoped rule, or enforcement (permissions, hooks,
   sandboxing, tool policy).
2. **Scope**: the current project (default) or user-global.
3. **Harnesses**: all six by default. When the user names fewer, still write
   the portable form unless they explicitly want a host-only artifact.
4. **Mode**: create, migrate, update, or audit. Audit writes nothing.
5. **For a skill**: its single user goal, trigger phrases, non-triggers,
   required inputs, side effects, validation, and final output.

If the user targets a harness other than these six, say the bundled guides
do not cover it and ask how to proceed.

## 1. Read the guide

Read `references/universal-agent-authoring.md` completely. Read each in-scope
harness guide as described in the table above. Do not rely on memory for
paths, precedence, or limits; they change between releases.

## 2. Survey before writing

Write nothing in this step. Record what exists.

For project scope, inspect the project root, and for instruction files also
each ancestor up to the repository root:

- instruction files: `AGENTS.md`, `AGENTS.override.md`, `CLAUDE.md`,
  `.claude/CLAUDE.md`, `CLAUDE.local.md`, `GEMINI.md`, `.agents/AGENTS.md`,
  `.agents/GEMINI.md`, `.gemini/settings.json`;
- rule directories: `.agents/rules/`, `.agent/rules/`, `.claude/rules/`,
  `.cline/rules/`, rule files directly inside `.clinerules/`, and
  `.codex/rules/` (Starlark command policy, never behavioral guidance);
- skill directories: `.agents/skills/`, `.claude/skills/`, `.cline/skills/`,
  `.clinerules/skills/`, `.opencode/skills/`, `.gemini/skills/`, and legacy
  `.agent/skills/` or `.codex/skills/`;
- workflows and commands: `.claude/commands/`, `.gemini/commands/`,
  `.opencode/commands/`, `.cline/workflows/`, `.clinerules/workflows/`, and
  any Antigravity workflow files.

For user-global scope, inspect every global skill location and global
instruction file in the guide's "User-global installs" table.

In both scopes:

- find every same-name skill in any other project or global location, and
  note which copy each harness will resolve (see "Hosts that see both trees"
  in the guide and each harness guide's precedence section);
- compare each generated copy, such as `.claude/skills/<name>/`, with its
  source and classify it as identical or divergent;
- note user-owned content that must survive, such as text in an existing
  `CLAUDE.md` or keys in `.gemini/settings.json`.

In audit mode, skip to step 6 and report.

## 3. Choose the artifact

Apply the guide's "Choose the artifact" order:

1. Durable repository facts needed on nearly every task: `AGENTS.md`.
2. A repeatable task with steps, inputs, validation, and an output: an Agent
   Skill. This is the universal workflow format.
3. Instructions for certain paths only: a shared semantic rule plus
   host-specific conditional adapters (step 4.4).
4. Hard enforcement: host configuration. Prompt rules are not a security
   boundary; never translate allow or deny policy into prose.
5. Live data or controlled external actions: the procedure in a skill, and
   MCP or plugins configured separately per host.

If the user asks for something the guide advises against, such as a project
`GEMINI.md` or a symlinked mirror, state the trade-off once, then follow the
user's decision.

## 4. Author the authoritative source

Edit only authoritative files: `AGENTS.md` for rules and
`.agents/skills/<name>/` for skills (or their user-global equivalents).

### 4.1 Persistent rules

- Put the shared contract directly in `AGENTS.md`. Keep only what an agent
  cannot infer: commands, boundaries, conventions, confirmation-required
  actions, completion expectations, and pointers to skills.
- Keep it well under 24,000 bytes (`agy` truncates there; Codex stops at
  32 KiB of combined project instructions).
- Ensure `CLAUDE.md` contains `@AGENTS.md` exactly once. If `CLAUDE.md`
  already has content, keep it and add the import above it; leave only
  genuinely Claude-specific text below the import. If that existing text
  duplicates `AGENTS.md`, propose moving it into `AGENTS.md` and get approval.
- Ensure `.gemini/settings.json` has `context.fileName` including
  `AGENTS.md` and `GEMINI.md`. Merge into existing JSON; never replace other
  keys.
- Do not create a project `GEMINI.md`. Do not copy the `AGENTS.md` body into
  `.claude/rules/`, `.agents/rules/`, `.cline/rules/`, or `.clinerules/`.
- Never put behavioral Markdown in `.codex/rules/`.

### 4.2 Skills

Create `.agents/skills/<name>/SKILL.md` and follow every constraint in the
guide's "Author a universal skill" section. In particular:

- frontmatter has only `name` and `description`, both present;
- `name` is lowercase kebab-case, at most 64 characters, and equal to the
  directory name;
- `description` is at most 1,024 characters, puts the action, trigger
  phrases, and important non-triggers first, and is quoted if it contains a
  colon;
- the body is under 24,000 bytes, preferably under about 5k tokens and 500
  lines, imperative and agent-neutral;
- inputs are requested in prose; no `$ARGUMENTS`, `{{args}}`, positional
  substitution, shell interpolation, or session variables;
- other skills are referenced as "the `other-skill` skill"; outcomes are
  described instead of naming a harness's internal tools;
- details go in `references/`, deterministic helpers in `scripts/`, and
  templates or output resources in `assets/`, with links relative to the
  skill directory;
- inputs, side effects, stopping conditions, validation, and final output are
  stated explicitly, for one user goal.

Put vendor-only frontmatter or metadata (for example Claude Code's
`allowed-tools`, Codex's `agents/openai.yaml`, OpenCode's
`metadata.opencode/autoinvoke`) in a clearly labeled host-specific variant or
sidecar, never in the universal copy.

### 4.3 Migrating a vendor workflow or command

Follow the guide's "Turn a vendor workflow into a universal skill" steps:
capture purpose, triggers, inputs, steps, side effects, validation, and
output; write the skill; replace argument variables with prose, nested slash
calls with skill references, and tool names with outcomes. If behavior cannot
be expressed as a skill, split it into the portable skill plus a thin,
labeled host adapter. Retire the old command or workflow only after
confirming nothing still invokes it, and with the user's approval. Delete
legacy `.clinerules/workflows/<name>.md` files that only delegate to a skill.

### 4.4 Path-scoped rules

There is no common conditional-rule format. Keep one authoritative semantic
body, read every in-scope harness guide, and add the host mechanism each one
documents, for example `agy` `.agents/rules/` files with `trigger: glob`,
Claude Code `.claude/rules/` files with `paths`, Cline `.cline/rules/` files
with `paths`, or nested instruction files where a host loads them. If an
adapter needs its own copy of the body, generate it from the authoritative
body and say which file is authoritative. Never let an always-on copy
duplicate `AGENTS.md`.

### 4.5 User-global artifacts

- Skills: author in `~/.agents/skills/<name>/` (Codex, Gemini CLI, Cline,
  OpenCode). Mirror byte-identically to `~/.claude/skills/<name>/` if Claude
  Code is in scope and to `~/.gemini/antigravity-cli/skills/<name>/` if `agy`
  is in scope. Do not use `~/.gemini/skills/`, `~/.cline/skills/`, or
  `~/.config/opencode/skills/` for a shared skill.
- Instructions: use each host's global file from the guide's table. Merge
  into user-owned files and never overwrite them. `~/.gemini/GEMINI.md`
  serves both `agy` and Gemini CLI; if only one is selected, say so and ask
  before writing it.
- A long global rule: store the body once at `~/.agents/rules/<name>.md` and
  add a short, marker-guarded pointer to each host file, as described in
  `references/agent-toolkit-repositories.md` under "Global rules".
- Warn that a global skill can override a same-name project skill in Claude
  Code, Cline, and OpenCode's `~/.config/opencode/skills`.

## 5. Generate the shims

The sync is one-way: `.agents/skills/<name>/` to `.claude/skills/<name>/`
(and to each user-global mirror in 4.5).

1. If the repository has a sync script documented in its `AGENTS.md`, use it.
2. Otherwise compare the destination with the source first. If the
   destination differs in a way that is not explained by your own source
   change, show the difference and STOP until the user reconciles it.
3. Replace the whole destination directory with a copy of the source,
   including `scripts/`, `references/`, and `assets/`, preserving executable
   bits. Add nothing to the copy, not even a "generated" marker.
4. Never edit both copies independently.

Do not use symlinks, and do not rely on `.gitignore`, `.clineignore`, or
another ignore file to deduplicate skills.

## 6. Validate

Run these checks and fix every failure before reporting:

- [ ] Each `SKILL.md` exists, its frontmatter parses, and it has only `name`
      and `description`.
- [ ] `name` matches the directory and the naming rules; `description` is at
      most 1,024 characters and trigger-oriented.
- [ ] `SKILL.md` is under 24,000 bytes.
- [ ] No host-only invocation, interpolation, frontmatter, or internal tool
      name is required for the skill to work.
- [ ] Every file the skill references exists, relative to the skill
      directory.
- [ ] Each mirror matches its source byte for byte, with the same executable
      bits. Examples: POSIX `diff -r <source> <mirror>`; PowerShell compare
      `Get-FileHash` over `Get-ChildItem -Recurse -File` of both trees.
- [ ] `AGENTS.md` holds the shared rules; `CLAUDE.md` imports it exactly
      once; `.gemini/settings.json` lists `AGENTS.md` in `context.fileName`.
- [ ] No project `GEMINI.md`; no rule body loaded twice through a host rules
      directory; nothing behavioral in `.codex/rules/`; no delegating
      `.clinerules/workflows/` shims.
- [ ] User-owned instructions and settings that existed before are intact.
- [ ] If a host validator is available, run it, for example
      `claude plugin validate .claude/skills`.

You usually cannot open fresh sessions in other harnesses. List the
fresh-session checks from the guide's "Validation checklist" for the user to
run in each selected harness: natural-language activation, explicit
invocation, the skill listed once, loaded instructions summarized, and a
clean stop when required input is missing. Remind the user to trust the
project first in Gemini CLI.

## 7. Report

Report:

- the authoritative files created or changed;
- the generated adapters and mirrors created or regenerated;
- user-owned files you merged into, and what you preserved;
- the validation you ran and its results;
- same-name collisions and override risks that remain;
- anything intentionally not done, such as host-only enforcement left for
  host configuration;
- the explicit invocation for each selected harness, plus the portable form
  "Use the `<name>` skill."

## Stop conditions

STOP and ask the user when:

- a generated copy contains edits that are not in its source;
- writing would overwrite or reorder user-owned content in an instruction or
  settings file;
- the required scope, harness set, or skill purpose cannot be determined;
- a same-name skill elsewhere would override the one you are writing and the
  user has not chosen how to resolve it;
- a destination is not writable without elevated privileges.
