# Book4matter   (Book Formatter)

See our web page at https://cocode.github.io/Book4matter/

Book4matter is a tool for formatting books for publication. It takes plain text or Markdown (pandoc flavored) and converts it to:

1. PDF for printing
1. PDF for sharing, as a PDF
2. ePub
3. HTML

This project uses pandoc to convert plain text or Markdown to HTML or ePub. For pdf/print, pandoc outputs to Typst, which does the print formatting. This setup allows you to generate EPUB, HTML and PDFs from the same source. It also separates the styling from the source, so you can apply the same style to multiple books, or change the style of multiple books by making a change in one place.

Using Markdown rather than plain text will give you more control of the output, and allow features like hyperlinks and images.

Book4matter is a command line tool, for now, so it's probably best for people that are comfortable with that.

## Documentation

Full documentation is available in ./docs. The documentation is, of course, formatted with 
Book4matter. This lets you quickly tests if your setup is working. 

```bash
./run.sh html docs
```

This will give you HTML formatted documentation in the ./docs/out directory.

See [DESIGN.md](DESIGN.md) for the full design and rationale.

## Examples

Book4matter comes with three example projects. The documentation, mentioned above. An example, in ./example
that uses multiple features of Book4matter. And ./novel, which demonstrates the simplest way to use Book4matter. 

## History

Note that this project was formerly "Kindle Pandoc Creator", so you may see references to that name,
or to "kpc" surviving in the code and documentation.

## What You Provide (Project Layout)

Book4matter expects things in standard places.

- `book_metadata.yaml` — title, author, etc. - See the docs for all options.
- `book_style.yaml` — trim size, margins, font.
- `chapters/*.md` — one file per chapter (or list them in a `chapters:` key).
- `media/` — images, referenced as `../media/...` from chapter files.

This produces
- `out/book-title-interior.pdf` — the build output.


## Docker Build

This project is built on docker, for security/isolation. There is no reason it could not just be run locally. We are working on a webapp version.

## Usage

Build the bundled example:

```bash
./run.sh print example/          # -> example/out/interior.pdf
```
Build your own book (a directory containing `book_metadata.yaml` and `chapters/*.md`):

```bash
./run.sh print path/to/book/
```

Import a Word manuscript (splits into chapters on each Heading 1):

```bash
./run.sh import manuscript.docx path/to/book/
```

Export to HTML — the whole book as one page, just the table of contents (for a
website), or a single chapter:

```bash
./run.sh html example/             # whole book, one HTML page with a clickable TOC
./run.sh html toc example/         # the table of contents only, a link-free fragment
./run.sh html chapter 2 example/   # one chapter, as an HTML fragment
```

`html toc` emits a `<nav class="book-toc">` of plain (unlinked) chapter titles
— the in-book anchors point nowhere off-site — ready to style and drop into a
web page. `html` and `html chapter` reuse the EPUB styling.

### Print & Bind at Home ("Imposition")

Book4matter can impose a PDF two-up into printable signatures for folding and
binding a book by hand. See the `impose` command in the [documentation](./docs).

## Heading conventions

- `# Title` (H1) is a **part**, aka a book section: it gets a divider page and an automatic
  "PART N" label. `## Title` (H2) is a **chapter** ("CHAPTER N"); chapter
  numbers run straight through part boundaries.
- Text written directly beneath a part heading (before the next heading —
  in practice, under the title in the part's own file) prints on the divider
  page itself, beneath the part title.
- Chapters *before* the first part are front matter: roman folios
  (i, ii, ...), listed in the contents ahead of Part One. Arabic page 1 is
  the first part's divider. Use this for an introduction or preface, e.g.
  `## Introduction {.unnumbered}`.
- `{.unnumbered}` on a part or chapter heading suppresses its auto label
  without advancing the count; `{.new-page}` forces a page break before a
  heading.
- 
  You can elect not to use Parts. See the documentation for details.

## Images

A standalone image (alone in its paragraph) understands a couple of classes:

- `{.center}` centres a caption-less image on its own line (print and EPUB). A
  captioned image — `![Caption](path)` — is already centred as a figure.
- `{.wrap-right}` / `{.wrap-left}` float the image so the rest of the section's
  text wraps beside it.

Size with `{width="3in"}` (and an optional `height="…"`).

## Page furniture

- **Folios.** Front matter is numbered in lowercase roman (i, ii, …),
  switching to arabic at the first part. Display pages — the title and
  copyright pages, and every part-divider page — show no folio, though they
  still count. Chapter openers keep theirs.
- **Running heads** (opt-in: `running-heads: true` in `book_style.yaml`). Print
  only. A centred small-caps line at the top of body pages — book title on
  left-hand (verso) pages, current chapter title on right-hand (recto)
  pages. Suppressed in front matter and on any page where a part or chapter
  opens. EPUB ignores the setting (readers paginate themselves).
