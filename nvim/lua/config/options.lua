local opt = vim.opt

-- line numbers
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorlineopt = "number" -- highlight only the current line number
opt.signcolumn = "yes"
opt.numberwidth = 3

-- indentation (per-project overrides come from .editorconfig, built in)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.shiftround = true

-- search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- live preview of :s substitutions

-- UI
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.showtabline = 0
opt.splitright = true
opt.splitbelow = true
opt.laststatus = 3 -- one global statusline
opt.showmode = false -- mode shows in the statusline badge and the cursor line number color
opt.pumheight = 12
opt.winborder = "single" -- slim square borders on all floating windows
opt.linebreak = true
opt.smoothscroll = true
opt.virtualedit = "block"
opt.confirm = true -- ask instead of failing on :q with unsaved changes
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
opt.shortmess:append({ W = true, I = true, c = true, C = true, s = true })
opt.showcmd = false
opt.ruler = false
opt.fillchars = { eob = " ", fold = " ", foldopen = "\u{f107}", foldclose = "\u{f105}", foldsep = " ", diff = "╱" }

-- folding (treesitter-based, everything open by default)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

-- responsiveness
opt.timeoutlen = 300
opt.updatetime = 200

-- files
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true -- persistent undo across sessions
opt.undolevels = 10000

-- input
opt.mouse = ""
opt.clipboard = "unnamedplus"

-- sessions (persistence.nvim)
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Neovim 0.12 message/cmdline UI: no "Press ENTER" prompts, no empty cmdline row
opt.cmdheight = 0
pcall(function()
  require("vim._core.ui2").enable({ msg = { targets = "msg" } })
end)

-- diagnostics: full message shown inline on the cursor line by tiny-inline-diagnostic
-- (plugins/lsp.lua; <leader>uv for all lines)
vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "\u{f057}",
      [vim.diagnostic.severity.WARN] = "\u{f071}",
      [vim.diagnostic.severity.INFO] = "\u{f05a}",
      [vim.diagnostic.severity.HINT] = "\u{f0335}",
    },
  },
  float = { source = true, header = "", prefix = "" },
})
