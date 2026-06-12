-- parts.lua - pandoc filter for per-heading class handling on the print side.
--
-- Part (H1) and Chapter (H2) numbers are now injected by book.typ's show
-- rules from state counters; this filter no longer rewrites heading content,
-- it only translates opt-in heading classes into typst raw blocks the
-- template can act on.

-- Pandoc does not put a --lua-filter's directory on package.path, so a plain
-- `require("_common")` would fail. PANDOC_SCRIPT_FILE is the absolute path
-- of this filter; derive its directory and prepend it.
package.path = (PANDOC_SCRIPT_FILE:match("^(.*/)") or "./") .. "?.lua;" .. package.path
local common = require("_common")

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
      end
    end
    out:insert(b)
  end
  return out
end
