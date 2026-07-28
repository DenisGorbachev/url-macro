#!/usr/bin/env bash

set -euo pipefail

unset GIT_INDEX_FILE
project_root=$(realpath "${MISE_PROJECT_ROOT:-$(pwd)}")

# Repair real-index entries left stale when a pathspec commit used a temporary index.
git -C "$project_root" diff --cached --name-only HEAD -z -- |
  while IFS= read -r -d '' path; do
    if git -C "$project_root" --literal-pathspecs diff --quiet HEAD -- "$path"; then
      git -C "$project_root" --literal-pathspecs add --all -- "$path"
    else
      worktree_diff_status=$?
      if [[ $worktree_diff_status -ne 1 ]]; then
        exit "$worktree_diff_status"
      fi
    fi
  done
