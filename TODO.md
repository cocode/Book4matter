# TODO

Project-level todo list. Outlives sessions (unlike the harness TaskList tool).
Edit freely; Claude reads and writes it on request.

## Blocked / deferred
- [ ] **Body widow/orphan control.** No single paragraph line stranded at a page
  top/bottom. BLOCKED: Typst 0.14.2 has no `par(widows/orphans)` and no
  block-level equivalent; the only workaround (`breakable: false`) looks worse.
  Decision: SKIP; revisit on a Typst upgrade that adds it. [TODO]

## Out of scope (do NOT implement here)
- **Figure caption system [F#10].** "For humans to resolve / fix the other
  projects" — not a code task for this repo.

## Decisions (resolved)
2. book.yaml split → hard split, no back-compat; merge both files; migrate
   fixtures here, rotary separately.
3. Borderline → table styling, block-quote, print hyperlinks IN; figure
   captions OUT.
