# Universal skills, rules, and workflows

Verified against current official documentation on 2026-07-29.

This is the cross-harness authoring guide for:

- [Antigravity CLI (`agy`)](docs/agy.md)
- [OpenAI Codex](docs/codex.md)
- [Claude Code](docs/claude.md)
- [Cline](docs/cline.md)
- [Pi](docs/pi.md)

The names are easy to blur together. In this guide, a **harness** is the client
or runtime that discovers instructions, exposes tools, and runs an agent loop.
An **agent** is the model-driven worker operating inside that harness. Some
products, especially Codex, use “agent” for the whole product as well. The
guides state which meaning applies.

The portable goal is semantic compatibility: one meaning, expressed through
the smallest number of host discovery adapters. Discovery paths, invocation
syntax, conditional-rule metadata, permissions, hooks, and dedicated workflow
formats are not universal.

## Short answer: can `AGENTS.md` remove all shims?

No, not across all five documented harnesses.

- `agy`, Codex, Cline, and Pi read project `AGENTS.md` natively.
- Claude Code explicitly reads `CLAUDE.md`, not `AGENTS.md`. Its documented
  bridge is a one-line `CLAUDE.md` import: `@AGENTS.md`.
- `AGENTS.md` can tell an already-running agent to read another file, but it
  cannot add that file to a harness's skill registry. Registry discovery,
  metadata loading, implicit activation, and slash-command completion happen
  through host-supported skill locations.
- Claude Code still needs project skills under `.claude/skills`. Codex, `agy`,
  and Pi share `.agents/skills`. Cline documents `.claude/skills` as a
  compatibility project path, so it does not need a third project copy.

The selected policy is **generated shims**:

- `CLAUDE.md` is a thin rules shim that imports the authoritative
  `AGENTS.md`.
- `.claude/skills/<name>/` is a full generated skill shim: a byte-identical
  mirror of the authoritative `.agents/skills/<name>/` directory.
- `.clinerules/workflows/<name>.md` is a thin generated invocation shim that
  tells Cline to use the corresponding skill.
- Symlinks are not used. This avoids Windows privilege and Git checkout
  differences, plus undocumented link behavior in some harnesses.

The project layout is therefore:

```text
AGENTS.md
CLAUDE.md                              # contains @AGENTS.md
.agents/
  skills/<name>/SKILL.md               # authoritative: agy + Codex + Pi
.claude/
  skills/<name>/SKILL.md               # generated shim: Claude Code + Cline
.clinerules/
  workflows/<name>.md                  # generated Cline shortcut
```

This is one authoritative rules file plus one bridge, and two skill discovery
trees. Only `AGENTS.md` and `.agents/skills` are edited by hand. The Claude
files and Cline workflow shortcuts are adapters and must be regenerated from
those sources.

## Compatibility summary

| Host | What it is | Reads project `AGENTS.md`? | Documented project skill path used here | Portable workflow form |
| --- | --- | --- | --- | --- |
| `agy` | Antigravity's terminal harness | Yes | `.agents/skills/<name>/SKILL.md` | Agent Skill |
| Codex | Coding-agent product and harness family; this guide targets local CLI/IDE discovery | Yes | `.agents/skills/<name>/SKILL.md` | Agent Skill |
| Claude Code | Coding harness/client for Claude agents | No; import it from `CLAUDE.md` | `.claude/skills/<name>/SKILL.md` | Agent Skill |
| Cline | Model-provider-independent coding harness/client | Yes | `.claude/skills/<name>/SKILL.md` | Agent Skill plus generated workflow shortcut |
| Pi | Minimal terminal coding harness | Yes | `.agents/skills/<name>/SKILL.md` | Agent Skill |

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

Add this bridge for Claude Code:

```markdown
@AGENTS.md
```

Claude Code expands the import at startup. Do not also copy the same body into
`.claude/rules/`, because that loads the same instruction twice. Add
Claude-only content below the import only when it is genuinely host-specific.

Nested instruction semantics differ. Codex, Claude Code, and Pi walk directory
hierarchies in different ways, while Cline's primary rules system is rooted in
`.clinerules/`. Treat a root `AGENTS.md` as the portable baseline. Add nested or
path-scoped adapters only after reading the relevant harness guide.

Never put behavioral Markdown in Codex `.codex/rules/*.rules`; those files are
Starlark command-execution policies.

## Author a universal skill

Use `.agents/skills/<skill-name>/` as the authoritative project source and
generate a complete shim at `.claude/skills/<skill-name>/`.

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

- Use only `name` and `description` in shared YAML frontmatter.
- Make `name` lowercase kebab-case, no more than 64 characters, and identical
  to the directory name.
- Keep `description` at or below 1,024 characters. Put the action, trigger
  phrases, and important non-triggers first.
- Write the body in imperative, agent-neutral language.
- Request inputs in prose. Do not depend on `$ARGUMENTS`, positional
  substitution, dynamic shell interpolation, or session variables.
- Refer to another skill as “the `other-skill` skill,” not `/other-skill`,
  `$other-skill`, or a host tool call.
- Describe outcomes such as “search the repository”; do not name a harness's
  internal tool such as Cline's `use_skill`.
- Put detailed reference material in `references/`, deterministic helpers in
  `scripts/`, and templates or output resources in `assets/`.
- Keep relative links anchored to the skill directory.
- State inputs, side effects, stopping conditions, validation, and final output.
- Keep one skill focused on one user goal.

Vendor-only frontmatter belongs in a host-specific fork, not in the universal
copy. Examples include Claude Code's `allowed-tools`, `context`, `agent`,
`disable-model-invocation`, `hooks`, and argument fields.

## Turn a vendor workflow into a universal skill

Claude commands, Cline workflows, Pi prompt templates, and Antigravity
workflows are convenient host interfaces, but their invocation and
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
8. Regenerate the full `.claude/skills/<name>/` shim.
9. Generate the Cline invocation shim at
   `.clinerules/workflows/<name>.md`.
10. Test implicit and explicit activation in every selected harness.
11. Retire any old workflow that duplicates the procedure after confirming
    nothing still invokes it.

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

For each skill, also generate this Cline workflow shortcut:

```markdown
# Use the skill

Use the `skill-name` skill for this request. Follow its `SKILL.md`
instructions exactly. Use relevant context already supplied by the user and
ask for any required input that is missing.
```

Save it as `.clinerules/workflows/skill-name.md`. The shortcut contains no
copy of the workflow procedure, scripts, or host-specific argument
interpolation. Its only job is to route `/skill-name.md` to the authoritative
skill. Cline also exposes the skill's native `/skill-name` command; this extra
workflow shortcut is a project policy, not a requirement of Cline's skills
system.

Do not rely on `.gitignore`, `.clineignore`, or another context-ignore file to
deduplicate a skill registry unless that harness explicitly documents the
behavior. File visibility and skill discovery are separate mechanisms.

### Collision warning for Cline

Cline's current skills page documents `.claude/skills` but not
`.agents/skills`. Its changelog and GitHub's current `gh skill install`
documentation also show emerging `.agents/skills` support. A version that scans
both trees may see the authoritative and shim copies. Keep them byte-identical
and inspect Cline's resolved Skills panel or `/skills` output. Do not assume
deduplication or precedence.

## User-global installs

There is no single fully documented global skill directory for all five.

| Host | Current documented global skill location |
| --- | --- |
| `agy` CLI | `~/.gemini/antigravity-cli/skills/<name>/` |
| Codex | `~/.agents/skills/<name>/` |
| Claude Code | `~/.claude/skills/<name>/` |
| Cline | `~/.cline/skills/<name>/` |
| Pi | `~/.agents/skills/<name>/` or `~/.pi/agent/skills/<name>/` |

Thus `~/.agents/skills` can be the global authoritative tree for Codex and Pi, but
`agy`, Claude Code, and Cline still need documented host copies. Global
instructions also differ: Codex uses `~/.codex/AGENTS.md`, `agy` uses
`~/.gemini/GEMINI.md`, Claude uses `~/.claude/CLAUDE.md`, Cline reads
`~/.agents/AGENTS.md`, and Pi uses `~/.pi/agent/AGENTS.md`.

Global copies are per-user, per-machine, and single-version. Updating one
changes behavior for every project using it. Merge into user-owned instruction
files; never overwrite them wholesale.

## Invocation wording

Portable documentation should say:

> Ask the agent to use the `skill-name` skill.

Host-specific shortcuts:

| Host | Explicit selection |
| --- | --- |
| `agy` | `/skill-name` in the CLI; a clear name mention also works |
| Codex | Type `$` and select the skill, or use `/skills` |
| Claude Code | `/skill-name` |
| Cline | `/skill-name.md` through the generated workflow shortcut; native `/skill-name` also remains available |
| Pi | `/skill:skill-name` when skill commands are enabled |

Never make success depend on slash autocomplete. A clear description must
support implicit activation, and plain-language name mention remains the
fallback.

## Validation checklist

For every skill:

- [ ] `SKILL.md` exists and its YAML parses.
- [ ] Frontmatter contains only `name` and `description`.
- [ ] The name matches the directory and satisfies the portable naming rules.
- [ ] The description is trigger-oriented and no longer than 1,024 characters.
- [ ] No host-only invocation, interpolation, frontmatter, or tool name remains.
- [ ] Every referenced resource exists.
- [ ] Side effects, stopping conditions, validation, and output are explicit.
- [ ] `.agents/skills/<name>` and `.claude/skills/<name>` match byte-for-byte.
- [ ] `.clinerules/workflows/<name>.md` exists and only delegates to the
      corresponding skill.

For the repository:

- [ ] `AGENTS.md` contains the shared rules.
- [ ] `CLAUDE.md` imports `AGENTS.md` exactly once.
- [ ] The same rule body is not also auto-loaded from a host rules directory.
- [ ] No behavioral guidance was placed in Codex `.codex/rules`.
- [ ] Existing user-owned instructions survived migration.
- [ ] Each harness lists the expected skill once.
- [ ] Each Cline skill has a `/skill-name.md` workflow shortcut.

In a fresh session for every harness:

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
- [`docs/cline.md`](docs/cline.md)
- [`docs/pi.md`](docs/pi.md)

Re-check the linked official sources before broad migrations. Discovery paths,
precedence, and invocation features change faster than the Agent Skills file
format.
