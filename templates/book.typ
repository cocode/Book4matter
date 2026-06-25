// templates/book.typ
//
// KDP 6x9 print-interior template.
//
// This file OWNS the print-critical geometry - trim size, the asymmetric
// binding gutter, font embedding, and page numbering. The title page, copyright
// page, table of contents, and chapter-heading styling are adapted from the ilm
// template (https://github.com/talal/ilm, MIT-0).
//
// Entry point: `#show: book.with(meta)`, where `meta` is the dictionary the bf
// CLI generates from book.yaml.

#import "@preview/wrap-it:0.1.1": wrap-content

// Chapter and Part numbering. Plain `state` counters (not `set heading(
// numbering:)`) so each runs its own straight 1, 2, 3... — chapter numbers
// do not reset across parts, and parts are counted independently of chapters.
//
// `chapter-num` increments inside the H2 show rule. `part-num` is instead
// driven by parts.lua, which emits `#part-num.update(N)` just before each
// numbered part heading: the update then precedes the heading's queryable
// location, so the table of contents can recover a part's number with
// `part-num.at(<heading location>)`. (A counter incremented inside the show
// rule lands *after* that location and reads off by one from the outline.)
//
// The `unnumbered-next` state is flipped on by parts.lua just before a
// `{.unnumbered}` heading so the matching show rule skips the auto label and
// leaves the count alone. One flag for both levels: it's consumed by the very
// next heading the parser emits, so there's no risk of cross-talk between H1
// and H2 markers.
#let chapter-num = state("chapter-num", 0)
#let part-num = state("part-num", 0)
#let unnumbered-next = state("unnumbered-next", false)

// Divider-page text. parts.lua wraps any blocks sitting between a part
// heading and the next heading — i.e. text written under the part title in
// the part's own chapter file — in a call to this function, and flips
// `part-text-next` just before the heading so the part show rule leaves the
// bottom of the divider page to us: the 2fr spacer and trailing pagebreak
// come after the text, keeping the title block at one-third height with the
// text beneath it on the same page. (Raw `#pagebreak()` typst inside divider
// text won't compile — pagebreaks can't live inside a content block.)
#let part-text-next = state("part-text-next", false)
// The part-page style ("classic" = all-caps label + part number; "fancy" = the
// letterspaced-label / Roman-numeral / rule / serif-title sample look). Stashed
// in a state because part-text() runs at module scope and can't see `meta`.
#let part-style = state("part-style", "classic")
#let part-text(body) = context {
  if part-style.get() == "fancy" {
    // Fancy divider: the blurb sits directly under the title, centred and
    // italic, in the body serif — matching the sample dividers.
    v(1.4em)
    set align(center)
    set text(style: "italic")
    pad(x: 1.5em, body)
    v(2fr)
    pagebreak(weak: true)
  } else {
    v(2.5em)
    pad(x: 2em, body)
    v(2fr)
    pagebreak(weak: true)
  }
}

// Run-in heading (level 6). parts.lua merges a level-6 heading into the start
// of the paragraph it heads and wraps its words in `#runin[...]`, so the
// heading shares the first line of the body instead of standing on its own.
// The font isn't known at module load (it comes from book.yaml via meta), so
// book() stashes it in this state and the helper reads it at render time.
#let runin-font = state("runin-font", "Liberation Sans")
#let runin(body) = context {
  text(font: runin-font.get(), weight: "bold")[#body.]
  h(0.4em)
}

// Spelled-out part ordinals for the contents page ("PART TWO · BASICS").
// Books with more than twenty parts fall back to the bare numeral.
#let part-words = ("One", "Two", "Three", "Four", "Five", "Six", "Seven",
  "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen",
  "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen", "Twenty")
#let part-word(n) = if n >= 1 and n <= part-words.len() {
  part-words.at(n - 1)
} else { str(n) }

#let book(meta, body) = {
  // The title may carry author-chosen line breaks ("\n") for the title-page
  // stack. Every other use -- PDF metadata, running heads -- wants it on one
  // line, so flatten the breaks to spaces for those; only the title page
  // splits on "\n".
  let flat-title = meta.title.replace("\n", " ")

  // Hand the heading font to the run-in helper (level-6 headings merged into
  // body text by parts.lua), which can't see `meta` from module scope.
  runin-font.update(meta.heading-font)
  // Let part-text() (module scope) know which part-page style is in force.
  part-style.update(meta.part-style)

  // --- PDF document metadata ---
  set document(title: flat-title, author: meta.authors)

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
    // Front matter carries roman folios (i, ii, iii...). The explicit page()
    // calls below (title, copyright, also-by) override this with
    // `numbering: none` — blind folios that still advance the page counter —
    // while the contents page and any front-matter chapters (an introduction
    // before the first part) display theirs. parts.lua injects the switch to
    // arabic numbering at the start of the main matter.
    numbering: "i",
    // The folio is rendered by this explicit footer rather than typst's
    // default numbering footer, so display pages can go blind: a page that
    // opens a part (its level-1 heading sits on it) shows no folio, per
    // book convention. `page.numbering` still drives the format ("i" / "1"),
    // keeps blind front-matter pages blind, and feeds the contents entries.
    footer: context {
      let pg = here().page()
      let display-page = query(heading.where(level: 1))
        .any(h => h.location().page() == pg)
      if page.numbering != none and not display-page {
        align(center, counter(page).display())
      }
    },
    // Running heads (opt-in via `running-heads: true` in book.yaml):
    // verso = book title, recto = current chapter title, small caps,
    // centred. Shown only in the main matter (arabic folios), and never on
    // a page where a part or chapter opens, nor between a part divider and
    // its first chapter (overflowing divider text). Verso/recto comes from
    // physical page parity — the same rule that drives the inside/outside
    // margins — so the book title sits on left-hand pages.
    header: if meta.running-heads {
      context {
        let pg = here().page()
        if page.numbering == "1" {
          let parts-or-chapters = heading.where(level: 1)
            .or(heading.where(level: 2))
          let opener = query(parts-or-chapters)
            .any(h => h.location().page() == pg)
          let prior = query(parts-or-chapters.before(here()))
          if not opener and prior.len() > 0 and prior.last().level == 2 {
            let head = if calc.even(pg) { flat-title } else { prior.last().body }
            align(center, text(size: 0.85em, smallcaps(head)))
          }
        }
      }
    },
  )

  // --- Body text & paragraphs ---
  set text(
    font: meta.font,
    size: meta.font-size,
    lang: meta.language,
    hyphenate: true,
    // Lining (uniform-height) figures throughout, not Libertinus's default
    // old-style text figures.
    number-type: "lining",
  )

  // Paragraph first-line indent, chosen by book_style.yaml `indent:`:
  //   all      — indent every paragraph, openers included (the house default).
  //   standard — flush opener after a heading, the rest indented (the classic
  //              trade-book look; matches what EPUB/HTML do).
  //   none     — no indent; paragraphs are told apart by the block spacing.
  // The (amount:, all:) form needs Typst >= 0.12 (the image ships a later one);
  // `all: false` is what leaves the post-heading opener flush.
  let fli = if meta.indent == "none" {
    0pt
  } else {
    (amount: 1.2em, all: meta.indent == "all")
  }
  set par(justify: true, leading: 0.72em, first-line-indent: fli)

  // --- Headings: sans-serif face (Helvetica-style), sized per level ---
  //
  // Level 1 = part divider (own page, block one-third down the page).
  // Level 2 = chapter       (page break, large heading at top).
  // Level 3 = section       (bold, spaced from preceding text).
  // Level 4 = subsection    (bold sans, body size).
  // Level 5+ = regular-weight sans (still distinguished from body serif).
  // Headings (every level, including the PART/CHAPTER labels the show rules
  // below emit) never hyphenate and never justify: a long title wraps whole
  // words onto the next line ("QUESTIONS", not "QUES-/TIONS") and stays
  // ragged-right instead of stretching to the margin. Body text still
  // hyphenates and justifies.
  show heading: set text(font: meta.heading-font, hyphenate: false)
  show heading: set par(justify: false)
  show heading.where(level: 1): it => {
    // parts-recto: open on a recto (odd) page. parts.lua makes the first part's
    // break happen before the numbering reset; this weak break handles later
    // parts and is a no-op for the first (already on its recto page).
    if meta.parts-recto { pagebreak(weak: true, to: "odd") } else {
      pagebreak(weak: true)
    }
    set align(center)
    if meta.part-style == "fancy" {
      // Fancy divider (sample look): a small letterspaced label, a large
      // Roman numeral, a short rule, then the title in title-case body serif.
      // Everything is set in the body serif rather than the sans heading face,
      // and the label starts a FIXED distance down the page (not vertically
      // centred), so it lands at the same height on every divider regardless of
      // how long the title or blurb runs.
      set text(font: meta.font)
      v(1.25in)
      context {
        if unnumbered-next.get() {
          unnumbered-next.update(false)
        } else {
          // part-num was set by parts.lua's `#part-num.update(N)` just before
          // this heading; rendered as an uppercase Roman numeral here.
          block(text(size: 0.95em, tracking: 0.35em, fill: luma(45%))[
            #upper(meta.part-label)
          ])
          v(0.7em)
          block(text(size: 4.2em, weight: "regular")[
            #numbering("I", part-num.get())
          ])
          v(0.5em)
          line(length: 0.6in, stroke: 0.5pt + luma(55%))
          v(0.85em)
        }
      }
      block(text(size: 1.7em, weight: "regular")[#it.body])
    } else {
      // Classic divider: all-caps label + part number, bold all-caps title,
      // the block sitting one-third down the page.
      v(1fr)
      context {
        if unnumbered-next.get() {
          unnumbered-next.update(false)
        } else {
          // part-num was already set by the `#part-num.update(N)` block that
          // parts.lua emitted just before this heading; here we only read it.
          block(text(size: 1.2em, weight: "regular")[
            #upper(meta.part-label) #context part-num.get()
          ])
          v(1em)
        }
      }
      block(text(size: 2em, weight: "bold", upper(it.body)))
    }
    // Bottom trailer (both styles): a 2fr spacer then the page break. With the
    // 1fr top of the classic style it puts the block one-third down; with the
    // fancy style's fixed top spacer it just fills the page below the title.
    // When divider text follows (flag set by parts.lua), #part-text supplies the
    // bottom spacer and break instead, so the text shares the divider page.
    context {
      if part-text-next.get() {
        part-text-next.update(false)
      } else {
        v(2fr)
        pagebreak(weak: true)
      }
    }
  }
  show heading.where(level: 2): it => {
    // chapters-recto: open the chapter on a recto (odd) page; a blank verso is
    // inserted before it when the previous page lands odd.
    if meta.chapters-recto { pagebreak(weak: true, to: "odd") } else {
      pagebreak(weak: true)
    }
    let centered = meta.chapter-style == "centered"
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
        if centered {
          // Centered opener: a bare chapter numeral over a short rule. Wraps a
          // long title more gracefully than the flush-left label does.
          align(center)[
            #text(size: 1.3em, weight: "bold")[#context chapter-num.get()]
            #v(0.45em)
            #line(length: 1.1in, stroke: 0.5pt)
          ]
          v(0.9em)
        } else {
          text(size: 0.9em, weight: "regular")[
            CHAPTER #context chapter-num.get()
          ]
          parbreak()
          v(0.4em)
        }
      }
    }
    set text(size: 1.4em, weight: "bold")
    // Centered style centres the (possibly wrapping) title; left keeps it flush.
    if centered { align(center, block(upper(it.body))) } else { block(upper(it.body)) }
    // Hard (non-weak) space so it survives next to a level-3 heading or a
    // chapter that page-breaks immediately after the title.
    v(4em)
  }
  show heading.where(level: 3): it => {
    v(2.4em, weak: true)
    set text(size: 1.4em, weight: "bold")
    block(below: 1em, sticky: true, text(tracking: 0.05em, upper(it.body)))
  }
  show heading.where(level: 4): it => {
    v(2em, weak: true)
    block(below: 1em, sticky: true, text(weight: "bold", size: 1.15em, tracking: 0.05em, upper(it.body)))
  }
  show heading.where(level: 5): it => {
    v(2em, weak: true)
    block(below: 1em, sticky: true, text(weight: "bold", size: 1em, it.body))
  }
  // Level 6 = run-in: normally parts.lua merges a level-6 heading into the
  // start of the paragraph it heads (see #runin above), so this show rule
  // never fires in ordinary flow. It only catches a level-6 heading parts.lua
  // couldn't merge -- e.g. one inside a wrap body, serialized before parts.lua
  // runs -- which is rendered as a plain bold block so nothing is lost.
  show heading.where(level: 6): it => {
    v(1em, weak: true)
    block(below: 0.6em, sticky: true, text(weight: "bold", size: 1em, it.body))
  }

  // --- Links: print-friendly. Never hyphenate a URL or email -- a soft hyphen
  // reads as part of the address (e.g. "thero-tarywaltz@..."). For external web
  // links append the destination in parentheses so a print reader can see where
  // it points; a bare autolink already shows its URL, and mailto: links keep
  // their visible text. (EPUB/HTML don't use this template, so their links stay
  // live and bare.)
  //
  // Internal links (TOC entries, cross-references) depend on the target. The
  // `pdf` target builds a digital PDF where they're a feature, so meta.links
  // == "live" keeps them clickable. The `print` target builds an interior for
  // KDP and other publishers, which forbid hyperlinks: meta.links == "print"
  // (the default) drops the link wrapper so only the visible text is emitted --
  // no annotation -- otherwise KDP reports "non-printable markup removed" on the
  // affected pages. Older _meta.typ files predate the key, hence the default.
  let live-links = meta.at("links", default: "print") == "live"
  show link: it => {
    set text(hyphenate: false)
    let d = it.dest
    if type(d) == str and (d.starts-with("http://") or d.starts-with("https://")) {
      // External web link: append the URL unless the visible text already is it
      // (a bare autolink, where pandoc emits no body).
      let bare = it.body == none or it.body == [] or it.body == [#d]
      if bare { it } else { [#it.body~(#d)] }
    } else if type(d) == str and d.starts-with("mailto:") {
      box(it.body)  // keep the address whole -- never split at an internal hyphen
    } else if live-links {
      it  // digital PDF: internal links stay clickable
    } else {
      it.body  // print: visible text only, no link annotation
    }
  }

  // --- Footnotes: print-friendly. Typst links the in-text marker to its note
  // and the note's number back up to the marker. Those internal link
  // annotations are invisible on paper but make KDP report "non-printable
  // markup removed" on the footnote pages, exactly as the TOC links do -- and
  // the show-link rule above never sees them, because typst's footnote
  // machinery emits the links itself. So for the print target re-render both
  // ends as plain superscripts with no link: identical on the page, just not
  // clickable. The digital `pdf` target keeps the default linked rendering.
  show footnote: it => {
    if live-links { it } else {
      // In-text marker: the footnote's number, superscripted, no link.
      let num = counter(footnote).at(it.location()).first()
      super(numbering(it.numbering, num))
    }
  }
  show footnote.entry: it => {
    if live-links { it } else {
      // Reproduce typst's default entry layout -- first line indented by
      // it.indent, the superscript number, then the note body; continuation
      // lines return to the margin -- but with a plain, link-free number.
      let loc = it.note.location()
      let num = counter(footnote).at(loc).first()
      par(first-line-indent: 0pt, hanging-indent: 0pt)[
        #h(it.indent)#super(numbering(it.note.numbering, num))#it.note.body
      ]
    }
  }

  // --- Block quotes (markdown `>`, which pandoc emits as quote(block: true)):
  // set off from the body -- slightly smaller, italic, indented both sides with
  // air above and below. Mark quotes semantically with `>`; never hand-indent.
  show quote.where(block: true): it => {
    set text(size: 0.95em, style: "italic")
    block(
      above: 1.1em, below: 1.1em,
      inset: (left: 1.6em, right: 1.6em),
      it.body,
    )
  }

  // --- Tables: book style (booktabs). Pandoc emits a full grid plus a manual
  // rule under the header; we drop the grid and keep three horizontal rules
  // (above the table, under the header, below the table), no vertical rules, a
  // bold header, and tabular (fixed-width) figures so columns of numbers align.
  // The reconstruction appends the closing rule pandoc doesn't emit; the guard
  // (table already ends in an hline) stops the show rule from recursing.
  show table.cell.where(y: 0): set text(weight: "bold")
  show table: it => {
    set text(number-width: "tabular")
    let kids = it.children
    if kids.len() > 0 and kids.last().func() == table.hline {
      it
    } else {
      table(
        columns: it.columns,
        align: it.align,
        inset: (x: 0.7em, y: 0.5em),
        stroke: (_, y) => (top: if y == 0 { 0.9pt } else { 0pt }),
        ..kids,
        table.hline(stroke: 0.9pt),
      )
    }
  }

  // ============ FRONT MATTER (roman folios; display pages blind) ============

  // Optional cover image as the very first page (digital `pdf`, plus epub/html
  // which pandoc handles separately). The print interior never sets meta.cover
  // -- KDP takes the cover as its own upload. Full-bleed: zero margins and no
  // header/footer/folio, the image scaled to fill the trim (fit: "cover" so a
  // cover sized to the trim ratio has no white bars; a slight mismatch crops
  // rather than letterboxes). meta.at(..) tolerates older _meta.typ files.
  let cover = meta.at("cover", default: none)
  if cover != none {
    page(margin: 0pt, header: none, footer: none, numbering: none)[
      #image(cover, width: 100%, height: 100%, fit: "cover")
    ]
  }

  // Title page. Title + subtitle share the heading font (sans) so the
  // subtitle reads as a smaller sibling of the title rather than slipping
  // back into the body serif (which made the italic look mismatched).
  //
  // The title auto-sizes to a fraction of the live width (not the whole of
  // it — filling margin to margin reads "word processor"). A multi-line title
  // (book.yaml `title:` with embedded "\n") is sized from its widest line and
  // stacked with tight leading; see the sizer note below.
  page(numbering: none)[
    #set align(center)
    #set text(font: meta.heading-font, hyphenate: false)
    #set par(justify: false)
    // Vertical rhythm in fraction units so the gaps share the free space
    // proportionally: title + rule + subtitle form a tight group in the upper
    // third, and the author sits alone low on the page. Using fr (not fixed
    // percentages) for the gaps means the big gap above the author can never
    // collapse -- mixing fixed percentages with a lone `1fr` let a tall
    // multi-line title starve that gap and overprint the author.
    #v(1.1fr)
    #context {
      // Pick the title size analytically: measure each line at the body font
      // size, then scale so the WIDEST line fills a fraction of the live
      // width. One measurement per line; no search loop.
      //
      // A single-line title fills ~78%; a stacked title fills ~62%. Stacked
      // lines are each short (often one word), so a higher fill would blow
      // them straight up to the clamp and let the giant lines eat the page.
      // Clamp to a min (long titles stay readable and wrap rather than going
      // postage-stamp) and a max (one-word titles don't blow out the page).
      let body = meta.font-size
      let avail = meta.trim.width - meta.margins.inside - meta.margins.outside
      let lines = meta.title.split("\n")
      let widest = calc.max(..lines.map(l =>
        measure(text(size: body, weight: "bold", l)).width.pt()))
      let fill = if lines.len() > 1 { 0.62 } else { 0.78 }
      let ideal = body * ((fill * avail).pt() / widest)
      let size = calc.max(1.4 * body, calc.min(6 * body, ideal))
      // Tighten the leading so a stacked title reads as one block rather than
      // three widely-spaced lines (no effect on a single-line title). The
      // block's `below` overrides Typst's default paragraph spacing, which is
      // ~1.2em of the *title* size (~1in at display sizes) and would otherwise
      // float the rule far beneath the title.
      set par(leading: 0.32em)
      block(below: 0.3em, text(size: size, weight: "bold", lines.join(linebreak())))
    }
    #if meta.subtitle != none {
      // Optional full-width rule between the title and subtitle
      // (book.yaml `title-rule: true`); otherwise just a little air.
      if meta.title-rule {
        // Seat the rule midway in the title->subtitle gap, not as an underline.
        // The subtitle paragraph carries its own leading space above it (which
        // adds to the gap below the rule), so the explicit gap ABOVE the rule
        // is the larger value to make the two read as equal.
        v(3em)
        line(length: 100%, stroke: 0.5pt)
        v(1.1em)
      } else {
        v(5em)
      }
      text(size: 1.3em, weight: "regular", tracking: 0.08em)[#upper(meta.subtitle)]
    }
    #v(3fr)
    #text(size: 1.4em)[#meta.authors.join(", ")]
    #v(0.7fr)
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
    // Colophon. The font names are pulled from meta so this line always names
    // the fonts the book was actually built with, whatever they are.
    This book was formatted by Book4matter, using Pandoc and Typst.
    The headings are set using #meta.heading-font and the body with #meta.font.
    #if meta.build-id != none [\ Printing: #meta.build-id]
  ]

  // "Also by <author>" page. Driven by the optional `also-by:` list in
  // book.yaml; skipped entirely when that list is empty. The "ALSO BY ..."
  // line is plain styled text (NOT a heading) so it neither trips the level-1
  // pagebreak show rule nor shows up in the table of contents.
  if meta.also-by.len() > 0 {
    page(numbering: none)[
      #set align(center)
      #set text(hyphenate: false)
      #set par(justify: false)
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
  // does not trip the level-1 part `pagebreak` show rule above.
  //
  // Custom entry rendering replaces typst's default outline (dot leaders,
  // flat hierarchy): no leaders, page numbers in a right-aligned tabular
  // column, part entries set off by space and styled as letterspaced caps
  // with the part number spelled out ("PART TWO · BASICS"), chapter entries
  // indented beneath their part. Page numbers render in the numbering style
  // of the page they point at, so entries for front-matter chapters (an
  // introduction before Part One) show roman folios.
  show outline.entry.where(level: 1): it => {
    // A forced linebreak inside a part title would wreck the one-line entry.
    show linebreak: _ => " "
    block(above: 1.5em, link(it.element.location(), context {
      set text(size: 0.85em, fill: luma(40%))
      // Both states were set by parts.lua *before* the heading, so reading
      // them at the heading's location is reliable (see note at the top).
      let prefix = if unnumbered-next.at(it.element.location()) { "" } else {
        // meta.part-label (default "Part") relabels the division; it's
        // uppercased with the rest of the entry below ("SECTION TWO · ...").
        meta.part-label + " " + part-word(part-num.at(it.element.location())) + " · "
      }
      grid(
        columns: (1fr, auto),
        column-gutter: 1.5em,
        align: (left + bottom, right + bottom),
        text(tracking: 0.12em, upper[#prefix#it.body()]),
        it.page(),
      )
    }))
  }
  show outline.entry.where(level: 2): it => {
    show linebreak: _ => " "
    block(above: 0.65em, link(it.element.location(), context {
      // Chapters indent beneath their part; a front-matter chapter before
      // the first part (an introduction) sits flush left.
      let indent = if query(heading.where(level: 1)
        .before(it.element.location())).len() > 0 { 1em } else { 0pt }
      grid(
        columns: (1fr, auto),
        column-gutter: 1.5em,
        align: (left + bottom, right + bottom),
        pad(left: indent, it.body()),
        it.page(),
      )
    }))
  }
  // Level 3 (topics) appear only when toc-depth >= 3. They nest one step deeper
  // than their chapter, set a little smaller and lighter so the three levels
  // stay visually distinct.
  show outline.entry.where(level: 3): it => {
    show linebreak: _ => " "
    block(above: 0.5em, link(it.element.location(), context {
      let under-part = query(heading.where(level: 1)
        .before(it.element.location())).len() > 0
      grid(
        columns: (1fr, auto),
        column-gutter: 1.5em,
        align: (left + bottom, right + bottom),
        pad(left: (if under-part { 1em } else { 0pt }) + 1.2em,
          text(size: 0.95em, fill: luma(35%), it.body())),
        it.page(),
      )
    }))
  }
  if meta.toc {
    page[
      #set par(justify: false)
      #set text(hyphenate: false)
      #v(2em)
      #text(font: meta.heading-font, size: 2em)[Contents]
      #v(0.5em)
      #line(length: 100%, stroke: 0.6pt)
      #outline(title: none, depth: meta.toc-depth)
    ]
  }

  // ================================ BODY =====================================
  // Front matter continues into the body: everything up to the first part
  // heading (e.g. an introduction) keeps the roman folios set above.
  // parts.lua injects
  //     #set page(numbering: "1")
  //     #counter(page).update(1)
  // just before the first part heading — or at the very top of a book with
  // no parts — which is where the main matter and arabic page numbers begin.
  body
}
