# Guidelines for `serde`

## Reqs

- Every input data type must derive `Serialize`, `Deserialize`.
- Every `Option`-wrapped field must have attr:
  - `#[serde(skip_serializing_if = "Option::is_none")]`.
- Every `OffsetDateTime` field must have attr:
  - `#[serde(with = "time::serde::rfc3339")]`.
- Every `Option<OffsetDateTime>` field must have attr:
  - `#[serde(with = "time::serde::rfc3339::option")]`.

## Notes

- Prefer `serde_with` to reduce code size by avoiding custom `Serialize`/`Deserialize` impls.
