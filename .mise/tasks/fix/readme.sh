#!/usr/bin/env bash
#MISE depends=["fix:name", "fix:code"]

set -euo pipefail

# "fix:readme" depends on "fix:code" because it reads the code files
# skip in CI because `gen:readme` may fail due to transient network errors (e.g. GitHub server not responding). Note: there is no enforcement that committed generated READMEs are current (this is acceptable).
if [[ ${CI+x} != x ]]; then
  mise run --output interleave gen:readme
fi
