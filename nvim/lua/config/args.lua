-- Program arguments prompt, remembered per project (persists across restarts).
local M = {}

local file = vim.fn.stdpath("data") .. "/program-args.json"

local function load()
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
  end)
  return ok and type(data) == "table" and data or {}
end

---Split a command line like a shell: spaces separate, quotes group, \ escapes.
function M.split(s)
  local args, cur, quote, escaped, has = {}, {}, nil, false, false
  for ch in s:gmatch(".") do
    if escaped then
      table.insert(cur, ch)
      escaped = false
    elseif ch == "\\" and quote ~= "'" then
      escaped = true
    elseif quote then
      if ch == quote then
        quote = nil
      else
        table.insert(cur, ch)
      end
    elseif ch == '"' or ch == "'" then
      quote, has = ch, true
    elseif ch:match("%s") then
      if #cur > 0 or has then
        table.insert(args, table.concat(cur))
        cur, has = {}, false
      end
    else
      table.insert(cur, ch)
    end
  end
  if #cur > 0 or has then
    table.insert(args, table.concat(cur))
  end
  return args
end

---Ask for arguments (prefilled with the last ones for `key`).
---Inside a coroutine (nvim-dap config) it yields; otherwise pass `cb`.
---Returns/calls back with (list, raw_string), or nil when cancelled.
function M.ask(key, cb)
  local saved = load()
  local co = not cb and coroutine.running() or nil
  local function done(raw)
    if raw == nil then
      if cb then
        return cb(nil)
      end
      return coroutine.resume(co, nil)
    end
    saved[key] = raw
    pcall(vim.fn.writefile, { vim.json.encode(saved) }, file)
    if cb then
      return cb(M.split(raw), raw)
    end
    coroutine.resume(co, M.split(raw), raw)
  end
  vim.ui.input({ prompt = "Arguments: ", default = saved[key] or "" }, function(raw)
    vim.schedule(function()
      done(raw)
    end)
  end)
  if co then
    return coroutine.yield()
  end
end

return M
