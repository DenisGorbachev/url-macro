#!/usr/bin/env -S nu --no-config-file

def --wrapped main [command: string, ...args: string]: nothing -> nothing {
    exec $command ...$args ...(nu-files)
}

export def nu-files []: nothing -> list<string> {
    ^git ls-files --cached --others --exclude-standard -z | split row (char nul) | where { is-not-empty } | uniq | where {|file|
        ($file | path type) == file and (
            ($file | path parse | get extension) == nu or (
                ($file | path parse | get extension) == '' and
                ((open --raw $file | lines | first 1 | str join) =~ '^#!.*\bnu(\s|$)')
            )
        )
    }
}
