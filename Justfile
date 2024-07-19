import? 'Justfile.local.just'

set quiet

default:
  just --list

build *args:
  cargo build {{args}}

lint *args:
  cargo clippy --all-targets --all-features {{args}} -- -D warnings

test *args:
  cargo nextest run {{args}}

watch *args:
  #!/usr/bin/env bash
  set -euxo pipefail
  PWD=$(pwd)
  CMD_RAW="nextest run $*"
  CMD_NO_WHITESPACE="$(echo -e "${CMD_RAW}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  cargo watch --clear --watch "$PWD" --exec "$CMD_NO_WHITESPACE"

check *args:
  cargo check --all-targets "$@"

fix *args:
  cargo fix --workspace --allow-dirty --allow-staged {{args}}

reset *args:
  supabase db reset
  just migrate {{args}}
