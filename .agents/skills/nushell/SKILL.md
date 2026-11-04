---
name: nushell
description: Use when reading or writing Nushell scripts.
---

# Nushell

## Strings

- Must be quoted.

## Command invocations

- Must use long options for all commands except `cd`, `cp`, `mv`, `rm`, `mkdir`, `ls`, `ln`, `chmod`, `chown`.

## Scripts

- Must have shebang: `#!/usr/bin/env -S nu --no-config-file`
