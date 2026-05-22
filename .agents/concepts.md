# Concepts

## Concept

A structure with the following fields:

* [Name](#name)
* [Definition](#definition)
* [Aliases](#aliases)
* [Examples](#examples)
* [Requirements](#requirements)
* [Allowances](#allowances)
* [Preferences](#preferences)
* [Constructors](#constructors)
* [Properties](#properties)
* [Notes](#notes)
* [Custom sections](#custom-sections)

Examples:

* A definition of a Rust package.
* A definition of a Rust function.

## Name

A string that uniquely identifies the item within its scope.

## Definition

An optional string that defines a concept.

Preferences:

* Should end with a period.

Allowances:

* May start with an article ("A", "An", "The").
* May start with the name of the concept being defined.
* May be a multiline string.

Notes:

* Definition is optional because some concepts have obvious definitions that can be omitted.
  * Examples:
    * fn main
    * Cargo.toml

## Aliases

An optional list of strings that represent alternative names for a concept.

## Examples

An optional [listmap](#listmap) of [examples](#example).

Preferences:

* Should be non-exhaustive (if the listmap is exhaustive: move it to "[Constructors](#constructors)").

Notes:

* The Markdown document may contain multiple sections that start with "Examples" but are not exactly equal to "Examples". Such sections should be treated as related to, but not exactly equal to examples of a concept.
  * Examples:
    * "Examples of names"
    * "Examples of calls"
    * "Examples of hashes"

## Requirements

An optional [listmap](#listmap) of [requirements](#requirement).

## Allowances

An optional [listmap](#listmap) of [allowances](#allowance).

## Preferences

An optional [listmap](#listmap) of [preferences](#preference).

## Constructors

An optional list of [constructors](#constructor) that contains all possible constructors of a concept.

Aliases: "One of"

Requirements:

* Must be exhaustive.

## Properties

An optional [listmap](#listmap) of [properties](#property).

## Notes

An optional [listmap](#listmap) of [notes](#note).

## Custom sections

An optional [listmap](#listmap) of [listmaps](#listmap) of [notes](#note).

## Example

A [stringtree](#stringtree) that [represents](#representation) an instance of a parent object.

Notes:

* Corresponds to a specific instance of a type in a [dependently-typed language](#dependently-typed-language).

## Requirement

A [stringtree](#stringtree) that [represents](#representation) a boolean test of an instance of a parent object.

Notes:

* Corresponds to a predicate in a [dependently-typed language](#dependently-typed-language).
* If an input doesn't pass the requirement test, then it is not an instance of a parent object.

## Allowance

A [stringtree](#stringtree) that [represents](#representation) a non-requirement (a lack of constraint).

Examples:

* "May access external APIs"

## Preference

A [stringtree](#stringtree) that [represents](#representation) a less-than-or-equal relation on a pair of instances of a parent object.

Notes:

* Preferences must be sorted by importance (most important first).
* Preferences should be used to make a choice between two inputs that pass the [requirements](#requirement).

## Constructor

A string that represents a constructor of a type.

* Corresponds to a constructor in a [dependently-typed language](#dependently-typed-language).

## Property

A [stringtree](#stringtree) that [represents](#representation) a property of an instance of a parent object.

Notes:

* Corresponds to a theorem in a [dependently-typed language](#dependently-typed-language).

## Note

A [stringtree](#stringtree) that [represents](#representation) additional information about a parent object.

## Method specification

A structure with the following fields:

* [Name](#name)
* Requirements (optional [listmap](#listmap) of [requirements](#requirement))
* Preferences (optional [listmap](#listmap) of [preferences](#preference))
* Properties (optional [listmap](#listmap) of [properties](#property))
* Notes (optional [listmap](#listmap) of [notes](#note))

* Must have methods:
  * `to_markdown`:
    * Requirements:
      * Must output a list where the top-level items correspond to the structure fields.

## Concepts document

A Markdown document that renders a list of [concepts](#concept) with the following elements:

* Heading level 1: document name that starts with "Concepts"
* For each concept:
  * Name: heading level 2.
  * Definition: paragraph after heading.
  * Other fields:
    * Paragraph that is exactly equal to the field name with ":" in the end.
    * Field value:
      * If the field type has a `to_markdown` method, then call it, otherwise render the most direct representation (e.g. render strings directly).

Requirements:

* The order of other fields in the document must match the order of other fields in the definition of [concept](#concept).
* A field must not appear twice.
* If the field is empty, it must not be rendered.
* Every code item name and single-line code snippet must be rendered in single backticks
  * Examples: `u64`, `PrintCommand`, `to_markdown`, `impl From<A> for B`

## Listmap

A listmap of type A is one of:

* A list of values of type A.
* A map from [names](#name) to values of type A.

Requirements:

* Must have methods:
  * `to_markdown`:
    * Requirements:
      * If the value is a list: must output a Markdown list.
      * If the value is a map: must output a Markdown list where each item is rendered as `{key}: {value}`.

Notes:

* If a listmap is a map, its iteration order is the insertion order of keys as they appear in the source text.

## Stringtree

A stringtree is a structure with the following fields:

* Text (string)
* Children (a list of stringtrees)

* Must have methods:
  * `to_markdown`:
    * Requirements:
      * Must output a multi-level Markdown list.
        * The "Text" field must be rendered as the top-level list item.
        * The "Children" field must be rendered as child list items.

Notes:

* In Markdown, a stringtree is just a nested list.
* In this document, every "Notes", "Requirements", "Preferences" contain examples of stringtrees as nested lists.

## Representation

A string that passes an [association test](#association-test) evaluated by a specific list of [agents](#agent).

Notes:

* The list of agents is an external input to a program that evaluates the concept document.

## Association test

A function from two strings to a boolean.

Aliases: is-test.

Examples:

* `is("cow", "animal") == true`
* `is("function", "relation") == true`
* `is("war", "peace") == false`
* `is("slavery", "freedom") == false`
* `is("love", "good") == true`

Notes:

* May represent a term-type relation ("cow" has type "animal").
* May represent a subtype-supertype relation ("function" is a subtype of "relation").
* May represent a term-predicate relation ("leaf" is "green").
* System prompt for association testing by LLMs: "Evaluate whether the statement in the user message is true or false in general".

## Agent

An entity whose goal is to prevent its own termination.

Notes:

* An agent can be artificial or natural (LLM or human).

## Dependently-typed language

A programming language that supports dependent types.

Aliases: DTL.

Examples:

* Lean
* Agda
* Gallina (Rocq prover)
