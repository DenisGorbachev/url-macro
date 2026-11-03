#!/usr/bin/env bash

set -euo pipefail

MISE_LOG_LEVEL=warn mise --cd "$PWD" install
if ! git diff --quiet -- || [[ -n $(git ls-files --others --exclude-standard) ]]; then
  echo "repoconf preparation requires existing changes to be staged before regeneration" >&2
  exit 1
fi
mise --cd "$PWD" run fix
git add --all
