## Headings: Parts, Chapters, and Front Matter

Markdown heading levels are how you give a book its structure. Book4matter reads
them as a hierarchy and supplies the "PART" and "CHAPTER" labels, the page
breaks, and the numbering for you --- you write only the titles.

| Markdown | Becomes | On the page |
|---|---|---|
| `#` | **Part** | Its own divider page, an auto "PART N" label, the title set a third of the way down |
| `##` | **Chapter** | A fresh page with an auto "CHAPTER N" label and a large heading |
| `###` | Section | A bold heading, spaced from the text above it |
| `####` | Subsection | A smaller bold heading |
| `#####` / `######` | Minor heading | Regular weight, still set apart from the body |

### Numbering takes care of itself

Parts are numbered one, two, three; chapters are numbered straight through, and
the count does **not** restart inside each part. Both labels are generated at
build time, so inserting or reordering a chapter renumbers everything
automatically. Never type "Chapter 3" into a heading yourself.

### Front matter

Any chapter that appears **before the first part** is treated as front matter. It
carries lowercase roman folios (i, ii, iii ...) and is listed in the Contents
ahead of Part One; arabic page 1 begins at the first part's divider. This is
where an introduction or preface belongs:

```
## Introduction {.unnumbered}
```

A book with no parts at all is simpler still: every `##` is a chapter and arabic
page numbers run from page one.

### Two small switches

Two optional classes ride on a heading:

- `{.unnumbered}` suppresses the auto "PART N" / "CHAPTER N" label without
  disturbing the count. (Pandoc's `{-}` shorthand means the same thing.) Use it
  for an Introduction, a Conclusion, or an Appendix that should carry no number.
- `{.new-page}` forces a page break just before the heading.

### Text on a part divider

A part is usually a page to itself with nothing but the title. If you want a few
words on that divider page --- an epigraph, a sentence framing the part --- write
them directly under the part heading, before the first chapter:

```
# Foundations

Everything in this part assumes you can already hold a frame and keep time.

## Posture
...
```

Because the chapter files are concatenated in order, this "divider text" lives at
the top of the part's own file, ahead of its first `##` chapter. It prints
beneath the part title on the divider page rather than spilling onto the next.
