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
