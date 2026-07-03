# TODO

Project-level todo list. Outlives sessions (unlike the harness TaskList tool).
Edit freely; Claude reads and writes it on request.

- [ ] Next Need to fix import of lists in docx files, they are coming through with hardcoded numbers (1., 2., 3.), instead of automatic list markdown (#., #., #.,), and with extra blank lines between them. Same for unnumbered lists.
- [x] Docker setup is wrong, it's mounting whole directories. This should be in permanent memory.
- [ ] HR does not work in print "A --- scene break renders as * * * in EPUB/HTML but crashes the print build (unknown variable: horizontalrule)"
- [ ] Add a --colophon option that lists the fonts used. Anything else? Maybe that gets the "set with Book4matter, using Pandoc and Typst in Font1, Font2
- [ ] Should we build and publish a docker image?
- [ ] The PDF (as opposed to print) target should have an option to include a cover. As should the epub
- [ ] If there are no headings in chapter files, and there is more than one file, auto-number the chapters by file.

## Blocked / deferred

- [ ] **Body widow/orphan control.** No single paragraph line stranded at a page
  top/bottom. BLOCKED: Typst 0.14.2 has no `par(widows/orphans)` and no
  block-level equivalent; the only workaround (`breakable: false`) looks worse.
  Decision: SKIP; revisit on a Typst upgrade that adds it. [TODO]

## Out of scope (do NOT implement here)
- **Figure caption system [F#10].** "For humans to resolve / fix the other
  projects" — not a code task for this repo.

## book.yaml-> book_metadata.yaml and book_style.yaml.
Currently, we just read both, and keeping metadata from style is just convention.
We should actually split the two, at some point.

## Decisions (resolved)
3. Borderline → table styling, block-quote, print hyperlinks IN; figure
   captions OUT.
