-- Language registry.
--
-- To add a language: create lua/lang/<name>.lua returning any of these fields,
-- then add <name> to `enabled` below. Every field is optional.
--
--   requires   = { { "binary", "how to install" } }, -- system toolchain, checked by :DevCheck
--   parsers    = { "treesitter", "parsers" },
--   tools      = { "mason-package-names" },          -- auto-installed by Mason
--   servers    = { lspconfig_name = { ...config } }, -- passed to vim.lsp.config()
--   formatters = { filetype = { "conform", "formatters" } },
--   linters    = { filetype = { "nvim-lint", "linters" } },
--   setup      = function() ... end,                 -- commands etc., run once at LSP setup
--   dap        = function(dap) ... end,              -- register adapters/configurations
--   tests      = function() return { neotest_adapter, ... } end,
--   plugins    = { lazy.nvim specs },                -- extra language plugins
local M = {}

M.enabled = {
  "lua",
  "c",
  "web",
  "go",
  "python",
  "rust",
  "shell",
  "data",
}

local cache
local function modules()
  if not cache then
    cache = {}
    for _, name in ipairs(M.enabled) do
      table.insert(cache, require("lang." .. name))
    end
  end
  return cache
end

---All enabled language modules, paired with their names.
function M.all()
  local out = {}
  for i, lang in ipairs(modules()) do
    table.insert(out, { name = M.enabled[i], spec = lang })
  end
  return out
end

---Concatenate a list field (parsers, tools, plugins) across all languages.
function M.list(field)
  local out = {}
  for _, lang in ipairs(modules()) do
    vim.list_extend(out, lang[field] or {})
  end
  return out
end

---Merge a map field (servers, formatters, linters) across all languages.
function M.map(field)
  local out = {}
  for _, lang in ipairs(modules()) do
    out = vim.tbl_extend("force", out, lang[field] or {})
  end
  return out
end

---Run a function field (dap, tests) for every language that defines it.
function M.each(field, ...)
  local results = {}
  for _, lang in ipairs(modules()) do
    if lang[field] then
      vim.list_extend(results, lang[field](...) or {})
    end
  end
  return results
end

return M
