# Guidelines

## General

* Read `Cargo.toml` before executing any tasks
* Don't create git commits

## Commands

Always use `mise run ...` commands to run the tests / lints.

* Run tests: `mise run test` (use this instead of `cargo test`)
* Run specific test: `mise run test <test_file_path>` (use this instead of `cargo test`)
* Format code: `mise run fmt` (use this instead of `cargo fmt`)
* Lint code: `mise run lint` (use this instead of `cargo clippy`)
* Check types: `mise run check` (use this instead of `cargo check`)

Always execute `mise run fmt` after completing your task.
