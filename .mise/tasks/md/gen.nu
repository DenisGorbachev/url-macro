#!/usr/bin/env -S nu --no-config-file

def main [
    generator: path
    --fix # Write generated files instead of checking freshness.
]: nothing -> nothing {
    let generator = $generator | path expand
    let scratch = (mktemp --directory)
    try {
        let outputs: table<path: string, content: string> = (
            with-env {TMPDIR: $scratch} { ^$generator } | from json
        )
        let outputs = ($outputs | each {|output|
            let destination = $output.path | path expand
            if ($destination | path type) not-in [null "file"] {
                fail $"Destination '($destination)' must be a file" $destination
            }
            {path: $destination, content: $output.content}
        })
        if ($outputs | get path | uniq | length) != ($outputs | length) {
            fail $"Generator '($generator)' returned duplicate destinations" $generator
        }
        for output in $outputs {
            $output.content | ^mise run --quiet --output "interleave" "lint:docs" -- --stdin --stdin-filename $output.path
        }
        if $fix {
            mut staged = []
            let failure = try {
                for output in $outputs {
                    let dir = mktemp --directory --tmpdir-path ($output.path | path dirname) ".generated.XXXXXXXX"
                    let file = $dir | path join "content"
                    $staged ++= [
                        {path: $output.path, file: $file, dir: $dir}
                    ]
                    $output.content | save --raw $file
                    ^chmod "644" $file
                }
                null
            } catch {|err| $err }
            let staged = $staged
            try {
                if $failure != null {
                    error make $failure
                }
                for output in $staged {
                    mv --force $output.file $output.path
                }
            } finally {
                if ($staged | is-not-empty) {
                    rm -r ...($staged | get dir)
                }
            }
        } else {
            for output in $outputs {
                if not ($output.path | path exists) or (open --raw $output.path) != $output.content {
                    fail $"Generated file '($output.path)' is missing or stale; rerun md:gen with --fix" $output.path
                }
            }
        }
    } finally {
        rm -r $scratch
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
