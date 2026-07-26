#!/usr/bin/env bash
#MISE depends=["fix:name"]

set -euo pipefail

assert_toml_value() {
  local file=${1:?} key=${2:?} expected=${3?} actual
  actual=$(taplo get --file-path "$file" --strip-newline "$key") || {
    echo "failed to read $key from $file" >&2
    return 1
  }
  if [[ $actual != "$expected" ]]; then
    echo "expected $key to be \"$expected\", got \"$actual\"" >&2
    return 1
  fi
}

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
fnox_toml="$project_root/fnox.toml"
project_name=$(mise run git:repo-name)
assert_toml_value "$fnox_toml" "providers.keychain.service" "$project_name"
assert_toml_value "$fnox_toml" "providers.pass.prefix" "$project_name/"
