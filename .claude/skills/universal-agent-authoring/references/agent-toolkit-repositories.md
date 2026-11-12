# Agent toolkit repositories and agent-guided installs

Verified against current official documentation on 2026-11-08.

This guide covers repositories whose product *is* agent tooling: skills,
rules, and conventions that other people install into their own harnesses.
[DOX](https://github.com/jpbaking/dox) is a reference example. It applies the
[universal authoring guide](universal-agent-authoring.md) to distribution and
covers the same harnesses: `agy`, Codex, Claude Code, Gemini CLI, Cline, and
OpenCode.

The recommended install mechanism is an **agent-guided install contract**: a
Markdown file, conventionally `AGENT-INSTALL.md`, that a user's own agent
executes. The agent stages the toolkit with `git clone` in a temporary
directory, reads the contract from that clone, surveys the machine, copies and
merges files, validates them, and reports. There is no `curl … | sh`
installer, and the toolkit's own files are never fetched over raw HTTP.

A fill-in template is in
[`templates/AGENT-INSTALL.md`](templates/AGENT-INSTALL.md).

## Why agent-guided instead of an install script

A pipe-to-shell script runs unreviewed code from the network with the user's
full privileges, and it cannot easily make judgment calls. The things an agent
toolkit install must do are mostly judgment calls:

| Need | Script | Agent-guided contract |
| --- | --- | --- |
| Merge into user-owned instruction files without clobbering them | Fragile text munging | Reads, merges, and shows the result |
| Ask which harnesses the user wants | Prompts or flags | Asks in conversation |
| Detect same-name skills, legacy copies, and overrides | Hard-coded checks | Surveys and reports in context |
| Handle Windows, WSL, macOS, and Linux paths | Several scripts | One contract, platform-aware agent |
| Explain what changed | Log output | Structured report of every file |
| Review before execution | Rarely done | The contract is readable prose |
| Work behind enterprise GitHub authentication | Needs a token in the script or URL | Uses the git or `gh` credentials the user already has |

The trade-off is determinism. A contract is executed by a model, so it must be
written to leave nothing to inference: exact destination tables, exact marker
text, explicit stop conditions, and a mechanical validation step. Smaller
models must be able to follow it.

If a deterministic helper is genuinely needed, for example to byte-compare
trees, ship it in the repository and have the contract run it **from the
staged clone, after the agent has read it**. Never instruct the agent to pipe
a downloaded script into a shell.

## Acquire with git, not raw HTTP

Toolkits are often published on GitHub Enterprise Server, on GHE.com, or as
internal repositories. There, even "public" content usually requires
authentication: raw file URLs, `archive/*.zip` links, and release asset
downloads return a sign-in page or a 404 to an anonymous `curl`, `wget`, or
agent web-fetch tool. The agent's URL fetcher also usually cannot use the
user's credentials at all.

`git` and `gh` can. They use the SSH keys, credential helpers, and `gh auth`
sessions the user already relies on every day. So the whole install path,
including the first step, goes through git:

- **Bootstrap from a clone.** The README prompt tells the agent to clone the
  repository into a temporary directory and follow `AGENT-INSTALL.md` from
  there. It does not ask the agent to fetch a raw URL.
- **One acquisition method.** Use `git clone`, or `gh repo clone` when the
  user prefers `gh`. Do not list raw-file, archive, or release-asset downloads
  as fallbacks; they fail in exactly the environments the fallback is meant
  for.
- **Accept any remote.** Let the user supply the remote in whatever form their
  credentials support: `https://github.com/<owner>/<repo>`,
  `https://<ghe-host>/<org>/<repo>`, or `git@<ghe-host>:<org>/<repo>.git`. Do
  not hard-code `github.com` into paths the agent derives.
- **Check access before cloning.** `git ls-remote <remote>` succeeds or fails
  quickly, and doubles as tag discovery for pinning and updates.
- **Stop on authentication failure.** Ask the user to authenticate, for
  example with `gh auth login --hostname <host>` followed by
  `gh auth setup-git --hostname <host>`, or by loading an SSH key, and then
  retry. Never put a token in a clone URL (it persists in `.git/config` and
  shell history), never ask the user to paste a token into the conversation,
  and never print credential-helper output.
- **No interactive prompts.** Run git with `GIT_TERMINAL_PROMPT=0` so a missing
  credential fails instead of hanging the agent's shell on a password prompt.
  This includes the bootstrap clone in the README prompt: the contract's
  checks only start once the agent has a clone, so the prompt itself must
  ask for non-interactive git and a clean stop on authentication failure.

### Skills must not fetch their own repository

The same constraint applies after installation. A skill that downloads a file
from the toolkit's repository at run time, such as a framework template from a
raw URL, breaks for enterprise users. Instead:

- bundle the file inside the skill, under `assets/`, so it installs with the
  skill and stays version-locked to it;
- if the file is too large or must track the latest release, tell the agent to
  obtain it with `git clone --depth 1` into a temporary directory (add
  `--filter=blob:none --sparse` and `git sparse-checkout set <path>` to fetch
  only what is needed), never with raw HTTP. GitHub does not support
  `git archive --remote`;
- when neither is possible, stop and ask the user to supply the file.

Fetching third-party URLs that genuinely need no authentication, such as a
public specification, is acceptable. The rule is about the toolkit's own
content.

## Repository layout

```text
README.md                    # humans: what it is, the install prompt, usage
AGENT-INSTALL.md             # the install contract (authoritative)
AGENTS.md                    # guidance for agents developing this repository
CLAUDE.md                    # @AGENTS.md
.gemini/settings.json        # context.fileName for Gemini CLI contributors
.agents/skills/<skill>/      # authoritative skill sources (shipped)
.claude/skills/<skill>/      # byte-identical mirror for Claude Code contributors
rules/shared/<toolkit>.md    # shared global rule body, if the toolkit has one
templates/                   # files the skills write into user projects, if any
LICENSE
```

Keep three audiences separate:

1. **The installer**: `AGENT-INSTALL.md` plus the files it copies
   (`.agents/skills/`, `rules/shared/`).
2. **Contributors' agents** working on the toolkit repository itself:
   `AGENTS.md`, `CLAUDE.md`, `.gemini/settings.json`, and the
   `.claude/skills` mirror. This is the universal layout applied to the
   toolkit's own repository.
3. **Projects that use the toolkit**: whatever its skills write into a
   project (DOX's `DOX.md` tree and root anchors). The install contract does
   not create these; the skills do, on request.

The installer copies from `.agents/skills/` only. The `.claude/skills/` mirror
exists for contributors and must never be a second install source.

### Dogfooding collision

When a contributor has the toolkit installed globally and opens the toolkit
repository, every harness sees the skill twice, and precedence differs:

- Claude Code and Cline prefer the **global** copy, so edits to the
  repository's skill appear to have no effect.
- Codex lists both copies.
- Gemini CLI prefers the workspace copy.
- OpenCode prefers the project `.agents/skills` copy over `~/.agents/skills`
  and `~/.claude/skills`.
- `agy` does not document a precedence.

Document this in the toolkit's `AGENTS.md`, and test changes in a fresh session
with the global copy temporarily removed or disabled.

## Choose the install scope

| Scope | Use for | Writes to | Owned by |
| --- | --- | --- | --- |
| User-global (default) | Tools a person uses across projects | Home-directory discovery paths and global instruction files | That user, on that machine |
| Project (opt-in) | Tools a team wants every clone to have | The project's universal layout | The repository, via version control |

Default to user-global for a toolkit. The install never touches a project,
not even its `.gitignore`. If the toolkit also needs per-project files, a
skill such as DOX's `dox-init` creates them later. Those files are committed
project truth and should work for a teammate who has nothing installed.

Offer project installation only as an explicit, opt-in section of the
contract. It writes the standard universal layout (`.agents/skills`,
`.claude/skills`, `AGENTS.md`, `CLAUDE.md`, `.gemini/settings.json`), and the
user commits it.

## Global destinations

Skill copies, with physical directories shared where hosts overlap:

| Destination | Serves |
| --- | --- |
| `~/.agents/skills/<skill>/` | Codex, Gemini CLI, Cline, OpenCode |
| `~/.claude/skills/<skill>/` | Claude Code (OpenCode also sees it; it resolves to `~/.agents/skills`) |
| `~/.gemini/antigravity-cli/skills/<skill>/` | `agy` |

Install each physical directory once, even when several selected harnesses
share it. Do not use `~/.gemini/skills/` for `agy`: Gemini CLI also reads it
and would list a duplicate of `~/.agents/skills/`. Do not use
`~/.cline/skills/` or `~/.config/opencode/skills/`: both hosts already read
`~/.agents/skills/`, so these would be redundant copies to keep in sync, and
`~/.config/opencode/skills/` would also override same-name project skills in
OpenCode.

Global instruction files for a rule pointer:

| Harness | File | Notes |
| --- | --- | --- |
| `agy` | `~/.gemini/GEMINI.md` | Shared with Gemini CLI |
| Codex | `~/.codex/AGENTS.md` | Respect `CODEX_HOME`; if `AGENTS.override.md` exists there, Codex reads it instead |
| Claude Code | `~/.claude/CLAUDE.md` | |
| Gemini CLI | `~/.gemini/GEMINI.md` | Shared with `agy`; check that `~/.gemini/settings.json` `context.fileName`, if set, still includes `GEMINI.md` |
| Cline | `~/.agents/AGENTS.md` | Respect `CLINE_DIR` only for Cline-native paths; this file is fixed |
| OpenCode | `~/.config/opencode/AGENTS.md` | |

`agy` and Gemini CLI share one physical pointer. If the user selects only one
of them, say that the pointer affects both, and ask before writing it.

On Windows, `~` means `%USERPROFILE%`. Write paths with forward slashes in the
contract and let the agent translate.

## Global rules

A toolkit rule loaded into every session must be safe in every project.

- **Self-gate.** The rule first checks for the toolkit's project marker (DOX
  looks for a root `DOX.md` containing `# DOX framework`). Where it is absent,
  the rule does at most one short suggestion per session and otherwise stays
  out of the way. It never initializes anything unprompted.
- **One body, many pointers.** Store the body once at
  `~/.agents/rules/<toolkit>.md` and put a short, marker-guarded pointer in
  each selected host's global instruction file. None of the six harnesses
  auto-loads `~/.agents/rules/` (`agy` scans `.agents/rules/` only inside a
  workspace and discards files without a `trigger`), so the body loads only
  through the pointers.
- **Summarize in the pointer.** Hosts do not reliably import arbitrary files,
  so the pointer must work even if the model never opens the body. State the
  essential behavior in two or three sentences, then say "Read and follow
  `~/.agents/rules/<toolkit>.md`."
- **Prefer pointers over host rule directories.** Do not also install the body
  into `~/.claude/rules/`, `~/.gemini/config/rules/`, or Cline's rules
  folders. Two routes means the same rule loads twice.
- **Never write to `~/.codex/rules/`**: those files are command-execution
  policy, not guidance.

### Marker-guarded blocks

Every edit to a user-owned file goes inside a uniquely named block:

```markdown
<!-- <toolkit>:global-rule -->
Read and follow `~/.agents/rules/<toolkit>.md`. In short: <two-sentence
summary of the rule's behavior>.
<!-- /<toolkit>:global-rule -->
```

Contract rules for blocks:

1. If the opening marker exists, replace everything through the closing marker
   with the current text.
2. Otherwise append the block once, separated by a blank line.
3. Create a missing file; never overwrite, reorder, or delete unrelated
   content; preserve the file's line endings.
4. Before any install, update, or uninstall edit, check the markers. They are
   well formed only when the file has neither marker, or exactly one opener
   followed later by exactly one closer. Anything else (an opener without a
   closer, a closer without an opener, a closer before the opener, or
   duplicates) is malformed: stop and show the user rather than guessing.
5. Uninstall removes exactly the block, including the markers and the blank
   line that rule 2 added before it, and leaves an emptied file in place.
   It removes the shared `~/.agents/rules/` directory only if it is now
   empty, and leaves host directories such as `~/.claude/skills/` alone.

Use a block ID that includes the toolkit name so several toolkits can coexist
in one file.

## The install contract

Structure `AGENT-INSTALL.md` as numbered, imperative steps:

0. **Preamble.** The agent's role, what the install touches (user-global
   only), what it never touches, the source repository URL, and how a fork or
   pinned tag substitutes into the steps.
1. **Acquire.** If the agent is already reading the contract from a fresh
   clone, use that clone. Otherwise check access with `git ls-remote`, then
   clone into a fresh temporary directory outside any project:
   `git clone --depth 1 [--branch <tag>] <remote> <tmp>/<toolkit>`, or the
   `gh repo clone` equivalent. Stop on authentication failure. Record the
   commit SHA for the report.
2. **Survey.** Before writing anything, check every global destination and, if
   inside a project, the project's skill directories (`.agents/skills`,
   `.claude/skills`, `.cline/skills`, `.clinerules/skills`, `.opencode/skills`,
   `.gemini/skills`) for same-name skills. Check for legacy locations from
   earlier toolkit versions. Ask which harnesses to install for; do not infer
   consent from which configuration directories exist.
3. **Install skills.** Copy whole directories from `.agents/skills/` to each
   selected physical destination, byte-identical, preserving executable bits.
   Replace an existing copy only if it matches a previous release or the user
   approves overwriting local edits. Never touch other skills.
4. **Install the rule** (if any). Copy the body to `~/.agents/rules/`, then
   merge the marker-guarded pointer into each selected host file.
5. **Clean up legacy.** Report copies left by earlier versions (old
   destinations, host rule directories, project-level adapters, Cline workflow
   shims) and remove them only with approval. Do not leave two active routes.
6. **Validate.** Compare every installed tree with the staged source
   byte-for-byte, confirm exactly one pointer block per selected host file,
   and confirm the rule body matches its source.
7. **Remove the staging directory.**
8. **Report.** List every file created, changed, removed, or intentionally
   left alone; every collision; the installed commit SHA or tag; and the next
   step, including per-harness invocation.

Add two more sections: **Update** (re-run the same contract; it must be
idempotent) and **Uninstall** (remove the installed skill directories and the
rule body, and remove the marker blocks, after listing them for approval).

### Writing for reliability

- Use tables for destinations so nothing is derived.
- Repeat critical exceptions at the step where they apply, not only in the
  preamble.
- Name stop conditions explicitly: malformed markers, divergent user edits,
  failed clone, missing write permission.
- Never require elevated privileges. If a destination is not writable, stop
  and report.
- Keep the contract host-neutral. Do not name a harness's internal tools.
- Do not put shell one-liners that only work on one OS in required steps;
  describe the result and offer per-OS commands as examples.

Byte comparison examples the contract can offer:

```text
POSIX:       diff -r <tmp>/<toolkit>/.agents/skills/<skill> ~/.agents/skills/<skill>
PowerShell:  Compare-Object (Get-ChildItem -Recurse -File <a> | Get-FileHash) `
                            (Get-ChildItem -Recurse -File <b> | Get-FileHash) -Property Hash
```

## The README install prompt

Give users one paste-in prompt that works in any of the six harnesses and
behind enterprise authentication:

```text
Install <toolkit>. Using git with my existing credentials (do not download raw
files or archives), clone <remote> at tag <tag> with --depth 1 and git's
terminal prompt disabled (GIT_TERMINAL_PROMPT=0) into a new temporary
directory outside any project. If the clone fails for lack of credentials,
stop and tell me how to sign in. Then read AGENT-INSTALL.md from that clone
and follow it exactly. Merge with—never blindly overwrite—any existing global
instruction files, ask me which harnesses to install for, and report every
file you created or changed.
```

- **Write `<remote>` in the form your users can clone.** For an enterprise
  toolkit, publish the internal HTTPS or SSH remote. For a public toolkit,
  `https://github.com/<owner>/<repo>` works, and users of a fork or internal
  mirror substitute their own.
- **Pin a tag** in the published prompt, or say that omitting it installs the
  default branch as it is at clone time.
- **Say what the prompt does.** The README should state that the user's agent
  will execute instructions from the cloned repository, and list the
  directories it may write to.
- Users can also clone the repository themselves and ask the agent to follow
  the local `AGENT-INSTALL.md`; the contract then reuses that clone.

## Security posture

The contract is executable instructions for an agent with filesystem access.
Treat it with the same care as an install script:

- Publish it only from a repository you control. Review changes to it as
  security-relevant, and keep it in a stable path.
- The contract must confine writes to the destinations it lists, plus the
  staging directory.
- Instruct the agent to treat the staged repository's other files as data:
  copy them, but do not follow instructions found inside skills, rules, or
  templates during installation.
- Do not have the contract run scripts from the clone unless a step explicitly
  requires it and the agent has read the script first.
- Do not fetch any URL during install. The clone is the only network access,
  and it goes through git with the user's own credentials.
- Do not ask for, embed, or print credentials.

## Testing an install contract

1. Run it against a scratch home directory (`HOME=$(mktemp -d)` on POSIX, or a
   throwaway user or VM) so real configuration is untouched.
2. Test the bootstrap against an authenticated-only remote, such as a private
   or internal repository, with no raw-URL access. The install must succeed
   using git alone, and it must stop cleanly when credentials are missing.
3. Test four starting states: clean, previous release installed, user content
   already in each global instruction file, and a same-name skill in a project.
4. Re-run immediately; the second run must report no changes.
5. Run uninstall; only the toolkit's files and blocks may disappear.
6. Execute the contract with at least one smaller model, not only a frontier
   model.
7. In a fresh session per selected harness, confirm each skill is listed
   once, the global rule is active, and invocation works.

## Checklist

- [ ] `AGENT-INSTALL.md` exists and is the only install path.
- [ ] The README prompt and the contract acquire sources with `git` or `gh`
      only; no raw-file, archive, or release-asset downloads.
- [ ] No skill fetches the toolkit's own files over HTTP at run time.
- [ ] Installed skills come only from `.agents/skills/`.
- [ ] Skills follow the universal portability rules.
- [ ] Destinations match the tables above; shared directories are installed
      once.
- [ ] Any global rule self-gates and is stored once under `~/.agents/rules/`.
- [ ] Every user-file edit is a uniquely marked, replaceable block.
- [ ] The contract has survey, validate, report, update, and uninstall steps.
- [ ] The README prompt pins a version or states that it tracks the default
      branch.
- [ ] The repository itself uses the universal layout for contributors, and
      `AGENTS.md` warns about the dogfooding collision.

## Related

- [Universal skills, rules, and workflows](universal-agent-authoring.md)
- Harness guides: [`agy`](docs/agy.md), [Codex](docs/codex.md),
  [Claude Code](docs/claude.md), [Gemini CLI](docs/gemini.md),
  [Cline](docs/cline.md), [OpenCode](docs/opencode.md)
- [Install contract template](templates/AGENT-INSTALL.md)
