```{=html}
<nav class="site-nav" aria-label="Book4matter navigation">
<a href="https://book4matter.com/">Home</a>
<a href="https://book4matter.com/examples/docs/book4matter.html" aria-current="page">User Manual</a>
<a href="https://book4matter.com/#examples">Examples</a>
<a href="https://app.book4matter.com/">Web app</a>
<a href="https://github.com/cocode/Book4matter/">GitHub</a>
</nav>
```

## ![](../media/book4matter-logo.png){width="1.5em" style="vertical-align: middle"} User Manual {#introduction .unnumbered}

This is the **Book4matter User Manual**: documentation for writing, configuring,
and publishing your books.

*Book4matter* turns a manuscript into four outputs: a PDF for print
ready for Amazon Kindle Direct Publishing (KDP), a PDF for screens to send to
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

Use [book4matter web](https://app.book4matter.com/) in your browser or run
book4matter cmd on your computer. This manual covers the manuscript markup,
book settings, and output formats for both.

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
