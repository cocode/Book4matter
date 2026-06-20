## Command-Line Reference

Every command runs through `run.sh`, which builds the Docker image if it is
missing and then runs the tool with your current directory mounted inside the
container. The general form is:

```
./run.sh [--rebuild] <command> [arguments]
```

`--rebuild` forces the image to be rebuilt first --- do this after changing a
template or updating the tool. The commands are `print`, `epub`, `html`, and
`import`. In each, `bookdir` defaults to the current directory.

### print

```
./run.sh print [bookdir] [--pages N] [--keep] [--build-id ID]
```

Builds the interior PDF to `bookdir/out/<title>-interior.pdf`.

- `--pages N` --- the estimated final page count. It selects a KDP-appropriate
  inside gutter (see the margins table in the previous chapter). Omit it and a
  generous default gutter is used. Any `margins` in `book_style.yaml` win
  regardless.
- `--keep` --- keep the intermediate Typst files (`_body.typ`, `_meta.typ`,
  `book.typ`, `main.typ`) in `out/` instead of deleting them. Handy when you want
  to read the generated Typst.
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
./run.sh html [bookdir]              # whole book: one standalone page + clickable TOC
./run.sh html toc [bookdir]          # just the contents, as a link-free fragment
./run.sh html chapter NN [bookdir]   # one chapter, as an HTML fragment
```

- The whole-book form is a single self-contained page (resources embedded) with a
  clickable table of contents --- the form used for the book4matter website. It
  links an optional `book_style.css` after the embedded styles, so dropping a
  `book_style.css` next to the page (or copying your project's CSS into `out/`
  under that name) themes the site; omit it and the embedded styling stands.
- `toc` emits a `<nav class="book-toc">` of plain, unlinked titles to drop into a
  web page (the in-book anchors would point nowhere off-site).
- `chapter NN` picks one chapter: `NN` matches the leading number in a filename
  (`010-foo.md` is `10`), or a 1-based position in the chapter list, or a
  filename/stem.
- `--build-id` is accepted for parity with the other commands but is not stamped
  on web output.

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
once --- usually the repository's short git hash --- and pass it to each format.
This manual's own `build.sh` does exactly that:

```
BUILD_ID="$(git rev-parse --short=10 HEAD)"
./run.sh print docs/ --build-id "$BUILD_ID"
./run.sh epub  docs/ --build-id "$BUILD_ID"
```
