# Concepts

## Concept

A struct with fields:

- [Name](#name).
- [Def](#def).
- [Aliases](#aliases).
- [Examples](#examples).
- [Reqs](#reqs).
- [Allowances](#allowances).
- [Prefs](#prefs).
- [Ctors](#ctors).
- [Properties](#properties).
- [Notes](#notes).
- [Custom sections](#custom-sections).

Examples:

- A def of a Rust pkg.
- A def of a Rust fn.

## Name

A string that uniquely identifies item within its scope.

## Def

An optional string that defines a concept.

Prefs:

- Should end with a period.

Allowances:

- May start with an article ("A", "An", "The").
- May start with name of concept being defined.
- May be a multiline string.

## Aliases

An optional list of strings that represent alternative names for a concept.

## Examples

An optional [listmap](#listmap) of [examples](#example).

Prefs:

- Should be non-exhaustive.
- If listmap is exhaustive, move it to "[Ctors](#ctors)".

Notes:

- Markdown doc may contain sections whose headings start with "Examples" but are not exactly "Examples". Treat these sections as related to, but distinct from, examples of a concept.
  - Examples:
    - "Examples of names".
    - "Examples of calls".
    - "Examples of hashes".

## Reqs

An optional [listmap](#listmap) of [reqs](#req).

## Allowances

An optional [listmap](#listmap) of [allowances](#allowance).

## Prefs

An optional [listmap](#listmap) of [prefs](#pref).

## Ctors

An optional list of [ctors](#ctor) that contains all possible ctors of a concept.

Aliases: "One of".

## Properties

An optional [listmap](#listmap) of [properties](#property).

## Notes

An optional [listmap](#listmap) of [notes](#note).

## Custom sections

An optional [listmap](#listmap) of [listmaps](#listmap) of [notes](#note).

## Example

A [stringtree](#stringtree) that [represents](#representation) an instance of a parent object.

Notes:

- Corresponds to a specific instance of a type in a [dependently typed lang](#dependently-typed-lang).

## Req

A [stringtree](#stringtree) that [represents](#representation) a bool test of an instance of a parent object.

Notes:

- Corresponds to a predicate in a [dependently typed lang](#dependently-typed-lang).
- If an input doesn't pass req test, it is not an instance of a parent object.

## Allowance

A [stringtree](#stringtree) that [represents](#representation) a non-req (a lack of constraint).

Examples:

- "May access external APIs".

## Pref

A [stringtree](#stringtree) that [represents](#representation) a less-than-or-equal relation on a pair of instances of a parent object.

Notes:

- Prefs must be sorted by importance (most important first).
- Prefs should be used to make a choice between two inputs that pass [reqs](#req).

## Ctor

A string that represents a ctor of a type.

- Corresponds to a ctor in a [dependently typed lang](#dependently-typed-lang).

## Property

A [stringtree](#stringtree) that [represents](#representation) a property of an instance of a parent object.

Notes:

- Corresponds to a theorem in a [dependently typed lang](#dependently-typed-lang).

## Note

A [stringtree](#stringtree) that [represents](#representation) additional information about a parent object.

## Method spec

A struct with fields:

- [Name](#name).
- Reqs (optional [listmap](#listmap) of [reqs](#req)).
- Prefs (optional [listmap](#listmap) of [prefs](#pref)).
- Properties (optional [listmap](#listmap) of [properties](#property)).
- Notes (optional [listmap](#listmap) of [notes](#note)).
- Must have methods:
  - `to_markdown`:
    - Reqs:
      - Must output a list where top-level items correspond to struct fields.

## Concepts doc

A Markdown doc that presents a list of [concepts](#concept) with elements:

- Heading level 1: doc name that starts with "Concepts".
- For each concept:
  - Name: heading level 2.
  - Def: paragraph after heading.
  - Other fields:
    - Paragraph that is exactly equal to field name with ":" at end.
    - Field value:
      - If field type has a `to_markdown` method, call it; else: render most direct representation (e.g.: render strings directly).

Reqs:

- Order of other fields in doc must match order of other fields in def of [concept](#concept).
- A field must not appear twice.
- If field is empty, it must not be rendered.
- Every code item name and single-line code snippet must be rendered in single backticks.
  - Examples: `u64`, `PrintCommand`, `to_markdown`, `impl From<A> for B`.

## Listmap

A listmap of type A is one of:

- A list of values of type A.
- A map from [names](#name) to values of type A.

Reqs:

- Must have methods:
  - `to_markdown`:
    - Reqs:
      - If value is a list, must output a Markdown list; else: must output a Markdown list where each item is rendered as `{key}: {value}`.

Notes:

- If a listmap is a map, its iteration order is insertion order of keys as they appear in source text.

## Stringtree

A stringtree is a struct with fields:

- Text (string).
- Children (a list of stringtrees).
- Must have methods:
  - `to_markdown`:
    - Reqs:
      - Must output a multi-level Markdown list.
        - "Text" field must be rendered as top-level list item.
        - "Children" field must be rendered as child list items.

## Representation

A string that passes an [association test](#association-test) evaluated by a specific list of [agents](#agent).

Notes:

- List of agents is an external input to a program that evaluates concept doc.

## Association test

A fn from two strings to a bool.

Aliases: is-test.

Examples:

- `is("cow", "animal") == true`.
- `is("function", "relation") == true`.
- `is("war", "peace") == false`.
- `is("slavery", "freedom") == false`.
- `is("love", "good") == true`.

Notes:

- May represent a term-type relation ("cow" has type "animal").
- May represent a subtype-supertype relation ("function" is a subtype of "relation").
- May represent a term-predicate relation ("leaf" is "green").
- System prompt for association testing by LLMs: "Evaluate whether the statement in the user message is true or false in general".

## Agent

An entity whose goal is to prevent its own termination.

## Dependently typed lang

A programming lang that supports dependent types.

Aliases: DTL.

Examples:

- Lean.
- Agda.
- Gallina (Rocq prover).
