#!/usr/bin/env -S nu --no-config-file
#MISE raw=true

def main [
    --vault: string = "Private" # 1Password vault for the repository key.
]: nothing -> nothing {
    let status = ^git status --porcelain=v1 --untracked-files=normal --ignore-submodules=none
    if ($status | is-not-empty) { fail "Commit or stash changes before running this task." $status }
    let config = "fnox.toml" | path expand --strict
    let files = [$config "AGENTS.md"]
    let tracked = ^git ls-files -v --error-unmatch -- ...$files "."
    if $tracked =~ '(?m)^[a-zS] ' {
        fail "Clear assume-unchanged and skip-worktree flags before running this task." $config
    }
    let repo_url = ^gh repo view (^git config --get remote.origin.url) --json "url" --jq ".url"
    let identity = ci-identity $vault $repo_url
    if $identity !~ '^AGE-SECRET-KEY-1[0-9A-Z]+$' {
        fail "The 1Password field must contain exactly one native age private key." $repo_url
    }
    ^git diff --exit-code --name-only HEAD -- ...$files
    mut generated = ""
    let failure = try {
        update-recipients $config $identity
        let changed = ^git diff --name-only -- $config
        if ($changed | is-not-empty) {
            ^mise run gen:agents
            $generated = ^git hash-object "AGENTS.md"
            ^git commit --only --message "chore: configure CI age key" -- ...$files
        }
        null
    } catch {|err| $err }
    if $failure != null {
        ^git restore --worktree -- $config
        if $generated != "" and (^git hash-object "AGENTS.md") == $generated {
            ^git restore --worktree -- "AGENTS.md"
        }
        error make $failure
    }
    $identity | ^gh secret set "FNOX_AGE_KEY" --repo $repo_url
    print $"Configured FNOX_AGE_KEY for ($repo_url)."
}

def ci-identity [vault: string, repo_url: string]: nothing -> string {
    let title = $repo_url | str replace --regex '^https://' ""
    let item = ci-item $vault $title
    if $item != null {
        match ($item.fields | where label == "password" | get value) {
            [$password] => { return ($password | str trim) }
            _ => { fail "Expected exactly one password field in the 1Password item." $title }
        }
    }
    let names = ^gh secret list --repo $repo_url --json "name" | from json | get name
    if "FNOX_AGE_KEY" in $names {
        fail $"GitHub already has FNOX_AGE_KEY. Restore its 1Password item in ($vault) before retrying, or explicitly rotate the key." $title
    }
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
    if $lookup.exit_code == 0 {
        let item = $lookup.stdout | from json
        if $item.title == $title { return $item }
    }
    let ids = ^op item list --vault $vault --format "json" | from json | where title == $title | get id
    match $ids {
        [] => { null }
        [$id] => {
            ^op item get $id --vault $vault --format "json" --reveal | from json
        }
        _ => { fail $"Multiple 1Password items match ($title) in ($vault): ($ids | str join ', '). Resolve the duplicate titles and retry." $title }
    }
}

def update-recipients [config: path, identity: string]: nothing -> nothing {
    let recipient = $identity | ^rage-keygen -y
    let settings = open $config
    for provider in ["providers.age.recipients" "profiles.test.providers.age.recipients"] {
        let path = $provider | split row "." | into cell-path
        let existing = $settings | get --optional $path
        if $existing != null and $recipient not-in $existing {
            {
                recipients: ($existing | append $recipient)
            } | to toml | ^tomli copy --in-place "recipients" $config $provider
        }
    }
    let keys = $settings | pending-keys $identity
    if ($keys | is-not-empty) {
        ^fnox --config $config --profile "test" reencrypt --force --provider "age" -- ...$keys
        let unreadable = open $config | pending-keys $identity
        if ($unreadable | is-not-empty) {
            fail $"Check the effective test age recipients. The CI key cannot decrypt: ($unreadable | str join ', ')." $config
        }
    }
}

def pending-keys [identity: string]: record -> list<string> {
    let entries = $in.profiles?.test?.secrets? | default {} | transpose name secret | where secret.provider? == "age" | where secret.value? != null
    let ciphertext = mktemp
    try {
        $entries | where {|entry|
            if $entry.secret.sync? != null { return true }
            $entry.secret.value | decode base64 | save --raw --force $ciphertext
            try {
                $identity | ^rage --decrypt --identity "-" $ciphertext out+err> /dev/null
                false
            } catch {
                true
            }
        } | get name | collect
    } finally {
        rm -f $ciphertext
    }
}

def fail [message: string, context: string]: nothing -> error {
    error make {
        msg: $message
        label: {
            text: $context
            span: (metadata $context).span
        }
    }
}
