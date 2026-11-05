# Project support

- Shell scripts must support GNU/Linux and Bash and BSD cmd-line tools bundled with macOS 15.

## Cargo.toml

- Must contain:
  - `workspace`:
    - `package`.
    - `metadata`:
      - `details`:
        - `name`.
        - `title`.
    - `lints`.
  - If `package` exists, must contain `package.metadata.details`.
- Every workspace pkg manifest must contain `lints.workspace = true`.
- Must not contain:
  - `workspace`:
    - `package`:
      - `description`.
      - `readme`.
  - `package`:
    - `readme`.

## README.ts

- Must support a regular pkg, a root pkg with workspace members, a virtual workspace.
- Must use `cargo metadata` to discover workspace pkgs, manifests, targets, resolved properties.
- Must normalize GitHub origin URLs and validate every non-empty pkg repo against origin.
- For root repo check, must prefer `workspace.package.repository` and fall back to resolved root `package.repository`.
- If `package.metadata.details.readme.generate ?? workspace.metadata.details.readme.generate ?? true` is `true` for a README, must enable it.
- If a README is enabled:
  - Then:
    - Must generate one README beside every workspace pkg manifest.
    - Must generate an `Other packages` section in root pkg README.
    - Must generate a heading and pkg README links at repo root for a virtual workspace.
- Must choose titles in this order:
  - Pkg README: non-empty `package.metadata.details.title`, then `package.name`.
  - Virtual workspace: non-empty `workspace.metadata.details.title`, `package.metadata.details.title`, `workspace.metadata.details.name`, then `package.name`.
- Pkg READMEs must derive installation, usage, binaries, crate docs, badges, license links from pkg metadata and targets.
- GitHub-specific content must be limited to public GitHub repos; non-GitHub repos must not require GitHub metadata.
- Must emit a JSON array of `{path, content}` records on stdout.

## AGENTS.ts

- Must preserve `renderXmlFile`, `runAgentDocsList`, `includeAgentDocs`, `includeAllFiles`.
- If `.agents/project.md` is present, must include it.
- Must use `cargo metadata` to:
  - Include requested files only from workspace members, plus root `Cargo.toml`.
  - Include repo docs for deps used directly by a workspace member.
  - Include requested dep-owned docs from any matching metadata pkg, selecting highest version, then manifest path, before checking whether file exists.
- Included paths must be repo-relative and sorted.
- If a requested path is absent, must skip it.
- Must preserve Markdown heading shifts and collision-safe lang-tagged code fences.
- Must rebase relative Markdown link and image destinations to repo root when source and normalized target paths are inside repo.
- Must preserve link labels, titles, query strings, fragments, unrelated Markdown formatting.
- Must leave absolute URLs, absolute paths, fragment-only links, undecodable paths, outside-repo sources and targets unchanged.
- Must emit a JSON array containing one `{path, content}` record on stdout.

## .mise/tasks/md/gen.nu

- Must set `TMPDIR` for generators and remove their temporary files after completion.
- Must lint every output through `lint:docs` before checking freshness or replacing destinations.
- Must stage all outputs beside their destinations before replacing any destination, then remove remaining temp files.
- Partial replacement failure is acceptable because the next successful generation repairs outputs.

## .mise/tasks/fix/name.sh

- Must accept an optional target name, defaulting to `git:repo-name`.
- Must read current name from `workspace.metadata.details.name`, falling back to `package.name`; missing or empty names must fail.
- Must normalize periods before deriving kebab- and snake-case names; a `package.name` fallback target must be kebab-case.
- Must rename matching names in:
  - Root and member manifests, including pkg names, members, default members, deps, local paths.
  - Rust crate refs outside `specs` and `.agents`.
  - Pkg dirs derived from member manifest paths.
- Must not assume a pkg dir layout or rename workspace root.
- Must rename nested dirs before parents and fail on existing destinations.
- Must refresh an existing `Cargo.lock` with `cargo metadata`, then validate full graph with `--locked`; validation without a lockfile must not create one.
- Must update original name source: raw workspace metadata or kebab-case root pkg name.
- Must roll back every file edit and dir move on failure, then remove transaction data.

## fnox.toml

- Must contain `env = "exec"`.
- Must contain `providers.age`.
  - Must have `type = "age"`.
  - Must contain a `recipients` array with at least two unique native age recipients.
  - Template baseline recipients must be host LAK and sandbox LAK.
  - A GitHub repo with test secrets must additionally contain its repo-specific CAK recipient.
- Every key under `profiles.test.secrets` must have `provider = "age"`.

## .mise/tasks/fix/fnox.sh

- Must declare `wait_for=["fix:name"]`.
- Must validate that `providers.keychain.service` equals `git:repo-name`.
- Must not migrate secrets between old and new idents.

## .mise/tasks/fnox/github/init-age-key.sh

- May clear clipboard without preserving contents that predate task.
- May treat write races as acceptable because script is run by a single user who guarantees that other scripts do not run concurrently.

## .mise/tasks/fix/cargo.sh

- Must declare `wait_for=["fix:name"]`.
- Must discover workspace pkg manifests with `cargo metadata`.
- If a manifest has no `lints` key, must add `lints.workspace = true`.
- If a manifest has `lints.workspace = true`, must preserve it.
- If a manifest has any other `lints` config:
  - Then:
    - Must preserve it.
    - Must fail.

## .mise/tasks/git/repo-name.sh

- Must derive name from final component of `origin`, removing a trailing slash and `.git`.
- Must use `MISE_PROJECT_ROOT` or current dir and support GitHub, Keybase, equiv URL shapes.
- If origin is unreadable or result is empty, must fail; else: must output only name.

## .mise/tasks/git/install-hooks.sh

- Must install executable `pre-commit`, `pre-merge-commit`, `commit-msg` hooks in Git's resolved hooks dir.
- Hooks must delegate to matching mise tasks and forward all args.
- Installation must replace obsolete Lefthook launchers.
- Installation must remove obsolete repo-generated `post-commit` hook without removing a user-modified hook.

## .mise/tasks/git/validate-commit.sh

- Must reject active-index entries marked `assume-unchanged` or `skip-worktree`.
- Before checks and after successful checks, must:
  - Require tracked working-tree contents, including submodules, to match active index.
  - Require every nonignored untracked file to be staged or removed.
- Must run `check` task against working tree.
- If active-index tree changes during successful checks, must fail.

## .repoconf/hooks/post-init.sh

- Must accept only initialized dir and derive names from `origin` without prompting.
- Must trust repo and install and reshim mise tools.
- If origin is GitHub, must read repo name, canonical URL with `gh`; else: must use `git:repo-name` without requiring `gh` or setting a repo URL.
- Must remove template license files and run `fix:name`.
- For each pkg discovered by `cargo metadata`:
  - Empty `package.metadata.details.title`.
  - Remove `package.description`.
  - If no repo URL is available, remove direct `repository` and `homepage`.
- Must always empty `workspace.metadata.details.title` and remove `workspace.package.description`.
- If a repo URL is available, must set `workspace.package.{repository,homepage}` to it; else: must remove `workspace.package.{repository,homepage}`.
- May rely on template root defining workspace fields it updates.
- Must update fnox idents, regenerate READMEs, build, test, stage, commit.

## .github/workflows/ci.yml

- Must keep Rust version specified in `rust-toolchain.toml`.
  - Rationale:
    - Setting it to "stable" in CI leads to warnings that aren't visible in pre-commit.
    - Building for both "stable" and pinned version takes extra time and disk space.
    - Pinning "stable" is not always possible (some projects do require nightly).
