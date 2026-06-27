-- parts.lua - pandoc filter for per-heading concerns on the print side.
--
-- Part (H1) and Chapter (H2) labels are injected by book.typ's show rules;
-- this filter never rewrites heading content. It does three things:
--
--   1. translates opt-in heading classes (.new-page, .unnumbered) into typst
--      raw blocks the template acts on;
--   2. counts numbered parts (mirroring epub-parts.lua) and emits
--      `#part-num.update(N)` before each, so both the part divider and the
--      table of contents can read the part's number *at* the heading's
--      location — a state incremented inside the show rule would land after
--      the heading and read off by one from the outline;
--   3. marks where the main matter begins (the first part heading), so the
--      template's roman front-matter folios switch to arabic numbering
--      there. Anything before the first part — an introduction, a preface —
--      is front matter: roman folios, listed in the contents before Part One;
--   4. gathers divider text: blocks between a part heading and the next
--      heading (i.e. text written under the part title in the part's own
--      chapter file) are wrapped in `#part-text[...]` so they print on the
--      divider page itself, beneath the title, instead of spilling onto the
--      following page.

-- Pandoc does not put a --lua-filter's directory on package.path, so a plain
-- `require("_common")` would fail. PANDOC_SCRIPT_FILE is the absolute path
-- of this filter; derive its directory and prepend it.
package.path = (PANDOC_SCRIPT_FILE:match("^(.*/)") or "./") .. "?.lua;" .. package.path
local common = require("_common")

-- Document-wide part counter. The pandoc invocation is given every chapter
-- file at once, so a single counter is consistent across the whole book.
local part_count = 0

-- Level-1 headings flagged `.section` (afterword, appendix, acknowledgments).
-- Keyed by the header object so the Pandoc pass below can tell them apart from
-- real parts when it looks for where the main matter begins -- by then the
-- `.section` class has already been stripped, so the object identity is the
-- only marker left.
local section_headers = {}

-- Per-heading class handling. The class is stripped from the heading so it
-- doesn't pollute the AST further down the pipeline.
--
-- Supported classes:
--   `.new-page`    -- emit a weak pagebreak just before the heading
--   `.unnumbered`  -- on H1 (part) and H2 (chapter), skip the auto label
--                     ("PART N" / "CHAPTER N"). book.typ reads this via a
--                     state set just before the heading; pandoc's `{-}`
--                     shorthand also maps here. A single state covers both
--                     levels because it's consumed by the very next heading.
--   `.section`     -- on H1, render the heading like an unnumbered chapter
--                     instead of a part divider: a top-of-contents entry with
--                     no number whose body flows as ordinary text. For an
--                     afterword, appendix, acknowledgments, etc.
function Blocks(blocks)
  local out = pandoc.List()
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    if b.t == "Header" and b.level == 6 and blocks[i + 1]
        and blocks[i + 1].t == "Para" then
      -- Run-in heading: fold a level-6 heading into the first line of the
      -- paragraph that follows it. The heading's words are wrapped in
      -- `#runin[...]` (defined in book.typ), which sets the heading font, bolds
      -- them, adds a full stop and a little space; the paragraph then flows on
      -- from there. Both blocks become one Para. A level-6 heading *not*
      -- followed by a paragraph falls through to book.typ's block fallback.
      local para = blocks[i + 1]
      local merged = pandoc.List()
      merged:insert(pandoc.RawInline("typst", "#runin["))
      merged:extend(b.content)
      merged:insert(pandoc.RawInline("typst", "]"))
      merged:extend(para.content)
      out:insert(pandoc.Para(merged))
      i = i + 1  -- also consume the paragraph (the loop tail advances past it)
    elseif b.t == "Header" then
      if common.pop_class(b, "new-page") then
        out:insert(pandoc.RawBlock("typst", "#pagebreak(weak: true)"))
      end
      if b.level == 1 and common.pop_class(b, "section") then
        -- Top-level section (afterword/appendix/acknowledgments): a level-1
        -- heading set like an unnumbered chapter rather than a part divider
        -- (book.typ reads #section-next). It carries no number, and its body
        -- flows as ordinary text, so we skip both the part counter and the
        -- #part-text divider machinery. #section-next also makes the contents
        -- entry drop the "Part N ·" prefix.
        --
        -- Like #part-num, this flag is set before the heading and only *read* by
        -- the show rules (never updated inside them), so the contents can query
        -- it at the heading's location without a show-rule update racing it.
        section_headers[b] = true
        out:insert(pandoc.RawBlock("typst", "#section-next.update(true)"))
        out:insert(b)
      else
        if b.level == 1 then
          -- Clear the section flag before a normal part, so it never leaks from
          -- an earlier `.section` (e.g. an appendix followed by a further part).
          out:insert(pandoc.RawBlock("typst", "#section-next.update(false)"))
        end
        if (b.level == 1 or b.level == 2) and common.pop_class(b, "unnumbered") then
          out:insert(pandoc.RawBlock("typst", "#unnumbered-next.update(true)"))
        elseif b.level == 1 then
          part_count = part_count + 1
          out:insert(pandoc.RawBlock("typst",
            "#part-num.update(" .. part_count .. ")"))
        end
        if b.level == 1 then
          -- Divider text: everything up to the next heading belongs on the
          -- part page. The flag must precede the heading (its show rule
          -- consumes it), so look ahead before emitting anything.
          local last = i
          while last + 1 <= #blocks and blocks[last + 1].t ~= "Header" do
            last = last + 1
          end
          if last > i then
            out:insert(pandoc.RawBlock("typst", "#part-text-next.update(true)"))
            out:insert(b)
            out:insert(pandoc.RawBlock("typst", "#part-text["))
            for j = i + 1, last do
              out:insert(blocks[j])
            end
            out:insert(pandoc.RawBlock("typst", "]"))
            i = last
          else
            out:insert(b)
          end
        else
          out:insert(b)
        end
      end
    else
      out:insert(b)
    end
    i = i + 1
  end
  return out
end

-- Front matter ends at the first part heading: everything before it keeps
-- the template's roman folios. This runs after Blocks (pandoc applies the
-- Pandoc function last), so the insert position also sits correctly relative
-- to the raw state blocks emitted above. A book with no parts at all gets
-- the switch at the very top: arabic page 1 is its first content page, as
-- before.
local parts_recto = (os.getenv("BF_PARTS_RECTO") == "1")

function Pandoc(doc)
  local at = 1
  local has_part = false
  for i, b in ipairs(doc.blocks) do
    -- A `.section` heading is level-1 but not a part, so it must not be mistaken
    -- for where the main matter begins (e.g. a chapters-only book with an
    -- afterword would otherwise switch to arabic folios at the afterword).
    if b.t == "Header" and b.level == 1 and not section_headers[b] then
      at = i
      has_part = true
      break
    end
  end
  doc.blocks:insert(at, pandoc.RawBlock("typst",
    '#set page(numbering: "1")\n#counter(page).update(1)'))
  -- When parts open on a recto, break to the odd page *before* that reset, so
  -- the blank Typst inserts stays in the roman front matter and the part's own
  -- page becomes arabic 1 (rather than the inserted blank taking number 1).
  if parts_recto and has_part then
    doc.blocks:insert(at, pandoc.RawBlock("typst",
      '#pagebreak(weak: true, to: "odd")'))
  end
  return doc
end
