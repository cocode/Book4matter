-- epub-wrap.lua - HTML-emitting counterpart to wrap.lua.
--
-- In the print pipeline wrap.lua wraps the *body* of a section into a typst
-- `wrap-content(...)` call because typst has no CSS float. For EPUB we don't
-- need to do that: CSS `float: right|left` on the figure makes subsequent text
-- flow around it naturally. So this filter only has to put the .wrap-* class
-- on a containing <figure>; the rest of the section is left alone.
--
-- We do this by constructing a pandoc.Figure node rather than emitting a raw
-- HTML string. Going through pandoc's AST avoids a subtle round-trip bug: a
-- RawBlock("html", '... alt="" ...') gets reparsed by pandoc's HTML reader,
-- which normalizes empty boolean-style attributes to bare `alt`, which then
-- fails XHTML validation when the EPUB writer serializes it.
--
-- Modern Kindle (KF8 and later) honors `float` on figures. Older readers
-- ignore it, and the figure renders as a plain block — the correct graceful
-- degradation, no extra work needed.

local function pop_wrap_class(img)
  for i, c in ipairs(img.classes) do
    if c == "wrap-right" or c == "wrap-left" then
      img.classes:remove(i)
      return c
    end
  end
  return nil
end

function Para(p)
  -- Only standalone images (one Image, nothing else) get the figure treatment;
  -- a `.wrap-right` image inline with text would be ambiguous and we'd rather
  -- emit the plain image than guess wrong.
  if #p.content ~= 1 or p.content[1].t ~= "Image" then return nil end
  local img = p.content[1]
  local cls = pop_wrap_class(img)
  if not cls then return nil end

  -- The image's caption becomes the figure caption; an empty caption stays
  -- empty (no <figcaption> emitted).
  local caption = pandoc.Caption(img.caption or {})
  -- Empty the image's own caption so pandoc's implicit_figures doesn't try
  -- to wrap it again inside our figure.
  img.caption = pandoc.Inlines({})

  return pandoc.Figure(
    pandoc.Blocks({ pandoc.Plain({img}) }),
    caption,
    pandoc.Attr("", {cls}, {})
  )
end
