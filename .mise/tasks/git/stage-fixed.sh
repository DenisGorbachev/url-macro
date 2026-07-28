#!/usr/bin/env bash

set -euo pipefail

project_root=$(realpath "${MISE_PROJECT_ROOT:-$(pwd)}")

# Restage the filesystem contents of paths already present in Git's active index.
git -C "$project_root" diff --cached --name-only --diff-filter=ACMR -z -- |
  while IFS= read -r -d '' path; do
    git -C "$project_root" --literal-pathspecs add -- "$path"
  done
