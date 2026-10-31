# Spec writing

## Objectives

- Minimize token count subject to preserved meaning.
- Prioritize precision, disambiguation, uniformity, technicality over prose fluency.
- Preserve obligations, permissions, negations, quantifiers, ordering, referents.

## Statements

- Use one statement per list item.
- Use homogeneous lists.
- End statements with periods.
- End list labels with colons.
- Omit `the following`.
- Omit final `and`, `or` from enumerations.
- Preserve `and`, `or` when they encode Boolean logic.
- Separate example labels from contents with colons: `for example: ...`, `e.g.: ...`.

## Control flow

- Encode conditional rules as:
  ```markdown
  - If {condition}:
    - Then: {statement}.
    - Else: {statement}.
  ```
- Omit `Else` when no alternative is specified.
- For each branch with multiple statements:
  - Use `Then:` / `Else:` followed by nested statement lists.
- Encode iteration as:
  ```markdown
  - For each {item} in {collection}:
    - {statement}.
  ```

## Compression

- Omit articles (`a`, `an`, `the`) before nouns where cardinality, scope, referents remain unambiguous.
- Use CS vernacular where meaning remains unambiguous:
  - `structure` → `struct`.
  - `identifier` → `ident`.
  - `implementation` → `impl`.
  - `specification` → `spec`.
  - `requirement` → `req`.
  - `directory` → `dir`.
  - `function` → `fn`.
  - `argument` → `arg`.
  - `parameter` → `param`.
  - `configuration` → `config`.
  - `document` → `doc`.
  - `documentation` → `docs`.
  - `attribute` → `attr`.
  - `dependency` → `dep`.
- Apply equivalent plural forms.
- Preserve code, literal values, paths, URLs.
- Update links, section-name references when headings change.
