#!/usr/bin/env bash
#
# Fails when a change touches the `lib/` directory of a package that keeps a
# `CHANGELOG.md` without adding anything to that `CHANGELOG.md`.
#
# Usage:
#   scripts/check_changelog_entry.sh [<base-ref> <head-ref>]
#
# Without arguments the range comes from `BASE_SHA` and `HEAD_SHA`, and falls
# back to the parents of the pull request merge commit that `actions/checkout`
# leaves at `HEAD`.
#
# Environment:
#   BASE_SHA               Base commit of the pull request.
#   HEAD_SHA               Head commit of the pull request.
#   PR_LABELS              JSON array of the pull request label names.
#   SKIP_CHANGELOG_LABEL   Label that waives the requirement.

set -euo pipefail

SKIP_LABEL="${SKIP_CHANGELOG_LABEL:-skip-changelog}"

resolve_commit() {
  local ref="${1:-}"
  [[ -n "$ref" ]] || return 1
  git rev-parse --verify --quiet "${ref}^{commit}" 2>/dev/null
}

if [[ "$#" -eq 2 ]]; then
  base="$(resolve_commit "$1" || true)"
  head="$(resolve_commit "$2" || true)"
elif [[ "$#" -eq 0 ]]; then
  base="$(resolve_commit "${BASE_SHA:-}" || true)"
  head="$(resolve_commit "${HEAD_SHA:-}" || true)"
  if [[ -z "$base" || -z "$head" ]]; then
    # `actions/checkout` checks out the merge commit for pull requests, whose
    # first parent is the base branch and second parent is the pull request.
    base="$(resolve_commit 'HEAD^1' || true)"
    head="$(resolve_commit 'HEAD^2' || true)"
  fi
else
  echo "Usage: $0 [<base-ref> <head-ref>]" >&2
  exit 2
fi

if [[ -z "$base" || -z "$head" ]]; then
  echo "::error::Cannot determine which commits to compare." >&2
  exit 2
fi

labels="${PR_LABELS:-[]}"
if jq -e --arg label "$SKIP_LABEL" 'any(.[]; . == $label)' <<< "$labels" > /dev/null 2>&1; then
  echo "The '${SKIP_LABEL}' label is applied, so no changelog entry is required."
  exit 0
fi

declare -A changed_packages=()
declare -A changelog_additions=()

# `core.quotePath=false` keeps non-ASCII paths readable instead of escaped.
diff_stat="$(git -c core.quotePath=false diff --numstat --no-renames "${base}...${head}")"

while read -r added _deleted path; do
  [[ -n "${path:-}" ]] || continue
  case "$path" in
    */lib/*)
      changed_packages["${path%%/lib/*}"]=1
      ;;
    */CHANGELOG.md)
      # A changelog that only loses lines does not describe a new change.
      if [[ "$added" != "0" ]]; then
        changelog_additions["${path%/CHANGELOG.md}"]=1
      fi
      ;;
  esac
done <<< "$diff_stat"

missing=()
for package in "${!changed_packages[@]}"; do
  # Packages without a changelog (examples, shared test helpers) are exempt,
  # because they are not published to pub.dev.
  if ! git cat-file -e "${head}:${package}/CHANGELOG.md" 2> /dev/null; then
    continue
  fi
  if [[ -z "${changelog_additions[$package]:-}" ]]; then
    missing+=("$package")
  fi
done

if [[ "${#missing[@]}" -eq 0 ]]; then
  echo "Every package with a modified 'lib/' also has a changelog entry."
  exit 0
fi

while IFS= read -r package; do
  echo "::error::${package}/lib was modified without adding an entry to ${package}/CHANGELOG.md."
done < <(printf '%s\n' "${missing[@]}" | sort)

cat >&2 << EOF

Add one bullet per change under the '## Unreleased' section of the changelog
of every package listed above, written for the people who use the package.
Do not bump version numbers, releases are handled by maintainers.

If the change genuinely needs no entry, a maintainer can apply the
'${SKIP_LABEL}' label to this pull request and the check will pass.
EOF

exit 1
