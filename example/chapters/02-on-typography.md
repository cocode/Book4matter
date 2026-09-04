# On Typography

Good typography is mostly invisible. The reader notices a *bad* line break or a
cramped margin, but rarely a good one.

## Why a binding gutter matters

In a printed book the inside margin must be wider than the outside, because the
binding swallows part of each page. KDP rejects interiors that ignore this, which
is exactly why this pipeline sets an asymmetric **gutter** rather than symmetric
margins.

## Surviving the trip

This second section exists so the table of contents has more than one entry per
chapter. It also confirms that **bold** and *italic* survive the journey from
Markdown all the way to the printed page.

{exercise:publish Publish a test interior} --- build the `print` output and
upload the interior PDF to a KDP draft (you need not actually publish it). Then
look back at {exercise:build-it} to see how far you have come. In the printed
book that reference carries the page number; on screen it is a live link.
