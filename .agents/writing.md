# Writing

## Objectives

- Minimize token count subject to preserved meaning.
- Prioritize precision, disambiguation, uniformity, technicality over prose fluency.
- Preserve obligations, permissions, negations, quantifiers, ordering, referents.

## Statements

- Omit guidance that restates default agent behavior.
- Don't add precautionary preservation rules.
- Use one statement per list item.
- Use homogeneous lists.
- End statements with periods.
- End list labels with colons.
- Omit `the following`.
- Omit final `and`, `or` from enumerations.
- Preserve `and`, `or` when they encode Bool logic.
- Separate example labels from contents with colons: `for example: ...`, `e.g.: ...`.

## Control flow

- If then-branch contains one statement, use `If {condition}, {statement}.`.
- If both branches contain one statement, use `If {condition}, {statement}; else: {statement}.`.
- For compound branches, use nested `If:` / `Then:` / `Else:` lists.
- Omit `Else` when no alternative is specified.
- Encode iteration as:
  ```markdown
  - For each {item} in {collection}:
    - {statement}.
  ```

## Compression

- Omit articles (`a`, `an`, `the`) before nouns.
- Use CS vernacular (e.g.: struct, ident, impl, spec, dir, fn, arg, param, config, doc, attr, dep, pref, db, op).
- Apply equiv plural forms.
- Preserve code, literal values, paths, URLs.
- Update links, section-name refs when headings change.
