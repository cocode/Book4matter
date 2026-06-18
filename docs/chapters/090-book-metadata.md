## The book_metadata.yaml File

`book_metadata.yaml` holds the book's identity --- the facts that stay true no
matter how the book is styled. Every key is optional except `title`. Anything you
leave out (or set to an empty string) is simply omitted: no blank author, no
empty copyright line.

**`title`** --- The book's title; defaults to "Untitled". A `\n` in the value
stacks the title across lines on the print title page --- `"The\nRotary\nWaltz"`
sets three lines --- while everywhere else (PDF metadata, EPUB, running heads)
the breaks collapse to spaces.

**`subtitle`** --- A subtitle, set beneath the title on the title page and
carried into the EPUB. Turn on `title-rule` (in `book_style.yaml`) to draw a rule
between the two.

**`author`** (or **`authors`**) --- One name as a string, or several as a YAML
list. Either key works. The author appears on the title page, in the PDF and
EPUB metadata, and in the "Also by" heading.

```
author: "Thomas Hill"
# --- or ---
authors:
  - "Ada Lovelace"
  - "Charles Babbage"
```

**`year`** --- The publication year. Used as the EPUB date (`<dc:date>`).

**`publisher`** --- Publisher name, shown on the copyright page and in the EPUB
metadata.

**`rights`** --- The copyright or rights statement printed on the copyright page
(and stored as the EPUB `<dc:rights>`). When you pass `--build-id`, a
"Printing: …" line is appended to it in the EPUB.

**`isbn`** --- Printed on the copyright page and used as the EPUB identifier
(tagged as ISBN-13).

**`credits`** --- An acknowledgements line on the copyright page --- a cover
credit, for instance: `"Cover photo courtesy of RJ Muna."`

**`language`** --- A language code such as `en` or `fr`. It sets the document
language for the PDF and the EPUB (`<dc:language>`) and drives hyphenation.
Defaults to `en`.

**`cover`** --- *EPUB only.* A path (relative to the book directory) to a cover
image, embedded as the EPUB cover. Print ignores it --- KDP takes the print cover
as a separate upload, so it never belongs in the interior PDF. The build stops if
the file is missing.

### The "Also by" page

Give an `also-by:` list and book4matter prints an "Also by *Author*" page in the
front matter (print only); omit it and there is no such page. Each entry needs a
`title` and may add a `cover` image, a `qr` image, and a `url`. A bare string is
treated as a title-only entry.

```
also-by:
  - title: "How to Teach Ballroom Dancing"
    cover: "media/htbd-cover.jpg"
    qr: "media/htbd-qr.png"
    url: "howtoteachballroomdancing.com"
  - "An Earlier Work"        # title only
```

### Listing chapters explicitly

By default every file in `chapters/` is built, in natural filename order. To fix
the order by hand instead, list the files under `chapters:`, relative to the book
directory; only those files, in that order, are built. A listed file that does
not exist stops the build.

```
chapters:
  - chapters/010-introduction.md
  - chapters/020-first-steps.md
```

> **Not a metadata key:** `--build-id` is a *command-line* flag, not something
> you put here, because it changes from build to build. See the Command-Line
> chapter.
