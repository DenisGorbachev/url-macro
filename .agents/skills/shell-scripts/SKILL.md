---
name: shell-scripts
description: Use when editing or reviewing files that contain shell code. Does not apply to commands used in tool calls.
---

# Shell scripts

- Target Bash and Zsh.
- Choose the best command for the job without checking whether it is installed; the user will install it.
- Do not hard-wrap lines to enforce a maximum length; the reader uses soft wraps.
- Prefer short options for `set`, `cd`, `cp`, `mv`, `rm`, `mkdir`, `ls`, `ln`, `chmod`, and `chown`; prefer long options for other commands.
- Prefer `echo` over `printf`.
- Use the bundled [log.sh](log.sh) for logging.
