# Concepts for knowledge base

## Observer

Program that downloads [lore](#lore) from [source](#lore-source) into local filesystem.

Reqs:

- Must accept `path` as last positional param (local target dir).
- Must atomically replace old dir with new dir.
  - Create temp path in same parent dir as `path` (suffix: ".new") (same filesystem is required for atomic rename).
  - Build new contents fully inside temp path.
  - Fsync files and temp path on best-effort basis where supported.
  - If `path` exists, rename it to backup name in same parent dir (suffix: ".old").
  - Rename temp path to `path` (atomic on POSIX and Windows when both paths are on same filesystem).
  - If final rename fails:
    - Then:
      - Attempt to restore backup.
      - Keep temp path for debugging.
  - After successful replacement, remove backup path.

## Lore

String that represents some informal knowledge about external system.

Notes:

- Formats: Markdown, images, PDF.
- Some informal knowledge may contain contradictions.
- Some informal knowledge may contradict experimental knowledge.
- This kind of knowledge is called "informal" because it doesn't have unique representation in any formal language.
  - Informal knowledge has multiple potential representations in any formal language.
  - Informal knowledge is inherently ambiguous (it must be disambiguated during [formalization](#formalization)).
- Some informal knowledge files may have [divergent content and extension](#divergent-file-content-and-file-extension-for-specific-validator-map).

## Lore dir

Dir with [lore files](#lore-file).

## Lore file

File that contains [lore](#lore).

## Lore root

Top-level [lore dir](#lore-dir).

## Lore source

Struct with `label` and `locator` string fields that uniquely identifies subset of informal knowledge.

Examples:

- Polymarket docs: <https://docs.polymarket.com/>.
- Polymarket CTF exchange contract source code: <https://github.com/Polymarket/ctf-exchange>.
- Polymarket CTF exchange contract instance: <https://polygonscan.com/address/0x4bfb41d5b3570defd03c39a9a4d8de6bd8b8982e>.

Notes:

- Lore source may be formatted as key-value pair (see examples).
- Lore source is identified by its `locator` (`label` is just human-readable note).

## Lore item ref

URI that uniquely identifies substring relative to [lore root](#lore-root).

Reqs:

- Must have "file://" scheme.
- Must have path (interpreted as path to lore file relative to [lore root](#lore-root)).
- May have query (interpreted as path to item within file).
  - Reqs:
    - Must not start with "/".
    - Must be delimited by "/".
    - Path elements must be URL-encoded.
  - Notes:
    - Item resolver should interpret query according to file format:
      - Examples:
        - Markdown resolver should interpret query as sequence of headings, followed by item's offset from last heading in query.
- Must have fragment that is equal to hash of item in its canonical byte representation:
  - Hash fn: SHA-256.
  - Fragment encoding: lowercase hex string of 32-byte digest.
  - Canonical byte representation:
    - Item is exact byte slice returned by item resolver (without normalization).
      - For text formats, resolver must return exact byte slice from file contents.
  - Reasons:
    - [observer](#observer) may output different informal knowledge base each time.
      - Some items may be modified by external actors that have write permissions on [source](#lore-source).
      - Some items may be modified as result of external API calls.
        - Examples:
          - List of trades may be extended due to new orders being placed and matched.

Examples:

- "file://docs.polymarket.com/developers/CLOB/authentication.md?Authentication/L1+Authentication/CLOB+Client/0#e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855".
  - Notes:
    - "docs.polymarket.com" is local dir name, not domain.

## Theory

Set of declarations in specific formal language.

Reqs:

- Every declaration must contain [ref](#lore-item-ref) to specific item of informal knowledge.

Prefs:

- Declaration A is better than Declaration B if Declaration A's [ref](#lore-item-ref) is more precise than Declaration B's [ref](#lore-item-ref) and other properties are equal.

Notes:

- Most common language is Lean 4.

## Experimental knowledge

[theory](#theory) that has been obtained through formally defined experiment.

Examples:

- `/markets` endpoint of Polymarket API returns array of markets with max len of 1000.
- In complete set of markets obtained from `/markets` endpoint, `market_slug` field has unique values.
- Some markets have `question_id` set to empty string.

## Formalization

Process whose input is [lore](#lore-dir) and output is [formal knowledge](#theory) without internal contradictions.

Note:

- Formalization is not mechanical: it requires "interpreter" entity (not defined in this doc).
- Single [lore root](#lore-root) may be related to multiple [theories](#theory) without internal contradictions ("multiple coherent interpretations of reality").

## Informalization

Process whose input is [theory](#theory) and whose output is [lore root](#lore-root).

Reqs:

- Given [lore root](#lore-root) `input` and equivalence relation `eqv`, applying chain of formalization and informalization must return `output` for which `eqv(input, output)` returns true.
  - In other words: formalized-informalized knowledge must "match" original knowledge according to `eqv`.

Notes:

- Informalization is mechanical.
- Given [lore root](#lore-root) `input`, applying chain of formalization and informalization may not return same `input`.
- Equivalence relation `eqv` is external program (not defined in this spec).

## Ref A is more precise than Ref B

[Ref A](#lore-item-ref) is more precise than [Ref B](#lore-item-ref) if Ref B is prefix of Ref A when compared without hash fragments.

Examples:

- Given source code file `s`, ref to specific method within `s` is more precise than ref to `s` itself.

## Divergent file content and file extension for specific validator map

File content and file extension are divergent for specific map from file extensions to file content validators and path to file iff file content doesn't pass validator implied by file extension.
