-- parts.lua - pandoc filter that turns a level-1 heading like
--
--     # Part I - About This Book
--
-- into a heading whose body is split across two lines:
--
--     Part I
--     About This Book
--
-- so the part-divider show rule in book.typ can render the part number
-- and the title stacked. Recognised separators are `-`, `--`, `---`,
-- en-dash, and em-dash. Headings that don't match are left alone.

local function split_part_title(text)
  -- Order matters: try the longer / multi-byte dashes first.
  for _, sep in ipairs({" \u{2014} ", " \u{2013} ", " --- ", " -- ", " - "}) do
    local i, j = text:find(sep, 1, true)
    if i then
      return text:sub(1, i - 1), text:sub(j + 1)
    end
  end
  return nil
end

function Header(h)
  if h.level ~= 1 then return nil end
  local text = pandoc.utils.stringify(h.content)
  local prefix, title = split_part_title(text)
  if not prefix or not title then return nil end
  if not prefix:match("^[Pp]art%s") then return nil end
  h.content = pandoc.Inlines({
    pandoc.Str(prefix),
    pandoc.LineBreak(),
    pandoc.Str(title),
  })
  return h
end

-- Per-heading class handling. The class is stripped from the heading so it
-- doesn't pollute the AST further down the pipeline.
--
-- Supported classes:
--   `.new-page`    -- emit a weak pagebreak just before the heading
--   `.unnumbered`  -- on level-2 headings, skip the auto "Chapter N" label
--                     (book.typ reads this via a state set just before the
--                     heading; pandoc's `{-}` shorthand also maps here)
local function pop_class(h, name)
  for i, c in ipairs(h.classes) do
    if c == name then
      h.classes:remove(i)
      return true
    end
  end
  return false
end

function Blocks(blocks)
  local out = pandoc.List()
  for _, b in ipairs(blocks) do
    if b.t == "Header" then
      if pop_class(b, "new-page") then
        out:insert(pandoc.RawBlock("typst", "#pagebreak(weak: true)"))
      end
      if b.level == 2 and pop_class(b, "unnumbered") then
        out:insert(pandoc.RawBlock("typst", "#unnumbered-next.update(true)"))
      end
    end
    out:insert(b)
  end
  return out
end
