# Guidance for agents working on this repository

This repository is two things at once:

1. **A documentation playbook**: the cross-harness guides at the root, in
   `docs/`, and in `templates/`.
2. **An installable agent toolkit** (`portable-agent-authoring`): two skills
   and a global rule that package those guides for other users. Users install
   it with `AGENT-INSTALL.md`.

## Authoritative and generated files

| Path | Status |
| --- | --- |
| `universal-agent-authoring.md`, `agent-toolkit-repositories.md`, `docs/*.md`, `templates/AGENT-INSTALL.md` | Authoritative guides ("the guide set") |
| `.agents/skills/<skill>/SKILL.md` | Authoritative skill text |
| `.agents/skills/<skill>/references/` | **Generated** copies of the guide set; never edit |
| `.claude/skills/` | **Generated** byte-identical mirror of `.agents/skills/`; never edit |
| `rules/shared/portable-agent-authoring.md` | Authoritative global rule body |
| `AGENT-INSTALL.md` | Install contract; review changes as security-relevant |
| `CLAUDE.md`, `.gemini/settings.json` | Host adapters; change only when host requirements change |
| `README.md` | Human-facing overview and install prompt |

After changing a guide or a `SKILL.md`, regenerate and check:

```text
scripts/sync-skills.sh          # regenerate references/ and the .claude/skills mirror
scripts/sync-skills.sh --check  # verify only; CI runs this
```

The script also lints each `SKILL.md` (frontmatter keys, name, description
length, body size). If it refuses because a generated path has uncommitted
edits, move any intended change into the authoritative file first. Use
`--force` only when those edits came from an earlier sync run.

Without a POSIX shell, do the same by hand: replace each skill's
`references/` directory with fresh copies of the guide set (keeping the
`docs/` and `templates/` subdirectories), then replace each
`.claude/skills/<skill>/` with a full copy of `.agents/skills/<skill>/`, and
compare the trees file by file.

## Editing the guides

- Keep the universal guide normative. Harness guides explain their mapping
  to it rather than copying the whole policy.
- Limit each claim to a documented harness and product surface, cite a
  current primary source, and say when documentation and released behavior
  disagree.
- Update a "Verified … on" date only for guides you actually re-checked.
- Keep relative links inside the guide set (root guides, `docs/`,
  `templates/`). The skills bundle only that set, so a link to `README.md`,
  `LICENSE`, or another file would break inside `references/`.
- Do not add a new harness without a complete guide covering rules, skills,
  workflows, invocation, discovery scope, collisions, and validation. Adding
  one also means updating both `SKILL.md` files, the global rule, and the
  destination tables in `AGENT-INSTALL.md`.
- When a guide changes a path, limit, precedence rule, or destination,
  update the affected `SKILL.md`, the global rule, and `AGENT-INSTALL.md` in
  the same change.

## Skills and the install contract

- Skills follow the portable rules in `universal-agent-authoring.md`:
  frontmatter with only `name` and `description`, no host-only syntax,
  body under 24,000 bytes.
- Skills must not fetch anything from this repository at run time; that is
  why they bundle the guide set.
- `AGENT-INSTALL.md` installs only from `.agents/skills/` and
  `rules/shared/`. It is derived from `templates/AGENT-INSTALL.md`; when the
  template changes, review the contract for the same change.
- The pointer summary in `AGENT-INSTALL.md` step 4 must describe the same
  behavior as `rules/shared/portable-agent-authoring.md`.

## Releasing

1. Merge the release changes to `main` with `scripts/sync-skills.sh --check`
   passing.
2. Create an annotated tag `vX.Y.Z` on that merge commit and push it.
3. In a follow-up change, update the tag in the README install prompt and in
   the "What this does" note below it. The README cannot name its own tag
   before the tag exists, so this is always a separate change.

## Dogfooding collision

If you also have this toolkit installed globally, every harness sees each
skill twice while you work here:

- Claude Code and Cline prefer the **global** copy, so edits here appear to
  have no effect;
- Codex lists both copies;
- Gemini CLI and OpenCode prefer this repository's copy;
- `agy` documents no precedence.

Test skill changes in a fresh session with the global copies temporarily
removed or disabled.

## Before you finish

1. `scripts/sync-skills.sh --check` passes.
2. Links you added resolve.
3. If you changed `AGENT-INSTALL.md`, re-read it end to end against
   `agent-toolkit-repositories.md` ("The install contract" and "Security
   posture").
4. Report which guides changed and whether their verification dates moved.
