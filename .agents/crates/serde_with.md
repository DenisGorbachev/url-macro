# Guidelines for `serde`

## Requirements

- If `#[serde_as]` is necessary:
  - Then: use it
  - Else: use targeted annotations (e.g. `#[serde(with = "As::<DisplayFromStr>")]`)
