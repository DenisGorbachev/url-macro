# Concepts

## Concept

Structure with fields:

- [Name](#name).
- [Definition](#definition).
- [Aliases](#aliases).
- [Examples](#examples).
- [Requirements](#requirements).
- [Allowances](#allowances).
- [Preferences](#preferences).
- [Constructors](#constructors).
- [Properties](#properties).
- [Notes](#notes).
- [Custom sections](#custom-sections).

Examples:

- Definition of Rust package.
- Definition of Rust function.

## Name

String that uniquely identifies item within its scope.

## Definition

Optional string that defines concept.

Preferences:

- Should end with period.

Allowances:

- May start with article ("A", "An", "The").
- May start with name of concept being defined.
- May be multiline string.

Notes:

- Definition is optional because some concepts have obvious definitions that can be omitted.
  - Examples:
    - `fn main`.
    - `Cargo.toml`.

## Aliases

Optional list of strings that represent alternative names for concept.

## Examples

Optional [listmap](#listmap) of [examples](#example).

Preferences:

- Should be non-exhaustive.
- If listmap is exhaustive:
  - Then: move it to "[Constructors](#constructors)".

Notes:

- Markdown document may contain sections whose headings start with "Examples" but are not exactly "Examples". Treat these sections as related to, but distinct from, examples of concept.
  - Examples:
    - "Examples of names".
    - "Examples of calls".
    - "Examples of hashes".

## Requirements

Optional [listmap](#listmap) of [requirements](#requirement).

## Allowances

Optional [listmap](#listmap) of [allowances](#allowance).

## Preferences

Optional [listmap](#listmap) of [preferences](#preference).

## Constructors

Optional list of [constructors](#constructor) that contains all possible constructors of concept.

Aliases: "One of".

Requirements:

- Must be exhaustive.

## Properties

Optional [listmap](#listmap) of [properties](#property).

## Notes

Optional [listmap](#listmap) of [notes](#note).

## Custom sections

Optional [listmap](#listmap) of [listmaps](#listmap) of [notes](#note).

## Example

[stringtree](#stringtree) that [represents](#representation) instance of parent object.

Notes:

- Corresponds to specific instance of type in [dependently typed language](#dependently-typed-language).

## Requirement

[stringtree](#stringtree) that [represents](#representation) boolean test of instance of parent object.

Notes:

- Corresponds to predicate in [dependently typed language](#dependently-typed-language).
- If input doesn't pass requirement test:
  - Then: it is not instance of parent object.

## Allowance

[stringtree](#stringtree) that [represents](#representation) non-requirement (lack of constraint).

Examples:

- "May access external APIs".

## Preference

[stringtree](#stringtree) that [represents](#representation) less-than-or-equal relation on pair of instances of parent object.

Notes:

- Preferences must be sorted by importance (most important first).
- Preferences should be used to make choice between two inputs that pass [requirements](#requirement).

## Constructor

String that represents constructor of type.

- Corresponds to constructor in [dependently typed language](#dependently-typed-language).

## Property

[stringtree](#stringtree) that [represents](#representation) property of instance of parent object.

Notes:

- Corresponds to theorem in [dependently typed language](#dependently-typed-language).

## Note

[stringtree](#stringtree) that [represents](#representation) additional information about parent object.

## Method specification

Structure with fields:

- [Name](#name).
- Requirements (optional [listmap](#listmap) of [requirements](#requirement)).
- Preferences (optional [listmap](#listmap) of [preferences](#preference)).
- Properties (optional [listmap](#listmap) of [properties](#property)).
- Notes (optional [listmap](#listmap) of [notes](#note)).
- Must have methods:
  - `to_markdown`:
    - Requirements:
      - Must output list where top-level items correspond to structure fields.

## Concepts document

Markdown document that presents list of [concepts](#concept) with elements:

- Heading level 1: document name that starts with "Concepts".
- For each concept:
  - Name: heading level 2.
  - Definition: paragraph after heading.
  - Other fields:
    - Paragraph that is exactly equal to field name with ":" at end.
    - Field value:
      - If field type has `to_markdown` method:
        - Then: call it.
        - Else: render most direct representation (e.g.: render strings directly).

Requirements:

- Order of other fields in document must match order of other fields in definition of [concept](#concept).
- Field must not appear twice.
- If field is empty:
  - Then: it must not be rendered.
- Every code item name and single-line code snippet must be rendered in single backticks.
  - Examples: `u64`, `PrintCommand`, `to_markdown`, `impl From<A> for B`.

## Listmap

Listmap of type A is one of:

- List of values of type A.
- Map from [names](#name) to values of type A.

Requirements:

- Must have methods:
  - `to_markdown`:
    - Requirements:
      - If value is list:
        - Then: must output Markdown list.
        - Else: must output Markdown list where each item is rendered as `{key}: {value}`.

Notes:

- If listmap is map:
  - Then: its iteration order is insertion order of keys as they appear in source text.

## Stringtree

Stringtree is structure with fields:

- Text (string).
- Children (list of stringtrees).
- Must have methods:
  - `to_markdown`:
    - Requirements:
      - Must output multi-level Markdown list.
        - "Text" field must be rendered as top-level list item.
        - "Children" field must be rendered as child list items.

Notes:

- In Markdown, stringtree is just nested list.
- In this document, every "Notes", "Requirements", "Preferences" section contains examples of stringtrees as nested lists.

## Representation

String that passes [association test](#association-test) evaluated by specific list of [agents](#agent).

Notes:

- List of agents is external input to program that evaluates concept document.

## Association test

Function from two strings to boolean.

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

Notes:

- Agent can be artificial or natural (LLM or human).

## Dependently typed language

Programming language that supports dependent types.

Aliases: DTL.

Examples:

- Lean.
- Agda.
- Gallina (Rocq prover).
