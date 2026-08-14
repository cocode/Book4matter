## Tables, Quotes, Footnotes, Links and Math

Ordinary book prose --- tables, quotations, notes, and links --- needs no special
syntax beyond standard Markdown. Book4matter sets each in book style.

### Tables

Write a normal Markdown pipe table and align a column with colons in the divider
row. In the PDF outputs it is set in book (booktabs) style: a rule above, a rule
under the header, and a rule below --- no vertical lines, no shaded cells ---
with the header in bold and figures set in tabular (fixed-width) columns so
digits line up.

```
| Step | Count | Beats |
|------|------:|------:|
| Rise |     1 |     1 |
| Turn |     2 |    23 |
| Fall |     3 |   456 |
```

### Block quotes

Mark a quotation with `>`; never indent by hand. A block quote is set a little
smaller and in italic, indented from both margins with air above and below:

> Waltzing has undergone so many alterations that the dance of today bears little
> resemblance to its ancestor --- yet the family likeness survives.

### Footnotes

Markdown footnotes work as usual. In the two PDF outputs they fall to the foot
of the page; in EPUB and HTML they collect at the end of the chapter, linked
from a superscript marker. The digital `pdf` output keeps its footnote markers
clickable; the `print` output does not, because KDP rejects internal hyperlinks
in print interiors.

While you can put footnotes anywhere, we recommend putting them in the file where
they are referenced. If you put all the footnotes in an otherwise empty file, 
you may end up with a "Ghost Chapter" in the table of contents, represeting
the empty file. This will happen with an empty file, too.

```
Practice the rise slowly at first.[^rise]

[^rise]: Rising too early is the commonest beginner's mistake.
```

### Links

Links survive to every format, but the target decides whether they are clickable.
Use the digital `pdf`, EPUB, and HTML outputs when links should work on screen;
use `print` when the file is going to a printer or to KDP.

- **In digital PDF, EPUB, and HTML** links stay live. That includes the table of
  contents, footnotes, cross-references, and external web links.
- **In print** there are no clickable annotations, because KDP rejects them, but
  the links still guide the reader. An internal cross-reference to another part
  of the book --- `[Rotation](#rotation)` --- prints as its text followed by the
  page it points to, so `"Rotation" (page 42)`; the page number is resolved for
  you at build time and updates automatically as the book repaginates. (A link
  whose target is missing simply prints its text.) External web links print the
  destination after the visible text, so `[CLICK HERE](https://www.example.com)`
  becomes `CLICK HERE (https://www.example.com)`. A bare autolink shows its URL
  once. Email addresses are kept whole and never broken at a hyphen across a line.

Write internal links with Markdown link syntax, `[text](#anchor)`, where the
anchor matches a heading. Raw HTML anchors like `<a href="#anchor">` do not
survive to print --- only the Markdown form is turned into a page reference.

### Punctuation

Write punctuation the Markdown way and the build sets it properly: `--` becomes
an en dash, `---` an em dash, and straight quotes turn into curly ones. There is
no need to paste Unicode dashes or smart quotes by hand.

### Math

Unfortunately, we don't yet have math expressions working fully in HTML and EPUB. 
They work fine in pdf and print.

