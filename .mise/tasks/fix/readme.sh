#!/usr/bin/env bash
#MISE depends=["fix:name", "fix:code", "fix:agents"]

set -euo pipefail

# "fix:readme" depends on "fix:code" because it reads the code files
# "fix:readme" depends on "fix:agents" because both tasks write to the Git index
# skip in CI because `gen:readme` may fail due to transient network errors (e.g. GitHub server not responding). Note: there is no enforcement that committed generated READMEs are current (this is acceptable).
if [[ ${CI+x} != x ]]; then
  mise run --output interleave gen:readme
  git add -- ':(glob)**/README.md'
fi
