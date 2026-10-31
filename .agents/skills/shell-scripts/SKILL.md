---
name: shell-scripts
description: Use when editing or reviewing files that contain shell code. Does not apply to commands used in tool calls.
---

# Shell scripts

- Target Bash and Zsh.
- Choose best command for job without checking whether it is installed; user will install it.
- Do not hard-wrap lines to enforce maximum length; reader uses soft wraps.
- Prefer short options for `set`, `cd`, `cp`, `mv`, `rm`, `mkdir`, `ls`, `ln`, `chmod`, `chown`; prefer long options for other commands.
- Prefer `echo` over `printf`.
- Use bundled [log.sh](log.sh) for logging.
