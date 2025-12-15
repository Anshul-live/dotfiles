-- =========================
-- Core Neovim configuration
-- =========================

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- UI
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

-- responsiveness
vim.opt.timeoutlen = 300
vim.opt.updatetime = 200

-- disable junk
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

--setup leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--diagnostic setup
vim.diagnostic.config({
  virtual_text = false,   -- disable inline text
  signs = true,           -- keep gutter signs
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
  },
})

