-- tracked.lua - pandoc filter for auto-numbered, cross-referenced, indexed
-- "tracked items": exercises, figures, charts, tables, or any kind the book
-- registers in book_metadata.yaml's `tracked:` map.
--
-- Author-facing tokens (kinds must be registered; the filter is handed the
-- registry via BF_TRACKED so it never grabs a random `{word:word}` from prose):
--
--   {exercise:pushups:def}                anchor -> "Exercise 3", numbered here
--   {exercise:pushups Push-ups to failure} anchor with a title for the index
--   {exercise:pushups}                    reference -> "Exercise 3"
--   {index:exercise}                       the list of all exercises (own line)
--
-- Grammar. Colons delimit the structured fields; a SPACE after the id begins the
-- free-text title:
--   kind:id            -> reference
--   kind:id:def        -> definition, no title
--   kind:id <title>    -> definition, title = <title>
--   kind:id:def <title>-> definition with title (both markers, harmless)
--
-- Two output modes, chosen by BF_TRACKED_MODE:
--   "print"  (PDF via typst): emit raw typst calls #tdef/#xref/#tindex, and let
--            book.typ do the numbering, linking, and (print) page resolution.
--   "reflow" (EPUB / HTML): there is no typst, so this filter numbers items
--            itself (per kind, in appearance order -- the same order typst
--            produces, so the numbers match) and emits pandoc-native elements:
--            a Span anchor, a Link reference, and a linked list for the index.
--            Reflowable formats have no fixed pages, so the list carries no page
--            numbers -- the links are the way there.
--
-- Only registered kinds are treated as tokens; a bare `{kind:id}` whose kind is
-- unregistered is left exactly as written (it may be ordinary prose). Hard build
-- errors: an unregistered kind in `{index:kind}`, a duplicate definition, and a
-- reference to an id never defined anywhere in the book.

local stringify = pandoc.utils.stringify

-- Registry from bf: "kind=Label;kind=Label". `kinds` gates what counts as a
-- token; `labels` is the printed word (used in reflow; print reads it from
-- typst's meta.tracked instead). Empty when the book tracks nothing.
local kinds, labels = {}, {}
for pair in (os.getenv("BF_TRACKED") or ""):gmatch("[^;]+") do
  local k, v = pair:match("^([^=]+)=(.*)$")
  if k then kinds[k] = true; labels[k] = v end
end
local mode = os.getenv("BF_TRACKED_MODE") or "print"

-- Gathered across the whole document (bf feeds pandoc every chapter at once).
local defined = {}       -- key -> true
local referenced = {}    -- key -> true
local counts = {}        -- kind -> running count (reflow numbering)
local numbers = {}       -- key -> assigned number (reflow)
local index_entries = {} -- kind -> ordered list of {id, n, title} (reflow)

local function die(msg)
  io.stderr:write("tracked.lua: " .. msg .. "\n")
  os.exit(1)
end

local function tstr(s)  -- Typst string literal (print mode)
  return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function label_word(kind)
  return labels[kind] or (kind:gsub("^%l", string.upper))
end

local function anchor(kind, id)
  return "trk-" .. kind .. "-" .. id
end

-- Parse the text between `{` and `}` into a token, or nil if it isn't token
-- shaped (leave it literal). The token is returned even when its kind is NOT
-- registered, with `registered` set accordingly, so callers can distinguish
-- ordinary prose (leave alone) from a distinctively marked token whose kind was
-- forgotten or mistyped (surface it). `explicit` marks the `:def` keyword, the
-- one anchor form that can only be tracked markup. `index:` is handled at block
-- level (Para), so `index` is never a registered kind and falls through here.
local function parse_token(inner)
  local kind, id, tail = inner:match("^([%l%d%-]+):([%w_%-.]+)(.*)$")
  if not kind then return nil end
  local reg = kinds[kind] == true
  if tail == "" then
    return { role = "ref", kind = kind, id = id, registered = reg, explicit = false }
  end
  local after_def = tail:match("^:def$") and "" or tail:match("^:def%s+(.*)$")
  if after_def ~= nil then
    return { role = "def", kind = kind, id = id, title = trim(after_def),
             registered = reg, explicit = true }
  elseif tail:match("^%s") then
    return { role = "def", kind = kind, id = id, title = trim(tail),
             registered = reg, explicit = false }
  end
  return nil  -- kind:id shape but an unrecognised tail (e.g. ":foo")
end

-- Coalesce each maximal run of Str/Space/SoftBreak in an inline list into one
-- text buffer (a token's title may contain spaces, so it spans several inlines),
-- calling on_run(text) -> replacement inlines. Any other inline (emphasis, code,
-- links) flushes the run and passes through untouched, so a token can't sit
-- inside markup but everything else is preserved.
local function walk_runs(inlines, on_run)
  local out = pandoc.List()
  local run = nil
  local function flush()
    if run ~= nil then out:extend(on_run(run)); run = nil end
  end
  for _, el in ipairs(inlines) do
    if el.t == "Str" then
      run = (run or "") .. el.text
    elseif el.t == "Space" or el.t == "SoftBreak" then
      run = (run or "") .. " "
    else
      flush(); out:insert(el)
    end
  end
  flush()
  return out
end

local function has_brace(inlines)
  for _, el in ipairs(inlines) do
    if el.t == "Str" and el.text:find("{", 1, true) then return true end
  end
  return false
end

-- Split a text run at tokens, calling handle(tok, key) for each recognised token
-- (returning the inlines to substitute) and wrapping the rest as Str.
local function split_tokens(text, handle)
  local out = pandoc.List()
  local pos, len = 1, #text
  while pos <= len do
    local open = text:find("{", pos, true)
    if not open then out:insert(pandoc.Str(text:sub(pos))); break end
    if open > pos then out:insert(pandoc.Str(text:sub(pos, open - 1))) end
    local close = text:find("}", open + 1, true)
    if not close then out:insert(pandoc.Str(text:sub(open))); break end
    local inner = text:sub(open + 1, close - 1)
    local tok = parse_token(inner)
    local repl
    if tok and tok.registered then
      repl = handle(tok, tok.kind .. ":" .. tok.id)
    elseif tok and tok.explicit then
      -- `{kind:id:def}` can only be tracked markup, so an unregistered kind is a
      -- forgotten registry or a typo, not prose -- surface it instead of printing
      -- the raw braces. Bare `{kind:id}` and space-titled forms stay lenient.
      die("tracked definition {" .. inner .. "} uses kind '" .. tok.kind ..
          "', which is not registered in book_metadata.yaml `tracked:`. Add it "
          .. "there (or remove ':def' if this isn't a tracked item).")
    end
    if repl then out:extend(repl) else out:insert(pandoc.Str(text:sub(open, close))) end
    pos = close + 1
  end
  return out
end

-- "Exercise #3" as inlines (reflow). The number is prefixed with "#" to match
-- the print side's tracked-label.
local function num_inlines(kind, n)
  return pandoc.List({ pandoc.Str(label_word(kind)), pandoc.Space(), pandoc.Str("#" .. tostring(n)) })
end

-- ---- print mode: tokens -> raw typst -------------------------------------

local function emit_print(tok, key)
  if tok.role == "ref" then
    referenced[key] = true
    return { pandoc.RawInline("typst", string.format("#xref(%s, %s)",
      tstr(tok.kind), tstr(tok.id))) }
  end
  if defined[key] then
    die("duplicate definition {" .. key .. ":def} -- each id must be defined once")
  end
  defined[key] = true
  if tok.title and tok.title ~= "" then
    return { pandoc.RawInline("typst", string.format("#tdef(%s, %s, title: %s)",
      tstr(tok.kind), tstr(tok.id), tstr(tok.title))) }
  end
  return { pandoc.RawInline("typst", string.format("#tdef(%s, %s)",
    tstr(tok.kind), tstr(tok.id))) }
end

-- ---- reflow mode: tokens -> pandoc Span / Link ----------------------------

local function scan_token(tok, key)  -- pass 1: number defs, record refs
  if tok.role == "ref" then
    referenced[key] = true
  else
    if numbers[key] then
      die("duplicate definition {" .. key .. ":def} -- each id must be defined once")
    end
    counts[tok.kind] = (counts[tok.kind] or 0) + 1
    numbers[key] = counts[tok.kind]
    index_entries[tok.kind] = index_entries[tok.kind] or pandoc.List()
    index_entries[tok.kind]:insert({ id = tok.id, n = numbers[key], title = tok.title })
  end
  return nil  -- pass 1 never substitutes
end

local function emit_reflow(tok, key)  -- pass 2
  local n = numbers[key]
  if tok.role == "ref" then
    return { pandoc.Link(num_inlines(tok.kind, n), "#" .. anchor(tok.kind, tok.id)) }
  end
  return { pandoc.Span(num_inlines(tok.kind, n),
    pandoc.Attr(anchor(tok.kind, tok.id), { "tracked-def" }, {})) }
end

-- ---- shared block handling: {index:kind} ----------------------------------

local function index_kind(para)
  return stringify(para):match("^%s*{index:([%l%d%-]+)}%s*$")
end

local function check_index_kind(kind)
  if not kinds[kind] then
    die("unknown tracked kind in {index:" .. kind ..
        "}; add '" .. kind .. "' to book_metadata.yaml `tracked:`")
  end
end

local function reflow_index(kind)
  local items = pandoc.List()
  for _, e in ipairs(index_entries[kind] or {}) do
    local text = num_inlines(kind, e.n)
    -- Fall back to the author's id when there's no title, so an entry is never a
    -- bare number ("Exercise 1 · pushups" rather than "Exercise 1").
    local desc = (e.title and e.title ~= "") and e.title or e.id
    text:extend({ pandoc.Space(), pandoc.Str("·"), pandoc.Space(), pandoc.Str(desc) })
    items:insert({ pandoc.Plain(pandoc.Inlines(
      { pandoc.Link(text, "#" .. anchor(kind, e.id)) })) })
  end
  return pandoc.Div(pandoc.Blocks({ pandoc.BulletList(items) }),
    pandoc.Attr("", { "tracked-index" }, {}))
end

-- ---- validation -----------------------------------------------------------

local function validate_danglers()
  local missing = {}
  for key in pairs(referenced) do
    if not defined[key] and not numbers[key] then missing[#missing + 1] = key end
  end
  if #missing > 0 then
    table.sort(missing)
    die("reference(s) to undefined tracked item(s): {" ..
        table.concat(missing, "}, {") .. "}. Define each at its location with "
        .. "{kind:id:def} (optionally followed by a space and a title).")
  end
end

-- ---- orchestration --------------------------------------------------------

function Pandoc(doc)
  -- Note: we do NOT bail out when the registry is empty. A book with no
  -- `tracked:` block should still be told if it uses a distinctively marked
  -- token (`{kind:id:def}` or `{index:kind}`) -- otherwise a forgotten registry
  -- silently prints raw braces. The has_brace guards keep brace-free text
  -- untouched, so a book that uses no tokens at all is effectively a no-op.
  if mode == "reflow" then
    -- Pass 1: number definitions and collect references (document order). The
    -- walk_runs output is discarded -- pass 1 only has side effects (numbering).
    doc:walk({ Inlines = function(ils)
      if has_brace(ils) then
        walk_runs(ils, function(t) split_tokens(t, scan_token); return pandoc.List() end)
      end
      return nil
    end })
    validate_danglers()
    -- Pass 2: substitute references/anchors, and expand each {index:kind}.
    return doc:walk({
      Inlines = function(ils)
        if not has_brace(ils) then return nil end
        return walk_runs(ils, function(t) return split_tokens(t, emit_reflow) end)
      end,
      Para = function(para)
        local kind = index_kind(para)
        if not kind then return nil end
        check_index_kind(kind)
        return reflow_index(kind)
      end,
    })
  end

  -- print mode
  local out = doc:walk({
    Inlines = function(ils)
      if not has_brace(ils) then return nil end
      return walk_runs(ils, function(t) return split_tokens(t, emit_print) end)
    end,
    Para = function(para)
      local kind = index_kind(para)
      if not kind then return nil end
      check_index_kind(kind)
      return pandoc.RawBlock("typst", string.format("#tindex(%s)\n", tstr(kind)))
    end,
  })
  validate_danglers()
  return out
end
