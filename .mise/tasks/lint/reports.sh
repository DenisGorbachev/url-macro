#!/usr/bin/env bash

set -euo pipefail

project_root=${MISE_PROJECT_ROOT:-$(pwd)}
status=0

# shellcheck disable=SC2043
for report in findings.md; do
  report_path="$project_root/$report"
  if [[ -e $report_path || -L $report_path ]]; then
    echo "$report_path must not exist" >&2
    status=1
  fi
done

exit "$status"
