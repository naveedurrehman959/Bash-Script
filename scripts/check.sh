#!/usr/bin/env bash
# check.sh - lint, format check and tests. Exit non-zero on any problem.
set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.."

files=(bin/healthrep lib/*.sh scripts/*.sh)

echo "==> shellcheck"
shellcheck -x "${files[@]}"
echo "==> shfmt"
shfmt -i 2 -ci -d "${files[@]}"
echo "==> bats"
bats test/
echo "All checks passed."
