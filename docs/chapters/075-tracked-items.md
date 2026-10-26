## Auto-Numbering, Cross-References, and Lists

Books are full of things that are numbered and referred to: exercises, figures,
charts, tables. Numbering them by hand is a trap --- insert one new figure early
on and every later number, and every reference to it, is suddenly wrong.
Book4matter numbers these *tracked items* for you, lets you refer to them by a
name you choose (never by number), and can gather them into a list --- a *List of
Exercises*, a *List of Figures* --- with the correct page beside each.

### Register the kinds you use

First tell the book which kinds of thing you track, in `book_metadata.yaml`. Each
kind gets a `label`: the word printed before the number and heading its list.

```
tracked:
  exercise: { label: "Exercise" }
  figure:   { label: "Figure" }
  chart:    { label: "Chart" }
  table:    { label: "Table" }
```

Registering the kinds up front is what keeps the feature safe: only these words
are treated as tracked-item markup, so an ordinary `{ratio: 3:2}` written in your
prose is left completely alone. A kind is lowercase letters, digits, or hyphens.

### Define an item where it belongs

Give each item a short id --- a name that means something to you, unique within
the whole book. Two ways to write a definition:

```
{exercise:pushups:def}
{exercise:pushups Push-ups to failure}
```

The first defines an exercise with the id `pushups` and no title. The second does
the same but adds a title: **anything after the first space is the title**. Both
print in place as *Exercise 3* (whatever the next number is); the title is not
printed here --- it is saved for the list at the back. Write any caption text
around the token yourself:

```
{figure:rotary A rotary telephone}. *An early rotary dial, c. 1950.*
```

For a figure or chart, put the definition in the caption beside the image; for an
exercise, at the head of the exercise. Each kind counts on its own, so your first
figure is *Figure 1* even if three exercises came before it.

### Refer to an item by name

Anywhere else --- before or after the definition --- refer to the item with just
its kind and id, no `:def`:

```
Warm up before you attempt {exercise:pushups}.
```

That prints *Exercise 3*, and the number is always right because the build looks
it up. What the reference becomes depends on the output, exactly like any other
internal link:

- **In digital PDF, EPUB, and HTML** it is a live, clickable link to the item.
- **In print** there are no clickable links (KDP forbids them), so it prints the
  number followed by the page, as *Exercise 3 (page 42)* --- resolved for you and
  kept correct as the book repaginates.

Because you never type a number, inserting, removing, or reordering items is
free: every number and every page updates on the next build.

### List them at the back (or the front)

Drop this on a line of its own wherever you want the list to appear:

```
{index:exercise}
```

It prints every exercise in order of appearance, each one a link to the item.
In the print and digital PDF outputs each entry carries its **page number**, like
a table of contents for your exercises; in EPUB and HTML, which have no fixed
pages, the entry is simply a tappable link. Give it a heading of its own:

```
# List of Exercises {.section}

{index:exercise}
```

By book convention a *List of Figures* or *List of Tables* sits in the front
matter, just after the table of contents, while an alphabetical index of terms
goes in the back. Book4matter does not force either: the list appears wherever
you place `{index:...}`, and the page numbers resolve correctly whether the
content it points to comes before or after it.

### When something is wrong, the build says so

The system fails loudly rather than printing a quietly wrong book:

- A reference to an id that is **never defined** stops the build and names it ---
  usually a typo in the id, or a definition you forgot to mark with `:def`.
- **Defining the same id twice** for one kind stops the build.
- An **unregistered kind in an unmistakable token** --- `{exercise:x:def}` or
  `{index:exercise}` when `exercise` isn't in your `tracked:` map --- stops the
  build. This is what catches the commonest mistake: forgetting the `tracked:`
  block altogether, or mistyping a kind (`{index:figurse}`).

The two *unmistakable* forms are the `:def` keyword and `{index:...}`; they can
only be tracked markup, so an unregistered kind there is always an error. The
plainer forms overlap with ordinary writing, so `{exercise:pushups}` or
`{exercise:pushups A title}` with an *unregistered* kind is left as text and
prints verbatim (you will see it and can fix it) rather than being seized from
your prose. Either way, tokens inside `code spans` and fenced code blocks are
never touched --- which is how this chapter shows them to you.

Numbering is book-wide, so the one output that cannot do it is a **single-chapter
HTML fragment** (`html chapter N`): with only one chapter in hand there is no way
to number across the book or resolve a reference to another chapter, so tracked
tokens are left as-is there. Every whole-book output --- print, PDF, EPUB, and
the whole-book HTML page --- handles them fully.

### An alphabetical index of terms

Mark a definition by surrounding its words with double brackets:

```markdown
Let's talk about [[practice hold]] in [[Rotary Waltz]].
```

The sentence prints as ordinary text, with no brackets, numbering, or special
styling. Only marked definitions enter the index; other mentions are not
collected automatically. No `tracked:` registration is needed for terms.
The name `term` is reserved for this built-in index.

Place the index on its own line, under a heading of your choice:

```markdown
# Index {.section}

{index:term}
```

Entries sort alphabetically without regard to case. Repeated definitions of the
same term share an entry, using the spelling of the first definition. In print
and PDF the entry lists its page numbers, with each page listed only once.
Digital PDF page numbers link to their definitions; print has no hyperlinks.
HTML and EPUB link the term to its first definition, with numbered links to
additional definitions. The index may appear before or after the definitions.

Every definition has a separate term-based anchor, such as `idx-frame-1` or
`idx-practice-hold-1`. Additional definitions with the same slug increment the
suffix. Heading definitions retain their own index anchors on the term itself.
The build removes duplicate index IDs from generated navigation, keeping the
definition as the unique target and its heading visible when following a link.
Ordinary heading links continue to use the heading's original anchor.
In print and PDF, the contents renders the heading text without its index
marker. A repeated definition marker stops the build with the term and anchor
ID in the error, rather than silently indexing a contents-page copy. Separate
intentional definitions of the same term still have distinct IDs and are valid.
HTML and EPUB also validate index anchors after navigation cleanup: a duplicate
ID or any definition ID left in navigation stops the build, naming the anchor,
generated file, and line numbers. EPUB checks across chapter files as well as
within each file, even when EPUBCheck is disabled with `--no-check`.

Markers must contain plain text; place emphasis around the entire marker if
needed (`*[[practice hold]]*`). Markers in code spans and code blocks stay literal.
Reference (`:ref`) syntax is not supported yet.
Single-chapter HTML fragments leave markers literal, like other tracked markup.

### Indexing text that is already a link

Put the double-bracket definition inside the ordinary Markdown link text:

```markdown
I started taking classes with Stanford University's [[[Richard Powers]]](https://www.richardpowers.com).
```

The three opening brackets are intentional: the outer `[` starts the link
text, and the inner `[[` starts the index definition. The closing brackets
nest the same way, followed by the link destination in parentheses. No spaces,
escapes, or bold markup are needed.

The name remains an ordinary outbound link, with the same styling as other
links. The **Richard Powers** entry in `{index:term}` links back to the name's
location in the book; clicking the name in the prose follows the external URL.
This combines an outbound link and an index definition without creating nested
links: the index definition supplies an anchor inside the outbound link.

### Using a different name in the index

Separate the visible text from the index entry with `|`:

```markdown
I started taking classes with [[Richard Powers|Powers, Richard]].
```

The prose shows **Richard Powers**, while the index lists **Powers, Richard**
under P. Both sides are plain text; spaces around the separator are trimmed.
The index entry determines grouping, alphabetical sorting, and the anchor name
(for example, `idx-powers-richard-1`). Different visible names with the same
index entry are collected together, just like repeated ordinary definitions.

This also works inside an outbound link, without adding bold formatting:

```markdown
I started taking classes with Stanford University's [[[Richard Powers|Powers, Richard]]](https://www.richardpowers.com).
```

Clicking the name in the prose opens the external website; clicking
**Powers, Richard** in the index returns to this passage. In print and PDF,
the index entry has the definition's page number as usual. Use exactly one `|`
and provide nonempty text on both sides. Existing `[[term]]` definitions work
unchanged, using the same words in the prose and index.

### Grouping terms with subentries

Use `>` in the index wording to separate a parent entry from a subentry:

```markdown
[[Practice hold]]
[[polka hold|Practice hold>polka]]
```

The second marker displays **polka hold** in the prose. The index groups it
under **Practice hold**, with an indented **polka** entry:

```text
Practice hold ................ 22
    ↳ polka .................. 23
```

Use `|` to separate the visible words from the index wording, as with other
aliases. Spaces around `>` are optional and trimmed. The parent and its
subentries sort alphabetically without regard to case; repeated definitions
of the same subentry share one entry, with duplicate page numbers removed.
Subentries with the same name under different parents remain separate.

If only a subentry is marked, its parent is created automatically. A parent
gets its own page numbers or definition links only from explicit parent
markers such as `[[Practice hold]]`; it does not collect its children's pages.
In HTML and EPUB, children link to their own definitions, and an automatically
created parent without a definition is plain text.

Subentries also work in headings and outbound links:

```markdown
## [[Polka practice hold|Practice hold>polka]]

[[[polka hold|Practice hold>polka]]](https://example.com)
```

The heading keeps its normal appearance and the link still opens the external
website. The index links to the marked term in the book. Each definition has
its own anchor, such as `idx-practice-hold-polka-1`, excluded from the contents
in every format.

Index rows have dot leaders between the term and its locations, and every
subentry has a `↳` marker as well as indentation. In HTML and EPUB, the numbers
on the right are linked occurrence numbers (1, 2, and so on), not fixed page
numbers; the term itself also links to the first definition. Automatically
created parents without definitions have no leaders or location numbers.

Print and PDF keep each parent with its first child. If a group spans pages,
the parent repeats as **Practice hold (continued)** above the children on each
subsequent page. The continuation heading does not repeat the parent's page
numbers or create a new index definition. Long child rows stay together.

One level of subentries is supported. Both parent and child must be nonempty;
`[[text|Parent>]]`, `[[text|>child]]`, and `[[text|A>B>C]]` stop the build with a
markup error. Commas remain ordinary index text, as in `Powers, Richard`.

### Finding markup errors

Invalid term definitions stop the build with a reason, the original chapter
path and line number, and the offending marker. For example:

```text
tracked.lua: term definitions require nonempty display text and index entry
  at /path/to/book/chapters/010-introduction.md:12
  offending markup: [[Richard Powers|]]
```

Print diagnostics refer to the chapter you edit, rather than a temporary file
created during preprocessing. If identical markup occurs in several places,
the error lists matching source locations instead of guessing one. For input
from standard input or markup transformed by Markdown parsing, a source location
may be unavailable; the message still includes the offending marker.
