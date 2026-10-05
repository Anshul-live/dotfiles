-- Native statusline: only what you might act on, no plugin, no refresh timer.
-- Left:  mode badge (NORMAL/INSERT/..., or an extra mode like DEBUG), file (+ modified dot)
-- Right: macro recording, LSP progress / missing LSP, diagnostics, git changes, pinned files, branch
local M = {}

local function hl(group, text)
  return "%#" .. group .. "#" .. text .. "%*"
end

-- Vim's own modes, keyed by the first letter of mode(); colors are config.palette names
local base_modes = {
  n = { "NORMAL", "normal" },
  i = { "INSERT", "insert" },
  v = { "VISUAL", "visual" },
  V = { "V-LINE", "visual" },
  ["\22"] = { "V-BLOCK", "visual" },
  s = { "SELECT", "visual" },
  S = { "S-LINE", "visual" },
  ["\19"] = { "S-BLOCK", "visual" },
  R = { "REPLACE", "replace" },
  c = { "COMMAND", "command" },
  r = { "PROMPT", "command" },
  ["!"] = { "SHELL", "terminal" },
  t = { "TERMINAL", "terminal" },
}

-- badge highlight per palette color, created on first use (reset on :colorscheme)
local badge_groups = {}
local function badge(text, color)
  local group = "StlMode_" .. color
  if not badge_groups[group] then
    local p = require("config.palette")
    vim.api.nvim_set_hl(0, group, { fg = p.bg, bg = p[color] or p.normal, bold = true })
    badge_groups[group] = true
  end
  return hl(group, " " .. text .. " ")
end

-- extra mode (config/modes.lua) replaces NORMAL; any other Vim mode shows next to it
local function mode_badges()
  local base = base_modes[vim.fn.mode():sub(1, 1)] or base_modes.n
  local extra = require("config.modes").active()
  if not extra then
    return badge(base[1], base[2])
  end
  local out = badge(extra:upper(), extra)
  if base[1] ~= "NORMAL" then
    out = out .. " " .. badge(base[1], base[2])
  end
  return out
end

local function file()
  if vim.bo.buftype == "terminal" then
    return "terminal"
  end
  local name = vim.fn.expand("%:~:.")
  if name == "" then
    return "[no name]"
  end
  local ok, devicons = pcall(require, "nvim-web-devicons")
  local icon = ok and devicons.get_icon(vim.fn.expand("%:t"), nil, { default = true }) or ""
  local flag = vim.bo.modified and (" " .. hl("StlWarn", "\u{f111}")) or (vim.bo.readonly and " \u{f023}" or "")
  return icon .. " " .. hl("StlFile", name) .. flag
end

local function recording()
  local reg = vim.fn.reg_recording()
  return reg ~= "" and hl("StlWarn", "\u{f111} rec @" .. reg) or ""
end

-- filetypes that have a configured server (computed once)
local lsp_fts
local function lsp()
  local progress = vim.lsp.status()
  if progress ~= "" then
    return hl("StlDim", progress:sub(1, 40))
  end
  if not lsp_fts then
    lsp_fts = { rust = true }
    for name in pairs(require("lang").map("servers")) do
      for _, ft in ipairs((vim.lsp.config[name] or {}).filetypes or {}) do
        lsp_fts[ft] = true
      end
    end
  end
  if vim.bo.buftype == "" and lsp_fts[vim.bo.filetype] and #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
    return hl("StlWarn", "\u{f071} no LSP")
  end
  return ""
end

local function diagnostics(errors_only)
  local count = vim.diagnostic.count(0)
  local s = vim.diagnostic.severity
  local out = {}
  if (count[s.ERROR] or 0) > 0 then
    table.insert(out, hl("DiagnosticError", "\u{f057} " .. count[s.ERROR]))
  end
  if not errors_only and (count[s.WARN] or 0) > 0 then
    table.insert(out, hl("DiagnosticWarn", "\u{f071} " .. count[s.WARN]))
  end
  return table.concat(out, " ")
end

local function git()
  local g = vim.b.gitsigns_status_dict
  if not g then
    return ""
  end
  local out = {}
  if (g.added or 0) > 0 then
    table.insert(out, hl("GitSignsAdd", "+" .. g.added))
  end
  if (g.changed or 0) > 0 then
    table.insert(out, hl("GitSignsChange", "~" .. g.changed))
  end
  if (g.removed or 0) > 0 then
    table.insert(out, hl("GitSignsDelete", "-" .. g.removed))
  end
  return table.concat(out, " ")
end

-- pinned files (harpoon): "1 main  2 oa", current one highlighted
local function pinned()
  if not package.loaded.harpoon then
    return ""
  end
  local current = vim.fn.expand("%:p")
  local out = {}
  for i, item in ipairs(require("harpoon"):list().items) do
    if i > 4 then
      break
    end
    local here = vim.fn.fnamemodify(item.value, ":p") == current
    table.insert(out, hl(here and "StlAccent" or "StlDim", i .. " " .. vim.fn.fnamemodify(item.value, ":t:r")))
  end
  return table.concat(out, "  ")
end

local function branch()
  local head = vim.b.gitsigns_head or vim.g.gitsigns_head
  return head and head ~= "" and hl("StlDim", "\u{e725} " .. head) or ""
end

function M.render()
  if vim.bo.filetype == "snacks_dashboard" then
    return ""
  end
  -- focus mode (config/focus.lua) keeps only what you'd act on right now
  local parts = require("config.modes").active() == "focus"
      and { recording(), diagnostics(true), hl("StlDim", require("config.focus").status()) }
    or { recording(), lsp(), diagnostics(), git(), pinned(), branch() }
  local right = {}
  for _, part in ipairs(parts) do
    if part ~= "" then
      table.insert(right, part)
    end
  end
  return mode_badges() .. " " .. file() .. "%=" .. table.concat(right, "   ") .. " "
end

function M.setup()
  local function colors()
    local p = require("config.palette")
    vim.api.nvim_set_hl(0, "StatusLine", { fg = p.dim, bg = p.bg })
    vim.api.nvim_set_hl(0, "StatusLineNC", { fg = p.dim, bg = p.bg })
    vim.api.nvim_set_hl(0, "StlFile", { fg = p.fg })
    vim.api.nvim_set_hl(0, "StlDim", { fg = p.dim })
    vim.api.nvim_set_hl(0, "StlAccent", { fg = p.accent, bold = true })
    vim.api.nvim_set_hl(0, "StlWarn", { fg = p.warn })
  end
  colors()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      colors()
      badge_groups = {}
    end,
  })
  vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
  -- redraw only when these change (cursor moves already redraw it)
  vim.api.nvim_create_autocmd({ "ModeChanged", "LspProgress", "LspAttach", "LspDetach", "DiagnosticChanged", "RecordingEnter", "RecordingLeave" }, {
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "GitSignsUpdate",
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })
end

return M
