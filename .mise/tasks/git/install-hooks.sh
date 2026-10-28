#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../../../.agents/skills/shell-scripts/log.sh"
hooks_dir=$(git rev-parse --path-format=absolute --git-path hooks)
mkdir -p "$hooks_dir"
temporary=
trap '[[ -z $temporary ]] || rm -f "$temporary"' EXIT

for hook in pre-commit pre-merge-commit commit-msg; do
  temporary=$(mktemp "$hooks_dir/.hook.XXXXXX")
  {
    echo '#!/bin/sh'
    echo "exec mise run $hook -- \"\$@\""
  } >"$temporary"
  hook_path="$hooks_dir/$hook"
  if [[ -L $hook_path ]]; then
    error "refusing to replace symlinked hook: $hook_path"
  elif [[ -e $hook_path ]]; then
    if ! cmp -s "$temporary" "$hook_path"; then
      error "refusing to replace existing hook with different contents: $hook_path"
    fi
    if [[ ! -x $hook_path ]]; then
      error "existing hook is not executable: $hook_path"
    fi
  else
    chmod 0755 "$temporary"
    ln "$temporary" "$hook_path"
  fi
  rm -f "$temporary"
  temporary=
done
