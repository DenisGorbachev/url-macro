# API client

## Package requirements

- Must contain `Cargo.toml` that meets [Cargo.toml requirements](#cargotoml-requirements).
- For each request in API:
  - Must contain [request cow type](#request-cow-type-requirements).
- For each response in API:
  - Must contain [response type](#response-type-requirements).
- Must have layout:
  - Request data types in `request` module.
  - Response data types in `response` module.
  - Common data types in `common` module.
  - [Technical types](#technical-type) at top level (attached to `src/lib.rs`).

## Cargo.toml requirements

- Must have dependencies:
  - `reqwest`.
  - `governor`.
  - `secrecy`.
  - `errgonomic`.
  - `serde`.
- May have dependencies:
  - `strum`.
  - `url-macro`.
- Every version under `dependencies` key must be specified only up to first nonzero component (good: "1", "0.3"; bad: "1.0", "0.3.3").

## Key requirements

- Must be type alias of `secrecy::SecretString`.

## RateLimits requirements

- Must be struct.
- Every field must have type exported from `governor`.
- Must have impls:
  - `Default`.

## HTTP Client requirements

- Must be struct.
- Must have attributes:
  - `#[derive(From, Into, Eq, PartialEq, Clone, Debug)]`.
- Must have fields:
  - `pub inner: HttpClient` (`use reqwest::Client as HttpClient;`).
  - `pub base: Url`.
  - `pub limits: RateLimits`.
- Must have methods:
  - `pub fn new(key: impl Into<Key>) -> Result<Self, ClientNewError>`:
    - Must call `Self::try_from`.
- Must have impls:
  - `From<Client>`.
  - `TryFrom<Key>`:
    - Must set bearer auth header via `default_headers`.

## Technical type

Type that meets one of:

- [Client requirements](#http-client-requirements).
- [Key requirements](#key-requirements).
- [RateLimits requirements](#ratelimits-requirements).

## API interface type requirements

- Must derive `Clone`, `Debug`.
- Should derive `Serialize`, `Deserialize`, `Eq`, `PartialEq`, `Hash`.
- Should not contain manual `Serialize` and `Deserialize` impls.
- Should use type-level `serde` attributes (e.g.: `rename_all`).

## Request cow type requirements

- Must meet [API interface type requirements](#api-interface-type-requirements).
- Ident must end with "Request".
- Every field must be `Cow`.
- Every field must have its own lifetime.
  - Lifetime name should be short.
  - Lifetime name should match field name (e.g.: its first letter).

## Request ref type requirements

- Must meet [API interface type requirements](#api-interface-type-requirements).
- Ident must end with "RequestRef".
- Must derive `Copy`.
- Every field must be immutable reference (not owned).

## Request own type requirements

- Must meet [API interface type requirements](#api-interface-type-requirements).
- Ident must end with "RequestOwn".
- Every field must be owned (not reference).

## Response type requirements

- Must meet [API interface type requirements](#api-interface-type-requirements).
- Ident must end with "Response".
- Every field must be owned (not reference).
