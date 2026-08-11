# Book4matter   (Book Formatter)

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

You can skip this section, if you don't want to bind your own books.

`impose` rearranges a PDF's pages **two-up into signatures** so you can print it
on a home printer, fold the sheets, and bind the book by hand. A *signature* is
a small stack of sheets folded together down the middle; several signatures are
then stacked and sewn or glued into a codex.

```bash
./run.sh print docs/                                  # -> the interior PDF
./run.sh impose docs/out/book4matter-interior.pdf     # -> docs/out/book4matter-signatures.pdf
```

The imposed PDF is written **next to its input** — so
`docs/out/book4matter-interior.pdf` produces
`docs/out/book4matter-signatures.pdf` — whether you run from the repo root or
from inside the book. Then **print it double-sided, flipping on the *short*
edge**, fold each signature at the centre, and stack and bind them.

Options:

- `--paper letter` (default) or `--paper a4` — the sheet you print on. Pages are
  scaled to fit each half-sheet, so any trim size works.
- `--signature N` — sheets per signature (default `4` — 4 sheets of paper, i.e.
  16 pages). Each sheet folds to 4 pages.
- `--single` — impose the whole book as one folded booklet (saddle-stitch),
  best for thin books you staple through the fold.
- `--margin INCHES` — safe margin inside each half-page (default `0.25`), keeping
  content out of the printer's no-print zone and off the fold.
- `-o NAME` — output filename (still written beside the input).

`impose` takes *any* PDF, not just a book4matter interior. Its streams are
Flate-compressed, so the imposed PDF stays about the size of the input.

The first run builds the Docker image. After changing the template or CLI, force
a rebuild:

```bash
./run.sh --rebuild print example/
```

To rebuild the image without running a build:

```bash
docker build -t book4matter .
```


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
