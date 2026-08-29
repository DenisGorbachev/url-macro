# General

You are a senior Rust software architect.

- Think deeply and make detailed plans before writing the code.
- Write high-quality, production-ready, generic, reusable code.

## Principles

Write code that minimizes losses:

- [Avoid data loss](#avoid-data-loss).
- [Minimize hardcoded data](#minimize-hardcoded-data).
- Minimize the memory consumption.
- Minimize the execution time.

### Avoid data loss

- Don't use panicking functions (instead, use checked functions that return a `Result`)
- Don't delete the data or drop the values unless the specification explicitly requires it
- Every internal function that drops the values or directly calls a function that deletes the data (according to specification) must have a doc comment with the following properties:
  - Must start with "/// PRUNING: "
  - Must describe what exactly this function drops or deletes
  - Must explain why this is required

Notes:

- A specification may require dropping some fields of the input if these fields are irrelevant to user goal.

### Minimize hardcoded data

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

## Development workflow

- After finishing the task: run `mise run agent:on:stop` (this command runs the lints and tests)
  - `mise run agent:on:stop` may modify `README.md`, `AGENTS.md`, `Cargo.toml` (this is normal, don't mention it)
  - `mise run agent:on:stop` includes `cargo fmt`, `cargo check`, `cargo clippy`, `cargo nextest` (no need to run them separately)
- After finishing the original task, improve the code:
  - Remove unnecessary code
  - Remove unnecessary allocations
  - Refactor code that converts between types into `From` / `Into` impls
- Don't write the tests
- Don't edit the files in the following top-level dirs: `specs`, `.agents`
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
- If the task can't be completed exactly as it is written (for example, due to limitations in the language or dependencies, or due to incorrect assumptions in the specification), append an item to [`findings.md`](#findingsmd) with priority `P0`.
- If unexpected behavior impedes your progress, but it's not a blocker (for example: domain is unavailable, program is unavailable, available memory or disk space is too low, command runs for unexpectedly long time or consumes an unexpected amount of resources), append an item to [`findings.md`](#findingsmd) with priority `P2`.
- If the task is technically possible but would result in low quality code, then don't write the code, but reply with an explanation. If there is an alternative solution that is clearly better, then implement it.
  - Examples
    - A task to write `impl From<Foo> for Bar` where `Foo` can't actually be infallibly converted to `Bar` (would require calling `unwrap`, which is bad) - in this case you should write `impl TryFrom<Foo> for Bar` and reply with "Foo can't be infallibly converted to Bar, so I implemented a fallible conversion instead".
    - A task to write a trait impl that only returns an error - in this case you should not write the trait impl but reply with "trait X can't be implemented for Foo because ..."
- If a sentence starts with "Idea: ":
  - Evaluate it thorougly.
  - If you agree:
    - Then: implement it.
    - Else: explain why you didn't implement it and brainstorm solutions.
- If you resolve the findings, remove them from [findings.md](#findingsmd)
  - If [findings.md](#findingsmd) becomes empty, remove it

## Review workflow

- Output a full list of [findings](#finding) (not a shortlist)
- If there are no findings, then start your reply with "No findings"
- If I reply to your review with an ordered list, process each item in the following way:
  - "+" - "Think about this finding again, then apply the best fix according to your thinking process"
  - "+ {number}" - "Apply proposed fix at {number}"
  - "-" - "Don't apply any fixes"
  - other - respond normally (keep the `ctid` in your response)
- If there are no more actionable items in the thread identified by a specific `ctid`: drop this `ctid` from your response.

## Debugging workflow

- Improve error handling, so that the root cause is clearly visible

## Subagents

- When spawning a code review subagent: use fresh context (not inherited).

## Messages from agent to user

- Use `~` in paths
- Format your message as a sequence of independently addressable items where each item begins with a [chat thread id heading](#chat-thread-id-heading)
- Don't mention successful verifications and checks unless asked explicitly.

## Commands

- Use `fd` and `rg` instead of `find` and `grep`
- Set the command-execution tool call’s timeout parameter and `yield_time_ms` to at least 300000 ms for the following commands: `mise run agent:on:stop`, `cargo build`, `git commit`

## Recommended crates

- `errgonomic` for error handling
- `strum` for enum derives
- `subtype` for defining newtypes
- `tempfile` for creating temp dirs or files

## Files

- The file name must match the name of the primary item in this file (for example: a file with `struct User` must be named `user.rs`)
- The trait implementations must be in the same file as the target type (for example: put `impl TryFrom<...> for User` in the same file as `struct User`, which is `user.rs`)

## Modules

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

## Visibility

- Items:
  - Prefer `pub` instead of `pub(crate)` or private.
- Fields:
  - If a struct is a refinement of its fields:
    - Then: its fields must be private, and the functions that construct, deserialize, mutate fields must preserve the invariant.
    - Else: its fields must be `pub`.

## Constants

- Define constants only for values used in multiple places (prefer inline values)
- Put constants in `src/constants.rs`

## Types

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

## Functions

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

## Struct derives

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

## Setters

- Use setters that take `&mut self` instead of setters that take `self` and return `Self` (because passing a `foo: &mut Foo` is more efficient than passing `foo: Foo` and returning `Foo` through the call stack)

## Enums

- When writing code related to enums, bring the variants in scope with `use Enum::*;` statement at the top of the file or function (prefer "at the top of the file" for data enums, prefer "at the top of the function" for error enums).

## Arithmetics

- Don't use the impls of traits `core::ops::{Add, AddAssign, Sub, SubAssign, Mul, MulAssign, Div, DivAssign, Rem, RemAssign, Neg, Shl, ShlAssign, Shr, ShrAssign}` or their operators unless they don't panic or silently overflow
- Write and use arithmetic trait impls that don't panic or silently overflow
- Prefer `checked` versions of arithmetic operations
- Every call to an `overflowing`, `saturating`, `wrapping` version must have a single-line comment above it that starts with "SAFETY: " and describes why calling this version is safe in this specific case
- Use `num` crate items if necessary (for example, to implement a function that calls arithmetic methods on a generic type)

## Index access

- Never use the following operators: `[], []=`
- Never use the following traits: `core::ops::{Index, IndexMut}`
- If you are sure that `get` or `get_mut` will never panic, use `expect` with a proof message (as described in [Functions](#functions))

Note: the index access operators and traits are banned because they may panic.

## Test fn

A function marked with `#[test]` or `#[tokio::test]`.

- Must return a `Result`
- Must implement proper error handling via `errgonomic` crate
- Should use macros from `assertables` crate
  - Should use `assert_infix` instead of `assert_gt`, `assert_ge`, `assert_lt`, `assert_le`, `assert_eq`

## Macros

- Write `macro_rules!` macros to reduce boilerplate
- If you see similar code in different places, write a macro and replace the similar code with a macro call
- If the macros has variadic args:
  - Then: do add `$(,)?`
  - Else: don't add `$(,)?`

## Shell

- Don't use hard wraps to enforce max line length (I'll use soft wraps in my editor)
- If a command is an argument of a tool call:
  - Then:
    - Prefer short options
  - Else:
    - If it's a common command (one of: set, cd, cp, mv, rm, mkdir, ls, ln, chmod, chown):
      - Then:
        - Prefer short options
      - Else
        - Prefer long options
    - Prefer `echo` instead of `printf`

## Cargo.toml

- Don't define package features with only a single optional dependency (such features are already defined by cargo automatically)
- Use `cargo add` to add dependencies
- If the package is [publishable](#publishable-package): use `cargo add {dependency}@{version}` to add a version whose patch component equals 0, then use `cargo update -p {dependency} --precise {version}` to lock that exact version

## Code style

- Don't enforce a line length limit when writing code, comments or documentation

## Chat thread id

- Must be a string
- Must contain at least 3 characters
- Must contain only uppercase characters

Examples:

- `RVC`
- `AKE`
- `LMY`

Notes:

- Should match the thread topic

## Chat thread id heading

A Markdown heading level 3 that contains only [chat thread id](#chat-thread-id).

Examples:

- `### RVC`
- `### AKE`
- `### LMY`

## findings.md

- If it exists:
  - Must contain a non-empty list of [findings](#finding)

## Finding

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

## Publishable package

A package that has a remote whose name contains `public` or `pre-public` and ends with `template`.
