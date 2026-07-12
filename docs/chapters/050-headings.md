#e Markdown

If you haven't used it before, Markdown is a very simple way of indicating style
and structure in text. 

Examples:

\*bold*

\# I am a heading

You can find complete documentation [here](https://garrettgman.github.io/rmarkdown/authoring_pandoc_markdown.html).

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
page numbers run from page one. And a book that writes `#` for its chapters ---
with no parts above them --- is handled too; see the Novels and Flat Books
chapter for that and for numbered, title-less chapters.

### Two small switches

Two optional classes ride on a heading:

- `{.unnumbered}` suppresses the auto "PART N" / "CHAPTER N" label without
  disturbing the count or the heading's place in the structure. (Pandoc's `{-}`
  shorthand means the same thing.) Use it for an Introduction or a Conclusion
  that should carry no number.
- `{.new-page}` forces a page break just before the heading.

### Top-level sections: afterwords and appendices

A part divider (`#`) is a grand thing: its own page, a "PART N" label, the title
floated a third of the way down. Back matter --- an afterword, an appendix, an
acknowledgments page --- wants none of that pomp, yet it still belongs at the top
level of the Contents, beside the parts rather than tucked under the last one.
Add `{.section}` to a `#` heading to get exactly that:

```
# Afterword {.section}

Thanks for reading this far.
```

On the page it is set like a chapter --- the title in your chapter style, with no
number --- and its text flows on beneath, the way a chapter opens, instead of
sitting alone on a divider. In the Contents it appears at the top level with no
"PART N ·" prefix. Its folios follow its position: a `{.section}` before the
first part is front matter, one after the parts is main matter, and it is never
itself counted as where the main matter begins.

In short: reach for `{.unnumbered}` when a heading should keep its place in the
structure but lose its number, and for `{.section}` when a top-level heading
should read like a chapter rather than a part.

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
