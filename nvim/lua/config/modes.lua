-- Extra modes on top of Vim's own (normal/insert/visual): while one is on,
-- single keys do that mode's actions instead of <leader> combos.
--
--   <leader>m        pick a mode
--   its own key      enter it (press again to leave), e.g. <leader>d for debug
--   <Esc> or q       leave
--
-- Motions (hjkl, w, gg, /, ...) keep working; a mode only borrows the keys it
-- lists and gives them back on exit. Modes are defined next to their plugin:
--
--   require("config.modes").define("debug", {
--     key = "<leader>d", desc = "...", -- color: config.palette[<mode name>]
--     keys = { { "c", fn_or_rhs, "Continue", mode = { "n", "x" } }, ... },
--     on_enter = fn, on_exit = fn, -- optional
--   })
local M = {}

local defs, order = {}, {}
local active, saved, hint_win = nil, {}, nil

---Name of the active mode, or nil.
function M.active()
  return active and active.name or nil
end

---Palette color of the active mode, or nil.
function M.color()
  return active and require("config.palette")[active.name] or nil
end

local function notify_change()
  vim.api.nvim_exec_autocmds("User", { pattern = "ModeLayerChanged", modeline = false })
  vim.cmd.redrawstatus()
end

-- the global mapping a mode key replaces (buffer-local maps are left alone)
local function save(mode, lhs)
  local lhs_norm = vim.keycode(lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if vim.keycode(m.lhs) == lhs_norm then
      table.insert(saved, { mode = mode, lhs = lhs, map = m })
      return
    end
  end
  table.insert(saved, { mode = mode, lhs = lhs })
end

local function restore()
  for i = #saved, 1, -1 do
    local s = saved[i]
    pcall(vim.keymap.del, s.mode, s.lhs)
    if s.map then
      vim.fn.mapset(s.map)
    end
  end
  saved = {}
end

-- cheat-sheet in the bottom-right corner while a mode is on
local function close_hint()
  if hint_win and vim.api.nvim_win_is_valid(hint_win) then
    vim.api.nvim_win_close(hint_win, true)
  end
  hint_win = nil
end

local function open_hint()
  close_hint()
  local def = active.def
  local items, seen = {}, {}
  for _, k in ipairs(def.keys) do
    if not seen[k[1]] then -- a key with normal + visual variants is listed once
      seen[k[1]] = true
      table.insert(items, { k[1], k[3] })
    end
  end
  table.insert(items, { "q", "leave" })
  local key_w, desc_w = 0, 0
  for _, it in ipairs(items) do
    key_w = math.max(key_w, vim.fn.strdisplaywidth(it[1]))
    desc_w = math.max(desc_w, vim.fn.strdisplaywidth(it[2]))
  end
  local rows = math.ceil(#items / 2)
  local lines, marks = {}, {}
  for r = 1, rows do
    local line = ""
    for c = 0, 1 do
      local it = items[r + c * rows]
      if it then
        local col = #line
        line = line .. " " .. it[1] .. string.rep(" ", key_w - vim.fn.strdisplaywidth(it[1])) .. "  " .. it[2]
        table.insert(marks, { r - 1, col + 1, col + 1 + #it[1] })
        if c == 0 then
          line = line .. string.rep(" ", desc_w - vim.fn.strdisplaywidth(it[2])) .. "  "
        end
      end
    end
    table.insert(lines, line .. " ")
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns = vim.api.nvim_create_namespace("modes_hint")
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = "ModeHintKey" })
  end
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  hint_win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    anchor = "SE",
    row = vim.o.lines - vim.o.cmdheight - 1,
    col = vim.o.columns,
    width = width,
    height = #lines,
    style = "minimal",
    border = "single",
    title = " " .. active.name:upper() .. " ",
    title_pos = "center",
    focusable = false,
    noautocmd = true,
    zindex = 40, -- under pickers and other floats
  })
  vim.wo[hint_win].winhighlight = "FloatBorder:ModeHintBorder,FloatTitle:ModeHintBorder"
end

local function set_colors()
  local color = M.color()
  if not color then
    return
  end
  vim.api.nvim_set_hl(0, "ModeHintKey", { fg = color, bold = true })
  vim.api.nvim_set_hl(0, "ModeHintBorder", { fg = color })
end

function M.exit()
  if not active then
    return
  end
  local def = active.def
  restore()
  close_hint()
  active = nil
  if def.on_exit then
    def.on_exit()
  end
  notify_change()
end

---@param name string
---@param opts? { auto?: boolean } auto: entered by an event (e.g. a debug session starting)
function M.enter(name, opts)
  local def = defs[name]
  if not def then
    return vim.notify("no mode named " .. name, vim.log.levels.ERROR)
  end
  if active and active.name == name then
    return
  end
  M.exit()
  active = { name = name, def = def, auto = opts and opts.auto }
  for _, k in ipairs(def.keys) do
    for _, mode in ipairs(type(k.mode) == "table" and k.mode or { k.mode or "n" }) do
      save(mode, k[1])
      -- a ":Cmd " prompt left open for typing must not be silent, or the typing is hidden
      local prompt = type(k[2]) == "string" and k[2]:sub(1, 1) == ":" and not k[2]:match("<CR>$")
      vim.keymap.set(mode, k[1], k[2], { desc = name .. ": " .. k[3], nowait = true, silent = not prompt })
    end
  end
  for _, lhs in ipairs({ "<Esc>", "q" }) do
    save("n", lhs)
    vim.keymap.set("n", lhs, M.exit, { desc = "Leave " .. name .. " mode", nowait = true })
  end
  set_colors()
  open_hint()
  if def.on_enter then
    def.on_enter()
  end
  notify_change()
end

---Leave `name` if it is active and was entered automatically.
function M.exit_auto(name)
  if active and active.name == name and active.auto then
    M.exit()
  end
end

function M.toggle(name)
  if active and active.name == name then
    M.exit()
  else
    M.enter(name)
  end
end

function M.define(name, def)
  if not defs[name] then
    table.insert(order, name)
  end
  defs[name] = def
  if def.key then
    vim.keymap.set("n", def.key, function()
      M.toggle(name)
    end, { desc = name:sub(1, 1):upper() .. name:sub(2) .. " mode" })
  end
end

function M.pick()
  -- one-key modes (<leader>d) first, then the <leader>o tool modes
  local items = vim.deepcopy(order)
  table.sort(items, function(a, b)
    local ka, kb = #(defs[a].key or ""), #(defs[b].key or "")
    return ka ~= kb and ka < kb or (ka == kb and a < b)
  end)
  vim.ui.select(items, {
    prompt = "Mode",
    format_item = function(name)
      local def = defs[name]
      local mark = (active and active.name == name) and "● " or "  "
      return ("%s%-8s %-12s %s"):format(mark, name, def.key and def.key:gsub("<leader>", "␣") or "", def.desc or "")
    end,
  }, function(name)
    if name then
      M.enter(name)
    end
  end)
end

vim.keymap.set("n", "<leader>m", M.pick, { desc = "Pick a mode" })
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    if active then
      open_hint()
    end
  end,
})
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_colors })

return M
