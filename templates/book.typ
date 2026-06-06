// templates/book.typ
//
// KDP 6x9 print-interior template.
//
// This file OWNS the print-critical geometry - trim size, the asymmetric
// binding gutter, font embedding, and page numbering. The title page, copyright
// page, table of contents, and chapter-heading styling are adapted from the ilm
// template (https://github.com/talal/ilm, MIT-0).
//
// Entry point: `#show: book.with(meta)`, where `meta` is the dictionary the kpc
// CLI generates from book.yaml.

#import "@preview/wrap-it:0.1.1": wrap-content

// Chapter numbering. A plain `state` (not `set heading(numbering:)`) so the
// chapter number runs straight 1, 2, 3... regardless of any enclosing Part
// divider. The `unnumbered-next` state is flipped on by parts.lua just before
// a `{.unnumbered}` chapter so the level-2 show rule skips the label and
// leaves the count alone.
#let chapter-num = state("chapter-num", 0)
#let unnumbered-next = state("unnumbered-next", false)

#let book(meta, body) = {
  // --- PDF document metadata ---
  set document(title: meta.title, author: meta.authors)

  // --- Page geometry (KDP print-critical) ---
  set page(
    width: meta.trim.width,
    height: meta.trim.height,
    margin: (
      inside: meta.margins.inside,
      outside: meta.margins.outside,
      top: meta.margins.top,
      bottom: meta.margins.bottom,
    ),
  )

  // --- Body text & paragraphs ---
  set text(
    font: meta.font,
    size: meta.font-size,
    lang: meta.language,
    hyphenate: true,
  )

  // The (amount:, all:) indent form needs Typst >= 0.12; fall back on older.
  let indent = if sys.version >= version(0, 12, 0) {
    (amount: 1.2em, all: false)
  } else {
    1.2em
  }
  set par(justify: true, leading: 0.72em, first-line-indent: indent)

  // --- Headings: sans-serif face (Helvetica-style), sized per level ---
  //
  // Level 1 = part divider (own page, vertically centred title).
  // Level 2 = chapter       (page break, large heading at top).
  // Level 3 = section       (bold, spaced from preceding text).
  // Level 4 = subsection    (bold sans, body size).
  // Level 5+ = regular-weight sans (still distinguished from body serif).
  show heading: set text(font: meta.heading-font)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    set align(center)
    // Disable hyphenation here so a long title wraps on a space rather than
    // breaking a word ("Varia-/tions"). Body text still hyphenates.
    set text(size: 2em, weight: "bold", hyphenate: false)
    v(1fr)
    block(upper(it.body))
    v(1fr)
    pagebreak(weak: true)
  }
  show heading.where(level: 2): it => {
    pagebreak(weak: true)
    v(3em)
    context {
      if unnumbered-next.get() {
        unnumbered-next.update(false)
      } else {
        // Function-form update — the increment is independent of get(), so
        // Typst's iterative layout converges. A value-form update whose
        // argument reads get() will stall (every chapter past a certain
        // point ends up sharing the same number).
        chapter-num.update(prev => prev + 1)
        text(size: 0.9em, weight: "regular")[
          CHAPTER #context chapter-num.get()
        ]
        parbreak()
        v(0.4em)
      }
    }
    set text(size: 1.4em, weight: "bold")
    block(upper(it.body))
    // Hard (non-weak) space so it survives next to a level-3 heading or a
    // chapter that page-breaks immediately after the title.
    v(4em)
  }
  show heading.where(level: 3): it => {
    v(2.4em, weak: true)
    set text(size: 1.2em, weight: "bold")
    block(below: 0.6em, upper(it.body))
  }
  show heading.where(level: 4): it => {
    v(2em, weak: true)
    block(below: 0.4em, text(weight: "bold", size: 1em, upper(it.body)))
  }
  show heading.where(level: 5): it => {
    v(2em, weak: true)
    block(below: 0.4em, text(weight: "regular", size: 1em, upper(it.body)))
  }
  show heading.where(level: 6): it => {
    v(2em, weak: true)
    block(below: 0.4em, text(weight: "regular", size: 1em, upper(it.body)))
  }

  // ===================== FRONT MATTER (no page numbers) =====================

  // Title page
  page(numbering: none)[
    #set align(center)
    #v(22%)
    #text(size: 2.4em, weight: "bold")[#meta.title]
    #if meta.subtitle != none {
      v(0.6em)
      text(size: 1.3em, style: "italic")[#meta.subtitle]
    }
    #v(1fr)
    #text(size: 1.2em)[#meta.authors.join(", ")]
    #v(12%)
  ]

  // Copyright page
  page(numbering: none)[
    #set text(size: 0.85em)
    #set par(first-line-indent: 0pt, leading: 0.65em)
    #v(1fr)
    #if meta.publisher != none [#meta.publisher \ ]
    #if meta.rights != none [#meta.rights \ ]
    #if meta.isbn != none [ISBN: #meta.isbn \ ]
    #if meta.credits != none [#v(0.8em) #meta.credits \ ]
    #v(0.8em)
    Formatted with Pandoc and Typst.
  ]

  // Table of contents. The title is plain styled text, NOT a heading, so it
  // does not trip the level-1 chapter `pagebreak` show rule above.
  //
  // The parts.lua filter splits "Part I - About This Book" across two lines
  // so the part-divider page can stack them. In the contents we want them on
  // one line, so flatten the linebreak back to " - " for level-1 entries.
  show outline.entry.where(level: 1): it => {
    show linebreak: _ => " - "
    it
  }
  if meta.toc {
    page(numbering: none)[
      #v(3em)
      #text(size: 1.7em, weight: "bold")[Contents]
      #v(1.2em)
      #outline(title: none, depth: 2, indent: auto)
    ]
  }

  // ===================== MAIN MATTER (page numbers from 1) ==================
  set page(numbering: "1")
  counter(page).update(1)

  body
}
