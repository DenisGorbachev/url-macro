#!/usr/bin/env -S usage bash
#USAGE arg "<dir>"

set -xeuo pipefail

dir=$(realpath "${usage_dir:?}")
cargo_toml="$dir/Cargo.toml"
fnox_toml="$dir/fnox.toml"

(
  cd "$dir"

  mise trust
  mise install
  mise reshim

  # Using the Git repo name instead of the folder name because a workspace can contain multiple checkouts of the same repository in different folders, and a virtual manifest has no `package.name`.
  origin_url=$(git remote get-url origin)
  repo_url=
  if [[ $origin_url == *github.com* ]]; then
    repo_json=$(gh repo view --json name,url)
    repo_name=$(jq --exit-status --raw-output '.name | strings | select(length > 0)' <<<"$repo_json")
    repo_url=$(jq --exit-status --raw-output '.url | strings | select(length > 0)' <<<"$repo_json")
  else
    repo_name=$(mise run git:repo-name)
  fi

  rm -f README.md

  mise run fix:name "$repo_name"
  cargo metadata --manifest-path "$cargo_toml" --format-version 1 --no-deps |
    jq --join-output --raw-output '
      .workspace_members as $members
      | .packages[]
      | select(.id as $id | $members | index($id))
      | .manifest_path + "\u0000"
    ' |
    while IFS= read -r -d '' manifest; do
      tomli set --filepath "$manifest" --in-place "package.metadata.details.title" ""
      tomli delete --filepath "$manifest" --in-place --if-exists "package.description"
      if [[ -z $repo_url ]]; then
        for field in repository homepage; do
          tomli delete --filepath "$manifest" --in-place --if-exists "package.$field"
        done
      fi
    done

  tomli set --filepath "$cargo_toml" --in-place "workspace.metadata.details.title" ""
  tomli delete --filepath "$cargo_toml" --in-place --if-exists "workspace.package.description"
  for field in repository homepage; do
    if [[ -n $repo_url ]]; then
      tomli set --filepath "$cargo_toml" --in-place "workspace.package.$field" "$repo_url"
    else
      tomli delete --filepath "$cargo_toml" --in-place --if-exists "workspace.package.$field"
    fi
  done

  tomli set --filepath "$fnox_toml" --in-place "providers.keychain.service" "$repo_name"
  tomli set --filepath "$fnox_toml" --in-place "providers.pass.prefix" "$repo_name/"

  mise run gen:readme
  mise run build
  mise run test

  git add .
  git commit -m "chore: update project details"
)
