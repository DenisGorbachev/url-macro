#!/usr/bin/env bash
#MISE wait_for=["fix:name"]

set -euo pipefail

check=false
if [[ ${1:-} == --check ]]; then
  check=true
  shift
fi
if [[ $# -ne 0 ]]; then
  echo "usage: $0 [--check]" >&2
  exit 1
fi

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
manifest_path="$project_root/Cargo.toml"
metadata_args=(cargo metadata --manifest-path "$manifest_path" --format-version 1 --no-deps)
if [[ $check == true ]]; then
  metadata_args+=(--locked)
fi
metadata=$("${metadata_args[@]}")
status=0

while IFS= read -r -d '' manifest; do
  if workspace_lints=$(taplo get --file-path "$manifest" --strip-newline "lints.workspace" 2>/dev/null) &&
    [[ $workspace_lints == true ]]; then
    continue
  fi
  if [[ $check == true ]] || tomli --filepath "$manifest" query "lints" >/dev/null 2>&1; then
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

# External paths are local overrides; publishable non-development dependencies also need a registry version.
dependency_errors=$(
  jq --raw-output '
    def manifest_dir: sub("[/\\\\]Cargo\\.toml$"; "");

    .workspace_members as $member_ids
    | [.packages[] | select(.id as $id | $member_ids | index($id))] as $packages
    | [$packages[] | .manifest_path | manifest_dir] as $package_dirs
    | $packages[] as $package
    | $package.dependencies[]
    | select(.path != null)
    | . as $dependency
    | if ($package_dirs | index($dependency.path) | not) then
        "\($package.manifest_path): dependency \u0027\($dependency.rename // $dependency.name)\u0027 uses non-workspace path \u0027\($dependency.path)\u0027; use a temporary [patch] entry in .cargo/config.toml for local overrides"
      elif $package.publish != [] and $dependency.kind != "dev" and $dependency.req == "*" then
        "\($package.manifest_path): publishable package \u0027\($package.name)\u0027 dependency \u0027\($dependency.rename // $dependency.name)\u0027 uses a workspace path without a registry version"
      else empty end
  ' <<<"$metadata"
)
if [[ -n $dependency_errors ]]; then
  echo "$dependency_errors" >&2
  status=1
fi

# Cargo metadata omits unused workspace dependencies, patches, and replacements.
root_manifest=$(taplo get --file-path "$manifest_path" --output-format json)
while IFS= read -r -d '' location && IFS= read -r -d '' dependency_name && IFS= read -r -d '' dependency_path; do
  dependency_path_candidate=$dependency_path
  [[ $dependency_path == /* ]] || dependency_path_candidate="$project_root/$dependency_path"
  if ! dependency_dir=$(realpath -- "$dependency_path_candidate"); then
    echo "$manifest_path: $location '$dependency_name' path '$dependency_path' does not resolve" >&2
    status=1
    continue
  fi
  if ! jq --exit-status --arg path "$dependency_dir" '
    def manifest_dir: sub("[/\\\\]Cargo\\.toml$"; "");
    .workspace_members as $members
    | [.packages[] | select(.id as $id | $members | index($id))] as $packages
    | any($packages[].dependencies[]; .path == $path)
      or any($packages[]; (.manifest_path | manifest_dir) == $path)
  ' <<<"$metadata" >/dev/null; then
    echo "$manifest_path: $location '$dependency_name' uses non-workspace path '$dependency_path'; use a temporary [patch] entry in .cargo/config.toml for local overrides" >&2
    status=1
  fi
done < <(
  jq --join-output --raw-output '
    def paths($location; $table):
      ($table // {}) | to_entries[]
      | select(.value | type == "object" and (.path? | type == "string"))
      | $location, "\u0000", .key, "\u0000", .value.path, "\u0000";
    paths("workspace dependency"; .workspace.dependencies?),
    ((.patch // {}) | to_entries[] | . as $patch | paths("patch \u0027\($patch.key)\u0027 dependency"; $patch.value)),
    paths("replacement"; .replace?)
  ' <<<"$root_manifest"
)

exit "$status"
