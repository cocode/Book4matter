## Images, Figures, and Scene Breaks

### Where images live

Keep images in a `media/` folder at the root of your book. Chapter files sit one
level down, in `chapters/`, so they reference an image with a leading `../`:

```
![A frame from the Gaskell Ball](../media/gaskell.jpg)
```

That one path works everywhere --- the print build, the EPUB, the HTML, and your
Markdown editor's preview --- because the build compiles from the book root and
never rewrites your paths.

### Captions and centering

A captioned image becomes a centered figure automatically, in every format:

```
![The closed hold, seen from above](../media/hold.png)
```

An image with **no** caption is treated as inline text and sits flush left. To
center a caption-less image on its own line, tag it `{.center}`:

```
![](../media/ornament.svg){.center}
```

### Sizing

Set the size with `width` or `height`:

```
![](../media/diagram.svg){width="3in"}
```

Give **one** dimension and the other scales to keep the image's proportions.
Setting both `width` and `height` to a ratio that does not match the image can
crop it, so as a rule size by a single dimension. SVG line art is welcome and
scales without loss; for photographs, supply roughly 300 DPI at the printed size,
which is what KDP expects for a sharp result.

### Wrapping text around an image

To float an image to one side and let the section's text flow beside it, tag it
`{.wrap-right}` or `{.wrap-left}`:

```
![](../media/step.svg){.wrap-right width="2in"}

The text of this section flows up the side of the image and returns to full
width once it clears the bottom edge.
```

The wrap runs from the image to the end of its section --- that is, until the
next heading at the same level or shallower. In print this is a true text wrap;
in EPUB and HTML it is a CSS float, which modern e-readers honor and older ones
quietly ignore (the image just becomes a normal block --- fine either way).

### Scene breaks

A "scene break" between passages is written as three hyphens alone on their own
line. In EPUB and HTML it renders as a centered `* * *` ornament instead of a
hard rule.

> **Print note.** The PDF pipeline does not yet render a bare scene break --- the
> Typst template defines no rule for it --- so avoid one in a book you build to
> print until that support is added.
