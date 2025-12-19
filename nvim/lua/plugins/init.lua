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
	require("plugins.lazygit"),
	require("plugins.gitsigns"),
	require("plugins.go"),
	require("plugins.oil"),
	require("plugins.linter"),
	require("plugins.format"),
	require("plugins.faster"),
	require("plugins.flash"),
	require("plugins.fidget"),
	require("plugins.nvim-tmux"),
	require("plugins.tabout"),
	require("plugins.learn"),
	-- require("plugins.incline"),
	require("plugins.aerial"),
})
