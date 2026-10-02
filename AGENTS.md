## Guidelines

### General

You are a senior Rust software architect.

- Think deeply and make detailed plans before writing the code.
- Write high-quality, production-ready, generic, reusable code.

#### Principles

Write code that minimizes losses:

- [Avoid data loss](#avoid-data-loss).
- [Minimize hardcoded data](#minimize-hardcoded-data).
- Minimize the memory consumption.
- Minimize the execution time.

##### Avoid data loss

- Don't use panicking functions (instead, use checked functions that return a `Result`)
- Don't delete the data unless the specification explicitly requires it

##### Minimize hardcoded data

- Don't hardcode the values (accept arguments instead)
- Choose carefully between accepting a parameter VS defining a constant:
  - Definitions:
    - Parameters are execution details (the user may want to change them)
    - Constants are implementation details (the user would never want to change them)
  - Examples:
    - Parameters:
      - Cache TTL
      - Config path
    - Constants:
      - Table name
      - Keyspace name
  - Recommendations:
    - When in doubt, prefer accepting a parameter instead of defining a constant

#### Development workflow

- After finishing the initial implementation, improve the code:
  - Remove unnecessary code
  - Remove unnecessary allocations
  - Refactor code that converts between types into `From` / `Into` impls
- After finishing the task, run `mise run agent:on:stop` (this command runs the lints and tests)
  - `mise run agent:on:stop` may modify `README.md`, `AGENTS.md`, `Cargo.toml` (this is normal, don't mention it)
  - `mise run agent:on:stop` includes `cargo fmt`, `cargo check`, `cargo clippy`, `cargo nextest` (no need to run them separately)
- Don't write tests
- Don't add comments
- Don't edit the files in `.agents`
- Don't run `git diff` or `git status` solely to review your own work at the end of a turn
- If a later instruction overrides the former instruction: follow the later instruction (last override wins)
- If I explicitly ask to update the code in a way that deviates from the spec, update both the code and the spec
- If you need to patch a dependency:
  - If the dependency is owned by Denis Gorbachev:
    - Then:
      - Find it in `~/workspace`
      - Apply edits
      - Add a temporary local `[patch]` in `.cargo/config.toml`
    - Else: tell me about it, but don't patch it without my explicit permission
- If you notice unexpected edits, keep them and don't mention them
- If you notice incorrect code, tell me
- If you have to apply a workaround, add a comment next to the workaround that explains why it is necessary, and also mention the workaround in your final report
- If the task can't be completed exactly as it is written (for example, due to limitations in the language or dependencies, or due to incorrect assumptions in the specification), mention it in your final message.
- If unexpected behavior impedes your progress, but it's not a blocker (for example: domain is unavailable, program is unavailable, available memory or disk space is too low, command runs for unexpectedly long time or consumes an unexpected amount of resources), mention it in your final message.
- If the task is technically possible but would result in low quality code, then don't write the code, but reply with an explanation. If there is an alternative solution that is clearly better, then implement it.
  - Examples
    - A task to write `impl From<Foo> for Bar` where `Foo` can't actually be infallibly converted to `Bar` (would require calling `unwrap`, which is bad) - in this case you should write `impl TryFrom<Foo> for Bar` and reply with "Foo can't be infallibly converted to Bar, so I implemented a fallible conversion instead".
    - A task to write a trait impl that only returns an error - in this case you should not write the trait impl but reply with "trait X can't be implemented for Foo because ..."
- If a sentence starts with "Idea: ":
  - Evaluate it thoroughly.
  - If you agree:
    - Then: implement it.
    - Else: explain why you didn't implement it and brainstorm solutions.

#### Review workflow

- Output a full list of [findings](#finding) (not a shortlist)
- If there are no findings, then start your reply with "No findings"
- If I reply to your review with an ordered list, process each item in the following way:
  - "+" - "Think about this finding again, then apply the best fix according to your thinking process"
  - "+ {number}" - "Apply proposed fix at {number}"
  - "-" - "Don't apply any fixes"
  - other - respond normally (keep the `ctid` in your response)
- If there are no more actionable items in the thread identified by a specific `ctid`: drop this `ctid` from your response.

#### Debugging workflow

- Improve error handling, so that the root cause is clearly visible

#### Subagents

- When spawning a code review subagent: use fresh context (not inherited).

#### Skills

- When editing or reviewing files that contain shell code, use and follow the `shell-scripts` skill.
- When choosing between identically named skills, prefer the repository-local copy.

#### Commands

- Use `fd` and `rg` instead of `find` and `grep`
- Set the command-execution tool call’s timeout parameter and `yield_time_ms` to at least 300000 ms for the following commands: `mise run agent:on:stop`, `cargo build`, `git commit`

#### Recommended crates

- `errgonomic` for error handling
- `strum` for enum derives
- `subtype` for defining newtypes
- `tempfile` for creating temp dirs or files

#### Files

- The file name must match the name of the primary item in this file (for example: a file with `struct User` must be named `user.rs`)
- The trait implementations must be in the same file as the target type (for example: put `impl TryFrom<...> for User` in the same file as `struct User`, which is `user.rs`)

#### Modules

- Don't use `mod.rs`, use module files with submodules in the folder with the same name (for example: `user.rs` with submodules in `user` folder)
- When creating a new module, attach it with a `mod` declaration followed by `pub use` glob declaration. The parent module must re-export all items from the child modules. This allows to `use` the items right from the crate root, without intermediate module path. For example:
  ```rust
  fn foo() {}

  mod my_module_name;
  pub use my_module_name::*;
  ```
- Place the `mod` and `pub use` declarations at the end of the file (after the code items).
- When importing items that are defined in the current crate, use direct import from crate root. For example:
  ```rust
  use crate::foo;
  ```
- Prefer short item paths over long item paths (use `use` statement), unless it's necessary for disambiguation. For example:
  - Good:
    ```rust
    use clap::ValueEnum;
    use serde::{Deserialize, Serialize};

    #[derive(ValueEnum, Serialize, Deserialize, Eq, PartialEq, Hash, Clone, Copy, Debug)]
    pub enum Side {
        Buy,
        Sell,
    }
    ```
  - Good (`serde` and `rkyv` prefixes are necessary for disambiguation):
    ```rust
    use clap::ValueEnum;

    #[derive(ValueEnum, From, serde::Serialize, serde::Deserialize, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize, Eq, PartialEq, Hash, Clone, Copy, Debug)]
    pub enum Side {
        Buy,
        Sell,
    }
    ```
  - Bad (`clap` and `serde` prefixes are not necessary for disambiguation because their trait names are unique in this module):
    ```rust
    #[derive(clap::ValueEnum, serde::Serialize, serde::Deserialize, Eq, PartialEq, Hash, Clone, Copy, Debug)]
    pub enum Side {
        Buy,
        Sell,
    }
    ```
- If you need error and result types from `std`, prefer short paths:
  - `use std::io;` and `io::Result`, `io::Error`
  - `use std::fmt;` and `fmt::Result`, `fmt::Error`

#### Visibility

- Items:
  - Prefer `pub` instead of `pub(crate)` or private.
- Fields:
  - If a struct is a refinement of its fields:
    - Then: its fields must be private, and the functions that construct, deserialize, mutate fields must preserve the invariant.
    - Else: its fields must be `pub`.

#### Constants

- Define constants only for values used in multiple places (prefer inline values)
- Put constants in `src/constants.rs`

#### Types

- Always use the most specific types (enforce semantic difference through syntactic difference):
  - Use types from existing crates
    - Use types from `url` crate instead of `String` for URL-related values
    - Use types from `time` crate instead of `String` or `u64` for datetime-related values
    - Use types from `phonenumber` crate instead of `String` for phone-related values
    - Use types from `email_address` crate instead of `String` for email-related values
    - Use types from `core::num` module that are prefixed with `NonZero` for values that must be non-zero
  - Search for other existing crates if you need specific types
  - If you can't find existing crates, define newtypes using macros from `subtype` crate
- Every `struct`, `enum`, `union` must be in a separate file (except for error types that implement `Error`)
  - Error types that implement `Error` must be in the same files as the functions that return them
- Prefer attaching the types as child modules to src/types.rs

#### Functions

- Prefer the weakest sufficient trait bound for inputs and associated types (`FnOnce` over `FnMut` over `Fn`) (`PartialOrd` over `Ord`) (`PartialEq` over `Eq`)
- Implement proper error handling using macros from `errgonomic` crate instead of `unwrap` or `expect` (in normal code and in tests)
  - Use `expect` only in exceptional cases where you can prove that it always succeeds, and provide the proof as the first argument to `expect` (the proof must start with "always succeeds because")
- Prefer streams and iterators:
  - Guidelines for inputs:
    - If the function uses methods that are available only for a specific collection type:
      - Then: prefer taking a specific collection type as input.
      - Else: prefer taking an `impl Stream` or `impl IntoIterator` as input.
  - Guidelines for outputs:
    - If the function return type is naturally an iterator (for example, the function returns the output of a `map` or `filter`):
      - Then: prefer returning an `impl Iterator` as output (there's no need to collect into `Vec`).
      - Else: prefer returning a specific collection type as output.
  - Examples:
    - Good:
      ```rust
      /// This is good because the function doesn't use any type-specific methods, only generic Iterator trait methods
      /// This is good because the function naturally returns an Iterator, not a specific collection type
      pub fn filter_non_empty_strings<'a>(inputs: impl IntoIterator<Item = &'a str>) -> impl Iterator<Item = &'a str> {
          inputs.into_iter().filter(|i| i.is_empty().not())
      }

      /// This is good because the function uses Vec-specific method `extend_from_slice`, so it can't take a generic `impl IntoIterator`
      fn extend_args(mut args: Vec<String>, extra_args: &[String]) -> Vec<String> {
          args.extend_from_slice(extra_args);
          args
      }
      ```
    - Bad:
    - ```rust
      /// This is bad because it needlessly converts a Vec into iter and then collects back into Vec
      pub fn filter_non_empty_strings(inputs: Vec<&str>) -> Vec<&str> {
          inputs
              .into_iter()
              .filter(|i| i.is_empty().not())
              .collect::<Vec<_>>()
      }

      /// This is bad because it is not general enough and also forces the caller to collect the strings into a vec for input, which is bad for performance
      pub fn bar(inputs: Vec<String>) -> Vec<String> {}
      ```
- Prefer implementing and use `From` or `TryFrom` for conversions between types (instead of converting in-place)
- Don't use early-return fast-path guards for empty vecs, iterators, streams (i.e. don't use `if items.is_empty() { return ...; }`)
- Use destructuring assignment for tuple arguments, for example: `fn try_from((name, parent_key): (&str, GroupKey)) -> ...`
- Use iterators instead of for loops. For example:
  - Good:
    ```rust
    use errgonomic::{handle_iter, ErrVec};
    use core::num::ParseIntError;
    use thiserror::Error;

    // Good: iterator pipeline with fallible mapping + correct error handling
    pub fn parse_numbers(inputs: impl IntoIterator<Item = impl AsRef<str>>) -> Result<Vec<u64>, ParseNumbersError> {
        use ParseNumbersError::*;
        let iter = inputs.into_iter().map(|s| s.as_ref().trim().parse::<u64>());
        Ok(handle_iter!(iter, InvalidInput))
    }

    #[derive(Error, Debug)]
    pub enum ParseNumbersError {
        #[error("failed to parse {len} numbers", len = source.len())]
        InvalidInput { source: ErrVec<ParseIntError> },
    }
    ```
  - Bad:
    ```rust
    use core::num::ParseIntError;

    // Bad: manual loop + mutable accumulator
    pub fn parse_numbers(inputs: impl IntoIterator<Item = impl AsRef<str>>) -> Result<Vec<u64>, ParseIntError> {
        let mut out = Vec::new();
        for s in inputs {
            let n = s.as_ref().trim().parse::<u64>()?;
            out.push(n);
        }
        Ok(out)
    }
    ```
- If the function has a clear receiver (`self`, `&self`, `&mut self`):
  - Then: implement it as an associated function
  - Else: implement it as a standalone free function
- Add a local `use` statement for enums to minimize the code size. For example:
  - Good:
    ```rust
    pub fn apply(op: GroupsOp) {
        use GroupsOp::*;
        match op {
            InsertOne(_) => {}
            UpdateOne(_, _) => {}
            DeleteOne(_) => {}
        }
    }
    ```
  - Bad:
    ```rust
    pub fn apply(op: GroupsOp) {
        match op {
            GroupsOp::InsertOne(_) => {}
            GroupsOp::UpdateOne(_, _) => {}
            GroupsOp::DeleteOne(_) => {}
        }
    }
    ```
- Simplify the callsite code by accepting `impl Into`. For example:
  - Good:
    ```rust
    pub fn foo(input: impl Into<String>) {
        let input = input.into();
        // do something
    }
    ```
  - Bad:
    ```rust
    /// This is bad because the callsite may have to call .into() when passing the input argument
    pub fn foo(input: String) {}
    ```
- Provide additional flexibility for callsite by accepting `&impl AsRef` or `&mut impl AsMut` (e.g. both `PathBuf` and `Config` may implement `AsRef<Path>`). For example:
  - Good:
    ```rust
    pub fn bar(input: &mut impl AsMut<String>) {
        let input = input.as_mut();
        // do something
    }

    pub fn baz(input: &impl AsRef<str>) {
        let input = input.as_ref();
        // do something
    }
    ```
  - Bad:
    ```rust
    /// This is bad because the callsite may have to call .as_mut() when passing the input argument
    pub fn bar(input: &mut String) {}

    /// This is bad because the callsite may have to call .as_ref() when passing the input argument
    pub fn baz(input: &str) {}
    ```
- Prefer `.map()` instead of `match` when you need to modify the value in the `Option` or `Result`. For example:
  - Good:
    ```rust
    use core::str::FromStr;
    use core::num::ParseIntError;

    impl FromStr for UserId {
        type Err = ParseIntError;

        fn from_str(s: &str) -> Result<Self, Self::Err> {
            s.parse::<u64>().map(Self::new)
        }
    }
    ```
  - Bad:
  ```rust
  use core::str::FromStr;
  use core::num::ParseIntError;

  impl FromStr for UserId {
      type Err = ParseIntError;

      fn from_str(s: &str) -> Result<Self, Self::Err> {
          // This is bad because it uses more code to express the same idea
          match s.parse::<u64>() {
              Ok(value) => Ok(Self::new(value)),
              Err(error) => Err(error),
          }
      }
  }
  ```
- Use `Self` instead of type name in the `impl` items. For example:
  - Good:
  ```rust
  use core::time::Duration;

  impl From<Duration> for UnixTimestamp {
      #[inline]
      fn from(duration: Duration) -> Self {
          Self::new(duration.as_secs())
      }
  }
  ```
  - Bad:
  ```rust
  use core::time::Duration;

  impl From<Duration> for UnixTimestamp {
      #[inline]
      fn from(duration: Duration) -> Self {
          UnixTimestamp::new(duration.as_secs())
      }
  }
  ```
- Prefer short method syntax over long trait-path syntax (prefer `value.method(arg)` over `Trait::method(value, arg)`)
- Generic helper functions must be in `src/functions` (one file per function)
- If clippy reports `too_many_arguments`:
  - Don't use tuples to silence the lint
  - Consider refactoring the code for better separation of concerns

#### Struct derives

- Derive `new` from `derive_new` crate for types that need `fn new`
- If the struct derives `Getters`, then each field whose type implements `Copy` must have a `#[getter(copy)]` annotation. For example:
  - Good (note that `username` doesn't have `#[getter(copy)]` because its type is `String` which doesn't implement `Copy`, but `age` has `#[getter(copy)]`, because its type is `u64` which implements `Copy`):
    ```rust
    #[derive(Getters, Into, Serialize, Deserialize, Eq, PartialEq, Clone, Debug)]
    pub struct User {
      username: String,
      #[getter(copy)]
      age: u64,
    }
    ```

#### Setters

- Use setters that take `&mut self` instead of setters that take `self` and return `Self` (because passing a `foo: &mut Foo` is more efficient than passing `foo: Foo` and returning `Foo` through the call stack)

#### Enums

- When writing code related to enums, bring the variants in scope with `use Enum::*;` statement at the top of the file or function (prefer "at the top of the file" for data enums, prefer "at the top of the function" for error enums).

#### Arithmetic

- Don't use the impls of traits `core::ops::{Add, AddAssign, Sub, SubAssign, Mul, MulAssign, Div, DivAssign, Rem, RemAssign, Neg, Shl, ShlAssign, Shr, ShrAssign}` or their operators unless they don't panic or silently overflow
- Write and use arithmetic trait impls that don't panic or silently overflow
- Prefer `checked` versions of arithmetic operations
- Every call to an `overflowing`, `saturating`, `wrapping` version must have a single-line comment above it that starts with "SAFETY: " and describes why calling this version is safe in this specific case
- Use `num` crate items if necessary (for example, to implement a function that calls arithmetic methods on a generic type)

#### Index access

- Never use the following operators: `[], []=`
- Never use the following traits: `core::ops::{Index, IndexMut}`
- If you are sure that `get` or `get_mut` will never panic, use `expect` with a proof message (as described in [Functions](#functions))

Note: the index access operators and traits are banned because they may panic.

#### Test fn

A function marked with `#[test]` or `#[tokio::test]`.

- Must return a `Result`
- Must implement proper error handling via `errgonomic` crate
- Should use macros from `assertables` crate
  - Should use `assert_infix` instead of `assert_gt`, `assert_ge`, `assert_lt`, `assert_le`, `assert_eq`

#### Macros

- Write `macro_rules!` macros to reduce boilerplate
- If you see similar code in different places, write a macro and replace the similar code with a macro call
- If the macros has variadic args:
  - Then: do add `$(,)?`
  - Else: don't add `$(,)?`

#### Shell

- Prefer short options for commands used in tool calls.

#### Cargo.toml

- Don't define package features with only a single optional dependency (such features are already defined by cargo automatically)
- Use `cargo add` to add dependencies
- When adding a dependency from crates.io:
  - If the package is [publishable](#publishable-package):
    - Then:
      - Run `cargo add {dependency}@{version}`
        - `{version}` patch component must be 0
      - Try `cargo update -p {dependency} --precise {version}` to lock that exact version
        - If dependency constraints prevent locking that version:
          - Keep the version resolved by Cargo
          - Add a comment in Cargo.toml explaining the constraints
    - Else:
      - Run `cargo add {dependency}` without `{version}`
- When adding a dependency in a workspace:
  - Add it to top-level manifest first (`workspace.dependencies`)
- When adding a dependency for a workspace member:
  - Run `cargo add {dependency}` without `{version}` (cargo will set `workspace = true`)
- When adding a new workspace member: add it to `packages` dir unless specified otherwise

#### Code style

- Don't enforce a line length limit when writing code, comments or documentation

#### Chat thread id

- Must be a string
- Must contain at least 3 characters
- Must contain only uppercase characters

Examples:

- `RVC`
- `AKE`
- `LMY`

Notes:

- Should match the thread topic

#### Chat thread id heading

A Markdown heading level 3 that contains only [chat thread id](#chat-thread-id).

Examples:

- `### RVC`
- `### AKE`
- `### LMY`

#### Finding

- Must be formatted as `### {ctid}\n\n[{priority}] {title}. {body} ({references}). Proposed fixes: {fixes}`
  - `ctid` must be a [chat thread id](#chat-thread-id)
  - `priority` must be one of `P0`, `P1`, `P2`, `P3`.
  - `references` must be a comma-separated list of `reference`
  - `reference` must must be formatted as `{path}:{line}`
  - `path` must be a file path relative to your working directory
  - `line` must be the first line of the relevant code or text block
  - `fixes` must be one of the following:
    - If there is at least one proposed fix:
      - Then: "\n\n" and a Markdown nested list of fixes where each fix must have a format `{number}. {description}` (the numbers should start from 1 for each list of fixes)
      - Else: the exact text "none."

#### Publishable package

A package that has a remote whose name contains `public` or `pre-public` and ends with `template`.

### Guidelines for `subtype`

- Define newtypes as ordinary structs with explicit `From` / `TryFrom` impls.
- The macro calls that begin with `subtype` (for example, `subtype!` and `subtype_string!`) are legacy APIs that expand to newtypes.
  - Don't use them in new code because their checker and preprocessor concepts have been superseded by explicit conversion impls.
- Use the `SerializeTransparent` derive for a refined newtype that must serialize identically to its inner field while using Serde's `try_from` container attribute for validated deserialization.

### Error handling

#### Principle

Every fallible function must return an error with enough data for the caller to retry the call.

#### Guidelines

* Use `handle!` instead of `?` try operator to unwrap `Result` types
* Use `handle!` instead of `Result::map_err`
* Use `handle_opt!` instead of `?` try operator to unwrap `Option` types
* Use `handle_opt!` instead of `Option::ok_or` and `Option::ok_or_else`
* Use `handle_bool!` instead of `if condition { return Err(...) }` to return an error if some condition is true
* Use `handle_iter!` or `handle_iter_of_refs!` to collect and return errors from iterators
* Use `handle_into_iter!` to handle errors in collections that implement `IntoIterator` (including `Vec` and `HashMap`)
* Calls to macros that begin with `handle` must not contain calls to `clone` (must not contain `.clone()`)
  * Rationale: there is no need to clone the variables because the macros consume them only in the error branch, and the error branch contains a `return` statement. The variables are not consumed in the success branch, so you can always use them in the subsequent code.
* Don't convert a `Result` into an `Option`, always propagate the error up the call stack
* Don't use `unwrap` or `expect`
* Don't return strings as errors
* Every fallible function must return a unique error type, even if it contains only one fallible expression
* Every call to another fallible function must be wrapped in a unique error enum variant
* Every fallible function body must begin with `use ThisFunctionError::*;`, where `ThisFunctionError` must be the name of this function's error enum (for example: `use ParseConfigError::*;`)
* Every fallible function body must use the error enum variant names without the error enum name prefix (for example: `ReadFileFailed` instead of `ParseConfigError::ReadFileFailed`)
* Every error type must be an enum
* Every error type must derive `Error` via `thiserror` v2
* Every error type must be located in the same file as the function that returns it below other non-mod items
* Every error enum variant must be a struct variant
* Every error enum variant must contain one field per owned variable that is relevant to the fallible expression that this variant wraps
  * The relevant variable is a variable whose value determines whether the fallible expression returns an `Ok` or an `Err`
* Every error enum variant must have fields only for [`data types`](#data-type), not for [`non-data types`](#non-data-type)
* Every error enum variant must have an `#[error]` attribute
  * The `#[error]` attribute must contain the error message displayed for the user
  * The `#[error]` attribute must not contain the `source` field
  * The `#[error]` attribute should contain only those fields that can be displayed on one line
  * If the `#[error]` attribute contains fields that implement `Display`, then those fields must be output using `Display` formatting (not `Debug` formatting)
    * Good:
      ```rust
      #[derive(Error, Debug)]
      pub enum QueryFailed {
          #[error("task not found for query '{query}'")]
          TaskNotFound { query: String }
      }
      ```
    * Bad:
      ```rust
      #[derive(Error, Debug)]
      pub enum QueryFailed {
          #[error("task not found for query '{query:?}'")]
          TaskNotFound { query: String }
      }
      ```
  * If the `#[error]` attribute contains fields whose values may be rendered as [hard-to-see string](#hard-to-see-string), then those fields must be wrapped in single quotes:
    * `name` can be rendered as hard-to-see string, so it must be wrapped in single quotes:
      * Good: `#[error("user '{name}' not found")]`
      * Bad: `#[error("user {name} not found")]`
    * `len` can't be rendered as hard-to-see string, so it must not be wrapped in single quotes:
      * Good: `#[error("failed to parse {len} responses", len = responses.len())]`
      * Bad: `#[error("failed to parse '{len}' responses", len = responses.len())]`
  * If the error enum variant has a field whose type is `std::process::Command` or `tokio::process::Command`, it must be rendered in the error message in backticks via `render_command` function from `errgonomic` crate (requires `process` feature)
* If the error enum variant has a `source` field, then this field must be the first field
* If each field of each variant of the error enum implements `Copy`, then the error enum must implement `Copy` too
* Every error enum variant field must have an owned type (not a reference)
* Every error enum variant field must not have a `#[from]` attribute
* Every variable that contains secret data (the one which must not be displayed or logged, e.g. password, API key, personally identifying information) must have a type that doesn't output the underlying data in the `Debug` and `Display` impls (e.g. `secrecy::SecretBox`)
* The code that calls a fallible function on each element of a collection should return an `impl Iterator<Item = Result<T, E>>` instead of short-circuiting on the first error
* If Clippy outputs a `result_large_err` warning, then the large fields of the error enum must be wrapped in a `Box`
* If an argument of callee implements `Copy`, the callee should not include it in the list of error enum variant fields (the caller must include it because of the rule to include all relevant owned variables)
* If you see a function that returns a `Result` whose last argument is `()` (e.g. `Result<(), ()>`, `Result<T, ()>`, `Result<u32, ()>`), then you must fix the error handling in this function according to the guidelines and replace `()` with a proper error type

##### Naming

* The name of the error enum must end with `Error` (for example: `ParseConfigError`)
* The name of the error enum variant should end with `Failed` or `NotFound` or `Invalid` (for example: `ReadFileFailed`, `UserNotFound`, `PasswordInvalid`)
* If the error variant name is associated with a child function call, the name of the error variant must be equal to the name of the function converted to CamelCase concatenated with `Failed` (for example: if the parent function calls `read_file`, then it should call it like this: `handle!(read_file(&path), ReadFileFailed, path)`
* The name of the error enum must include the name of the function converted to CamelCase
  * If the function is a freestanding function, the name of the error type must be exactly equal to the name of the function converted to CamelCase concatenated with `Error`
  * If the function is an associated function, the name of the error type must be exactly equal to the name of the type without generics concatenated with the name of the function in CamelCase concatenated with `Error`
  * If the error is specified as an associated type of a foreign trait with multiple functions that return this associated error type, then the name of the error type must be exactly equal to the name of the trait including generics concatenated with the name of the type for which this trait is implemented concatenated with `Error`
* Every `impl TryFrom<A> for B` must use a special form of error handling that matches on multiple variables at once and returns a single error that contains fields for all available variables. For example:
  ```rust
  #[derive(Getters, Clone, Debug)]
  pub struct Human {
      name: String,
      #[getter(copy)]
      age: u32,
  }
  
  #[derive(Getters, Clone, Debug)]
  pub struct Adult {
      name: NonEmptyString,
      #[getter(copy)]
      age: u32,
  }
  
  impl TryFrom<Human> for Adult {
      type Error = TryFromHumanForAdultError;
  
      fn try_from(input: Human) -> Result<Self, Self::Error> {
          use TryFromHumanForAdultError::*;
          let Human {
              name,
              age,
          } = input;
          let name_result = NonEmptyString::try_from(name);
          let is_adult = age > 18;
          match (name_result, is_adult) {
              (Ok(name), true) => Ok(Self {
                  name,
                  age,
              }),
              (name_result, is_adult) => Err(ConversionFailed {
                  name_result,
                  age,
                  is_adult,
              }),
          }
      }
  }
  
  #[derive(Error, Debug)]
  pub enum TryFromHumanForAdultError {
      #[error("failed to convert human to adult")]
      ConversionFailed { name_result: Result<NonEmptyString, TryFromStringForNonEmptyStringError>, age: u32, is_adult: bool },
  }
  ```

#### Definitions

##### Fallible expression

An expression that returns a `Result`.

##### Fallible expression group

A group of [fallible expressions](#fallible-expression) where each output variable does not depend on the output variables of other fallible expressions within the same group.

Aliases: FEG.

##### Data type

A type that holds the actual data.

Examples:

* `bool`
* `String`
* `PathBuf`

##### Non-data type

A type that doesn't hold the actual data.

Examples:

* `RestClient` doesn't point to the actual data, it only allows querying it.
* `DatabaseConnection` doesn't hold the actual data, it only allows querying it.

##### Hard-to-see string

A string that is empty or contains only whitespace characters.

#### Files

##### File: src/functions/exit.rs

````rust
use crate::eprintln_error;
use std::error::Error;
use std::process::ExitCode;

#[cfg(feature = "futures")]
use futures::Stream;
#[cfg(feature = "futures")]
use futures::StreamExt;
#[cfg(feature = "futures")]
use std::pin::pin;

/// Converts a [`Result`] into an [`ExitCode`], printing a detailed error trace on failure.
pub fn exit_result<E: Error>(result: Result<ExitCode, E>) -> ExitCode {
    result.unwrap_or_else(|err| {
        eprintln_error(&err);
        ExitCode::FAILURE
    })
}

/// Converts an [`Option`] into an [`ExitCode`], printing a detailed error trace on failure.
pub fn exit_option<E: Error>(option: Option<E>) -> ExitCode {
    match option {
        None => ExitCode::SUCCESS,
        Some(err) => {
            eprintln_error(&err);
            ExitCode::FAILURE
        }
    }
}

/// Converts an [`impl IntoIterator<Item = Result<(), E>>`](IntoIterator) into an [`ExitCode`], printing a detailed error trace on the first failure.
pub fn exit_iterator_of_results_print_first<E: Error>(iter: impl IntoIterator<Item = Result<(), E>>) -> ExitCode {
    for result in iter.into_iter() {
        if let Err(error) = result {
            eprintln_error(&error);
            return ExitCode::FAILURE;
        }
    }
    ExitCode::SUCCESS
}

#[cfg(feature = "futures")]
/// Converts an [`impl IntoIterator<Item = Result<(), E>>`](IntoIterator) into an [`ExitCode`], printing a detailed error trace on the first failure.
pub async fn exit_stream_of_results_print_first<E: Error>(stream: impl Stream<Item = Result<(), E>>) -> ExitCode {
    let mut stream = pin!(stream);
    if let Some(Err(error)) = stream.next().await {
        eprintln_error(&error);
        return ExitCode::FAILURE;
    }
    ExitCode::SUCCESS
}
````

##### File: src/functions/get_root_error.rs

````rust
use core::error::Error;

/// Returns the deepest source error in the error chain (the root cause).
pub fn get_root_source(error: &dyn Error) -> &dyn Error {
    let mut source = error;
    while let Some(source_new) = source.source() {
        source = source_new;
    }
    source
}
````

##### File: src/functions/partition_result.rs

````rust
use alloc::vec::Vec;

/// PRUNING: drops collected `Ok` values and ignores later `Ok` values after the first `Err`, because `handle_iter!` only returns errors when any item fails.
#[doc(hidden)]
pub fn partition_result<T, E>(results: impl IntoIterator<Item = Result<T, E>>) -> Result<Vec<T>, Vec<E>> {
    let iter = results.into_iter();
    let (lower, _) = iter.size_hint();
    let (oks, errors) = iter.fold((Vec::with_capacity(lower), Vec::new()), |(mut oks, mut errors), result| {
        match result {
            Ok(value) => {
                if errors.is_empty() {
                    oks.push(value);
                }
            }
            Err(error) => {
                if errors.is_empty() {
                    oks = Vec::new();
                }
                errors.push(error);
            }
        }
        (oks, errors)
    });

    if errors.is_empty() { Ok(oks) } else { Err(errors) }
}
````

##### File: src/functions/render_command.rs

````rust
use alloc::string::String;
use alloc::vec::Vec;
use core::iter::once;
use std::process::Command;

pub fn render_command(command: &Command) -> String {
    let parts = once(command.get_program().to_string_lossy())
        .chain(command.get_args().map(|arg| arg.to_string_lossy()))
        .collect::<Vec<_>>();
    let result = shlex::try_join(parts.iter().map(|x| x.as_ref()));
    match result {
        Ok(string) => string,
        Err(_) => command.get_program().to_string_lossy().into_owned(),
    }
}
````

##### File: src/functions/write_to_named_temp_file.rs

````rust
use crate::{handle, map_err};
use std::fs::File;
use std::io;
use std::io::Write;
use std::path::PathBuf;
use tempfile::{NamedTempFile, PersistError};
use thiserror::Error;

/// Writes the provided buffer to a named temporary file and persists it to disk.
///
/// Returns the persisted file handle and its path.
pub fn write_to_named_temp_file(buf: &[u8]) -> Result<(File, PathBuf), WriteToNamedTempFileError> {
    use WriteToNamedTempFileError::*;
    let mut temp = handle!(NamedTempFile::new(), CreateTempFileFailed);
    handle!(temp.write_all(buf), WriteFailed);
    map_err!(temp.keep(), KeepFailed)
}

/// Errors returned by [`write_to_named_temp_file`].
#[derive(Error, Debug)]
pub enum WriteToNamedTempFileError {
    /// Failed to create a temporary file.
    #[error("failed to create a temporary file")]
    CreateTempFileFailed { source: io::Error },
    /// Failed to write the buffer into the temporary file.
    #[error("failed to write to a temporary file")]
    WriteFailed { source: io::Error },
    /// Failed to persist the temporary file to its final path.
    #[error("failed to persist the temporary file")]
    KeepFailed { source: PersistError },
}
````

##### File: src/functions/writeln_error.rs

````rust
use crate::{ErrorDisplayer, WriteToNamedTempFileError, map_err, write_to_named_temp_file};
use alloc::format;
use core::error::Error;
use core::fmt::{self, Formatter};
use std::eprintln;
use std::io;
use std::io::{Write, stderr};

/// Writes a human-readable error trace to the provided formatter.
pub fn writeln_error_to_formatter<E: Error + ?Sized>(error: &E, f: &mut Formatter<'_>) -> fmt::Result {
    use std::fmt::Write;
    write!(f, "- {error}")?;
    if let Some(source_new) = error.source() {
        f.write_char('\n')?;
        writeln_error_to_formatter(source_new, f)
    } else {
        Ok(())
    }
}

/// Writes a human-readable error trace to the provided writer and persists the full debug output to a temp file.
///
/// This is useful for CLI tools that want a concise error trace on stderr and a path to a full report.
pub fn writeln_error_to_writer_and_file<E: Error>(error: &E, writer: &mut dyn Write) -> Result<(), WritelnErrorToWriterAndFileError> {
    use WritelnErrorToWriterAndFileError::*;
    let displayer = ErrorDisplayer(error);
    map_err!(writeln!(writer, "{displayer}"), WriteFailed)?;
    map_err!(writeln!(writer), WriteFailed)?;
    let error_debug = format!("{error:#?}");
    let result = write_to_named_temp_file(error_debug.as_bytes());
    match result {
        Ok((_file, path_buf)) => {
            map_err!(writeln!(writer, "See the full error report:"), WriteFailed)?;
            if cfg!(windows) {
                map_err!(writeln!(writer, "{}", path_buf.display()), WriteFailed)?;
            } else {
                // assuming `less` is available
                map_err!(writeln!(writer, "less {}", path_buf.display()), WriteFailed)?;
            }
            Ok(())
        }
        Err(source) => {
            map_err!(writeln!(writer, "{source:#?}"), WriteFailed)?;
            Err(WriteToNamedTempFileFailed {
                source,
            })
        }
    }
}

/// Errors returned by [`writeln_error_to_writer_and_file`].
#[derive(thiserror::Error, Debug)]
pub enum WritelnErrorToWriterAndFileError {
    #[error("failed to write the error trace")]
    WriteFailed { source: io::Error },
    #[error("failed to write the full error report")]
    WriteToNamedTempFileFailed { source: WriteToNamedTempFileError },
}

/// Writes an error trace to stderr and, if possible, includes a path to the full error report.
pub fn eprintln_error<E>(error: &E)
where
    E: Error,
{
    use WritelnErrorToWriterAndFileError::*;
    let mut stderr = stderr().lock();
    let result = writeln_error_to_writer_and_file(error, &mut stderr);
    match result {
        Ok(()) => (),
        Err(WriteFailed {
            source,
        }) => eprintln!("failed to write the error to stderr: {source:#?}"),
        Err(WriteToNamedTempFileFailed {
            source,
        }) => eprintln!("failed to write the error to the report file: {source:#?}"),
    }
}

#[cfg(test)]
mod tests {
    use crate::functions::writeln_error::tests::JsonSchemaNewError::{InvalidInput, InvalidValues};
    use crate::{ErrVec, ErrorDisplayer};
    use CliRunError::*;
    use CommandRunError::*;
    use I18nRequestError::*;
    use I18nUpdateRunError::*;
    use JsonValueNewError::*;
    use UpdateRowError::*;
    use alloc::string::{String, ToString};
    use alloc::vec;
    use pretty_assertions::assert_eq;
    use std::eprintln;
    use std::error::Error;
    use thiserror::Error;
    use tokio::io::{Error as TokioIoError, ErrorKind as TokioIoErrorKind};

    #[test]
    fn must_write_error() {
        let error = CommandRunFailed {
            source: I18nUpdateRunFailed {
                source: UpdateRowsFailed {
                    source: vec![
                        I18nRequestFailed {
                            source: JsonSchemaNewFailed {
                                source: InvalidInput {
                                    input: "foo".to_string(),
                                },
                            },
                            row: Row::new("Foo"),
                        },
                        I18nRequestFailed {
                            source: RequestSendFailed {
                                source: TokioIoError::new(TokioIoErrorKind::AddrNotAvailable, "server at 239.143.73.1 did not respond"),
                            },
                            row: Row::new("Bar"),
                        },
                    ]
                    .into(),
                },
            },
        };
        let expected = include_str!("writeln_error/fixtures/must_write_error.txt");
        assert_write_eq(&error, expected);
    }

    #[test]
    fn must_write_nested_error() {
        let error = UpdateRowsFailed {
            source: vec![I18nRequestFailed {
                source: JsonSchemaNewFailed {
                    source: InvalidValues {
                        source: vec![
                            InvalidKey {
                                key: "zed".to_string(),
                            },
                            InvalidKey {
                                key: "moo".to_string(),
                            },
                        ]
                        .into(),
                    },
                },
                row: Row::new("Foo"),
            }]
            .into(),
        };
        let expected = include_str!("writeln_error/fixtures/must_write_nested_error.txt");
        assert_write_eq(&error, expected);
    }

    fn assert_write_eq<E: Error>(error: &E, expected: &str) {
        use std::fmt::Write;
        let mut actual = String::new();
        let displayer = ErrorDisplayer(error);
        writeln!(actual, "{displayer}").unwrap();
        eprintln!("{actual}");
        assert_eq!(actual, expected)
    }

    #[derive(Error, Debug)]
    pub enum CliRunError {
        #[error("failed to run CLI command")]
        CommandRunFailed { source: CommandRunError },
    }

    #[derive(Error, Debug)]
    pub enum CommandRunError {
        #[error("failed to run i18n update command")]
        I18nUpdateRunFailed { source: I18nUpdateRunError },
    }

    #[derive(Error, Debug)]
    pub enum I18nUpdateRunError {
        #[error("failed to update {len} rows", len = source.len())]
        UpdateRowsFailed { source: ErrVec<UpdateRowError> },
    }

    #[derive(Error, Debug)]
    pub enum UpdateRowError {
        #[error("failed to send an i18n request for row '{row}'", row = row.name)]
        I18nRequestFailed { source: I18nRequestError, row: Row },
    }

    #[derive(Error, Debug)]
    pub enum I18nRequestError {
        #[error("failed to construct a JSON schema")]
        JsonSchemaNewFailed { source: JsonSchemaNewError },
        #[error("failed to send a request")]
        RequestSendFailed { source: TokioIoError },
    }

    #[derive(Error, Debug)]
    pub enum JsonSchemaNewError {
        #[error("input must be a JSON object")]
        InvalidInput { input: String },
        #[error("failed to construct {len} values", len = source.len())]
        InvalidValues { source: ErrVec<JsonValueNewError> },
    }

    #[derive(Error, Debug)]
    pub enum JsonValueNewError {
        #[error("'{key}' must be a JSON value")]
        InvalidKey { key: String },
    }

    #[derive(Debug)]
    pub struct Row {
        name: String,
    }

    impl Row {
        pub fn new(name: impl Into<String>) -> Self {
            Self {
                name: name.into(),
            }
        }
    }
}
````

##### File: src/types/debug_as_display.rs

````rust
use core::fmt::{self, Debug, Display, Formatter};

/// A wrapper that renders `Debug` using the inner type's `Display` implementation.
/// This wrapper is needed for types that have an easy-to-understand `Display` impl but hard-to-understand `Debug` impl.
#[derive(Ord, PartialOrd, Eq, PartialEq, Copy, Clone)]
pub struct DebugAsDisplay<T: Display>(
    /// Inner value rendered with `Display` for both `Debug` and `Display`.
    pub T,
);

impl<T: Display> Debug for DebugAsDisplay<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        Display::fmt(&self.0, f)
    }
}

impl<T: Display> Display for DebugAsDisplay<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        Display::fmt(&self.0, f)
    }
}

impl<T: Display> From<T> for DebugAsDisplay<T> {
    fn from(value: T) -> Self {
        Self(value)
    }
}
````

##### File: src/types/display_as_debug.rs

````rust
use core::fmt::{self, Debug, Display, Formatter};

/// A wrapper that renders `Display` using the inner type's `Debug` implementation.
#[derive(Ord, PartialOrd, Eq, PartialEq, Copy, Clone, Debug)]
pub struct DisplayAsDebug<T: Debug>(
    /// Inner value rendered with `Debug` for `Display`.
    pub T,
);

impl<T: Debug> Display for DisplayAsDebug<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        Debug::fmt(&self.0, f)
    }
}

impl<T: Debug> From<T> for DisplayAsDebug<T> {
    fn from(value: T) -> Self {
        Self(value)
    }
}
````

##### File: src/types/err_vec.rs

````rust
use crate::ErrorDisplayer;
use alloc::format;
use alloc::vec::Vec;
use core::error::Error;
use core::fmt::{self, Debug, Display, Formatter, Write};
use core::ops::{Deref, DerefMut};

/// An owned collection of errors
#[derive(Default, Clone, Debug)]
pub struct ErrVec<E: Error>(pub Vec<E>);

impl<E: Error> ErrVec<E> {
    pub fn new(iter: impl IntoIterator<Item = E>) -> Self {
        Self(iter.into_iter().collect())
    }
}

impl<E: Error> Display for ErrVec<E> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        write!(f, "encountered {len} errors", len = self.len())?;
        self.0.iter().try_for_each(|error| {
            f.write_char('\n')?;
            let recursive_displayer = ErrorDisplayer(error);
            let string = format!("{recursive_displayer}");
            let mut lines = string.lines();
            let first_line_opt = lines.next();
            if let Some(first_line) = first_line_opt {
                write!(f, "  * {first_line}")?;
                lines.try_for_each(|line| write!(f, "\n    {line}"))?;
            }
            Ok(())
        })
    }
}

impl<E: Error> Error for ErrVec<E> {}

impl<E: Error> Deref for ErrVec<E> {
    type Target = Vec<E>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<E: Error> DerefMut for ErrVec<E> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl<E: Error> From<ErrVec<E>> for Vec<E> {
    fn from(val: ErrVec<E>) -> Self {
        val.0
    }
}

impl<E: Error> From<Vec<E>> for ErrVec<E> {
    fn from(inner: Vec<E>) -> Self {
        Self(inner)
    }
}

impl<E: Error + Clone, const N: usize> From<[E; N]> for ErrVec<E> {
    fn from(inner: [E; N]) -> Self {
        Self(inner.to_vec())
    }
}

impl<E: Error + Clone> From<&[E]> for ErrVec<E> {
    fn from(inner: &[E]) -> Self {
        Self(inner.to_vec())
    }
}
````

##### File: src/types/error_displayer.rs

````rust
use crate::writeln_error_to_formatter;
use core::fmt::{self, Display, Formatter};
use std::error::Error;

pub struct ErrorDisplayer<'a, E: ?Sized>(pub &'a E);

impl<E: Error + ?Sized> Display for ErrorDisplayer<'_, E> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        writeln_error_to_formatter(self.0, f)
    }
}

impl<'a, E: Error + ?Sized> From<&'a E> for ErrorDisplayer<'a, E> {
    fn from(error: &'a E) -> Self {
        Self(error)
    }
}
````

##### File: src/types/item_error.rs

````rust
use thiserror::Error;

/// Associates an error with the item that caused it.
#[derive(Error, Debug)]
#[error("error occurred for item {item}: {source}")]
pub struct ItemError<T, E> {
    /// The item that produced the error.
    pub item: T,
    /// The error produced for the item.
    pub source: E,
}
````

##### File: src/types/path_buf_display.rs

````rust
use crate::DisplayAsDebug;
use std::path::PathBuf;

/// A [`PathBuf`] that returns a `Debug` representation in [`Display`](std::fmt::Display) impl.
pub type PathBufDisplay = DisplayAsDebug<PathBuf>;
````

##### File: src/functions.rs

````rust
mod get_root_error;
mod partition_result;

pub use get_root_error::*;
pub use partition_result::*;

cfg_if::cfg_if! {
    if #[cfg(feature = "std")] {
        mod writeln_error;
        mod write_to_named_temp_file;
        mod exit;
        pub use writeln_error::*;
        pub use write_to_named_temp_file::*;
        pub use exit::*;
    }
}

cfg_if::cfg_if! {
    if #[cfg(all(feature = "process"))] {
        mod render_command;
        pub use render_command::*;
    }
}
````

##### File: src/lib.rs

````rust
//! Macros for ergonomic error handling with [thiserror](https://crates.io/crates/thiserror).
//!
//! ## Example
//!
//! ```rust
//! # #[cfg(feature = "std")]
//! # {
//! # use std::io;
//! # use std::fs::read_to_string;
//! # use std::path::{Path, PathBuf};
//! # use serde::{Deserialize, Serialize};
//! # use serde_json::from_str;
//! # use thiserror::Error;
//! # use errgonomic::handle;
//! #
//! #[derive(Serialize, Deserialize)]
//! struct Config {/* some fields */}
//!
//! // bad: doesn't return the path to config (the user won't be able to fix it)
//! fn parse_config_v1(path: PathBuf) -> io::Result<Config> {
//!     let contents = read_to_string(&path)?;
//!     let config = from_str(&contents).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
//!     Ok(config)
//! }
//!
//! // good: returns the path to config & the underlying deserialization error (the user will be able fix it)
//! fn parse_config_v2(path: PathBuf) -> Result<Config, ParseConfigError> {
//!     use ParseConfigError::*;
//!     let contents = handle!(read_to_string(&path), ReadToStringFailed, path);
//!     let config = handle!(from_str(&contents), DeserializeFailed, path, contents);
//!     Ok(config)
//! }
//!
//! #[derive(Error, Debug)]
//! enum ParseConfigError {
//!     #[error("failed to read file to string: '{path}'")]
//!     ReadToStringFailed { path: PathBuf, source: std::io::Error },
//!     #[error("failed to parse the file contents into config: '{path}'")]
//!     DeserializeFailed { path: PathBuf, contents: String, source: serde_json::Error }
//! }
//! # }
//! ```
//!
//! Advantages:
//!
//! * `parse_config_v2` allows you to determine exactly what error has occurred
//! * `parse_config_v2` provides you with all information needed to fix the underlying issue
//! * `parse_config_v2` allows you to retry the call by reusing the `path` (avoiding unnecessary clones)
//!
//! Disadvantages:
//!
//! * `parse_config_v2` is longer
//!
//! That means `parse_config_v2` is strictly better but requires writing more code. However, with LLMs, writing more code is not an issue. Therefore, it's better to use a more verbose approach `v2`, which provides better errors.
//!
//! This crates provides the `handle` family of macros to simplify the error handling code.
//!
//! ## Better debugging
//!
//! To improve your debugging experience: call [`exit_result`] in `main` right before return, and it will display all information necessary to understand the root cause of the error:
//!
//! ```rust
//! # #[cfg(feature = "std")]
//! # {
//! # use errgonomic::exit_result;
//! # use thiserror::Error;
//! # use std::process::ExitCode;
//! #
//! # #[derive(Error, Debug)]
//! # enum Err {}
//! #
//! # fn run() -> Result<ExitCode, Err> { Ok(ExitCode::SUCCESS) }
//! #
//! pub fn main() -> ExitCode {
//!     exit_result(run())
//! }
//! # }
//! ```
//!
//! This will produce a nice "error trace" like below:
#![doc = "```text"]
#![doc = include_str!("./functions/writeln_error/fixtures/must_write_error.txt")]
#![doc = "```"]
//!

#![cfg_attr(not(test), deny(unused_crate_dependencies))]
#![no_std]

extern crate alloc;
extern crate core;
#[cfg(feature = "std")]
extern crate std;

mod macros;

mod types;

pub use types::*;

mod functions;

pub use functions::*;

#[cfg(all(test, feature = "std"))]
mod drafts;
````

##### File: src/macros.rs

````rust
/// [`handle!`](crate::handle) is a better alternative to [`map_err`](Result::map_err) because it doesn't capture any variables from the environment if the result is [`Ok`], only when the result is [`Err`].
/// By contrast, a closure passed to `map_err` always captures the variables from environment, regardless of whether the result is [`Ok`] or [`Err`]
/// Use [`handle!`](crate::handle) if you need to pass owned variables to an error variant (which is returned only in case when result is [`Err`])
/// In addition, this macro captures the original error in the `source` variable, and sets it as the `source` key of the error variant
///
/// Note: [`handle!`](crate::handle) assumes that your error variant is a struct variant
#[macro_export]
macro_rules! handle {
    ($result:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        match $result {
            Ok(value) => value,
            Err(source) => return Err($variant {
                source: source.into(),
                $($arg: $crate::_into!($arg$(: $value)?)),*
            }),
        }
    };
}

/// See also: [`handle_opt_take!`](crate::handle_opt_take)
#[macro_export]
macro_rules! handle_opt {
    ($option:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        match $option {
            Some(value) => value,
            None => return Err($variant {
                $($arg: $crate::_into!($arg$(: $value)?)),*
            }),
        }
    };
}

/// This macro is an opposite of [`handle_opt!`](crate::handle_opt) - it returns an error if the option contains a `Some` variant.
///
/// Note that this macro calls [`Option::take`], which will leave a `None` if the option was `Some(value)`.
/// Note that this macro has a mandatory argument `$some_value` (used in `if let Some($some_value) = $option.take()`), which will also be passed to the error enum variant.
#[macro_export]
macro_rules! handle_opt_take {
    ($option:expr, $variant:ident, $some_value:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        if let Some($some_value) = $option.take() {
            return Err($variant {
                $some_value: $some_value.into(),
                $($arg: $crate::_into!($arg$(: $value)?)),*
            })
        }
    };
}

/// Returns an error when the condition is true.
///
/// This is useful for guard checks that should fail fast with a specific error variant.
#[macro_export]
macro_rules! handle_bool {
    ($condition:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        if $condition {
            return Err($variant {
                $($arg: $crate::_into!($arg$(: $value)?)),*
            });
        };
    };
}

/// Collects results from an iterator, returning a variant that wraps all errors.
///
/// `$results` must be an `impl Iterator<Item = Result<T, E>>`.
#[macro_export]
macro_rules! handle_iter {
    ($results:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        {
            match $crate::partition_result($results) {
                Ok(oks) => oks,
                Err(errors) => {
                    return Err($variant {
                        source: errors.into(),
                        $($arg: $crate::_into!($arg$(: $value)?)),*
                    });
                }
            }
        }
    };
}

/// Collects results while keeping the corresponding input items, returning `(outputs, items)` on success.
///
/// This macro returns a tuple because the iteration consumes items that may be needed later.
/// If there are no errors, `items.len() == outputs.len()`.
/// If the results iterator terminates early, the returned `items` may be shorter than the original input.
#[macro_export]
macro_rules! handle_iter_of_refs {
    ($results:expr, $items:expr, $variant:ident $(, $arg:ident$(: $value:expr)?)*) => {
        {
            use alloc::vec::Vec;
            let (outputs, items, errors) = core::iter::zip($results, $items).fold(
                (Vec::new(), Vec::new(), Vec::new()),
                |(mut outputs, mut items, mut errors), (result, item)| {
                    match result {
                        Ok(output) => {
                            outputs.push(output);
                            items.push(item);
                        }
                        Err(source) => {
                            errors.push($crate::ItemError {
                                item,
                                source,
                            });
                        }
                    }
                    (outputs, items, errors)
                },
            );
            if errors.is_empty() {
                (outputs, items)
            } else {
                return Err($variant {
                    source: errors.into(),
                    $($arg: $crate::_into!($arg$(: $value)?)),*
                });
            }
        }
    };
}

/// Collects results from any `IntoIterator`, wrapping all errors into one variant.
#[macro_export]
macro_rules! handle_into_iter {
    ($results:expr, $variant:ident $(, $arg:ident$(: $value:expr)?)*) => {
        $crate::handle_iter!($results.into_iter(), $variant $(, $arg$(: $value)?),*)
    };
}

/// [`handle_discard`](crate::handle_discard) should only be used when you want to discard the source error. This is discouraged. Prefer other handle-family macros that preserve the source error.
#[macro_export]
macro_rules! handle_discard {
    ($result:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        match $result {
            Ok(value) => value,
            Err(_) => return Err($variant {
                $($arg: $crate::_into!($arg$(: $value)?)),*
            }),
        }
    };
}

/// [`map_err`](crate::map_err) should be used only when the error variant doesn't capture any owned variables (which is very rare), or exactly at the end of the block (in the position of returned expression).
#[macro_export]
macro_rules! map_err {
    ($result:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        $result.map_err(|source| $variant {
            source: source.into(),
            $($arg: $crate::_into!($arg$(: $value)?)),*
        })
    };
}

/// Converts [`None`] into an error variant without returning early.
///
/// [`map_none`](crate::map_none) should be used only when the error variant doesn't capture any owned variables (which is very rare), or exactly at the end of the block (in the position of returned expression).
#[macro_export]
macro_rules! map_none {
    ($option:expr, $variant:ident$(,)? $($arg:ident$(: $value:expr)?),*) => {
        match $option {
            Some(value) => Ok(value),
            None => Err($variant {
                $($arg: $crate::_into!($arg$(: $value)?)),*
            })
        }
    };
}

/// Internal
#[doc(hidden)]
#[macro_export]
macro_rules! _into {
    ($arg:ident) => {
        $arg.into()
    };
    ($arg:ident: $value:expr) => {
        $value.into()
    };
}

/// Internal
#[doc(hidden)]
#[macro_export]
macro_rules! _index_err {
    ($f:ident) => {
        |(index, item)| $f(item).map_err(|err| (index, err))
    };
}

/// Internal
#[doc(hidden)]
#[macro_export]
macro_rules! _index_err_async {
    ($f:ident) => {
        async |(index, item)| $f(item).await.map_err(|err| (index, err))
    };
}

#[cfg(all(test, feature = "std"))]
mod tests {
    use crate::{ErrVec, ItemError, PathBufDisplay};
    use alloc::boxed::Box;
    use alloc::string::String;
    use alloc::vec::Vec;
    use futures::future::join_all;
    use serde::{Deserialize, Serialize};
    use std::io;
    use std::path::{Path, PathBuf};
    use std::println;
    use std::str::FromStr;
    use std::sync::{Arc, RwLock};
    use thiserror::Error;
    use tokio::fs::read_to_string;
    use tokio::task::JoinSet;

    #[allow(dead_code)]
    struct PrintNameCommand {
        dir: PathBuf,
        format: Format,
    }

    #[allow(dead_code)]
    impl PrintNameCommand {
        async fn run(self) -> Result<(), PrintNameCommandError> {
            use PrintNameCommandError::*;
            let Self {
                dir,
                format,
            } = self;
            let config = handle!(parse_config(&dir, format).await, ParseConfigFailed);
            println!("{}", config.name);
            Ok(())
        }
    }

    /// This function tests the [`crate::handle!`] macro
    #[allow(dead_code)]
    async fn parse_config(dir: &Path, format: Format) -> Result<Config, ParseConfigError> {
        use Format::*;
        use ParseConfigError::*;
        let path_buf = dir.join("config.json");
        let contents = handle!(read_to_string(&path_buf).await, ReadFileFailed, path: path_buf);
        match format {
            Json => {
                let config = handle!(serde_json::de::from_str(&contents), DeserializeFromJson, path: path_buf, contents);
                Ok(config)
            }
            Toml => {
                let config = handle!(toml::de::from_str(&contents), DeserializeFromToml, path: path_buf, contents);
                Ok(config)
            }
        }
    }

    /// This function tests the [`crate::handle_opt!`] and [`crate::map_none!`] macros.
    #[allow(dead_code)]
    fn first_word(lines: &[String]) -> Result<&str, FirstWordError> {
        use FirstWordError::*;
        let line = handle_opt!(lines.first(), LineNotFound);
        map_none!(line.split_whitespace().next(), WordNotFound)
    }

    /// This function tests the [`crate::handle_iter!`] macro
    #[allow(dead_code)]
    fn multiply_evens(numbers: Vec<u32>) -> Result<Vec<u32>, MultiplyEvensError> {
        use MultiplyEvensError::*;
        let results = numbers.into_iter().map(|number| {
            use CheckEvenError::*;
            if number % 2 == 0 {
                match number.checked_mul(10) {
                    Some(product) => Ok(product),
                    None => Err(NumberOverflowed {
                        number,
                    }),
                }
            } else {
                Err(NumberNotEven {
                    number,
                })
            }
        });
        Ok(handle_iter!(results, CheckEvensFailed))
    }

    /// This function tests the [`crate::handle_into_iter!`] macro
    #[allow(dead_code)]
    async fn read_files(paths: Vec<PathBuf>) -> Result<Vec<String>, ReadFilesError> {
        use ReadFilesError::*;
        let results = paths
            .into_iter()
            .map(check_file)
            .collect::<JoinSet<_>>()
            .join_all()
            .await;
        Ok(handle_into_iter!(results, CheckFilesFailed))
    }

    #[allow(dead_code)]
    async fn read_files_ref(paths: Vec<PathBuf>) -> Result<Vec<String>, ReadFilesRefError> {
        use ReadFilesRefError::*;
        let iter = paths.iter().map(check_file_ref);
        let results = join_all(iter).await;
        let items = paths.into_iter().map(PathBufDisplay::from);
        let (outputs, _items) = handle_iter_of_refs!(results.into_iter(), items, CheckFilesRefFailed);
        Ok(outputs)
    }

    // async fn check_file(path: &Path)

    /// This function exists to test error handling in async code
    #[allow(dead_code)]
    async fn process(number: u32) -> Result<u32, ProcessError> {
        Ok(number)
    }

    #[derive(Error, Debug)]
    enum PrintNameCommandError {
        #[error("failed to parse config")]
        ParseConfigFailed { source: ParseConfigError },
    }

    /// Variants don't have the `format` field because every variant already corresponds to a single specific format
    /// Some variants have the `path` field because the `contents` depends on `path`
    /// Some `source` field types are wrapped in `Box` according to suggestion from `result_large_err` lint
    #[derive(Error, Debug)]
    enum ParseConfigError {
        #[error("failed to read the file: {path}")]
        ReadFileFailed { path: PathBuf, source: io::Error },
        #[error("failed to deserialize the file contents from JSON: {path}")]
        DeserializeFromJson { path: PathBuf, contents: String, source: Box<serde_json::error::Error> },
        #[error("failed to deserialize the file contents from TOML: {path}")]
        DeserializeFromToml { path: PathBuf, contents: String, source: Box<toml::de::Error> },
    }

    #[allow(dead_code)]
    #[derive(Error, Debug)]
    enum ProcessError {}

    #[allow(dead_code)]
    #[derive(Copy, Clone, Debug)]
    enum Format {
        Json,
        Toml,
    }

    #[derive(Serialize, Deserialize, Clone, Debug)]
    struct Config {
        name: String,
        timeout: u64,
        parallel: bool,
    }

    #[allow(dead_code)]
    fn parse_even_number(input: &str) -> Result<u32, ParseEvenNumberError> {
        use ParseEvenNumberError::*;
        let number = handle!(input.parse::<u32>(), InputParseFailed);
        handle_bool!(number % 2 != 0, NumberNotEven, number);
        Ok(number)
    }

    #[derive(Error, Debug)]
    enum ParseEvenNumberError {
        #[error("failed to parse input")]
        InputParseFailed { source: <u32 as FromStr>::Err },
        #[error("number is not even: {number}")]
        NumberNotEven { number: u32 },
    }

    #[derive(Error, Debug)]
    enum FirstWordError {
        #[error("line not found")]
        LineNotFound {},
        #[error("word not found")]
        WordNotFound {},
    }

    #[derive(Error, Debug)]
    enum MultiplyEvensError {
        #[error("failed to check {len} numbers", len = source.len())]
        CheckEvensFailed { source: ErrVec<CheckEvenError> },
    }

    #[derive(Error, Debug)]
    enum ReadFilesError {
        #[error("failed to check {len} files", len = source.len())]
        CheckFilesFailed { source: ErrVec<CheckFileError> },
    }

    #[derive(Error, Debug)]
    enum ReadFilesRefError {
        #[error("failed to check {len} files", len = source.len())]
        CheckFilesRefFailed { source: ErrVec<ItemError<PathBufDisplay, CheckFileRefError>> },
    }

    #[derive(Error, Debug)]
    enum CheckEvenError {
        #[error("number is not even: {number}")]
        NumberNotEven { number: u32 },
        #[error("number overflowed: {number}")]
        NumberOverflowed { number: u32 },
    }

    async fn check_file(path: PathBuf) -> Result<String, CheckFileError> {
        use CheckFileError::*;
        let content = handle!(read_to_string(&path).await, ReadToStringFailed, path);
        handle_bool!(content.is_empty(), FileIsEmpty, path);
        Ok(content)
    }

    #[derive(Error, Debug)]
    enum CheckFileError {
        #[error("failed to read the file to string: {path}")]
        ReadToStringFailed { path: PathBuf, source: io::Error },
        #[error("file is empty: {path}")]
        FileIsEmpty { path: PathBuf },
    }

    async fn check_file_ref(path: &PathBuf) -> Result<String, CheckFileRefError> {
        use CheckFileRefError::*;
        let content = handle!(read_to_string(&path).await, ReadToStringFailed);
        handle_bool!(content.is_empty(), FileIsEmpty);
        Ok(content)
    }

    #[derive(Error, Debug)]
    enum CheckFileRefError {
        #[error("failed to read the file to string")]
        ReadToStringFailed { source: io::Error },
        #[error("file is empty")]
        FileIsEmpty,
    }

    #[derive(Clone, Debug)]
    struct State {
        user: User,
    }

    #[derive(Clone, Debug)]
    struct User {
        username: String,
    }

    #[allow(dead_code)]
    #[derive(Clone, Debug)]
    struct Book {
        user_idx: usize,
        name: String,
    }

    #[allow(dead_code)]
    fn get_username(state: Arc<RwLock<State>>) -> Result<String, GetUsernameError> {
        use GetUsernameError::*;
        // `state.read()` returns `LockResult` whose Err variant is `PoisonError<RwLockReadGuard<'_, T>>`, which contains an anonymous lifetime
        // The error enum returned from this function must contain only owned fields, so it can't contain a `source` that has a lifetime
        // Therefore, we have to use handle_discard!, although it is discouraged
        let guard = handle_discard!(state.read(), AcquireReadLockFailed);
        let username = guard.user.username.clone();
        Ok(username)
    }

    #[derive(Error, Debug)]
    pub enum GetUsernameError {
        #[error("failed to acquire read lock")]
        AcquireReadLockFailed,
    }

    #[derive(Clone, Debug)]
    struct Db {
        users: Vec<User>,
        books: Vec<Book>,
    }

    impl Db {
        /// Validates only the foreign keys
        /// Assumes that the collection items have already been validated before they were inserted
        #[allow(dead_code)]
        pub fn validate(&self) -> impl Iterator<Item = DbValidateError> {
            use DbValidateError::*;

            self.books
                .iter()
                .enumerate()
                .filter_map(|(book_idx, book)| {
                    let user_idx = book.user_idx;
                    if self.users.get(user_idx).is_none() {
                        Some(UserNotFound {
                            book_idx,
                            user_idx,
                        })
                    } else {
                        None
                    }
                })
        }
    }

    #[derive(Error, Debug)]
    pub enum DbValidateError {
        #[error("book #{book_idx} has a non-existent user #{user_idx}")]
        UserNotFound { book_idx: usize, user_idx: usize },
    }

    #[allow(dead_code)]
    fn get_answer(prompt: String, get_response: &mut impl FnMut(String) -> Result<WeirdResponse, io::Error>) -> Result<String, GetAnswerError> {
        use GetAnswerError::*;
        // Since the `get_response` external API doesn't return the `prompt` in its error, we have to clone `prompt` before passing it as argument, so that we could pass it to the error enum variant
        // Cloning may be necessary with external APIs that don't return arguments in errors, but it must not be necessary in our code
        let mut response = handle!(get_response(prompt.clone()), GetResponseFailed, prompt);
        handle_opt_take!(response.error, ResponseContainsError, error);
        Ok(response.answer)
    }

    /// OpenAI Responses API returns a response with `error: Option<WeirdResponseError>` field, which is weird, but must still be handled
    #[derive(Debug)]
    pub struct WeirdResponse {
        answer: String,
        error: Option<WeirdResponseError>,
    }

    #[allow(dead_code)]
    #[derive(Error, Debug)]
    pub enum WeirdResponseError {
        #[error("prompt is empty")]
        PromptIsEmpty,
        #[error("context limit reached")]
        ContextLimitReached,
    }

    /// [`GetAnswerError::GetResponseFailed`] `error` attribute doesn't contain a reference to `{prompt}` because the prompt can be very long, so it would make the error message very long, which is undesirable
    #[derive(Error, Debug)]
    pub enum GetAnswerError {
        #[error("failed to get response")]
        GetResponseFailed { source: io::Error, prompt: String },
        #[error("response contains an error")]
        ResponseContainsError { error: WeirdResponseError },
    }
}
````

##### File: src/types.rs

````rust
mod debug_as_display;
mod display_as_debug;
mod item_error;

pub use debug_as_display::*;
pub use display_as_debug::*;
pub use item_error::*;

cfg_if::cfg_if! {
    if #[cfg(feature = "std")] {
        mod err_vec;
        mod path_buf_display;
        mod error_displayer;

        pub use err_vec::*;
        pub use path_buf_display::*;
        pub use error_displayer::*;
    }
}
````

## Project info

### `git remote`

```shell
origin
```

## Project files

### mise.toml

```toml
min_version = "2026.7.13"

[settings]
idiomatic_version_file_enable_tools = ["rust"]
task.output = "keep-order"

[tools]
node = "24.15.0"
deno = "1.46.1"
fnox = "1.33.1"
fd = "10.4.2"
"github:ewhauser/shuck" = "0.2.2"
"aqua:rvben/rumdl" = "0.1.0"
"npm:@commitlint/config-conventional" = "19.6.0"
"npm:@commitlint/cli" = "19.6.0"
"npm:@commitlint/types" = "19.5.0"
"npm:skills" = "1.5.24"
"cargo:https://github.com/DenisGorbachev/cargo-insert-docs" = { version = "rev:9bccf15cc367a50d2652b0eaf5da7faf5929c666", crate = "cargo-insert-docs", locked = true }
"cargo:cargo-hack" = "0.6.33"
"cargo:cargo-nextest" = "0.9.145"
"cargo:cargo-expand" = "1.0.114"
"cargo:taplo-cli" = "0.10.0"
"cargo:sd" = "1.0.0"

[hooks]
postinstall = { task = "git:install-hooks" }

[env]
SHUCK_CACHE_DIR = "{{config_root}}/.cache"

[tasks."build"]
run = "cargo build --workspace"

[tasks."check"]
depends = ["cargo:validate-config"]
run = [{ tasks = ["lint", "test"] }]

[tasks."test"]
depends = ["test:code", "test:docs"]

[tasks."lint"]
depends = ["lint:name", "lint:configs", "lint:code", "lint:code:style", "lint:shell", "lint:docs", "lint:reports"]

[tasks."lint:name"]
run = [{ task = "fix:name", args = ["--check"] }]

[tasks."lint:configs"]
depends = ["lint:configs:cargo", "lint:configs:fnox"]

[tasks."lint:configs:cargo"]
run = [{ task = "fix:cargo", args = ["--check"] }]

[tasks."lint:configs:fnox"]
run = [{ task = "fix:fnox" }]

[tasks."lint:code"]
run = "cargo clippy --locked --workspace --all-targets --all-features -- -D warnings"

[tasks."lint:code:style"]
run = "cargo fmt --all -- --check"

[tasks."lint:shell"]
run = '''shuck --config "lint.source-paths = ['$HOME']" check .'''

[tasks."lint:docs"]
run = "rumdl check"

[tasks."test:code"]
run = "fnox --profile test exec --replace -- cargo nextest run --locked --workspace --all-features --no-tests warn"

[tasks."test:code:integration"]
# see also: "agent:test:code:integration"
# `--test-threads 1` because integration tests must be run sequentially
run = [{ task = "test:code", args = ["--ignore-default-filter", "--max-fail", "1", "--test-threads", "1", "integration_tests::"] }]

[tasks."test:code:slow"]
# see also: "agent:test:code:slow"
# `--test-threads` is omitted because slow tests may be run in parallel
run = [{ task = "test:code", args = ["--ignore-default-filter", "--max-fail", "1", "slow_tests::"] }]

[tasks."test:docs"]
env = { RUSTDOCFLAGS = "-D warnings" }
run = "cargo test --locked --workspace --doc --all-features --no-fail-fast --quiet"

[tasks."pre-commit"]
alias = "pre-merge-commit"
run = [{ task = "git:validate-commit" }]

[tasks."commit-msg"]
run = 'mise run --output interleave commitlint -- --edit "$@"'

[tasks."fix"]
depends = ["fix:code", "fix:aux"]

[tasks."fix:aux"]
depends = ["fix:configs", "fix:docs", "fix:agents", "fix:readme"]

[tasks."fix:configs"]
depends = ["fix:cargo", "fix:fnox"]

[tasks."fix:code"]
depends = ["fix:name", "fix:code:style", "fix:shell"]

[tasks."fix:shell"]
run = '''shuck --config "lint.source-paths = ['$HOME']" check --fix .'''

[tasks."fix:code:warnings"]
depends = ["fix:cargo"]
# second pass is needed because "cargo clippy --fix" exits with 0 even if some warnings remain
env = { __CARGO_FIX_YOLO = 'yeah' }
run = [
    "cargo clippy --workspace --all-targets --all-features --fix --allow-dirty --allow-staged",
    { task = "lint:code" },
]

[tasks."fix:code:style"]
# Run after `fix:code:warnings` because both tasks modify the same code files.
depends = ["fix:code:warnings"]
run = "cargo fmt --all"

[tasks."fix:docs"]
depends = ["fix:agents", "fix:readme"]
# use `rumdl check --fix` instead of `rumdl fmt` because `rumdl check --fix` exits with 1 if errors remain (since v0.1.0)
run = "rumdl check --fix"

[tasks."fix:agents"]
# "fix:agents" depends on "fix:code" because it reads the code files
depends = ["fix:name", "fix:configs", "fix:code"]
run = [{ task = "gen:agents" }]

[tasks."gen:readme"]
run = "./README.ts"

[tasks."gen:agents"]
run = "./AGENTS.ts"

[tasks."commitlint"]
run = "commitlint --extends \"$(mise where npm:@commitlint/config-conventional)/node_modules/@commitlint/config-conventional/lib/index.js\""

[tasks."agent:docs:list"]
run = "[ -d .agents/docs ] && find .agents/docs -type f -print || true"
output = "interleave"
quiet = true

[tasks."agent:on:stop"]
depends = ["cargo:validate-config", "fix:shell"]
run = [{ task = "fix" }, { task = "agent:test" }]

[tasks."agent:test"]
depends = ["agent:test:code", "agent:test:code:integration", "agent:test:code:slow", "test:docs"]

[tasks."agent:test:code"]
# don't include `--fail-fast` because it's better to let the agent see all failures
# reduce output to save tokens
run = [{ task = "test:code", args = ["--cargo-quiet", "--show-progress", "none", "--no-input-handler", "--status-level", "fail", "--final-status-level", "flaky", "--no-fail-fast"] }]

[tasks."agent:test:code:integration"]
# see also: "test:code:integration"
# `--test-threads 1` because integration tests must be run sequentially
run = [{ task = "test:code", args = ["--cargo-quiet", "--show-progress", "none", "--no-input-handler", "--status-level", "fail", "--final-status-level", "flaky", "--ignore-default-filter", "--max-fail", "1", "--test-threads", "1", "integration_tests::"] }]

[tasks."agent:test:code:slow"]
# see also: "test:code:slow"
# `--test-threads` is omitted because slow tests may be run in parallel
run = [{ task = "test:code", args = ["--cargo-quiet", "--show-progress", "none", "--no-input-handler", "--status-level", "fail", "--final-status-level", "flaky", "--ignore-default-filter", "--max-fail", "1", "slow_tests::"] }]
```

### fnox.toml

```toml
#:schema https://fnox.jdx.dev/schema.json

if_missing = "error"
env = "exec"

[providers]
keychain = { type = "keychain", service = "rust-private-lib-template" }
pass = { type = "password-store", prefix = "rust-private-lib-template/" }
age = { type = "age", recipients = [
    "age1sf4r4amev2svqr6llwg8hgtz9n7p5qdh7hh0mavcshzfrmgfduksnq3hql",
    "age1605gsnxpe536sprwccyumq74veg0g80u55n8ggems0t8deau6qdsfnq3m3"
] }
```

### Cargo.toml

```toml
[workspace]
resolver = "3"

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.93.1"
homepage = "https://github.com/DenisGorbachev/rust-private-lib-template"
repository = "https://github.com/DenisGorbachev/rust-private-lib-template"
keywords = []
categories = []
exclude = [
    ".*",
    "*.local.*",
    "doc/dev",
    "specs",
    "AGENTS.ts",
    "CargoMetadata.ts",
    "README.ts",
    "AGENTS*.md",
    "CLAUDE*.md",
    "deno.lock",
    "deno.json",
    "clippy.toml",
    "commitlint.config.mjs",
    "fnox.toml",
    "mise.toml",
    "rumdl.toml",
    "shuck.toml",
    "rustfmt.toml",
    "rust-toolchain.toml",
    "skills-lock.json",
    ".yolobox"
]

[workspace.metadata.details]
name = "rust-private-lib-template"
title = "Rust private template"
readme = { generate = false }

[workspace.lints.rust]
redundant_imports = "deny"
unused_import_braces = "deny"
# unused_qualifications must not be "deny" because our code style has multiple `use Foo::*;`, and some macros (derive_more::Display, strum::Display, strum::EnumString) produce code with full qualifications
# unused_qualifications = "deny"

[workspace.lints.clippy]
absolute_paths = "deny"
arithmetic_side_effects = "deny"

[package]
name = "rust-private-lib-template"
version.workspace = true
edition.workspace = true
rust-version.workspace = true
description = "A template for creating Rust private repositories."
homepage.workspace = true
repository.workspace = true
keywords.workspace = true
categories.workspace = true
exclude.workspace = true

[package.metadata.details]
title = "Rust private template"

[lints]
workspace = true

[dependencies]
derive-getters = { version = "0.5.0", features = ["auto_copy_getters"] }
derive-new = "0.7.0"
derive_more = { version = "2.1.1", features = ["full"] }
errgonomic = { git = "https://github.com/DenisGorbachev/errgonomic" }
itertools = "0.14.0"
standard-traits = { git = "https://github.com/DenisGorbachev/standard-traits" }
strum = { version = "0.27.2", features = ["derive"] }
stub-macro = { version = "0.2.1" }
subtype = { git = "https://github.com/DenisGorbachev/subtype" }
```

### src/lib.rs

```rust
//! This is a module-level comment for a Rust lib
```
