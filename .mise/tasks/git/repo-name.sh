#!/usr/bin/env bash
#MISE output="interleave"
#MISE quiet=true

set -euo pipefail

project_root=$(realpath "${MISE_PROJECT_ROOT:-$(pwd)}")
origin_url=$(git -C "$project_root" remote get-url origin) || {
  echo "failed to read the origin remote URL for $project_root" >&2
  exit 1
}
origin_url=${origin_url%/}
repo_name=${origin_url##*/}
repo_name=${repo_name%.git}
if [[ -z $repo_name ]]; then
  echo "failed to extract the repository name from origin remote URL: $origin_url" >&2
  exit 1
fi
echo "$repo_name"
