#!/usr/bin/env -S nu --no-config-file

def main [
    --minimum-age: duration = 1wk # Required age of each registry release.
    --timeout: duration = 30sec # Timeout for each metadata request.
]: nothing -> nothing {
    if $minimum_age < 0sec or $timeout <= 0sec {
        fail "Minimum age must be nonnegative and timeout must be positive" ($minimum_age | into string)
    }
    cd (^git "rev-parse" "--show-toplevel" | str trim)
    let cargo_home = $env.CARGO_HOME? | default ($env.HOME | path join ".cargo") | path expand
    let index_root = $cargo_home | path join "registry" "index"
    let caches = if ($index_root | path exists) {
        ls $index_root | where type == "dir" | get "name" | where {|dir|
            $dir | path basename | str starts-with "index.crates.io-"
        } | each {|dir| $dir | path join ".cache" }
    } else {
        []
    }
    let lockfiles = ^git "ls-files" "--cached" "--deduplicate" "--full-name" "-z" | split row (char nul) | where {|file|
        ($file | path basename) == "Cargo.lock"
    }
    let packages = $lockfiles | each {|file|
        let lock = ^git "show" $":($file)" | from toml
        $lock.package? | default [] | where {|package|
            $package.source? != null and not ($package.source | str starts-with "git+")
        } | each {|package| $package | insert "lockfile" $file }
    } | flatten | uniq-by "source" "name" "version" "checksum"
    let cutoff = (date now) - $minimum_age
    for package in $packages {
        try {
            if $package.source != "registry+https://github.com/rust-lang/crates.io-index" {
                fail $"Unsupported registry '($package.source)'; publication age cannot be verified" $package.source
            }
            let published = publication-time $package --timeout $timeout ...$caches
            if $published > $cutoff {
                fail $"Published ($published | format date '%+'); minimum age is ($minimum_age); eligible at (($published + $minimum_age) | format date '%+')" $package.version
            }
        } catch {|err|
            fail $"($package.lockfile): ($package.name)@($package.version): ($err.msg)" $package.name
        }
    }
}

def publication-time [package: record, --timeout: duration = 30sec, ...caches: path]: nothing -> datetime {
    let name = $package.name | str lowercase
    if $name !~ '^[a-z0-9_-]+$' {
        fail $"Invalid crates.io package name '($package.name)'" $package.name
    }
    let prefix = match ($name | str length) {
        1 => "1"
        2 => "2"
        3 => $"3/($name | str substring 0..0)"
        _ => $"($name | str substring 0..1)/($name | str substring 2..3)"
    }
    let index_path = $"($prefix)/($name)"
    let cached = cached-entries $index_path ...$caches | where {|entry|
        $entry.name == $package.name and $entry.vers == $package.version and $entry.pubtime? != null
    }
    let entries = if ($cached | is-empty) {
        http get --raw --max-time $timeout $"https://index.crates.io/($index_path)" | lines | each { from json } | where {|entry|
            $entry.name == $package.name and $entry.vers == $package.version
        }
    } else {
        $cached
    }
    if ($entries | is-empty) {
        fail "Version is absent from crates.io publication metadata" $package.version
    }
    let timestamps = $entries | each {|entry|
        if $entry.cksum != $package.checksum {
            fail "Staged checksum differs from crates.io publication metadata" $package.checksum
        }
        $entry.pubtime | into datetime --format "%+"
    } | uniq
    if ($timestamps | length) != 1 {
        fail "Conflicting publication timestamps in crates.io metadata" $package.version
    }
    $timestamps | first
}

def cached-entries [index_path: path, ...caches: path]: nothing -> table {
    let files = $caches | each {|cache| $cache | path join $index_path } | where { path exists }
    $files | each {|file|
        open --raw $file | split row (char nul) | where {|part| $part | str starts-with "{" } | each { from json }
    } | flatten
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
