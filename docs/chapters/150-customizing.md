## Customizing the Output

Most of what you will want to change needs no template editing at all --- it is a
line in `book_style.yaml`. This chapter covers the customization that is built
in; the next goes further, into the templates themselves.

### Restyling through book_style.yaml

Trim size, margins, body and heading fonts, type size, the Contents page, running
heads, the title rule --- all of these are keys in `book_style.yaml` (see the
reference in Part Three). Because appearance lives in that one file, you can copy
or symlink a single `book_style.yaml` across several books to give them a shared
house style, and restyle them all by editing it in one place. The manuscript and
its metadata never change.

### Using a custom font

The default faces are bundled, but you can use any font you have licensed:

1. Make a `fonts/` folder at the root of your book.
2. Drop the `.ttf` or `.otf` files into it.
3. Name the family in `book_style.yaml`:

```
font: "EB Garamond"
heading-font: "Cormorant"
```

When a `fonts/` folder is present, book4matter points Typst at it automatically,
so the fonts travel with the book project --- no system install, no image
rebuild. System and bundled fonts are still searched, so a missing `fonts/`
folder is fine. The PDF builds embed whatever is used, so the font's license
must permit PDF embedding.

True to this project's grain, prefer a real, licensed book face that you keep
with the project over pulling one from a web font service. It keeps the build
self-contained and the typography under your control.

### Fonts in EPUB and HTML

EPUB and HTML deliberately do *not* embed your custom fonts. `epub.css` names
only the generic `serif` and `sans-serif` families and lets the reader's device
choose --- which is what readers expect, and what lets them override fonts
anyway. A custom `font:` therefore affects the two PDF outputs only.
