# API client

## Package requirements

- Must contain a `Cargo.toml` that meets the [Cargo.toml requirements](#cargotoml-requirements).
- Must contain [request cow types](#request-cow-type-requirements) for each request in the API.
- Must contain [response types](#response-type-requirements) for each response in the API.
- Must have the following layout:
  - Request data types in the `request` module.
  - Response data types in the `response` module.
  - Common data types in the `common` module.
  - [Technical types](#technical-type) at the top level (attached to `src/lib.rs`).

## Cargo.toml requirements

- Must have the following dependencies:
  - `reqwest`.
  - `governor`.
  - `secrecy`.
  - `errgonomic`.
  - `serde`.
- May have the following dependencies:
  - `strum`.
  - `url-macro`.
- Every version under the `dependencies` key must be specified only up to the first nonzero component (good: "1", "0.3"; bad: "1.0", "0.3.3").

## Key requirements

- Must be a type alias of `secrecy::SecretString`.

## RateLimits requirements

- Must be a struct.
- Every field must have a type exported from `governor`.
- Must have the following impls:
  - `Default`.

## HTTP Client requirements

- Must be a struct.
- Must have the following attributes:
  - `#[derive(From, Into, Eq, PartialEq, Clone, Debug)]`.
- Must have the following fields:
  - `pub inner: HttpClient` (`use reqwest::Client as HttpClient;`).
  - `pub base: Url`.
  - `pub limits: RateLimits`.
- Must have the following methods:
  - `pub fn new(key: impl Into<Key>) -> Result<Self, ClientNewError>`:
    - Must call `Self::try_from`.
- Must have the following impls:
  - `From<Client>`.
  - `TryFrom<Key>`:
    - Must set the bearer auth header via `default_headers`.

## Technical type

A type that meets one of the following sets of requirements:

- [Client requirements](#http-client-requirements).
- [Key requirements](#key-requirements).
- [RateLimits requirements](#ratelimits-requirements).

## API interface type requirements

- Must derive `Clone` and `Debug`.
- Should derive `Serialize`, `Deserialize`, `Eq`, `PartialEq`, and `Hash`.
- Should not contain manual `Serialize` and `Deserialize` impls.
- Should use type-level `serde` attributes (e.g., `rename_all`).

## Request cow type requirements

- Must meet the [API interface type requirements](#api-interface-type-requirements).
- The identifier must end with "Request".
- Every field must be a `Cow`.
- Every field must have its own lifetime.
  - The lifetime name should be short.
  - The lifetime name should match the field name (e.g., its first letter).

## Request ref type requirements

- Must meet the [API interface type requirements](#api-interface-type-requirements).
- The identifier must end with "RequestRef".
- Must derive `Copy`.
- Every field must be an immutable reference (not owned).

## Request own type requirements

- Must meet the [API interface type requirements](#api-interface-type-requirements).
- The identifier must end with "RequestOwn".
- Every field must be owned (not a reference).

## Response type requirements

- Must meet the [API interface type requirements](#api-interface-type-requirements).
- The identifier must end with "Response".
- Every field must be owned (not a reference).
