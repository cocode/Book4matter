# One source, four outputs

Every output is generated from the same Markdown, so they never fall out of
sync.

## Print PDF

A ready-to-print PDF.

I've used this for Amazon KDP, so it follows the rules there, like "no hyperlinks".

External hyperlinks are reformatted to show the URL after the anchor text. 
 Internal links are [converted to page number references](https://book4matter.com/examples/docs/book4matter.html#links-in-pdf-and-print), like

    See HTML on page 37

A table of contents is automatically generated. This PDF does not include a cover, since that is a separate upload on KDP.

## Shareable PDF

The same book with live, clickable hyperlinks and a linked table of contents —
the version you email or post, not the one you send to a printer. This version can include a cover image, if you want.

## EPUB

A reflowable e-book that passes the W3C EPUBCheck validator (the same class of
checks KDP runs on upload), so most rejections are caught before you ever
upload.

Note: Each EPUB publisher has different requirements. They restrict things like manuscript length, image size, and even limits on references to other publishers. You'll want to check these out, before publishing.

## Website

One self-contained HTML page with an automatic table of contents and [your own
stylesheet](https://book4matter.com/examples/docs/book4matter.html#restyling-the-website-without-touching-the-template)

This is how this website was generated. 
