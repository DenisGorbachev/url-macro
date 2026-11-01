# Writing

## Objectives

- Minimize token count.
- Prioritize precision, disambiguation, uniformity, technicality over prose fluency.

## Statements

- End statements with periods.
- End list labels with colons.
- Omit `the following`.
- Omit final `and`, `or` from enumerations.
- Separate example labels from contents with colons: `for example: ...`, `e.g.: ...`.
- Prefix example explanations with `Good:`, `Bad:`.

## Control flow

- If then-branch contains one statement, use `If {condition}, {statement}.`.
- If both branches contain one statement, use `If {condition}, {statement}; else: {statement}.`.
- For compound branches, use nested `If:` / `Then:` / `Else:` lists.
- Encode iteration as:
  ```markdown
  - For each {item} in {collection}:
    - {statement}.
  ```

## Compression

- Omit `the` before nouns.
- Retain indefinite articles (`a`, `an`).
- Prefer CS shorthands (e.g.: struct, ident, impl, spec, dir, fn, arg, param, config, doc, attr, dep, pref, db, op, pkg, lang, cmd, exec, eval, req, res) (disambiguated by context).
