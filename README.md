# <img src="docs/media/book4matter-logo.png" alt="" width="48" height="48" align="absmiddle"> Book4matter (Book Formatter)

See our web page at https://book4matter.com/ and our 
[Book4matter Web](https://github.com/cocode/book4matter-web) GitHub.

Book4matter is a tool for formatting books for publication. It takes plain text or Markdown (pandoc flavored) and converts it to:

1. PDF for screen (links are clickable)
1. PDF for print (links have page numbers)
1. EPUB
1. HTML

This project uses pandoc to convert plain text or Markdown to HTML or ePub. For pdf/print, pandoc outputs to Typst, which does the print formatting. This setup allows you to generate EPUB, HTML and PDFs from the same source. It also separates the styling from the source, so you can apply the same style to multiple books, or change the style of multiple books by making a change in one place.

Using Markdown rather than plain text will give you more control of the output, and allow features like hyperlinks and images.

## Getting started

- **book4matter web** runs in your browser. Add a manuscript and choose an output format. [Open the web app](https://app.book4matter.com/)
- **book4matter cmd with Docker** uses the published image. [Docker instructions](https://book4matter.com/examples/docs/book4matter.html#option-1-the-docker-hub-image)
- **book4matter cmd from source** runs on your computer with local dependencies. [Source instructions](https://book4matter.com/examples/docs/book4matter.html#option-2-install-directly-without-docker)

To rebuild the Docker image from this checkout, run `./run.sh --rebuild`. The runtime uses Debian 12 (Bookworm) slim. The Dockerfile pins the base image by digest and fixes both the Debian and Debian Security package repositories to dated snapshots.

## Documentation

The [user manual](https://book4matter.com/examples/docs/book4matter.html) covers both web and cmd. Jump to
[Markdown](https://book4matter.com/examples/docs/book4matter.html#markdown), [images](https://book4matter.com/examples/docs/book4matter.html#images-figures-and-scene-breaks),
[table of contents settings](https://book4matter.com/examples/docs/book4matter.html#contents-settings), or [indexes](https://book4matter.com/examples/docs/book4matter.html#an-alphabetical-index-of-terms).
The manual's source is in [docs/](docs/).

For development, see the [Docker image instructions](README-DEV.md) and [design notes](DESIGN.md).

## Examples

Book4matter comes with three example projects. The documentation, mentioned above. An example, in ./example
that uses multiple features of Book4matter. And ./novel, which demonstrates the simplest way to use Book4matter. 

## History

Note that this project was formerly "Kindle Pandoc Creator", so you may see references to that name,
or to "kpc" surviving in the code and documentation.

## Using book4matter cmd

See the [project layout](https://book4matter.com/examples/docs/book4matter.html#your-first-book) and
[command-line reference](https://book4matter.com/examples/docs/book4matter.html#command-line-reference) for building a book,
importing a Word manuscript, exporting HTML, and printing folded signatures.
