#!/usr/bin/env bash
# Integration tests for the EPUB and HTML pipelines.
#
# For the example book and every fixture under tests/, builds an EPUB (piped
# through epubcheck) and the HTML outputs (asserting the website TOC fragment
# is link-free and the whole-book page's TOC links all resolve to a section).
# Everything runs inside the book4matter Docker image — the host
# never installs pandoc, java, or epubcheck.
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
  tests/typography
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

# HTML / table-of-contents checks. No validator like epubcheck exists for HTML,
# so we assert the two things that matter for this project: the website TOC
# fragment (`html toc`) is link-free and lists chapters, and every link in the
# whole-book page's TOC resolves to a section id in the document.
check_html() {
  local f="$1" page toc missing
  page=$(./run.sh html "$f" 2>/dev/null | awk '/ wrote /{print $NF}'); page="${page#/work/}"
  toc=$(./run.sh html toc "$f" 2>/dev/null | awk '/ wrote /{print $NF}'); toc="${toc#/work/}"
  [ -f "$page" ] || { echo "  FAIL: no whole-book page written"; return 1; }
  [ -f "$toc" ]  || { echo "  FAIL: no toc fragment written"; return 1; }

  # Website TOC fragment: a <nav class="book-toc"> listing chapters, no links.
  grep -q 'class="book-toc"' "$toc" || { echo "  FAIL: toc missing book-toc nav"; return 1; }
  grep -q '<li>' "$toc"             || { echo "  FAIL: toc lists no entries"; return 1; }
  if grep -q '<a ' "$toc"; then       echo "  FAIL: toc fragment contains links"; return 1; fi

  # Whole-book page: every TOC target (href="#x") must exist as an id="x".
  missing=$(comm -23 \
    <(grep -oE 'href="#[^"]+"' "$page" | sed -E 's/.*#(.*)"/\1/' | sort -u) \
    <(grep -oE ' id="[^"]+"'   "$page" | sed -E 's/.* id="(.*)"/\1/' | sort -u))
  if [ -n "$missing" ]; then echo "  FAIL: TOC link(s) with no target: $missing"; return 1; fi

  echo "  ok: toc fragment link-free; page TOC links resolve"
}

for f in "${FIXTURES[@]}"; do
  printf '\n\033[1m== %s (html) ==\033[0m\n' "$f"
  if check_html "$f"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed+=("$f (html)")
  fi
done

printf '\n=========================================\n'
printf '  passed: %d\n  failed: %d\n' "$pass" "$fail"
if (( fail > 0 )); then
  printf '  failures:\n'
  for f in "${failed[@]}"; do printf '    - %s\n' "$f"; done
  exit 1
fi
printf '  all green\n'
