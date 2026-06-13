# KindlePandocCreator

./rotary was moved to ~/Documents/Writing/Dance/Why/rotary

Markdown -> print-ready **6x9 KDP paperback interior PDF**, via Pandoc -> Typst,
entirely inside Docker. See [DESIGN.md](DESIGN.md) for the full design and
rationale.

## Requirements

- Docker. Nothing else is installed on the host.

## Usage

Build the bundled example:

```bash
./run.sh print example/          # -> example/out/interior.pdf
```

Build your own book (a directory containing `book.yaml` and `chapters/*.md`):

```bash
./run.sh print path/to/book/
```

Import a Word manuscript (splits into chapters on each Heading 1):

```bash
./run.sh import manuscript.docx path/to/book/
```

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

- `book.yaml` — title, author, trim size, margins, font.
- `chapters/*.md` — one file per chapter (or list them in a `chapters:` key).
- `media/` — images, referenced as `../media/...` from chapter files.
- `out/interior.pdf` — the build output.

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

## Page furniture

- **Folios.** Front matter is numbered in lowercase roman (i, ii, …),
  switching to arabic at the first part. Display pages — the title and
  copyright pages, and every part-divider page — show no folio, though they
  still count. Chapter openers keep theirs.
- **Running heads** (opt-in: `running-heads: true` in `book.yaml`). Print
  only. A centred small-caps line at the top of body pages — book title on
  left-hand (verso) pages, current chapter title on right-hand (recto)
  pages. Suppressed in front matter and on any page where a part or chapter
  opens. EPUB ignores the setting (readers paginate themselves).
