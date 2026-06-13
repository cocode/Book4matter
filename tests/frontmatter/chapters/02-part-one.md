# About This Book

## Why Does This Book Exist?

The part divider before this chapter is where the main matter begins: its
page should be arabic page 1, and the contents entry for "About This Book"
should read "PART ONE · ABOUT THIS BOOK" in letterspaced capitals with the
numeral 1 in the right-hand column — no dot leaders anywhere. The divider
page itself shows no folio: display pages are blind, though they still
count, which is why this chapter opens on page 2.

This chapter's own contents entry should be indented beneath the part
entry, with its page number aligned in the same right-hand column as every
other entry's.

This book also turns on `running-heads` in its book.yaml, and this chapter
runs long enough to show them working. The rules: no running head in the
front matter, none on a page where a part or chapter opens (such as this
page), and on every other body page a small-caps line centred in the head
margin — the book title on left-hand (verso) pages, the current chapter
title on right-hand (recto) pages. Whether a page is verso or recto follows
the physical sequence of the bound book, the same rule that swaps the
binding gutter from side to side.

So: this opening page must have no running head. The next page of this
chapter is a left-hand page, and should carry "Front Matter Test" in small
caps at the top. The page after that is a right-hand page, and should carry
"Why Does This Book Exist?" — and since both are ordinary text pages, each
also shows its folio at the foot.

The rest of this chapter is ballast to push it across three pages. A
six-by-nine page at eleven points holds roughly three hundred and fifty
words, so two further pages want seven hundred or so between them; the
paragraphs below supply them without saying anything that matters.

Running heads earn their keep in reference books. A reader who flips into
the middle of a novel knows roughly where they are, because a novel is read
front to back; a reader who flips into the middle of a manual is lost,
because a manual is consulted. The running head is the consultation aid:
glance at the top of the open spread and the left page names the book, the
right page names the chapter. That convention — title verso, chapter recto
— is old enough that most readers absorb it without ever noticing it, which
is the mark of furniture doing its job.

The suppression rules are equally conventional. A chapter opener already
announces itself in large type, so a running head there would be redundant
and slightly embarrassing, like introducing someone who has just introduced
themselves. Display pages — part dividers, and the blind pages of the front
matter — carry no running head for the same reason they carry no folio:
they are scenery, not text, and the furniture of navigation belongs on the
text.

There is one wrinkle worth spelling out for the test. The running head on a
right-hand page names the *current* chapter, meaning the chapter whose text
is flowing across that page. The machinery finds the most recent part or
chapter heading before the top of the page; if that turns out to be a part
heading rather than a chapter, the page is sitting between a divider and
its first chapter — overflowing divider text — and shows no running head at
all, because naming the previous part's last chapter there would be a lie.

Headers and footers also have to stay out of each other's way. The folio
keeps its place at the foot of the page whether or not a running head is
present, so switching `running-heads` on or off never reflows a book — it
only adds or removes the line at the top. That is worth a sentence in a
test fixture because the two are built from the same machinery, and a
regression that tangled them — a folio jumping into the head margin, a
running head displacing a page number — would be easy to introduce and
embarrassing to ship.

A note on the face: running heads here are set in the body face, in small
capitals, a size down from the text. Small caps are the traditional choice
because they read as a label rather than a sentence; they whisper. Setting
them in the heading face instead would shout, and the head margin of every
page is no place for shouting. If a book's body face lacks true small
caps, the synthesized ones will still pass at this size, though a discerning
eye may catch the slightly heavy strokes.

The last convention exercised here is silence in the front matter. Roman-
folioed pages — the contents, an introduction before the first part —
carry no running heads at all, however long they run. The front matter is
the porch of the book; nobody needs a signpost on the porch. Navigation
begins where the text begins, at arabic page one, which in this book is
the divider page announcing Part One.

One more paragraph should see this chapter safely onto its third page
regardless of small shifts in leading or margins. If the page you are
reading now has a centred small-caps line at its top, then either the book
title or this chapter's title is up there, on the correct side, above an
ordinary folio at the foot — exactly the modest, useful behaviour a running
head is supposed to have.

## Who Is It For?

A second chapter, so the fixture shows two indented entries grouped under
one part with vertical space setting the part group off from its
neighbours. This chapter is numbered Chapter 2 — the unnumbered
introduction must not have consumed a chapter number.
