## How Book4matter Uses Typst

### Two routes from one source

Markdown is the single source. Pandoc parses it, and from there the formats
diverge:

- **Print and digital PDF** take the long way round. Pandoc converts the
  Markdown into a Typst *body fragment*, and Typst typesets that into pages.
- **EPUB and HTML** are written by Pandoc directly.

Why route PDF output through Typst at all? Because Typst alone cannot produce
EPUB, and authoring straight in Typst would forfeit the EPUB and HTML outputs.
With Pandoc in the middle, all four outputs come from the same Markdown. Typst
earns its place on the page-layout side: it is fast, needs no enormous TeX
installation, embeds fonts automatically, and ships in the same `pandoc/typst`
image.

### What a PDF build generates

Build with `--keep` and you can read the intermediate Typst the pipeline writes
into `out/`:

- **`_meta.typ`** --- a Typst dictionary built from your `book_metadata.yaml` and
  `book_style.yaml`: title, authors, trim, margins, fonts, and the rest.
- **`_body.typ`** --- Pandoc's Typst rendering of your chapters, with a short
  prelude of imports prepended.
- **`book.typ`** --- the template, copied in from the image.
- **`main.typ`** --- the short entry point that ties them together:

```
#import "book.typ": book
#import "_meta.typ": meta
#show: book.with(meta)
#include "_body.typ"
```

Typst compiles `main.typ` into either the print interior PDF or the digital PDF.
Without `--keep`, these files are removed after the build.

The two commands share this pipeline, then differ in the metadata passed to the
template. `print` removes internal hyperlinks and omits the cover; `pdf` keeps
links live and includes the configured cover image as the first page.

### The template

`book.typ` owns the PDF page geometry --- the exact trim, the asymmetric binding
gutter used by print books, font embedding, and page numbering --- and the
styling: the title and copyright pages, the table of contents, and the show
rules that turn each heading level into a part, a chapter, or a section. That
styling is adapted from the MIT-0-licensed *ilm* Typst template.

### The Pandoc filters

Small Lua filters bridge Markdown and each output so the same source behaves
consistently across formats:

- **PDF outputs:** `parts.lua` numbers the parts, acts on the `{.unnumbered}`,
  `{.new-page}`, and `{.section}` classes, switches the front matter over to the
  main-matter page numbers, and lifts part-divider text onto the divider page;
  `wrap.lua` turns a `.wrap-left` / `.wrap-right` image into a Typst text wrap and
  centers a `.center` image.
- **EPUB and HTML:** `epub-parts.lua` injects the "Part N" / "Chapter N" labels,
  `epub-wrap.lua` floats wrap images with CSS, and `toc-list.lua` builds the
  link-free contents used by `html toc`.

### Fonts

Typst embeds whatever fonts a build uses. The defaults (Libertinus Serif and
Liberation Sans) live in the image. For a custom face, Typst also searches a
per-book `fonts/` folder --- the subject of the next chapter --- so the fonts
travel with the book and nothing is installed or downloaded. The `wrap-it`
package behind text wrapping is vendored into the image as well, so a compile
never has to reach the network.
