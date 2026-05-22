# Guidelines for `serde`

* Every input data type must derive `Serialize` and `Deserialize`
* Every `Option`-wrapped field must have attributes:
  * `#[serde(skip_serializing_if = "Option::is_none")]`
* Every `OffsetDateTime` field must have attributes:
  * `#[serde(with = "time::serde::rfc3339")]`
* Every `Option<OffsetDateTime>` field must have attributes:
  * `#[serde(with = "time::serde::rfc3339::option")]`
* Every field that stores a physical value must be serialized as a map that includes at least two fields: `value` and `unit`
  * `value` must be a primitive type
  * `unit` must be a string that contains the unit name in singular form (for example: "nanosecond", "second", "minute", "kilogram", "meter")
    * `unit` may contain a prefix (for example: "nano", "kilo")
