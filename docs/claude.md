# Claude Code guide

Verified against current Anthropic documentation on 2026-07-29.

> **Type:** Claude Code is a coding harness/client. Claude is the model-driven
> agent operating in it. This guide does not describe the separate Claude
> desktop/web skill installation surfaces.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent instructions | `CLAUDE.md` or `.claude/CLAUDE.md`; optional `CLAUDE.local.md` | `~/.claude/CLAUDE.md` |
| Modular rules | `.claude/rules/**/*.md` | `~/.claude/rules/**/*.md` |
| Agent Skills | `.claude/skills/<name>/SKILL.md` | `~/.claude/skills/<name>/SKILL.md` |
| Legacy custom commands | `.claude/commands/*.md` | `~/.claude/commands/*.md` |

## Bridge `AGENTS.md`

Claude Code explicitly reads `CLAUDE.md`, not `AGENTS.md`. The official bridge
is:

```markdown
@AGENTS.md
```

Imports resolve relative to the file containing them and may nest up to four
hops. This lets `AGENTS.md` remain the one authoritative universal rules file.
Add Claude-only guidance below the import if required.

Do not also copy the imported body into `.claude/rules`; that gives Claude the
same instructions twice. Use `.claude/rules` for genuinely modular or
path-scoped Claude adapters. Rules without `paths` frontmatter load at launch;
path-scoped rules load when matching files become relevant.

Claude Code discovers `CLAUDE.md` files in the hierarchy above the working
directory at launch and discovers files below it on demand. Verify the resolved
set with `/context` or `/memory`.

## Skills and commands

Claude Code project skills must be under
`.claude/skills/<name>/SKILL.md`. It can select them from the description or
invoke them as `/skill-name`.

Custom commands have been merged into skills. Existing
`.claude/commands/<name>.md` files still work, but skills are preferred because
they bundle supporting files and support implicit activation. Convert a
portable command or workflow into a standard skill, then retire the command
once callers have migrated.

Claude Code offers host-only frontmatter, including:

- `argument-hint`, `arguments`, and dynamic substitutions;
- `disable-model-invocation` and `user-invocable`;
- `allowed-tools` and `disallowed-tools`;
- `model`, `effort`, `context`, `agent`, and `background`;
- `hooks`, `paths`, and dynamic shell context.

Do not put these fields or substitutions in a universal `SKILL.md`. If one is
essential, maintain a clearly labeled Claude-specific variant.

Although current Claude Code can follow individual symlinked skill entries,
the universal repository policy does not use them. It uses full generated
copies so Windows privilege settings, Git checkout configuration, and other
harnesses' undocumented link behavior cannot break discovery.

## Universal layout

In the shared layout:

```text
AGENTS.md
CLAUDE.md                         # @AGENTS.md
.agents/skills/<name>/            # authoritative universal source
.claude/skills/<name>/            # byte-identical generated shim
```

Claude Code uses `CLAUDE.md` and `.claude/skills`. It does not discover the
`.agents/skills` source just because `AGENTS.md` mentions it.

## Validate

1. Start a fresh session and run `/context`; confirm `CLAUDE.md` and its
   `AGENTS.md` import are present.
2. Run `/skills`; confirm the generated skill shim appears once.
3. Invoke `/skill-name` and test natural-language activation separately.
4. Check enterprise, personal, project, plugin, and legacy command scopes for
   same-name overrides.
5. Confirm no equivalent `.claude/rules` body duplicates `@AGENTS.md`.

## Official sources

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Extend Claude with skills](https://code.claude.com/docs/en/slash-commands)
- [Explore the `.claude` directory](https://code.claude.com/docs/en/claude-directory)
- [Debug your configuration](https://code.claude.com/docs/en/debug-your-config)
