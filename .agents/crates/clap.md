# Guidelines for `clap`

## Requirements

- For each enum in project:
  - If enum has only unit variants and doesn't implement `Error`
    - Then: it must derive `ValueEnum` with `#[value(rename_all = "kebab-case")]`
