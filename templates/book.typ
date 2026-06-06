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
  // Level 4+ = default typst heading styling.
  show heading: set text(font: meta.heading-font)
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    set align(center)
    // Disable hyphenation here so a long title wraps on a space rather than
    // breaking a word ("Varia-/tions"). Body text still hyphenates.
    set text(size: 2em, weight: "bold", hyphenate: false)
    v(1fr)
    block(it.body)
    v(1fr)
    pagebreak(weak: true)
  }
  show heading.where(level: 2): it => {
    pagebreak(weak: true)
    v(3em)
    set text(size: 1.4em, weight: "bold")
    block(below: 1.2em, it.body)
  }
  show heading.where(level: 3): it => {
    v(1.2em, weak: true)
    set text(size: 1.2em, weight: "bold")
    block(below: 0.6em, it.body)
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
