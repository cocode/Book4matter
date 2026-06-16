# Book4matter   (Book Formatter)

This is a tool to take markdown (pandoc flavored) and convert it to:

1. PDF for printing (specifically aimed at kdp, generated via Typst)
2. epub
3. html

This is a personal project I use to format the books I have published. 
It takes markdown, and uses pandoc to convert it to html, or epub. For pdf/print, pandoc outputs 
to Typst, which does the print formatting. This setup allows you to generate epub, html and print
from the same source. It also separates the styling from the source, so you can apply the same style
to multiple books, or change the style of multiple books by making a change in one place.

This is a command line tool, so it's probably best for people that are comfortable with that.


See [DESIGN.md](DESIGN.md) for the full design and rationale.

## Docker Build

This project is build on docker, for security/isolation. There is no reason it could not just be run locally.

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

The first run builds the Docker image. After changing the template or CLI, force
a rebuild:

```bash
./run.sh --rebuild print example/
```

To rebuild the image without running a build:

```bash
docker build -t kindle-pandoc-creator .
```

## Book layout

- `book_metadata.yaml` — title, author
- `book_style.yaml` — trim size, margins, font.
- `chapters/*.md` — one file per chapter (or list them in a `chapters:` key).
- `media/` — images, referenced as `../media/...` from chapter files.
- `out/book-title-interior.pdf` — the build output.

## Heading conventions

- `# Title` (H1) is a **part**: it gets a divider page and an automatic
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
