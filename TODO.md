# TODO

Project-level todo list. Outlives sessions (unlike the harness TaskList tool).
Edit freely; Claude reads and writes it on request.

## In progress

(nothing right now)

## Backlog

- [ ] We need widow and orphan control. For example, The heading 'That Hurts!' in the current HTTBD is the last line of the page.
- [ ] We need to remove the newlines in the title, that are used for laying out the title page, as they carry over to the running page headers.
- [ ] book.yaml is becoming a style sheet. This is wrong. Style should be separate, so we can have templates. move all style related items to style.yaml
- [ ] Import word doc should extract images into media directory.
- [ ] Make hyperlinks work properly. Ebooks just work, but for print hyperlinks should convert to anchor text, followed by the destination URL in parentheses.
- [ ] **Afterword treatment.** `190-conclusion.md` is currently swept into Part IV
  because there's no later part divider. Decide whether it should sit outside the
  parts (e.g. a small "Afterword" divider) or stay where it is.
  (The related Introduction case is done: chapters before the first part are now
  front matter with roman folios. An afterword could get the inverse treatment —
  an `{.unnumbered}` part divider already suppresses the "PART N" label.)
- [ ] **Copyright credit bleed.** The wrap-test PDF showed the copyright page's
  "Formatted with Pandoc and Typst." styling appearing to influence later pages.
  Investigate whether a `set text(size: 0.85em)` inside the copyright `page[…]`
  block is leaking. (May not actually be leaking — verify first.)

## Done (recent)

- Running heads (opt-in `running-heads: true`, print only): verso = book
  title, recto = current chapter title, centred small caps. Suppressed in
  front matter and on part/chapter opener pages. tests/frontmatter has it on.
- Blind folios on display pages: title, copyright, and every part-divider
  page count but show no folio (custom footer replaces typst's default).
  Chapter openers keep theirs. (FEATURES.md #7.)
- No hyphenation in any title: headings at every level (and their
  PART/CHAPTER labels), the title page, the also-by page, and contents
  entries all wrap whole words, ragged right. Body text still justifies and
  hyphenates. Long-title fixtures added to tests/headings (toc now on there).
- Part divider text: blocks between a part heading and the next heading
  (i.e. text under the title in the part's own file) now print on the
  divider page beneath the title, instead of spilling onto the next page.
  No markup needed; parts.lua wraps them in book.typ's `#part-text[...]`.
- Contents page redesign: no dot leaders, page numbers in a right-aligned
  column, part entries as letterspaced caps with spelled-out numbers
  ("PART TWO · BASICS") set off by space, chapters indented beneath their
  part; "Contents" title in the heading font over a rule.
- Front-matter roman folios (i, ii, ...): displayed from the contents page on,
  blind on title/copyright/also-by. Chapters before the first part divider
  (an introduction) are front matter — roman folios, listed in the contents
  before Part One; arabic page 1 starts at the first part heading.
  New fixture: tests/frontmatter.
- Fixed `.unnumbered` on the print side: _body.typ never imported the state
  bindings from book.typ, so any book actually using the class failed to
  compile (BODY_PRELUDE now imports part-num and unnumbered-next).
- Page break on opt-in `{.new-page}` headings (parts.lua); applied to the six
  `### Step N` headings in `150-modern-version.md`.
- Part IV hyphenation fix: disabled hyphenation on the part-divider show rule
  so "Basic Step and Variations" wraps on a space, not mid-word.
- Wrap-it integration: `.wrap-right` / `.wrap-left` attribute on markdown images.
- Pandoc lua filters: `wrap.lua` and `parts.lua` under `templates/`.
- Renamed rotary chapters to 3-digit prefixes (010-, 020-, ...).
- Demoted all chapter headings by one level so Part = H1, Chapter = H2.
- Four part dividers (Part I-IV) added to rotary book.
