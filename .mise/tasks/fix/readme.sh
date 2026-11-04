#!/usr/bin/env bash
#MISE depends=["fix:name", "fix:code"]

set -euo pipefail

mise run --output interleave gen:readme
