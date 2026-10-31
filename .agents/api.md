# API client

## Pkg reqs

- Must contain a `Cargo.toml` that meets [Cargo.toml reqs](#cargotoml-reqs).
- For each request in API:
  - Must contain a [request cow type](#request-cow-type-reqs).
- For each response in API:
  - Must contain a [response type](#response-type-reqs).
- Must have layout:
  - Request data types in `request` module.
  - Response data types in `response` module.
  - Common data types in `common` module.
  - [Technical types](#technical-type) at top level (attached to `src/lib.rs`).

## Cargo.toml reqs

- Must have deps:
  - `reqwest`.
  - `governor`.
  - `secrecy`.
  - `errgonomic`.
  - `serde`.
- May have deps:
  - `strum`.
  - `url-macro`.
- Every version under `dependencies` key must be specified only up to first nonzero component (good: "1", "0.3"; bad: "1.0", "0.3.3").

## Key reqs

- Must be a type alias of `secrecy::SecretString`.

## RateLimits reqs

- Must be a struct.
- Every field must have a type exported from `governor`.
- Must have impls:
  - `Default`.

## HTTP Client reqs

- Must be a struct.
- Must have attrs:
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

A type that meets one of:

- [Client reqs](#http-client-reqs).
- [Key reqs](#key-reqs).
- [RateLimits reqs](#ratelimits-reqs).

## API interface type reqs

- Must derive `Clone`, `Debug`.
- Should derive `Serialize`, `Deserialize`, `Eq`, `PartialEq`, `Hash`.
- Should not contain manual `Serialize` and `Deserialize` impls.
- Should use type-level `serde` attrs (e.g.: `rename_all`).

## Request cow type reqs

- Must meet [API interface type reqs](#api-interface-type-reqs).
- Ident must end with "Request".
- Every field must be a `Cow`.
- Every field must have its own lifetime.
  - Lifetime name should be short.
  - Lifetime name should match field name (e.g.: its first letter).

## Request ref type reqs

- Must meet [API interface type reqs](#api-interface-type-reqs).
- Ident must end with "RequestRef".
- Must derive `Copy`.
- Every field must be an immutable ref.

## Request own type reqs

- Must meet [API interface type reqs](#api-interface-type-reqs).
- Ident must end with "RequestOwn".
- Every field must be owned.

## Response type reqs

- Must meet [API interface type reqs](#api-interface-type-reqs).
- Ident must end with "Response".
- Every field must be owned.
