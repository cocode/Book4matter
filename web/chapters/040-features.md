# What you get

## Real book typography

Powered by [Typst under the hood](https://book4matter.com/examples/docs/book4matter.html#how-book4matter-uses-typst): proper hyphenation and justification, small
title/copyright/contents front matter, running heads, and quality book faces
(Libertinus Serif for text, a Helvetica-metric sans for headings) bundled right
in the image — no font wrangling. You can use your own fonts, too, of course.

## KDP Support

[Trim sizes, gutter margins](https://book4matter.com/examples/docs/book4matter.html#the-book_style.yaml-file) that scale with page count, and an EPUB that clears
the same validator KDP uses. The defaults aim at a US 6×9 trade paperback that
uploads clean.

## Markdown you already know

[Standard Pandoc Markdown](https://book4matter.com/examples/docs/book4matter.html#markdown): headings, emphasis, lists, block quotes, footnotes,
tables, images, and hyperlinks. Plain `.txt` works too, for novelists who want
nothing but words and scene breaks.

## Novels and non-fiction alike

Use `#` for a chapter and `##` for a section within it. For a book with parts,
set `use-parts: true` in `book_style.yaml` to make `#` a part and `##` a chapter. A novel can also use
[numbered chapters with no titles](https://book4matter.com/examples/docs/book4matter.html#novels-and-flat-books).

## Import from Word

Already have a `.docx`? Book4matter can [import it](https://book4matter.com/examples/docs/book4matter.html#importing-from-word), split it into chapter files
on its headings, and pull the embedded images out for you — a running start
instead of a blank page.

## Reproducible by design

You can run everything from a pinned Docker image. No host installs, no network at
build time, and the same inputs produce the same outputs on any machine.
