-- toc-list.lua - rebuild the document as a link-free, nested table of contents.
--
-- `bf html toc` exports a book's contents for embedding on a website, where
-- the in-book section anchors would point nowhere. Pandoc's own --toc always
-- emits links, so rather than post-process that HTML we build the list here
-- from the headings: level-1 headings at the top level, level-2 headings
-- nested beneath the preceding level-1 (the same depth as the EPUB and print
-- contents, i.e. --toc-depth=2). Deeper headings are omitted.
--
-- Only the heading *text* is kept -- any Link inside a heading is flattened to
-- its label -- so the writer emits a plain <ul>/<li> tree with no anchors. The
-- wrapping <nav class="book-toc"> is a single hook for the host site's CSS.

local function is_unlisted(h)
  for _, c in ipairs(h.classes) do
    if c == "unlisted" then return true end
  end
  return false
end

-- Drop any hyperlink, keeping its visible text, so the TOC never links out.
local function delink(inlines)
  return pandoc.Span(inlines):walk({
    Link = function(l) return l.content end,
  }).content
end

function Pandoc(doc)
  -- Collect top-level entries; each carries an optional list of sub-entries.
  local entries = pandoc.List({})
  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Header" and (blk.level == 1 or blk.level == 2)
        and not is_unlisted(blk) then
      if blk.level == 1 or #entries == 0 then
        -- A level-1 heading, or a level-2 that appears before any level-1
        -- (no parent to nest under): becomes a top-level entry.
        entries:insert({ title = delink(blk.content), subs = pandoc.List({}) })
      else
        entries[#entries].subs:insert(delink(blk.content))
      end
    end
  end

  local function li(title, subs)
    local blocks = pandoc.List({ pandoc.Plain(title) })
    if #subs > 0 then
      local sub_items = pandoc.List({})
      for _, s in ipairs(subs) do
        sub_items:insert(pandoc.List({ pandoc.Plain(s) }))
      end
      blocks:insert(pandoc.BulletList(sub_items))
    end
    return blocks
  end

  local items = pandoc.List({})
  for _, e in ipairs(entries) do
    items:insert(li(e.title, e.subs))
  end

  return pandoc.Pandoc(pandoc.Blocks({
    pandoc.RawBlock("html", '<nav class="book-toc">'),
    pandoc.BulletList(items),
    pandoc.RawBlock("html", "</nav>"),
  }), doc.meta)
end
