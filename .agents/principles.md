# Principles

## Preservation

### Examples

- Preserve the shape of the underlying API in the CLI (e.g.: commands should accept the same arguments as methods).
- Preserve the secrecy of private data (e.g.: hide passwords, API keys, private keys).

### Exceptions

- If the user explicitly requests breaking preservation:
  - Then: preservation may be broken.
  - Example:
    - If the user explicitly requests data deletion:
      - Then: data may be deleted.
- If the specification explicitly allows breaking preservation:
  - Then: preservation may be broken.
- The principle of preservation may be broken due to limitations of physical reality.
  - Examples:
    - The old data may be deleted to free space for new data (limitation of disk size).
      - An interactive program should ask the user before deleting the data.
      - A non-interactive program should either display an error ("not enough disk space") instead of silently deleting the data, or at least display a log line.
    - The list view may display only 20 items along with a "Show more" button (limitation of screen size, limitation of network bandwidth).
    - The confirmation dialog for item deletion may have a "Don't ask again" checkbox (limitation of available time).

The cases where the principle of preservation is broken must be described in the documentation.

The principle of preservation may not be broken in order to minimize the time spent writing code or to minimize the amount of code (in other words: lossy simplifications are not allowed).

## Unique naming

- Use the same name for the same entity.
- Don't use the same name for multiple different entities.

### Examples

- In Rust, "result" refers to a `Result` type.
- For each custom type:
  - If it does not include a `Result`:
    - Then: its name must not contain `Result`.
