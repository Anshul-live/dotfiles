-- Winbar "where am I": file › class › function at the cursor, from treesitter
-- (no plugin, no LSP request). Shown only on windows holding a real file.
local M = {}

-- node types that count as a scope, across the languages in lua/lang
local scope_types = {
  function_definition = true, -- c, cpp, python
  function_declaration = true, -- lua, go, js/ts
  function_item = true, -- rust
  method_declaration = true, -- go
  method_definition = true, -- js/ts
  class_specifier = true, -- cpp
  struct_specifier = true, -- c, cpp
  namespace_definition = true, -- cpp
  class_definition = true, -- python
  class_declaration = true, -- js/ts
  interface_declaration = true, -- ts
  type_spec = true, -- go
  impl_item = true, -- rust
  struct_item = true, -- rust
  enum_item = true, -- rust
  trait_item = true, -- rust
  mod_item = true, -- rust
}

-- a scope's name: its `name` field, or (C/C++) the innermost `declarator`, or (Rust impl) its type
local function name_of(node, buf)
  local name = node:field("name")[1]
  if not name then
    local decl = node:field("declarator")[1]
    while decl and decl:field("declarator")[1] do
      decl = decl:field("declarator")[1]
    end
    name = decl or node:field("type")[1]
  end
  return name and vim.treesitter.get_node_text(name, buf):gsub("%s+", " ") or nil
end

local cache = {}

local function scopes(buf, row, col)
  local key = vim.b[buf].changedtick .. ":" .. row
  if cache[buf] and cache[buf].key == key then
    return cache[buf].text
  end
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { row, col }, ignore_injections = false })
  local parts = {}
  while ok and node do
    if scope_types[node:type()] then
      local name = name_of(node, buf)
      if name then
        table.insert(parts, 1, name)
      end
    end
    node = node:parent()
  end
  local text = table.concat(parts, " \u{203a} ")
  cache[buf] = { key = key, text = text }
  return text
end

local function render()
  -- %{% %} in 'winbar' is evaluated with the target window current
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  local where = scopes(buf, cursor[1] - 1, cursor[2])
  local out = " %#WinBarFile#" .. file .. "%*"
  if where ~= "" then
    out = out .. "%#WinBarSep# \u{203a} %*%#WinBar#" .. where .. "%*"
  end
  return out
end

-- an error here would make Neovim clear 'winbar' for good, so never let one escape
function M.render()
  local ok, out = pcall(render)
  return ok and out or ""
end

function M.setup()
  local function colors()
    local p = require("config.palette")
    vim.api.nvim_set_hl(0, "WinBar", { fg = p.dim })
    vim.api.nvim_set_hl(0, "WinBarNC", { fg = p.faint })
    vim.api.nvim_set_hl(0, "WinBarFile", { fg = p.fg })
    vim.api.nvim_set_hl(0, "WinBarSep", { fg = p.faint })
  end
  colors()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = colors })
  -- per window: only real files get a winbar (an empty one would still take a line)
  vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "WinNew" }, {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return -- floats
      end
      local buf = vim.api.nvim_win_get_buf(win)
      local real = vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
      vim.wo[win].winbar = real and "%{%v:lua.require'config.winbar'.render()%}" or ""
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(ev)
      cache[ev.buf] = nil
    end,
  })
end

return M
