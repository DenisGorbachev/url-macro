#!/usr/bin/env bash
#MISE raw=true
#USAGE arg "<profile>" help="Secret profile" {
#USAGE   choices "prod" "test"
#USAGE }
#USAGE arg "<key>" help="Secret key"
#USAGE arg "[fnox_args]" help="Additional fnox set arguments, including optional secret value" var=#true

set -euo pipefail

profile_raw=${1:?"profile is required"} && shift
key_raw=${1:?"key is required"} && shift
# this script doesn't define a dedicated value arg because fnox already accepts the value among its own args

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
  echo "unrecognized profile: $profile" >&2
  exit 1
  ;;
esac

# `--key-name` is required to set a different key name per profile (by default fnox sets the same key name as key)
fnox_args=(set --profile "$profile" --provider "$provider" --key-name "$key_name" "$key" "$@")

if [[ -t 0 && $# -eq 0 ]]; then
  # Work around fnox redrawing its hidden prompt under mise raw tasks.
  read -r -s -p "Secret value: " value
  echo >&2
  fnox "${fnox_args[@]}" <<< "$value"
else
  fnox "${fnox_args[@]}"
fi
