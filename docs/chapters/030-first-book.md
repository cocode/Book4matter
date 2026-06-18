## Your First Book

A book4matter book is just a folder. At minimum it holds two YAML files and a
`chapters/` directory:

```
my-book/
  book_metadata.yaml   # what the book is:  title, author, rights, language
  book_style.yaml      # how it looks:      trim, margins, fonts
  chapters/            # one Markdown file per chapter (or per part)
    010-introduction.md
    020-first-steps.md
  media/               # images, referenced from chapters as ../media/...
  out/                 # build output lands here
```

Only one of the two YAML files is strictly required --- book4matter reads both
and merges them --- but keeping identity in `book_metadata.yaml` and appearance in
`book_style.yaml` is the convention this manual follows.

### Chapter order

By default every `chapters/*.md` file is included, sorted by filename in
*natural* order, so `2.md` comes before `10.md`. Numeric prefixes such as `010`,
`020`, `030` make the order explicit and leave gaps to slot a new file between
two existing ones without renumbering. If you would rather order the files by
hand, list them under a `chapters:` key in `book_metadata.yaml`; then only those
files, in that order, are built.

### Building each format

```
./run.sh print my-book/     # -> my-book/out/<title>-interior.pdf
./run.sh epub  my-book/     # -> my-book/out/<title>.epub
./run.sh html  my-book/     # -> my-book/out/<title>.html
```

Output always lands in the book's `out/` directory, named after the book's
title. The PDF carries an `-interior` suffix, matching KDP's vocabulary: the
**interior** and the **cover** are uploaded to KDP as two separate files.
Book4matter produces the interior only, and your cover never appears in the print
PDF. (For EPUB you *may* supply a `cover:` image; see the metadata reference.)

### The bundled example

The repository ships a tiny example book. Build it to confirm your setup works
before pointing the tool at your own manuscript:

```
./run.sh print example/     # -> example/out/the-pocket-pipeline-interior.pdf
```
