local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  require("plugins.colorscheme"),
  require("plugins.lsp"),
  require("plugins.cmp"),
  require("plugins.dap"),
  require("plugins.telescope"),
  require("plugins.statusline"),
  require("plugins.treesitter"),
  require("plugins.autopair"),
  require("plugins.aerial")
})

