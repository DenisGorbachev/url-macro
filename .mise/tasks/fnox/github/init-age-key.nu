#!/usr/bin/env -S nu --no-config-file
#MISE raw=true

use std/assert

def main [
    --vault: string = "Repos" # 1Password vault for the repository key.
]: nothing -> nothing {
    let config = "fnox.toml" | path expand --strict
    require-clean-repo $config
    let repo_url = ^gh repo view (^git config --get remote.origin.url) --json "url" --jq ".url"
    let identity = ci-identity $vault $repo_url
    assert ($identity =~ '^AGE-SECRET-KEY-1[0-9A-Z]+$') $"Expected one native age private key for ($repo_url)."
    update-config $config $identity
    let changed = ^git diff --name-only -- $config
    if ($changed | is-not-empty) { commit-config $config }
    $identity | ^gh secret set "FNOX_AGE_KEY" --repo $repo_url
    print $"Configured FNOX_AGE_KEY for ($repo_url)."
}

def require-clean-repo [config: path]: nothing -> nothing {
    let status = ^git status --porcelain=v1 --untracked-files=normal --ignore-submodules=none
    assert ($status | is-empty) $"Commit or stash changes before running this task.\n($status)"
    let tracked = ^git ls-files -v --error-unmatch -- $config "AGENTS.md" "."
    assert ($tracked !~ '(?m)^[a-zS] ') "Clear assume-unchanged and skip-worktree flags before running this task."
}

def update-config [config: path, identity: string]: nothing -> nothing {
    ^git diff --exit-code --name-only HEAD -- $config "AGENTS.md"
    try {
        update-recipients $config $identity
        reencrypt-test-secrets $config $identity
    } catch {|err|
        ^git restore --worktree -- $config
        error make $err
    }
}

def commit-config [config: path]: nothing -> nothing {
    let files = [$config "AGENTS.md"]
    ^git diff --exit-code --name-only HEAD -- "AGENTS.md"
    try {
        ^mise run gen:agents
    } catch {|err|
        ^git restore --worktree -- ...$files
        error make $err
    }
    commit-generated ...$files
}

def commit-generated [...files: path]: nothing -> nothing {
    let generated = ^git hash-object -- ...$files
    try {
        ^git commit --only --message "chore: configure CI age key" -- ...$files
    } catch {|err|
        restore-generated $files $generated
        error make $err
    }
}

def restore-generated [files: list<path>, generated: string]: nothing -> nothing {
    let current = ^git hash-object -- ...$files | complete
    if $current.exit_code == 0 and ($current.stdout | str trim) == $generated {
        ^git restore --worktree -- ...$files
    }
}

def ci-identity [vault: string, repo_url: string]: nothing -> string {
    let title = $repo_url | str replace --regex '^https://' ""
    let item = ci-item $vault $title
    if $item != null {
        return (item-password $item)
    }
    let names = ^gh secret list --repo $repo_url --json "name" | from json | get name
    assert ("FNOX_AGE_KEY" not-in $names) $"GitHub already has FNOX_AGE_KEY. Restore ($title) in ($vault) before retrying, or explicitly rotate the key."
    create-identity $vault $title
}

def item-password [item: record]: nothing -> string {
    let passwords = $item.fields | where label == "password" | get value
    assert (($passwords | length) == 1) $"Expected exactly one password field in the 1Password item ($item.title)."
    $passwords | first | str trim
}

def create-identity [vault: string, title: string]: nothing -> string {
    let identity = ^rage-keygen | lines | last
    let password = {
        id: "password"
        type: "CONCEALED"
        purpose: "PASSWORD"
        label: "password"
        value: $identity
    }
    {
        title: $title
        category: "PASSWORD"
        fields: [$password]
    } | to json | ^op item create - --vault $vault out> /dev/null
    $identity
}

def ci-item [vault: string, title: string]: nothing -> oneof<record, nothing> {
    let lookup = ^op item get $title --vault $vault --format "json" --reveal | complete
    try {
        assert ($lookup.exit_code == 0)
        let item = $lookup.stdout | from json
        assert ($item.title == $title)
        $item
    } catch {
        listed-item $vault $title
    }
}

def listed-item [vault: string, title: string]: nothing -> oneof<record, nothing> {
    let ids = listed-item-ids $vault $title
    if ($ids | is-not-empty) {
        ^op item get ($ids | first) --vault $vault --format "json" --reveal | from json
    }
}

def listed-item-ids [vault: string, title: string]: nothing -> list<string> {
    let ids = ^op item list --vault $vault --format "json" | from json | where title == $title | get id
    assert (($ids | length) <= 1) $"Resolve duplicate 1Password items for ($title) in ($vault): ($ids | str join ', ')."
    $ids
}

def update-recipients [config: path, identity: string]: nothing -> nothing {
    let recipient = $identity | ^rage-keygen -y
    $recipient | add-recipient $config "providers.age.recipients"
    $recipient | add-recipient $config "profiles.test.providers.age.recipients"
}

def add-recipient [config: path, provider: string]: string -> nothing {
    let recipient = $in
    let path = $provider | split row "." | into cell-path
    let existing = open --raw $config | from toml | get --optional $path
    if $existing != null and $recipient not-in $existing {
        {
            recipients: ($existing | append $recipient)
        } | to toml | ^tomli copy --in-place "recipients" $config $provider
    }
}

def reencrypt-test-secrets [config: path, identity: string]: nothing -> nothing {
    let keys = pending-keys $config $identity
    if ($keys | is-empty) { return }
    ^fnox --config $config --profile "test" reencrypt --force --provider "age" -- ...$keys
    let unreadable = pending-keys $config $identity
    assert ($unreadable | is-empty) $"Check the test age recipients in ($config). The CI key cannot decrypt: ($unreadable | str join ', ')."
}

def pending-keys [config: path, identity: string]: nothing -> list<string> {
    let settings = open --raw $config | from toml
    $settings.profiles?.test?.secrets? | default {} | transpose name secret | where {|entry|
        let secret = $entry.secret
        $secret.provider? == "age" and $secret.value? != null and (
            $secret.sync? != null or not (decryptable $identity $secret.value)
        )
    } | get name
}

def decryptable [identity: string, value: string]: nothing -> bool {
    let ciphertext = mktemp
    try {
        $value | decode base64 | save --raw --force $ciphertext
        let result = $identity | ^rage --decrypt --identity "-" --output "/dev/null" $ciphertext | complete
        $result.exit_code == 0
    } finally {
        rm -f $ciphertext
    }
}
