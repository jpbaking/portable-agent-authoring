#!/bin/sh
# Regenerate and check the generated parts of this repository:
#
#   1. .agents/skills/<skill>/references/  <- the guide set at the repository root
#   2. .claude/skills/<skill>/             <- byte-identical mirror of .agents/skills/<skill>/
#
# It also lints every .agents/skills/*/SKILL.md against the portable rules.
#
# Usage:
#   scripts/sync-skills.sh           regenerate; refuse to overwrite uncommitted edits
#   scripts/sync-skills.sh --check   verify only; exit 1 on drift or lint failure (CI)
#   scripts/sync-skills.sh --force   regenerate even over uncommitted edits
set -eu

# Skills that bundle the full guide set under references/.
bundle_skills="universal-agent-authoring agent-toolkit-authoring"
# The guide set, relative to the repository root. Links inside these files
# must stay within the set so they resolve inside references/.
guides="universal-agent-authoring.md agent-toolkit-repositories.md docs templates"

mode=sync
case "${1:-}" in
  "") ;;
  --check) mode=check ;;
  --force) mode=force ;;
  *) echo "usage: $0 [--check|--force]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."
status=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

fail() { echo "error: $*" >&2; status=1; }

# --- Lint ------------------------------------------------------------------

lint_skill() {  # lint_skill DIR
  dir=$1; name=$(basename "$dir"); file="$dir/SKILL.md"
  [ -f "$file" ] || { fail "$file is missing"; return 0; }
  [ "$(head -n 1 "$file")" = "---" ] || { fail "$file: no YAML frontmatter"; return 0; }
  front=$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$file")
  keys=$(printf '%s\n' "$front" | sed -n 's/^\([A-Za-z0-9_-]*\):.*/\1/p' | sort | tr '\n' ' ')
  [ "$keys" = "description name " ] ||
    fail "$file: frontmatter keys must be exactly name and description (found: $keys)"
  fm_name=$(printf '%s\n' "$front" | sed -n 's/^name:[[:space:]]*//p')
  [ "$fm_name" = "$name" ] || fail "$file: name '$fm_name' does not match directory '$name'"
  printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' ||
    fail "$file: name must be lowercase kebab-case"
  [ "${#name}" -le 64 ] || fail "$file: name is longer than 64 characters"
  desc=$(printf '%s\n' "$front" | sed -n 's/^description:[[:space:]]*//p')
  [ -n "$desc" ] || fail "$file: description is empty or not on one line"
  desc_len=$(printf '%s' "$desc" | wc -m | tr -d ' ')
  [ "$desc_len" -le 1024 ] || fail "$file: description is $desc_len characters (max 1024)"
  case "$desc" in
    \"*|\'*) ;;
    *': '*) fail "$file: description contains ': ' and must be quoted" ;;
  esac
  size=$(wc -c < "$file" | tr -d ' ')
  [ "$size" -lt 24000 ] || fail "$file is $size bytes (must stay under 24000)"
}

for dir in .agents/skills/*; do
  [ -d "$dir" ] && lint_skill "$dir"
done

# --- Build the expected .agents/skills tree --------------------------------

mkdir "$tmp/skills"
for dir in .agents/skills/*; do
  [ -d "$dir" ] && cp -Rp "$dir" "$tmp/skills/"
done
for name in $bundle_skills; do
  [ -d ".agents/skills/$name" ] || { fail ".agents/skills/$name is missing"; continue; }
  rm -rf "$tmp/skills/$name/references"
  mkdir "$tmp/skills/$name/references"
  for g in $guides; do cp -Rp "$g" "$tmp/skills/$name/references/"; done
done

# --- Compare and regenerate ------------------------------------------------

same_tree() {  # same content, same file set, same executable bits
  [ -d "$1" ] && [ -d "$2" ] || return 1
  diff -r "$1" "$2" > /dev/null 2>&1 || return 1
  [ "$(cd "$1" && find . -type f -perm -u+x | sort)" = \
    "$(cd "$2" && find . -type f -perm -u+x | sort)" ]
}

has_local_edits() {  # uncommitted or untracked changes under the path
  [ -e "$1" ] || return 1
  ! git diff --quiet HEAD -- "$1" 2> /dev/null ||
    [ -n "$(git ls-files --others --exclude-standard -- "$1")" ]
}

sync_one() {  # sync_one EXPECTED DESTINATION
  if same_tree "$1" "$2"; then return 0; fi
  if [ "$mode" = check ]; then
    fail "$2 is out of date; run scripts/sync-skills.sh"
    diff -rq "$1" "$2" >&2 || true
    return 0
  fi
  if [ "$mode" = sync ] && has_local_edits "$2"; then
    fail "$2 has uncommitted edits that do not match its source. Move intended
       changes into the authoritative file, or re-run with --force if the edits
       came from an earlier sync."
    return 0
  fi
  rm -rf "$2"
  mkdir -p "$(dirname "$2")"
  cp -Rp "$1" "$2"
  echo "updated: $2"
}

[ "$status" -eq 0 ] || exit 1

for name in $bundle_skills; do
  sync_one "$tmp/skills/$name/references" ".agents/skills/$name/references"
done
# Mirror only once the sources are current, so the mirror never captures a
# half-synced tree.
[ "$status" -eq 0 ] || exit 1

for dir in "$tmp"/skills/*; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  sync_one "$dir" ".claude/skills/$name"
done

for dir in .claude/skills/*; do
  [ -d "$dir" ] || continue
  [ -d ".agents/skills/$(basename "$dir")" ] ||
    fail "$dir has no source in .agents/skills/; remove it or add the source"
done

[ "$status" -eq 0 ] && [ "$mode" = check ] && echo "ok: generated files are current"
exit "$status"
