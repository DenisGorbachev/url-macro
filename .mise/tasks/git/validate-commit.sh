#!/usr/bin/env bash

set -euo pipefail

project_dir=${MISE_PROJECT_ROOT:-$(pwd)}
project_root=$(git -C "$project_dir" rev-parse --show-toplevel)
git_output_template=$(git -C "$project_root" rev-parse --path-format=absolute --git-path validate-commit-output.XXXXXX)
git_output_file=$(mktemp "$git_output_template")

# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2329
cleanup() {
  # PRUNING: Remove only the temporary Git output file created by this validation run.
  rm -f -- "$git_output_file"
}
trap cleanup EXIT

show_status() {
  git -C "$project_root" status --short --untracked-files=all || true
}

assert_worktree_matches_index() {
  local phase=${1:?}
  local index_entry index_tag
  local diff_status=0

  if ! git -C "$project_root" ls-files -v -z >"$git_output_file"; then
    echo "failed to inspect active Git index flags $phase checks" >&2
    return 1
  fi
  while IFS= read -r -d '' index_entry; do
    index_tag=${index_entry:0:1}
    if [[ $index_tag == S || $index_tag == [[:lower:]] ]]; then
      echo "commit validation does not support assume-unchanged or skip-worktree entries in the active Git index $phase checks" >&2
      echo "clear those flags and use a full worktree; sparse checkouts cannot guarantee that checks read the candidate tree" >&2
      return 1
    fi
  done <"$git_output_file"

  git -C "$project_root" diff --no-ext-diff --quiet --ignore-submodules=none -- || diff_status=$?
  if [[ $diff_status -eq 1 ]]; then
    echo "commit validation requires the working tree to match the active Git index $phase checks" >&2
    echo "partial staging and commits that exclude other working-tree changes are intentionally unsupported" >&2
    show_status >&2
    return 1
  fi
  if [[ $diff_status -ne 0 ]]; then
    echo "failed to compare the working tree with the active Git index $phase checks" >&2
    return "$diff_status"
  fi

  if ! git -C "$project_root" ls-files --others --exclude-standard -z >"$git_output_file"; then
    echo "failed to list nonignored untracked files $phase checks" >&2
    return 1
  fi
  if [[ -s $git_output_file ]]; then
    echo "commit validation requires every nonignored untracked file to be staged or removed $phase checks" >&2
    echo "partial staging is intentionally unsupported; use a separate worktree for unrelated work" >&2
    show_status >&2
    return 1
  fi
}

initial_tree=$(git -C "$project_root" write-tree) || {
  echo "failed to snapshot the active Git index before checks; resolve any unmerged entries and retry" >&2
  exit 1
}
assert_worktree_matches_index "before"

# This design assumes repository-mutating commands do not run concurrently; a transient mutation restored before the final assertions cannot be detected.
mise run check

assert_worktree_matches_index "after"
final_tree=$(git -C "$project_root" write-tree) || {
  echo "failed to snapshot the active Git index after checks" >&2
  exit 1
}
if [[ $final_tree != "$initial_tree" ]]; then
  echo "the active Git index changed while commit checks were running" >&2
  echo "commit checks must leave the candidate tree unchanged; retry after the concurrent or mutating task finishes" >&2
  exit 1
fi
