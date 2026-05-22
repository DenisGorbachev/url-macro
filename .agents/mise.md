# Guidelines for `mise`

## mise.toml

* If the project contains at least one Cargo.toml file that contains `trybuild` in `dependencies` or `dev-dependencies`: then `tools.rust.components` must contain `rust-src`
  * Rationale: `rust-src` is needed to stabilize the tests (`trybuild` relies on the output from `rustc` which depends on whether `rust-src` is installed)  
