## Novels and Flat Books

The previous chapter describes the full hierarchy --- parts, then chapters, then
sections. Many books never use it. A novel is the clearest case: it has chapters,
often with no titles at all, just numbers, and no parts above them. Book4matter
has a low-friction path for exactly this, so that a book with the least possible
structure needs the least possible formatting.

### There is no such thing as parts without chapters

A book can have chapters and no parts, but never parts and no chapters. So when a
manuscript uses no `##` headings anywhere, book4matter reads `#` as **chapter**,
not part --- a plain chaptered book, arabic page numbers from page one, no
divider pages. You write `#` for each chapter title and nothing else. This
happens on its own; there is no flag to set.

### `--no-parts`: when you *do* use `##` inside a chapter

Some authors naturally write `#` for a chapter and `##` for a heading *within*
that chapter. Left alone, book4matter would read those as parts and chapters. Pass
`--no-parts` (or set `no-parts: true` in `book_style.yaml`) and every heading
shifts down one level: `#` becomes a chapter, `##` a section, `###` a subsection,
and so on. No part dividers are produced.

```
./run.sh print my-novel/ --no-parts
```

### Files with no heading become numbered chapters

Here is the smallest possible book: a folder of text files with no markup in them
at all.

```
my-novel/
  book_metadata.yaml
  chapters/
    01.txt
    02.txt
    03.txt
```

Each file with no heading becomes one chapter, numbered in the order the files
are read --- the first file is Chapter 1, the next Chapter 2, and so on. You never
type the numbers; book4matter supplies them, so inserting or reordering a file
renumbers the rest. The chapter opens with a centered numeral over a short rule,
the classic novel look.

Because nothing in the book carries a title, there is nothing to list, so the
**Contents page is left out** automatically. (Set `toc: true` in `book_style.yaml`
if you want one anyway; the numbered chapters then appear as "Chapter 1",
"Chapter 2", and so on.)

### Plain text files

Chapters may be `.txt` as well as `.md`. A `.txt` file is still read as Markdown
--- so blank lines separate paragraphs, `---` becomes an em dash, and a line of
`* * *` becomes a scene break --- but a novelist writing ordinary prose need not
know any of that. Type paragraphs, leave a blank line between them, and it comes
out right.

### A named section among numbered chapters

Most novels want at least a titled page or two --- a prologue, an introduction, an
afterword. Give that one file a `#` heading and leave the rest without one:

```
chapters/
  00-introduction.txt      # begins with "# Introduction"
  01.txt                   # no heading
  02.txt                   # no heading
  99-afterword.txt         # begins with "# Afterword"
```

A titled file set among untitled ones is treated as a **named section**: it shows
its title (Introduction, Afterword) and is **not** given a chapter number, nor
does it disturb the count. The untitled files remain Chapter 1, Chapter 2. Because
the book now has titles, a Contents page is included, listing the named sections
alongside the numbered chapters.

If instead *every* file has a `#` title, they are all ordinary titled chapters,
numbered straight through --- the titled-chapter novel, or any chaptered
non-fiction book built with `--no-parts`.

### The bundled novel

The repository ships a second example, `novel/`, alongside the `example/` book. It
is a very short fable with no titles, no parts, and no markup --- just numbered
`.txt` chapters --- so you can see the whole of this chapter at work:

```
# Writes novel/out/the-smallest-fire-interior.pdf.
./run.sh print novel/
```
