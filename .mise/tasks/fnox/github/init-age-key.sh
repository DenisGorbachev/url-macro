#!/usr/bin/env bash
#MISE raw=true

# A caller may enable tracing for all shell scripts. Disable it before any key
# material exists so the private identity cannot be written to a trace.
set +x
set -euo pipefail

umask 077

temp_dir=
temp_config_path=
clipboard_tool=

copy_to_clipboard() {
  case "$clipboard_tool" in
  pbcopy)
    pbcopy
    ;;
  wl-copy)
    wl-copy
    ;;
  xclip)
    xclip -selection clipboard
    ;;
  xsel)
    xsel --clipboard --input
    ;;
  *)
    echo "no supported clipboard command is configured" >&2
    return 1
    ;;
  esac
}

# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2329
cleanup() {
  local status=$? cleanup_failed=false
  trap - EXIT
  set +e

  if [[ -n $clipboard_tool ]]; then
    if ! copy_to_clipboard </dev/null; then
      echo "warning: failed to clear the clipboard" >&2
      cleanup_failed=true
    fi
  fi

  # PRUNING: Remove only the temporary config copy and key-generation directory
  # created by this invocation. The identity must not survive the workflow.
  if [[ -n $temp_config_path ]]; then
    if ! rm -f -- "$temp_config_path"; then
      echo "warning: failed to remove temporary config: $temp_config_path" >&2
      cleanup_failed=true
    fi
  fi
  if [[ -n $temp_dir ]]; then
    if ! rm -rf -- "$temp_dir"; then
      echo "warning: failed to remove temporary key directory: $temp_dir" >&2
      cleanup_failed=true
    fi
  fi
  if [[ $status -eq 0 && $cleanup_failed == true ]]; then
    status=1
  fi

  exit "$status"
}
trap cleanup EXIT

require_command() {
  local command_name=${1:?}
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "required command not found: $command_name" >&2
    exit 1
  fi
}

select_clipboard_tool() {
  local candidate
  for candidate in pbcopy wl-copy xclip xsel; do
    if command -v "$candidate" >/dev/null 2>&1; then
      clipboard_tool=$candidate
      return
    fi
  done

  echo "a clipboard command is required (pbcopy, wl-copy, xclip, or xsel)" >&2
  exit 1
}

github_repo_from_origin() {
  local origin=${1:?} repo
  case "$origin" in
  git@github.com:*)
    repo=${origin#git@github.com:}
    ;;
  https://github.com/*)
    repo=${origin#https://github.com/}
    ;;
  ssh://git@github.com/*)
    repo=${origin#ssh://git@github.com/}
    ;;
  *)
    echo "failed to extract a GitHub repository from origin: $origin" >&2
    return 1
    ;;
  esac

  repo=${repo%/}
  repo=${repo%.git}
  if [[ ! $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "failed to extract owner/repo from GitHub origin: $origin" >&2
    return 1
  fi
  echo "$repo"
}

assert_safe_fnox_file() {
  local fnox_path=${1:?}
  if [[ -L $fnox_path ]]; then
    echo "refusing to replace symlinked fnox config: $fnox_path" >&2
    return 1
  fi
  if [[ ! -f $fnox_path ]]; then
    echo "fnox config not found: $fnox_path" >&2
    return 1
  fi
}

copy_config_with_metadata() {
  local source=${1:?} destination=${2:?}
  if cp --version >/dev/null 2>&1; then
    cp --preserve=all -- "$source" "$destination"
  else
    cp -p "$source" "$destination"
  fi
}

validate_age_config() {
  local project_root=${1:?} fnox_path=${2:?}
  if ! MISE_PROJECT_ROOT="$project_root" "$project_root/.mise/tasks/fix/fnox.sh" \
    --fnox-toml "$fnox_path" --allow-pass-test-secrets; then
    echo "fnox config validation failed: $fnox_path" >&2
    return 1
  fi
}

read_fnox_config() {
  local config_path=${1:?}
  taplo get --file-path "$config_path" --output-format json
}

refuse_age_ciphertext() {
  local config_json=${1:?} has_age_ciphertext
  if ! has_age_ciphertext=$(jq --raw-output '
    def secret_values:
      ((.secrets // {}) | .[]?),
      ((.profiles // {}) | .[]? | (.secrets // {}) | .[]?);

    any(
      secret_values;
      (.provider? == "age")
      or (((.sync? // {}) | .provider?) == "age")
    )
  ' <<<"$config_json"); then
    echo "failed to inspect fnox secrets for existing age ciphertext" >&2
    exit 1
  fi

  if [[ $has_age_ciphertext == true ]]; then
    echo "fnox.toml already contains age-backed ciphertext; refusing to add or replace a CI age key because the existing secrets would need to be re-encrypted" >&2
    exit 1
  fi
}

copy_private_identity() {
  local identity_path=${1:?}
  if ! awk '/^AGE-SECRET-KEY-[[:alnum:]]+$/ { printf "%s", $0 }' "$identity_path" | copy_to_clipboard; then
    echo "failed to copy the private identity to the clipboard" >&2
    return 1
  fi
}

copy_value() {
  local value=${1:?}
  if ! printf '%s' "$value" | copy_to_clipboard; then
    echo "failed to copy a value to the clipboard" >&2
    return 1
  fi
}

append_recipient() {
  local fnox_path=${1:?} recipient=${2:?} project_root=${3:?}
  local config_json new_recipients_json
  local recipients_source_path source_config_path expected_config_path updated_config_path

  assert_safe_fnox_file "$fnox_path"
  if ! config_json=$(read_fnox_config "$fnox_path"); then
    echo "failed to read $fnox_path before updating it" >&2
    exit 1
  fi
  refuse_age_ciphertext "$config_json"

  if jq --exit-status --arg recipient "$recipient" '
    .providers.age.recipients | index($recipient) != null
  ' >/dev/null <<<"$config_json"; then
    echo "the generated recipient is already present in $fnox_path; refusing to replace an existing CI age key" >&2
    exit 1
  fi

  new_recipients_json=$(jq --compact-output --arg recipient "$recipient" '
    .providers.age.recipients + [$recipient]
  ' <<<"$config_json")

  recipients_source_path="$temp_dir/recipients.toml"
  source_config_path="$temp_dir/source-config.toml"
  expected_config_path="$temp_dir/expected-config.json"
  updated_config_path="$temp_dir/updated-config.json"
  echo "recipients = $new_recipients_json" >"$recipients_source_path"

  temp_config_path=$(mktemp "$fnox_path.XXXXXXXXXX")
  copy_config_with_metadata "$fnox_path" "$temp_config_path"
  cp -- "$temp_config_path" "$source_config_path"
  tomli copy --filepath "$recipients_source_path" --in-place \
    recipients "$temp_config_path" providers.age.recipients

  jq --argjson recipients "$new_recipients_json" '
    .providers.age.recipients = $recipients
  ' <<<"$config_json" >"$expected_config_path"
  if ! read_fnox_config "$temp_config_path" >"$updated_config_path"; then
    echo "failed to read the updated fnox config" >&2
    exit 1
  fi
  if ! jq --slurp --exit-status '.[0] == .[1]' \
    "$expected_config_path" "$updated_config_path" >/dev/null; then
    echo "updating the recipients would modify other fnox settings; refusing the update" >&2
    exit 1
  fi
  taplo lint --no-auto-config --no-schema "$temp_config_path"
  validate_age_config "$project_root" "$temp_config_path"
  assert_safe_fnox_file "$fnox_path"
  if ! cmp -s "$source_config_path" "$fnox_path"; then
    echo "$fnox_path changed while it was being updated; refusing to overwrite the newer contents" >&2
    exit 1
  fi

  # Portable Bash has no pathname compare-and-swap. The repository lock
  # serializes cooperating tasks, and the user confirms immediately before
  # this function that editors and other noncooperating writers are stopped.
  # PRUNING: Atomically replace fnox.toml only after proving that the public
  # recipient is the sole semantic change; the original contents are preserved.
  mv -f -- "$temp_config_path" "$fnox_path"
  temp_config_path=
}

if [[ $# -ne 0 ]]; then
  echo "usage: $0" >&2
  exit 1
fi

require_command git

project_dir=${MISE_PROJECT_ROOT:-$(pwd)}
if ! project_root=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null); then
  echo "Skipping: $project_dir is not a Git repository."
  exit 0
fi

repo_dir_name=${project_root##*/}
if [[ $repo_dir_name == *@* ]]; then
  echo "Skipping: $project_root is not a canonical repository checkout."
  exit 0
fi

if ! origin_url=$(git -C "$project_root" remote get-url origin 2>/dev/null); then
  echo "Skipping: $project_root has no origin remote."
  exit 0
fi
if [[ $origin_url != *github.com* ]]; then
  echo "Skipping: the origin remote is not hosted on GitHub."
  exit 0
fi

for command_name in awk cmp cp jq mktemp rage-keygen taplo tomli; do
  require_command "$command_name"
done

fnox_toml="$project_root/fnox.toml"
assert_safe_fnox_file "$fnox_toml"
validate_age_config "$project_root" "$fnox_toml"

if ! config_json=$(read_fnox_config "$fnox_toml"); then
  echo "failed to read $fnox_toml" >&2
  exit 1
fi
refuse_age_ciphertext "$config_json"

if ! name_with_owner=$(github_repo_from_origin "$origin_url"); then
  exit 1
fi

echo
echo "→ Check the 1Password item \"$name_with_owner\" for \"FNOX_AGE_KEY\""
echo "→ Check https://github.com/$name_with_owner/settings/secrets/actions for \"FNOX_AGE_KEY\""
read -r -p "→ Continue only if this is the intended repository and neither exists (press Enter; Ctrl-C to cancel)" _

select_clipboard_tool

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/fnox-github-init-age-key.XXXXXXXXXX")
identity_path="$temp_dir/identity.txt"
rage-keygen --output "$identity_path"

private_line_count=$(awk '/^AGE-SECRET-KEY-[[:alnum:]]+$/ { count++ } END { print count + 0 }' "$identity_path")
if [[ $private_line_count -ne 1 ]]; then
  echo "rage-keygen did not produce exactly one AGE-SECRET-KEY line" >&2
  exit 1
fi
if ! recipient=$(rage-keygen -y "$identity_path"); then
  echo "failed to derive the public age recipient" >&2
  exit 1
fi
if [[ ! $recipient =~ ^age1[0-9a-z]+$ ]]; then
  echo "rage-keygen returned an invalid public age recipient" >&2
  exit 1
fi

echo
copy_value "$name_with_owner"
read -r -p "→ Create or open one 1Password item named \"$name_with_owner\" (copied to clipboard)" _
copy_private_identity "$identity_path"
read -r -p "→ Set concealed field \"FNOX_AGE_KEY\" to the secret key (copied to clipboard)" _
read -r -p "→ Save the 1Password item" _

echo
echo "→ Open https://github.com/$name_with_owner/settings/secrets/actions/new"
copy_value FNOX_AGE_KEY
read -r -p "→ Set \"Name\" to \"FNOX_AGE_KEY\" (copied to clipboard)" _

copy_private_identity "$identity_path"
read -r -p "→ Set \"Secret\" to the secret key (copied to clipboard)" _
read -r -p "→ Click \"Add secret\"" _
copy_to_clipboard </dev/null

read -r -p "→ Close fnox.toml editors and stop its writers, then continue (Ctrl-C to cancel)" _

append_recipient "$fnox_toml" "$recipient" "$project_root"
echo "✓ Added the CI age recipient to $fnox_toml"
