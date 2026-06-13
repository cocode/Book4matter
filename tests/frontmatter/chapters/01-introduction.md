## Introduction {.unnumbered}

This chapter-level heading sits before the first part divider, which makes
it front matter. Three things should be true of it in the print build.
First, its pages carry roman folios — the front matter starts counting at
the title page, so this opening page should display something like "iv" at
the foot, not an arabic numeral and not a blank. Second, it appears in the
table of contents *before* Part One, set flush left rather than indented,
because it belongs to no part. Third, its contents entry shows a roman page
number, while the entries for the parts and chapters that follow show
arabic ones.

Because the heading carries the `unnumbered` class, no "CHAPTER N" label is
printed above the title, and the chapter count is not advanced — the first
real chapter after Part One is still Chapter 1.

The rest of this chapter is filler, present only to push the introduction
past a single page so the build demonstrates roman folios advancing: the
second page of this introduction should display the next roman numeral in
sequence. Real front matter earns its length with acknowledgements and
apologies; a test fixture has to make do with self-description.

A book's front matter is everything before the story starts: the title
page, the copyright page, perhaps a dedication, the table of contents, and
any prefatory text. Printers traditionally number these pages in lowercase
roman numerals, reserving arabic numerals for the main text. The convention
survives because it is useful: the front matter can grow or shrink late in
production — a foreword commissioned at the last minute, a second page of
acknowledgements — without renumbering the body of the book.

The display pages at the very front — title, copyright — are counted but
show no folio at all. Publishers call these blind folios. The first page to
actually display its number is usually the table of contents, which is why
a contents page often opens on "v" or "vii" despite being nowhere near the
fifth or seventh page a reader turns.

This paragraph and the ones that follow exist purely as ballast. The text
block of a six-by-nine trim at eleven points holds roughly three hundred
and fifty words, so the introduction needs a bit more than that to spill
onto a second page. It does not need to be interesting; it needs only to be
long, and prose written to be long rather than interesting has a venerable
history in the law, in academia, and in the small print of insurance
policies, where it is produced by professionals.

Consider, while we pad, what the arabic switch actually tests: the pandoc
filter finds the first level-one heading in the whole document and injects
the numbering change just before it. If this paragraph were instead the end
of the book — if no part heading ever followed — the filter would place the
switch at the very top, and page one would be the first page of this
introduction. That fallback keeps books without parts working exactly as
they did before front-matter support existed.

One last paragraph for good measure, so that the page break lands safely
inside the filler regardless of small future changes to leading, margins,
or font metrics. If you can read this on the second page of the
introduction, beneath a roman folio one step past the previous page's, the
front matter is doing its job.
