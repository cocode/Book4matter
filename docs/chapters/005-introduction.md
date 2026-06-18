## Introduction {.unnumbered}

*Book4matter* turns a folder of Markdown into three books at once: a
print-ready PDF for Amazon Kindle Direct Publishing (KDP), an EPUB for
e-readers, and a standalone HTML page for the web. You write once, in plain
Markdown, and the same source produces all three.

The book you are reading is itself a book4matter project. Its chapters live in
`docs/chapters/` as ordinary Markdown, its identity in `docs/book_metadata.yaml`,
and its appearance in `docs/book_style.yaml`. Building it is the surest proof
that the pipeline works:

```
./run.sh print docs/     # this manual, as a 6x9 interior PDF
./run.sh epub  docs/     # the same, as an EPUB
./run.sh html  docs/     # the same, as one HTML page
```

### What it is for

Book4matter is the tool its author uses to format the books he self-publishes.
It is a command-line tool, run inside Docker, and it is happiest in the hands of
someone comfortable with a terminal. It is deliberately small: it does the
typesetting a self-publisher actually needs and stops there.

### What it does not do

It does not design your cover. KDP accepts the cover as a separate file, so
book4matter produces the **interior** only --- the pages between the covers. It
also will not write your book, fix your grammar, or upload to KDP for you.

### How it fits together

Markdown is the single source of truth. [Pandoc](https://pandoc.org) parses it;
for print it emits a [Typst](https://typst.app) fragment that a small template
typesets into the PDF, and for EPUB and HTML it writes those formats directly.
Keeping the design in a template --- apart from the manuscript --- means one change
restyles every book, and the same words reach print, e-reader, and web without
drifting apart.

The chapters that follow take you from a first build (Part One) through writing
(Part Two) and configuration (Part Three) to the decisions and machinery behind
the output (Part Four).
