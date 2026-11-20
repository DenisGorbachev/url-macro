#!/usr/bin/env -S nu --no-config-file
#MISE raw=true

def main [
    --vault: string = "Private" # 1Password vault for the repository key.
]: nothing -> nothing {
    let repo_url = ^gh repo view (^git config --get remote.origin.url) --json "url" --jq ".url"
    let identity = ci-identity $vault $repo_url
    if $identity !~ '^AGE-SECRET-KEY-1[0-9A-Z]+$' {
        fail "The 1Password field must contain exactly one native age private key." $repo_url
    }
    update-recipients ("fnox.toml" | path expand --strict) $identity
    $identity | ^gh secret set "FNOX_AGE_KEY" --repo $repo_url
    print $"Configured FNOX_AGE_KEY for ($repo_url)."
}

def ci-identity [vault: string, repo_url: string]: nothing -> string {
    let title = $repo_url | str replace --regex '^https://' ""
    let ids = ^op item list --vault $vault --cache=false --format "json" | from json | where title == $title | get id
    match $ids {
        [$id] => {
            ^op item get $id --vault $vault --cache=false --reveal --format "human-readable" --fields "label=password" | str trim
        }
        [] => {
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
        _ => { fail $"Multiple 1Password items match ($title) in ($vault): ($ids | str join ', '). Resolve the duplicate titles and retry." $title }
    }
}

def update-recipients [config: path, identity: string]: nothing -> nothing {
    let recipient = $identity | ^rage-keygen -y
    let original = open --raw $config
    let settings = $original | from toml
    let staged = mktemp --tmpdir-path ($config | path dirname) --suffix ".local.toml" ".ci-age-XXXXXXXX"
    try {
        ^cp -p $config $staged
        for provider in ["providers.age.recipients" "profiles.test.providers.age.recipients"] {
            let path = $provider | split row "." | into cell-path
            let existing = $settings | get --optional $path
            if $existing != null and $recipient not-in $existing {
                {
                    recipients: ($existing | append $recipient)
                } | to toml | ^tomli copy --in-place "recipients" $staged $provider
            }
        }
        let keys = $settings | pending-keys $identity
        if ($keys | is-not-empty) {
            ^fnox --config $staged --profile "test" reencrypt --force --provider "age" -- ...$keys
            let unreadable = open $staged | pending-keys $identity
            if ($unreadable | is-not-empty) {
                fail $"Check the effective test age recipients. The CI key cannot decrypt: ($unreadable | str join ', ')." $config
            }
        }
        # The caller must ensure fnox.toml is not edited concurrently while this task runs.
        if (open --raw $staged) != $original { mv --force $staged $config }
    } finally {
        rm -f $staged
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
