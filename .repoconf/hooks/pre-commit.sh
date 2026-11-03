#!/usr/bin/env bash

set -euo pipefail

git diff --no-ext-diff --quiet --ignore-submodules=none -- || {
  echo "repoconf preparation requires existing changes to be staged before regeneration" >&2
  exit 1
}
untracked=$(git ls-files --others --exclude-standard)
if [[ -n $untracked ]]; then
  echo "repoconf preparation requires untracked files to be staged or removed before regeneration" >&2
  exit 1
fi

MISE_LOG_LEVEL=warn mise install
mise run fix
git add --all
