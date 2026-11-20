#!/usr/bin/env bash
#MISE wait_for=["fix:name"]

set -euo pipefail

fnox_toml=
while [[ $# -gt 0 ]]; do
  case "$1" in
  --fnox-toml)
    fnox_toml=${2:?"--fnox-toml requires a path"}
    shift 2
    ;;
  *)
    echo "usage: $0 [--fnox-toml <path>]" >&2
    exit 1
    ;;
  esac
done

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
fnox_toml=${fnox_toml:-"$project_root/fnox.toml"}
project_name=$(mise --cd "$project_root" run git:repo-name)
taplo get --file-path "$fnox_toml" --output-format json | jq --exit-status --arg project_name "$project_name" '
  def require($condition; $message): if $condition then . else error($message) end;
  require(.providers.keychain.service == $project_name; "providers.keychain.service must match repository name")
  | require(.env == "exec"; "env must be exec")
  | require((.providers.age | type) == "object"; "providers.age must be a table")
  | require(.providers.age.type == "age"; "providers.age.type must be age")
  | .providers.age.recipients as $recipients
  | require(($recipients | type) == "array"; "providers.age.recipients must be an array")
  | require(($recipients | length) >= 2; "providers.age.recipients must contain at least two recipients")
  | require(all($recipients[]; if type == "string" then test("^age1[0-9a-z]+$") else false end); "providers.age.recipients contains invalid native age recipients")
  | require(($recipients | length) == ($recipients | unique | length); "providers.age.recipients must not contain duplicates")
  | (.profiles.test.secrets // {})
  | require(type == "object"; "profiles.test.secrets must be a table")
  | to_entries
  | map(select(.value | if type == "object" then .provider != "age" else true end))
  | require(length == 0; "test secrets must use age: " + (map(.key) | join(", ")))
' >/dev/null
