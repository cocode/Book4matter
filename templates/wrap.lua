-- wrap.lua - pandoc filter that turns
--
--     ## A section
--
--     ![](path){.wrap-right width="2.04in"}
--
--     Paragraphs (and sub-headings) that belong to this section.
--
--     ## Next section   <- ends the wrap region
--
-- into a typst `wrap-content(...)` call. The image goes on the right (or left,
-- for .wrap-left), and the body of the wrap is every block that follows the
-- image up to (but not including) the next heading at the same level as the
-- one the image sits under, or shallower. wrap-it itself takes care of
-- splitting the body at the bottom of the image and continuing the rest at
-- full page width.
--
-- The output assumes `wrap-content` is in scope (kpc prepends an import for
-- "@preview/wrap-it" to the generated body).
--
-- It also handles a standalone `.center` image (`![](path){.center}`),
-- emitting `#align(center)[...]` so a caption-less image is centred on its own
-- line instead of sitting flush-left. (A captioned image is already centred by
-- typst's default figure handling; this is for the no-caption case.)

local function typst_str(s)
  return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

-- Returns (image, align) if `block` is a standalone wrap-tagged image,
-- otherwise nil.
local function wrap_descriptor(block)
  if block.t ~= "Para" or #block.content ~= 1 then return nil end
  local img = block.content[1]
  if img.t ~= "Image" then return nil end
  for _, c in ipairs(img.classes) do
    if c == "wrap-right" then return img, "right" end
    if c == "wrap-left"  then return img, "left"  end
  end
  return nil
end

local function emit_wrap(img, body_blocks, align)
  local image_args = typst_str(img.src)
  local w = img.attributes.width
  if w and w ~= "" then image_args = image_args .. ", width: " .. w end
  local body_typst = pandoc.write(pandoc.Pandoc(body_blocks), "typst")
  -- Pin the grid columns so the image actually lands flush with the page
  -- margin (and the body column fills the rest). Without this, wrap-it's
  -- default `columns: 2` lets typst auto-size the columns, which collapses
  -- the body column to zero when the body is empty and parks the image at
  -- the wrong horizontal position.
  local columns = (align == "right") and "(1fr, auto)" or "(auto, 1fr)"
  return pandoc.RawBlock("typst", string.format(
    "#wrap-content(\n  image(%s),\n  [\n%s  ],\n  align: %s,\n  columns: %s,\n)\n",
    image_args, body_typst, align, columns))
end

-- Returns the image if `block` is a standalone `.center` image, otherwise nil.
local function center_descriptor(block)
  if block.t ~= "Para" or #block.content ~= 1 then return nil end
  local img = block.content[1]
  if img.t ~= "Image" then return nil end
  for _, c in ipairs(img.classes) do
    if c == "center" then return img end
  end
  return nil
end

-- A standalone `.center` image: centre it as its own block. We reuse pandoc's
-- own typst serialization of the image (so width/height are handled exactly as
-- everywhere else) and wrap it in `#align(center)[...]`. typst ignores the
-- `.center` class itself, so the marker never reaches the output.
local function emit_center(img)
  local img_typst = pandoc.write(pandoc.Pandoc({ pandoc.Para { img } }), "typst")
  return pandoc.RawBlock("typst", "#align(center)[" .. img_typst .. "]")
end

function Blocks(blocks)
  local out = pandoc.List()
  local i = 1
  -- Level of the most recent heading we've seen at this block-list level.
  -- The wrap consumes blocks until the next heading whose level is <= this,
  -- i.e. the next sibling (or shallower) section.
  local section_level = 99
  while i <= #blocks do
    local b = blocks[i]
    if b.t == "Header" then section_level = b.level end
    local img, align = wrap_descriptor(b)
    if img then
      local body = pandoc.List()
      i = i + 1
      while i <= #blocks do
        local n = blocks[i]
        if n.t == "Header" and n.level <= section_level then break end
        body:insert(n)
        i = i + 1
      end
      out:insert(emit_wrap(img, body, align))
    else
      local cimg = center_descriptor(b)
      if cimg then
        out:insert(emit_center(cimg))
      else
        out:insert(b)
      end
      i = i + 1
    end
  end
  return out
end
