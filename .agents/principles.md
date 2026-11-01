# Principles

## Preservation

### Examples

- Preserve secrecy of private data using secret types (e.g.: `secrecy::SecretString` for API keys).
- Preserve shape of underlying API in CLI (e.g.: cmds should accept same args as methods).

### Exceptions

- Principle of preservation may be broken due to limitations of physical reality.
  - Examples:
    - Old data may be deleted to free space for new data (limitation of disk size).
      - An interactive program should ask user before deleting data.
      - A non-interactive program should either display an error ("not enough disk space") instead of silently deleting data, or at least display a log line.
    - List view may display only 20 items along with a "Show more" button (limitation of screen size, limitation of network bandwidth).
    - Confirmation dialog for item deletion may have a "Don't ask again" checkbox (limitation of available time).

Cases where principle of preservation is broken must be described in docs.

Principle of preservation may not be broken in order to minimize time spent writing code or to minimize amount of code (in other words: lossy simplifications are not allowed).

## Unique naming

- Use same name for same entity.
- Don't use same name for multiple different entities.

### Examples

- In Rust, "result" refers to a `Result` type.
- For each custom type:
  - If it does not include a `Result`, its name must not contain `Result`.
