# Concepts

## Concept

Struct with fields:

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

- Def of Rust pkg.
- Def of Rust fn.

## Name

String that uniquely identifies item within its scope.

## Def

Optional string that defines concept.

Prefs:

- Should end with period.

Allowances:

- May start with article ("A", "An", "The").
- May start with name of concept being defined.
- May be multiline string.

## Aliases

Optional list of strings that represent alternative names for concept.

## Examples

Optional [listmap](#listmap) of [examples](#example).

Prefs:

- Should be non-exhaustive.
- If listmap is exhaustive, move it to "[Ctors](#ctors)".

Notes:

- Markdown doc may contain sections whose headings start with "Examples" but are not exactly "Examples". Treat these sections as related to, but distinct from, examples of concept.
  - Examples:
    - "Examples of names".
    - "Examples of calls".
    - "Examples of hashes".

## Reqs

Optional [listmap](#listmap) of [reqs](#req).

## Allowances

Optional [listmap](#listmap) of [allowances](#allowance).

## Prefs

Optional [listmap](#listmap) of [prefs](#pref).

## Ctors

Optional list of [ctors](#ctor) that contains all possible ctors of concept.

Aliases: "One of".

## Properties

Optional [listmap](#listmap) of [properties](#property).

## Notes

Optional [listmap](#listmap) of [notes](#note).

## Custom sections

Optional [listmap](#listmap) of [listmaps](#listmap) of [notes](#note).

## Example

[stringtree](#stringtree) that [represents](#representation) instance of parent object.

Notes:

- Corresponds to specific instance of type in [dependently typed lang](#dependently-typed-lang).

## Req

[stringtree](#stringtree) that [represents](#representation) bool test of instance of parent object.

Notes:

- Corresponds to predicate in [dependently typed lang](#dependently-typed-lang).
- If input doesn't pass req test, it is not instance of parent object.

## Allowance

[stringtree](#stringtree) that [represents](#representation) non-req (lack of constraint).

Examples:

- "May access external APIs".

## Pref

[stringtree](#stringtree) that [represents](#representation) less-than-or-equal relation on pair of instances of parent object.

Notes:

- Prefs must be sorted by importance (most important first).
- Prefs should be used to make choice between two inputs that pass [reqs](#req).

## Ctor

String that represents ctor of type.

- Corresponds to ctor in [dependently typed lang](#dependently-typed-lang).

## Property

[stringtree](#stringtree) that [represents](#representation) property of instance of parent object.

Notes:

- Corresponds to theorem in [dependently typed lang](#dependently-typed-lang).

## Note

[stringtree](#stringtree) that [represents](#representation) additional information about parent object.

## Method spec

Struct with fields:

- [Name](#name).
- Reqs (optional [listmap](#listmap) of [reqs](#req)).
- Prefs (optional [listmap](#listmap) of [prefs](#pref)).
- Properties (optional [listmap](#listmap) of [properties](#property)).
- Notes (optional [listmap](#listmap) of [notes](#note)).
- Must have methods:
  - `to_markdown`:
    - Reqs:
      - Must output list where top-level items correspond to struct fields.

## Concepts doc

Markdown doc that presents list of [concepts](#concept) with elements:

- Heading level 1: doc name that starts with "Concepts".
- For each concept:
  - Name: heading level 2.
  - Def: paragraph after heading.
  - Other fields:
    - Paragraph that is exactly equal to field name with ":" at end.
    - Field value:
      - If field type has `to_markdown` method, call it; else: render most direct representation (e.g.: render strings directly).

Reqs:

- Order of other fields in doc must match order of other fields in def of [concept](#concept).
- Field must not appear twice.
- If field is empty, it must not be rendered.
- Every code item name and single-line code snippet must be rendered in single backticks.
  - Examples: `u64`, `PrintCommand`, `to_markdown`, `impl From<A> for B`.

## Listmap

Listmap of type A is one of:

- List of values of type A.
- Map from [names](#name) to values of type A.

Reqs:

- Must have methods:
  - `to_markdown`:
    - Reqs:
      - If value is list, must output Markdown list; else: must output Markdown list where each item is rendered as `{key}: {value}`.

Notes:

- If listmap is map, its iteration order is insertion order of keys as they appear in source text.

## Stringtree

Stringtree is struct with fields:

- Text (string).
- Children (list of stringtrees).
- Must have methods:
  - `to_markdown`:
    - Reqs:
      - Must output multi-level Markdown list.
        - "Text" field must be rendered as top-level list item.
        - "Children" field must be rendered as child list items.

## Representation

String that passes [association test](#association-test) evaluated by specific list of [agents](#agent).

Notes:

- List of agents is external input to program that evaluates concept doc.

## Association test

Fn from two strings to bool.

Aliases: is-test.

Examples:

- `is("cow", "animal") == true`.
- `is("function", "relation") == true`.
- `is("war", "peace") == false`.
- `is("slavery", "freedom") == false`.
- `is("love", "good") == true`.

Notes:

- May represent term-type relation ("cow" has type "animal").
- May represent subtype-supertype relation ("function" is subtype of "relation").
- May represent term-predicate relation ("leaf" is "green").
- System prompt for association testing by LLMs: "Evaluate whether the statement in the user message is true or false in general".

## Agent

Entity whose goal is to prevent its own termination.

## Dependently typed lang

Programming lang that supports dependent types.

Aliases: DTL.

Examples:

- Lean.
- Agda.
- Gallina (Rocq prover).
