-- _common.lua - shared helpers for parts.lua (print) and epub-parts.lua (EPUB).
--
-- Both filters consume the same per-heading classes (.new-page, .unnumbered);
-- this module is the single source of truth for that stripping logic so the
-- two pipelines can't drift.

local M = {}

-- Remove `name` from h.classes if present and return whether it was there.
-- Used to consume opt-in class signals (.new-page, .unnumbered) without
-- letting them leak into the downstream AST.
function M.pop_class(h, name)
  for i, c in ipairs(h.classes) do
    if c == name then
      h.classes:remove(i)
      return true
    end
  end
  return false
end

return M
