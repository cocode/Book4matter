# How it works {.unnumbered}

Book4matter is a thin pipeline over two excellent tools, wired together so you
never have to touch either directly.

1. **Pandoc** reads your Markdown and your two YAML config files.
2. For **print and PDF**, Pandoc emits Typst, and **Typst** does the page
   layout — margins, running heads, hyphenation, front matter.
3. For **EPUB and HTML**, Pandoc writes those directly, sharing the same
   metadata and styling decisions.

Because the styling lives outside your prose, the same manuscript flows into
every format without edits, and one change to a style file re-themes every book
that points at it.

## Learn more

The full manual — installation, configuration, every command, and the design
decisions behind the defaults — is itself a Book4matter book. Build it from the
`docs/` directory, or read it in the repository.

Book4matter is a command-line tool, and open source. If you're comfortable in a
terminal and want your words to look like a real book, it's built for you.
