# Guidelines for `serde`

## Requirements

- Every input data type must derive `Serialize` and `Deserialize`
- Every `Option`-wrapped field must have attributes:
  - `#[serde(skip_serializing_if = "Option::is_none")]`
- Every `OffsetDateTime` field must have attributes:
  - `#[serde(with = "time::serde::rfc3339")]`
- Every `Option<OffsetDateTime>` field must have attributes:
  - `#[serde(with = "time::serde::rfc3339::option")]`

## Notes

- It is recommended to use `serde_with` to reduce the code size by avoiding custom `Serialize`/`Deserialize` impls
