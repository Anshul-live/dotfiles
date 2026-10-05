-- blink.cmp source for *.hurl files (there is no Hurl language server). Completes by context:
--   line start        methods, HTTP <status>, headers, [Sections]
--   [Asserts]         queries (jsonpath, status, header, ...), then predicates (==, contains, exists, ...)
--   [Captures]        name: <query>
--   [Options]         per-request options
--   {{                variables: vars.env-style files next to the .hurl file / in cwd, and
--                     names captured earlier in this file
--   header values     Content-Type / Accept / Authorization values
local M = {}

local Kind = require("blink.cmp.types").CompletionItemKind
local Snippet = vim.lsp.protocol.InsertTextFormat.Snippet

local methods = { "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS" }

local sections = {
  Captures = "save values from the response as {{variables}}",
  Asserts = "checks on the response (status, json fields, timing)",
  QueryStringParams = "?key=value pairs, one per line",
  FormParams = "application/x-www-form-urlencoded body, key: value",
  MultipartFormData = "multipart body; files as key: file,path;",
  Cookies = "request cookies, name: value",
  BasicAuth = "user: password",
  Options = "per-request options (insecure, location, retry, ...)",
}

local headers = {
  ["Content-Type"] = { "application/json", "application/x-www-form-urlencoded", "multipart/form-data", "text/plain" },
  ["Accept"] = { "application/json", "*/*", "text/html" },
  ["Authorization"] = { "Bearer {{token}}", "Basic {{credentials}}" },
  ["User-Agent"] = { "hurl" },
  ["Cache-Control"] = { "no-cache" },
  ["Cookie"] = {},
  ["X-Request-Id"] = {},
}

-- query = snippet for its argument (if any)
local queries = {
  status = "",
  url = "",
  header = ' "${1:Content-Type}"',
  cookie = ' "${1:name}"',
  body = "",
  bytes = "",
  jsonpath = ' "\\$.${1:field}"',
  xpath = ' "${1://title}"',
  regex = ' "${1:pattern}"',
  variable = ' "${1:name}"',
  duration = "",
  sha256 = "",
  md5 = "",
  certificate = ' "${1:Subject}"',
}

local predicates = {
  ["=="] = "equals",
  ["!="] = "not equal",
  [">"] = "greater than",
  [">="] = "greater or equal",
  ["<"] = "less than",
  ["<="] = "less or equal",
  contains = "string / list contains",
  startsWith = "string starts with",
  endsWith = "string ends with",
  matches = "regex match",
  exists = "field is present",
  isString = "type check",
  isInteger = "type check",
  isFloat = "type check",
  isBoolean = "type check",
  isCollection = "list or object",
  isEmpty = "empty string / list",
  isIsoDate = "ISO 8601 date",
  includes = "list includes value",
  count = "filter: number of items (then a predicate)",
}

local options = {
  insecure = "true",
  location = "true",
  ["max-redirs"] = "5",
  retry = "3",
  ["retry-interval"] = "500",
  delay = "1000",
  variable = "name=value",
  verbose = "true",
  compressed = "true",
  ["http1.1"] = "true",
  skip = "true",
}

local function item(label, opts)
  return vim.tbl_extend("force", { label = label, kind = Kind.Keyword }, opts or {})
end

-- the [Section] the cursor is in, or nil when in the request/response head
-- (a blank line right above the cursor counts as the start of a new request)
local function current_section(buf, row)
  if row > 1 and (vim.api.nvim_buf_get_lines(buf, row - 2, row - 1, false)[1] or ""):match("^%s*$") then
    return nil
  end
  for l = row - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1] or ""
    local s = line:match("^%s*%[(%a+)%]")
    if s then
      return s
    end
    if line:match("^%s*%u+%s+%S") or line:match("^%s*HTTP") then
      return nil
    end
  end
end

-- variable names: KEY=value lines in env files near the .hurl file, plus captures/option variables
local function variables(buf)
  local names, seen = {}, {}
  local function add(name, detail)
    if name and not seen[name] then
      seen[name] = true
      table.insert(names, { name = name, detail = detail })
    end
  end
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  local files = {}
  for _, d in ipairs({ dir, vim.fn.getcwd() }) do
    vim.list_extend(files, vim.fn.glob(d .. "/*.env", false, true))
    vim.list_extend(files, vim.fn.glob(d .. "/.env", false, true))
  end
  for _, f in ipairs(files) do
    for _, line in ipairs(vim.fn.readfile(f)) do
      local k, v = line:match("^%s*([%w_.-]+)%s*=%s*(.-)%s*$")
      add(k, k and (vim.fs.basename(f) .. ": " .. v))
    end
  end
  local section
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    section = line:match("^%s*%[(%a+)%]") or (line:match("^%s*%u+%s+%S") and "") or section
    if section == "Captures" then
      add(line:match("^%s*([%w_-]+)%s*:"), "captured in this file")
    elseif section == "Options" then
      add(line:match("^%s*variable%s*:%s*([%w_-]+)="), "set in [Options]")
    end
  end
  return names
end

-- Open the menu with just these items after `[`, `{{`, `Header: ` or `query `: autopairs
-- inserts brackets itself (so blink never sees them typed) and blink ignores spaces as triggers.
function M.attach(buf)
  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = function()
      local col = vim.fn.col(".") - 1
      local line = vim.api.nvim_get_current_line()
      local last = line:sub(col, col)
      if not (last == "[" or last == "{" or last == " " or last == ":") then
        return
      end
      local ctx = { line = line, cursor = { vim.fn.line("."), col }, bufnr = buf }
      M.get_completions(M, ctx, function(r)
        if #r.items > 0 then
          require("blink.cmp").show({ providers = { "hurl" } })
        end
      end)
    end,
  })
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return vim.bo.filetype == "hurl"
end

function M:get_trigger_characters()
  return { "{", "[", " ", ":" }
end

function M:get_completions(ctx, callback)
  local before = ctx.line:sub(1, ctx.cursor[2])
  local after = ctx.line:sub(ctx.cursor[2] + 1)
  local items = {}
  local function done()
    callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  end

  -- {{variable}}
  if before:match("{{[%w_.-]*$") then
    local close = after:match("^}}") and "" or "}}"
    for _, v in ipairs(variables(ctx.bufnr)) do
      table.insert(items, item(v.name, { kind = Kind.Variable, insertText = v.name .. close, detail = v.detail }))
    end
    return done()
  end

  -- [Section]
  if before:match("^%s*%[%a*$") then
    for name, doc in pairs(sections) do
      local close = after:match("^%]") and "" or "]" -- autopairs may have added it
      table.insert(items, item(name, { kind = Kind.Module, insertText = name .. close, detail = doc }))
    end
    return done()
  end

  -- header values
  local hname = before:match("^%s*([%w-]+):%s*[^%s]*$")
  if hname and headers[hname] then
    for _, v in ipairs(headers[hname]) do
      table.insert(items, item(v, { kind = Kind.Value }))
    end
    return done()
  end

  local section = current_section(ctx.bufnr, ctx.cursor[1])

  -- [Asserts] / [Captures]: query, then predicate
  if section == "Asserts" or section == "Captures" then
    local q = before:match("^%s*([%a]+)") -- first word on the line
    if section == "Captures" then
      q = before:match("^%s*[%w_-]+%s*:%s*(%a+)")
    end
    -- query (and its "argument") typed, no predicate yet: `status `, `jsonpath "$.id" `
    local rest = q and queries[q] and before:match("^%s*" .. q .. "(.*)$")
    local query_typed = rest and (rest:match("^%s+%S*$") or rest:match('^%s+"[^"]*"%s+%S*$'))
    if section == "Asserts" and query_typed then
      for p, doc in pairs(predicates) do
        local first = ({ ["=="] = "0", exists = "1", contains = "2" })[p] or "9" -- most used on top
        table.insert(items, item(p, { kind = Kind.Operator, detail = doc, sortText = first .. p }))
      end
      return done()
    end
    if section == "Asserts" and before:match("^%s*%a*$") or section == "Captures" and before:match(":%s*%a*$") then
      for name, arg in pairs(queries) do
        table.insert(items, item(name, {
          kind = Kind.Function,
          insertText = name .. arg .. (section == "Asserts" and " $0" or ""),
          insertTextFormat = Snippet,
          detail = "query",
        }))
      end
      return done()
    end
    if section == "Captures" and before:match("^%s*[%w_-]*$") then
      table.insert(items, item("capture", {
        kind = Kind.Snippet,
        insertText = '${1:name}: jsonpath "\\$.${2:field}"',
        insertTextFormat = Snippet,
        detail = "name: jsonpath \"$.field\"",
      }))
    end
  end

  -- [Options]
  if section == "Options" and before:match("^%s*[%w.-]*$") then
    for name, example in pairs(options) do
      table.insert(items, item(name, { kind = Kind.Property, insertText = name .. ": ${1:" .. example .. "}", insertTextFormat = Snippet }))
    end
    return done()
  end

  -- line start in the request head: methods, status line, headers, sections
  if not section and before:match("^%s*[%a-]*$") then
    for _, m in ipairs(methods) do
      table.insert(items, item(m, {
        kind = Kind.Keyword,
        insertText = m .. " ${1:{{base_url\\}\\}}/${2:path}",
        insertTextFormat = Snippet,
        detail = "request line",
      }))
    end
    table.insert(items, item("HTTP", { insertText = "HTTP ${1:200}", insertTextFormat = Snippet, detail = "expected status" }))
    for h in pairs(headers) do
      table.insert(items, item(h, { kind = Kind.Field, insertText = h .. ": ", detail = "header" }))
    end
    for name, doc in pairs(sections) do
      table.insert(items, item("[" .. name .. "]", { kind = Kind.Module, filterText = name, detail = doc }))
    end
  end
  done()
end

return M
