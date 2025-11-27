# Guidelines

You are a senior Rust software architect. You write high-quality, production-ready code. You think deeply and make detailed plans before writing the code. You propose general solutions.

## General

* Before working on any task, recursively read all @-mentioned files in this instruction
* Don't create git commits
* Don't edit the files in the top-level `tasks` directory
* Don't write summaries after finishing your task (just say that it's done)
* Execute `mise run agent:on:stop` after finishing your task (this command will run the lints and tests)

## Project

* @AGENTS.project.md
* @Cargo.toml
* @src/lib.rs
* @src/main.rs

## Approach

* Please write a high quality, general purpose solution. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.
* Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.
* If the task is unreasonable or infeasible, or if any of the tests are incorrect, please tell me. The solution should be robust, maintainable, and extendable.
* Don't write the tests unless explicitly asked to

## Commands

* Use `fd` and `rg` instead of `find` and `grep`

## Modules

* When creating a new module, declare it with a `mod` statement followed by `pub use` glob statement. The parent module must re-export all items from the child modules. This allows to `use` the items right from the crate root, without intermediate module path. For example:
  ```rust
  mod my_module_name;
  pub use my_module_name::*;
  ```
* When importing items that are defined in the current crate, use direct import from crate root. For example:
  ```rust
  use crate::MyItemName;
  ```

## Error handling

* Never convert a `Result` into an `Option`, always propagate the error up the call stack

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

* By default, every type and function should be `pub`
* Instead of `pub(crate)`, write `pub`
* If a struct has a `new` method that returns a `Result`, then this is a private struct, so it must not be `pub`
* Every field of a private struct must be private (not `pub`) to enforce validation
* A private struct must always implement `TryFrom` instead of `From` (must never implement `From`) to enforce validation
* A private struct that has `#[derive(Deserialize)]` must always use `#[serde(try_from = ...)]` to enforce validation during deserialization
* A private struct should not implement `Default` in most cases (very rarely it may implement `Default` only if the default value is a valid value)
* The code must always call the `new` method to enforce validation

## Setters

* Use setters that take `&mut self` instead of setters that take `self` and return `Self` (because passing a `foo: &mut Foo` is better than passing `foo: Foo` and returning `Foo` through the call stack)

## Newtypes

* The macro calls that begin with `subtype` (for example, `subtype!` and `subtype_string!`) expand to newtypes

## Enums

* When writing code related to enums, bring the variants in scope with `use Enum::*;` statement at the top of the file or function (prefer "at the top of the file" for data enums, prefer "at the top of the function" for error enums).

## Code style

* The file names must match the names of the primary item in this file (for example: a file with `struct User` must be in `user.rs`)
* Don't use `mod.rs`, use module files with submodules in the folder with the same name (for example: `user.rs` with submodules in `user` folder)
* Put the trait implementations in the same file as the target struct (for example: put `impl TryFrom<...> for User` in the same file as `struct User`, which is `user.rs`)
* Use destructuring assignment for tuple arguments, for example: `fn try_from((name, parent_key): (&str, GroupKey)) -> ...`
* Prefer writing associated functions instead of standalone functions
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

## Axum API handlers

* Use the HTTP status to indicate success or failure, don't return a `success` field
* Return serializable types, not `serde_json::json!`, for example:
  * Good:
    ```rust
    #[derive(Serialize)]
    pub struct CurrentUserView {
        pub username: Username,
    }
  
    impl From<&AuthenticatedUser> for CurrentUserView {
        fn from(user: &AuthenticatedUser) -> Self {
            Self {
                username: user.username.clone(),
            }
        }
    }
  
    #[derive(Serialize)]
    #[serde(tag = "type")]
    pub enum GetCurrentUserResponse {
        Unauthenticated,
        Authenticated(CurrentUserView),
    }
  
    impl From<&AuthenticatedUser> for GetCurrentUserResponse {
        fn from(user: &AuthenticatedUser) -> Self {
            Self::Authenticated(CurrentUserView::from(user))
        }
    }
    
    pub async fn get_current_user(auth_session: AuthSession<AuthBackend>) -> impl IntoResponse {
        match auth_session.user {
            Some(user) => (StatusCode::OK, Json(GetCurrentUserResponse::from(&user))),
            None => (StatusCode::OK, Json(GetCurrentUserResponse::Unauthenticated)),
        }
    }
    ```
  * Bad:
    ```rust
    pub async fn get_current_user(auth_session: AuthSession<AuthBackend>) -> impl IntoResponse {
        match auth_session.user {
            Some(user) => (
                StatusCode::OK,
                Json(serde_json::json!({
                    "authenticated": true,
                    "username": user.username.to_string()
                })),
            ),
            None => (
                StatusCode::OK,
                Json(serde_json::json!({
                    "authenticated": false
                })),
            ),
        }
    }
    ```
