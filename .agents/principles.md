# Principles

## Preservation

### Examples

- Preserve shape of underlying API in CLI (e.g.: cmds should accept same args as methods).
- Preserve secrecy of private data (e.g.: hide passwords, API keys, private keys).

### Exceptions

- If user explicitly requests breaking preservation, preservation may be broken.
  - Example:
    - If user explicitly requests data deletion, data may be deleted.
- If spec explicitly allows breaking preservation, preservation may be broken.
- Principle of preservation may be broken due to limitations of physical reality.
  - Examples:
    - Old data may be deleted to free space for new data (limitation of disk size).
      - Interactive program should ask user before deleting data.
      - Non-interactive program should either display error ("not enough disk space") instead of silently deleting data, or at least display log line.
    - List view may display only 20 items along with "Show more" button (limitation of screen size, limitation of network bandwidth).
    - Confirmation dialog for item deletion may have "Don't ask again" checkbox (limitation of available time).

Cases where principle of preservation is broken must be described in docs.

Principle of preservation may not be broken in order to minimize time spent writing code or to minimize amount of code (in other words: lossy simplifications are not allowed).

## Unique naming

- Use same name for same entity.
- Don't use same name for multiple different entities.

### Examples

- In Rust, "result" refers to `Result` type.
- For each custom type:
  - If it does not include `Result`, its name must not contain `Result`.
