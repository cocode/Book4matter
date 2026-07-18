## Introduction {.unnumbered}

*Book4matter* turns a folder of text formatted with Markdown into four outputs: a print-ready
interior PDF for Amazon Kindle Direct Publishing (KDP), a digital PDF to send to
readers, an EPUB for e-readers, and a standalone HTML page for the web. You
write once, in plain Markdown, and the same source produces all four.

It can also format the pages for printing locally, for binding into a book.

The book you are reading is itself a book4matter project. Its chapters live in
`docs/chapters/` as ordinary Markdown, its identity in `docs/book_metadata.yaml`,
and its appearance in `docs/book_style.yaml`.

### What it is for

Book4matter is a tool used to format the books for self-publishing. You
write in Markdown, simple text with a few simple options. Then you can distribute
it as PDF, EPUB, or HTML, or upload the print version to Amazon KDP for printing.

It is a command-line tool, run inside Docker, and it is happiest in the hands of
someone comfortable with a terminal. It is deliberately small: it does the
typesetting a self-publisher actually needs and stops there.

### What it does not do

It does not design your cover. KDP accepts the print cover as a separate file,
so the `print` command produces the **interior** only --- the pages between the
covers. The `pdf`, `epub`, and whole-book `html` outputs can include a cover
image if you supply one. Book4matter also will not write your book, fix your
grammar, or upload to KDP for you.

### How it fits together

Markdown is the single source of truth. [Pandoc](https://pandoc.org) parses it;
for the two PDF outputs it emits a [Typst](https://typst.app) fragment that a
small template typesets into pages, and for EPUB and HTML it writes those
formats directly.
Keeping the design in a template --- apart from the manuscript --- means one change
restyles every book, and the same words reach print, e-reader, and web without
drifting apart.

The chapters that follow take you from a first build (Part One) through writing
(Part Two) and configuration (Part Three) to the decisions and machinery behind
the output (Part Four).

### Building Your Book

The commands to build your book are simple:

```
# This manual, as a 6x9 print interior PDF.
./run.sh print docs/
# The same pages as a digital PDF, with live links.
./run.sh pdf docs/
# The same book as an EPUB.
./run.sh epub docs/
# The same book as one HTML page.
./run.sh html docs/

# The same book, four pages per sheet, formatted for folding and binding.
./run.sh impose docs/out/book4matter-interior.pdf
```


