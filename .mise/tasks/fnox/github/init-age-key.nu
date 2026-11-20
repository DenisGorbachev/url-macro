#!/usr/bin/env -S nu --no-config-file
#MISE raw=true
#USAGE flag "--vault <vault>" help="1Password vault for the repository key" default="Private"

def main [
    --vault: string = "Private" # 1Password vault for the repository key.
]: nothing -> nothing {
    let root = (^git -C ($env.MISE_PROJECT_ROOT? | default $env.PWD) rev-parse --show-toplevel | complete)
    if $root.exit_code != 0 { return }
    cd ($root.stdout | str trim)
    if ($env.PWD | path basename) =~ "@" { return }
    let origin = (^git config --default "" --get remote.origin.url | str trim)
    if $origin !~ '(?i)^(?:(?:https?|ssh|git)://(?:[^/@]+@)?github\.com(?::\d+)?/|(?:[^/@:]+@)?github\.com:)' { return }

    let config = "fnox.toml"
    if ($config | path type) != "file" { fail "Expected a regular fnox.toml file" $config }
    ^./.mise/tasks/fix/fnox.sh
    let repo = (^gh repo view $origin --json "nameWithOwner,url" | from json)
    let identity = (ci-identity $vault $repo)
    if $identity !~ '^AGE-SECRET-KEY-1[0-9A-Z]+$' {
        fail "The 1Password field must contain exactly one native age private key." $repo.url
    }
    update-recipients $config $identity
    $identity | ^gh secret set "FNOX_AGE_KEY" --repo $repo.url
    print $"Configured FNOX_AGE_KEY for ($repo.nameWithOwner)."
}

def ci-identity [vault: string, repo: record]: nothing -> string {
    let title = $repo.url | str replace --regex '^https://' ""
    let items = (^op item list --vault $vault --cache=false --format "json" | from json | where {|item|
        $item.title in [$title $repo.nameWithOwner]
    })
    match ($items | length) {
        0 => {
            let secrets = (^gh secret list --repo $repo.url --json "name" | from json)
            if ($secrets | any {|secret| $secret.name == "FNOX_AGE_KEY" }) {
                fail $"GitHub already has FNOX_AGE_KEY. Restore its 1Password item in ($vault) before retrying, or explicitly rotate the key." $title
            }
            let identity = (^rage-keygen | lines | last)
            {
                title: $title
                category: "PASSWORD"
                fields: [
                    {
                        id: "password"
                        type: "CONCEALED"
                        purpose: "PASSWORD"
                        label: "password"
                        value: $identity
                    }
                ]
            } | to json | ^op item create - --vault $vault out> /dev/null
            $identity
        }
        1 => {
            let item = $items | first
            let field = if $item.title == $title { "password" } else { "FNOX_AGE_KEY" }
            ^op item get $item.id --vault $vault --cache=false --reveal --format "human-readable" --fields $"label=($field)" | str trim
        }
        _ => { fail $"Multiple 1Password items match ($title) in ($vault): ($items | get id | str join ', '). Resolve the duplicate titles and retry." $title }
    }
}

def update-recipients [config: path, identity: string]: nothing -> nothing {
    let recipient = $identity | ^rage-keygen -y | str trim
    let original = (open --raw $config)
    let settings = $original | from toml
    let staged = (mktemp --suffix ".local.toml" ".ci-age-XXXXXXXX")
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
        migrate-test-secrets $staged $identity
        if ($config | path type) != "file" or (open --raw $config) != $original {
            fail "fnox.toml changed during setup. Retry with the updated config." $config
        }
        if (open --raw $staged) != $original { mv --force $staged $config }
    } finally {
        rm -f $staged
    }
}

def migrate-test-secrets [staged: path, identity: string]: nothing -> nothing {
    let settings = (open $staged)
    let secrets = $settings.profiles?.test?.secrets? | default {}
    let imports = (
        $settings.import?
        | default []
        | each { path expand }
        | prepend ($staged | path expand)
    )
    let scratch = (mktemp --directory)
    let work = $scratch | path join "migration.toml"
    try {
        for entry in ($secrets | transpose name secret) {
            for field in ["value" "sync.value"] {
                let binding = if $field == "value" { $entry.secret } else { $entry.secret.sync? }
                if $binding.provider? != "age" or $binding.value? == null or ($binding.value | can-decrypt $identity $scratch) { continue }
                let target = $"profiles.test.secrets.($entry.name | to json --raw).($field)"
                let secret = {provider: "age", value: $binding.value}
                {
                    import: $imports
                    profiles: {
                        test: {
                            secrets: {CI_AGE_VALUE: $secret}
                        }
                    }
                } | to toml | save --force $work
                try {
                    ^fnox --config $work --profile "test" --no-defaults --no-daemon reencrypt --force --provider "age" "CI_AGE_VALUE"
                } catch {|err| fail $"Re-encryption failed for ($target): ($err.msg)" $target }
                let value = open $work | get profiles.test.secrets.CI_AGE_VALUE.value
                if not ($value | can-decrypt $identity $scratch) { fail "The CI key cannot decrypt the new ciphertext." $target }
                ^tomli set --in-place --filepath $staged $target $value
            }
        }
    } finally {
        rm -r $scratch
    }
}

def can-decrypt [identity: string, scratch: path]: string -> bool {
    let ciphertext = $scratch | path join "ciphertext"
    $in | decode base64 | save --raw --force $ciphertext
    try {
        $identity | ^rage --decrypt --identity "-" $ciphertext out+err> /dev/null
        true
    } catch {
        false
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
