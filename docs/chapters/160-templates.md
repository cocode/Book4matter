## Editing the Templates

Beyond fonts and the `book_style.yaml` knobs, the look is governed by the
templates baked into the Docker image. You can change them, with one thing
understood up front: **there is no theme or plugin system.** Customizing the
templates means editing the project's own template files and rebuilding the
image. The change then applies to every book you build with that image, so this
is the path for shaping *your* house style, not for per-book themes.

### The files

- **`templates/book.typ`** --- the print template. It holds the page geometry,
  the title / copyright / "Also by" / contents pages, and the show rules that
  style every heading level. Most print-appearance changes happen here: heading
  sizes and spacing, the title-page layout, the running-head format, the table
  and block-quote styling.
- **`templates/epub.css`** --- the styling for EPUB *and* the HTML outputs. Edit
  this to change how the e-book and the default web page look.
- **`templates/*.lua`** --- the Pandoc filters from the previous chapter. Edit
  these only to change structural behavior: how labels are injected, how wraps
  work, how the contents list is built.

### Applying a change

The templates live inside the image, so after editing one, rebuild:

```
./run.sh --rebuild print mybook/
```

Until you rebuild, the old templates are what run.

### What book.typ expects

`book.typ` is driven by a `meta` dictionary that the tool assembles from your
YAML (you can read it as `_meta.typ` in a `--keep` build). The template consumes
a fixed set of keys --- the ones documented in Part Three. Changing how an
existing value is *used* is a `book.typ` edit on its own. Introducing a brand-new
setting would also mean teaching the tool to pass it through, which is a code
change beyond the scope of styling.

### Restyling the website without touching the template

The HTML output is styled by `epub.css`, but you need not edit that shared file
to restyle the *site*. The generated page is plain, semantic HTML --- a `#TOC`
nav, one `section` per part and chapter, `.part-label` / `.chapter-label` spans
--- so you can layer a separate stylesheet over it and let it win on the cascade.
That is exactly how this manual's own website is built: `docs/build.sh` links a
`book4matter-web.css` into the generated page after the built-in styles. It gives
the site its own look without disturbing the templates that the print and EPUB
outputs share.
