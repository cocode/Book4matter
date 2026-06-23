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

**`indent`** --- *Print only.* How paragraphs are indented. `all` (the default)
indents every paragraph's first line, openers included; `standard` leaves the
first paragraph after a heading flush and indents the rest (the trade-book
convention, and what EPUB and HTML already do); `none` drops indents entirely and
tells paragraphs apart by the space between them. Defaults to `all`.

**`toc`** --- Whether to print the Contents page. Defaults to `true`. The
Contents lists parts and chapters; a front-matter chapter shows its roman folio.

**`toc-depth`** --- How many heading levels the Contents includes. `2` (the
default) lists parts and chapters; `3` also lists topics (level-3 `###`
headings), set smaller and nested under their chapter. Applies to print, EPUB,
and HTML.

**`running-heads`** --- *Print only.* When `true`, body pages carry a small-caps
running head: the book title on left-hand (verso) pages and the current chapter
on right-hand (recto) pages. It is suppressed in the front matter and on any page
where a part or chapter opens. Defaults to `false`. EPUB and HTML ignore it ---
those readers paginate themselves.

**`title-rule`** --- When `true`, draw a horizontal rule between the title and
subtitle on the title page. Defaults to `false`.

**`chapter-style`** --- *Print only.* The chapter opener's layout. `centered`
(the default) centers a bare chapter numeral over a short rule with the title
centered beneath --- which carries a wrapped title gracefully. `left` instead
prints a "CHAPTER N" label with the title flush left. Defaults to `centered`.

**`part-style`** --- *Print only.* The part divider's layout. `classic` (the
default) prints an all-caps label and arabic number ("PART 1") above the title in
bold capitals, sitting a third of the way down the page. `fancy` instead sets the
divider in the body serif as a small letterspaced label, a large Roman numeral, a
short rule, and the title in title-case --- the literary look of a trade book's
section openers. Any text written beneath the part heading in its chapter file
prints as a centered italic blurb on the divider itself. Defaults to `classic`.

**`part-label`** --- The word for the top-level division, replacing "Part"
everywhere it is auto-generated: the print divider and table of contents (set in
capitals there, so `SECTION TWO · ...`), and the EPUB and HTML labels. Defaults
to `Part`. Set it to `Section`, `Book`, `Volume`, or anything else. It does not
touch wording you write yourself in a heading or in body text.

**`parts-recto`** --- *Print only.* When `true`, every part divider begins on a
recto (the right-hand, odd-numbered page); a blank page is inserted before it when
the previous page would otherwise leave it on a verso. The blank is counted and
may carry a folio. Defaults to `false`. EPUB and HTML have no fixed page sides, so
they ignore it.

**`chapters-recto`** --- *Print only.* The same for chapters: when `true`, each
chapter opens on a recto page. Defaults to `false`.

> **Not supported:** a `line-height:` key appears in some older example files,
> but the tool does not read it --- body leading is fixed in the template. Leave
> it out.
