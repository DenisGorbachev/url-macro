#!/usr/bin/env bash

set -euo pipefail

profile_raw=${1:?"profile is required"} && shift
key_raw=${1:?"key is required"} && shift
# this script doesn't read the value_raw arg because the value can be piped from stdin or typed manually in response to the hidden input prompt

profile=$profile_raw
key=$(ccase --to constant "$key_raw")
key_name=$(ccase --to constant "${profile}_${key}")

case "$profile" in
prod)
  provider=keychain
  ;;
test)
  provider=pass
  ;;
*)
  printf 'unrecognized profile: %s\n' "$profile" >&2
  exit 1
  ;;
esac

# `--key-name` is required to set a different key name per profile (by default fnox sets the same key name as key)
fnox set --profile "$profile" --provider "$provider" --key-name "$key_name" "$key" "$@"
