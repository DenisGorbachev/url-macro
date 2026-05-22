# Concepts for knowledge base

## Observer

A program that downloads [lore](#lore) from [source](#lore-source) into the local filesystem.

Requirements:

* Must accept a `path` as the last positional parameter (the target local directory)
* Must atomically replace the old directory with a new directory
  * Create the temp path in the same parent directory as `path` (suffix: ".new") (same filesystem required for atomic rename)
  * Build the new contents fully inside the temp path
  * Fsync files and the temp path (best-effort where supported)
  * If `path` exists, rename it to a backup name in the same parent directory (suffix: ".old")
  * Rename the temp path to `path` (atomic on POSIX and Windows when same filesystem)
  * If the final rename fails, attempt to restore the backup and keep the temp path for debugging
  * After a successful replace, remove the backup path

## Lore

A string that represents some informal knowledge about an external system.

Notes:

* Some informal knowledge may be formatted as Markdown (example: a technical documentation page).
* Some informal knowledge may be formatted as images (example: a diagram).
* Some informal knowledge may be formatted as PDF (example: a device manual).
* Some informal knowledge may contain contradictions.
* Some informal knowledge may contradict the experimental knowledge.
* This kind of knowledge is called "informal" because it doesn't have a unique representation in any formal language.
  * Informal knowledge has multiple potential representations in any formal language.
  * Informal knowledge is inherently ambiguous (it must be disambiguated during [formalization](#formalization)).
* Some informal knowledge files have an internal tree structure
  * Examples
    * Every valid source code file has an internal tree structure
    * Every valid Markdown file has an internal tree structure
* Some informal knowledge files may have [divergent content and extension](#divergent-file-content-and-file-extension-for-a-specific-validator-map)

## Lore dir

A directory with [lore files](#lore-file).

## Lore file

A file that contains [lore](#lore).

## Lore root

The top-level [lore dir](#lore-dir).

## Lore source

A structure with `label` and `locator` string fields that uniquely identifies a subset of informal knowledge.

Examples:

* Polymarket docs: <https://docs.polymarket.com/>
* Polymarket CTF exchange contract source code: <https://github.com/Polymarket/ctf-exchange>
* Polymarket CTF exchange contract instance: <https://polygonscan.com/address/0x4bfb41d5b3570defd03c39a9a4d8de6bd8b8982e>

Notes:

* Lore source may be formatted as a key-value pair (see examples).
* Lore source is identified by its `locator` (the `label` is just a human-readable note).

## Lore item reference

A URI that uniquely identifies a substring relative to the [lore root](#lore-root).

Requirements:

* Must have a "file://" scheme.
* Must have a path (interpreted as the path to the lore file relative to the [lore root](#lore-root))
* May have a query (interpreted as the path to the item within the file)
  * Requirements
    * Must not start with "/"
    * Must be delimited by "/"
    * The path elements must be URL-encoded
  * Notes:
    * The item resolver should interpret the query according to the file format:
      * Examples:
        * Markdown resolver should interpret the query as a sequence of headings, followed by an offset of the item starting from the latest heading in the query.
* Must have a fragment that is equal to the hash of the item in its canonical byte representation:
  * Hash function: SHA-256.
  * Fragment encoding: lowercase hex string of the 32-byte digest.
  * Canonical byte representation:
    * The item is the exact byte slice returned by the item resolver (without normalization).
      * For text formats, the resolver must return the exact byte slice from the file contents.
  * Reasons:
    * The [observer](#observer) may output a different informal knowledge base each time
      * Some items may be modified by external actors that have write permissions on [source](#lore-source)
      * Some items may be modified as a result of external API calls
        * Examples:
          * The list of trades may be extended due to new orders being placed and matched.

Examples:

* "file://docs.polymarket.com/developers/CLOB/authentication.md?Authentication/L1+Authentication/CLOB+Client/0#e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  * Notes:
    * "docs.polymarket.com" is a local dir name, not a domain

## Theory

A set of declarations in a specific formal language.

Requirements:

* Every declaration must contain a [reference](#lore-item-reference) to a specific item of the informal knowledge

Preferences:

* Declaration A is better than Declaration B if Declaration A [reference](#lore-item-reference) is more precise than Declaration B [reference](#lore-item-reference) and other properties are equal.

Notes:

* Most common language: Lean 4.

## Experimental knowledge

A [theory](#theory) that has been obtained through a formally defined experiment.

Examples:

* The `/markets` endpoint of Polymarket API returns an array of markets with max length of 1000.
* In the complete set of markets obtained from `/markets` endpoint, the `market_slug` field has unique values.
* Some markets have a `question_id` set to an empty string.

Notes:

* Some knowledge can be obtained only through experiments.

## Formalization

A process whose input is [lore](#lore-dir) and output is [formal knowledge](#theory) that doesn't have internal contradictions.

Note:

* Formalization is not mechanical (requires an "interpreter" entity (not defined in this document)).
* A single [lore root](#lore-root) may be related to multiple [theories](#theory) without internal contradictions ("multiple coherent interpretations of reality").

## Informalization

A process whose input is [theory](#theory) and output is [lore root](#lore-root).

Requirements:

* Given [lore root](#lore-root) `input` and an equivalence relation `eqv`, applying a chain of formalization and informalization must return `output` for which `eqv(input, output)` returns true.
  * In other words: the formalized-informalized knowledge must "match" the original knowledge according to `eqv`.

Notes:

* Informalization is mechanical.
* Given [lore root](#lore-root) `input`, applying a chain of formalization and informalization may not return the same `input`.
* The equivalence relation `eqv` is an external program (not defined in this specification).

## Reference A is more precise than Reference B

[Reference A](#lore-item-reference) is more precise than [Reference B](#lore-item-reference) if Reference B is a prefix of Reference A when compared without the hash fragments.

Examples:

* Given a source code file `s`, a reference to a specific method within `s` is more precise than reference to `s` itself.

## Divergent file content and file extension for a specific validator map

File content and file extension are divergent for a specific map from file extensions to file content validators and a path to the file iff the file content doesn't pass the validator implied by the file extension.
