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
--      is front matter: roman folios, listed in the contents before Part One.

-- Pandoc does not put a --lua-filter's directory on package.path, so a plain
-- `require("_common")` would fail. PANDOC_SCRIPT_FILE is the absolute path
-- of this filter; derive its directory and prepend it.
package.path = (PANDOC_SCRIPT_FILE:match("^(.*/)") or "./") .. "?.lua;" .. package.path
local common = require("_common")

-- Document-wide part counter. The pandoc invocation is given every chapter
-- file at once, so a single counter is consistent across the whole book.
local part_count = 0

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
function Blocks(blocks)
  local out = pandoc.List()
  for _, b in ipairs(blocks) do
    if b.t == "Header" then
      if common.pop_class(b, "new-page") then
        out:insert(pandoc.RawBlock("typst", "#pagebreak(weak: true)"))
      end
      if (b.level == 1 or b.level == 2) and common.pop_class(b, "unnumbered") then
        out:insert(pandoc.RawBlock("typst", "#unnumbered-next.update(true)"))
      elseif b.level == 1 then
        part_count = part_count + 1
        out:insert(pandoc.RawBlock("typst",
          "#part-num.update(" .. part_count .. ")"))
      end
    end
    out:insert(b)
  end
  return out
end

-- Front matter ends at the first part heading: everything before it keeps
-- the template's roman folios. This runs after Blocks (pandoc applies the
-- Pandoc function last), so the insert position also sits correctly relative
-- to the raw state blocks emitted above. A book with no parts at all gets
-- the switch at the very top: arabic page 1 is its first content page, as
-- before.
function Pandoc(doc)
  local at = 1
  for i, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 1 then
      at = i
      break
    end
  end
  doc.blocks:insert(at, pandoc.RawBlock("typst",
    '#set page(numbering: "1")\n#counter(page).update(1)'))
  return doc
end
