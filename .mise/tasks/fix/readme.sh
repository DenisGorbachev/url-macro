#!/usr/bin/env bash
#MISE depends=["fix:name", "fix:code"]

set -euo pipefail

mise --cd "$MISE_PROJECT_ROOT" run --output interleave gen:readme
