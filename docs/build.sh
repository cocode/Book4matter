#!/usr/bin/env bash
# Build the book4matter manual. This docs/ directory is itself a book4matter
# book, so building it is the project eating its own dog food.
#
# Every build is stamped with the repo's short git hash via --build-id (see the
# Command-Line chapter), so any PDF or EPUB can be traced back to the commit
# that produced it.
#
# Usage:
#   docs/build.sh                 # build print + epub + html
#   docs/build.sh print           # build only the given format(s)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Short git hash, with a -dirty suffix when the working tree has uncommitted
# changes, so a stamped build is never mistaken for a clean-commit build.
BUILD_ID="$(git -C "$ROOT" rev-parse --short=10 HEAD 2>/dev/null || echo unknown)"
if [[ "$BUILD_ID" != "unknown" ]] && ! git -C "$ROOT" diff --quiet HEAD -- 2>/dev/null; then
  BUILD_ID="${BUILD_ID}-dirty"
fi
echo "build-id: $BUILD_ID" >&2

formats=(print epub html)
[[ "$#" -gt 0 ]] && formats=("$@")

cd "$ROOT"
for fmt in "${formats[@]}"; do
  ./run.sh "$fmt" docs/ --build-id "$BUILD_ID"
  if [[ "$fmt" == "html" ]]; then
    # bf html links an optional book_style.css; supply it by copying our site
    # stylesheet into out/ under that name. The tool emits the <link> itself, so
    # there is nothing to inject here.
    cp "$HERE/book4matter-web.css" "$HERE/out/book_style.css"
    echo "✓ copied book4matter-web.css -> out/book_style.css" >&2
  fi
done
