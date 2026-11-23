#!/usr/bin/env -S nu --no-config-file
#MISE raw=true

use std/assert

const FNOX_CONFIG = "fnox.toml" | path expand

# Caller must guarantee that 1Password vault items are unique by title
def main [
    --vault: string = "Repos" # 1Password vault for the repository key.
]: nothing -> nothing {
    require-clean-repo
    let repo_url = ^gh repo view (^git config --get remote.origin.url) --json "url" --jq ".url"
    let identity = ci-identity $vault $repo_url
    assert ($identity =~ '^AGE-SECRET-KEY-1[0-9A-Z]+$') $"Expected one native age private key for ($repo_url)."
    update-config $identity
    let changed = ^git diff --name-only -- $FNOX_CONFIG
    if ($changed | is-not-empty) { commit-config }
    $identity | ^gh secret set "FNOX_AGE_KEY" --repo $repo_url
    print $"Configured FNOX_AGE_KEY for ($repo_url)."
}

def require-clean-repo []: nothing -> nothing {
    let status = ^git status --porcelain=v1 --untracked-files=normal --ignore-submodules=none
    assert ($status | is-empty) $"Commit or stash changes before running this task.\n($status)"
    let tracked = ^git ls-files -v --error-unmatch -- $FNOX_CONFIG "AGENTS.md" "."
    assert ($tracked !~ '(?m)^[a-zS] ') "Clear assume-unchanged and skip-worktree flags before running this task."
}

def update-config [identity: string]: nothing -> nothing {
    ^git diff --exit-code --name-only HEAD -- $FNOX_CONFIG "AGENTS.md"
    try {
        update-recipients $identity
        reencrypt-test-secrets $identity
    } catch {|err|
        ^git restore --worktree -- $FNOX_CONFIG
        error make $err
    }
}

def commit-config []: nothing -> nothing {
    let files = [$FNOX_CONFIG "AGENTS.md"]
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
    let id = listed-item-id $vault $title
    if $id != null {
        ^op item get $id --vault $vault --format "json" --reveal | from json
    }
}

def listed-item-id [vault: string, title: string]: nothing -> oneof<string, nothing> {
    ^op item list --vault $vault --format "json" | from json | where title == $title | get --optional 0.id
}

def update-recipients [identity: string]: nothing -> nothing {
    let recipient = $identity | ^rage-keygen -y
    let settings = open --raw $FNOX_CONFIG | from toml
    let test_age = $settings.profiles?.test?.providers?.age?
    if $test_age == null {
        $settings.providers?.age?.recipients? | add-recipient $recipient "providers.age.recipients"
    } else {
        $test_age.recipients? | add-recipient $recipient "profiles.test.providers.age.recipients"
    }
}

def add-recipient [recipient: string, field: string]: oneof<list<any>, nothing> -> nothing {
    let existing = $in
    if $existing != null and $recipient not-in $existing {
        {
            recipients: ($existing | append $recipient)
        } | to toml | ^tomli copy --in-place "recipients" $FNOX_CONFIG $field
    }
}

def reencrypt-test-secrets [identity: string]: nothing -> nothing {
    let keys = pending-keys $identity
    if ($keys | is-empty) { return }
    ^fnox --config $FNOX_CONFIG --profile "test" reencrypt --force --provider "age" -- ...$keys
    let unreadable = pending-keys $identity
    assert ($unreadable | is-empty) $"Check the test age recipients in ($FNOX_CONFIG). The CI key cannot decrypt: ($unreadable | str join ', ')."
}

def pending-keys [identity: string]: nothing -> list<string> {
    let settings = open --raw $FNOX_CONFIG | from toml
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
