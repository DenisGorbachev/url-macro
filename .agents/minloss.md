# Definitions

## Project

Directory with source code or [auxiliary](#auxiliary-file) files.

## Metric

Function from object to quantitative value.

Examples:

- Peak RSS memory usage of program.
- Average wall-clock time of running program on specific set of inputs for specific number of iterations.
- Count of CLI options.
- Count of lines of code.

Notes:

- Set of metrics depends on object type.

## Project metric

[metric](#metric) of [project](#project).

Examples:

- Test coverage.
- Test suite wall-clock running time (averaged across N runs with warmed-up cache).
- Compilation time.

## Program metric

[metric](#metric) of program.

Examples:

- Peak RSS memory usage.
- Wall clock running time (averaged across N runs with warmed-up cache).

## Stat

Structure where every field is [metric](#metric).

Notes:

- Given input set of objects and function from objects to stats, it is possible to calculate Pareto front of objects.
  - Objects that are inferior to Pareto front objects should be discarded.

## Auxiliary file

File that doesn't contain program but is used indirectly when building program.

Examples:

- Package manager config.
- Linter config.
- Agent context file.

## High-level specification

String that can be interpreted as struct with fields:

- `frontends` (list of [frontend APIs](#frontend-api)).
- `backends` (list of [backend APIs](#backend-api)).
- `audience` (string that describes list of [agents](#agent)).

Examples:

- "A Fjall database CLI for developers":
  - `frontends` includes stdio API (stdin, stdout, stderr) and shell API (e.g.: escape codes).
  - `backends` includes Fjall API and filesystem API.
  - `audience` includes developers.

## Rust fn

Preferences:

- Should not use [optimization hacks](#optimization-hack).

## Constructor of type T

Function whose return type mentions `T`.

Examples:

- `fn foo(a: A, b: B) -> Result<K, M>` is producer of `Result`, `K`, `M`.

## Direct constructor of type T

[constructor](#constructor-of-type-t) whose return type is exactly `T`.

## Most explicit constructor of type T

[constructor](#constructor-of-type-t) that allows callers to set more fields than other constructors of same type.

Requirements:

- If it doesn't produce side effects:
  - Then: must be named `new`.
  - Else: must be named `create`.

## Producing expression of type T

Expression whose return type mentions `T`.

Synonyms: ProdExp.

Examples:

- `UserBuilder::default().name("Alice").build()?` is ProdExp of `User`.
- `Database::new(config)?` is ProdExp of `Database`.

Requirements:

- Must set all [relevant fields](#relevant-field).
  - Notes:
    - Should use most explicit constructor.
    - Config values have [config struct](#config-struct) type.
- Must not set any [irrelevant fields](#irrelevant-field).
- Must not use naive types that omit crucial data.
  - Examples:
    - Must not use `NaiveDateTime`, which omits timezone data.

Preferences:

- Should rely on `impl Into` to reduce code size.
  - Examples:
    - `Article::new`:
      - Constructor: `impl Article { pub fn new(title: impl Into<String>, text: impl Into<String>) -> Self { ... } }`.
      - ProdExp:
        - Bad: `Article::new("Title".to_string(), "Text".to_string())` (bad because it explicitly converts `str` to `String` using `to_string`).
        - Good: `Article::new("Title", "Text")` (good because it relies on `impl Into`).

Notes:

- When parsing date without timezone, don't assume UTC unless specification explicitly requires it.

## Parameter of producing expression of type T

Variable that is passed into [producing expression of type T](#producing-expression-of-type-t).

## Relevant field

Field of struct is relevant for effect E if effect E depends on value of that field.

Examples:

- `/books/update` API call:
  - `id` query parameter is relevant because it influences effect of updating book (determines which book to update).
  - `Cookie` header is irrelevant because it doesn't influence effect of updating book (setting this header has no effect).

## Irrelevant field

Field of struct that is not [relevant](#relevant-field) for effect E.

## Config struct

Struct that contains configuration parameters.

Requirements:

- Must have `Default` impl.
  - For each parameter:
    - If it can't have default value:
      - Then:
        - Must not be in config struct.
        - Must be accepted as required argument.
- Must implement `Serialize` and `Deserialize` from `serde`.

Preferences:

- Should be produced by `figment` crate.

## Frontend-facing fn

Rust fn that calls [frontend API](#frontend-api).

Preferences:

- Should be [reversible](#reversible-fn), unless it is expected by user to be irreversible.
  - Examples of fns that are expected to be irreversible:
    - `FileDeleteCommand::run` (user explicitly types "delete" when invoking this command).
  - Examples of fns that are expected to be reversible:
    - `FileShowCommand::run` (user does not type any destructive words when invoking this command).
- If it is irreversible:
  - Then: should be [atomic](#atomic-fn).

## Internal fn

Rust fn defined in current crate.

## External fn

Rust fn imported from external crate.

## Frontend API

API that program calls to read user input or write output for user.

Examples:

- Terminal emulator API.
- Shell API.
- Browser API.
- Filesystem API (can be frontend API if it is used to read or write user-provided files).

## Backend API

API that program calls to read or write parts of state that are not explicit inputs or outputs.

Examples:

- Filesystem API (can be backend API if it is used to read or write internal state).
- Database API.

## Reversible fn

Rust fn whose effect can be reversed.

Properties:

- Some fns that take arguments only by reference are irreversible.
  - Example:
    - `remove_file` that takes `&Path` and removes file.
- Some reversible fns call irreversible fns.
  - Example:
    - `remove_file_with_backup` that makes backup of file before removing it.
- Every read-only fn is reversible because it has no effects.

Notes:

- Formal definition: Rust fn `f` is reversible if there exists Rust fn `g` that takes output of `f` as input so that when `f` and `g` are executed sequentially, [extended state](#extended-state) of program is not modified.

## Irreversible fn

Rust fn that is not [reversible](#reversible-fn).

## Atomic fn

Rust fn whose effects are either applied completely or not at all.

Examples:

- Function that wraps database operations in transaction.
- Function that writes to temp file and then atomically replaces old file with new file (on filesystems that support atomic renames).

## Fallible fn

Rust fn that returns `Result`.

## Partial fn

Rust fn that returns `Option`.

## Private struct

Struct that has only partial or fallible constructors.

Requirements:

- Must enforce validation:
  - Must not have `pub` fields.
  - Must implement `TryFrom` instead of `From` (must not implement `From`).
  - If it has `#[derive(Deserialize)]`:
    - Then: must have `#[serde(try_from = ...)]` to enforce validation during deserialization.

Preferences:

- Should not implement `Default` in most cases (very rarely, it may implement `Default` if default value is valid value).

## Input data type

Type that contains fields that hold input data.

Examples:

- `Author` (contains `name` that is provided as input data).
- `Book` (contains `name` that is provided as input data).
- `AuthorBook` (contains `author_id` and `book_id` that are provided as input data).

## Extended state

State that contains all data that program can read (including memory, disks, databases, remote APIs).

## Input source

Original location of data that is held by input variable (where program has read it from).

Examples:

- Configuration file.
- HTTP request.
- Program arguments (`argv`).
- Standard input (`stdin`).
- Environment (`env`).

## Software resources

- Processor:
  - CPU (speed).
  - GPU (speed).
  - Remote server processor (speed).
- Memory:
  - RAM (capacity, speed).
  - GPU memory (capacity, speed).
  - Disk (capacity, speed).
  - Remote server storage (speed).
- Rate limits on external APIs.

## Agent

Entity that is assumed to be working towards specific goal.

Notes:

- This definition is intentionally broad.
- This definition includes both humans and programs.
- Distinction between "active" and "passive" programs is false dichotomy: even operating system can be seen as passive program that responds to external input from internal hardware clock.

## User time loss expectation

Mathematical expectation of amount of time that it takes user to reach specific desirable state.

Notes:

- If product is program:
  - Then: this amount of time includes execution time plus launch time (e.g.: typing CLI arguments, filling GUI forms).

TODO:

- Make this definition more precise.
  - Notes:
    - User loses some time initially because they need to read docs, then install and configure program.
    - User saves time because program can execute certain actions faster (same actions that would be done by user manually).
    - User saves time because program prevents undesirable actions which could have been executed by user (mistakes).
    - User saves time because program prevents undesirable actions which could have been executed by other agents (hacks).
      - Examples:
        - ERC-20 contract prevents other actors from increasing token supply.

## Optimization hack

Optimization that relies on property that cannot be assumed to hold in future.

Examples:

- Optimization that relies on implementation detail in dependency (this property cannot be assumed to hold in future because implementation details are not part of public interface and may change without notice).

## Monomial

Algebraic expression that is product of variables raised to specific powers.

Examples:

- `1` (monomial where every variable has power of zero).
- `a^2`.
- `a * b * c^-1` (monomial equivalent to `(a * b) / c`).
