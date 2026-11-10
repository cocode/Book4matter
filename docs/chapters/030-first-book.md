## Your First Book

For book4matter cmd, keep your book in a project folder like this one.
You can also open the same project in book4matter web with **Add a folder**.

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

book4matter cmd reads and merges the settings in the two YAML files. It needs
at least one of them. In book4matter web, both files are optional. This manual
keeps identity in `book_metadata.yaml` and appearance in `book_style.yaml`. The `chapters/`
directory holds one Markdown file per chapter or part, `media/` holds images
referenced from chapters as `../media/...`, and book4matter cmd writes its output in `out/`.

### Chapter order

By default every `chapters/*.md` file is included, sorted by filename in
*natural* order, so `2.md` comes before `10.md`. Numeric prefixes such as `010`,
`020`, `030` make the order explicit and leave gaps to slot a new file between
two existing ones without renumbering. With book4matter cmd, if you would rather order the files by
hand, list them under a `chapters:` key in `book_metadata.yaml`; then only those
files, in that order, are built. In book4matter web, the files you add determine the chapter set.

If you don't need chapter titles, you can just put one chapter per file, and Book4matter will
assume each file is a chapter and number them. You can still put titles on some chapters, like
"# Introduction", "# Afterword".

The Novels and Flat Books chapter covers that low-structure path.

Plain `.txt` files are treated as pure text: Markdown commands such as `#`,
`*emphasis*`, and links appear literally. Leave a blank line between paragraphs
and put each chapter in its own file. Use `.md` for titles and other formatting.

### Choosing an output format

book4matter cmd writes each format into the book's `out/` directory, named after the book's
title: `print` writes `<title>-interior.pdf`, `pdf` writes `<title>.pdf`, `epub`
writes `<title>.epub`, and `html` writes `<title>.html`.

Use `print` when you are printing a book or uploading an interior to KDP. It
omits the cover and removes internal link annotations, because print platforms
such as KDP expect the cover as a separate file and may reject hyperlinks inside
an interior PDF. Use `pdf` when you will send someone a PDF. It can include the
cover and keeps hyperlinks live for the table of contents, footnotes, and web
links.

### The bundled examples

The repository ships with several examples.

* example
* novel
* docs

#### Example

The `example/` folder contains *The Pocket Pipeline*. To try it with your
own manuscript, see [Start a book from an example](#project-quickstart).

#### Novel

You can also look at the ./novel example, which shows simplified formatting.

#### Docs

And you can also look at our documentation, in ./docs, which is also a Book4matter project.
