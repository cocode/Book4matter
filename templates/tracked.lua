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

-- Pandoc's Markdown AST has no source line positions. Find the offending
-- markup in the original inputs on failure, rather than reporting print's
-- rewritten scratch files. If text occurs more than once, list every candidate
-- instead of guessing which source occurrence was responsible.
local diagnostic_token = nil
local function source_locations(token)
  local paths = PANDOC_STATE.input_files
  local originals = os.getenv("BF_TRACKED_SOURCES")
  if originals then paths = pandoc.json.decode(originals) end
  local pattern = token:gsub("([^%w%s])", "%%%1"):gsub("%s+", "%%s+")
  local locations = {}
  for _, path in ipairs(paths) do
    if path ~= "-" then
      local file = io.open(path, "r")
      if file then
        local source = file:read("*a")
        file:close()
        local pos = 1
        while true do
          local a, b = source:find(pattern, pos)
          if not a then break end
          local _, line = source:sub(1, a - 1):gsub("\n", "")
          locations[#locations + 1] = path .. ":" .. (line + 1)
          pos = b + 1
        end
      end
    end
  end
  return locations
end

local function die(msg)
  io.stderr:write("tracked.lua: " .. msg .. "\n")
  if diagnostic_token then
    local locations = source_locations(diagnostic_token)
    if #locations == 1 then
      io.stderr:write("  at " .. locations[1] .. "\n")
    elseif #locations > 1 then
      io.stderr:write("  matching source locations (markup occurs more than once):\n")
      for _, loc in ipairs(locations) do io.stderr:write("    " .. loc .. "\n") end
    else
      io.stderr:write("  source location unavailable (input may be stdin or transformed markup)\n")
    end
    io.stderr:write("  offending markup: " .. diagnostic_token .. "\n")
  end
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
local function walk_runs(inlines, on_run, on_other)
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
      flush(); out:insert(on_other and on_other(el) or el)
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
    diagnostic_token = "{" .. inner .. "}"
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
    diagnostic_token = nil
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

-- Terms share this filter and index placement with numbered tracked items.
-- [[term]] is an unnumbered definition; repeated definitions are grouped.
local terms, term_order = {}, {}
local term_aliases = {}
local term_counts = {}

-- Pandoc's implicit header references can parse [[Frame]] as "[", a Link
-- to a heading named Frame, and "]". Recover the term before scanning text
-- runs; retain ordinary internal links and all surrounding text unchanged.
local function recover_terms(ils)
  local out = pandoc.List()
  local i = 1
  while i <= #ils do
    local a, b, c = ils[i], ils[i + 1], ils[i + 2]
    if a and b and c and a.t == "Str" and b.t == "Link" and c.t == "Str"
        and a.text:sub(-1) == "[" and c.text:sub(1, 1) == "]"
        and b.target:sub(1, 1) == "#" then
      out:insert(pandoc.Str(a.text:sub(1, -2) .. "[[" .. stringify(b.content)
        .. "]]" .. c.text:sub(2)))
      i = i + 3
    else
      out:insert(a)
      i = i + 1
    end
  end
  return out
end

local function term_inlines(text)
  local out = pandoc.List()
  local pos = 1
  while true do
    local a, b, raw = text:find("%[%[([^%[%]]-)%]%]", pos)
    if not a then
      if pos <= #text then out:insert(pandoc.Str(text:sub(pos))) end
      break
    end
    if a > pos then out:insert(pandoc.Str(text:sub(pos, a - 1))) end
    diagnostic_token = "[[" .. raw .. "]]"
    local display, title = raw:match("^([^|]*)|([^|]*)$")
    if not display then
      if raw:find("|", 1, true) then die("term definitions allow only one | separator") end
      display, title = raw, raw
    end
    local aliases = {}
    if raw:find("|", 1, true) and title:find(";", 1, true) then
      local parts = {}
      for part in (title .. ";"):gmatch("(.-);") do
        part = trim(part)
        if part == "" then die("index aliases require nonempty names after each ;") end
        parts[#parts + 1] = part
      end
      title = parts[1]
      for i = 2, #parts do
        if parts[i]:find(">", 1, true) then die("see aliases must be top-level names, without >") end
        aliases[#aliases + 1] = parts[i]
      end
    end
    display, title = trim(display), trim(title)
    if display == "" or title == "" then
      die("term definitions require nonempty display text and index entry")
    end
    if display:find(":", 1, true) then
      die("term references (:ref) are not supported; use [[term]] or [[text|index entry]]")
    end
    local parent, child = title:match("^([^>]*)>([^>]*)$")
    if title:find(">", 1, true) then
      if not parent or trim(parent) == "" or trim(child) == "" then
        die("subentries require nonempty parent and child, with exactly one > separator")
      end
      parent, title = trim(parent), trim(child)
    end
    local root_title = parent or title
    local root_key = pandoc.text.lower(root_title)
    if not terms[root_key] then
      terms[root_key] = {title = root_title, anchors = {}, children = {}, implicit = parent ~= nil}
      term_order[#term_order + 1] = root_key
    elseif not parent and terms[root_key].implicit then
      terms[root_key].title = title
      terms[root_key].implicit = false
    end
    local key = root_key
    if parent then
      key = root_key .. ">" .. pandoc.text.lower(title)
      if not terms[key] then
        terms[key] = {title = title, anchors = {}}
        table.insert(terms[root_key].children, key)
      end
    end
    for _, alias in ipairs(aliases) do
      local alias_key = pandoc.text.lower(alias)
      if alias_key == key then die("an index see alias cannot refer to itself: " .. alias) end
      if term_aliases[alias_key] and term_aliases[alias_key].target ~= key then
        die("index see alias '" .. alias .. "' refers to more than one entry")
      end
      if not term_aliases[alias_key] then
        term_aliases[alias_key] = {title = alias, target = key, token = diagnostic_token,
          target_title = parent and (parent .. ", " .. title) or title}
      end
    end
    local slug = key:gsub("[^%w\128-\255]+", "-"):gsub("^-", ""):gsub("-$", "")
    if slug == "" then slug = "term" end
    term_counts[slug] = (term_counts[slug] or 0) + 1
    local id = "idx-" .. slug .. "-" .. term_counts[slug]
    table.insert(terms[key].anchors, id)
    if mode == "reflow" then
      out:insert(pandoc.Span({pandoc.Str(display)}, pandoc.Attr(id)))
    else
      local args = string.format("%s, %s, %s", tstr(key), tstr(title), tstr(id))
      if display ~= title then args = args .. ", display: " .. tstr(display) end
      if parent then args = args .. ", parent: " .. tstr(parent) end
      if #aliases > 0 then
        local values = {}
        for _, alias in ipairs(aliases) do values[#values + 1] = tstr(alias) end
        args = args .. ", aliases: (" .. table.concat(values, ", ") .. ",)"
      end
      out:insert(pandoc.RawInline("typst", "#termdef(" .. args .. ")"))
    end
    diagnostic_token = nil
    pos = b + 1
  end
  return out
end

local function term_row(entry, child)
  local label = pandoc.List()
  if child then label:extend({pandoc.Str("↳"), pandoc.Space()}) end
  if #entry.anchors == 0 then
    label:insert(pandoc.Str(entry.title))
  else
    label:insert(pandoc.Link({pandoc.Str(entry.title)}, "#" .. entry.anchors[1]))
  end
  local row = pandoc.List({pandoc.Span(label, pandoc.Attr("", {"index-label"}))})
  if #entry.anchors > 0 then
    local links = pandoc.List()
    for i, id in ipairs(entry.anchors) do
      if i > 1 then links:insert(pandoc.Str(", ")) end
      links:insert(pandoc.Link({pandoc.Str(tostring(i))}, "#" .. id))
    end
    row:insert(pandoc.Span({}, pandoc.Attr("", {"index-leader"}, {["aria-hidden"] = "true"})))
    row:insert(pandoc.Span(links, pandoc.Attr("", {"index-locations"})))
  end
  return pandoc.Div({pandoc.Plain(row)}, pandoc.Attr("", {"index-row"}))
end

local function term_index()
  local items = pandoc.List()
  local order = {}
  for _, key in ipairs(term_order) do order[#order + 1] = key end
  for key in pairs(term_aliases) do order[#order + 1] = key end
  table.sort(order)
  for _, key in ipairs(order) do
    local alias = term_aliases[key]
    if alias then
      local text = {pandoc.Str(alias.title .. "."), pandoc.Space(),
        pandoc.Emph({pandoc.Str("see")}), pandoc.Space(),
        pandoc.Link({pandoc.Str(alias.target_title)}, "#" .. terms[alias.target].anchors[1])}
      items:insert({pandoc.Div({pandoc.Plain(text)}, pandoc.Attr("", {"index-see"}))})
    else
      local entry = terms[key]
      local blocks = pandoc.Blocks({term_row(entry, false)})
      if #entry.children > 0 then
        local children = pandoc.List()
        table.sort(entry.children)
        for _, child_key in ipairs(entry.children) do
          children:insert({term_row(terms[child_key], true)})
        end
        blocks:insert(pandoc.BulletList(children))
      end
      items:insert(blocks)
    end
  end
  return pandoc.Div({pandoc.BulletList(items)}, pandoc.Attr("", {"term-index"}))
end

-- ---- shared block handling: {index:kind} ----------------------------------

local function index_kind(para)
  return stringify(para):match("^%s*{index:([%l%d%-]+)}%s*$")
end

local function check_index_kind(kind)
  if kind ~= "term" and not kinds[kind] then
    diagnostic_token = "{index:" .. kind .. "}"
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
  -- Collect all definitions before expanding indexes, including front indexes.
  -- Process nested inline content in reading order, rather than Pandoc's
  -- default inside-out order (which would collect links before earlier prose).
  local function collect_terms(ils)
    return walk_runs(recover_terms(ils), term_inlines, function(el)
      return el:walk({ Inlines = collect_terms })
    end)
  end
  doc = doc:walk({ traverse = "topdown", Inlines = collect_terms })
  for key, alias in pairs(term_aliases) do
    if terms[key] then
      diagnostic_token = alias.token
      die("index see alias '" .. alias.title .. "' conflicts with an existing entry")
    end
  end
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
        if kind == "term" then return term_index() end
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
      if kind == "term" then return pandoc.RawBlock("typst", "#termindex()") end
      return pandoc.RawBlock("typst", string.format("#tindex(%s)\n", tstr(kind)))
    end,
  })
  validate_danglers()
  return out
end
