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

// Chapter and Part numbering. Plain `state` counters (not `set heading(
// numbering:)`) so each runs its own straight 1, 2, 3... — chapter numbers
// do not reset across parts, and parts are counted independently of chapters.
// The `unnumbered-next` state is flipped on by parts.lua just before a
// `{.unnumbered}` heading so the matching show rule skips the auto label and
// leaves the count alone. One flag for both levels: it's consumed by the very
// next heading the parser emits, so there's no risk of cross-talk between H1
// and H2 markers.
#let chapter-num = state("chapter-num", 0)
#let part-num = state("part-num", 0)
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
  // Level 1 = part divider (own page, block one-third down the page).
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
    set text(hyphenate: false)
    v(1fr)
    context {
      if unnumbered-next.get() {
        unnumbered-next.update(false)
      } else {
        // Function-form update for the same reason as chapter-num below:
        // value-form updates that read get() can stall Typst's layout loop.
        part-num.update(prev => prev + 1)
        block(text(size: 1.2em, weight: "regular")[
          PART #context part-num.get()
        ])
        v(1em)
      }
    }
    block(text(size: 2em, weight: "bold", upper(it.body)))
    // 1fr above, 2fr below: the part block sits one-third down the page
    // rather than dead centre.
    v(2fr)
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
    block(below: 1em, upper(it.body))
  }
  show heading.where(level: 4): it => {
    v(2em, weak: true)
    block(below: 1em, text(weight: "bold", size: 1em, upper(it.body)))
  }
  show heading.where(level: 5): it => {
    v(2em, weak: true)
    block(below: 1em, text(weight: "regular", size: 1em, upper(it.body)))
  }
  show heading.where(level: 6): it => {
    v(2em, weak: true)
    block(below: 1em, text(weight: "regular", size: 1em, upper(it.body)))
  }

  // ===================== FRONT MATTER (no page numbers) =====================

  // Title page. Title + subtitle share the heading font (sans) so the
  // subtitle reads as a smaller sibling of the title rather than slipping
  // back into the body serif (which made the italic look mismatched).
  //
  // The title shrinks itself to fit on a single line. We measure the title at
  // the maximum size, and if it overruns the live area we step the size down
  // until it fits or hits a minimum (below which a wrap is preferable to
  // postage-stamp text). The shrink is bounded so short titles stay big and
  // long titles stay readable.
  page(numbering: none)[
    #set align(center)
    #set text(font: meta.heading-font)
    #v(22%)
    #context {
      // Pick the title size analytically: measure the title at the body font
      // size, then scale linearly so the rendered width equals the live-area
      // width. One measurement; no search loop. Clamp to a min so very long
      // titles stay readable (and wrap rather than going postage-stamp), and
      // to a max so one-word titles don't blow out the page.
      let body = meta.font-size
      let avail = meta.trim.width - meta.margins.inside - meta.margins.outside
      let ref-width = measure(text(size: body, weight: "bold", meta.title)).width
      let ideal = body * (avail / ref-width)
      let min-size = 1.4 * body
      let max-size = 8 * body
      let size = calc.max(min-size, calc.min(max-size, ideal))
      text(size: size, weight: "bold")[#meta.title]
    }
    #if meta.subtitle != none {
      v(0.6em)
      text(size: 1.3em, weight: "regular")[#meta.subtitle]
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
    #if meta.build-id != none [\ Printing: #meta.build-id]
  ]

  // "Also by <author>" page. Driven by the optional `also-by:` list in
  // book.yaml; skipped entirely when that list is empty. The "ALSO BY ..."
  // line is plain styled text (NOT a heading) so it neither trips the level-1
  // pagebreak show rule nor shows up in the table of contents.
  if meta.also-by.len() > 0 {
    page(numbering: none)[
      #set align(center)
      #v(15%)
      #text(font: meta.heading-font, size: 1.7em, weight: "bold")[
        #upper("Also by " + meta.authors.join(", "))
      ]
      #v(2em)
      #for work in meta.also-by {
        if work.cover != none {
          image(work.cover, height: 2.6in)
          v(0.8em)
        }
        text(size: 1.2em, style: "italic")[#work.title]
        if work.qr != none {
          v(1.2em)
          image(work.qr, width: 1.1in)
        }
        if work.url != none {
          v(0.4em)
          text(size: 0.9em)[#work.url]
        }
      }
    ]
  }

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
