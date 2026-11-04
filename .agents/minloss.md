# Defs

## Project

A dir with source code or [auxiliary](#auxiliary-file) files.

## Metric

A fn from an object to a quantitative value.

Examples:

- Peak RSS memory usage of a program.
- Average wall-clock time of running a program on a specific set of inputs for a specific number of iterations.
- Count of CLI options.
- Count of lines of code.

## Project metric

A [metric](#metric) of a [project](#project).

Examples:

- Test coverage.
- Test suite wall-clock running time (averaged across N runs with a warmed-up cache).
- Compilation time.

## Program metric

A [metric](#metric) of a program.

Examples:

- Peak RSS memory usage.
- Wall clock running time (averaged across N runs with a warmed-up cache).

## Stat

A struct where every field is a [metric](#metric).

Notes:

- Given an input set of objects and a fn from objects to stats, it is possible to calculate a Pareto front of objects.
  - Objects that are inferior to Pareto front objects should be discarded.

## Auxiliary file

A file that doesn't contain a program but is used indirectly when building a program.

Examples:

- Pkg manager config.
- Linter config.
- Agent ctx file.

## High-level spec

A string that can be interpreted as a struct with fields:

- `frontends` (a list of [frontend APIs](#frontend-api)).
- `backends` (a list of [backend APIs](#backend-api)).
- `audience` (a string that describes a list of [agents](#agent)).

Examples:

- "A Fjall db CLI for developers":
  - `frontends` includes stdio API (stdin, stdout, stderr) and shell API (e.g.: escape codes).
  - `backends` includes Fjall API and filesystem API.
  - `audience` includes developers.

## Rust fn

Prefs:

- Should not use [optimization hacks](#optimization-hack).

## Ctor of type T

A fn whose return type mentions `T`.

Examples:

- `fn foo(a: A, b: B) -> Result<K, M>` is a producer of `Result`, `K`, `M`.

## Direct ctor of type T

A [ctor](#ctor-of-type-t) whose return type is exactly `T`.

## Most explicit ctor of type T

A [ctor](#ctor-of-type-t) that allows callers to set more fields than other ctors of same type.

Reqs:

- If it doesn't produce side effects, must be named `new`; else: must be named `create`.

## Producing expr of type T

An expr whose return type mentions `T`.

Synonyms: ProdExp.

Examples:

- `UserBuilder::default().name("Alice").build()?` is a ProdExp of `User`.
- `Database::new(config)?` is a ProdExp of `Database`.

Reqs:

- Must set all [relevant fields](#relevant-field).
  - Notes:
    - Should use most explicit ctor.
    - Config values have a [config struct](#config-struct) type.
- Must not set any [irrelevant fields](#irrelevant-field).
- Must not use naive types that omit crucial data.
  - Examples:
    - Must not use `NaiveDateTime`, which omits timezone data.

Prefs:

- Should rely on `impl Into` to reduce code size.
  - Examples:
    - `Article::new`:
      - Ctor: `impl Article { pub fn new(title: impl Into<String>, text: impl Into<String>) -> Self { ... } }`.
      - ProdExp:
        - Bad: `Article::new("Title".to_string(), "Text".to_string())` (bad because it explicitly converts `str` to `String` using `to_string`).
        - Good: `Article::new("Title", "Text")` (good because it relies on `impl Into`).

Notes:

- When parsing a date without a timezone, don't assume UTC unless spec explicitly requires it.

## Param of a producing expr of type T

A var that is passed into [producing expr of type T](#producing-expr-of-type-t).

## Relevant field

A field of a struct is relevant for effect E if effect E depends on value of that field.

Examples:

- `/books/update` API call:
  - `id` query param is relevant because it influences effect of updating book (determines which book to update).
  - `Cookie` header is irrelevant because it doesn't influence effect of updating book (setting this header has no effect).

## Irrelevant field

A field of a struct that is not [relevant](#relevant-field) for effect E.

## Config struct

A struct that contains config params.

Reqs:

- Must have a `Default` impl.
  - For each param:
    - If it can't have a default value:
      - Then:
        - Must not be in config struct.
        - Must be accepted as a required arg.
- Must implement `Serialize` and `Deserialize` from `serde`.

Prefs:

- Should be produced by `figment` crate.

## Frontend-facing fn

A Rust fn that calls a [frontend API](#frontend-api).

Prefs:

- Should be [reversible](#reversible-fn), unless it is expected by user to be irreversible.
  - Examples of fns that are expected to be irreversible:
    - `FileDeleteCommand::run` (user explicitly types "delete" when invoking this cmd).
  - Examples of fns that are expected to be reversible:
    - `FileShowCommand::run` (user does not type any destructive words when invoking this cmd).
- If it is irreversible, should be [atomic](#atomic-fn).

## Internal fn

A Rust fn defined in current crate.

## External fn

A Rust fn imported from an external crate.

## Frontend API

An API that program calls to read user input or write output for user.

Examples:

- Terminal emulator API.
- Shell API.
- Browser API.
- Filesystem API (can be a frontend API if it is used to read or write user-provided files).

## Backend API

An API that program calls to read or write parts of state that are not explicit inputs or outputs.

Examples:

- Filesystem API (can be a backend API if it is used to read or write internal state).
- Db API.

## Reversible fn

A Rust fn whose effect can be reversed.

Notes:

- Formal def: Rust fn `f` is reversible if there exists a Rust fn `g` that takes output of `f` as input so that when `f` and `g` are executed sequentially, [extended state](#extended-state) of program is not modified.

## Irreversible fn

A Rust fn that is not [reversible](#reversible-fn).

## Atomic fn

A Rust fn whose effects are either applied completely or not at all.

Examples:

- A fn that wraps db ops in a transaction.
- A fn that writes to a temp file and then atomically replaces old file with new file (on filesystems that support atomic renames).

## Fallible fn

A Rust fn that returns a `Result`.

## Partial fn

A Rust fn that returns an `Option`.

## Private struct

A struct that has only partial or fallible ctors.

Reqs:

- Must enforce validation:
  - Must not have `pub` fields.
  - Must implement `TryFrom` instead of `From`.
  - If it has `#[derive(Deserialize)]`, must have `#[serde(try_from = ...)]` to enforce validation during deserialization.

Prefs:

- Should not implement `Default` in most cases (very rarely, it may implement `Default` if default value is a valid value).

## Input data type

A type that contains fields that hold input data.

Examples:

- `Author` (contains `name` that is provided as input data).
- `Book` (contains `name` that is provided as input data).
- `AuthorBook` (contains `author_id` and `book_id` that are provided as input data).

## Extended state

A state that contains all data that program can read (including memory, disks, dbs, remote APIs).

## Input source

Original location of data that is held by input var (where program has read it from).

Examples:

- Config file.
- HTTP request.
- Program args (`argv`).
- Standard input (`stdin`).
- Env (`env`).

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

An entity that is assumed to be working towards a specific goal.

## User time loss expectation

A mathematical expectation of amount of time that it takes user to reach a specific desirable state.

Notes:

- If product is a program, this amount of time includes execution time plus launch time (e.g.: typing CLI args, filling GUI forms).

TODO:

- Make this def more precise.

## Optimization hack

An optimization that relies on a property that cannot be assumed to hold in future.

Examples:

- An optimization that relies on an impl detail in a dep (impl details are not a part of public interface).

## Monomial

An algebraic expr that is a product of vars raised to specific powers.

Examples:

- `1` (a monomial where every var has a power of zero).
- `a^2`.
- `a * b * c^-1` (a monomial equiv to `(a * b) / c`).
