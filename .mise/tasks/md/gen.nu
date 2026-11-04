#!/usr/bin/env -S nu --no-config-file

def main [
    generator: path
    path?: path
    --fix # Write generated files instead of checking freshness.
]: nothing -> nothing {
    let generator = $generator | path expand
    let scratch = (mktemp --directory)
    mut temporary_dirs = [$scratch]
    let failure = try {
        let result = (
            with-env {MD_GEN_TMP_DIR: $scratch} { ^$generator | complete }
        )
        if $result.exit_code != 0 {
            fail $"Generator '($generator)' exited with ($result.exit_code):\n($result.stderr)" $generator
        }
        let outputs: table<path: string, content: string> = $result.stdout | from json
        if $path != null and ($outputs | length) != 1 {
            fail "A destination override requires exactly one generated file" $path
        }
        let outputs = ($outputs | each {|output|
            let destination = $path | default $output.path | path expand
            if ($destination | path type) not-in [null "file"] {
                fail $"Destination '($destination)' must be a file" $destination
            }
            {path: $destination, content: $output.content}
        })
        if ($outputs | get path | uniq | length) != ($outputs | length) {
            fail $"Generator '($generator)' returned duplicate destinations" $generator
        }
        for output in $outputs {
            let lint = $output.content | ^mise run --quiet --output "interleave" "lint:docs" -- --stdin --stdin-filename $output.path | complete
            if $lint.exit_code != 0 {
                fail $"Generated Markdown for '($output.path)' failed linting:\n($lint.stdout)($lint.stderr)" $output.path
            }
        }
        if $fix {
            mut staged = []
            for output in $outputs {
                let dir = mktemp --directory --tmpdir-path ($output.path | path dirname) ".generated.XXXXXXXX"
                $temporary_dirs ++= [$dir]
                let file = $dir | path join "content"
                $output.content | save --raw $file
                ^chmod "644" $file
                $staged ++= [
                    {path: $output.path, file: $file}
                ]
            }
            for output in $staged {
                mv --force $output.file $output.path
            }
        } else {
            for output in $outputs {
                if not ($output.path | path exists) or (open --raw $output.path) != $output.content {
                    fail $"Generated file '($output.path)' is missing or stale; rerun md:gen with --fix" $output.path
                }
            }
        }
        null
    } catch {|err| $err }
    mut failures = [$failure] | compact
    for dir in $temporary_dirs {
        let failure = try {
            rm -r $dir
            null
        } catch {|err| $err }
        if $failure != null {
            $failures ++= [$failure]
        }
    }
    if ($failures | is-not-empty) {
        error make {
            msg: $"Generation failed for '($generator)'"
            label: {
                text: "Generator"
                span: (metadata $generator).span
            }
            inner: $failures
        }
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
