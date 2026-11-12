---
name: agent-toolkit-authoring
description: Design, create, update, or audit an agent toolkit repository (a repository whose product is skills and rules that other people install into their own harnesses) and its agent-guided install contract, AGENT-INSTALL.md. Use when asked to make skills or rules installable or distributable, write or review an AGENT-INSTALL.md or README install prompt, replace a curl-pipe-to-shell or script installer, add a self-gating global rule with marker-guarded pointer blocks, or plan global install destinations, updates, and uninstall for Antigravity CLI (agy), Codex, Claude Code, Gemini CLI, Cline, and OpenCode. Not for authoring one project's own skills or rules; use the universal-agent-authoring skill for that. This skill relies on the universal-agent-authoring skill for skill and rule format.
---

# Agent toolkit authoring

Turn a repository of skills and rules into a toolkit other people can install
with their own agent: a readable install contract (`AGENT-INSTALL.md`)
executed by the user's agent, acquisition through `git` only, merge-aware
edits to user-owned files, and update and uninstall paths.

The guides are bundled with this skill:

| File | Read it when |
| --- | --- |
| `references/agent-toolkit-repositories.md` | Always, completely, before writing anything |
| `references/templates/AGENT-INSTALL.md` | Writing or reviewing an install contract; it is the starting point |
| `references/universal-agent-authoring.md` | Always; it defines the skill and rule format the toolkit must follow |
| `references/docs/<harness>.md` | Checking a harness's global paths, precedence, or limits |

For authoring the individual skills and the contributor layout, also use the
`universal-agent-authoring` skill.

## Inputs

Determine these from the request and the repository; ask for what is
missing before writing:

1. Toolkit display name and lowercase kebab-case id. The id is used in paths
   such as `~/.agents/rules/<id>.md` and in marker blocks such as
   `<!-- <id>:global-rule -->`.
2. The remote users clone, in the form their credentials support: public
   `https://github.com/<owner>/<repo>`, an enterprise HTTPS remote, or an SSH
   remote. Do not assume `github.com`.
3. Release pinning: a tag to publish in the install prompt, or the explicit
   choice to track the default branch.
4. The skills to ship (directories under `.agents/skills/`).
5. Whether a global rule is needed, and what it gates on: a project marker
   file, a kind of task, or both.
6. Whether to offer an opt-in project install section.
7. Earlier install methods or destinations that need legacy cleanup.
8. Mode: create, update, or audit. Audit writes nothing.

## 1. Read the guides

Read `references/agent-toolkit-repositories.md` and
`references/universal-agent-authoring.md` completely, and the template.

## 2. Survey the repository

Write nothing in this step. Record:

- which parts of the toolkit layout exist: `README.md`, `AGENT-INSTALL.md`,
  `AGENTS.md`, `CLAUDE.md`, `.gemini/settings.json`, `.agents/skills/`,
  `.claude/skills/`, `rules/shared/`, `templates/`, `LICENSE`;
- every existing install path: install scripts, `curl … | sh` or
  `iwr … | iex` instructions, package-manager hooks, or docs telling users
  to copy files by hand;
- every fetch of the toolkit's own content over HTTP, in skills, rules, the
  README, or a contract. Search for `curl`, `wget`, `Invoke-WebRequest`,
  `iwr`, `raw.githubusercontent.com`, `/archive/`, `/releases/download/`,
  `| sh`, `| bash`, and web-fetch instructions;
- skills that violate the universal portability rules;
- existing tags (`git tag`, or `git ls-remote --tags <remote>`);
- destinations earlier releases installed to, for the legacy cleanup step.

In audit mode, compare everything against the guide's "Checklist" and the
template, then go to step 9.

## 3. Decide the design

Confirm with the user any decision not already given:

- **Scope**: user-global by default. The install contract never writes to a
  project, not even `.gitignore`. Per-project files are created later by a
  skill, on request.
- **Skills**: what each one does, and that each ships only from
  `.agents/skills/`.
- **Global rule**: only if needed. It must be safe in every project: it
  self-gates on a project marker or on the task kind, does at most one short
  suggestion per session where it does not apply, and never initializes
  anything unprompted.
- **Project install**: include the opt-in section only if a team needs it.

## 4. Lay out the repository

Keep the guide's three audiences separate:

1. **Installer**: `AGENT-INSTALL.md` plus what it copies, which is
   `.agents/skills/` and `rules/shared/<id>.md`. Nothing else is an install
   source; `.claude/skills/` is never one.
2. **Contributors' agents**: the universal layout for the toolkit
   repository itself (`AGENTS.md`, `CLAUDE.md` containing `@AGENTS.md`,
   `.gemini/settings.json`, the `.claude/skills` mirror). Follow the
   `universal-agent-authoring` skill to create these.
3. **Projects that use the toolkit**: whatever the skills write when asked.

In the toolkit's `AGENTS.md`, document which files are authoritative and
which are generated, how to regenerate the mirror, and the dogfooding
collision: with the toolkit also installed globally, Claude Code and Cline
prefer the global copy, Codex lists both, Gemini CLI and OpenCode prefer the
workspace copy, and `agy` documents no precedence. Tell contributors to test
in a fresh session with the global copy removed or disabled.

## 5. Make the skills install-safe

- Apply every portability rule from the universal guide to each skill.
- A skill must not fetch the toolkit's own files at run time. Bundle them in
  the skill (under `assets/` or `references/`) so they install and version
  with it. If a file is too large or must track the latest release, instruct
  `git clone --depth 1` into a temporary directory (optionally
  `--filter=blob:none --sparse` with `git sparse-checkout set <path>`). If
  neither works, stop and ask the user for the file.
- Fetching third-party content that needs no authentication is acceptable.

## 6. Write the global rule

Skip this step if the toolkit has no global rule.

1. Write the body once at `rules/shared/<id>.md`. Start with the gate: when
   the rule applies, and that it does nothing otherwise.
2. Write the pointer block the contract will merge into each host file:

   ```markdown
   <!-- <id>:global-rule -->
   Read and follow `~/.agents/rules/<id>.md`. In short: <summary>.
   <!-- /<id>:global-rule -->
   ```

   The summary is two or three sentences that work even if the model never
   opens the body.
3. The install routes the rule only through pointers: no copies in
   `~/.claude/rules/`, `~/.gemini/config/rules/`, or Cline rules folders, and
   never anything in `~/.codex/rules/`.

## 7. Write AGENT-INSTALL.md

1. Start from a copy of `references/templates/AGENT-INSTALL.md`.
2. Replace every placeholder listed in the template's leading comment:
   `<Toolkit>`, `<toolkit>`, `<remote>`, each `<skill-a>`-style skill name,
   the rule summary, and the rule's one-sentence gate description. Keep the
   variables the installing agent fills in at run time, such as `<tmp>`,
   `<tag>`, `<host>`, `<owner>/<repo>`, `<skill>`, `<source>`, and
   `<destination>`.
3. Delete section 4 if there is no global rule. Delete the leading comment.
4. Make section 5 concrete: list each legacy destination, rule copy, and
   project adapter that earlier releases left behind, or state that there
   are none.
5. Keep destinations in tables, repeat critical exceptions at the step where
   they apply, name every stop condition, and keep the contract host-neutral:
   no harness tool names and no OS-only one-liners in required steps.
6. If the toolkit itself is likely to be opened as a project by contributors,
   add a survey note telling the agent to leave the repository's own
   `.agents/skills` and `.claude/skills` alone.
7. Keep the Update and Uninstall sections; include the project install
   section only if chosen in step 3.

## 8. Write the README install prompt

Add one paste-in prompt based on the guide's "The README install prompt":

- clone with `git` using the user's existing credentials, `--depth 1`, and
  git's terminal prompt disabled (`GIT_TERMINAL_PROMPT=0`), into a new
  temporary directory outside any project; no raw files or archives;
- stop and tell the user how to sign in if the clone fails for lack of
  credentials, since the contract's own access check runs only after a clone
  exists;
- pin the published tag, or state that omitting it installs the default
  branch as it is at clone time; when pinning an annotated tag, say that
  git's "not a commit" warning about the tag is normal, since the agent sees
  it before reading the contract;
- read `AGENT-INSTALL.md` from that clone and follow it exactly;
- merge with, never blindly overwrite, existing global instruction files;
  ask which harnesses to install for; report every file created or changed.

Next to the prompt, state that the user's agent will execute instructions
from the cloned repository, list the directories it may write to, and say
that users of a fork, mirror, or enterprise host substitute their remote.
Add usage instructions with the per-harness invocation forms.

## 9. Validate

Check, and fix every failure:

- [ ] Every item in the guide's "Checklist" holds.
- [ ] No template placeholder from step 7.2 remains in `AGENT-INSTALL.md`.
- [ ] Every path the contract copies from exists in the repository, and every
      skill it names exists under `.agents/skills/`.
- [ ] The contract's skill destinations are exactly `~/.agents/skills/`,
      `~/.claude/skills/`, and `~/.gemini/antigravity-cli/skills/`, each
      written once.
- [ ] The rule's marker block id contains the toolkit id, and the pointer
      summary matches the rule body's behavior.
- [ ] The step 2 search for HTTP fetches of the toolkit's content now finds
      nothing in the README, contract, skills, or rule.
- [ ] Each skill passes the `universal-agent-authoring` skill's validation,
      and `.claude/skills/` matches `.agents/skills/` byte for byte.

Then offer to test the contract as described in the guide's "Testing an
install contract": against a scratch home directory (for example
`HOME=$(mktemp -d)` on POSIX), from clean, previous-release, existing-content,
and same-name-skill starting states, re-run for idempotency, and uninstall.
Never test against the user's real home directory without explicit
permission.

## 10. Report

Report the files created or changed, the design decisions and who made them,
the validation results, the published install prompt, open items (for
example "tag a release so the prompt can pin it"), and any remaining
installer or HTTP-fetch paths that need retiring.

## Stop conditions

STOP and ask the user when:

- the toolkit id, remote, or shipped skill set cannot be determined;
- an existing installer or contract would be replaced and the user has not
  approved retiring it;
- a skill depends on fetching the toolkit's own content and cannot bundle it;
- the global rule cannot be made safe to load in every project;
- a generated mirror contains edits that are not in its source.
