# Afterword {.section}

## Origins

Book4matter began due to frustration with Microsoft Word. I wanted to not have to worry about formatting
while I was writing. And writing in Word meant that version control really wasn't an option.

Book4matter allows you to write once, in plain text, and publish to multiple formats.


## Goals

Book4matter makes writing my books easier. I hope it will do the same for you. Let us know, via github, about any issues you run into.

## Dependencies

The heavy lifting for the project is done by two projects --- [Pandoc](https://pandoc.org),
which reads more document formats than anyone reasonably should, and
[Typst](https://typst.app), which makes fine typesetting programmable without a
LaTeX-shaped learning cliff. Book4matter is mostly a thin, opinionated layer that
aims them at the narrow job of building a book.

We also use epubcheck to validate the output of EPUB generation.


