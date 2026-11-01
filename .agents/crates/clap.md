# Guidelines for `clap`

## Reqs

- For each enum in project:
  - If enum has only unit variants and doesn't implement `Error`, it must derive `ValueEnum` with `#[value(rename_all = "kebab-case")]`.
- For each field in a type that derives `Parser`:
  - If this field's type is local, this type must implement `FromStr`.
