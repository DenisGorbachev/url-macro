#!/usr/bin/env bash

set -euo pipefail

MISE_LOG_LEVEL=warn mise --cd "$PWD" install
