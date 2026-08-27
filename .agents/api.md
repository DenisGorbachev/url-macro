# API client

## Package requirements

- Must contain a `Cargo.toml` that passes [Cargo.toml requirements](#cargotoml-requirements)
- Must contain [request cow types](#request-cow-type-requirements) for each request in the API
- Must contain [response types](#response-type-requirements) for each response in the API
- Must have the following layout:
  - Request data types in `request` module
  - Response data types in `response` module
  - Common data types in `common` module
  - [Technical types](#technical-type) at the top level (attached to src/lib.rs)

## Cargo.toml requirements

- Must have dependencies:
  - `reqwest`
  - `governor`
  - `secrecy`
  - `errgonomic`
  - `serde`
- May have dependencies:
  - `strum`
  - `url-macro`
- Every version under `dependencies` key must be specified only up to the first non-zero part (good: "1", "0.3", bad: "1.0", "0.3.3")

## Key requirements

- Must be a type alias of `secrecy::SecretString`.

## RateLimits requirements

- Must be a struct
- Every field must have a type exported from `governor`
- Must have impls:
  - `Default`

## HTTP Client requirements

- Must be a struct
- Must have attributes:
  - `#[derive(From, Into, Eq, PartialEq, Clone, Debug)]`
- Must have fields:
  - `pub inner: HttpClient` (`use reqwest::Client as HttpClient;`)
  - `pub base: Url`
  - `pub limits: RateLimits`
- Must have methods:
  - `pub fn new(key: impl Into<Key>) -> Result<Self, ClientNewError>`
    - Must call `Self::try_from`
- Must have impls:
  - `From<Client>`
  - `TryFrom<Key>`
    - Must set the bearer auth header via `default_headers`

## Technical type

A type that passes one of the following requirements:

- [Client requirements](#http-client-requirements)
- [Key requirements](#key-requirements)
- [RateLimits requirements](#ratelimits-requirements)

## API interface type requirements

- Must have derives: `Clone`, `Debug`.
- Should have derives: `Serialize`, `Deserialize`, `Eq`, `PartialEq`, `Hash`.
- Should not contain manual `Serialize` and `Deserialize` impls
- Should use type-level `serde` attributes (e.g. `rename_all`)

## Request cow type requirements

- Must pass [API interface type](#api-interface-type-requirements)
- Ident must end with "Request".
- Every field must be a `Cow`.
- Every field must have its own lifetime.
  - Lifetime name should be short
  - Lifetime name should match the name of the field (e.g. first letter)

## Request ref type requirements

- Must pass [API interface type](#api-interface-type-requirements)
- Ident must end with "RequestRef".
- Must have derives: `Copy`.
- Every field must be an immutable reference (not owned).

## Request own type requirements

- Must pass [API interface type](#api-interface-type-requirements)
- Ident must end with "RequestOwn".
- Every field must be owned (not a reference).

## Response type requirements

- Must pass [API interface type](#api-interface-type-requirements)
- Ident must end with "Response".
- Every field must be owned (not a reference).
