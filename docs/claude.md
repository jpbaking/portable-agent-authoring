# Claude Code guide

Verified against current Anthropic documentation on 2026-11-08. Observed
locally with Claude Code 2.1.319.

> **Type:** Claude Code is a coding harness/client. Claude is the model-driven
> agent operating in it. This guide does not describe the separate Claude
> desktop/web skill installation surfaces.

## Use these locations

| Artifact | Project | User-global |
| --- | --- | --- |
| Persistent instructions | `CLAUDE.md` or `.claude/CLAUDE.md`; optional `CLAUDE.local.md`; `AGENTS.md` when no `CLAUDE.md` exists (v2.1.277+) | `~/.claude/CLAUDE.md` |
| Modular rules | `.claude/rules/**/*.md` | `~/.claude/rules/**/*.md` |
| Agent Skills | `.claude/skills/<name>/SKILL.md` | `~/.claude/skills/<name>/SKILL.md` |
| Legacy custom commands | `.claude/commands/*.md` | `~/.claude/commands/*.md` |

Managed (organization) instructions live at `/etc/claude-code/CLAUDE.md` on
Linux/WSL, `/Library/Application Support/ClaudeCode/CLAUDE.md` on macOS, and
`C:\Program Files\ClaudeCode\CLAUDE.md` on Windows.

## `AGENTS.md` support

Since v2.1.277, Claude Code reads `AGENTS.md` through a built-in plugin
(`cc-plugin-agents-md@builtin`). The default **Project instructions** mode is
`claude-md-or-agents-md`:

| Repository contains | Claude reads |
| --- | --- |
| `AGENTS.md`, and no `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` at or above the working directory | `AGENTS.md` |
| `AGENTS.md` plus any of those `CLAUDE.md` files | The `CLAUDE.md` files only |
| A `CLAUDE.md` that imports `@AGENTS.md` | `CLAUDE.md`, with `AGENTS.md` included once through the import |

`~/.claude/CLAUDE.md`, managed `CLAUDE.md`, and `.claude/rules/` do not count
for that check; they load alongside `AGENTS.md`. Claude Code does not read
`AGENTS.local.md`, `AGENTS.override.md`, or anything under `.agents/`.

The setting can also be `claude-md-and-agents-md`, `claude-md`, or
`managed-only`, configured through `/config` or in user/managed settings under
`pluginConfigs` → `cc-plugin-agents-md@builtin`. Project settings files cannot
change it.

Direct `AGENTS.md` loading is unavailable when the built-in plugin is disabled,
on some first sessions after upgrading from v2.1.276 or earlier, and, before
v2.1.281, in some sessions such as Amazon Bedrock or telemetry-disabled ones.

## Keep the `@AGENTS.md` bridge

The universal layout still ships a one-line `CLAUDE.md`:

```markdown
@AGENTS.md
```

Anthropic documents that keeping the import never causes a double read under
any **Project instructions** value. It also makes loading deterministic:

- older Claude Code releases and sessions without direct `AGENTS.md` support
  still receive the rules;
- a contributor's personal `CLAUDE.local.md` would otherwise stop Claude from
  reading `AGENTS.md`; with the bridge, `CLAUDE.md` imports it regardless;
- `InstructionsLoaded` hooks fire for an imported `AGENTS.md`, but not for one
  read directly through the setting.

Imports resolve relative to the file containing them and may nest up to four
hops. Add Claude-only guidance below the import if required. A symlinked
`CLAUDE.md` also works, but Windows clones without `core.symlinks` check it out
as a plain one-line file, so the universal policy uses the import.

Do not also copy the imported body into `.claude/rules`; that gives Claude the
same instructions twice. Use `.claude/rules` for genuinely modular or
path-scoped Claude adapters. Rules without `paths` frontmatter load at launch;
path-scoped rules load when matching files become relevant.

Claude Code loads `CLAUDE.md` files from the working directory and every
ancestor at launch, ordered root-first, and loads subdirectory files on demand.
Verify the resolved set with `/memory` or `/context all`.

## Skills and commands

Claude Code project skills must be under `.claude/skills/<name>/SKILL.md`.
It also loads `.claude/skills` in every parent directory up to the repository
root, and nested `<subdir>/.claude/skills` when Claude touches files there.
It does not scan `.agents/skills`.

Precedence on a name collision: enterprise over personal, personal over
project, and a skill over a same-named `.claude/commands` file. Plugin skills
are namespaced as `/plugin-name:skill-name`.

Invoke a skill as `/skill-name`, or let Claude select it from its description.
The combined `description` and `when_to_use` text is truncated at 1,536
characters in the skill listing; the portable 1,024-character limit stays
within that.

Custom commands have been merged into skills. Existing
`.claude/commands/<name>.md` files still work, but convert portable commands
into standard skills and retire the command once callers have migrated.

Claude Code offers host-only frontmatter, including:

- `when_to_use`, `argument-hint`, `arguments`, and `$ARGUMENTS` substitutions;
- `disable-model-invocation` and `user-invocable`;
- `allowed-tools` and `disallowed-tools`;
- `model`, `effort`, `context`, `agent`, `background`, and `shell`;
- `hooks`, `paths`, and dynamic shell context.

Do not put these fields or substitutions in a universal `SKILL.md`. If one is
essential, maintain a clearly labeled Claude-specific variant. Claude Code
ignores unrecognized frontmatter fields silently.

Claude Code follows a symlinked skill directory and loads it once, but the
universal policy uses full generated copies so Windows privilege settings, Git
checkout configuration, and other harnesses' link handling cannot break
discovery.

## Universal layout

```text
AGENTS.md
CLAUDE.md                         # @AGENTS.md
.agents/skills/<name>/            # authoritative universal source
.claude/skills/<name>/            # byte-identical generated mirror
```

`.claude/skills` is the only generated skill copy the universal layout needs,
and it exists for Claude Code. Cline and OpenCode also scan it, but both
resolve a same-name skill to the `.agents/skills` source, so the copy must stay
byte-identical.

## Validate

1. Start a fresh session and run `/memory`; confirm `CLAUDE.md` and its
   `AGENTS.md` import are listed.
2. Run `claude plugin validate .claude/skills` to catch unparseable
   frontmatter (v2.1.233+).
3. Ask "What skills are available?"; confirm the mirrored skill appears once.
4. Invoke `/skill-name` and test natural-language activation separately.
5. Check enterprise, personal, project, plugin, and legacy command scopes for
   same-name overrides.
6. Confirm no `.claude/rules` body duplicates `@AGENTS.md`.

## Official sources

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)
- [Explore the `.claude` directory](https://code.claude.com/docs/en/claude-directory)
- [Debug your configuration](https://code.claude.com/docs/en/debug-your-config)
