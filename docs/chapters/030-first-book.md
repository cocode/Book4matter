## Your First Book

A book4matter book is just a folder. At minimum it holds two YAML files and a
`chapters/` directory:

```
my-book/
  book_metadata.yaml
  book_style.yaml
  chapters/
    010-introduction.md
    020-first-steps.md
  media/
  out/
```

Only one of the two YAML files is strictly required --- book4matter reads both
and merges them --- but keeping identity in `book_metadata.yaml` and appearance in
`book_style.yaml` is the convention this manual follows. The `chapters/`
directory holds one Markdown file per chapter or part, `media/` holds images
referenced from chapters as `../media/...`, and `out/` is where build output
lands.

### Chapter order

By default every `chapters/*.md` file is included, sorted by filename in
*natural* order, so `2.md` comes before `10.md`. Numeric prefixes such as `010`,
`020`, `030` make the order explicit and leave gaps to slot a new file between
two existing ones without renumbering. If you would rather order the files by
hand, list them under a `chapters:` key in `book_metadata.yaml`; then only those
files, in that order, are built.

Plain `.txt` files count as chapters too, and a chapter file need not carry a
heading at all: a novel can be nothing but numbered text files. The Novels and
Flat Books chapter covers that low-structure path.

### Building each format

```
# For printing or KDP upload.
./run.sh print my-book/
# For sending someone a PDF.
./run.sh pdf my-book/
# For e-readers.
./run.sh epub my-book/
# For the web.
./run.sh html my-book/
```

Output always lands in the book's `out/` directory, named after the book's
title: `print` writes `<title>-interior.pdf`, `pdf` writes `<title>.pdf`, `epub`
writes `<title>.epub`, and `html` writes `<title>.html`.

Use `print` when you are printing a book or uploading an interior to KDP. It
omits the cover and removes internal link annotations, because print platforms
such as KDP expect the cover as a separate file and may reject hyperlinks inside
an interior PDF. Use `pdf` when you will send someone a PDF. It can include the
cover and keeps hyperlinks live for the table of contents, footnotes, and web
links.

### The bundled example

The repository ships a tiny example book. Build it to confirm your setup works
before pointing the tool at your own manuscript:

```
# Writes example/out/the-pocket-pipeline-interior.pdf.
./run.sh print example/
```
