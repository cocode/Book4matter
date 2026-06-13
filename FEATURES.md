# Typesetting features, in priority order

Source: visual design review of the rotary book interior
(`the-rotary-waltz-interior.pdf`, build `b72c403c09-dirty`, 2026-06-12).
Page references below are printed folios in that build (folio = PDF page − 5).
To regenerate review images: `swift render_rotary.swift <book.pdf> <outdir>`
(renders all pages as PNGs plus facing-page spread sheets; macOS-only, no
installs). Book-content fixes (text, images, structure) are tracked separately
in the rotary repo's `improvements.md`.

Line numbers in `templates/book.typ` are as of 2026-06-12.

## 1. Small consistency fixes (one sitting, do first)

- [x] **Disable hyphenation in chapter/section headings.** The level-1 (part)
  show rule already sets `hyphenate: false`; levels 2–6 don't. Chapter titles
  currently print as "ALTER-NATELY" (folio 59), "APPROXIMA-TION" (60),
  "QUES-TIONS" (69). Either add `hyphenate: false` to the
  `show heading: set text(...)` rule at book.typ:66, or per-level.
- [ ] **Don't hyphenate/break links and email addresses.** The afterword email
  prints as "thero-tarywaltz@worldware.com" (folio 72) — the hyphen reads as
  part of the address. A `show link: set text(hyphenate: false)` plus the same
  for raw autolinks should cover it.
- [x] **Set the TOC title in the heading font.** "Contents" (book.typ:232) is
  the only display heading in the book that renders in the body serif; every
  other display element uses `meta.heading-font`. (Done with the contents
  redesign, 2026-06-12.)

## 2. Heading hierarchy and case

The biggest aesthetic lever. Today every level is force-uppercased by the
template (`upper()` at every show rule), and the level scale is nearly flat:
L3 = 1.2em bold caps, L4 = 1.0em bold caps, L5/L6 = 1.0em regular caps. On a
page like folio 36, a section head and its subheads are visually
indistinguishable; pages with many Q&A-style subheads ("WHY FLAT?", "WHY
TOGETHER?") shout.

- [ ] Reserve all-caps for chapter titles (or drop to small caps); set lower
  levels in bold/italic sentence case so levels are tellable at a glance.
- [ ] Consider a run-in style for the lowest heading level (bold italic lead-in,
  text continues on the same line) — fits the Q&A subheads common in teaching
  text.
- [ ] L5 and L6 are currently identical; differentiate or collapse.

## 3. Font defaults and diagnostics

`book.yaml` already supports `font:`, `heading-font:`, `font-size:`, and a
per-book `fonts/` dir (kpc/__main__.py:170–171, 233–241). The problem is the
default: an unconfigured book silently gets **Liberation Sans** (Arial clone)
headings over a Libertinus Serif body — exactly what happened to rotary.

- [ ] Default `heading-font` to the body `font` instead of Liberation Sans, so
  the zero-config book is coherently single-family.
- [ ] Warn loudly (or fail) when a requested font family isn't resolvable in
  the container (`typst fonts` can enumerate); silent fallback is how the
  Arial surprise happened.

## 4. Title page design pass

The title auto-sizes to fill the full text measure (book.typ, the title-page
`page(numbering: none)` block, ~l.194–220), which is why it runs
margin-to-margin and reads "word processor".

- [ ] **Multi-line title support (verified bug + fix).** A stacked title —
  `title: "The\nRotary\nWaltz"` in book.yaml — breaks into clean lines, but the
  sizer measures `meta.title` and scales its *widest line* to fill the column.
  With one word per line, "Rotary" gets blown up to the 8×body clamp (~88pt),
  three giant lines eat the page, the `v(1fr)` collapses, and the subtitle
  overprints the author. Reproduced at 6×9 in Cormorant (the user hit this).
  Fix that rendered cleanly: measure each line, size so the *widest line* fills
  ~62% of the live width (not 100%), lower the clamp to ~6×body, tighten
  `par(leading)` for the stack, and render the stack with
  `title.split("\n").join(linebreak())`:

  ```typst
  let lines = title.split("\n")
  let widest = calc.max(..lines.map(l =>
    measure(text(size: body, weight: "bold", l)).width.pt()))
  let ideal = body * ((0.62 * avail).pt() / widest)
  let size = calc.max(1.4 * body, calc.min(6 * body, ideal))
  ```
- [ ] **Rule between title and subtitle (user request).** Add an optional short
  centered rule (`line(length: 33%, stroke: 0.5pt)`) between the title block and
  the subtitle. Pairs with the stacked title; both shown working in the same
  6×9 test. Consider a book.yaml toggle (`title-rule: true`) rather than
  hardcoding.
- [ ] Cap the auto-size at ~70–80% of the measure for single-line titles too
  (or a max relative to trim).
- [ ] Reconsider vertical rhythm: title block near optical center (~38–40%
  down), author given more presence than 1.2em.
- [ ] Optional `ornament:` hook in book.yaml (small image/char under the
  title; reusable on part dividers) — cheap way to give a book a signature.
  (The user's cover mockup uses one; would unify cover and title page.)

The book.yaml side of this is trivial (`title:` with `\n`); it just can't land
until the sizer fix above exists, or the title renders as the broken giant
version. Subtitle font choice and any imprint line under the author are cover
(Affinity) concerns, not title-page template ones.

## 5. Table styling

Pandoc emits default Typst tables: full grid, every cell boxed, unweighted
header (rotary folio 44). Add a book-style table show rule: rule above table,
rule under header row, rule below table, no vertical rules, header bold or
small caps.

## 6. Running heads (option)

`running-heads: true` in book.yaml → verso = book title, recto = current
chapter title, small caps or italic, suppressed on part/chapter opener pages
and front matter. Folio could move into the running head line or stay
bottom-center. For reference books people flip through, this is the single
biggest navigation aid; rotary currently has no running heads at all.

## 7. Suppress folios on display pages

Part-divider pages currently print folios (rotary folios 1, 52, 71).
Convention: display pages show no folio. Likely needs the L1 show rule to
emit its own `page(numbering: none)` environment, or a state flag consumed by
a custom footer.

## 8. Part-divider conventions

- [ ] Option to force part dividers (and optionally chapters) to open recto,
  inserting a blank verso when needed. In rotary, parts fall on either side
  arbitrarily, and two part openers land two pages apart (folios 52/54).
- [ ] Option to suppress the auto "PART N" label for back-matter-ish parts.
  (Related: existing TODO.md item "Afterword treatment" — an afterword
  shouldn't need a full Part wrapper.)

## 9. TOC entry styling — DONE 2026-06-12

Part entries currently look identical to chapter entries except for indent.
Bold the part entries, drop their dot leaders, add a little space above each
part group. Depth is hardcoded to 2 — fine, but could come from book.yaml.

Done: leaders dropped everywhere, page numbers in a right-aligned column,
part entries as spaced gray caps with spelled-out ordinals
("PART TWO · BASICS"), space above each part group, chapters indented
beneath their part. Front matter now carries roman folios, and chapters
before the first part (an introduction) list in the contents — flush left,
roman page number — before Part One. Depth is still hardcoded to 2.

## 10. Figure caption system

Only one figure in rotary has a numbered caption ("Figure 1: Dance
Directions", folio 12); the step diagrams instead carry baked-in SVG titles
("Step One") in a different face and size. Add a consistent caption show rule
(size, face, spacing, optional "Figure N" numbering) so books can caption
images properly and the baked-in titles can come out of the SVGs.

## 11. Heading keep-with-next / minimum-space

The `{.new-page}` attribute (parts.lua) is a blunt instrument: rotary's step
sections use it and produce pages that are 70–85% empty (folios 42, 43). A
better primitive: headings never sit within N lines of the page bottom, and/or
an attribute like `{.min-space=12em}` that breaks only when remaining space is
genuinely too small. Would let most hard `{.new-page}` markers be removed.

## 12. Block quote styling

Block quotes are currently only indented, same size/face as body (folio 8).
A designed quote style — slightly smaller, or italic, with breathing room —
would set off the historical quotations this kind of book leans on.

## 13. "Also by" page placement option

The also-by page is generated in front matter (book.typ:193–217). Marketing
convention for self-pub is increasingly back matter (after the
afterword/contact page, where a finished, satisfied reader sees it). Make
placement a book.yaml choice: `also-by-placement: front | back`.

---

Already tracked in TODO.md, not duplicated here: print-friendly hyperlinks
(anchor text + URL in parens), Word-import image extraction, afterword/part
treatment, copyright-page style leak investigation.
