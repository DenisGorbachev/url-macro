#!/usr/bin/env bash
#MISE depends=["fix:name"]

set -euo pipefail

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
metadata=$(cargo metadata --manifest-path "$project_root/Cargo.toml" --format-version 1 --no-deps)
status=0

while IFS= read -r -d '' manifest; do
  if workspace_lints=$(taplo get --file-path "$manifest" --strip-newline "lints.workspace" 2>/dev/null) &&
    [[ $workspace_lints == true ]]; then
    continue
  fi
  if tomli --filepath "$manifest" query "lints" >/dev/null 2>&1; then
    echo "$manifest: lints.workspace must equal true" >&2
    status=1
  else
    tomli set --filepath "$manifest" --in-place --type bool "lints.workspace" true
  fi
done < <(
  jq --join-output --raw-output '
    .workspace_members as $members
    | .packages[]
    | select(.id as $id | $members | index($id))
    | .manifest_path + "\u0000"
  ' <<<"$metadata"
)

exit "$status"
