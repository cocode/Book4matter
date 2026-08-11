## Default Formatting Decisions

The default look is a set of deliberate choices about how a book should read. You
can change any of them --- the next chapters show how --- but it is worth knowing
what they are and why.

### Body text

The body is set justified and hyphenated, so the right margin stays even, with
lining (uniform-height) figures rather than old-style ones. The default face is
Libertinus Serif at 11pt: a quiet, readable book face bundled in the image, so
the default needs no font setup and nothing is fetched from the network.

### Paragraph indents

Paragraphs are set off by a first-line indent rather than by blank space --- the
book convention. In the PDF outputs, `indent:` in `book_style.yaml` chooses
among three styles:

- `all` (the default) --- indent *every* paragraph, including the one that opens a
  chapter or section. The house style: no flush-left openers.
- `standard` --- leave the opening paragraph after a heading flush and indent the
  rest. The classic trade-book look, and what EPUB and HTML already do, so
  `standard` makes print match them.
- `none` --- no indents at all; paragraphs are told apart by the space between
  them (block style).

EPUB and HTML always use the `standard` look --- readers expect it on screen and
can override it anyway --- so `indent:` is a PDF setting.

### Headings

Headings are set in a sans-serif face (Liberation Sans by default), in capitals,
ragged-right: they never justify or hyphenate, so a long title wraps whole words
instead of stretching or splitting. Each level has its own job --- a part is a
divider page, a chapter opens a fresh page, and the lower levels are run-in
section headings.

### Page numbers and running heads

Front matter carries lowercase roman folios (i, ii, iii ...); arabic numbering
begins at the first part. Display pages --- the title, copyright, and "Also by"
pages, and every part divider --- show no folio, though they still count, so the
numbering downstream stays correct. Running heads are off by default; when on,
they appear only on ordinary body pages (never where a part or chapter opens),
and only in the PDF outputs.

### Parts and chapters

A part divider sets its title about a third of the way down the page, rather than
dead centre, with room beneath for optional divider text. Chapters open on a
fresh page with a centered numeral over a short rule and the title centered
beneath (set `chapter-style: left` for a flush-left "CHAPTER N" opener instead).
Both are numbered automatically, and chapter numbers run straight through the
whole book instead of resetting inside each part.

Two more `book_style.yaml` switches, `parts-recto` and `chapters-recto`, make
parts or chapters begin on a recto (right-hand) page, inserting a blank page when
needed --- the traditional way to open a chapter in a well-set book. The inserted
blank is counted in the page numbering (it may show a folio), and the main matter
still starts at page 1.

### Figures

A captioned image becomes a centered figure; figures are *not* auto-numbered
("Figure 1.2"), because trade books usually refer to an image in prose rather
than by number. How tables, quotes, footnotes, and links are set is described
where you write them, in the *Tables, Quotes, Footnotes, and Links* chapter.

### Links in PDF and print

The `pdf` command is for screen reading, so hyperlinks stay live there: the
table of contents, footnotes, cross-references, and external links are all
clickable. The `print` command is for physical books and KDP interiors, which
forbid clickable annotations --- so instead of dropping the reader, a print
cross-reference to another part of the book prints as its text plus the target
page, `"Rotation" (page 42)`, with the page number resolved at build time.
External web links print their destination in parentheses after the visible
text, and email addresses are kept whole so they never break at a hyphen. EPUB
and HTML links stay live and bare.
