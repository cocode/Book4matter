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
book convention. The openers differ slightly by format:

- **In print**, *every* paragraph's first line is indented, including the one
  that opens a chapter or section. This is the template's house style: no
  flush-left openers.
- **In EPUB and HTML**, the first paragraph after a heading is left flush and the
  paragraphs after it are indented --- the convention readers expect on screen.

So a chapter opens a touch differently in print than on a screen. If you would
rather they match exactly, it is a one-line change in `book.typ` or `epub.css`.

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
and only in print.

### Parts and chapters

A part divider sets its title about a third of the way down the page, rather than
dead centre, with room beneath for optional divider text. Chapters open on a
fresh page under an auto "CHAPTER N" label. Both are numbered automatically, and
chapter numbers run straight through the whole book instead of resetting inside
each part.

### Tables, quotes, and figures

Tables are set in book (booktabs) style: three horizontal rules, no verticals, a
bold header, and tabular figures so columns of numbers align. Block quotes are
set smaller and italic, indented from both margins. A captioned image becomes a
centered figure; figures are *not* auto-numbered ("Figure 1.2"), because trade
books usually refer to an image in prose rather than by number.

### Links in print

A printed link cannot be clicked, so an external web link prints its destination
in parentheses after the text, and email addresses are kept whole so they never
break at a hyphen. On screen --- in EPUB and HTML --- links stay live and bare.
