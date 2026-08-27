#!/usr/bin/env bash
#MISE wait_for=["fix:name"]

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

validate_fnox_config() {
  local config_json=${1:?} allow_pass_test_secrets=${2:?} actual_type recipient_count invalid_recipient_indexes invalid_test_secrets

  actual_type=$(jq --raw-output '.providers.age | type' <<<"$config_json")
  if [[ $actual_type != object ]]; then
    echo "providers.age must be a table, got $actual_type" >&2
    return 1
  fi

  if ! jq --exit-status '.providers.age.type == "age"' >/dev/null <<<"$config_json"; then
    echo 'providers.age.type must be "age"' >&2
    return 1
  fi

  actual_type=$(jq --raw-output '.providers.age.recipients | type' <<<"$config_json")
  if [[ $actual_type != array ]]; then
    echo "providers.age.recipients must be an array, got $actual_type" >&2
    return 1
  fi

  recipient_count=$(jq --raw-output '.providers.age.recipients | length' <<<"$config_json")
  if ((recipient_count < 2)); then
    echo "providers.age.recipients must contain at least two recipients, got $recipient_count" >&2
    return 1
  fi

  invalid_recipient_indexes=$(jq --raw-output '
    .providers.age.recipients
    | to_entries
    | map(
        select(
          .value
          | if type == "string" then (test("^age1[0-9a-z]+$") | not) else true end
        )
        | (.key | tostring)
      )
    | join(", ")
  ' <<<"$config_json")
  if [[ -n $invalid_recipient_indexes ]]; then
    echo "providers.age.recipients contains invalid native age recipients at indexes: $invalid_recipient_indexes" >&2
    return 1
  fi

  if ! jq --exit-status '
    (.providers.age.recipients | length)
    == (.providers.age.recipients | unique | length)
  ' >/dev/null <<<"$config_json"; then
    echo "providers.age.recipients must not contain duplicates" >&2
    return 1
  fi

  actual_type=$(jq --raw-output '(.profiles.test.secrets // {}) | type' <<<"$config_json")
  if [[ $actual_type != object ]]; then
    echo "profiles.test.secrets must be a table, got $actual_type" >&2
    return 1
  fi

  invalid_test_secrets=$(jq --raw-output --argjson allow_pass_test_secrets "$allow_pass_test_secrets" '
    (.profiles.test.secrets // {})
    | to_entries
    | map(
        select(
          .value
          | if type == "object" then
              (.provider != "age" and (($allow_pass_test_secrets and .provider == "pass") | not))
            else
              true
            end
        )
        | .key
      )
    | join(", ")
  ' <<<"$config_json")
  if [[ -n $invalid_test_secrets ]]; then
    if [[ $allow_pass_test_secrets == true ]]; then
      echo "test secrets must use provider = \"age\" or migration-only provider = \"pass\": $invalid_test_secrets" >&2
    else
      echo "test secrets must use provider = \"age\": $invalid_test_secrets" >&2
    fi
    return 1
  fi
}

fnox_toml=
allow_pass_test_secrets=false
while [[ $# -gt 0 ]]; do
  case "$1" in
  --fnox-toml)
    fnox_toml=${2:?"--fnox-toml requires a path"}
    shift 2
    ;;
  --allow-pass-test-secrets)
    # TODO: Remove this migration-only mode after every repository has migrated its test secrets from pass to age.
    allow_pass_test_secrets=true
    shift
    ;;
  *)
    echo "usage: $0 [--fnox-toml <path>] [--allow-pass-test-secrets]" >&2
    exit 1
    ;;
  esac
done

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
fnox_toml=${fnox_toml:-"$project_root/fnox.toml"}
project_name=$(mise --cd "$project_root" run git:repo-name)
assert_toml_value "$fnox_toml" "providers.keychain.service" "$project_name"
assert_toml_value "$fnox_toml" "env" "exec"
config_json=$(taplo get --file-path "$fnox_toml" --output-format json)
validate_fnox_config "$config_json" "$allow_pass_test_secrets"
