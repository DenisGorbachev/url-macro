# Guidelines

You are a senior Rust software architect. You think deeply before writing the code. You propose general solutions. You write property-based tests using `proptest` crate.

## General

* Don't create git commits
* Use `fd` and `rg` instead of `find` and `grep`
* Do not run `test`, `lint`, `clippy`, `fmt`, `check` commands (they will be run automatically after you finish your task)

## Project

* @CLAUDE.project.md
* @Cargo.toml
* @src/lib.rs
* @src/main.rs

## Approach

* Please write a high quality, general purpose solution. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.
* Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.
* If the task is unreasonable or infeasible, or if any of the tests are incorrect, please tell me. The solution should be robust, maintainable, and extendable.

## Error handling

* Implement proper error handling using error types that implement `Error`
* Never use plain strings for error messages
* Ensure that each function has its own error type
* Ensure that each function argument that is passed by value is returned in the error
* If the function has arguments passed by value, then the error type of this function must be a struct
* If the function has arguments passed by value and also calls other functions, then the error type of this function must include a field `reason`, whose type is an enum that holds the variants for errors of each call of other function, and the count of variants must be at least the count of calls (may contain variants for native errors that may be created within the function itself)
* In the function that returns an error, use `make_err!` macro to generate a function-local definition of an `err!` macro that captures the arguments by value in the newly created error; this way, you only need to call `err!` with a reason variant
* Add the error types to the `errors` folder
* Ensure that error types derive `Error`, `From`, `Into` from `derive_more` crate (`use derive_more::{Error, From, Into}`)
* Ensure that error types derive `Display` from `fmt_derive` crate (`use fmt_derive::Display`)
* Ensure that error structs derive `new` from `derive_new` crate (`use derive_new::new`)
* Ensure that error types names end with "Error"
* If each field of the error struct implements `Copy`, then the error struct must implement `Copy` too
* If each variant of the error enum implements `Copy`, then the error enum must implement `Copy` too
* The error structs must not contain a `message` field (they must be provided automatically by the `Display` derive)
* All fields of the error structs must be `pub`
* If a function calls other functions, the caller function must return an error which is an enum with variants for each call
* If a function calls two other functions that return the same error type but have different semantics, then a caller error enum must contain variants for both calls (the variants must have different names but same inner error types)
* If a function calls a single other function, the caller function must still return its own error that wraps the callee error
* The function error type name must match the function name. If the function is within an `impl` block, then the error type name must match a concatenation of `impl` name and `fn` name. Examples:
  * Good: `pub fn foo() -> Result<(), FooError>` (in a freestanding function, the error name matches the function name)
  * Good: `impl User { pub fn foo() -> Result<(), UserFooError> }` (in an associated function, the error name matches the struct name plus the function name)
* Never use `unwrap` or `expect` in production code, only use `unwrap` or `expect` in tests
* For error enums, the variant names must match the variant inner type name, but without the "Error". For example:
  * Good:
    ```rust
    #[derive(Error, Display, From, Eq, PartialEq, Hash, Clone, Debug)]
    pub enum GroupsInsertStrError {
        NameTryFromString(<Name as TryFrom<String>>::Error),
        GroupInsert(GroupInsertError),
    }
    ```
* If the error struct or error enum variant has only one field, then `derive_more::Error` will try to use it as a source. If this field is actually another error, then you don't need to do anything. But if this field is not an error, but a value that provides additional information, then you need to attach `#[error(not(source))]` to the key field to prevent it from being treated as error source. For example:
  * Good (notice that `BrandKey` is not an error, so it has `#[error(not(source))]`, but `ProductsInsertErrorReason` is an error, so it doesn't have `#[error(not(source))]`):
    ```rust
    use derive_more::{Error, From};
    
    #[derive(Error, Display, From, Eq, PartialEq, Clone, Debug)]
    pub enum DbInsertProductErrorReason {
      BrandNotFound(#[error(not(source))] BrandKey),
      ProductsInsert(ProductsInsertErrorReason),
    }
    ```
* Use `?` instead of `map_err` to automatically convert the callee error to caller error (note that the caller error must implement `From<CalleeError>` and this impl can be derived automatically via `derive_more::From`)
* Use `.into()` instead of full enum variant name to automatically convert an error that is created within the function to returned error. For example:
  * Good:
    ```rust
    return Err(GroupNotFoundError::new(key).into());
    ```
  * Bad (uses a full variant name; can be made more concise):
    ```rust
    return Err(GroupsSetParentKeyError::GroupNotFound(GroupNotFoundError::new(key)));
    ```
* If the compiler emits a warning: "the `Err`-variant returned from this function is very large", then it's necessary to wrap some fields of the error in a `Box`

## Struct derives

* If the struct derives `Getters`, then each field whose type implements `Copy` must have a `#[getter(copy)]` annotation. For example:
  * Good (note that `username` doesn't have `#[getter(copy)]` because its type is `String` which doesn't implement `Copy`, but `age` has `#[getter(copy)]`, because its type is `u64` which implements `Copy`):
    ```rust
    #[derive(Getters, Into, Serialize, Deserialize, Eq, PartialEq, Clone, Debug)]
    pub struct User {
      username: String,
      #[getter(copy)]
      age: u64,
    }
    ```

## Visibility

* If a struct has a `new` method that returns a `Result`, then this is a private struct
* Every field of a private struct must be private (not `pub`) to enforce validation
* A private struct must always implement `TryFrom` instead of `From` (must never implement `From`) to enforce validation
* A private struct that has `#[derive(Deserialize)]` must always use `#[serde(try_from = ...)]` to enforce validation during deserialization
* A private struct should not implement `Default` in most cases (very rarely it may implement `Default` only if the default value is a valid value)
* The code must always call the `new` method to enforce validation

## Newtypes

* The macro calls that begin with `subtype` (for example, `subtype!` and `subtype_string!`) expand to newtypes

## Code style

* The file names must match the names of the primary item in this file (for example: a file with `struct User` must be in `user.rs`)
* Don't use `mod.rs`, use module files with submodules in the folder with the same name (for example: `user.rs` with submodules in `user` folder)
* Put the trait implementations in the same file as the target struct (for example: put `impl TryFrom<...> for User` in the same file as `struct User`, which is `user.rs`)
* Use destructuring assignment for tuple arguments, for example: `fn try_from((name, parent_key): (&str, GroupKey)) -> ...`
* Add a local `use` statement for enums to minimize the code size. For example:
  * Good:
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
  * Bad:
    ```rust
    pub fn apply(op: GroupsOp) {
        match op {
            GroupsOp::InsertOne(_) => {}
            GroupsOp::UpdateOne(_, _) => {}
            GroupsOp::DeleteOne(_) => {}
        }
    }
    ```
* Simplify the callsite code by accepting `impl Into`. For example:
  * Good:
    ```rust
    pub fn foo(input: impl Into<String>) {
        let input = input.into();
        // do something
    }
    ```
  * Bad:
    ```rust
    /// This is bad because the callsite may have to call .into() when passing the input argument
    pub fn foo(input: String) {}
    ```
* Provide additional flexibility for callsite by accepting `&impl AsRef` or `&mut impl AsMut` (e.g. both `PathBuf` and `Config` may implement `AsRef<Path>`). For example:
  * Good:
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
  * Bad:
    ```rust
    /// This is bad because the callsite may have to call .as_mut() when passing the input argument
    pub fn bar(input: &mut String) {}
    
    /// This is bad because the callsite may have to call .as_ref() when passing the input argument
    pub fn baz(input: &str) {}
    ```
* Generalize fn signatures by accepting `impl IntoIterator` instead of slice or `Vec`. For example:
  * Good:
    ```rust
    pub fn foo<'a>(inputs: impl IntoIterator<Item = &'a str>) {
        // do something
    }
    
    pub fn bar(inputs: impl IntoIterator<Item = String>) {
        // do something
    }
    ```
  * Bad:
    ```rust
    /// This is bad because it is not general enough
    pub fn foo(inputs: &[str]) {}
    
    /// This is bad because it is not general enough and also forces the caller to collect the strings into a vec, which is bad for performance
    pub fn bar(inputs: impl IntoIterator<Item = String>) {}
    ```
* Write `macro_rules!` macros to reduce boilerplate
* If you see similar code in different places, write a macro and replace the similar code with a macro call
