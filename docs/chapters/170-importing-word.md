## Importing from Word

Many manuscripts begin life in Microsoft Word. The `import` command converts a
`.docx` into the Markdown this pipeline expects, so you can start from an existing
draft instead of retyping it.

```
./run.sh import manuscript.docx mybook/
```

### What it does

Pandoc converts the document to Markdown and extracts its images, and book4matter
then splits the result into chapter files:

- **One file per Heading 1.** Each `Heading 1` starts a new chapter file. The
  split is fence-aware, so a `#` inside a code block is never mistaken for a
  heading. Anything before the first Heading 1 is written to `000-frontmatter.md`
  for review --- usually you trim it, since the template makes its own title page
  and contents.
- **Numbered in steps of ten.** Files are named `010-slug.md`, `020-slug.md`, and
  so on, leaving gaps so you can slot in a part divider or an appendix later
  without renumbering the rest.
- **Images extracted to `media/`.** Pictures are pulled into a `media/` folder and
  referenced as `../media/...`, the same convention a hand-written book uses. An
  image Word had embedded in a heading is lifted out to a figure just beneath it.
- **Punctuation kept verbatim.** The author's real em dashes, curly quotes, and
  ellipses are preserved rather than rewritten, so the Markdown is clean to edit.
  Tracked changes are accepted and comments are dropped.

### Flags

- `--no-split` --- write the whole document as a single Markdown file instead of
  splitting on Heading 1.
- `--force` --- overwrite a `chapters/` folder that already holds files. By
  default the importer refuses, so existing work is never clobbered by accident.

### After importing

Expect to tidy up by hand. Import carries the words, the structure, and the
images across; you then map the headings onto book4matter's parts and chapters
(Word's single level of "Heading 1" cannot express the part/chapter distinction),
check the image sizes against the ~300 DPI print target, and trim the front
matter. From there it is an ordinary book4matter project.
