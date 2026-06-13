#!/usr/bin/env bash
# Integration tests for the EPUB pipeline.
#
# Builds an EPUB for the example book and every fixture under tests/, piping
# each through epubcheck. Everything runs inside the kindle-pandoc-creator
# Docker image — the host never installs pandoc, java, or epubcheck.
#
# Usage:  ./tests/run.sh           (run from project root)
#         ./tests/run.sh --rebuild (rebuild the image first)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

REBUILD=""
if [[ "${1:-}" == "--rebuild" ]]; then REBUILD="--rebuild"; shift; fi

# All book directories to validate. `example/` is the canonical demo book; the
# tests/* fixtures each exercise one tricky feature.
FIXTURES=(
  example
  tests/headings
  tests/wrap
  tests/parts
  tests/frontmatter
)

pass=0
fail=0
failed=()

for f in "${FIXTURES[@]}"; do
  printf '\n\033[1m== %s ==\033[0m\n' "$f"
  # `./run.sh epub` already runs epubcheck inside the container and exits
  # non-zero on errors, so this is just orchestration.
  if ./run.sh $REBUILD epub "$f"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed+=("$f")
  fi
  # The --rebuild flag is only meaningful on the first call; clear it so we
  # don't rebuild N times.
  REBUILD=""
done

printf '\n=========================================\n'
printf '  passed: %d\n  failed: %d\n' "$pass" "$fail"
if (( fail > 0 )); then
  printf '  failures:\n'
  for f in "${failed[@]}"; do printf '    - %s\n' "$f"; done
  exit 1
fi
printf '  all green\n'
