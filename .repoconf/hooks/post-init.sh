#!/usr/bin/env -S usage bash
#USAGE flag "-n --name <name>" help="Package name (if this flag is not provided, then the package name is inferred from the directory name)"
#USAGE arg "<dir>"

set -xeuo pipefail

dir=$(realpath "${usage_dir:?}")
name_new_default="${usage_name:-$(basename "$dir")}"
cargo_toml="$dir/Cargo.toml"
#mise_toml="$dir/mise.toml"

read -r -p "Rust package name (default: $name_new_default): " name_new
read -r -p "Rust package description: " description
read -r -p "Rust package title (default: same as description): " title

if [[ -z $name_new ]]; then
  name_new=$name_new_default
fi

if [[ -z $title ]]; then
  title=$description
fi

(
  cd "$dir"

  files=("README.md" "LICENSE-APACHE" "LICENSE-MIT")
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      rm "$file"
    fi
  done

  mise trust
  mise install

  name_old=$(taplo get -f "$cargo_toml" "package.name")
  name_old_snake_case=$(ccase --to snake "$name_old")
  name_new_snake_case=$(ccase --to snake "$name_new")
  repo_url=$(cd "$dir" && gh repo view --json url | jq -r .url)

  tomli set -f "$cargo_toml" "package.name" "$name_new" | sponge "$cargo_toml"
  tomli set -f "$cargo_toml" "package.repository" "$repo_url" | sponge "$cargo_toml"
  tomli set -f "$cargo_toml" "package.homepage" "$repo_url" | sponge "$cargo_toml"
  tomli set -f "$cargo_toml" "package.description" "$description" | sponge "$cargo_toml"
  tomli set -f "$cargo_toml" "package.metadata.details.title" "$title" | sponge "$cargo_toml"
  tomli delete --if-exists -f "$cargo_toml" "package.metadata.details.readme.generate" | sponge "$cargo_toml"

  # rg exits with status code = 1 if it doesn't find any files, so we need to disable & re-enable "set -e"
  set +e
  rg --files-with-matches "$name_old_snake_case" "$dir" | xargs gsed -i "s/\b$name_old_snake_case\b/$name_new_snake_case/g"
  set -e

  mise exec -- lefthook install

  mise run build
  mise run test

  git add .
  git commit -a -m "chore: update package details"
)
