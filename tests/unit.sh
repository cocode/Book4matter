#!/usr/bin/env bash
# Fast, repeatable unit tests for the chapter-preprocessing logic (novel /
# no-parts / auto-numbering / .txt). Pure Python -- no pandoc or typst -- so it
# runs in about a second and can be run again and again.
#
# It runs INSIDE the book4matter image (the host has no PyYAML), but against the
# *working-tree* `bf` package mounted at /work (PYTHONPATH=/work), so code edits
# are picked up with no image rebuild. Only the image's python3 + PyYAML are used.
#
# Usage:  ./tests/unit.sh                 (from anywhere)
#         ./tests/unit.sh --rebuild       (rebuild the image first)
#         ./tests/unit.sh -k mixed        (extra args pass through to unittest)
set -euo pipefail

IMAGE="book4matter"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

REBUILD=0
if [[ "${1:-}" == "--rebuild" ]]; then REBUILD=1; shift; fi
if [[ "$REBUILD" == 1 ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Building $IMAGE image..." >&2
  docker build -t "$IMAGE" "$ROOT"
fi

exec docker run --rm -v "$ROOT:/work" -w /work -e PYTHONPATH=/work \
  --entrypoint python3 "$IMAGE" \
  -m unittest discover -s tests -p 'test_*.py' -v "$@"
