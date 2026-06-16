-- epub-parts.lua - HTML-emitting counterpart to parts.lua.
--
-- Injects auto-numbered "Part N" / "Chapter N" labels into H1 / H2 headings,
-- mirroring book.typ's print show rules. The label is a <span> with a class
-- that epub.css renders as display:block above the title text, so the
-- heading reads
--     Part 1
--     About This Book
-- visually, while remaining a single <h1> (or <h2>) semantically.
--
-- Heading classes:
--   .new-page   -> kept on the heading so epub.css can do
--                  `page-break-before: always`.
--   .unnumbered -> suppress the auto label on H1 and H2 (matches print).
--                  Stripped from the AST either way so it doesn't leak into
--                  the HTML class list.

-- Pandoc does not put a --lua-filter's directory on package.path, so a plain
-- `require("_common")` would fail. PANDOC_SCRIPT_FILE is the absolute path
-- of this filter; derive its directory and prepend it.
package.path = (PANDOC_SCRIPT_FILE:match("^(.*/)") or "./") .. "?.lua;" .. package.path
local common = require("_common")

-- Document-wide counters. The pandoc invocation is given every chapter file
-- at once, so these single state variables yield a consistent count across
-- the whole book even when the EPUB is later split into multiple xhtml files.
local part_count = 0
local chapter_count = 0

function Header(h)
  -- `.unnumbered` is the print template's signal to skip auto-numbering. We
  -- mirror that here, and strip the class so it doesn't reach the HTML
  -- writer regardless of whether we acted on it.
  local unnumbered = common.pop_class(h, "unnumbered")

  if h.level == 1 and not unnumbered then
    part_count = part_count + 1
    local new_content = pandoc.Inlines({
      pandoc.Span({pandoc.Str("Part " .. part_count)},
                  {class = "part-label"}),
      -- Separator so the label and title don't run together when flattened
      -- inline (the TOC); harmless in the heading, where the label is
      -- display:block and a leading space on the next line collapses.
      pandoc.Space(),
    })
    new_content:extend(h.content)
    h.content = new_content
    return h
  end

  if h.level == 2 and not unnumbered then
    chapter_count = chapter_count + 1
    local new_content = pandoc.Inlines({
      pandoc.Span({pandoc.Str("Chapter " .. chapter_count)},
                  {class = "chapter-label"}),
      pandoc.Space(),
    })
    new_content:extend(h.content)
    h.content = new_content
  end

  return h
end
