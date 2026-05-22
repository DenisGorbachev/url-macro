# Principles

## Preservation

### Examples

* Preserve the shape of the underlying API in the CLI (e.g. commands should accept the same arguments as methods).
* Preserve the secrecy of private data (e.g. hide passwords, API keys, private keys).

### Exceptions

* The principle of preservation may be broken if the user explicitly requests it.
  * The data may be deleted if the user explicitly requests the deletion.
* The principle of preservation may be broken if the specification explicitly allows it.
* The principle of preservation may be broken due to limitations of physical reality.
  * Examples:
    * The old data may be deleted to free the space for the new data (limitation of disk size).
      * An interactive program should ask the user before deleting the data.
      * A non-interactive program should either display an error ("not enough disk space") instead of silently deleting the data, or at least display a log line.
    * The list view may display only 20 items along with "Show more" button (limitation of screen size, limitation of network bandwidth).
    * The confirmation dialog for item deletion may have a "Don't ask again" checkbox (limitation of available time).

The cases where the principle of preservation is broken must be described in the documentation.

The principle of preservation may not be broken in order to minimize the time spent on writing the code or to minimize the amount of code (in other words: lossy simplifications are not allowed).

## Unique naming

* Use the same name for the same entity.
* Don't use the same name for multiple different entities.

### Examples

* In Rust, the name "result" is associated with a `Result` type, so if a custom type does not include a `Result`, it must not have `Result` in its name.
