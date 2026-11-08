# Multi-harness authoring guides

Create skills, rules, and repeatable workflows once—then make them work
reliably across multiple coding-agent harnesses.

This repository is a public, vendor-neutral playbook for:

- Google Antigravity CLI (`agy`)
- OpenAI Codex
- Claude Code
- Google Gemini CLI
- Cline
- OpenCode

It separates portable behavior from host-specific discovery, invocation, and
enforcement. The result is one authoritative workflow or rule with small,
generated adapters instead of several independently maintained versions.

> This is a community-maintained documentation project. It is not affiliated
> with, endorsed by, or an official publication of Google, OpenAI, Anthropic,
> Cline, or the OpenCode maintainers.

## Scope

The documented Antigravity target is the `agy` CLI. Antigravity Desktop/IDE is
not currently part of the compatibility contract. Gemini CLI is covered as a
separate harness from `agy`.

Pi and other harnesses are no longer in scope. Earlier versions of these guides
documented Pi; that guide has been removed.

The guides cover:

- project and user-global instruction discovery;
- Agent Skill locations and portable `SKILL.md` authoring;
- explicit invocation shortcuts;
- rules and reusable workflow equivalents;
- generated compatibility shims;
- collision detection and validation.

They do not attempt to unify host permissions, hooks, sandbox policy, model
configuration, plugins, or MCP authentication. Those remain host-specific.

## Why use these guides?

Agent harnesses increasingly share concepts such as `AGENTS.md` and
`SKILL.md`, but they do not share every filesystem path or user interface.

These guides help you:

- write Agent Skills that remain portable;
- maintain one authoritative set of repository rules;
- use each harness's native explicit invocation, without wrapper files;
- generate only the shims that are actually required;
- avoid duplicate skill discovery and drifting copies;
- keep permissions, hooks, and other enforcement host-specific;
- migrate legacy commands and workflows without retaining two sources of
  truth.

## Start here

Choose the guide that matches your task:

| Goal | Read |
| --- | --- |
| Create or migrate something for all supported harnesses | [Universal skills, rules, and workflows](universal-agent-authoring.md) |
| Configure Antigravity CLI | [`agy` guide](docs/agy.md) |
| Configure OpenAI Codex | [Codex guide](docs/codex.md) |
| Configure Claude Code | [Claude Code guide](docs/claude.md) |
| Configure Gemini CLI | [Gemini CLI guide](docs/gemini.md) |
| Configure Cline | [Cline guide](docs/cline.md) |
| Configure OpenCode | [OpenCode guide](docs/opencode.md) |

The universal guide is normative for shared authoring. Each harness guide
explains how that shared design maps to its native discovery paths, rule
systems, workflow features, invocation syntax, and validation tools.

## Repository structure

```text
.
├── README.md
├── universal-agent-authoring.md
└── docs/
    ├── agy.md
    ├── codex.md
    ├── claude.md
    ├── gemini.md
    ├── cline.md
    └── opencode.md
```

## Recommended universal layout

```text
AGENTS.md
CLAUDE.md
.gemini/
  settings.json
.agents/
  skills/<name>/SKILL.md
.claude/
  skills/<name>/SKILL.md
```

Ownership:

- `AGENTS.md` is the authoritative persistent project guidance.
- `CLAUDE.md` is a rules bridge containing `@AGENTS.md` for Claude Code.
- `.gemini/settings.json` sets `context.fileName` so Gemini CLI reads
  `AGENTS.md`.
- `.agents/skills/<name>/` is the authoritative skill source.
- `.claude/skills/<name>/` is a byte-identical generated skill mirror for
  Claude Code.

Antigravity CLI, Codex, Gemini CLI, Cline, and OpenCode read the
authoritative `.agents/skills` tree directly. Claude Code is the only harness
that needs a skill copy; Cline and OpenCode also see it but resolve to the
`.agents/skills` source.

## Explicit invocation

| Harness | Shortcut |
| --- | --- |
| Antigravity CLI | `/skill-name` |
| Codex | Select `$skill-name`, or browse with `/skills` |
| Claude Code | `/skill-name` |
| Gemini CLI | Name the skill in the prompt; no per-skill slash command yet |
| Cline | `/skill-name` |
| OpenCode | `@skill-name` in the prompt |

Plain-language invocation remains portable:

> Use the `skill-name` skill.

## Instructions for agents

If you are an agent asked to create, migrate, or update skills, rules, or
workflows in a repository using these guides:

1. Determine whether the requested artifact is universal or restricted to one
   harness.
2. For a universal artifact, read
   [the universal authoring guide](universal-agent-authoring.md) completely.
3. Read every harness guide that is in scope before choosing paths or
   frontmatter.
4. Inspect existing `AGENTS.md`, `CLAUDE.md`, discovery directories, and
   same-name skills before writing.
5. Preserve user-owned instructions and reconcile divergent generated files
   before replacing them.
6. Edit only the authoritative source:
   - persistent rules in `AGENTS.md`;
   - skills in `.agents/skills/<name>/`.
7. Regenerate required shims:
   - `CLAUDE.md`;
   - `.gemini/settings.json` (merge; never overwrite user settings);
   - `.claude/skills/<name>/`.
8. Keep permissions, hooks, sandbox settings, plugins, and conditional rule
   metadata host-specific.
9. Validate discovery and explicit invocation in a fresh session for every
   selected harness.
10. Report the authoritative files, generated adapters, validation performed,
    and any unresolved discovery collisions.

Do not assume that `AGENTS.md` can register skills from arbitrary directories.
Persistent instructions can tell an agent what to read, but skill discovery,
metadata loading, and command completion are controlled by the harness.

## Universal or harness-specific?

Create a universal artifact when:

- the same user goal and procedure should work across harnesses;
- only discovery or invocation differs;
- the workflow can use agent-neutral instructions and resources.

Create a harness-specific artifact when:

- it depends on proprietary frontmatter or argument interpolation;
- it configures permissions, hooks, sandboxing, models, or tools;
- it relies on a dedicated host workflow engine;
- its behavior cannot be expressed as a portable Agent Skill.

When both are needed, keep the reasoning and procedure in the universal skill
and make the host-specific artifact a thin adapter.

## Documentation freshness

The guides were checked against current official documentation on 2026-11-08.
Vendor discovery paths and invocation features can change, so each
harness-specific guide ends with the official sources used for verification.

When relying on this repository for a migration, re-check the relevant official
sources and report any changed discovery path, precedence rule, or invocation
behavior.

## Contributing

Corrections and compatibility updates are welcome. A useful contribution
should:

1. Limit its claim to a documented harness and product surface.
2. Cite a current primary source, preferably official product documentation or
   released upstream source.
3. State when documentation and observed released behavior disagree.
4. Preserve the distinction between portable semantics and host adapters.
5. Update the verification date only for guides that were actually re-checked.
6. Avoid adding a new supported harness without a complete guide covering
   rules, skills, workflows, invocation, discovery scope, collisions, and
   validation.

Please keep the universal guide normative. Harness guides should explain their
mapping to it rather than copy the whole compatibility policy.

## License

This repository is released under the
[BSD Zero Clause License](LICENSE), SPDX identifier `0BSD`.

Start with [Universal skills, rules, and workflows](universal-agent-authoring.md).
