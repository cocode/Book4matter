#!/usr/bin/env bash
# Build the Book4matter website: one standalone HTML page from web/chapters/.
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

echo "✓ open web/out/book4matter.html" >&2
