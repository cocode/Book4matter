#!/usr/bin/env bash
# Build the Book4matter website: one standalone HTML page from web/chapters/,
# then drop the site stylesheet next to it so the page is styled.
#
# This web/ directory is itself a book4matter book, so building the site uses
# the same tool the site describes. Reuses the manual's stylesheet
# (docs/book4matter-web.css) so the site and the docs share one look.
#
# Usage (from anywhere):
#   web/build.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

cd "$ROOT"
./run.sh html web/

# `bf html` links an optional book_style.css next to the page; supply it by
# copying the shared site stylesheet into out/ under that name. The tool emits
# the <link> itself, so there is nothing to inject.
cp "$ROOT/docs/book4matter-web.css" "$HERE/out/book_style.css"
echo "✓ copied book4matter-web.css -> web/out/book_style.css" >&2
echo "✓ open web/out/book4matter.html" >&2
