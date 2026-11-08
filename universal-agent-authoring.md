# Universal skills, rules, and workflows

Verified against current official documentation on 2026-11-08.

This is the cross-harness authoring guide for:

- [Antigravity CLI (`agy`)](docs/agy.md)
- [OpenAI Codex](docs/codex.md)
- [Claude Code](docs/claude.md)
- [Gemini CLI](docs/gemini.md)
- [Cline](docs/cline.md)
- [OpenCode](docs/opencode.md)

The names are easy to blur together. In this guide, a **harness** is the client
or runtime that discovers instructions, exposes tools, and runs an agent loop.
An **agent** is the model-driven worker operating inside that harness. Some
products, especially Codex, use “agent” for the whole product as well. The
guides state which meaning applies.

The portable goal is semantic compatibility: one meaning, expressed through
the smallest number of host discovery adapters. Discovery paths, invocation
syntax, conditional-rule metadata, permissions, hooks, and dedicated workflow
formats are not universal.

## Short answer: can `AGENTS.md` and `.agents/skills` remove all shims?

Almost, but not across all six documented harnesses.

- `agy`, Codex, Cline, and OpenCode read project `AGENTS.md` natively.
- Claude Code reads `AGENTS.md` natively since v2.1.277, but only when no
  `CLAUDE.md` or `CLAUDE.local.md` exists, and not in every session. A
  one-line `CLAUDE.md` containing `@AGENTS.md` makes loading deterministic and
  never causes a double read.
- Gemini CLI reads `GEMINI.md` by default. Its `context.fileName` setting in
  `.gemini/settings.json` makes it read `AGENTS.md` instead.
- `agy`, Codex, Gemini CLI, Cline, and OpenCode all discover
  `.agents/skills`.
- Claude Code still discovers project skills only under `.claude/skills`, so
  it needs a generated mirror.
- `AGENTS.md` can tell an already-running agent to read another file, but it
  cannot add that file to a harness's skill registry. Registry discovery,
  metadata loading, implicit activation, and slash-command completion happen
  through host-supported skill locations.

The selected policy is **generated shims**:

- `CLAUDE.md` is a thin rules bridge that imports the authoritative
  `AGENTS.md`.
- `.gemini/settings.json` is a thin settings adapter that points Gemini CLI at
  `AGENTS.md`.
- `.claude/skills/<name>/` is a full generated skill mirror: a byte-identical
  copy of the authoritative `.agents/skills/<name>/` directory.
- Symlinks are not used. This avoids Windows privilege and Git checkout
  differences, plus differing link behavior across harnesses.

The project layout is therefore:

```text
AGENTS.md                              # authoritative rules
CLAUDE.md                              # bridge: @AGENTS.md (Claude Code)
.gemini/
  settings.json                        # adapter: context.fileName (Gemini CLI)
.agents/
  skills/<name>/SKILL.md               # authoritative: agy, Codex, Gemini CLI, Cline, OpenCode
.claude/
  skills/<name>/SKILL.md               # generated mirror: Claude Code
```

Only `AGENTS.md` and `.agents/skills` are edited by hand. `CLAUDE.md` and
`.gemini/settings.json` change only when their host requirements change, and
the `.claude/skills` mirror is regenerated from the source.

## Compatibility summary

| Host | What it is | Reads project `AGENTS.md`? | Reads `.agents/skills`? | Adapter in this layout |
| --- | --- | --- | --- | --- |
| `agy` | Antigravity's terminal harness | Yes | Yes | None |
| Codex | Coding-agent product and harness family; this guide targets local CLI/IDE discovery | Yes | Yes | None |
| Claude Code | Coding harness/client for Claude agents | Yes (v2.1.277+), only without `CLAUDE.md`; bridge with `@AGENTS.md` | No; `.claude/skills` | `CLAUDE.md`, `.claude/skills` mirror |
| Gemini CLI | Google's open-source terminal harness | Only via `context.fileName` | Yes (alias, preferred over `.gemini/skills`) | `.gemini/settings.json` |
| Cline | Model-provider-independent coding harness/client | Yes | Yes | None |
| OpenCode | Open-source, provider-independent coding harness (V2) | Yes (`AGENTS.md` only; no `CLAUDE.md` fallback) | Yes | None |

See the harness-specific guides for user-global paths, precedence, invocation
syntax, dedicated rules, and vendor workflows.

## Choose the artifact

Use this order:

1. For durable repository facts and expectations that matter on nearly every
   task, write `AGENTS.md`.
2. For a repeatable task with steps, inputs, validation, and an output, write an
   Agent Skill. This is the universal workflow format.
3. For instructions that activate only for certain paths, keep the semantic
   rule shared but add host-specific conditional-rule adapters. There is no
   common path-rule frontmatter across these harnesses.
4. For hard enforcement—command permission, sandboxing, hooks, or tool
   allow/deny policy—use host configuration. Prompt rules are guidance, not a
   security boundary.
5. For live data or controlled external actions, keep the procedure in a skill
   and configure MCP/plugins separately for each host.

## Author universal persistent rules

Put the shared repository contract directly in `AGENTS.md`. Keep it concise and
include only information an agent cannot reliably infer from the repository:

- build, test, and validation commands;
- architectural boundaries and repository-specific conventions;
- destructive or externally visible actions that require confirmation;
- completion and reporting expectations;
- pointers to optional, task-specific skills.

Keep it well under the smallest host budget: Codex stops at 32 KiB of combined
project instructions, and `agy` truncates a rule file at 24,000 bytes.

Add the Claude Code bridge as `CLAUDE.md`:

```markdown
@AGENTS.md
```

Add the Gemini CLI adapter as `.gemini/settings.json` (merge into an existing
file rather than replacing it):

```json
{
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
```

Do not create a project `GEMINI.md`. `agy` reads `GEMINI.md` and `AGENTS.md`
cumulatively, so a `GEMINI.md` copy or bridge loads extra or duplicate rules
there. Do not copy the `AGENTS.md` body into `.claude/rules/`, `.agents/rules/`,
or `.cline/rules/` either; each would load the same instruction twice. Add
host-only content below the `CLAUDE.md` import, or in that host's rules
directory, only when it is genuinely host-specific.

Nested instruction semantics differ. Codex reads one file per directory from
the project root down; Claude Code loads ancestors at launch and subdirectories
on demand; `agy` loads the workspace and its parents but not subfolders; Gemini
CLI adds files just in time as tools touch paths; OpenCode combines ancestors
nearest-first rather than root-first. Treat a root `AGENTS.md` as
the portable baseline. Add nested or path-scoped adapters only after reading
the relevant harness guide.

Never put behavioral Markdown in Codex `.codex/rules/*.rules`; those files are
Starlark command-execution policies.

## Author a universal skill

Use `.agents/skills/<skill-name>/` as the authoritative project source and
generate a complete mirror at `.claude/skills/<skill-name>/`.

Minimum `SKILL.md`:

```markdown
---
name: skill-name
description: State what this skill does and the requests or situations that should trigger it.
---

# Skill title

1. Read the required project context.
2. Perform the task.
3. Run the relevant validation.
4. Report the result and anything intentionally unresolved.
```

Apply these portability constraints:

- Use only `name` and `description` in shared YAML frontmatter, and always
  include both.
- Make `name` lowercase kebab-case, no more than 64 characters, and identical
  to the directory name.
- Keep `description` at or below 1,024 characters (Cline's limit). Put the
  action, trigger phrases, and important non-triggers first. Quote it if it
  contains a colon.
- Keep the `SKILL.md` body under 24 KB (`agy`'s limit) and preferably under
  about 5k tokens and 500 lines.
- Write the body in imperative, agent-neutral language.
- Request inputs in prose. Do not depend on `$ARGUMENTS`, `{{args}}`,
  positional substitution, dynamic shell interpolation, or session variables.
- Refer to another skill as “the `other-skill` skill,” not `/other-skill`,
  `$other-skill`, or a host tool call.
- Describe outcomes such as “search the repository”; do not name a harness's
  internal tool such as Gemini CLI's `activate_skill`, Cline's `skills` tool,
  or OpenCode's `skill` tool.
- Put detailed reference material in `references/`, deterministic helpers in
  `scripts/`, and templates or output resources in `assets/`.
- Keep relative links anchored to the skill directory.
- State inputs, side effects, stopping conditions, validation, and final output.
- Keep one skill focused on one user goal.

Vendor-only frontmatter and metadata belong in a host-specific fork or sidecar,
not in the universal copy. Examples include Claude Code's `when_to_use`,
`allowed-tools`, `context`, `agent`, `disable-model-invocation`, `hooks`, and
argument fields, Codex's `agents/openai.yaml`, and OpenCode's
`metadata.opencode/autoinvoke`.

## Turn a vendor workflow into a universal skill

Claude commands, Gemini CLI TOML commands, OpenCode commands, Cline
workflows, and Antigravity workflows are convenient host interfaces, but their invocation and
interpolation syntax are not portable.

To migrate one:

1. Capture its purpose, trigger phrases, required inputs, ordered steps, side
   effects, validation, and final output.
2. Create `.agents/skills/<name>/SKILL.md`.
3. Put selection clues in `description` and the procedure in the body.
4. Replace host argument variables with prose such as “Use the path supplied by
   the user; ask if it is missing.”
5. Replace nested slash-command calls with semantic skill references.
6. Replace host tool names with the result that must be achieved.
7. Move deterministic logic to `scripts/` only when instructions are not
   reliable enough.
8. Regenerate the full `.claude/skills/<name>/` mirror.
9. Test implicit and explicit activation in every selected harness.
10. Retire any old command or workflow that duplicates the procedure after
    confirming nothing still invokes it.

If the vendor workflow has behavior a skill cannot express, split it: keep
portable reasoning and procedure in the skill, and put host automation in a
clearly labeled adapter, hook, extension, or plugin.

## Keep generated shims safe

Treat `.agents/skills` as authoritative and `.claude/skills` as generated:

- never edit both copies independently;
- copy the whole directory, including scripts, references, and assets;
- keep the generated copy byte-identical—do not add a shim marker inside its
  `SKILL.md`;
- compare the two trees byte-for-byte in CI;
- preserve executable bits on scripts;
- fail a sync if the destination contains unrecognized user edits;
- audit global and project paths for the same skill name.

The sync operation must be one-way:

```text
.agents/skills/<name>/  ->  .claude/skills/<name>/
```

An agent performing the sync must first compare the destination, warn if it
contains divergent user edits, and replace it only after those edits have been
reconciled. This keeps regeneration idempotent without silently losing work.

Do not rely on `.gitignore`, `.clineignore`, or another context-ignore file to
deduplicate a skill registry unless that harness explicitly documents the
behavior. File visibility and skill discovery are separate mechanisms.

### Hosts that see both trees

Cline scans both `.agents/skills` and `.claude/skills`. In current upstream
source it deduplicates by `name` and resolves the project skill to
`.agents/skills`; that order is not in Cline's published docs. Keep the trees
byte-identical so either resolution behaves the same, and inspect the Skills
panel after upgrading.

OpenCode also scans both trees and documents its order: `.agents/skills` is
registered after `.claude/skills`, so the `.agents/skills` copy wins. A same-ID
skill in `.opencode/skills` or `~/.config/opencode/skills` still overrides
both.

`agy`, Codex, and Gemini CLI do not scan `.claude/skills`. Claude Code does not
scan `.agents/skills`.

### Migrating from the earlier layout

Earlier versions of these guides also generated
`.clinerules/workflows/<name>.md` shortcuts for Cline and documented Pi. Cline
now exposes skills natively as `/skill-name` and shows same-name workflows as
separate menu entries, so delete generated shortcuts that only delegated to a
skill. Pi is no longer in scope; Pi-specific files such as `.pi/` are outside
this layout and should be left to their owners.

## User-global installs

There is no single global skill directory that all six read.

| Host | Global skill locations | Global instructions |
| --- | --- | --- |
| `agy` | `~/.gemini/antigravity-cli/skills/`, `~/.gemini/skills/`, `~/.gemini/config/skills/` | `~/.gemini/GEMINI.md` or `~/.gemini/AGENTS.md` |
| Codex | `~/.agents/skills/` | `~/.codex/AGENTS.md` |
| Claude Code | `~/.claude/skills/` | `~/.claude/CLAUDE.md` |
| Gemini CLI | `~/.agents/skills/` or `~/.gemini/skills/` | `~/.gemini/GEMINI.md` |
| Cline | `~/.agents/skills/` or `~/.cline/skills/` | `~/.agents/AGENTS.md` |
| OpenCode | `~/.config/opencode/skills/`, `~/.agents/skills/`, or `~/.claude/skills/` | `~/.config/opencode/AGENTS.md` |

A practical global layout:

```text
~/.agents/skills/<name>/                     # authoritative: Codex, Gemini CLI, Cline, OpenCode
~/.claude/skills/<name>/                     # generated mirror: Claude Code
~/.gemini/antigravity-cli/skills/<name>/     # generated mirror: agy
```

Use the `agy`-specific folder rather than `~/.gemini/skills/`, which Gemini
CLI also reads and would list as a duplicate of `~/.agents/skills/`.

`~/.gemini/GEMINI.md` serves both `agy` and Gemini CLI. The other global
instruction files are separate per host.

Global copies are per-user, per-machine, and single-version. Updating one
changes behavior for every project using it, and some hosts (Claude Code,
Cline, and OpenCode's `~/.config/opencode/skills`) let a global skill override
a same-name project skill. Merge into
user-owned instruction files; never overwrite them wholesale.

## Invocation wording

Portable documentation should say:

> Ask the agent to use the `skill-name` skill.

Host-specific shortcuts:

| Host | Explicit selection |
| --- | --- |
| `agy` | `/skill-name` |
| Codex | Type `$` and select the skill, or use `/skills` |
| Claude Code | `/skill-name` |
| Gemini CLI | Name the skill in the prompt; no per-skill slash command yet (optional `.gemini/commands/<name>.toml` adapter) |
| Cline | `/skill-name` |
| OpenCode | `@skill-name` in the prompt (optional `.opencode/commands/<name>.md` adapter for a slash shortcut) |

Never make success depend on slash autocomplete. A clear description must
support implicit activation, and plain-language name mention remains the
fallback.

## Validation checklist

For every skill:

- [ ] `SKILL.md` exists and its YAML parses.
- [ ] Frontmatter contains only `name` and `description`.
- [ ] The name matches the directory and satisfies the portable naming rules.
- [ ] The description is trigger-oriented and no longer than 1,024 characters.
- [ ] The body is under 24 KB.
- [ ] No host-only invocation, interpolation, frontmatter, or tool name remains.
- [ ] Every referenced resource exists.
- [ ] Side effects, stopping conditions, validation, and output are explicit.
- [ ] `.agents/skills/<name>` and `.claude/skills/<name>` match byte-for-byte.

For the repository:

- [ ] `AGENTS.md` contains the shared rules.
- [ ] `CLAUDE.md` imports `AGENTS.md` exactly once.
- [ ] `.gemini/settings.json` lists `AGENTS.md` in `context.fileName`.
- [ ] No project `GEMINI.md` exists.
- [ ] The same rule body is not also auto-loaded from a host rules directory.
- [ ] No behavioral guidance was placed in Codex `.codex/rules`.
- [ ] No legacy delegating `.clinerules/workflows/<name>.md` shims remain.
- [ ] Existing user-owned instructions survived migration.
- [ ] Each harness lists the expected skill once.

In a fresh session for every harness (trust the project first wherever the
harness asks; Gemini CLI ignores workspace settings and skills otherwise):

1. Ask a natural-language request that should select the skill.
2. Invoke the skill explicitly with that harness's syntax.
3. Inspect the discovered skill list and resolve duplicate names.
4. Ask the agent to summarize its loaded project instructions.
5. Confirm missing required input causes a question or a clean stop.
6. Confirm the workflow produces the same required result.

## Harness details

The per-harness guides are the source of truth for host-specific behavior:

- [`docs/agy.md`](docs/agy.md)
- [`docs/codex.md`](docs/codex.md)
- [`docs/claude.md`](docs/claude.md)
- [`docs/gemini.md`](docs/gemini.md)
- [`docs/cline.md`](docs/cline.md)
- [`docs/opencode.md`](docs/opencode.md)

Re-check the linked official sources before broad migrations. Discovery paths,
precedence, and invocation features change faster than the Agent Skills file
format.
