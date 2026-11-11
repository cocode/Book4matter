## Under the Hood 

Book4matter is a book focused wrapper for two excellent tools, [Pandoc](https://pandoc.org/)
and [Typst](https://typst.app/) allowing you
to use their power, without you having to deal with the details.

1. **Pandoc** reads your Markdown and your two YAML config files.
2. For **print and PDF**, Pandoc emits Typst, and **Typst** does the page
   layout — margins, running heads, hyphenation, front matter.
3. For **EPUB and HTML**, Pandoc writes those directly, sharing the same
   metadata and styling decisions.

Because the styling lives outside your prose, the same manuscript flows into
every format without edits, and one change to a style file re-themes every book
that points at it. And you can use the command-line version of Book4matter to automatically
rebuild the book with every new version of your manuscript.

### Learn more

The full [manual](https://book4matter.com/examples/docs/book4matter.html) —
installation, configuration, every command, and the design decisions behind the
defaults — is itself a Book4matter book. Read it online, build it from the
`docs/` directory, or read the source in the
[repository](https://github.com/cocode/Book4matter/tree/main/docs).
