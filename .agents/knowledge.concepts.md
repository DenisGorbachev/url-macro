# Concepts for knowledge base

## Observer

Program that downloads [lore](#lore) from [source](#lore-source) into local filesystem.

Requirements:

- Must accept `path` as last positional parameter (local target directory).
- Must atomically replace old directory with new directory.
  - Create temp path in same parent directory as `path` (suffix: ".new") (same filesystem is required for atomic rename).
  - Build new contents fully inside temp path.
  - Fsync files and temp path on best-effort basis where supported.
  - If `path` exists:
    - Then: rename it to backup name in same parent directory (suffix: ".old").
  - Rename temp path to `path` (atomic on POSIX and Windows when both paths are on same filesystem).
  - If final rename fails:
    - Then:
      - Attempt to restore backup.
      - Keep temp path for debugging.
  - After successful replacement, remove backup path.

## Lore

String that represents some informal knowledge about external system.

Notes:

- Some informal knowledge may be formatted as Markdown (example: technical documentation page).
- Some informal knowledge may be formatted as images (example: diagram).
- Some informal knowledge may be formatted as PDF (example: device manual).
- Some informal knowledge may contain contradictions.
- Some informal knowledge may contradict experimental knowledge.
- This kind of knowledge is called "informal" because it doesn't have unique representation in any formal language.
  - Informal knowledge has multiple potential representations in any formal language.
  - Informal knowledge is inherently ambiguous (it must be disambiguated during [formalization](#formalization)).
- Some informal knowledge files have internal tree structure.
  - Examples:
    - Every valid source code file has internal tree structure.
    - Every valid Markdown file has internal tree structure.
- Some informal knowledge files may have [divergent content and extension](#divergent-file-content-and-file-extension-for-specific-validator-map).

## Lore dir

Directory with [lore files](#lore-file).

## Lore file

File that contains [lore](#lore).

## Lore root

Top-level [lore dir](#lore-dir).

## Lore source

Structure with `label` and `locator` string fields that uniquely identifies subset of informal knowledge.

Examples:

- Polymarket docs: <https://docs.polymarket.com/>.
- Polymarket CTF exchange contract source code: <https://github.com/Polymarket/ctf-exchange>.
- Polymarket CTF exchange contract instance: <https://polygonscan.com/address/0x4bfb41d5b3570defd03c39a9a4d8de6bd8b8982e>.

Notes:

- Lore source may be formatted as key-value pair (see examples).
- Lore source is identified by its `locator` (`label` is just human-readable note).

## Lore item reference

URI that uniquely identifies substring relative to [lore root](#lore-root).

Requirements:

- Must have "file://" scheme.
- Must have path (interpreted as path to lore file relative to [lore root](#lore-root)).
- May have query (interpreted as path to item within file).
  - Requirements:
    - Must not start with "/".
    - Must be delimited by "/".
    - Path elements must be URL-encoded.
  - Notes:
    - Item resolver should interpret query according to file format:
      - Examples:
        - Markdown resolver should interpret query as sequence of headings, followed by item's offset from last heading in query.
- Must have fragment that is equal to hash of item in its canonical byte representation:
  - Hash function: SHA-256.
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
    - "docs.polymarket.com" is local directory name, not domain.

## Theory

Set of declarations in specific formal language.

Requirements:

- Every declaration must contain [reference](#lore-item-reference) to specific item of informal knowledge.

Preferences:

- Declaration A is better than Declaration B if Declaration A's [reference](#lore-item-reference) is more precise than Declaration B's [reference](#lore-item-reference) and other properties are equal.

Notes:

- Most common language is Lean 4.

## Experimental knowledge

[theory](#theory) that has been obtained through formally defined experiment.

Examples:

- `/markets` endpoint of Polymarket API returns array of markets with maximum length of 1000.
- In complete set of markets obtained from `/markets` endpoint, `market_slug` field has unique values.
- Some markets have `question_id` set to empty string.

Notes:

- Some knowledge can be obtained only through experiments.

## Formalization

Process whose input is [lore](#lore-dir) and output is [formal knowledge](#theory) without internal contradictions.

Note:

- Formalization is not mechanical: it requires "interpreter" entity (not defined in this document).
- Single [lore root](#lore-root) may be related to multiple [theories](#theory) without internal contradictions ("multiple coherent interpretations of reality").

## Informalization

Process whose input is [theory](#theory) and whose output is [lore root](#lore-root).

Requirements:

- Given [lore root](#lore-root) `input` and equivalence relation `eqv`, applying chain of formalization and informalization must return `output` for which `eqv(input, output)` returns true.
  - In other words: formalized-informalized knowledge must "match" original knowledge according to `eqv`.

Notes:

- Informalization is mechanical.
- Given [lore root](#lore-root) `input`, applying chain of formalization and informalization may not return same `input`.
- Equivalence relation `eqv` is external program (not defined in this specification).

## Reference A is more precise than Reference B

[Reference A](#lore-item-reference) is more precise than [Reference B](#lore-item-reference) if Reference B is prefix of Reference A when compared without hash fragments.

Examples:

- Given source code file `s`, reference to specific method within `s` is more precise than reference to `s` itself.

## Divergent file content and file extension for specific validator map

File content and file extension are divergent for specific map from file extensions to file content validators and path to file iff file content doesn't pass validator implied by file extension.
