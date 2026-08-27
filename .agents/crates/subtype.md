# Guidelines for `subtype`

- Define newtypes as ordinary structs with explicit `From` / `TryFrom` impls.
- The macro calls that begin with `subtype` (for example, `subtype!` and `subtype_string!`) are legacy APIs that expand to newtypes.
  - Don't use them in new code because their checker and preprocessor concepts have been superseded by explicit conversion impls.
- Use the `SerializeTransparent` derive for a refined newtype that must serialize identically to its inner field while using Serde's `try_from` container attribute for validated deserialization.
