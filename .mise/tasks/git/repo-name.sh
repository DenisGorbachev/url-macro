#!/usr/bin/env bash
#MISE output="interleave"
#MISE quiet=true

set -euo pipefail

if [[ $# -gt 1 || ( $# -eq 1 && $1 != --with-owner ) ]]; then
  echo "usage: git:repo-name [--with-owner]" >&2
  exit 1
fi

project_root=$(realpath "${MISE_PROJECT_ROOT:-$(pwd)}")
origin_url=$(git -C "$project_root" config --get remote.origin.url) || {
  echo "failed to read the origin remote URL for $project_root" >&2
  exit 1
}
if [[ ${1:-} == --with-owner ]]; then
  case "$origin_url" in
  git@github.com:*) repo_name=${origin_url#git@github.com:} ;;
  https://github.com/*) repo_name=${origin_url#https://github.com/} ;;
  ssh://git@github.com/*) repo_name=${origin_url#ssh://git@github.com/} ;;
  *)
    echo "failed to extract a GitHub repository from origin: $origin_url" >&2
    exit 1
    ;;
  esac
else
  origin_url=${origin_url%/}
  repo_name=${origin_url##*/}
fi
repo_name=${repo_name%/}
repo_name=${repo_name%.git}
if [[ -z $repo_name ]]; then
  echo "failed to extract the repository name from origin remote URL: $origin_url" >&2
  exit 1
fi
if [[ ${1:-} == --with-owner && ! $repo_name =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "failed to extract owner/repo from GitHub origin: $origin_url" >&2
  exit 1
fi
echo "$repo_name"
