#!/usr/bin/env bash

set -euo pipefail

# `mise install` must be executed in post-merge.sh, too, because fast-forward merges skip pre-commit.sh
mise install
