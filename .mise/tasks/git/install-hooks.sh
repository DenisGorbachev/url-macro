#!/usr/bin/env bash

set -euo pipefail

hooks_dir=$(git rev-parse --path-format=absolute --git-path hooks)
mkdir -p "$hooks_dir"

for hook in pre-commit pre-merge-commit commit-msg; do
  {
    echo '#!/bin/sh'
    echo "exec mise run $hook -- \"\$@\""
  } >"$hooks_dir/$hook"
  chmod 0755 "$hooks_dir/$hook"
done
