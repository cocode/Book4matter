# KindlePandocCreator — Design

A pipeline that turns Markdown into a print-ready PDF for **Amazon Kindle Direct
Publishing (KDP)** paperback interiors, epub or html. Markdown is the single source of truth;
everything runs inside Docker (no host installs).

## Goals & scope

- **Input:** one or more Markdown files (`chapters/*.md`) plus a `book_metadata.yaml`
  file and a book_style.md file.
- PDF **Output (v1):** a 6×9-inch, black-and-white **paperback interior PDF**
  (`out/interior.pdf`).
- EPUB, as a parallel Pandoc target — which is *why* the pipeline
  routes Markdown → Pandoc → Typst rather than authoring directly in Typst
  (Typst alone cannot produce EPUB; Pandoc can feed both).
- HTML  - This is a recent addition, and not heavily tested. 
- **Out of scope:** the cover. The author supplies their own cover to KDP
  separately. This pipeline produces the interior only.

## Why Pandoc → Typst → PDF

```
                       ┌───────────────────────┐
   chapters/*.md ─┐    │  book_metadata.yaml   │ (title, author, trim, margins, font…)
                  │    └──────┬───────┘
                  ▼           │
              pandoc ─t typst │ generates a Typst *body fragment*
                  │           ▼
                  │     templates/book.typ  (geometry + styling)
                  ▼           │
              typst compile ──┘ ───────────────▶  out/interior.pdf
```

- **Pandoc** parses Markdown and converts it to a Typst body fragment, and keeps
  the door open for EPUB later.
- **Typst** does the typesetting. It is fast, has no enormous TeX install, and
  the official `pandoc/typst` Docker image bundles both tools.

## Template strategy

`templates/book.typ` is a thin, hand-rolled Typst template that **owns the
print-critical geometry**:

- exact **6×9 trim** (`page(width: 6in, height: 9in)`),
- an **asymmetric binding gutter** (`margin: (inside:, outside:, …)`) — KDP
  requires a larger inside margin that scales with page count,
- **embedded fonts** (automatic in Typst),
- running page numbers and chapter styling.

The *styling* (title page, table of contents, chapter headings) is adapted from
the **ilm** Typst template (MIT-0 licensed, so freely reusable).

## Fonts

Default body font is **Libertinus Serif**, which is bundled inside the Typst
binary (it is *not* a Google webfont) — so there is zero font-download and zero
font supply-chain surface. The font is configurable in `book.yaml`. When a
different face is wanted, a properly licensed font file is vendored into the
Docker image rather than fetched at runtime.

## Input model

- `book.yaml` holds all metadata and build options (title, author(s), trim,
  margins, font, etc.).
- Chapter order: an explicit `chapters:` list in `book.yaml` if present;
  otherwise `chapters/*.md` sorted by filename.
- Each level-1 heading (`# …`) becomes a chapter.

### `book_metadata.yaml` (illustrative)

```yaml
title: "The Example Book"
subtitle: "A Demonstration of the Pipeline"
author: "Jane Author"          # string or a list
year: 2026
publisher: "Self-Published"
rights: "© 2026 Jane Author. All rights reserved."
isbn: ""
language: en

chapters:                      # optional explicit order
  - chapters/010-introduction.md
  - chapters/020-on-typography.md
```


### `book_style.yaml` (illustrative)

```yaml

trim: 6x9                      # or a {width, height} mapping
margins:                       # inches; omit to use page-count-based defaults
  inside: 0.875
  outside: 0.625
  top: 0.75
  bottom: 0.75

font: "Libertinus Serif"       # body face (must be findable; see fonts/ below)
heading-font: "Liberation Sans" # title page, part/chapter labels, headings
font-size: 11pt
line-height: 1.4
toc: true
running-heads: false           # true -> book title (verso) / chapter (recto)
                               # small-caps heads on body pages; print only

```

### Custom fonts (print)

Drop `.ttf` / `.otf` files into `<bookdir>/fonts/` and reference them by family
name from `font:` / `heading-font:` in `book.yaml`. `kpc print` automatically
passes `--font-path <bookdir>/fonts` to typst when the directory exists, so the
fonts travel with the book project (no system installs, no image rebuilds).
System fonts are still searched, so a missing `fonts/` dir is fine. The font's
license must permit embedding in a PDF — the build will silently embed
whatever's used.

EPUB intentionally does NOT embed custom fonts; `epub.css` specifies generic
`serif` / `sans-serif` families and lets the reader device pick.

## `.docx` import

Many manuscripts start life in Word. `kpc import` converts a `.docx` into the
Markdown the pipeline expects:

```
manuscript.docx
   │  pandoc (docx → pandoc-markdown, --extract-media)
   ▼
fence-aware split on every level-1 heading
   ├─▶ chapters/000-frontmatter.md  (content before the first H1, for review)
   ├─▶ chapters/010-slug.md, 020-slug.md …
   └─▶ media/                       (extracted images)
```

- **Markdown flavor:** Pandoc Markdown — most faithful to the Word source and
  round-trips perfectly into the build. Hand-cleanup is expected afterward.
- **Split:** fence-aware, so a `#` inside a code block is never mistaken for a
  chapter break. Content before the first H1 goes to `000-frontmatter.md` (the
  template generates its own title page + TOC, so this is usually trimmed).
- **Numbering:** three-digit, step-of-10 (`010`, `020`, …). Leaves gaps to slot
  hand-written inserts (part dividers, appendices) without renumbering siblings.
- **Images:** extracted to `media/`; chapter files reference them as
  `../media/…` so they resolve both in the build and in Markdown previews.
- `--track-changes=accept`, comments dropped, ATX headings, no hard-wrapping.
- The importer refuses to overwrite a non-empty `chapters/` unless `--force`.

## Image paths (how they resolve)

Images live in `media/` at the book root. Chapter files reference `../media/x`.
The build generates intermediate Typst under `out/`, and compiles with
`typst --root <bookdir>`, so `../media/x` resolves to `<bookdir>/media/x` from
both the chapter files and the generated Typst. No path rewriting at build time.

## Margins / binding gutter

KDP's minimum inside (gutter) margin scales with page count:

| Page count | Min. inside margin |
|------------|--------------------|
| ≤ 150      | 0.375 in           |
| 151–300    | 0.5 in             |
| 301–500    | 0.625 in           |
| 501–700    | 0.75 in            |
| 701+       | 0.875 in           |

`book.yaml` margins win if specified. Otherwise `--pages N` selects a
gutter-aware default; with no hint, a comfortable fixed default is used. A future
enhancement can auto-iterate (compile → count pages → recompile) for an exact
gutter.

## Tooling & invocation

- **Docker image:** `FROM pandoc/typst` + `python3` + `py3-yaml`. The `kpc` CLI
  and `templates/` are copied in. `ENTRYPOINT` is `python3 -m kpc`.
- **CLI (`kpc`):** a thin Python orchestrator.
  - `kpc print [bookdir] [--pages N] [--keep]`
  - `kpc epub  [bookdir] [--no-check]`
  - `kpc import <file.docx> [bookdir] [--no-split] [--force]`
- **Host wrapper (`run.sh`):** builds the image if missing, then runs the
  container with the current directory mounted at `/work`.

```bash
./run.sh print example/          # → example/out/interior.pdf
./run.sh import manuscript.docx  # → chapters/*.md + media/
```

Nothing is ever installed on the host; the wrapper only shells into the
container.

## Build order

1. `Dockerfile`
2. `templates/book.typ` + Pandoc wiring (get a compiling PDF)
3. example book
4. `import` command
