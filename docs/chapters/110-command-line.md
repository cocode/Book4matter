## Command-Line Reference

Every command runs through `run.sh`, which builds the Docker image if it is
missing and then runs the tool with your current directory mounted inside the
container. The general form is:

```
./run.sh [--rebuild] <command> [arguments]
```

`--rebuild` forces the image to be rebuilt first --- do this after changing a
template or updating the tool. The commands are `print`, `pdf`, `epub`, `html`,
`import`, and `impose`. For the book-building commands, `bookdir` defaults to the
current directory.

### print

```
./run.sh print [bookdir] [--pages N] [--keep] [--no-parts] [--build-id ID]
```

Builds the print interior PDF to `bookdir/out/<title>-interior.pdf`. Use this
for KDP upload or for a file you intend to print as a book. The print interior
does not include the cover, because KDP takes the print cover as a separate
upload. It also removes internal hyperlinks from the table of contents,
footnotes, and cross-references, because Amazon KDP enforces no hyperlinks in a
print interior. External web links are converted to visible text plus their
destination, as in `CLICK HERE (https://www.example.com)`.

- `--pages N` --- the estimated final page count. It selects a KDP-appropriate
  inside gutter (see the margins table in the previous chapter). Omit it and a
  generous default gutter is used. Any `margins` in `book_style.yaml` win
  regardless.
- `--keep` --- keep the intermediate Typst files (`_body.typ`, `_meta.typ`,
  `book.typ`, `main.typ`) in `out/` instead of deleting them. Handy when you want
  to read the generated Typst.
- `--no-parts` --- treat `#` headings as chapters, not parts, shifting every
  heading down one level. See the Novels and Flat Books chapter.
- `--build-id ID` --- a printing identifier, printed as "Printing: *ID*" on the
  copyright page.

### pdf

```
./run.sh pdf [bookdir] [--pages N] [--keep] [--no-parts] [--build-id ID]
```

Builds a digital PDF to `bookdir/out/<title>.pdf`. Use this when you will send
someone a PDF directly. It uses the same page layout as `print`, but keeps
hyperlinks live for the table of contents, footnotes, cross-references, and
external links. If `book_metadata.yaml` has a `cover:` image, the digital PDF
includes it as the first page.

- `--pages N` --- the estimated final page count, using the same gutter logic as
  `print`.
- `--keep` --- keep the intermediate Typst files in `out/`.
- `--no-parts` --- treat `#` headings as chapters, not parts (as for `print`).
- `--build-id ID` --- a printing identifier, printed as "Printing: *ID*" on the
  copyright page.

### epub

```
./run.sh epub [bookdir] [--no-check] [--build-id ID]
```

Builds an EPUB 3 to `bookdir/out/<title>.epub`. The result is validated with
epubcheck --- the same kind of check KDP runs on upload --- and validation errors
fail the build.

- `--no-check` --- skip the epubcheck step.
- `--build-id ID` --- appended to the rights line in the EPUB metadata.

The EPUB cover, if any, comes from the `cover:` key in `book_metadata.yaml`.

### html

```
# Whole book: one standalone page with a clickable table of contents.
./run.sh html [bookdir]
# Just the contents, as a link-free fragment.
./run.sh html toc [bookdir]
# One chapter, as an HTML fragment.
./run.sh html chapter NN [bookdir]
```

- The whole-book form is a single self-contained page (resources embedded) with a
  clickable table of contents --- the form used for the book4matter website. It
  links an optional `book_style.css` after the embedded styles, so dropping a
  `book_style.css` next to the page (or copying your project's CSS into `out/`
  under that name) themes the site; omit it and the embedded styling stands. If
  `book_metadata.yaml` has a `cover:` image, the whole-book page embeds it near
  the top.
- `toc` emits a `<nav class="book-toc">` of plain, unlinked titles to drop into a
  web page (the in-book anchors would point nowhere off-site).
- `chapter NN` picks one chapter: `NN` matches the leading number in a filename
  (`010-foo.md` is `10`), or a 1-based position in the chapter list, or a
  filename/stem.
- `--build-id` is accepted for parity with the other commands but is not stamped
  on web output.

### impose

```
./run.sh impose <file.pdf> [--paper P] [--signature N] \
  [--single] [--margin INCHES] [-o NAME]
```

Rearranges a PDF two-up into printable signatures for home binding. It is
separate from the `print` command: KDP and commercial print shops impose pages
for you, but `impose` is useful when you are printing on a home printer, folding
the sheets, and binding the book yourself.

`impose` takes any PDF, not just a book4matter interior. The output is written
next to its input, so `docs/out/book4matter-interior.pdf` produces
`docs/out/book4matter-signatures.pdf`. Print the result double-sided, flipping on
the short edge, then fold each signature down the middle.

- `--paper letter` or `--paper a4` --- the sheet you print on. The default is
  `letter`.
- `--signature N` --- sheets per signature. The default is `4`, which makes
  16-page signatures because each sheet folds to four pages.
- `--single` --- impose the whole PDF as one folded booklet, useful for thin
  saddle-stitched work.
- `--margin INCHES` --- safe margin inside each half-page cell. The default is
  `0.25`.
- `-o NAME` or `--output NAME` --- output filename, still written beside the
  input.

### import

```
./run.sh import <file.docx> [bookdir] [--no-split] [--force]
```

Converts a Word manuscript into `chapters/*.md` plus an extracted `media/`
folder, splitting the document into one file per Heading 1.

- `--no-split` --- write a single Markdown file instead of splitting on H1.
- `--force` --- overwrite a `chapters/` directory that already has files.

The Importing from Word chapter covers this in full.

### Stamping builds with --build-id

`--build-id` is how you make a given printing identifiable. Compute the value
once --- usually the repository's short git hash --- and pass it to the outputs
that stamp it. This manual's own `build.sh` does exactly that:

```
BUILD_ID="$(git rev-parse --short=10 HEAD)"
./run.sh print docs/ --build-id "$BUILD_ID"
./run.sh pdf docs/ --build-id "$BUILD_ID"
./run.sh epub docs/ --build-id "$BUILD_ID"
```
