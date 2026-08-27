#!/usr/bin/env bash

# Rename specification
#
# * Must use `workspace.metadata.details.name` as the current repository name when defined, otherwise `package.name`.
# * Must use the explicit argument or the Git remote name as the target repository name.
# * Must rename matching parts of every workspace package name and Rust crate reference.
# * Must update Cargo manifest references, including workspace members, default members, dependency names, and local dependency paths.
# * Must derive package directories from workspace member manifest paths rather than assuming a workspace layout.
# * Must not rename the workspace root directory.
# * Must rename nested package directories before their parents.
# * Must refresh an existing Cargo lockfile and validate the renamed workspace before committing the new repository name.
# * Must roll back modified files and directory moves if any rename step fails.

set -euo pipefail

# Invoked indirectly by the EXIT trap in `apply_rename`.
# shellcheck disable=SC2329
rollback_transaction() {
  local backup_root=${1:?} status=${2:?}
  trap - EXIT
  set +e
  if [[ ! -e $backup_root/committed ]]; then
    while IFS= read -r -d '' source && IFS= read -r -d '' destination; do
      if [[ -e $source && ! -e $destination ]]; then
        mv "$source" "$destination"
      fi
    done <"$backup_root/directory-rollbacks"
    # PRUNING: Restore the archived originals, dropping only changes made by this failed rename transaction.
    [[ ! -f $backup_root/files.tar ]] || tar -xPf "$backup_root/files.tar"
  fi
  # PRUNING: Delete only temporary transaction backups after success or rollback because the originals have been committed or restored.
  rm -rf "$backup_root"
  exit "$status"
}

apply_rename() (
  set -euo pipefail
  local metadata=${1:?} name_old=${2:?} name_new=${3:?} name_key=${4:?}
  local workspace_root
  workspace_root=$(jq --exit-status --raw-output '.workspace_root' <<<"$metadata")
  local cargo_toml="$workspace_root/Cargo.toml"

  # `ccase` leaves periods unchanged, so normalize them before deriving kebab- and snake-case names.
  local name_old_case_input=${name_old//./-} name_new_case_input=${name_new//./-}
  local name_old_snake_case name_new_snake_case name_old_kebab_case name_new_kebab_case
  name_old_snake_case=$(ccase --to snake "$name_old_case_input")
  name_new_snake_case=$(ccase --to snake "$name_new_case_input")
  name_old_kebab_case=$(ccase --to kebab "$name_old_case_input")
  name_new_kebab_case=$(ccase --to kebab "$name_new_case_input")
  local kebab_pattern="\b(?:$name_new_kebab_case|$name_old_kebab_case)\b"
  local snake_pattern="\b(?:$name_new_snake_case|$name_old_snake_case)(\b|_)"

  local backup_root
  backup_root=$(mktemp -d "${TMPDIR:-/tmp}/fix-name.XXXXXX")
  local manifest_paths_file="$backup_root/manifest-paths"
  local rust_paths_file="$backup_root/rust-paths"
  local backup_paths_file="$backup_root/backup-paths"
  local directory_rollbacks_file="$backup_root/directory-rollbacks"
  local -a package_dirs=()
  local -a package_dir_destinations=()
  : >"$directory_rollbacks_file"
  trap 'rollback_transaction "$backup_root" "$?"' EXIT

  jq --join-output --raw-output '
    .workspace_members as $members
    | [
        (.workspace_root + "/Cargo.toml"),
        (.packages[] | select(.id as $id | $members | index($id)) | .manifest_path)
      ]
    | unique | sort_by(split("/") | length) | reverse[]
    | . + "\u0000"
  ' <<<"$metadata" >"$manifest_paths_file"
  : >"$rust_paths_file"
  if [[ $name_old_snake_case != "$name_new_snake_case" ]]; then
    rg --files-with-matches --null --glob '*.rs' --glob '!specs/**' --glob '!.agents/**' -- "$name_old_snake_case" "$workspace_root" >"$rust_paths_file" || [[ $? -eq 1 ]]
  fi

  cat "$manifest_paths_file" "$rust_paths_file" >"$backup_paths_file"
  local cargo_lock="$workspace_root/Cargo.lock"
  if [[ -f $cargo_lock ]]; then
    jq --null-input --join-output --raw-output --arg path "$cargo_lock" '$path + "\u0000"' >>"$backup_paths_file"
  fi
  # Archive every mutable file before editing so a failure after a directory move can restore the original workspace.
  tar -cPf "$backup_root/files.tar" --null -T "$backup_paths_file"

  local path package_dir package_name package_name_new destination rollbacks_file_new
  while IFS= read -r -d '' path; do
    package_dir=${path%/*}
    [[ $package_dir != "$workspace_root" ]] || continue
    package_name=${package_dir##*/}
    package_name_new=$(sd --flags c "$kebab_pattern" "$name_new_kebab_case" <<<"$package_name")
    destination="${package_dir%/*}/$package_name_new"
    [[ $package_dir != "$destination" ]] || continue
    if [[ -e $destination ]]; then
      echo "cannot rename package directory because destination already exists: $destination" >&2
      return 1
    fi
    rollbacks_file_new="$directory_rollbacks_file.new"
    jq --null-input --join-output --raw-output --arg source "$destination" --arg destination "$package_dir" '$source + "\u0000" + $destination + "\u0000"' >"$rollbacks_file_new"
    cat "$directory_rollbacks_file" >>"$rollbacks_file_new"
    mv "$rollbacks_file_new" "$directory_rollbacks_file"
    package_dirs+=("$package_dir")
    package_dir_destinations+=("$destination")
  done <"$manifest_paths_file"

  # Cargo references must change in the same rollback-protected transaction as package directories; otherwise path dependencies can make the workspace unreadable and prevent a retry.
  while IFS= read -r -d '' path; do
    sd --flags c "$kebab_pattern" "$name_new_kebab_case" "$path"
    if [[ $name_old_snake_case != "$name_new_snake_case" ]]; then
      sd --flags c "$snake_pattern" "${name_new_snake_case}\$1" "$path"
    fi
  done <"$manifest_paths_file"
  if [[ $name_key == package.name ]]; then
    tomli set --filepath "$cargo_toml" --in-place "$name_key" "$name_new_kebab_case"
  fi
  while IFS= read -r -d '' path; do
    sd --flags c "$snake_pattern" "${name_new_snake_case}\$1" "$path"
  done <"$rust_paths_file"

  local index
  for index in "${!package_dirs[@]}"; do
    mv "${package_dirs[$index]}" "${package_dir_destinations[$index]}"
  done

  local validation_flag=--no-deps
  if [[ -f $cargo_lock ]]; then
    cargo metadata --manifest-path "$cargo_toml" --format-version 1 >/dev/null || {
      echo "failed to refresh $cargo_lock" >&2
      return 1
    }
    validation_flag=--locked
  fi
  cargo metadata --manifest-path "$cargo_toml" --format-version 1 "$validation_flag" >/dev/null || {
    echo "renamed Cargo workspace metadata is invalid in $cargo_toml" >&2
    return 1
  }
  if [[ $name_key == workspace.metadata.details.name ]]; then
    tomli set --filepath "$cargo_toml" --in-place "$name_key" "$name_new"
  fi
  touch "$backup_root/committed"
)

check=false
if [[ ${1:-} == --check ]]; then
  check=true
  shift
fi
if [[ $# -gt 1 ]]; then
  echo "usage: $0 [--check] [new-name]" >&2
  exit 1
fi

cargo_toml=$(realpath "${MISE_PROJECT_ROOT:-$(pwd)}/Cargo.toml")
name_new=${1:-$(mise run git:repo-name)}
name_key=workspace.metadata.details.name
if ! name_old=$(taplo get --file-path "$cargo_toml" --strip-newline "$name_key" 2>/dev/null); then
  name_key=package.name
  name_old=$(taplo get --file-path "$cargo_toml" --strip-newline "$name_key") || {
    echo "failed to read workspace.metadata.details.name or package.name from $cargo_toml" >&2
    exit 1
  }
  name_new=$(ccase --to kebab "${name_new//./-}")
fi
if [[ -z $name_old ]]; then
  echo "$name_key must not be empty in $cargo_toml" >&2
  exit 1
fi
if [[ $name_old == "$name_new" ]]; then
  exit 0
fi
if [[ $check == true ]]; then
  echo "$cargo_toml: $name_key '$name_old' does not match repository name '$name_new'; run 'mise run fix:name'" >&2
  exit 1
fi

metadata=$(cargo metadata --manifest-path "$cargo_toml" --format-version 1 --no-deps) || {
  echo "failed to read Cargo workspace metadata from $cargo_toml" >&2
  exit 1
}

apply_rename "$metadata" "$name_old" "$name_new" "$name_key"
