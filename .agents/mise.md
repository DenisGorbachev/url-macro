# Guidelines for `mise`

## mise.toml

- If project contains at least one `Cargo.toml` file that contains `trybuild` in `dependencies` or `dev-dependencies`, `tools.rust.components` must contain `rust-src`.
  - Rationale: `rust-src` is needed to stabilize tests (`trybuild` relies on output from `rustc`, which depends on whether `rust-src` is installed).
