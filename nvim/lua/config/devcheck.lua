-- :DevCheck — verify the whole dev setup in one screen.
-- Per language: server, formatters, linters, debugger, parsers. Plus system tools.
-- Every ✗ comes with the command that fixes it.
local M = {}

local ok_icon, bad_icon = "\u{f00c}", "\u{f00d}"

local function exe(cmd)
  return type(cmd) == "string" and vim.fn.executable(cmd) == 1
end

local function check_lang(entry, problems)
  local spec, parts = entry.spec, {}
  local function add(label, good, fix)
    table.insert(parts, (good and "" or "!") .. label)
    if not good then
      table.insert(problems, { lang = entry.name, what = label, fix = fix })
    end
  end

  for _, req in ipairs(spec.requires or {}) do
    add("bin:" .. req[1], exe(req[1]), req[2])
  end

  local registry_ok, registry = pcall(require, "mason-registry")
  for _, tool in ipairs(spec.tools or {}) do
    if registry_ok and registry.has_package(tool) and not registry.is_installed(tool) then
      add(tool, false, ":MasonInstall " .. tool)
    end
  end

  for name in pairs(spec.servers or {}) do
    local cfg = vim.lsp.config[name] or {}
    local cmd = type(cfg.cmd) == "table" and cfg.cmd[1] or nil
    add("lsp:" .. name, cmd == nil or exe(cmd), cmd and (":MasonInstall for " .. cmd))
  end

  local conform_ok, conform = pcall(require, "conform")
  local seen = {}
  for _, list in pairs(spec.formatters or {}) do
    local any_available, names = false, {}
    for _, f in ipairs(list) do
      if not seen[f] then
        table.insert(names, f)
      end
      if conform_ok then
        local info = conform.get_formatter_info(f)
        any_available = any_available or info.available
      end
    end
    for _, f in ipairs(names) do
      seen[f] = true
    end
    if #names > 0 then
      add("fmt:" .. table.concat(names, "/"), not conform_ok or any_available, ":MasonInstall " .. names[1])
    end
  end

  local lint_ok, lint = pcall(require, "lint")
  for _, list in pairs(spec.linters or {}) do
    for _, l in ipairs(list) do
      local linter = lint_ok and lint.linters[l]
      local cmd = type(linter) == "table" and linter.cmd or l
      add("lint:" .. l, type(cmd) ~= "string" or exe(cmd), ":MasonInstall " .. l)
    end
  end

  for _, parser in ipairs(spec.parsers or {}) do
    if #vim.api.nvim_get_runtime_file("parser/" .. parser .. ".so", false) == 0 then
      add("ts:" .. parser, false, ":TSInstall " .. parser)
    end
  end
  return parts
end

function M.run()
  require("lazy").load({ plugins = { "mason.nvim", "conform.nvim", "nvim-lint", "nvim-dap" } })
  local problems, lines = {}, {}
  local function line(s)
    table.insert(lines, s)
  end

  line("# Languages")
  for _, entry in ipairs(require("lang").all()) do
    local parts = check_lang(entry, problems)
    local bad = vim.iter(parts):any(function(p)
      return p:sub(1, 1) == "!"
    end)
    local shown = vim.tbl_map(function(p)
      return p:sub(1, 1) == "!" and (bad_icon .. " " .. p:sub(2)) or p
    end, parts)
    line(("%s %-8s %s"):format(bad and bad_icon or ok_icon, entry.name, table.concat(shown, "  ")))
  end

  line("")
  line("# Debug adapters")
  local dap = require("dap")
  for name, adapter in pairs(dap.adapters) do
    local cmd = type(adapter) == "table" and (adapter.command or (adapter.executable or {}).command)
    if type(cmd) == "string" then
      local good = exe(cmd)
      line(("%s %-10s %s"):format(good and ok_icon or bad_icon, name, cmd))
      if not good then
        table.insert(problems, { lang = "dap", what = name, fix = ":MasonInstall for " .. cmd })
      end
    end
  end

  line("")
  line("# System")
  local system = {
    { "tree-sitter", "brew install tree-sitter-cli" },
    { "rg", "brew install ripgrep" },
    { "fd", "brew install fd" },
    { "git", "xcode-select --install" },
    { "lazygit", "brew install lazygit" },
    { "lazydocker", "brew install lazydocker" },
  }
  for _, t in ipairs(system) do
    local good = exe(t[1])
    line(("%s %s"):format(good and ok_icon or bad_icon, t[1]))
    if not good then
      table.insert(problems, { lang = "system", what = t[1], fix = t[2] })
    end
  end
  local devmode = vim.fn.system({ "DevToolsSecurity", "-status" }):find("enabled") ~= nil
  line(("%s macOS developer mode (native debugging)"):format(devmode and ok_icon or bad_icon))
  if not devmode then
    table.insert(problems, { lang = "system", what = "developer mode", fix = "sudo DevToolsSecurity -enable" })
  end

  line("")
  if #problems == 0 then
    line(ok_icon .. " Everything is installed and wired up.")
  else
    line(("# %d to fix"):format(#problems))
    for _, p in ipairs(problems) do
      line(("%s %s %s  ->  %s"):format(bad_icon, p.lang, p.what, p.fix))
    end
  end

  Snacks.win({
    text = lines,
    title = " DevCheck ",
    title_pos = "center",
    width = 0.7,
    height = math.min(#lines + 2, math.floor(vim.o.lines * 0.8)),
    border = "single",
    ft = "markdown",
    wo = { conceallevel = 0, wrap = false },
    keys = { q = "close", ["<Esc>"] = "close" },
  })
  return problems
end

return M
