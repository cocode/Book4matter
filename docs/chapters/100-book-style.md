## The book_style.yaml File

`book_style.yaml` controls appearance only --- page size, margins, fonts, and a
little page furniture. Point several books at one style file and they share a
look; restyle them all by editing that one file. Every key has a sensible
default, so the smallest possible style file is no file at all.

**`trim`** --- The finished page size. Write it as `6x9` (inches), or as an
explicit mapping for an unusual size. Defaults to `6x9`, the standard US trade
paperback.

```
trim: 6x9
# --- or ---
trim: {width: 5.5, height: 8.5}
```

**`margins`** --- The four page margins in inches: `inside`, `outside`, `top`,
`bottom`. The **inside** margin is the binding (gutter) edge and is normally the
widest, because the binding swallows part of every page. Omit `margins` and
book4matter fills them in: `outside` 0.625, `top` and `bottom` 0.75, and an
inside gutter sized to the book's length. With no `--pages` hint it uses a
generous 0.875" (safe to ~500 pages); with `--pages N` it picks KDP's minimum for
that length plus 0.125" of breathing room:

| Interior pages | KDP minimum gutter | With `--pages` |
|---|---|---|
| ≤ 150 | 0.375" | 0.5" |
| 151–300 | 0.5" | 0.625" |
| 301–500 | 0.625" | 0.75" |
| 501–700 | 0.75" | 0.875" |
| 701+ | 0.875" | 0.875" |

Anything you set here overrides those defaults.

**`font`** --- The body typeface. Defaults to **Libertinus Serif**, which is
bundled in the image, so the default needs no setup. To use another face, drop
its files into the book's `fonts/` folder and name the family here; see the
Customizing chapter.

**`heading-font`** --- The face for parts, chapters, and headings. Defaults to
**Liberation Sans** (a Helvetica-metric face, also bundled).

**`font-size`** --- Body text size, for example `11pt`. A bare number is read as
points (`11` means `11pt`). Defaults to `11pt`.

**`toc`** --- Whether to print the Contents page. Defaults to `true`. The
Contents lists parts and chapters; a front-matter chapter shows its roman folio.

**`running-heads`** --- *Print only.* When `true`, body pages carry a small-caps
running head: the book title on left-hand (verso) pages and the current chapter
on right-hand (recto) pages. It is suppressed in the front matter and on any page
where a part or chapter opens. Defaults to `false`. EPUB and HTML ignore it ---
those readers paginate themselves.

**`title-rule`** --- When `true`, draw a horizontal rule between the title and
subtitle on the title page. Defaults to `false`.

> **Not supported:** a `line-height:` key appears in some older example files,
> but the tool does not read it --- body leading is fixed in the template. Leave
> it out.
