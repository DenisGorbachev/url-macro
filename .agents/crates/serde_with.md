# Guidelines for `serde_with`

## Reqs

- If `#[serde_as]` is necessary, use it; else: use targeted annotations (e.g.: `#[serde(with = "As::<DisplayFromStr>")]`).
