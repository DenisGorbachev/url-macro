#!/usr/bin/env bash

set -euo pipefail

hooks_dir=$(git rev-parse --path-format=absolute --git-path hooks)
mkdir -p "$hooks_dir"

# Remove obsolete Lefthook launchers, including hooks that no longer have mise replacements.
for hook_path in "$hooks_dir"/*; do
  [[ -f $hook_path ]] || continue
  [[ $(<"$hook_path") == *"call_lefthook run "* ]] || continue
  rm -f "$hook_path"
done
rm -f "$(git rev-parse --path-format=absolute --git-path info/lefthook.checksum)"

write_hook() {
  local hook_path=${1:?}
  local command=${2:?}

  {
    echo '#!/bin/sh'
    echo "$command"
  } >"$hook_path"
  chmod 0755 "$hook_path"
}

# These repository-owned hooks intentionally replace the previous Lefthook launchers.
write_hook "$hooks_dir/pre-commit" 'exec mise run pre-commit -- "$@"'
write_hook "$hooks_dir/pre-merge-commit" 'exec mise run pre-merge-commit -- "$@"'
write_hook "$hooks_dir/commit-msg" 'exec mise run commit-msg -- "$@"'

post_commit_hook="$hooks_dir/post-commit"
if [[ -f $post_commit_hook && $(<"$post_commit_hook") == $'#!/bin/sh\nexec mise run post-commit -- "$@"' ]]; then
  # PRUNING: Remove only the obsolete repository-generated hook because commit validation no longer mutates the index.
  rm -f -- "$post_commit_hook"
fi
