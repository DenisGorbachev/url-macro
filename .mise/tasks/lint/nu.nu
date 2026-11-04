#!/usr/bin/env -S nu --no-config-file

use ../nu.nu nu-files

def main []: nothing -> nothing {
    let files = nu-files
    let result = (^nu-lint check --config nu-lint.toml --format compact ...$files | complete)
    print --no-newline $result.stdout
    print --stderr --no-newline $result.stderr
    if $result.exit_code != 0 {
        exit $result.exit_code
    }
    # nu-lint 1.8.0 returns zero for warnings and hints; reject compact diagnostics explicitly.
    if $result.stdout =~ '(?m)^.+:\d+:\d+: \w+\(' {
        exit 1
    }
    exec nufmt --dry-run --shebang ...$files
}
