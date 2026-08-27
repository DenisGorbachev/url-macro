#!/usr/bin/env bash

set -euo pipefail

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
config="$project_root/.cargo/config.toml"

# Read the working-tree file so an unstaged local override cannot bypass validation.
taplo lint --no-auto-config --no-schema "$config"
config_json=$(taplo get --file-path "$config" --output-format json)
violations=$(
  jq --raw-output --arg config "$config" '
    def patch_path_overrides:
      (.patch // {})
      | to_entries[]
      | .key as $source
      | .value
      | to_entries[]
      | select((.value | type) == "object" and (.value.path? | type) == "string")
      | "\($config): patch source \u0027\($source)\u0027 dependency \u0027\(.key)\u0027 uses local path \u0027\(.value.path)\u0027; commit and push the dependency, remove the override, update Cargo.lock, and retry";

    patch_path_overrides,
    (
      (.paths // [])[]
      | select(type == "string")
      | "\($config): legacy Cargo path override \u0027\(.)\u0027 is not allowed during final validation or commits; remove the override and retry"
    )
  ' <<<"$config_json"
)
if [[ -n $violations ]]; then
  echo "$violations" >&2
  exit 1
fi
